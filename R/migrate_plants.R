#' Migrate a legacy plants.plt table for SWAT+ revision 62
#'
#' SWAT+ revision 62 reads three lignin fraction fields after the residue-cover
#' fields. A legacy row without those values can cause the list-directed Fortran
#' reader to continue into the next row, making every second plant unavailable
#' to plant communities and management schedules.
#'
#' This helper preserves all plant rows and calibrated parameters, renames the
#' two legacy wind-residue columns to their revision 62 names, and inserts the
#' three required lignin fractions. The default fractions match the values used
#' internally by SWAT+ when its carbon model is disabled.
#'
#' @param file_path Path to `plants.plt`.
#' @param carbon_fractions Named numeric vector containing `avg_lig_frac`,
#'   `ab_lig_frac`, and `bg_lig_frac`.
#' @param overwrite Replace `file_path`. When `FALSE`, return the migrated lines
#'   without writing them.
#'
#' @return Invisibly returns the migrated text lines.
#' @export
swat_migrate_plants_rev62 <- function(
    file_path,
    carbon_fractions = c(avg_lig_frac = 0.85, ab_lig_frac = 0.15,
                         bg_lig_frac = 0.12),
    overwrite = TRUE) {
  stopifnot(length(file_path) == 1L, is.character(file_path),
            length(overwrite) == 1L, is.logical(overwrite), !is.na(overwrite))
  if (!file.exists(file_path)) stop("Missing plants.plt file: ", file_path)

  required_carbon <- c("avg_lig_frac", "ab_lig_frac", "bg_lig_frac")
  if (is.null(names(carbon_fractions)) ||
      !all(required_carbon %in% names(carbon_fractions))) {
    stop("carbon_fractions must name: ", paste(required_carbon, collapse = ", "))
  }
  carbon_fractions <- carbon_fractions[required_carbon]
  if (any(!is.finite(carbon_fractions)) || any(carbon_fractions < 0) ||
      any(carbon_fractions > 1)) {
    stop("carbon_fractions must contain finite values from 0 to 1.")
  }

  lines <- readLines(file_path, warn = FALSE)
  if (length(lines) < 3L) stop("Incomplete plants.plt file: ", file_path)
  split_fields <- function(x) strsplit(trimws(x), "[[:space:]]+")[[1L]]
  header <- split_fields(lines[2L])
  rows <- lapply(lines[-c(1L, 2L)], split_fields)
  if (any(lengths(rows) != length(header))) {
    bad <- which(lengths(rows) != length(header))[1L] + 2L
    stop("plants.plt row ", bad, " has ", lengths(rows)[bad - 2L],
         " values; expected ", length(header), ".")
  }

  description_pos <- match("description", header, nomatch = 0L)
  carbon_pos <- match(required_carbon, header, nomatch = 0L)
  if (all(carbon_pos > 0L)) {
    if (!identical(carbon_pos, seq.int(carbon_pos[1L], length.out = 3L))) {
      stop("Revision 62 lignin fields are not contiguous in plants.plt.")
    }
  } else if (any(carbon_pos > 0L)) {
    stop("plants.plt contains only part of the revision 62 lignin schema.")
  } else {
    insert_at <- if (description_pos > 0L) description_pos else length(header) + 1L
    before <- if (insert_at > 1L) seq_len(insert_at - 1L) else integer()
    after <- if (insert_at <= length(header)) insert_at:length(header) else integer()
    values <- format(carbon_fractions, trim = TRUE, scientific = FALSE)
    header <- c(header[before], required_carbon, header[after])
    rows <- lapply(rows, function(row) c(row[before], values, row[after]))
  }

  legacy_names <- match(c("wnd_dead", "wnd_flat"), header, nomatch = 0L)
  if (all(legacy_names > 0L)) {
    header[legacy_names] <- c("rsd_pctcov", "rsd_covfac")
  } else if (any(legacy_names > 0L)) {
    stop("plants.plt contains only one of wnd_dead and wnd_flat.")
  }

  migrated <- c(lines[1L], paste(header, collapse = " "),
                vapply(rows, paste, collapse = " ", character(1)))
  if (overwrite) writeLines(migrated, file_path, useBytes = TRUE)
  invisible(migrated)
}
