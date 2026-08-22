test_that("Evidence IR preserves stable linked identifiers", {
  input <- data.frame(a = c(1, 2, 3), b = c(4, 5, 6), c = c(7, 8, 9))
  evidence <- as_rclaimlab_evidence(input, labels = c("alpha", "beta", "gamma"), seed = 77)

  expect_s3_class(evidence, "rclaimlab_evidence")
  expect_true(validate_rclaimlab_evidence(evidence))
  expect_equal(evidence$schema_version, "rclaimlab-evidence-2")
  expect_equal(evidence$observations$observation_id, sprintf("obs-%04d", 1:3))
  expect_equal(evidence$dimensions$dimension_id, sprintf("dim-%03d", 1:3))
  expect_equal(nrow(evidence$values), 9)
  expect_equal(evidence$values$evidence_id, evidence$links$evidence_id)
  expect_equal(evidence$analysis$artifact_hash,
               as_rclaimlab_evidence(input, labels = c("alpha", "beta", "gamma"), seed = 77)$analysis$artifact_hash)

  path <- tempfile(fileext = ".json")
  write_rclaimlab_evidence(evidence, path)
  restored <- read_rclaimlab_evidence(path)
  expect_equal(restored$analysis$artifact_hash, evidence$analysis$artifact_hash)
  expect_equal(as.data.frame(restored)$label, c("alpha", "beta", "gamma"))
})

test_that("all model and foundational adapters satisfy the Evidence IR contract", {
  pca <- stats::prcomp(iris[1:12, 1:4], scale. = TRUE)
  regression <- stats::lm(mpg ~ wt + hp, data = mtcars)
  classification <- stats::glm(am ~ wt + hp, data = mtcars, family = stats::binomial())
  set.seed(2026)
  clusters <- stats::kmeans(iris[1:20, 1:4], centers = 3)
  analysis_of_variance <- stats::aov(mpg ~ factor(cyl), data = mtcars)
  bootstrap <- bootstrap_mean(mtcars$mpg, times = 40, seed = 2026)

  adapters <- list(
    data.frame = as_rclaimlab_evidence(iris[1:12, 1:4]),
    prcomp = as_rclaimlab_evidence(pca),
    lm = as_rclaimlab_evidence(regression),
    glm = as_rclaimlab_evidence(classification),
    kmeans = as_rclaimlab_evidence(clusters, data = iris[1:20, 1:4]),
    numeric_summary = as_rclaimlab_evidence(mtcars$mpg, variable = "mpg"),
    table = as_rclaimlab_evidence(table(iris$Species)),
    aov = as_rclaimlab_evidence(analysis_of_variance),
    bootstrap_mean = as_rclaimlab_evidence(bootstrap)
  )

  expect_named(adapters, c("data.frame", "prcomp", "lm", "glm", "kmeans", "numeric_summary", "table", "aov", "bootstrap_mean"))
  for (name in names(adapters)) {
    expect_true(validate_rclaimlab_evidence(adapters[[name]]), info = name)
    expect_equal(adapters[[name]]$analysis$engine, name, info = name)
    expect_true(nzchar(adapters[[name]]$analysis$artifact_hash), info = name)
  }
  expect_true(all(c("loadings", "explained_variance", "scale") %in% names(adapters$prcomp$metadata)))
  expect_true(all(c("fitted", "residual", "interval_low") %in% adapters$lm$dimensions$label))
  expect_true(all(c("predicted_probability", "predicted_class") %in% adapters$glm$dimensions$label))
  expect_true(all(c("accuracy", "sensitivity", "specificity", "brier_score") %in% names(adapters$glm$metadata$classification)))
  expect_true(all(c("cluster", "distance_to_centroid") %in% adapters$kmeans$dimensions$label))
  expect_equal(length(adapters$kmeans$metadata$stability$agreement), 5)
  expect_true(adapters$kmeans$metadata$stability$minimum >= 0 && adapters$kmeans$metadata$stability$minimum <= 1)
})

test_that("invalid analytical evidence fails early", {
  expect_error(as_rclaimlab_evidence(data.frame(a = numeric(), b = numeric())), "empty")
  expect_error(as_rclaimlab_evidence(data.frame(a = 1:3, b = c(1, NA, 3))), "NA")
  expect_error(as_rclaimlab_evidence(data.frame(a = 1:3, b = 4:6), labels = c("x", "x", "z")), "unique")
  expect_s3_class(as_rclaimlab_evidence(data.frame(a = 1:3, text = letters[1:3])), "rclaimlab_evidence")
})

test_that("adapter builder normalizes default roles and named units", {
  evidence <- rclaimlab:::build_rclaimlab_evidence(
    data.frame(a = 1:3, b = 4:6), labels = c("a", "b", "c"),
    engine = "fixture", analysis_call = "fixture()", seed = 2026,
    roles = NULL, units = c(b = "seconds", a = "count")
  )
  expect_equal(evidence$dimensions$role, c("variable", "variable"))
  expect_equal(evidence$dimensions$unit, c("count", "seconds"))
})

test_that("lesson compiler creates a complete canonical vertical slice", {
  evidence <- as_rclaimlab_evidence(
    stats::prcomp(iris[1:15, 1:4], scale. = TRUE),
    labels = paste0("iris-", seq_len(15))
  )
  stages <- c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
  tasks <- lapply(stages, function(stage) {
    task_spec(paste0("pca-", stage), stage, paste("Complete the", stage, "stage"),
              criteria = stats::setNames("Cites linked evidence", "evidence"))
  })
  lesson <- lesson_spec(
    "canonical-pca", "Canonical PCA evidence lesson",
    outcomes = c("Explain one PCA score", "Transfer the interpretation"),
    evidence = evidence, tasks = tasks
  )
  output <- tempfile("rclaimlab-compiled-")
  build <- compile_lesson(lesson, output)

  expect_s3_class(build, "rclaimlab_build")
  expect_true(all(file.exists(build$files)))
  expect_false(any(build$checks$status == "FAIL"))
  expect_equal(read_lesson_manifest(output)$manifest_version, "2.0")
  expect_equal(read_rclaimlab_evidence(file.path(output, "evidence.json"))$analysis$artifact_hash,
               evidence$analysis$artifact_hash)
  points <- jsonlite::fromJSON(file.path(output, "scene", "points.json"), simplifyVector = FALSE)
  expect_equal(points[[1]]$observation_id, "obs-0001")
  expect_true(length(points[[1]]$evidence_ids) >= 2)
  expect_equal(as.data.frame(lesson)$task_type, stages)
})

test_that("version 2 receipts preserve learning and reproducibility evidence", {
  path <- tempfile("rclaimlab-receipt-")
  dir.create(path)
  receipt <- write_learning_receipt(
    path, attempt_number = 2,
    orientation = list(goal = TRUE), prediction = "PC1 separates the groups",
    explanation = "Observation one has a high PC1 score.",
    explanation_criteria = list(claim = TRUE, evidence = TRUE, limitation = TRUE),
    evidence_point = list(observation_id = "obs-0001", evidence_ids = c("ev-0001-001", "ev-0001-002")),
    transfer_response = "The second case follows the same pattern.",
    evidence_hash = "abc123", outcome = "complete"
  )
  expect_s3_class(receipt, "rclaimlab_receipt")
  expect_true(validate_learning_receipt(receipt))
  restored <- read_learning_receipt(path)
  expect_equal(restored$schema_version, "rclaimlab-receipt-2")
  expect_equal(restored$evidence$artifact_hash, "abc123")
  expect_equal(as.data.frame(restored)$outcome, "complete")
})

test_that("compiler-owned analytical artifacts are deterministic", {
  evidence <- as_rclaimlab_evidence(iris[1:8, 1:3], seed = 2026)
  lesson <- lesson_spec(
    "deterministic", "Deterministic build",
    outcomes = c("Explain evidence", "Repair a claim", "Transfer reasoning"),
    evidence = evidence,
    tasks = list(task_spec("orient", "orient", "Orient"))
  )
  first <- tempfile("build-first-")
  second <- tempfile("build-second-")
  compile_lesson(lesson, first)
  compile_lesson(lesson, second)
  stable_files <- c("evidence.json", "lesson-spec.json", "scene/points.json", "scene/evidence.json", "scene/index.html")
  first_hashes <- unname(tools::md5sum(file.path(first, stable_files)))
  second_hashes <- unname(tools::md5sum(file.path(second, stable_files)))
  expect_equal(first_hashes, second_hashes)
})
