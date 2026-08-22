default_rclaimlab_education <- function(education = NULL) {
  if (!is.null(education)) return(education)
  list(
    audience = "introductory data-science learners",
    estimated_minutes = 15L,
    prerequisites = c("basic data-frame vocabulary", "read a simple plot"),
    objectives = c(
      "state a data question and identify the evidence boundary",
      "run a reproducible R transformation",
      "explain one observation with coordinate or statistic evidence"
    ),
    sequence = c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce"),
    assessment = "Use a claim-evidence-limitation-transfer rubric.",
    instructor_materials = character(),
    accessibility_alternative = "semantic table and keyboard path",
    extension_activities = character()
  )
}

default_rclaimlab_manifest <- function(path = ".", lesson_id = NULL, title = NULL,
                                       source_platform = "rclaimlab",
                                       source_project = NULL, course_id = NULL,
                                       session_id = NULL, block_id = NULL,
                                       activity_id = NULL, dataset_file = NULL,
                                       dataset_source = NULL, dataset_license = NULL,
                                       required_columns = c("label", "x", "y", "z"),
                                       seed = 2026, web_r_version = "0.6.0",
                                       storage = "browser-local",
                                       export_consent_required = TRUE,
                                       research_use = "separate-consent",
                                       education = NULL,
                                       evidence_file = "scene/evidence.json",
                                       evidence_hash = NULL) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (is.null(lesson_id)) lesson_id <- basename(path)
  if (is.null(title)) title <- lesson_id
  if (is.null(source_project)) source_project <- source_platform
  if (is.null(dataset_file)) dataset_file <- "data/source.csv"
  if (is.null(dataset_source)) dataset_source <- ""
  if (is.null(dataset_license)) dataset_license <- ""
  list(
    manifest_version = "2.0",
    lesson_id = as.character(lesson_id),
    title = as.character(title),
    source_platform = as.character(source_platform),
    source_project = as.character(source_project),
    course_id = course_id,
    session_id = session_id,
    block_id = block_id,
    activity_id = activity_id,
    dataset = list(
      file = as.character(dataset_file),
      source = as.character(dataset_source),
      license = as.character(dataset_license)
    ),
    r_contract = list(
      required_columns = as.character(required_columns),
      scene_columns = list(label = "label", x = "x", y = "y", z = "z")
    ),
    reproducibility = list(
      seed = seed,
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      web_r_version = as.character(web_r_version)
    ),
    accessibility = list(semantic_table = TRUE, keyboard_path = TRUE),
    privacy = list(
      storage = as.character(storage),
      export_consent_required = isTRUE(export_consent_required),
      research_use = as.character(research_use)
    ),
    education = default_rclaimlab_education(education),
    evidence = list(
      schema_version = "rclaimlab-evidence-2",
      artifact = as.character(evidence_file),
      artifact_hash = evidence_hash
    ),
    artifacts = list(
      lesson_entrypoint = "index.qmd",
      scene = "scene/index.html",
      points = "scene/points.json",
      evidence = as.character(evidence_file),
      reproducibility_report = "checks/reproducibility-report.json",
      learning_receipt = "checks/learning-receipt.json"
    )
  )
}

#' Write a version 2 lesson manifest
#'
#' @param path Lesson directory.
#' @param lesson_id,title Stable identifier and learner-facing title.
#' @param source_platform,source_project Source-system provenance.
#' @param course_id,session_id,block_id,activity_id Optional external course identifiers.
#' @param dataset_file,dataset_source,dataset_license Dataset provenance.
#' @param required_columns Scene data contract.
#' @param seed,web_r_version Reproducibility settings.
#' @param storage,export_consent_required,research_use Privacy contract.
#' @param education Educational metadata list.
#' @param evidence_file,evidence_hash Evidence IR location and deterministic hash.
#' @param overwrite Whether an existing manifest may be replaced.
#' @return Invisibly returns the manifest path.
#' @export
write_lesson_manifest <- function(path = ".", lesson_id = NULL, title = NULL,
                                  source_platform = "rclaimlab",
                                  source_project = NULL, course_id = NULL,
                                  session_id = NULL, block_id = NULL,
                                  activity_id = NULL, dataset_file = NULL,
                                  dataset_source = NULL, dataset_license = NULL,
                                  required_columns = c("label", "x", "y", "z"),
                                  seed = 2026, web_r_version = "0.6.0",
                                  storage = "browser-local",
                                  export_consent_required = TRUE,
                                  research_use = "separate-consent",
                                  education = NULL,
                                  evidence_file = "scene/evidence.json",
                                  evidence_hash = NULL,
                                  overwrite = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  ensure_dir(path)
  output <- file.path(path, "lesson-manifest.json")
  if (file.exists(output) && !isTRUE(overwrite)) {
    stop("lesson-manifest.json already exists; use overwrite = TRUE to replace it", call. = FALSE)
  }
  manifest <- default_rclaimlab_manifest(
    path = path, lesson_id = lesson_id, title = title,
    source_platform = source_platform, source_project = source_project,
    course_id = course_id, session_id = session_id, block_id = block_id,
    activity_id = activity_id, dataset_file = dataset_file,
    dataset_source = dataset_source, dataset_license = dataset_license,
    required_columns = required_columns, seed = seed,
    web_r_version = web_r_version, storage = storage,
    export_consent_required = export_consent_required, research_use = research_use,
    education = education, evidence_file = evidence_file,
    evidence_hash = evidence_hash
  )
  write_json_object(manifest, output)
  invisible(output)
}

#' Read a lesson manifest
#'
#' @param path Lesson directory or manifest JSON path.
#' @return The parsed manifest list.
#' @export
read_lesson_manifest <- function(path = ".") {
  manifest_path <- if (dir.exists(path)) file.path(path, "lesson-manifest.json") else path
  if (!file.exists(manifest_path)) stop("lesson-manifest.json was not found", call. = FALSE)
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("reading a lesson manifest requires the optional jsonlite package", call. = FALSE)
  }
  jsonlite::fromJSON(manifest_path, simplifyVector = TRUE)
}

#' Validate an R-ClaimLab lesson manifest
#'
#' @param manifest A manifest list or a lesson directory/manifest JSON path.
#' @return Invisibly returns TRUE when the manifest satisfies the version 2 contract.
#' @export
validate_lesson_manifest <- function(manifest = ".") {
  value <- if (is.list(manifest)) manifest else read_lesson_manifest(manifest)
  required <- c("manifest_version", "lesson_id", "title", "r_contract",
                "reproducibility", "privacy", "education", "evidence", "artifacts")
  missing <- setdiff(required, names(value))
  if (length(missing)) stop("lesson manifest is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  if (!identical(as.character(value$manifest_version), "2.0")) {
    stop("unsupported lesson manifest version; expected 2.0", call. = FALSE)
  }
  contract <- value$r_contract
  if (!is.list(contract) || !identical(as.character(contract$required_columns), c("label", "x", "y", "z"))) {
    stop("lesson manifest r_contract must require label, x, y, and z", call. = FALSE)
  }
  reproducibility <- value$reproducibility
  if (!is.list(reproducibility) || is.null(reproducibility$seed) ||
      is.null(reproducibility$web_r_version)) {
    stop("lesson manifest reproducibility must declare seed and web_r_version", call. = FALSE)
  }
  privacy <- value$privacy
  if (!is.list(privacy) || is.null(privacy$storage) || is.null(privacy$export_consent_required)) {
    stop("lesson manifest privacy must declare storage and export consent", call. = FALSE)
  }
  evidence <- value$evidence
  if (!is.list(evidence) || !identical(as.character(evidence$schema_version), "rclaimlab-evidence-2") ||
      is.null(evidence$artifact) || !nzchar(as.character(evidence$artifact))) {
    stop("lesson manifest evidence must declare the v2 schema and artifact", call. = FALSE)
  }
  if (!is.null(value$education)) {
    education <- value$education
    if (!is.list(education) || is.null(education$audience) ||
        is.null(education$estimated_minutes) || is.null(education$objectives) ||
        length(as.character(education$objectives)) < 1L ||
        length(suppressWarnings(as.numeric(education$estimated_minutes))) != 1L ||
        is.na(suppressWarnings(as.numeric(education$estimated_minutes)))) {
      stop("lesson manifest education must declare audience, estimated_minutes, and at least one objective", call. = FALSE)
    }
  }
  artifacts <- value$artifacts
  if (!is.list(artifacts) || !all(c("lesson_entrypoint", "scene", "points", "evidence") %in% names(artifacts))) {
    stop("lesson manifest artifacts must include lesson_entrypoint, scene, points, and evidence", call. = FALSE)
  }
  artifact_paths <- unlist(artifacts, use.names = FALSE)
  if (any(grepl("(^|[/\\\\])\\.\\.([/\\\\]|$)", artifact_paths, perl = TRUE)) ||
      any(grepl("^[A-Za-z]:[/\\\\]", artifact_paths, perl = TRUE))) {
    stop("lesson manifest artifact paths must be relative to the lesson", call. = FALSE)
  }
  invisible(TRUE)
}

#' Write a version 2 learner-controlled receipt
#'
#' @param path Lesson directory.
#' @param attempt_number Integer attempt number.
#' @param orientation,prediction,explanation,explanation_criteria Learning-stage evidence.
#' @param evidence_point Selected observation and evidence identifiers.
#' @param transfer_response,transfer_point Transfer-stage evidence.
#' @param source_platform,course_id,session_id,block_id,activity_id Source provenance.
#' @param seed,input_data,scene_files Reproducibility inputs.
#' @param evidence_hash Linked Evidence IR hash.
#' @param outcome Completion state.
#' @param consent Receipt storage and consent state.
#' @param overwrite Whether an existing receipt may be replaced.
#' @return Invisibly returns an `rclaimlab_receipt` with its file path attribute.
#' @export
write_learning_receipt <- function(path = ".", attempt_number = 1,
                                   orientation = list(), prediction = "", explanation = "",
                                   explanation_criteria = list(), evidence_point = NULL,
                                   transfer_response = "", transfer_point = NULL,
                                   source_platform = "rclaimlab",
                                   course_id = NULL, session_id = NULL,
                                   block_id = NULL, activity_id = NULL,
                                   seed = 2026, input_data = NULL,
                                   scene_files = c("scene/index.html", "scene/points.json"),
                                   evidence_hash = NULL, outcome = "in_progress",
                                   consent = "local-only", overwrite = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  ensure_dir(file.path(path, "checks"))
  output <- file.path(path, "checks", "learning-receipt.json")
  if (file.exists(output) && !isTRUE(overwrite)) {
    stop("learning-receipt.json already exists; use overwrite = TRUE to replace it", call. = FALSE)
  }
  file_hashes <- stats::setNames(as.list(rep(NA_character_, length(scene_files))), scene_files)
  for (i in seq_along(scene_files)) {
    candidate <- file.path(path, scene_files[[i]])
    if (file.exists(candidate)) file_hashes[[i]] <- unname(tools::md5sum(candidate))
  }
  input_hash <- NA_character_
  if (!is.null(input_data)) {
    input_hash <- unname(tools::md5sum(input_data))
    if (length(input_hash) == 0L) input_hash <- NA_character_
  }
  receipt <- list(
    receipt_version = "2.0",
    schema_version = "rclaimlab-receipt-2",
    generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    source_platform = as.character(source_platform),
    course_id = course_id, session_id = session_id,
    block_id = block_id, activity_id = activity_id,
    attempt_number = as.integer(attempt_number),
    orientation = orientation,
    prediction = as.character(prediction),
    explanation = as.character(explanation),
    explanation_criteria = explanation_criteria,
    evidence_point = evidence_point,
    transfer_response = as.character(transfer_response),
    transfer_point = transfer_point,
    outcome = as.character(outcome),
    reproducibility = list(
      seed = seed,
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      web_r_version = "0.6.0",
      input_data_md5 = input_hash,
      scene_files_md5 = file_hashes
    ),
    evidence = list(artifact_hash = evidence_hash),
    privacy = list(consent = as.character(consent), storage = "browser-local")
  )
  write_json_object(receipt, output)
  receipt <- structure(receipt, class = c("rclaimlab_receipt", "list"))
  attr(receipt, "path") <- output
  invisible(receipt)
}

#' Read an R-ClaimLab learning receipt
#'
#' @param path Path to a receipt JSON file or a lesson directory.
#' @return An object of class `rclaimlab_receipt`.
#' @export
read_learning_receipt <- function(path = ".") {
  receipt_path <- if (dir.exists(path)) file.path(path, "checks", "learning-receipt.json") else path
  if (!file.exists(receipt_path)) stop("learning receipt was not found", call. = FALSE)
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("reading a learning receipt requires jsonlite", call. = FALSE)
  value <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
  value <- structure(value, class = c("rclaimlab_receipt", "list"))
  attr(value, "path") <- normalizePath(receipt_path, winslash = "/")
  validate_learning_receipt(value)
  value
}

#' Validate an R-ClaimLab learning receipt
#'
#' @param receipt A receipt list or a JSON file path.
#' @return Invisibly returns TRUE when the receipt satisfies the version 2 contract.
#' @export
validate_learning_receipt <- function(receipt) {
  value <- if (is.list(receipt)) receipt else {
    if (!file.exists(receipt)) stop("learning receipt was not found", call. = FALSE)
    if (!requireNamespace("jsonlite", quietly = TRUE)) stop("reading a learning receipt requires jsonlite", call. = FALSE)
    read_learning_receipt(receipt)
  }
  required <- c("receipt_version", "schema_version", "attempt_number", "orientation", "prediction",
                "explanation", "explanation_criteria", "transfer_response", "outcome",
                "reproducibility", "evidence", "privacy")
  missing <- setdiff(required, names(value))
  if (length(missing)) stop("learning receipt is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  if (!identical(as.character(value$receipt_version), "2.0") ||
      !identical(as.character(value$schema_version), "rclaimlab-receipt-2")) {
    stop("unsupported learning receipt schema; expected rclaimlab-receipt-2", call. = FALSE)
  }
  if (length(value$attempt_number) != 1L || is.na(suppressWarnings(as.integer(value$attempt_number)))) {
    stop("learning receipt attempt_number must be an integer", call. = FALSE)
  }
  if (!is.list(value$reproducibility) || is.null(value$reproducibility$seed) ||
      is.null(value$reproducibility$r_version) || is.null(value$reproducibility$web_r_version)) {
    stop("learning receipt reproducibility must declare seed, r_version, and web_r_version", call. = FALSE)
  }
  if (!is.list(value$privacy) || is.null(value$privacy$storage) || is.null(value$privacy$consent)) {
    stop("learning receipt privacy must declare storage and consent", call. = FALSE)
  }
  invisible(TRUE)
}

#' @export
print.rclaimlab_receipt <- function(x, ...) {
  cat("<rclaimlab_receipt>", x$outcome, "\n")
  cat("Attempt:", x$attempt_number, " Evidence:", x$evidence$artifact_hash %||% "not recorded", "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_receipt <- function(object, ...) {
  list(
    schema_version = object$schema_version,
    attempt_number = object$attempt_number,
    outcome = object$outcome,
    criteria = object$explanation_criteria,
    evidence_hash = object$evidence$artifact_hash
  )
}

#' @export
as.data.frame.rclaimlab_receipt <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    attempt_number = as.integer(x$attempt_number),
    prediction = paste(unlist(x$prediction), collapse = " "),
    explanation = paste(unlist(x$explanation), collapse = " "),
    transfer_response = paste(unlist(x$transfer_response), collapse = " "),
    outcome = paste(unlist(x$outcome), collapse = " "),
    evidence_hash = paste(unlist(x$evidence$artifact_hash), collapse = " "),
    stringsAsFactors = FALSE
  )
}
