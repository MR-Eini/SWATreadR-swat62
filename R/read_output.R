#' Read a standard SWAT+ text output without discarding records
#'
#' Handles revision 62's optional plant and management labels in basin and HRU
#' water-balance and plant-weather outputs. HRU labels use the engine's a16/a30
#' formats and may have no whitespace separator. Unknown layouts fail explicitly.
#' @param file_path Path to a text output with title, names and units rows.
#' @return A tibble retaining all named columns and data records.
#' @export
read_swat_output <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  if (length(lines) < 3L) stop("Incomplete output: ", file_path)
  header <- strsplit(trimws(lines[2L]), "[[:space:]]+")[[1L]]
  header <- make.unique(header, sep = "_")
  data <- lines[-seq_len(3L)]
  data <- data[nzchar(trimws(data))]
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
  if (!length(data)) {
    result <- stats::setNames(rep(list(character()), length(header)), header)
  } else {
    result <- withCallingHandlers(
      data.table::fread(text = paste(data, collapse = "\n"), header = FALSE),
      warning = function(w) stop("Cannot safely parse ", basename(file_path), ": ", conditionMessage(w)))
    if (nrow(result) != length(data) || ncol(result) != length(header)) {
      stop("Output header/data mismatch in ", basename(file_path))
    }
    names(result) <- header
  }
  result <- tibble::as_tibble(result)
  if (!is.null(extra)) {
    for (name in names(extra)) {
      extra[[name]][extra[[name]] == "" & !is.na(extra[[name]])] <- NA_character_
      result[[name]] <- extra[[name]]
    }
  }
  result
}
