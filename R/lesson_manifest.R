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
                                       research_use = "separate-consent") {
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
    export_consent_required = export_consent_required, research_use = research_use
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
