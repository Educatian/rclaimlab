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
  expect_match(html, "learning-analytics/scene/index.html")
  expect_match(html, "edm-patterns/scene/index.html")
  expect_true(all(vapply(catalog$modules, function(module) identical(module$status, "ready"), logical(1))))
})

test_that("course catalog rejects duplicate module ids", {
  catalog <- default_course_catalog()
  catalog$modules[[2]]$id <- catalog$modules[[1]]$id
  expect_error(validate_course_catalog(catalog), "unique")
})
