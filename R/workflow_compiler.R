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
             "evidence/index.json", "analysis/workflow.R", "report/index.qmd", "report/index.html",
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
  if (identical(contract$code_quest$mode, "classification_slice")) {
    quest_table <- do.call(rbind, lapply(contract$code_quest$candidates, function(item) data.frame(
      group = item$label, n = item$n, accuracy = item$accuracy,
      error_rate = item$error_rate, brier_score = item$brier_score,
      artifact_id = item$artifact_id, artifact_hash = item$artifact_hash,
      stringsAsFactors = FALSE
    )))
    utils::write.csv(quest_table, file.path(output_dir, "data", "slice-metrics.csv"), row.names = FALSE, na = "")
  }
  writeLines(workflow_html(run$workflow$title, contract), file.path(output_dir, "app", "index.html"), useBytes = TRUE)

  source_code <- run$execution$source_code %||% c(
    paste0("# R-ClaimLab workflow: ", run$workflow$id),
    paste0("# Role: ", run$workflow$role),
    "# Analysis evidence is stored under ../evidence/."
  )
  writeLines(source_code, file.path(output_dir, "analysis", "workflow.R"), useBytes = TRUE)
  writeLines(workflow_report_qmd(run, primary_id), file.path(output_dir, "report", "index.qmd"), useBytes = TRUE)
  writeLines(workflow_report_html(run, primary_id), file.path(output_dir, "report", "index.html"), useBytes = TRUE)
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
                "evidence/index.json", "analysis/workflow.R", "report/index.qmd", "report/index.html",
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
               'id="screen-quest"', 'id="quest-code"', 'id="quest-run"', 'id="quest-pin"',
               'id="download-workflow-receipt"', 'id="deliverable-list"', 'data-workflow-ready="true"')
  add("role_ui", if (all(vapply(markers, grepl, logical(1), x = html, fixed = TRUE))) "PASS" else "FAIL",
      "Role activity rail, R Code Quest, evidence views, handoff, and local receipt controls are present")
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

workflow_browser_contract <- function(run, primary_id, evidence, table) {
  seed <- run$workflow$analysis$seed %||% 2026L
  source_manifest <- workflow_public_source_manifest(run)
  has_text <- function(value) !is.null(value) && length(value) == 1L && !is.na(value) && nzchar(trimws(as.character(value)))
  execution <- utils::modifyList(
    list(seed = seed, r_version = R.version.string),
    run$execution
  )
  execution$source_code_hash <- evidence_hash(paste(run$execution$source_code %||% character(), collapse = "\n"))
  list(
    schema_version = "rclaimlab-browser-workflow-1",
    workflow = list(id = run$workflow$id, title = run$workflow$title,
      role = run$workflow$role, role_label = workflow_role_label(run$workflow$role),
      goal = run$workflow$goal, question = run$workflow$analysis$question %||% run$workflow$goal,
      activities = lapply(run$workflow$activities, unclass), deliverables = run$workflow$deliverables,
      handoff_from = run$workflow$handoff_from %||% NULL),
    source = source_manifest,
    evidence = list(primary_artifact = primary_id, artifact_hash = evidence$analysis$artifact_hash,
      bundle_hash = run$bundle$bundle_hash, engine = evidence$analysis$engine,
      dimensions = evidence$dimensions, rows = table, total_rows = nrow(as.data.frame(evidence)),
      sampled_rows = nrow(table), metrics = workflow_browser_metrics(evidence),
      metadata = evidence$metadata),
    code_quest = workflow_code_quest_contract(run, primary_id, evidence),
    execution = execution,
    verification = list(
      analysis_verified = has_text(evidence$analysis$artifact_hash) && has_text(run$bundle$bundle_hash),
      source_version_recorded = has_text(source_manifest$revision) || has_text(source_manifest$content_md5),
      license_declared = has_text(source_manifest$license),
      publication_ready = isTRUE(source_manifest$publishable)
    ),
    privacy = list(storage = "browser-local", telemetry = FALSE, raw_data_exported = FALSE)
  )
}

workflow_code_quest_contract <- function(run, primary_id, evidence) {
  model <- run$bundle$artifacts[["model-evidence"]]
  slices <- model$metadata$workflow$slices %||% list()
  slice_results <- slices$results %||% list()
  if (length(slice_results)) {
    candidates <- lapply(names(slice_results), function(id) {
      value <- slice_results[[id]]
      label <- sub("^[^=]+=", "", id)
      list(
        id = id, label = label, n = as.integer(value$n),
        accuracy = unname(value$accuracy %||% NA_real_),
        error_rate = if (is.null(value$accuracy)) NA_real_ else unname(1 - value$accuracy),
        brier_score = unname(value$brier_score %||% NA_real_),
        artifact_id = "model-evidence",
        artifact_hash = model$analysis$artifact_hash
      )
    })
    error_rates <- vapply(candidates, function(item) item$error_rate, numeric(1))
    target <- candidates[[which.max(error_rates)]]
    group_variable <- sub("=.*$", "", names(slice_results)[[1]])
    default <- candidates[[length(candidates)]]$label
    code <- c(
      "# Compare holdout error by an approved review slice.",
      "slice_results <- read.csv(\"../data/slice-metrics.csv\")",
      paste0("target_group <- \"", default, "\"  # edit this value"),
      "selected <- subset(slice_results, group == target_group)",
      "selected[order(-selected$error_rate), ]"
    )
    return(list(
      schema_version = "rclaimlab-code-quest-1", mode = "classification_slice",
      title = "Which subgroup causes the model error spike?",
      prompt = paste0("Edit target_group, run the R code, and identify the largest eligible ", group_variable, " error rate."),
      loop = c("Inspect", "Edit R", "Run", "Explain", "Pin evidence"),
      code = paste(code, collapse = "\n"), editable_variable = "target_group",
      allowed_values = vapply(candidates, `[[`, character(1), "label"),
      candidates = candidates, target = target$label,
      suppressed = slices$suppressed %||% list(), minimum_n = slices$minimum_n %||% 20L,
      interpretation = list(minimum_characters = 30L, require_group = TRUE,
        require_boundary = TRUE,
        boundary_terms = c("sample", "holdout", "causal", "certification", "limited", "uncertain")),
      receipt = list(seed = run$workflow$analysis$seed %||% 2026L,
        r_version = R.version.string, rows = sum(vapply(candidates, function(item) item$n, integer(1))),
        code_hash = evidence_hash(code), artifact_id = "model-evidence",
        artifact_hash = model$analysis$artifact_hash)
    ))
  }

  table <- as.data.frame(evidence)
  numeric <- names(table)[vapply(table, is.numeric, logical(1))]
  numeric <- setdiff(numeric, c("observation_id"))
  value_column <- if (length(numeric)) numeric[[1]] else names(table)[[1]]
  values <- suppressWarnings(as.numeric(table[[value_column]]))
  if (!any(is.finite(values))) values <- seq_len(nrow(table))
  order_index <- order(values, decreasing = TRUE, na.last = NA)
  order_index <- utils::head(order_index, min(3L, length(order_index)))
  candidates <- lapply(order_index, function(index) list(
    id = as.character(table$observation_id[[index]] %||% table$label[[index]] %||% index),
    label = {
      raw_label <- as.character(table$label[[index]] %||% table$observation_id[[index]] %||% index)
      if (identical(raw_label, as.character(table$observation_id[[index]])) || grepl("^(src|obs)-", raw_label)) paste("Record", index) else raw_label
    },
    value = unname(values[[index]]), artifact_id = primary_id,
    artifact_hash = evidence$analysis$artifact_hash
  ))
  target <- candidates[[1]]
  default <- candidates[[length(candidates)]]$id
  code <- c(
    "# Inspect a compiled evidence row with R.",
    "evidence <- read.csv(\"../data/evidence-table.csv\")",
    paste0("target_record <- \"", default, "\"  # edit this value"),
    "selected <- subset(evidence, observation_id == target_record)",
    paste0("selected[, c(\"observation_id\", \"", value_column, "\")]"))
  list(
    schema_version = "rclaimlab-code-quest-1", mode = "evidence_record",
    title = paste0("Which record has the largest ", value_column, " value?"),
    prompt = "Edit target_record, run the R code, explain the result, and pin the evidence.",
    loop = c("Inspect", "Edit R", "Run", "Explain", "Pin evidence"),
    code = paste(code, collapse = "\n"), editable_variable = "target_record",
    allowed_values = vapply(candidates, `[[`, character(1), "id"),
    candidates = candidates, target = target$label, suppressed = list(), minimum_n = NA_integer_,
    interpretation = list(minimum_characters = 30L, require_group = FALSE,
      require_boundary = TRUE, boundary_terms = c("sample", "causal", "limited", "uncertain", "descriptive")),
    receipt = list(seed = run$workflow$analysis$seed %||% 2026L,
      r_version = R.version.string, rows = nrow(table), code_hash = evidence_hash(code),
      artifact_id = primary_id, artifact_hash = evidence$analysis$artifact_hash)
  )
}

workflow_browser_metrics <- function(evidence) {
  metadata <- evidence$metadata %||% list()
  classification <- metadata$classification %||% list()
  baseline <- metadata$workflow$baseline %||% list()
  evaluation <- metadata$evaluation %||% list()
  if (!is.null(classification$accuracy)) return(list(
    list(label = "Baseline accuracy", value = baseline$value %||% NA_real_),
    list(label = "Model accuracy", value = classification$accuracy),
    list(label = "Brier score", value = classification$brier_score %||% NA_real_)
  ))
  if (!is.null(evaluation$rmse)) return(list(
    list(label = "RMSE", value = evaluation$rmse),
    list(label = "MAE", value = evaluation$mae %||% NA_real_),
    list(label = "R squared", value = evaluation$r_squared %||% NA_real_)
  ))
  list(
    list(label = "Evidence rows", value = nrow(as.data.frame(evidence))),
    list(label = "Analysis engine", value = evidence$analysis$engine),
    list(label = "Artifact status", value = "Verified")
  )
}

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

workflow_report_html <- function(run, primary_id) {
  title <- html_escape(run$workflow$title)
  role <- html_escape(workflow_role_label(run$workflow$role))
  question <- html_escape(run$workflow$analysis$question %||% run$workflow$goal)
  artifact <- html_escape(primary_id)
  bundle <- html_escape(run$bundle$bundle_hash)
  paste0(
    '<!doctype html><html lang="en"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width,initial-scale=1">',
    '<title>', title, ' - workflow report</title>',
    '<style>:root{font-family:Inter,ui-sans-serif,system-ui,sans-serif;color:#14203a;background:#f5f7fb}',
    'body{margin:0}.shell{max-width:880px;margin:0 auto;padding:48px 24px 80px}',
    'a{color:#155fe4}.back{display:inline-flex;margin-bottom:28px;font-weight:700;text-decoration:none}',
    'header,.card{background:#fff;border:1px solid #dfe5ef;border-radius:18px;padding:28px;box-shadow:0 10px 30px rgba(20,32,58,.06)}',
    'header{margin-bottom:18px}h1{font-size:clamp(2rem,6vw,3.4rem);line-height:1.02;margin:.25rem 0 1rem}',
    'h2{font-size:1.2rem;margin:0 0 .7rem}.eyebrow{color:#155fe4;font-size:.76rem;font-weight:800;letter-spacing:.12em;text-transform:uppercase}',
    '.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.card p{line-height:1.65;margin:.35rem 0}',
    'code{overflow-wrap:anywhere;color:#155fe4}@media(max-width:650px){.shell{padding:24px 16px 56px}.grid{grid-template-columns:1fr}}',
    '</style></head><body><main class="shell">',
    '<a class="back" href="../app/index.html">&larr; Return to evidence workspace</a>',
    '<header><span class="eyebrow">Portable workflow report</span><h1>', title, '</h1>',
    '<p><strong>Role:</strong> ', role, '</p><p><strong>Question:</strong> ', question, '</p></header>',
    '<div class="grid"><section class="card"><span class="eyebrow">Evidence handoff</span><h2>Stable evidence linkage</h2>',
    '<p>Primary artifact: <code>', artifact, '</code></p><p>Bundle hash: <code>', bundle, '</code></p>',
    '<p>The workspace, evidence table, analysis script, and receipt remain linked through source-record and artifact identifiers.</p></section>',
    '<section class="card"><span class="eyebrow">Interpretation boundary</span><h2>Human review remains required</h2>',
    '<p>This workflow supports evidence review and reproducibility. It does not establish causality, certify fairness, or authorize individual decisions.</p></section></div>',
    '</main></body></html>'
  )
}

workflow_template_path <- function(name) {
  source <- file.path(RCLAIMLAB_SOURCE_ROOT, "inst", "templates", name)
  if (nzchar(RCLAIMLAB_SOURCE_ROOT) && file.exists(source)) return(source)
  installed <- system.file("templates", name, package = "rclaimlab")
  if (!nzchar(installed) || !file.exists(installed)) stop("workflow template asset was not found: ", name, call. = FALSE)
  installed
}

workflow_template_asset_uri <- function(name, mime_type) {
  asset <- readBin(workflow_template_path(name), what = "raw", n = 5000000L)
  encoded <- gsub("[\r\n]", "", jsonlite::base64_enc(asset))
  paste0("data:", mime_type, ";base64,", encoded)
}

workflow_html <- function(title, contract, mode_home = NULL) {
  navigation <- ""
  if (!is.null(mode_home)) {
    if (!is.character(mode_home) || length(mode_home) != 1L || is.na(mode_home) ||
        !grepl("^(\\.\\./)+index\\.html$", mode_home)) {
      stop("mode_home must be a relative parent index.html path", call. = FALSE)
    }
    navigation <- paste0('<a class="mode-home" href="', html_escape(mode_home),
                         '"><span aria-hidden="true">&#8592;</span> Change mode</a>')
  }
  template <- paste(readLines(workflow_template_path("workflow-shell.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  css <- paste(readLines(workflow_template_path("workflow.css"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  icon_font <- readBin(workflow_template_path(file.path("icons", "fa-solid-900.woff2")), what = "raw", n = 2000000L)
  icon_font_base64 <- gsub("[\r\n]", "", jsonlite::base64_enc(icon_font))
  css <- sub("{{ICON_FONT_WOFF2}}", icon_font_base64, css, fixed = TRUE)
  brand_mark <- workflow_template_asset_uri(file.path("icons", "rclaimlab-mark.svg"), "image/svg+xml")
  script <- paste(vapply(c("workflow-presentation.js", "workflow.js"), function(file) {
    paste(readLines(workflow_template_path(file), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  }, character(1)), collapse = "\n")
  presentation <- paste(readLines(workflow_template_path("workflow-presentation.json"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  presentation <- gsub("<", "\\u003c", presentation, fixed = TRUE)
  script <- paste0("const RCLAIMLAB_ROLE_PRESENTATION = ", presentation, ";\n", script)
  json <- jsonlite::toJSON(contract, auto_unbox = TRUE, dataframe = "rows", null = "null", na = "null", digits = NA)
  json <- gsub("<", "\\u003c", json, fixed = TRUE)
  template <- sub("{{TITLE}}", html_escape(title), template, fixed = TRUE)
  template <- sub("{{MODE_HOME_LINK}}", navigation, template, fixed = TRUE)
  template <- sub("{{BRAND_MARK_DATA_URI}}", brand_mark, template, fixed = TRUE)
  template <- sub("{{WORKFLOW_CSS}}", css, template, fixed = TRUE)
  template <- sub("{{WORKFLOW_JSON}}", json, template, fixed = TRUE)
  sub("{{WORKFLOW_JS}}", script, template, fixed = TRUE)
}
