test_that("named controls preserve new flags and shifted object rows", {
  x <- c("fixture", "csvout dbout cdfout crop_yld", "y y y y",
         "gwflow_out", "y", "objects daily monthly yearly avann extra",
         "basin_wb y y y y retained", "hru_wb y y y y retained")
  y <- swat_control_set(x, c(csvout = "n", dbout = "n", cdfout = "n"))
  y <- swat_print_objects(y, list(basin_wb = c("daily", "avann")))
  expect_equal(swat_control_get(y, "crop_yld"), c(crop_yld = "y"))
  expect_equal(swat_control_get(y, "gwflow_out"), c(gwflow_out = "y"))
  expect_equal(y[7:8], c("basin_wb y n n y retained", "hru_wb n n n n retained"))
  expect_error(swat_print_objects(x, list(missing = "daily")), "absent")
  expect_error(swat_control_set(x, c(unknown = 0)), "header")
})

test_that("plants maturity fields are integers and extra columns survive", {
  path <- file.path(tempdir(), "plants.plt")
  tbl <- tibble::tibble(name = "crop", days_mat = 110, yrs_mat = 2, added = 1.25)
  write_swat(tbl, path, overwrite = TRUE)
  expect_match(readLines(path)[3], "crop  110  2  1.25", fixed = TRUE)
  expect_equal(lapply(read_swat(path), identity), lapply(tbl, identity))
  original <- readLines(path)
  tbl$days_mat <- 110.5
  expect_error(write_swat(tbl, path), "whole numbers")
  expect_equal(readLines(path), original)
})

test_that("management uses names and retains short operations and new columns", {
  path <- tempfile(fileext = ".txt")
  writeLines(c("fixture", "hru year mon day crop/fert/pest operation phubase added",
    "units", "1 2007 4 2 corn PLANT", "1 2007 9 1 corn HARVEST 20 7"), path)
  x <- read_swat_mgt(path)
  expect_equal(nrow(x), 2L)
  expect_equal(x$added, c(NA_real_, 7))
  expect_equal(x$operation, c("PLANT", "HARVEST"))
  writeLines(c("fixture", "hru year mon day crop/fert/pest operation", "units"), path)
  expect_equal(nrow(read_swat_mgt(path)), 0L)
})

test_that("revision 62 object-label mode is preserved", {
  x <- c("fixture", "csvout use_obj_labels cdfout", "y y y",
    "crop_yld mgtout hydcon fdcout", "b n y y")
  result <- swat_print_options(x, mgtout = "y")
  expect_equal(swat_control_get(result, "use_obj_labels"), c(use_obj_labels = "y"))
  expect_equal(result[5], "n y n n")
})

test_that("fixed-width adjacent HRU labels do not truncate output", {
  path <- file.path(tempdir(), "hru_pw_day.txt")
  fields <- c("jday", "mon", "day", "yr", "unit", "gis_id", "name",
    paste0("value", 1:25), "plant_cov", "mgt_ops")
  row <- paste0(paste(sprintf("%6d", c(1, 1, 1, 2007)), collapse = ""),
    paste(sprintf("%8d", c(1, 0)), collapse = ""), "  ", sprintf("%-16s", "hru001"),
    paste(sprintf("%12.3f", 1:25), collapse = ""), "   ",
    sprintf("%-16s", "abcdefghijklmnop"), sprintf("%-30s", "schedule"))
  writeLines(c("fixture", paste(fields, collapse = " "), "units", row, row), path)
  result <- read_swat_output(path)
  expect_equal(nrow(result), 2L)
  expect_equal(result$plant_cov, rep("abcdefghijklmnop", 2))
  expect_equal(result$mgt_ops, rep("schedule", 2))
  expect_equal(result$value25, c(25, 25))
})
