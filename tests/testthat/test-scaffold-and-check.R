test_that("scaffold_lesson produces a checkable lesson", {
  path <- tempfile("rclaimlab-lesson-")
  scaffold_lesson(path, title = "Test lesson")
  data <- data.frame(x = c(-1, 0, 1), y = c(1, -1, 0), z = c(0, 0, 1))
  render_scene(data, "x", "y", "z", output_dir = file.path(path, "scene"))
  writeLines("Generated test data under CC0.", file.path(path, "DATA_LICENSE.md"))

  result <- check_lesson(path, write_report = TRUE)
  expect_false(any(result$status == "FAIL"))
  expect_true(all(c("manifest_contract", "static_fallback", "ai_safety_markers") %in% result$check))
  expect_true(file.exists(file.path(path, "checks", "reproducibility-report.md")))
  expect_true(file.exists(file.path(path, "checks", "reproducibility-report.json")))
  expect_true(file.exists(file.path(path, "checks", "session-info.txt")))
  report <- jsonlite::read_json(file.path(path, "checks", "reproducibility-report.json"), simplifyVector = TRUE)
  expect_identical(report$path, ".")
  expect_false(grepl(normalizePath(path, winslash = "/"), paste(readLines(file.path(path, "checks", "reproducibility-report.json")), collapse = "\n"), fixed = TRUE))
  expect_true(file.exists(file.path(path, "renv.lock")))
  expect_true(file.exists(file.path(path, "lesson-manifest.json")))
  manifest <- read_lesson_manifest(path)
  expect_true(validate_lesson_manifest(manifest))
  expect_equal(manifest$manifest_version, "2.0")
  expect_equal(manifest$r_contract$required_columns, c("label", "x", "y", "z"))

  strict <- check_lesson(path, write_report = FALSE, strict = TRUE)
  expect_true(any(strict$status == "FAIL" & strict$check == "data_license"))
})

test_that("validate_lesson_manifest rejects unsafe artifact paths", {
  manifest <- list(
    manifest_version = "2.0", lesson_id = "x", title = "x",
    r_contract = list(required_columns = c("label", "x", "y", "z")),
    reproducibility = list(seed = 2026, web_r_version = "0.6.0"),
    privacy = list(storage = "browser-local", export_consent_required = TRUE),
    education = list(audience = "learners", estimated_minutes = 15,
                     objectives = c("a", "b", "c")),
    evidence = list(schema_version = "rclaimlab-evidence-2", artifact = "scene/evidence.json"),
    artifacts = list(lesson_entrypoint = "../outside.qmd", scene = "scene/index.html", points = "scene/points.json", evidence = "scene/evidence.json")
  )
  expect_error(validate_lesson_manifest(manifest), "relative")
})

test_that("lesson bundles preserve manifest and portable learning receipts", {
  path <- tempfile("rclaimlab-bundle-source-")
  scaffold_lesson(path, title = "Bridge lesson")
  data <- data.frame(label = c("a", "b", "c"), x = c(-1, 0, 1), y = c(1, 0, -1), z = c(0, 1, 0))
  render_scene(data, "x", "y", "z", labels = data$label, output_dir = file.path(path, "scene"))
  writeLines("Source: DataSandbox synthetic dataset. License: CC BY 4.0.", file.path(path, "DATA_LICENSE.md"))
  write_learning_receipt(path, attempt_number = 2, prediction = "clustered", explanation = "The middle point is elevated", outcome = "complete")
  expect_true(validate_learning_receipt(file.path(path, "checks", "learning-receipt.json")))
  bundle <- export_lesson_bundle(path, output = tempfile("rclaimlab-bundle-export-"))
  expect_true(file.exists(file.path(bundle, "lesson-manifest.json")))
  expect_true(file.exists(file.path(bundle, "checks", "learning-receipt.json")))
  portable <- tempfile(fileext = ".json")
  portable_payload <- list(
    schema_version = "rclaimlab-bundle-1",
    files = list(
      "lesson-manifest.json" = paste(readLines(file.path(path, "lesson-manifest.json"), warn = FALSE), collapse = "\n"),
      "data/source.csv" = "label,x,y,z\na,-1,1,0\nb,0,0,1\nc,1,-1,0\n"
    )
  )
  jsonlite::write_json(portable_payload, portable, auto_unbox = TRUE, pretty = TRUE)
  imported <- import_datasandbox_bundle(portable, output = tempfile("rclaimlab-import-"))
  expect_true(file.exists(file.path(imported, "lesson-manifest.json")))
  expect_true(file.exists(file.path(imported, "data", "source.csv")))
})
