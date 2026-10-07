test_that("chunks retain every row, whitespace and promoted numeric values", {
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(c("fixture", "id value name", "units", "1 2 first", "",
               " 2   2.5 second ", "3 4 third", "4 5 fourth", "5 6 fifth"), path)
  expected <- tibble::tibble(id = 1:5, value = c(2, 2.5, 4, 5, 6),
                             name = c("first", "second", "third", "fourth", "fifth"))
  for (size in c(1L, 2L, 3L, 10000L)) {
    expect_equal(read_swat_output(path, chunk_rows = size), expected)
    expect_equal(read_output_chunks(path, size, parse_swat_output_chunk,
                                    buffer_limit = 0), expected)
  }
  for (size in list(0, -1, 1.5, NA_real_, Inf, 100001, c(1, 2), "1")) {
    expect_error(read_swat_output(path, chunk_rows = size), "chunk_rows")
  }
})

test_that("chunk boundaries preserve adjacent native HRU labels", {
  folder <- tempfile(); dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE))
  path <- file.path(folder, "hru_pw_day.txt")
  header <- c("jday", "mon", "day", "yr", "unit", "gis_id", "name",
              paste0("value", 1:25), "plant_cov", "mgt_ops")
  row <- function(i) paste0(
    paste(sprintf("%6d", c(i, 1, i, 2007)), collapse = ""),
    paste(sprintf("%8d", c(1, 0)), collapse = ""), "  ", sprintf("%-16s", "hru001"),
    paste(sprintf("%12.3f", (1:25) + i / 10), collapse = ""), "   ",
    sprintf("%-16s", "abcdefghijklmnop"), sprintf("%-30s", paste0("schedule", i)))
  writeLines(c("fixture", paste(header, collapse = " "), "units",
               vapply(1:5, row, character(1))), path)
  x <- read_swat_output(path, chunk_rows = 2)
  expect_equal(x$day, 1:5)
  expect_equal(x$value25, 25 + (1:5) / 10)
  expect_equal(x$plant_cov, rep("abcdefghijklmnop", 5))
  expect_equal(x$mgt_ops, paste0("schedule", 1:5))
})

test_that("calibration metadata survives annual output chunk boundaries", {
  folder <- tempfile(); dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE))
  path <- file.path(folder, "basin_wb_aa.txt")
  lines <- readLines(test_path("fixtures", "basin_wb_aa.txt"))
  writeLines(c(lines[1:3], rep(lines[4], 3)), path)
  x <- read_swat_output(path, chunk_rows = 1)
  expect_equal(x$precip, rep(792.783, 3))
  expect_equal(x$cal_sim, rep("Original Simulation", 3))
  expect_equal(x$cal_adj, rep(0, 3))
})

test_that("late malformed rows are rejected rather than silently discarded", {
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(c("fixture", "id value", "units", "1 2", "2 3", "3 4 5"), path)
  expect_error(read_swat_output(path, chunk_rows = 2), "mismatch|Cannot safely parse")
  writeLines(c("fixture", "id value", "units", "1 2", "2 3", "3"), path)
  expect_error(read_swat_output(path, chunk_rows = 2), "mismatch|Cannot safely parse")
  writeLines(c("fixture", "id value", "units"), path)
  expect_equal(names(read_swat_output(path)), c("id", "value"))
  expect_equal(nrow(read_swat_output(path)), 0L)
})

test_that("chunked management preserves short operations and literal quotes", {
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  writeLines(c("fixture", "hru year mon day crop/fert/pest operation phubase added",
               "units", "1 2007 4 2 corn PLANT", "2 2007 9 1 corn HARVEST 20 7",
               "3 2007 10 2 crop\"name PLANT"), path)
  x <- read_swat_mgt(path, chunk_rows = 1)
  expect_equal(x$hru, 1:3)
  expect_equal(x$added, c(NA_real_, 7, NA_real_))
  expect_equal(x[["crop/fert/pest"]], c("corn", "corn", 'crop"name'))
  expect_equal(x, read_swat_mgt(path, chunk_rows = 100))
  expect_equal(x, read_output_chunks(path, 1, parse_swat_mgt_chunk, buffer_limit = 0))
})
