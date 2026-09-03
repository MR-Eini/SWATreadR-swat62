#' Read SWAT+ management output using its header
#'
#' Management operations have different numbers of trailing values. Missing
#' trailing values are retained as NA; additional named fields are preserved.
#' @param file_path Path to mgt_out.txt.
#' @return A tibble with the engine's column names.
#' @export
read_swat_mgt <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  if (length(lines) < 3L) stop("Incomplete management output: ", file_path)
  header <- strsplit(trimws(lines[2L]), "[[:space:]]+")[[1L]]
  required <- c("hru", "year", "mon", "day", "crop/fert/pest", "operation")
  if (!all(required %in% header) || anyDuplicated(header)) {
    stop("Unsupported management output header: ", file_path)
  }
  data <- lines[-seq_len(3L)]
  data <- data[nzchar(trimws(data))]
  rows <- strsplit(trimws(data), "[[:space:]]+")
  if (any(lengths(rows) < length(required)) || any(lengths(rows) > length(header))) {
    stop("Management row does not match its header: ", file_path)
  }
  result <- lapply(seq_along(header), function(i) vapply(rows, function(x) x[i], character(1)))
  names(result) <- header
  numeric_fields <- setdiff(header, c("crop/fert/pest", "operation"))
  result[numeric_fields] <- lapply(result[numeric_fields], as.numeric)
  tibble::as_tibble(result)
}
