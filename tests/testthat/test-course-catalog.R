test_that("default course catalog validates and renders a complete static home", {
  catalog <- default_course_catalog()
  expect_true(validate_course_catalog(catalog))
  output <- tempfile("rlearnxr-course-")
  files <- render_course_catalog(catalog, output, overwrite = TRUE)
  expect_true(file.exists(files$index))
  expect_true(file.exists(files$catalog))
  html <- paste(readLines(files$index, warn = FALSE), collapse = "\n")
  expect_match(html, "RLEARNXR_CATALOG")
  expect_match(html, "local progress")
  expect_match(html, "statistics-pca")
})

test_that("course catalog rejects duplicate module ids", {
  catalog <- default_course_catalog()
  catalog$modules[[2]]$id <- catalog$modules[[1]]$id
  expect_error(validate_course_catalog(catalog), "unique")
})
