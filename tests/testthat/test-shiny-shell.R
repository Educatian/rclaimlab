test_that("optional Shiny shell is exported without becoming a core dependency", {
  expect_true(is.function(run_rclaimlab_shiny))
  description <- utils::packageDescription("rclaimlab")
  expect_match(unname(description[["Suggests"]]), "shiny")
})

test_that("Shiny shell reports its optional dependency clearly", {
  skip_if(requireNamespace("shiny", quietly = TRUE))
  expect_error(
    run_rclaimlab_shiny(launch.browser = FALSE),
    "optional Shiny shell requires"
  )
})

test_that("Shiny educator app can be constructed without launching a browser", {
  skip_if_not_installed("shiny")
  app <- rclaimlab:::build_rclaimlab_shiny_app(catalog = default_course_catalog())
  expect_s3_class(app, "shiny.appobj")
  expect_true(is.function(app$serverFuncSource))
  expect_error(rclaimlab:::build_rclaimlab_shiny_app(lesson_dir = tempfile()), "does not exist")
})
