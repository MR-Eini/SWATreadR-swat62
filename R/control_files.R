#' Read or update named SWAT+ control fields
#'
#' Control files contain a whitespace-separated header followed by a value row.
#' These helpers locate fields by name and retain additional fields and sections.
#' They do not migrate a model between engine revisions.
#' @param lines Character vector returned by `readLines()`.
#' @param fields Character vector of field names.
#' @param values Named vector of replacement values.
#' @return `swat_control_get()` returns a named character vector;
#'   `swat_control_set()` returns the updated lines.
#' @export
swat_control_get <- function(lines, fields) {
  tokens <- strsplit(trimws(lines), "[[:space:]]+")
  idx <- which(vapply(tokens, function(x) all(fields %in% x), logical(1)))
  if (length(idx) != 1L || idx == length(lines)) {
    stop("Expected one control header containing: ", paste(fields, collapse = ", "))
  }
  pos <- match(fields, tokens[[idx]])
  if (anyDuplicated(tokens[[idx]]) || length(tokens[[idx + 1L]]) < max(pos)) {
    stop("Malformed control section: ", paste(fields, collapse = ", "))
  }
  stats::setNames(tokens[[idx + 1L]][pos], fields)
}

#' @rdname swat_control_get
#' @export
swat_control_set <- function(lines, values) {
  fields <- names(values)
  if (!length(fields) || any(!nzchar(fields)) || anyDuplicated(fields) || anyNA(values)) {
    stop("Provide unique named, non-missing control values.")
  }
  swat_control_get(lines, fields)
  tokens <- strsplit(trimws(lines), "[[:space:]]+")
  idx <- which(vapply(tokens, function(x) all(fields %in% x), logical(1)))
  row <- tokens[[idx + 1L]]
  row[match(fields, tokens[[idx]])] <- as.character(values)
  lines[idx + 1L] <- paste(row, collapse = " ")
  lines
}

#' Update entries in a named file.cio section
#'
#' @param lines Character vector containing file.cio.
#' @param section Section label, such as `lum` or `climate`.
#' @param positions Integer entry positions after the section label.
#' @param values Character replacement values, one for each position.
#' @return Updated lines, retaining all other sections and entries.
#' @export
swat_cio_set <- function(lines, section, positions, values) {
  tokens <- strsplit(trimws(lines), '[[:space:]]+')
  idx <- which(vapply(tokens, function(x) identical(x[1L], section), logical(1)))
  if (length(idx) != 1L) stop('Missing or ambiguous file.cio section: ', section)
  if (!length(positions) || anyNA(positions) || any(positions < 1L | positions != trunc(positions)) ||
      anyDuplicated(positions) || length(values) != length(positions) || anyNA(values) ||
      any(!nzchar(values) | grepl('[[:space:]]', values))) {
    stop('Provide unique positive entry positions and one nonempty token per value.')
  }
  row <- tokens[[idx]]
  if (max(positions) + 1L > length(row)) stop('Missing entries in file.cio section: ', section)
  row[positions + 1L] <- values
  lines[idx] <- paste(row, collapse = ' ')
  lines
}

#' Configure SWAT+ object output by name
#'
#' Existing object switches are reset to `n`, then requested switches are enabled.
#' Headers, control sections, extra object columns and their order are preserved.
#' Unknown objects or intervals raise an error before any file is written.
#' @param lines Character vector containing print.prt.
#' @param outputs Named list of character vectors, for example
#'   `list(basin_wb = c("daily", "avann"))`.
#' @return Updated character vector.
#' @export
swat_print_objects <- function(lines, outputs = list()) {
  tokens <- strsplit(trimws(lines), "[[:space:]]+")
  idx <- which(vapply(tokens, function(x) identical(x[1L], "objects"), logical(1)))
  if (length(idx) != 1L || idx == length(lines)) stop("Missing or ambiguous print.prt objects header.")
  intervals <- c("daily", "monthly", "yearly", "avann")
  pos <- match(intervals, tokens[[idx]])
  if (anyNA(pos)) stop("Unsupported print.prt interval header.")
  rows <- seq.int(idx + 1L, length(lines))
  rows <- rows[vapply(tokens[rows], function(x) length(x) >= max(pos) &&
    all(x[pos] %in% c("y", "n")), logical(1))]
  objects <- vapply(tokens[rows], `[`, character(1), 1L)
  if (anyDuplicated(objects)) stop("Duplicate print.prt object names.")
  missing <- setdiff(names(outputs), objects)
  if (length(missing)) stop("Objects absent from print.prt: ", paste(missing, collapse = ", "))
  if (any(!unlist(outputs) %in% intervals)) stop("Unknown output interval.")
  for (i in seq_along(rows)) {
    row <- tokens[[rows[i]]]
    row[pos] <- "n"
    requested <- outputs[[objects[i]]]
    row[pos[match(requested, intervals)]] <- "y"
    lines[rows[i]] <- paste(row, collapse = " ")
  }
  lines
}

#' Configure SWAT+ text output flags across legacy and revision 62 headers
#' @param lines Character vector containing print.prt.
#' @param mgtout,fdcout Management and flow-duration switches (`y` or `n`).
#' @param crop_yld Crop yield switch (`n`, `y`, `a`, or `b`).
#' @return Updated lines. The revision 62 `use_obj_labels` setting is preserved.
#' @export
swat_print_options <- function(lines, mgtout = "n", fdcout = "n", crop_yld = "n") {
  fields <- unlist(strsplit(trimws(lines), "[[:space:]]+"))
  lines <- swat_control_set(lines, c(csvout = "n", cdfout = "n"))
  if ("dbout" %in% fields) lines <- swat_control_set(lines, c(dbout = "n"))
  crop_field <- if ("crop_yld" %in% fields) "crop_yld" else "soilout"
  lines <- swat_control_set(lines, stats::setNames(crop_yld, crop_field))
  swat_control_set(lines, c(mgtout = mgtout, hydcon = "n", fdcout = fdcout))
}
