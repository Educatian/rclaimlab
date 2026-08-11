test_that("scaffold_lesson produces a checkable lesson", {
  path <- tempfile("rlearnxr-lesson-")
  scaffold_lesson(path, title = "Test lesson")
  data <- data.frame(x = c(-1, 1), y = c(1, -1), z = c(0, 0))
  render_scene(data, "x", "y", "z", output_dir = file.path(path, "scene"))
  writeLines("Generated test data under CC0.", file.path(path, "DATA_LICENSE.md"))

  result <- check_lesson(path, write_report = TRUE)
  expect_false(any(result$status == "FAIL" & result$check != "environment_lock"))
  expect_true(file.exists(file.path(path, "checks", "reproducibility-report.md")))
  expect_true(file.exists(file.path(path, "checks", "session-info.txt")))
})
