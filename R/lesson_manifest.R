default_rlearnxr_education <- function(education = NULL) {
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
    sequence = c("orient", "predict", "run_r", "explore", "explain", "transfer", "reproduce"),
    assessment = "Use a claim-evidence-limitation-transfer rubric.",
    instructor_materials = character(),
    accessibility_alternative = "semantic table and keyboard path",
    extension_activities = character()
  )
}

default_rlearnxr_manifest <- function(path = ".", lesson_id = NULL, title = NULL,
                                       source_platform = "rlearnxr",
                                       source_project = NULL, course_id = NULL,
                                       session_id = NULL, block_id = NULL,
                                       activity_id = NULL, dataset_file = NULL,
                                       dataset_source = NULL, dataset_license = NULL,
                                       required_columns = c("label", "x", "y", "z"),
                                       seed = 2026, web_r_version = "0.6.0",
                                       storage = "browser-local",
                                       export_consent_required = TRUE,
                                       research_use = "separate-consent",
                                       education = NULL) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (is.null(lesson_id)) lesson_id <- basename(path)
  if (is.null(title)) title <- lesson_id
  if (is.null(source_project)) source_project <- source_platform
  if (is.null(dataset_file)) dataset_file <- "data/source.csv"
  if (is.null(dataset_source)) dataset_source <- ""
  if (is.null(dataset_license)) dataset_license <- ""
  list(
    manifest_version = "1.0",
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
    education = default_rlearnxr_education(education),
    artifacts = list(
      lesson_entrypoint = "index.qmd",
      scene = "scene/index.html",
      points = "scene/points.json",
      reproducibility_report = "checks/reproducibility-report.json",
      learning_receipt = "checks/learning-receipt.json"
    )
  )
}

write_lesson_manifest <- function(path = ".", lesson_id = NULL, title = NULL,
                                  source_platform = "rlearnxr",
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
                                  overwrite = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  ensure_dir(path)
  output <- file.path(path, "lesson-manifest.json")
  if (file.exists(output) && !isTRUE(overwrite)) {
    stop("lesson-manifest.json already exists; use overwrite = TRUE to replace it", call. = FALSE)
  }
  manifest <- default_rlearnxr_manifest(
    path = path, lesson_id = lesson_id, title = title,
    source_platform = source_platform, source_project = source_project,
    course_id = course_id, session_id = session_id, block_id = block_id,
    activity_id = activity_id, dataset_file = dataset_file,
    dataset_source = dataset_source, dataset_license = dataset_license,
    required_columns = required_columns, seed = seed,
    web_r_version = web_r_version, storage = storage,
    export_consent_required = export_consent_required, research_use = research_use,
    education = education
  )
  write_json_object(manifest, output)
  invisible(output)
}

read_lesson_manifest <- function(path = ".") {
  manifest_path <- if (dir.exists(path)) file.path(path, "lesson-manifest.json") else path
  if (!file.exists(manifest_path)) stop("lesson-manifest.json was not found", call. = FALSE)
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("reading a lesson manifest requires the optional jsonlite package", call. = FALSE)
  }
  jsonlite::fromJSON(manifest_path, simplifyVector = TRUE)
}

#' Validate an R-LearnXR lesson manifest
#'
#' @param manifest A manifest list or a lesson directory/manifest JSON path.
#' @return Invisibly returns TRUE when the manifest satisfies the version 1 contract.
#' @export
validate_lesson_manifest <- function(manifest = ".") {
  value <- if (is.list(manifest)) manifest else read_lesson_manifest(manifest)
  required <- c("manifest_version", "lesson_id", "title", "r_contract",
                "reproducibility", "privacy", "artifacts")
  missing <- setdiff(required, names(value))
  if (length(missing)) stop("lesson manifest is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  if (!identical(as.character(value$manifest_version), "1.0")) {
    stop("unsupported lesson manifest version; expected 1.0", call. = FALSE)
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
  if (!is.null(value$education)) {
    education <- value$education
    if (!is.list(education) || is.null(education$audience) ||
        is.null(education$estimated_minutes) || is.null(education$objectives) ||
        length(as.character(education$objectives)) < 3L ||
        length(suppressWarnings(as.numeric(education$estimated_minutes))) != 1L ||
        is.na(suppressWarnings(as.numeric(education$estimated_minutes)))) {
      stop("lesson manifest education must declare audience, estimated_minutes, and at least three objectives", call. = FALSE)
    }
  }
  artifacts <- value$artifacts
  if (!is.list(artifacts) || !all(c("lesson_entrypoint", "scene", "points") %in% names(artifacts))) {
    stop("lesson manifest artifacts must include lesson_entrypoint, scene, and points", call. = FALSE)
  }
  artifact_paths <- unlist(artifacts, use.names = FALSE)
  if (any(grepl("(^|[/\\\\])\\.\\.([/\\\\]|$)", artifact_paths, perl = TRUE)) ||
      any(grepl("^[A-Za-z]:[/\\\\]", artifact_paths, perl = TRUE))) {
    stop("lesson manifest artifact paths must be relative to the lesson", call. = FALSE)
  }
  invisible(TRUE)
}

write_learning_receipt <- function(path = ".", attempt_number = 1,
                                   prediction = "", explanation = "",
                                   source_platform = "rlearnxr",
                                   course_id = NULL, session_id = NULL,
                                   block_id = NULL, activity_id = NULL,
                                   seed = 2026, input_data = NULL,
                                   scene_files = c("scene/index.html", "scene/points.json"),
                                   outcome = "in_progress",
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
    receipt_version = "1.0",
    generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    source_platform = as.character(source_platform),
    course_id = course_id, session_id = session_id,
    block_id = block_id, activity_id = activity_id,
    attempt_number = as.integer(attempt_number),
    prediction = as.character(prediction),
    explanation = as.character(explanation),
    outcome = as.character(outcome),
    reproducibility = list(
      seed = seed,
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      web_r_version = "0.6.0",
      input_data_md5 = input_hash,
      scene_files_md5 = file_hashes
    ),
    privacy = list(consent = as.character(consent), storage = "browser-local")
  )
  write_json_object(receipt, output)
  invisible(output)
}

#' Validate an R-LearnXR learning receipt
#'
#' @param receipt A receipt list or a JSON file path.
#' @return Invisibly returns TRUE when the receipt satisfies the version 1 contract.
#' @export
validate_learning_receipt <- function(receipt) {
  value <- if (is.list(receipt)) receipt else {
    if (!file.exists(receipt)) stop("learning receipt was not found", call. = FALSE)
    if (!requireNamespace("jsonlite", quietly = TRUE)) stop("reading a learning receipt requires jsonlite", call. = FALSE)
    jsonlite::fromJSON(receipt, simplifyVector = FALSE)
  }
  required <- c("receipt_version", "attempt_number", "prediction", "explanation", "outcome", "reproducibility", "privacy")
  missing <- setdiff(required, names(value))
  if (length(missing)) stop("learning receipt is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  if (!identical(as.character(value$receipt_version), "1.0")) stop("unsupported learning receipt version; expected 1.0", call. = FALSE)
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
