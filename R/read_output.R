#' Read a standard SWAT+ text output without discarding records
#'
#' Handles revision 62's optional plant and management labels in basin and HRU
#' water-balance and plant-weather outputs. HRU labels use the engine's a16/a30
#' formats and may have no whitespace separator. Unknown layouts fail explicitly.
#' Average annual basin water balance also retains the engine's unlabelled
#' calibration fields as `cal_sim` and `cal_adj`.
#' @param file_path Path to a text output with title, names and units rows.
#' @param chunk_rows Maximum physical data rows read per chunk (1 to 100000).
#'   Chunking avoids the single-string limit; the returned table still needs RAM.
#' @return A tibble retaining all named columns and data records.
#' @export
read_swat_output <- function(file_path, chunk_rows = 10000L) {
  read_output_chunks(file_path, chunk_rows, parse_swat_output_chunk)
}

# Read a bounded set of physical rows at a time. Never collapse an entire
# multi-GB output into a single R string. The final table still needs RAM.
read_output_chunks <- function(file_path, chunk_rows, parse_chunk,
                               buffer_limit = 256 * 1024^2) {
  if (length(chunk_rows) != 1L || !is.numeric(chunk_rows) ||
      is.na(chunk_rows) || !is.finite(chunk_rows) || chunk_rows < 1 ||
      chunk_rows > 100000L || chunk_rows != floor(chunk_rows)) {
    stop("chunk_rows must be a whole number between 1 and 100000", call. = FALSE)
  }
  con <- file(file_path, open = "rt")
  on.exit(close(con), add = TRUE)
  lines <- readLines(con, n = 3L, warn = FALSE)
  if (length(lines) < 3L) stop("Incomplete output: ", file_path)
  large <- file.info(file_path)$size > buffer_limit
  chunks <- list()
  prototype <- NULL
  consume <- function(chunk) {
    if (is.null(prototype)) {
      prototype <<- chunk[0L, ]
    } else {
      if (!identical(names(chunk), names(prototype))) {
        stop("Output columns changed between chunks in ", file_path)
      }
      # Promote column types without retaining the data in large-file mode.
      prototype <<- tibble::as_tibble(data.table::rbindlist(
        list(prototype, chunk[0L, ]), use.names = TRUE, fill = FALSE))
    }
    if (!large) chunks[[length(chunks) + 1L]] <<- chunk
  }
  records <- consume_output_chunks(con, lines, chunk_rows, file_path,
                                   parse_chunk, consume)
  if (!records) return(parse_chunk(lines, character(), file_path))
  if (!large) {
    result <- data.table::rbindlist(chunks, use.names = TRUE, fill = FALSE)
  } else {
    # Allocate the complete table once. A two-pass read avoids simultaneously
    # keeping every parsed chunk and another full table during rbindlist().
    result <- lapply(prototype, function(column) {
      rep(column[NA_integer_], records)
    })
    data.table::setDT(result)
    close(con)
    con <- file(file_path, open = "rt")
    if (!identical(readLines(con, n = 3L, warn = FALSE), lines)) {
      stop("Output header changed while reading ", file_path)
    }
    offset <- 0
    fill_result <- function(chunk) {
      if (!identical(names(chunk), names(prototype)) || offset + nrow(chunk) > records) {
        stop("Output changed while reading ", file_path)
      }
      index <- seq.int(offset + 1, offset + nrow(chunk))
      for (name in names(chunk)) {
        data.table::set(result, i = index, j = name, value = chunk[[name]])
      }
      offset <<- offset + nrow(chunk)
    }
    second_records <- consume_output_chunks(con, lines, chunk_rows, file_path,
                                            parse_chunk, fill_result)
    if (second_records != records) stop("Output changed while reading ", file_path)
  }
  if (nrow(result) != records) stop("Output row count mismatch in ", file_path)
  tibble::as_tibble(as.list(result))
}

consume_output_chunks <- function(con, lines, chunk_rows, file_path,
                                  parse_chunk, consume) {
  records <- 0
  repeat {
    data <- readLines(con, n = as.integer(chunk_rows), warn = FALSE)
    if (!length(data)) break
    data <- data[grepl("[^[:space:]]", data)]
    if (!length(data)) next
    # A corrupt row must not be allowed to create an oversized parse string.
    bytes <- as.double(nchar(data, type = "bytes")) + 1
    if (any(bytes > 64 * 1024^2)) stop("Oversized output row in ", file_path)
    groups <- floor((cumsum(bytes) - 1) / (64 * 1024^2))
    for (group in unique(groups)) {
      block <- data[groups == group]
      chunk <- parse_chunk(lines, block, file_path)
      if (nrow(chunk) != length(block)) stop("Output row count mismatch in ", file_path)
      consume(chunk)
      records <- records + length(block)
    }
  }
  records
}

parse_swat_output_chunk <- function(lines, data, file_path) {
  header <- strsplit(trimws(lines[2L]), "[[:space:]]+")[[1L]]
  header <- make.unique(header, sep = "_")
  labels <- identical(tail(header, 2L), c("plant_cov", "mgt_ops"))
  extra <- NULL
  if (labels && grepl("^hru_(wb|pw)_", basename(file_path))) {
    # src/hru_output.f90 formats 100/101: 4i6,2i8,2x,a16,Nf12.3,3x,a16,a30.
    start <- 62L + 12L * (length(header) - 9L)
    extra <- list(plant_cov = trimws(substr(data, start, start + 15L)),
                  mgt_ops = trimws(substr(data, start + 16L, start + 45L)))
    data <- substr(data, 1L, start - 4L)
    header <- head(header, -2L)
  } else if (labels && grepl("^basin_(wb|pw)_", basename(file_path))) {
    extra <- list(plant_cov = rep(NA_character_, length(data)),
                  mgt_ops = rep(NA_character_, length(data)))
    header <- head(header, -2L)
  }
  if (identical(basename(file_path), "basin_wb_aa.txt") && length(data)) {
    # basin_output.f90 format 103 / time_module.f90: the numeric fields are
    # followed by cal_sim (a29, possibly containing spaces) and cal_adj (f17.3).
    # Neither is named in the shared water-balance header.
    end <- 60L + 12L * (length(header) - 7L)
    if (any(nchar(data) > end)) {
      if (any(nchar(data) != end + 46L)) {
        stop("Unexpected calibration suffix in ", basename(file_path))
      }
      adjustment <- trimws(substr(data, end + 30L, end + 46L))
      adjustment <- suppressWarnings(as.numeric(adjustment))
      if (anyNA(adjustment)) stop("Invalid cal_adj in ", basename(file_path))
      extra <- c(extra, list(cal_sim = trimws(substr(data, end + 1L, end + 29L)),
                             cal_adj = adjustment))
      data <- substr(data, 1L, end)
    }
  }
  if (!length(data)) {
    result <- stats::setNames(rep(list(character()), length(header)), header)
  } else {
    result <- withCallingHandlers(
      data.table::fread(text = paste(data, collapse = "\n"), header = FALSE,
                       sep = " ", quote = "", blank.lines.skip = FALSE),
      warning = function(w) stop("Cannot safely parse ", basename(file_path), ": ", conditionMessage(w)))
    if (nrow(result) != length(data) || ncol(result) != length(header)) {
      stop("Output header/data mismatch in ", basename(file_path))
    }
    names(result) <- header
  }
  result <- tibble::as_tibble(as.list(result))
  if (!is.null(extra)) {
    for (name in names(extra)) {
      if (is.character(extra[[name]])) {
        extra[[name]][extra[[name]] == "" & !is.na(extra[[name]])] <- NA_character_
      }
      result[[name]] <- extra[[name]]
    }
  }
  result
}
