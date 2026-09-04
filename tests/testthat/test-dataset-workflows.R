workflow_fixture <- function(rows = 120L) {
  set.seed(42)
  data.frame(
    age = sample(18:70, rows, replace = TRUE),
    hours = round(stats::rnorm(rows, 40, 8), 1),
    education = factor(sample(c("secondary", "college", "graduate"), rows, replace = TRUE)),
    group = factor(rep(c("A", "B"), length.out = rows)),
    income = factor(ifelse(seq_len(rows) %% 3L == 0L, "high", "standard")),
    score = round(20 + seq_len(rows) * .3 + stats::rnorm(rows, 0, 3), 2),
    stringsAsFactors = FALSE
  )
}

local_workflow_dataset <- function(rows = 120L) {
  path <- tempfile(fileext = ".csv")
  utils::write.csv(workflow_fixture(rows), path, row.names = FALSE)
  import_dataset(dataset_source("local", path))
}

test_that("local dataset source preserves deterministic provenance", {
  path <- tempfile(fileext = ".csv")
  utils::write.csv(workflow_fixture(150L), path, row.names = FALSE)
  source <- dataset_source("local", path)
  manifest <- inspect_dataset(source)
  expect_s3_class(manifest, "rclaimlab_dataset_manifest")
  expect_false(manifest$publishable)
  expect_equal(nrow(preview_dataset(source, 20L)), 20L)
  first <- import_dataset(source, max_rows = 40L, seed = 8L)
  second <- import_dataset(source, max_rows = 40L, seed = 8L)
  expect_s3_class(first, "rclaimlab_dataset")
  expect_equal(first$source_record_id, second$source_record_id)
  expect_equal(first$data, second$data)
  expect_equal(length(unique(first$source_record_id)), 40L)
  expect_s3_class(profile_dataset(first), "rclaimlab_data_profile")
})

test_that("dataset source rejects unsupported and unsafe selections", {
  expect_error(dataset_source("huggingface", "invalid"), "owner/name")
  expect_error(dataset_source("local", "x", file = "y"), "file must be NULL")
  expect_error(preview_dataset(dataset_source("local", tempfile()), 101L), "between 1 and 100")
  expect_error(import_dataset(dataset_source("local", tempfile()), max_rows = 1L), "greater than or equal")
  nested <- data.frame(x = 1:2)
  nested$list <- I(list(list(a = 1), list(a = 2)))
  expect_error(rclaimlab:::reject_unsupported_tabular_data(nested), "nested or list")
})

test_that("workflow DAG validation detects missing references and cycles", {
  dataset <- local_workflow_dataset()
  workflow <- workflow_from_dataset(dataset, "data_analyst", predictors = c("age", "hours"))
  expect_s3_class(workflow, "rclaimlab_workflow")
  broken <- workflow
  broken$activities[[2]]$depends_on <- "missing"
  expect_error(validate_workflow_spec(broken), "unknown dependencies")
  cyclic <- workflow
  cyclic$activities[[1]]$depends_on <- cyclic$activities[[length(cyclic$activities)]]$id
  expect_error(validate_workflow_spec(cyclic), "cycle")
  expect_error(run_workflow(workflow), "requires approvals")
})

test_that("imported data can compile into a real guided-learning workflow", {
  dataset <- local_workflow_dataset()
  workflow <- workflow_from_dataset(
    dataset, "guided_learning", predictors = c("age", "hours"),
    question = "What patterns can a learner explain and transfer?"
  )
  expect_equal(workflow$role, "guided_learning")
  expect_true(all(c("frame", "inspect", "explain", "revise", "challenge", "reproduce") %in% vapply(workflow$activities, `[[`, character(1), "type")))
  run <- run_workflow(approve_workflow(workflow))
  expect_s3_class(run, "rclaimlab_workflow_run")
  expect_true(all(c("dataset-profile", "analyst-evidence") %in% run$bundle$registry$artifact_id))
  expect_equal(run$execution$mode, "descriptive")
})

test_that("analyst scientist and reviewer share traceable evidence", {
  dataset <- local_workflow_dataset()
  analyst <- approve_workflow(workflow_from_dataset(
    dataset, "data_analyst", predictors = c("age", "hours"),
    question = "What descriptive evidence is visible?"
  ))
  analyst_run <- run_workflow(analyst)
  expect_s3_class(analyst_run, "rclaimlab_workflow_run")
  expect_true(all(c("dataset-profile", "analyst-evidence") %in% analyst_run$bundle$registry$artifact_id))

  scientist <- continue_workflow(
    analyst_run, "data_scientist", outcome = "income",
    predictors = c("age", "hours", "education"), slice_by = "group",
    analysis = "glm", question = "How well does the approved model classify held-out records?"
  )
  scientist_run <- run_workflow(approve_workflow(scientist))
  model <- scientist_run$bundle$artifacts[["model-evidence"]]
  expect_equal(model$metadata$evaluation$mode, "holdout")
  expect_true(all(c("accuracy", "brier_score") %in% names(model$metadata$classification)))
  expect_true(length(model$metadata$workflow$split$test_record_ids) > 1L)
  expect_true(all(model$observations$observation_id %in% dataset$source_record_id))

  reviewer <- continue_workflow(scientist_run, "model_reviewer")
  reviewer_run <- run_workflow(approve_workflow(reviewer))
  expect_true(all(c("model-evidence", "review-evidence") %in% reviewer_run$bundle$registry$artifact_id))
  expect_equal(reviewer_run$bundle$artifacts[["review-evidence"]]$metadata$review$status, "requires_human_approval")
  expect_true(validate_evidence_bundle(reviewer_run$bundle))
})

test_that("linear workflows produce deterministic holdout metrics", {
  dataset <- local_workflow_dataset()
  make_run <- function() run_workflow(approve_workflow(workflow_from_dataset(
    dataset, "data_scientist", outcome = "score",
    predictors = c("age", "hours", "education"), analysis = "lm", seed = 99L
  )))
  first <- make_run()
  second <- make_run()
  first_evidence <- first$bundle$artifacts[["model-evidence"]]
  second_evidence <- second$bundle$artifacts[["model-evidence"]]
  expect_equal(first_evidence$analysis$artifact_hash, second_evidence$analysis$artifact_hash)
  expect_true(all(c("rmse", "mae", "r_squared") %in% names(first_evidence$metadata$evaluation)))
})

test_that("workflow compiler creates portable role UI and local receipt", {
  dataset <- local_workflow_dataset(300L)
  run <- run_workflow(approve_workflow(workflow_from_dataset(
    dataset, "data_scientist", outcome = "income",
    predictors = c("age", "hours", "education"), slice_by = "group", analysis = "glm"
  )))
  output <- tempfile("compiled-workflow-")
  build <- compile_workflow(run, output)
  expect_s3_class(build, "rclaimlab_build")
  expect_true(all(build$checks$status == "PASS"))
  expect_true(all(check_workflow(output, strict = TRUE)$status == "PASS"))
  html <- paste(readLines(file.path(output, "app", "index.html"), warn = FALSE), collapse = "\n")
  expect_match(html, 'id="activity-list"', fixed = TRUE)
  expect_match(html, 'id="evidence-canvas"', fixed = TRUE)
  expect_match(html, 'data-workspace-screen="focus"', fixed = TRUE)
  expect_match(html, 'data-workspace-screen="quest"', fixed = TRUE)
  expect_match(html, 'data-workspace-screen="trace"', fixed = TRUE)
  expect_match(html, 'data-workspace-screen="claim"', fixed = TRUE)
  expect_match(html, 'data-workspace-screen="handoff"', fixed = TRUE)
  expect_match(html, 'id="metric-two-value"', fixed = TRUE)
  expect_match(html, 'id="quest-code"', fixed = TRUE)
  expect_match(html, 'id="quest-run"', fixed = TRUE)
  expect_match(html, 'id="quest-pin"', fixed = TRUE)
  expect_match(html, '"rclaimlab-code-quest-1"', fixed = TRUE)
  expect_match(html, '"classification_slice"', fixed = TRUE)
  expect_match(html, '"metrics"', fixed = TRUE)
  expect_match(html, '"license_declared":false', fixed = TRUE)
  expect_match(html, '"publication_ready":false', fixed = TRUE)
  expect_match(html, 'publication blocked', fixed = TRUE)
  expect_match(html, 'Record ${index >= 0 ? index + 1 : ""}', fixed = TRUE)
  expect_match(html, 'querySelector("span:last-child")', fixed = TRUE)
  expect_match(html, 'const criteriaItems = Array.isArray(activity.criteria)', fixed = TRUE)
  expect_match(html, 'state.screen = "handoff"', fixed = TRUE)
  expect_match(html, 'learning_events: state.events', fixed = TRUE)
  expect_match(html, 'logEvent("code_quest_run"', fixed = TRUE)
  expect_match(html, 'logEvent("claim_saved"', fixed = TRUE)
  expect_true(file.exists(file.path(output, "data", "slice-metrics.csv")))
  expect_true(file.exists(file.path(output, "report", "index.html")))
  report_html <- paste(readLines(file.path(output, "report", "index.html"), warn = FALSE), collapse = "\n")
  expect_match(report_html, 'Return to evidence workspace', fixed = TRUE)
  expect_match(report_html, 'Interpretation boundary', fixed = TRUE)
  expect_false(grepl(normalizePath(dirname(output), winslash = "/"), html, fixed = TRUE))
  receipt <- write_workflow_receipt(run, output, claims = list(fit = "Holdout evidence is limited."))
  expect_s3_class(receipt, "rclaimlab_workflow_receipt")
  expect_true(validate_workflow_receipt(read_workflow_receipt(output)))
  expect_error(compile_workflow(run, output), "already exist")
  expect_error(compile_workflow(run, tempfile(), publish = TRUE), "pinned revision")
})

test_that("workflow draft is schema-only and cannot auto-approve", {
  workflow <- workflow_from_dataset(local_workflow_dataset(), "data_analyst", predictors = c("age", "hours"))
  draft <- draft_workflow_text(workflow)
  expect_equal(draft$provider, "deterministic-template")
  expect_false(draft$approved)
  expect_false(draft$changes_method)
  expect_error(draft_workflow_text(workflow, include_rows = TRUE), "does not send raw rows")
  expect_error(draft_workflow_text(workflow, function(request) list(title = "missing")), "must return")
})

test_that("legacy lessons convert without changing their public contract", {
  evidence <- as_rclaimlab_evidence(iris[1:20, 1:3], labels = paste0("row-", 1:20))
  stages <- c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
  lesson <- lesson_spec(
    "legacy", "Legacy lesson", "Explain evidence",
    evidence = evidence,
    tasks = lapply(stages, function(stage) task_spec(stage, stage, paste("Complete", stage)))
  )
  workflow <- as_rclaimlab_workflow(lesson)
  expect_equal(workflow$role, "guided_learning")
  expect_equal(length(workflow$activities), length(stages))
  expect_s3_class(run_workflow(workflow), "rclaimlab_workflow_run")
})

test_that("workflow wizard remains an optional local authoring surface", {
  expect_true(is.function(run_workflow_wizard))
  skip_if_not_installed("shiny")
  app <- rclaimlab:::build_workflow_wizard_app(tempdir())
  expect_s3_class(app, "shiny.appobj")
  source <- paste(deparse(body(rclaimlab:::build_workflow_wizard_app)), collapse = "\n")
  expect_match(source, "data-storyboard-scene", fixed = TRUE)
  expect_match(as.character(rclaimlab:::workflow_launcher()), "rw-purpose-layout", fixed = TRUE)
  expect_match(source, "rw-plan-layout", fixed = TRUE)
  expect_match(as.character(rclaimlab:::workflow_launcher()), "graduation-cap", fixed = TRUE)
  expect_match(source, "rclaimlab-step", fixed = TRUE)
  expect_match(source, 'summary_cell <- function(label, value, icon = "circle-info")', fixed = TRUE)
  expect_match(source, "approval pending", fixed = TRUE)
  expect_match(source, "decision_approval_status", fixed = TRUE)
  expect_match(source, "input_artifacts", fixed = TRUE)
  expect_match(source, "output_type", fixed = TRUE)
  expect_match(source, "group_ids <- cumsum", fixed = TRUE)
  expect_match(source, "workflow_activity_presentation", fixed = TRUE)
  expect_match(source, "current_href()", fixed = TRUE)
  expect_match(source, "drag_drop_script", fixed = TRUE)
  expect_match(source, "local-drop-status", fixed = TRUE)
  expect_match(source, "Drop one file at a time", fixed = TRUE)
  expect_match(source, "input.files=files", fixed = TRUE)
  expect_match(source, "hasDataset", fixed = TRUE)
  expect_match(source, "input.provider == 'huggingface'", fixed = TRUE)
  expect_match(source, "Parsed NA", fixed = TRUE)
  expect_match(source, "Recommended - approval pending", fixed = TRUE)
  expect_match(source, "rclaimlab-mark.svg", fixed = TRUE)
  expect_match(rclaimlab:::workflow_wizard_css(), ".rw-dropzone.is-dragover", fixed = TRUE)
  expect_match(rclaimlab:::workflow_wizard_css(), ".rw-phase.disabled", fixed = TRUE)
  expect_match(rclaimlab:::workflow_wizard_css(), ".rw-brand-logo", fixed = TRUE)
})

test_that("compiled workflow and guided lesson embed the Figma brand mark", {
  mark <- rclaimlab:::workflow_template_asset_uri(file.path("icons", "rclaimlab-mark.svg"), "image/svg+xml")
  expect_match(mark, "^data:image/svg\\+xml;base64,")
  expect_gt(nchar(mark), 100L)
  workflow_html <- rclaimlab:::workflow_html("Branded workflow", list())
  lesson_html <- rclaimlab:::scene_html("Branded lesson", "[]")
  expect_match(workflow_html, "data:image/svg\\+xml;base64,")
  expect_match(lesson_html, "data:image/svg\\+xml;base64,")
  expect_false(grepl("{{BRAND_MARK_DATA_URI}}", workflow_html, fixed = TRUE))
  expect_false(grepl("{{BRAND_MARK_DATA_URI}}", lesson_html, fixed = TRUE))
})
