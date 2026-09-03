test_that('file.cio entries are changed by section and extra entries survive', {
  lines <- c('header', 'lum old.sch management.sch a b c extra',
             'simulation time.sim print.prt null object.cnt null future')
  updated <- swat_cio_set(lines, 'simulation', 3L, 'object.prt')
  expect_identical(updated[2], lines[2])
  expect_identical(strsplit(updated[3], ' ')[[1]],
                   c('simulation','time.sim','print.prt','object.prt','object.cnt','null','future'))
  expect_error(swat_cio_set(lines, 'missing', 1L, 'x'), 'Missing')
  expect_error(swat_cio_set(lines, 'lum', 20L, 'x'), 'Missing entries')
})
