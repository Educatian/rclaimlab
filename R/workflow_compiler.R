#' Compile a workflow run into portable role-adaptive artifacts
#'
#' @param run Completed workflow run.
#' @param output_dir Destination directory.
#' @param overwrite Whether compiler-owned output may be replaced.
#' @param publish Enforce pinned source and license publication gates.
#' @param max_visual_rows Maximum browser visualization observations.
#' @return An `rclaimlab_build`.
#' @export
compile_workflow <- function(run, output_dir, overwrite = FALSE, publish = FALSE,
                             max_visual_rows = 1000L) {
  if (!inherits(run, "rclaimlab_workflow_run")) stop("run must be an rclaimlab_workflow_run", call. = FALSE)
  validate_workflow_spec(run$workflow)
  validate_evidence_bundle(run$bundle)
  max_visual_rows <- as.integer(max_visual_rows)
  if (length(max_visual_rows) != 1L || is.na(max_visual_rows) || max_visual_rows < 10L || max_visual_rows > 1000L) {
    stop("max_visual_rows must be one integer from 10 to 1000", call. = FALSE)
  }
  if (isTRUE(publish) && !is.null(run$dataset) && !isTRUE(run$dataset$manifest$publishable)) {
    stop("publishable workflows require a pinned revision/version and a declared source license", call. = FALSE)
  }
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  owned <- c("source-manifest.json", "dataset-profile.json", "workflow-spec.json",
             "evidence/index.json", "analysis/workflow.R", "report/index.qmd",
             "app/index.html", "checks/workflow-report.json")
  if (!isTRUE(overwrite) && any(file.exists(file.path(output_dir, owned)))) {
    stop("compiled workflow files already exist; use overwrite = TRUE", call. = FALSE)
  }
  invisible(lapply(c("evidence/artifacts", "analysis", "report", "app", "checks", "data"),
                   function(relative) ensure_dir(file.path(output_dir, relative))))

  source_manifest <- workflow_public_source_manifest(run)
  write_json_object(source_manifest, file.path(output_dir, "source-manifest.json"))
  write_json_object(workflow_public_profile(run), file.path(output_dir, "dataset-profile.json"))
  write_json_object(workflow_public_spec(run$workflow), file.path(output_dir, "workflow-spec.json"))
  bundle_index <- list(
    schema_version = run$bundle$schema_version, workflow_id = run$bundle$workflow_id,
    source = run$bundle$source, registry = run$bundle$registry,
    dependencies = run$bundle$dependencies, lineage = run$bundle$lineage,
    bundle_hash = run$bundle$bundle_hash
  )
  write_json_object(bundle_index, file.path(output_dir, "evidence", "index.json"))
  for (id in names(run$bundle$artifacts)) {
    write_rclaimlab_evidence(run$bundle$artifacts[[id]],
      file.path(output_dir, "evidence", "artifacts", paste0(id, ".json")), overwrite = TRUE)
  }

  primary_id <- workflow_primary_artifact(run$bundle)
  primary <- run$bundle$artifacts[[primary_id]]
  full_table <- as.data.frame(primary)
  utils::write.csv(full_table, file.path(output_dir, "data", "evidence-table.csv"), row.names = FALSE, na = "")
  visual_table <- workflow_visual_sample(full_table, max_visual_rows, run$workflow$analysis$seed %||% 2026L)
  contract <- workflow_browser_contract(run, primary_id, primary, visual_table)
  writeLines(workflow_html(run$workflow$title, contract), file.path(output_dir, "app", "index.html"), useBytes = TRUE)

  source_code <- run$execution$source_code %||% c(
    paste0("# R-ClaimLab workflow: ", run$workflow$id),
    paste0("# Role: ", run$workflow$role),
    "# Analysis evidence is stored under ../evidence/."
  )
  writeLines(source_code, file.path(output_dir, "analysis", "workflow.R"), useBytes = TRUE)
  writeLines(workflow_report_qmd(run, primary_id), file.path(output_dir, "report", "index.qmd"), useBytes = TRUE)
  writeLines(c("project:", "  type: website", "  output-dir: _site", "format:",
               "  html:", "    toc: true", "execute:", "  freeze: auto"),
             file.path(output_dir, "report", "_quarto.yml"), useBytes = TRUE)

  checks <- check_workflow(output_dir, strict = FALSE, publish = publish, write_report = TRUE)
  structure(
    list(
      schema_version = "rclaimlab-workflow-build-1", lesson_id = run$workflow$id,
      workflow_id = run$workflow$id, role = run$workflow$role,
      output_dir = output_dir, evidence_hash = run$bundle$bundle_hash,
      bundle_hash = run$bundle$bundle_hash, primary_artifact = primary_id,
      files = file.path(output_dir, owned), checks = checks
    ),
    class = c("rclaimlab_workflow_build", "rclaimlab_build", "list")
  )
}

#' Check compiled role-adaptive workflow artifacts
#'
#' @param path Compiled workflow directory.
#' @param strict Stop when any check fails.
#' @param publish Require publication metadata.
#' @param write_report Write JSON and Markdown reports.
#' @return A check data frame.
#' @export
check_workflow <- function(path, strict = FALSE, publish = FALSE, write_report = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  results <- list()
  add <- function(check, status, detail) {
    results[[length(results) + 1L]] <<- data.frame(check = check, status = status, detail = detail, stringsAsFactors = FALSE)
  }
  required <- c("source-manifest.json", "dataset-profile.json", "workflow-spec.json",
                "evidence/index.json", "analysis/workflow.R", "report/index.qmd",
                "app/index.html", "data/evidence-table.csv")
  missing <- required[!file.exists(file.path(path, required))]
  add("artifact_set", if (length(missing)) "FAIL" else "PASS",
      if (length(missing)) paste("Missing:", paste(missing, collapse = ", ")) else "All portable workflow artifacts exist")
  parse_json <- function(relative) tryCatch(jsonlite::fromJSON(file.path(path, relative), simplifyVector = FALSE), error = identity)
  workflow <- parse_json("workflow-spec.json")
  bundle <- parse_json("evidence/index.json")
  source <- parse_json("source-manifest.json")
  add("workflow_schema", if (is.list(workflow) && identical(workflow$schema_version, "rclaimlab-workflow-1")) "PASS" else "FAIL",
      "Workflow specification uses rclaimlab-workflow-1")
  add("bundle_schema", if (is.list(bundle) && identical(bundle$schema_version, "rclaimlab-evidence-bundle-1")) "PASS" else "FAIL",
      "Evidence index uses rclaimlab-evidence-bundle-1")
  publish_ok <- !isTRUE(publish) || (is.list(source) && isTRUE(source$publishable))
  add("publication_source", if (publish_ok) "PASS" else "FAIL",
      if (publish_ok) "Source revision and license satisfy the selected gate" else "Publication requires a pinned source and declared license")
  html_path <- file.path(path, "app", "index.html")
  html <- if (file.exists(html_path)) paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n") else ""
  markers <- c('id="activity-list"', 'id="evidence-canvas"', 'id="evidence-table-body"',
               'id="download-workflow-receipt"', 'id="deliverable-list"', 'data-workflow-ready="true"')
  add("role_ui", if (all(vapply(markers, grepl, logical(1), x = html, fixed = TRUE))) "PASS" else "FAIL",
      "Role activity rail, evidence views, handoff, and local receipt controls are present")
  text_files <- required[file.exists(file.path(path, required))]
  combined <- paste(vapply(file.path(path, text_files), function(file) {
    paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  }, character(1)), collapse = "\n")
  secret <- grepl("(KAGGLE_API_TOKEN|HF_TOKEN|OPENAI_API_KEY|Bearer[[:space:]][A-Za-z0-9])", combined, ignore.case = TRUE)
  local_path <- grepl("[A-Za-z]:[/\\\\](Users|Program Files|Documents)[/\\\\]", combined, ignore.case = TRUE)
  add("privacy_redaction", if (!secret && !local_path) "PASS" else "FAIL", "Compiled artifacts exclude credentials and local absolute paths")
  evidence_files <- list.files(file.path(path, "evidence", "artifacts"), pattern = "\\.json$", full.names = TRUE)
  evidence_valid <- length(evidence_files) > 0L && all(vapply(evidence_files, function(file) {
    object <- tryCatch(read_rclaimlab_evidence(file), error = function(error) NULL)
    !is.null(object) && isTRUE(validate_rclaimlab_evidence(object))
  }, logical(1)))
  add("evidence_contract", if (evidence_valid) "PASS" else "FAIL", "Every bundled artifact satisfies rclaimlab-evidence-2")
  result <- do.call(rbind, results)
  if (isTRUE(write_report)) {
    ensure_dir(file.path(path, "checks"))
    jsonlite::write_json(result, file.path(path, "checks", "workflow-report.json"), dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
    writeLines(c("# R-ClaimLab workflow check", "",
                 paste0("- **", result$check, ":** ", result$status, " - ", result$detail)),
               file.path(path, "checks", "workflow-report.md"), useBytes = TRUE)
  }
  if (isTRUE(strict) && any(result$status == "FAIL")) {
    stop("workflow checks failed: ", paste(result$check[result$status == "FAIL"], collapse = ", "), call. = FALSE)
  }
  result
}

workflow_public_source_manifest <- function(run) {
  if (is.null(run$dataset)) return(list(
    schema_version = "rclaimlab-dataset-manifest-1", provider = "legacy",
    id = run$workflow$id, revision = run$bundle$bundle_hash, files = list(),
    license = "CC BY 4.0", citation = "R-ClaimLab guided lesson",
    source_url = NA_character_, publishable = TRUE
  ))
  manifest <- unclass(run$dataset$manifest)
  manifest$local_path <- NULL
  if (identical(manifest$provider, "local")) {
    manifest$id <- basename(run$dataset$source$id)
    manifest$source_url <- NA_character_
  }
  manifest$selected_file <- run$dataset$import$file
  manifest$content_md5 <- run$dataset$import$content_md5
  manifest$source_fingerprint <- run$dataset$source_fingerprint
  manifest
}

workflow_public_profile <- function(run) {
  if (is.null(run$dataset)) return(list(schema_version = "rclaimlab-dataset-profile-1", mode = "legacy_lesson"))
  profile <- profile_dataset(run$dataset, outcome = run$workflow$analysis$outcome,
    intent = if (run$workflow$analysis$method == "glm") "classify" else if (run$workflow$analysis$method == "lm") "explain" else "describe")
  list(schema_version = "rclaimlab-dataset-profile-1", rows = profile$rows,
       columns = profile$columns, outcome = profile$outcome, intent = profile$intent,
       warnings = profile$warnings, source = profile$source)
}

workflow_public_spec <- function(workflow) {
  value <- unclass(workflow)
  value$dataset <- if (is.null(workflow$dataset)) NULL else list(
    schema_version = workflow$dataset$schema_version,
    provider = workflow$dataset$source$provider,
    id = if (workflow$dataset$source$provider == "local") basename(workflow$dataset$source$id) else workflow$dataset$source$id,
    revision = workflow$dataset$manifest$revision,
    source_fingerprint = workflow$dataset$source_fingerprint,
    rows = nrow(workflow$dataset$data), columns = names(workflow$dataset$data)
  )
  value$activities <- lapply(workflow$activities, unclass)
  value$representations <- lapply(workflow$representations, unclass)
  value$upstream <- if (is.null(workflow$upstream)) NULL else list(bundle_hash = workflow$upstream$bundle_hash)
  value$legacy_lesson <- NULL
  value
}

workflow_primary_artifact <- function(bundle) {
  preference <- c("model-evidence", "analyst-evidence", "review-evidence", "lesson-evidence", "dataset-profile")
  selected <- preference[preference %in% names(bundle$artifacts)]
  if (!length(selected)) stop("evidence bundle does not contain a renderable artifact", call. = FALSE)
  selected[[1]]
}

workflow_visual_sample <- function(data, maximum, seed) {
  if (nrow(data) <= maximum) return(data)
  keep <- with_preserved_seed(seed, sort(sample.int(nrow(data), maximum)))
  data[keep, , drop = FALSE]
}

workflow_browser_contract <- function(run, primary_id, evidence, table) list(
  schema_version = "rclaimlab-browser-workflow-1",
  workflow = list(id = run$workflow$id, title = run$workflow$title,
    role = run$workflow$role, role_label = workflow_role_label(run$workflow$role),
    goal = run$workflow$goal, question = run$workflow$analysis$question %||% run$workflow$goal,
    activities = lapply(run$workflow$activities, unclass), deliverables = run$workflow$deliverables,
    handoff_from = run$workflow$handoff_from %||% NULL),
  source = workflow_public_source_manifest(run),
  evidence = list(primary_artifact = primary_id, artifact_hash = evidence$analysis$artifact_hash,
    bundle_hash = run$bundle$bundle_hash, engine = evidence$analysis$engine,
    dimensions = evidence$dimensions, rows = table, total_rows = nrow(as.data.frame(evidence)),
    sampled_rows = nrow(table), metadata = evidence$metadata),
  execution = run$execution,
  privacy = list(storage = "browser-local", telemetry = FALSE, raw_data_exported = FALSE)
)

workflow_report_qmd <- function(run, primary_id) c(
  "---", paste0('title: "', gsub('"', '\\"', run$workflow$title), '"'), "format: html", "---", "",
  "# Workflow purpose", "", paste0("**Role:** ", workflow_role_label(run$workflow$role)), "",
  paste0("**Question:** ", run$workflow$analysis$question %||% run$workflow$goal), "",
  "# Evidence handoff", "", paste0("The primary artifact is `", primary_id,
    "` in evidence bundle `", run$bundle$bundle_hash, "`."), "",
  "The browser app, evidence table, source manifest, analysis script, and workflow receipt remain linked through stable source-record and artifact identifiers.", "",
  "# Interpretation boundary", "",
  "This workflow supports evidence review and reproducibility. It does not establish causality, certify fairness, or authorize individual decisions.", "",
  "[Open the role-adaptive evidence workspace](../app/index.html)"
)

workflow_template_path <- function(name) {
  source <- file.path(RCLAIMLAB_SOURCE_ROOT, "inst", "templates", name)
  if (nzchar(RCLAIMLAB_SOURCE_ROOT) && file.exists(source)) return(source)
  installed <- system.file("templates", name, package = "rclaimlab")
  if (!nzchar(installed) || !file.exists(installed)) stop("workflow template asset was not found: ", name, call. = FALSE)
  installed
}

workflow_html <- function(title, contract) {
  template <- paste(readLines(workflow_template_path("workflow-shell.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  css <- paste(readLines(workflow_template_path("workflow.css"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  script <- paste(readLines(workflow_template_path("workflow.js"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  json <- jsonlite::toJSON(contract, auto_unbox = TRUE, dataframe = "rows", null = "null", na = "null", digits = NA)
  json <- gsub("<", "\\u003c", json, fixed = TRUE)
  template <- sub("{{TITLE}}", html_escape(title), template, fixed = TRUE)
  template <- sub("{{WORKFLOW_CSS}}", css, template, fixed = TRUE)
  template <- sub("{{WORKFLOW_JSON}}", json, template, fixed = TRUE)
  sub("{{WORKFLOW_JS}}", script, template, fixed = TRUE)
}
