edge_workflow_data <- function(rows = 90L) {
  data.frame(
    x = seq_len(rows),
    z = round(sin(seq_len(rows) / 5), 4),
    category = rep(c("a", "b", "c"), length.out = rows),
    group = rep(c("A", "B"), length.out = rows),
    outcome = factor(ifelse(seq_len(rows) %% 4L == 0L, "event", "reference")),
    score = 2 + seq_len(rows) * .2 + cos(seq_len(rows) / 3),
    stringsAsFactors = FALSE
  )
}

edge_dataset <- function(rows = 90L) {
  path <- tempfile("edge-data-", fileext = ".csv")
  utils::write.csv(edge_workflow_data(rows), path, row.names = FALSE)
  import_dataset(dataset_source("local", path))
}

test_that("dataset constructors and S3 summaries expose the contract", {
  path <- tempfile(fileext = ".csv")
  utils::write.csv(edge_workflow_data(), path, row.names = FALSE)
  source <- dataset_source("local", path)
  manifest <- inspect_dataset(source)
  dataset <- import_dataset(source)

  expect_output(print(source), "rclaimlab_dataset_source")
  expect_equal(summary(source)$provider, "local")
  expect_output(print(manifest), "rclaimlab_dataset_manifest")
  expect_equal(summary(manifest)$files, 1L)
  expect_equal(nrow(as.data.frame(manifest)), 1L)
  expect_output(print(dataset), "rclaimlab_dataset")
  expect_equal(summary(dataset)$rows, 90L)
  expect_equal(as.data.frame(dataset), dataset$data)
  expect_equal(profile_dataset(dataset)$source$id, basename(path))

  expect_error(rclaimlab:::validate_dataset_source(list()), "valid")
  bad_manifest <- manifest
  bad_manifest$schema_version <- "wrong"
  expect_error(rclaimlab:::validate_dataset_manifest(bad_manifest), "does not satisfy")
  bad_dataset <- dataset
  bad_dataset$source_record_id[[2]] <- bad_dataset$source_record_id[[1]]
  expect_error(rclaimlab:::validate_rclaimlab_dataset(bad_dataset), "does not satisfy")
})

test_that("dataset limits, parsing, selection, and seed helpers fail safely", {
  source <- dataset_source("local", tempfile())
  expect_error(import_dataset(source, max_download_mb = 0), "positive number")
  expect_error(rclaimlab:::select_tabular_file(character()), "no CSV")
  expect_error(rclaimlab:::select_tabular_file(c("a.csv", "b.csv")), "multiple")
  expect_equal(rclaimlab:::select_tabular_file(c("a.csv", "b.tsv"), "b.tsv"), "b.tsv")
  expect_error(rclaimlab:::select_tabular_file(c("a.csv", "b.tsv"), "c.csv"), "not found")
  expect_true(is.na(rclaimlab:::collapse_metadata_text(NULL)))
  expect_true(is.na(rclaimlab:::collapse_metadata_text("  ")))
  expect_equal(rclaimlab:::collapse_metadata_text(list("a", "b")), "a; b")

  unsupported <- tempfile(fileext = ".txt")
  writeLines(c("x", "1"), unsupported)
  expect_error(rclaimlab:::read_tabular_file(unsupported), "CSV, TSV, and Parquet")
  tiny <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(x = 1), tiny, row.names = FALSE)
  expect_error(rclaimlab:::read_tabular_file(tiny), "at least two rows")

  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  original_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  first <- rclaimlab:::with_preserved_seed(7L, stats::runif(3))
  second <- rclaimlab:::with_preserved_seed(7L, stats::runif(3))
  expect_equal(first, second)
  if (had_seed) expect_equal(get(".Random.seed", envir = .GlobalEnv), original_seed)
  else expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  expect_match(rclaimlab:::dataset_cache_dir(
    list(provider = "x", id = "y", file = NULL),
    list(provider = "x", id = "y", revision = "1"), FALSE
  ), "rclaimlab-dataset")

  selected_path <- tempfile(fileext = ".csv")
  utils::write.csv(edge_workflow_data(20L), selected_path, row.names = FALSE)
  selected <- import_dataset(dataset_source("local", selected_path), columns = c("x", "z"))
  expect_equal(names(selected$data), c("x", "z"))
  expect_error(import_dataset(dataset_source("local", selected_path), columns = character()), "must name")
  expect_s3_class(profile_dataset(edge_workflow_data(20L)), "rclaimlab_data_profile")

  duplicated <- data.frame(x = 1:2, y = 3:4, check.names = FALSE)
  names(duplicated) <- c("x", "x")
  expect_error(rclaimlab:::reject_unsupported_tabular_data(duplicated), "unique")
  if (!nzchar(Sys.which("kaggle"))) {
    expect_error(rclaimlab:::kaggle_executable(), "official 'kaggle' CLI")
  }
  expect_error(rclaimlab:::http_json("https://example.invalid", attempts = 0L), "1 to 3")
})

test_that("Hugging Face provider contract works from deterministic API fixtures", {
  mock_http_json <- function(url, simplify = TRUE) {
    if (grepl("/is-valid", url, fixed = TRUE)) return(list(viewer = TRUE, preview = TRUE, parquet = TRUE))
    if (grepl("/splits", url, fixed = TRUE)) return(list(splits = data.frame(
      dataset = "owner/data", config = "default", split = "train", stringsAsFactors = FALSE
    )))
    if (grepl("/size", url, fixed = TRUE)) return(list(size = list(dataset = list(num_rows = 100L))))
    if (grepl("/parquet", url, fixed = TRUE)) return(list(parquet_files = data.frame(
      dataset = "owner/data", config = "default", split = "train",
      url = "https://example.org/train.parquet", filename = "train.parquet", size = 1000,
      stringsAsFactors = FALSE
    )))
    if (grepl("/statistics", url, fixed = TRUE)) return(list(num_examples = 100L))
    if (grepl("/rows", url, fixed = TRUE)) return(list(rows = list(
      list(row = list(x = 1, label = "a")), list(row = list(x = 2, label = "b"))
    )))
    if (grepl("huggingface.co/api/datasets", url, fixed = TRUE)) return(list(
      sha = "abc123", tags = c("license:cc0-1.0"), cardData = list(license = "cc0-1.0", citation = "Fixture citation"),
      siblings = data.frame(rfilename = c("README.md", "data.csv"), stringsAsFactors = FALSE)
    ))
    stop("unexpected fixture URL")
  }
  testthat::local_mocked_bindings(http_json = mock_http_json, .package = "rclaimlab")

  source <- dataset_source("huggingface", "owner/data", split = "train")
  manifest <- inspect_dataset(source)
  expect_false(manifest$publishable)
  expect_equal(manifest$license, "cc0-1.0")
  expect_equal(nrow(preview_dataset(source, 2L)), 2L)

  pinned <- dataset_source("huggingface", "owner/data", revision = "abc123", split = "train", file = "data.csv")
  pinned_manifest <- inspect_dataset(pinned)
  expect_true(pinned_manifest$publishable)
  expect_equal(pinned_manifest$files$file[[1]], "data.csv")

  missing_file <- dataset_source("huggingface", "owner/data", revision = "abc123", file = "missing.csv")
  expect_error(inspect_dataset(missing_file), "does not exist")

  blocked_http <- function(url, simplify = TRUE) {
    if (grepl("huggingface.co/api/datasets", url, fixed = TRUE)) return(list(
      sha = "abc123", cardData = list(license = "mit"), siblings = data.frame(rfilename = "data.csv")
    ))
    if (grepl("/is-valid", url, fixed = TRUE)) return(list(viewer = FALSE, preview = FALSE, parquet = FALSE))
    stop("unexpected")
  }
  testthat::local_mocked_bindings(http_json = blocked_http, .package = "rclaimlab")
  expect_error(inspect_dataset(dataset_source("huggingface", "owner/data")), "cannot serve")
})

test_that("Hugging Face imports and previews preserve the pinned file contract", {
  mock_http_json <- function(url, simplify = TRUE) {
    if (grepl("/is-valid", url, fixed = TRUE)) return(list(viewer = TRUE))
    if (grepl("/splits", url, fixed = TRUE)) return(list(splits = data.frame(dataset = "owner/data", config = "default", split = "train")))
    if (grepl("/parquet", url, fixed = TRUE)) return(list(parquet_files = data.frame()))
    if (grepl("/size", url, fixed = TRUE) || grepl("/statistics", url, fixed = TRUE)) return(list())
    if (grepl("huggingface.co/api/datasets", url, fixed = TRUE)) return(list(
      sha = "abc123", cardData = list(license = "mit", citation = "Fixture"), tags = "license:mit",
      siblings = data.frame(rfilename = "data.csv")
    ))
    stop("unexpected fixture URL")
  }
  mock_download <- function(url, filename, manifest, cache, max_download_mb) list(
    data = edge_workflow_data(30L), file = filename,
    content_md5 = "fixture-md5", cached = TRUE
  )
  testthat::local_mocked_bindings(
    http_json = mock_http_json,
    download_tabular_url = mock_download,
    .package = "rclaimlab"
  )
  source <- dataset_source("huggingface", "owner/data", revision = "abc123", file = "data.csv")
  dataset <- import_dataset(source, max_rows = 20L, sample = "head")
  expect_equal(nrow(dataset$data), 20L)
  expect_true(dataset$import$cached)
  expect_equal(nrow(preview_dataset(source, 3L)), 3L)
})

test_that("archive and row conversion helpers reject unsafe structures", {
  expect_equal(nrow(rclaimlab:::rows_to_data_frame(list(
    list(x = 1, y = "a"), list(x = 2)
  ))), 2L)
  expect_error(rclaimlab:::rows_to_data_frame(list()), "no rows")
  expect_error(rclaimlab:::rows_to_data_frame(list(list(x = list(a = 1)))), "nested")

  destination <- tempfile("unzip-")
  dir.create(destination)
  archive <- tempfile(fileext = ".zip")
  old <- setwd(destination)
  on.exit(setwd(old), add = TRUE)
  writeLines("safe", "safe.txt")
  utils::zip(archive, "safe.txt", flags = "-q")
  expect_true(rclaimlab:::safe_unzip(archive, destination, 1))
  expect_error(rclaimlab:::safe_unzip(archive, destination, 0), "size limit")

  writeLines("nested", "nested.zip")
  nested_archive <- tempfile(fileext = ".zip")
  utils::zip(nested_archive, "nested.zip", flags = "-q")
  expect_error(rclaimlab:::safe_unzip(nested_archive, destination, 1), "nested archives")

  malformed <- charToRaw('{"x":"line\ncontrol"}')
  repaired <- rclaimlab:::escape_json_string_controls(malformed)
  expect_true(jsonlite::validate(repaired))
})

test_that("workflow constructors reject malformed role contracts", {
  expect_error(activity_spec("x", "invalid", "Prompt"), "arg")
  expect_error(activity_spec("x", "frame", "Prompt", criteria = "unnamed"), "named")
  expect_error(activity_spec("x", "frame", "Prompt", depends_on = NA_character_), "non-empty")

  dataset <- edge_dataset()
  workflow <- workflow_from_dataset(dataset, "data_analyst", predictors = c("x", "z"))
  expect_output(print(workflow), "rclaimlab_workflow")
  expect_equal(summary(workflow)$role, "data_analyst")
  expect_equal(nrow(as.data.frame(workflow)), length(workflow$activities))
  expect_error(as_rclaimlab_workflow(1), "no R-ClaimLab")
  expect_error(workflow_from_dataset(dataset, "data_scientist"), "require an outcome")
  expect_error(workflow_from_dataset(dataset, "data_scientist", outcome = "missing"), "not found")
  expect_error(workflow_from_dataset(dataset, "data_scientist", outcome = "score", predictors = "score"), "cannot duplicate")
  expect_error(workflow_from_dataset(dataset, "data_scientist", outcome = "category", analysis = "glm"), "two-level")
  expect_error(workflow_from_dataset(dataset, "data_analyst", predictors = "missing"), "must name")
  expect_error(workflow_from_dataset(dataset, "data_analyst", predictors = "x", slice_by = "missing"), "not found")

  broken <- workflow
  broken$activities[[2]]$input_artifacts <- "missing-artifact"
  expect_error(validate_workflow_spec(broken), "unplanned artifacts")
  expect_error(validate_workflow_spec(list()), "must satisfy")

  base_activity <- activity_spec("frame", "frame", "Frame", evidence_required = FALSE)
  expect_error(workflow_spec("x", "X", "data_analyst", "describe", list(), list(base_activity),
    deliverables = list(output = "Output")), "dataset must")
  expect_error(workflow_spec("x", "X", "data_analyst", "describe", NULL, list("bad"),
    deliverables = list(output = "Output")), "activities must")
  expect_error(workflow_spec("x", "X", "data_analyst", "describe", NULL, list(base_activity),
    representations = list("bad"), deliverables = list(output = "Output")), "representations must")
  expect_error(workflow_spec("x", "X", "data_analyst", "describe", NULL, list(base_activity),
    deliverables = list()), "deliverables must")
  duplicate <- workflow
  duplicate$activities[[2]]$id <- duplicate$activities[[1]]$id
  expect_error(validate_workflow_spec(duplicate), "must be unique")
  incomplete <- workflow
  incomplete$activities <- incomplete$activities[1]
  expect_error(validate_workflow_spec(incomplete), "requires activities")
})

test_that("model workflow edge states and bundle validators are explicit", {
  dataset <- edge_dataset(100L)
  run <- run_workflow(approve_workflow(workflow_from_dataset(
    dataset, "data_scientist", outcome = "score", predictors = c("x", "category"), analysis = "lm"
  )))
  expect_output(print(run), "rclaimlab_workflow_run")
  expect_output(print(run$bundle), "rclaimlab_evidence_bundle")
  expect_equal(summary(run)$execution$mode, "lm")
  expect_equal(summary(run$bundle)$workflow_id, run$workflow$id)
  expect_equal(as.data.frame(run), run$bundle$registry)
  expect_true(validate_evidence_bundle(run$bundle))

  broken <- run$bundle
  broken$registry$artifact_hash[[1]] <- "wrong"
  expect_error(validate_evidence_bundle(broken), "artifact hash")
  expect_error(continue_workflow(structure(list(), class = "rclaimlab_workflow_run")), "legacy")
  expect_error(continue_workflow(list()), "must be")

  auto_lm <- workflow_from_dataset(dataset, "data_scientist", outcome = "score", predictors = c("x", "z"))
  expect_equal(auto_lm$analysis$method, "lm")
  expect_error(workflow_from_dataset(dataset, "data_analyst", predictors = "x", analysis = "lm"), "model workflows require")

  category_only <- edge_dataset()
  analyst <- workflow_from_dataset(category_only, "data_analyst", predictors = "category")
  expect_s3_class(run_workflow(approve_workflow(analyst)), "rclaimlab_workflow_run")

  direct_reviewer <- workflow_from_dataset(
    edge_dataset(160L), "model_reviewer", outcome = "outcome",
    predictors = c("x", "z"), analysis = "glm"
  )
  direct_review_run <- run_workflow(approve_workflow(direct_reviewer))
  expect_true(all(c("model-evidence", "review-evidence") %in% names(direct_review_run$bundle$artifacts)))

  slice_dataset <- edge_dataset(300L)
  sliced <- run_workflow(approve_workflow(workflow_from_dataset(
    slice_dataset, "data_scientist", outcome = "outcome",
    predictors = c("x", "z"), slice_by = "group", analysis = "glm"
  )))
  expect_length(sliced$bundle$artifacts[["model-evidence"]]$metadata$workflow$slices$results, 2L)

  insufficient <- edge_dataset(25L)
  insufficient$data$category[1:24] <- NA_character_
  bad_workflow <- workflow_from_dataset(insufficient, "data_scientist", outcome = "outcome",
    predictors = "category", analysis = "glm")
  expect_error(run_workflow(approve_workflow(bad_workflow)), "too few complete rows")

  expect_error(rclaimlab:::validate_evidence_bundle(list()), "must satisfy")
  expect_error(rclaimlab:::workflow_split(factor(c("a", "b")), "glm", 1L), "fewer than two")
  expect_s3_class(rclaimlab:::ensure_binary_factor(c("a", "b")), "factor")
})

test_that("workflow receipts cover conversion, summaries, and privacy failures", {
  dataset <- edge_dataset()
  run <- run_workflow(approve_workflow(workflow_from_dataset(
    dataset, "data_scientist", outcome = "outcome", predictors = c("x", "z"), analysis = "glm"
  )))
  path <- tempfile("receipt-")
  receipt <- write_workflow_receipt(run, path, attempt_number = 2L, approval = "pending")
  expect_output(print(receipt), "rclaimlab_workflow_receipt")
  expect_equal(summary(receipt)$attempt_number, 2L)
  expect_equal(as.data.frame(receipt)$role, "data_scientist")
  expect_error(write_workflow_receipt(run, path, overwrite = FALSE), "already exists")
  expect_error(write_workflow_receipt(run, tempfile(), attempt_number = 0), "positive integer")
  expect_error(read_workflow_receipt(tempfile()), "not found")

  bad <- receipt
  bad$privacy$telemetry <- TRUE
  expect_error(validate_workflow_receipt(bad), "disable telemetry")
  bad <- receipt
  bad$role <- "unknown"
  expect_error(validate_workflow_receipt(bad), "unsupported role")
  bad <- receipt
  bad$evidence$bundle_hash <- ""
  expect_error(validate_workflow_receipt(bad), "bundle hash")
  expect_error(validate_workflow_receipt(list()), "must satisfy")
  bad <- receipt
  bad$claims <- list(secret = "OPENAI_API_KEY=do-not-store")
  expect_error(validate_workflow_receipt(bad), "credential")
  expect_error(write_workflow_receipt(list(), tempfile()), "run must")

  legacy_dir <- tempfile("legacy-receipt-")
  legacy <- write_learning_receipt(
    legacy_dir, course_id = "course", activity_id = "activity",
    prediction = "Prediction", explanation = "Explanation",
    transfer_response = "Transfer", evidence_hash = "artifact-hash",
    outcome = "complete"
  )
  converted <- as_workflow_receipt(legacy)
  expect_equal(converted$role, "guided_learning")
  expect_true(validate_workflow_receipt(converted))
})

test_that("workflow compiler reports corrupt and publication-invalid artifacts", {
  dataset <- edge_dataset()
  run <- run_workflow(approve_workflow(workflow_from_dataset(
    dataset, "data_analyst", predictors = c("x", "z")
  )))
  expect_error(compile_workflow(run, tempfile(), max_visual_rows = 9L), "10 to 1000")
  output <- tempfile("compiler-edge-")
  compile_workflow(run, output)
  unlink(file.path(output, "workflow-spec.json"))
  checks <- check_workflow(output, strict = FALSE, publish = TRUE)
  expect_true(any(checks$status == "FAIL"))
  expect_error(check_workflow(output, strict = TRUE, publish = TRUE), "checks failed")
  expect_error(compile_workflow(list(), tempfile()), "run must")
  expect_error(rclaimlab:::workflow_primary_artifact(rclaimlab:::new_evidence_bundle("empty", NULL)), "renderable")

  large <- data.frame(x = 1:100, y = 101:200)
  sample_a <- rclaimlab:::workflow_visual_sample(large, 20L, 7L)
  sample_b <- rclaimlab:::workflow_visual_sample(large, 20L, 7L)
  expect_equal(sample_a, sample_b)
  expect_equal(nrow(sample_a), 20L)

  evidence <- as_rclaimlab_evidence(iris[1:30, 1:3])
  stages <- c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
  lesson <- lesson_spec("legacy-compile", "Legacy compile", "Explain evidence", evidence,
    tasks = lapply(stages, function(stage) task_spec(stage, stage, paste("Complete", stage))))
  legacy_run <- run_workflow(as_rclaimlab_workflow(lesson))
  legacy_output <- tempfile("legacy-workflow-")
  legacy_build <- compile_workflow(legacy_run, legacy_output)
  expect_true(all(legacy_build$checks$status == "PASS"))
})

test_that("workflow drafting validates provider type and prompt IDs", {
  workflow <- workflow_from_dataset(edge_dataset(), "data_analyst", predictors = c("x", "z"))
  expect_error(draft_workflow_text(workflow, provider = "not a function"), "provider must")
  expect_error(draft_workflow_text(workflow, function(request) list(
    title = "Title", question = "Question", prompts = c(missing = "Prompt")
  )), "keyed by activity id")
  ids <- vapply(workflow$activities, `[[`, character(1), "id")
  draft <- draft_workflow_text(workflow, function(request) list(
    title = "Reviewed title", question = "Reviewed question",
    prompts = stats::setNames(rep("Reviewed prompt", length(ids)), ids), model = "fixture-model"
  ))
  expect_equal(draft$provider, "fixture-model")
  expect_false(draft$approved)
})
