test_that("scaffold_lesson produces a checkable lesson", {
  path <- tempfile("rlearnxr-lesson-")
  scaffold_lesson(path, title = "Test lesson")
  data <- data.frame(x = c(-1, 0, 1), y = c(1, -1, 0), z = c(0, 0, 1))
  render_scene(data, "x", "y", "z", output_dir = file.path(path, "scene"))
  writeLines("Generated test data under CC0.", file.path(path, "DATA_LICENSE.md"))

  result <- check_lesson(path, write_report = TRUE)
  expect_false(any(result$status == "FAIL"))
  expect_true(file.exists(file.path(path, "checks", "reproducibility-report.md")))
  expect_true(file.exists(file.path(path, "checks", "reproducibility-report.json")))
  expect_true(file.exists(file.path(path, "checks", "session-info.txt")))
  expect_true(file.exists(file.path(path, "renv.lock")))
  expect_true(file.exists(file.path(path, "lesson-manifest.json")))
  manifest <- read_lesson_manifest(path)
  expect_equal(manifest$manifest_version, "1.0")
  expect_equal(manifest$r_contract$required_columns, c("label", "x", "y", "z"))

  strict <- check_lesson(path, write_report = FALSE, strict = TRUE)
  expect_true(any(strict$status == "FAIL" & strict$check == "data_license"))
})

test_that("lesson bundles preserve manifest and portable learning receipts", {
  path <- tempfile("rlearnxr-bundle-source-")
  scaffold_lesson(path, title = "Bridge lesson")
  data <- data.frame(label = c("a", "b", "c"), x = c(-1, 0, 1), y = c(1, 0, -1), z = c(0, 1, 0))
  render_scene(data, "x", "y", "z", labels = data$label, output_dir = file.path(path, "scene"))
  writeLines("Source: DataSandbox synthetic dataset. License: CC BY 4.0.", file.path(path, "DATA_LICENSE.md"))
  write_learning_receipt(path, attempt_number = 2, prediction = "clustered", explanation = "The middle point is elevated", outcome = "complete")
  bundle <- export_lesson_bundle(path, output = tempfile("rlearnxr-bundle-export-"))
  expect_true(file.exists(file.path(bundle, "lesson-manifest.json")))
  expect_true(file.exists(file.path(bundle, "checks", "learning-receipt.json")))
  portable <- tempfile(fileext = ".json")
  portable_payload <- list(
    schema_version = "rlearnxr-bundle-1",
    files = list(
      "lesson-manifest.json" = paste(readLines(file.path(path, "lesson-manifest.json"), warn = FALSE), collapse = "\n"),
      "data/source.csv" = "label,x,y,z\na,-1,1,0\nb,0,0,1\nc,1,-1,0\n"
    )
  )
  jsonlite::write_json(portable_payload, portable, auto_unbox = TRUE, pretty = TRUE)
  imported <- import_datasandbox_bundle(portable, output = tempfile("rlearnxr-import-"))
  expect_true(file.exists(file.path(imported, "lesson-manifest.json")))
  expect_true(file.exists(file.path(imported, "data", "source.csv")))
})
