test_that("evidence adapters reject malformed method inputs", {
  expect_error(as_rclaimlab_evidence(structure(list(), class = "unknown_model")), "no R-ClaimLab")
  expect_equal(nrow(as_rclaimlab_evidence(data.frame(a = 1:3, b = 4:6), dimensions = "a")$dimensions), 1)
  expect_error(as_rclaimlab_evidence(data.frame(a = 1:3, b = letters[1:3]), dimensions = c("a", "b")), "numeric")

  pca <- stats::prcomp(iris[1:6, 1:4])
  expect_error(as_rclaimlab_evidence(pca, components = "PC1"), "two")
  factor_lm <- suppressWarnings(stats::lm(Species ~ Sepal.Length, data = iris))
  expect_error(as_rclaimlab_evidence(factor_lm), "numeric response")

  model <- stats::glm(am ~ wt, data = mtcars, family = stats::binomial())
  expect_error(as_rclaimlab_evidence(model, threshold = 0), "between")
  expect_error(as_rclaimlab_evidence(model, threshold = c(.4, .6)), "one number")

  set.seed(9)
  km <- stats::kmeans(iris[1:10, 1:4], centers = 2)
  expect_error(as_rclaimlab_evidence(km, data = iris[1:9, 1:4]), "rows")
  expect_error(as_rclaimlab_evidence(km, data = iris[1:10, 1:4], dimensions = "Sepal.Length"), "two")
  broken <- iris[1:10, 1:4]
  broken[1, 1] <- Inf
  expect_error(as_rclaimlab_evidence(km, data = broken), "non-finite")
})

test_that("Evidence IR validator identifies each broken link", {
  evidence <- as_rclaimlab_evidence(iris[1:5, 1:3])
  expect_output(print(evidence), "rclaimlab_evidence")
  expect_equal(summary(evidence)$observations, 5)

  png <- tempfile(fileext = ".png")
  grDevices::png(png)
  expect_invisible(plot(evidence))
  grDevices::dev.off()
  expect_true(file.exists(png))
  expect_error(plot(evidence, x_dimension = "missing"), "not found")

  broken <- unclass(evidence)
  expect_error(validate_rclaimlab_evidence(broken), "must be")
  broken <- evidence; broken$schema_version <- "old"
  expect_error(validate_rclaimlab_evidence(broken), "unsupported")
  broken <- evidence; broken$analysis$artifact_hash <- NULL
  expect_error(validate_rclaimlab_evidence(broken), "incomplete")
  broken <- evidence; broken$observations$observation_id[2] <- broken$observations$observation_id[1]
  expect_error(validate_rclaimlab_evidence(broken), "unique")
  broken <- evidence; broken$values$observation_id[1] <- "missing"
  expect_error(validate_rclaimlab_evidence(broken), "dangling")
  broken <- evidence; broken$links$evidence_id[1] <- "wrong"
  expect_error(validate_rclaimlab_evidence(broken), "synchronized")
  broken <- evidence; broken$values$value[1] <- Inf
  expect_error(validate_rclaimlab_evidence(broken), "finite")

  expect_error(read_rclaimlab_evidence(tempfile()), "not found")
  file <- tempfile(fileext = ".json")
  write_rclaimlab_evidence(evidence, file)
  expect_error(write_rclaimlab_evidence(evidence, file), "already exists")
})

test_that("lesson specifications enforce the educational sequence", {
  criterion <- c(link = "Cite one evidence value")
  orient <- task_spec("o", "orient", "State the question", criterion, evidence_required = FALSE)
  predict <- task_spec("p", "predict", "Make a prediction", criterion)
  expect_false(orient$evidence_required)
  expect_error(task_spec("", "orient", "Prompt"), "id")
  expect_error(task_spec("x", "orient", " "), "prompt")
  expect_error(task_spec("x", "orient", "Prompt", "unnamed"), "named")

  expect_equal(representation_spec("table")$title, "Evidence table")
  expect_error(representation_spec("plot2d", dimensions = ""), "non-empty")
  expect_error(representation_spec("scene3d", title = " "), "title")

  evidence <- as_rclaimlab_evidence(iris[1:5, 1:3])
  lesson <- lesson_spec("l", "Lesson", c("Explain evidence"), evidence, list(orient, predict))
  expect_output(print(lesson), "rclaimlab_lesson")
  expect_equal(summary(lesson)$evidence_hash, evidence$analysis$artifact_hash)
  expect_equal(nrow(as.data.frame(lesson)), 2)
  expect_error(lesson_spec("l", "Lesson", character()), "outcomes")
  expect_error(lesson_spec("l", "Lesson", "Outcome", evidence = list()), "evidence")
  expect_error(lesson_spec("l", "Lesson", "Outcome", tasks = list(list())), "tasks")
  expect_error(lesson_spec("l", "Lesson", "Outcome", representations = list()), "representations")
  expect_error(lesson_spec("l", "Lesson", "Outcome", accessibility = list()), "accessibility")
  expect_error(lesson_spec("l", "Lesson", "Outcome", content_license = " "), "content_license")

  broken <- unclass(lesson)
  expect_error(validate_lesson_spec(broken), "must be")
  broken <- lesson; broken$schema_version <- "old"
  expect_error(validate_lesson_spec(broken), "unsupported")
  broken <- lesson; broken$tasks[[2]]$id <- "o"
  expect_error(validate_lesson_spec(broken), "unique")
  reversed <- lesson; reversed$tasks <- rev(reversed$tasks)
  expect_error(validate_lesson_spec(reversed), "sequence")
})

test_that("compiler and build methods cover overwrite and summary contracts", {
  evidence <- as_rclaimlab_evidence(iris[1:6, 1:3])
  tasks <- list(task_spec("o", "orient", "Orient"), task_spec("e", "explain", "Explain"))
  lesson <- lesson_spec("build", "Build lesson", c("Explain", "Repair", "Transfer"), evidence, tasks)
  output <- tempfile("compiler-edge-")
  build <- compile_lesson(lesson, output)
  expect_output(print(build), "rclaimlab_build")
  expect_equal(summary(build)$lesson_id, "build")
  expect_true(all(as.data.frame(build)$exists))
  expect_error(compile_lesson(lesson, output), "already exist")
  expect_s3_class(compile_lesson(lesson, output, overwrite = TRUE), "rclaimlab_build")
  empty <- lesson_spec("empty", "Empty", "Outcome")
  expect_error(compile_lesson(empty, tempfile()), "evidence is required")
  expect_error(compile_lesson(list(), tempfile()), "must be")
})

test_that("version 2 manifest validator reports contract errors", {
  path <- tempfile("manifest-edge-")
  dir.create(path)
  manifest_path <- write_lesson_manifest(path, title = "Manifest edge")
  expect_true(file.exists(manifest_path))
  expect_error(write_lesson_manifest(path, overwrite = FALSE), "already exists")
  expect_error(read_lesson_manifest(tempfile()), "not found")
  manifest <- read_lesson_manifest(path)

  mutate_error <- function(expr, message) expect_error(validate_lesson_manifest(expr), message)
  broken <- manifest; broken$title <- NULL; mutate_error(broken, "missing")
  broken <- manifest; broken$manifest_version <- "1.0"; mutate_error(broken, "expected 2.0")
  broken <- manifest; broken$r_contract$required_columns <- "x"; mutate_error(broken, "r_contract")
  broken <- manifest; broken$reproducibility$seed <- NULL; mutate_error(broken, "reproducibility")
  broken <- manifest; broken$privacy$storage <- NULL; mutate_error(broken, "privacy")
  broken <- manifest; broken$evidence$schema_version <- "old"; mutate_error(broken, "evidence")
  broken <- manifest; broken$education$objectives <- character(); mutate_error(broken, "education")
  broken <- manifest; broken$artifacts$evidence <- NULL; mutate_error(broken, "artifacts")
  broken <- manifest; broken$artifacts$scene <- "../outside.html"; mutate_error(broken, "relative")
})

test_that("version 2 receipt methods reject malformed attempts", {
  path <- tempfile("receipt-edge-")
  dir.create(path)
  input <- file.path(path, "input.csv")
  writeLines("x\n1", input)
  receipt <- write_learning_receipt(path, input_data = input, evidence_hash = "hash", outcome = "complete")
  expect_output(print(receipt), "rclaimlab_receipt")
  expect_equal(summary(receipt)$evidence_hash, "hash")
  expect_error(write_learning_receipt(path, overwrite = FALSE), "already exists")
  expect_error(read_learning_receipt(tempfile()), "not found")

  broken <- receipt; broken$prediction <- NULL
  expect_error(validate_learning_receipt(broken), "missing")
  broken <- receipt; broken$receipt_version <- "1.0"
  expect_error(validate_learning_receipt(broken), "unsupported")
  broken <- receipt; broken$attempt_number <- NA
  expect_error(validate_learning_receipt(broken), "integer")
  broken <- receipt; broken$reproducibility$seed <- NULL
  expect_error(validate_learning_receipt(broken), "reproducibility")
  broken <- receipt; broken$privacy$storage <- NULL
  expect_error(validate_learning_receipt(broken), "privacy")
})
