#' Render linked evidence as a portable browser scene
#'
#' @param data A data frame.
#' @param x,y,z Names of three finite numeric columns.
#' @param labels Optional unique learner-facing labels.
#' @param observation_ids Optional stable observation identifiers.
#' @param evidence_ids Optional list of evidence identifiers keyed by observation.
#' @param output_dir Destination scene directory.
#' @param title Scene title.
#' @param learning_contract Optional `rlearnxr_lesson` or browser-contract list
#'   used to render method-specific prompts, criteria, diagnostics, and provenance.
#' @param min_rows Minimum observations accepted by this renderer. Direct 3D
#'   authoring defaults to three; the compiler may lower this for table/2D-first
#'   aggregate evidence.
#' @param overwrite Whether compiler-owned scene files may be replaced.
#' @return Invisibly returns paths to HTML, point JSON, and Evidence IR artifacts.
#' @export
render_scene <- function(data, x, y, z, labels = NULL, observation_ids = NULL,
                          evidence_ids = NULL, output_dir = "scene",
                          title = "R-LearnXR 3D Scene", learning_contract = NULL,
                          min_rows = 3L, overwrite = FALSE) {
  scene_data <- validate_scene_data(
    data, x, y, z, labels, observation_ids = observation_ids, min_rows = min_rows
  )
  if (!is.character(title) || length(title) != 1L || is.na(title) || !nzchar(trimws(title))) {
    stop("title must be one non-empty character string", call. = FALSE)
  }
  if (!is.null(evidence_ids) && !is.list(evidence_ids)) {
    stop("evidence_ids must be a list keyed by observation id", call. = FALSE)
  }

  ensure_dir(output_dir)
  output_files <- file.path(output_dir, c("points.json", "index.html", "evidence.json"))
  if (!isTRUE(overwrite) && any(file.exists(output_files))) {
    stop("scene output already exists; use overwrite = TRUE to replace it", call. = FALSE)
  }
  scene_evidence <- as_rlearnxr_evidence(
    scene_data[c("x", "y", "z")], labels = scene_data$label,
    analysis_call = "render_scene(data)", seed = 2026L
  )
  scene_evidence$observations$observation_id <- scene_data$observation_id
  scene_evidence$values$observation_id <- rep(scene_data$observation_id, times = 3L)
  scene_evidence$links$observation_id <- scene_evidence$values$observation_id
  scene_evidence$analysis$artifact_hash <- evidence_hash(within(unclass(scene_evidence), analysis$artifact_hash <- NULL))
  validate_rlearnxr_evidence(scene_evidence)
  if (is.null(evidence_ids)) {
    evidence_ids <- split(scene_evidence$values$evidence_id, scene_evidence$values$observation_id)
  }
  point_records <- lapply(seq_len(nrow(scene_data)), function(i) list(
    observation_id = scene_data$observation_id[[i]],
    evidence_ids = as.character(evidence_ids[[scene_data$observation_id[[i]]]] %||% evidence_ids[[i]] %||% character()),
    x = scene_data$x[[i]], y = scene_data$y[[i]], z = scene_data$z[[i]],
    label = scene_data$label[[i]]
  ))
  points_json <- as.character(jsonlite::toJSON(
    point_records, auto_unbox = TRUE, null = "null", na = "null", digits = NA
  ))
  writeLines(points_json, file.path(output_dir, "points.json"), useBytes = TRUE)
  write_rlearnxr_evidence(scene_evidence, file.path(output_dir, "evidence.json"), overwrite = TRUE)
  browser_contract <- if (inherits(learning_contract, "rlearnxr_lesson")) {
    lesson_scene_contract(learning_contract)
  } else if (is.list(learning_contract)) {
    learning_contract
  } else {
    default_scene_contract(title)
  }
  embedded_points <- gsub("<", "\\u003c", points_json, fixed = TRUE)
  writeLines(scene_html(title, embedded_points, browser_contract), file.path(output_dir, "index.html"), useBytes = TRUE)
  invisible(list(
    index = file.path(output_dir, "index.html"),
    points = file.path(output_dir, "points.json"),
    evidence = file.path(output_dir, "evidence.json")
  ))
}
