#' Compile an analysis object into a portable evidence lesson
#'
#' @param lesson An `rlearnxr_lesson` containing linked evidence.
#' @param output_dir Destination lesson directory.
#' @param overwrite Whether compiler-owned files may be replaced.
#' @return An object of class `rlearnxr_build`.
#' @export
compile_lesson <- function(lesson, output_dir, overwrite = FALSE) {
  validate_lesson_spec(lesson)
  if (is.null(lesson$evidence)) stop("lesson evidence is required before compilation", call. = FALSE)
  validate_rlearnxr_evidence(lesson$evidence)
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  owned <- c("evidence.json", "lesson-spec.json", "lesson-manifest.json", "index.qmd", "_quarto.yml")
  if (!isTRUE(overwrite) && any(file.exists(file.path(output_dir, owned)))) {
    stop("compiled lesson files already exist; use overwrite = TRUE to replace them", call. = FALSE)
  }
  ensure_dir(output_dir)
  ensure_dir(file.path(output_dir, "data"))
  ensure_dir(file.path(output_dir, "scene"))
  ensure_dir(file.path(output_dir, "checks"))
  evidence_path <- file.path(output_dir, "evidence.json")
  lesson_path <- file.path(output_dir, "lesson-spec.json")
  jsonlite::write_json(unclass(lesson$evidence), evidence_path, auto_unbox = TRUE, dataframe = "rows", pretty = TRUE, na = "null", null = "null", digits = NA)
  lesson_json <- unclass(lesson)
  lesson_json$evidence <- list(
    schema_version = lesson$evidence$schema_version,
    artifact = "evidence.json",
    artifact_hash = lesson$evidence$analysis$artifact_hash
  )
  lesson_json$tasks <- lapply(lesson$tasks, unclass)
  lesson_json$representations <- lapply(lesson$representations, unclass)
  jsonlite::write_json(lesson_json, lesson_path, auto_unbox = TRUE, pretty = TRUE, na = "null", null = "null")
  wide <- as.data.frame(lesson$evidence)
  utils::write.csv(wide, file.path(output_dir, "data", "evidence-table.csv"), row.names = FALSE, na = "")
  dimension_labels <- lesson$evidence$dimensions$label
  selected <- seq_len(min(3L, length(dimension_labels)))
  scene <- data.frame(
    observation_id = wide$observation_id,
    label = wide$label,
    x = wide[[selected[[1]] + 2L]],
    y = wide[[selected[[2]] + 2L]],
    z = if (length(selected) >= 3L) wide[[selected[[3]] + 2L]] else 0,
    stringsAsFactors = FALSE
  )
  render_scene(
    scene, "x", "y", "z", labels = scene$label,
    observation_ids = scene$observation_id,
    evidence_ids = evidence_ids_by_observation(lesson$evidence),
    output_dir = file.path(output_dir, "scene"), title = lesson$title, overwrite = TRUE
  )
  writeLines(c(
    "project:", "  type: website", "  output-dir: _site",
    "execute:", "  freeze: auto", "format:", "  html:", "    toc: true"
  ), file.path(output_dir, "_quarto.yml"), useBytes = TRUE)
  writeLines(c(
    "# Data License and Provenance", "",
    "The compiled evidence table is derived from the R analysis object named in evidence.json.",
    "Original lesson content is CC BY 4.0. Source data retain their original license and must be documented by the lesson author before publication.",
    "The artifact hash, source call, seed, R version, and package versions provide transformation provenance."
  ), file.path(output_dir, "DATA_LICENSE.md"), useBytes = TRUE)
  writeLines(c(
    "{", '  "R": {', paste0('    "Version": "', paste(R.version$major, R.version$minor, sep = "."), '",'),
    '    "Repositories": [{"Name": "CRAN", "URL": "https://cloud.r-project.org"}]',
    "  },", '  "Packages": {}', "}"
  ), file.path(output_dir, "renv.lock"), useBytes = TRUE)
  qmd <- c(
    "---", paste0('title: "', gsub('"', '\\"', lesson$title), '"'), "format: html", "---", "",
    "# Learning objectives", "", paste0("- ", lesson$outcomes), "",
    "# Predict, explore, explain, repair, and transfer", "",
    "Predict before inspecting the evidence. Explore the linked table or scene, explain a claim with evidence, repair the explanation, and transfer it to a new observation.", "",
    "```{r}", "#| echo: true", paste0("set.seed(", lesson$evidence$analysis$seed, ")"), "```", "",
    "# Evidence compiler artifact", "",
    paste0("This lesson was compiled from `", lesson$evidence$analysis$engine, "` evidence with hash `", lesson$evidence$analysis$artifact_hash, "`."), "",
    "[Open the synchronized browser laboratory](scene/index.html)", "",
    "The semantic evidence artifact is available at [`evidence.json`](evidence.json)."
  )
  writeLines(qmd, file.path(output_dir, "index.qmd"), useBytes = TRUE)
  write_lesson_manifest(
    output_dir,
    lesson_id = lesson$id,
    title = lesson$title,
    evidence_file = "evidence.json",
    evidence_hash = lesson$evidence$analysis$artifact_hash,
    education = list(
      audience = "data-science learners",
      estimated_minutes = 20L,
      prerequisites = character(),
      objectives = lesson$outcomes,
      sequence = vapply(lesson$tasks, `[[`, character(1), "type"),
      assessment = "Evidence-linked explanation and transfer",
      instructor_materials = character(),
      accessibility_alternative = "semantic table and keyboard path",
      extension_activities = character()
    ),
    overwrite = TRUE
  )
  files <- file.path(output_dir, c("evidence.json", "lesson-spec.json", "lesson-manifest.json", "index.qmd", "_quarto.yml", "DATA_LICENSE.md", "renv.lock", "data/evidence-table.csv", "scene/index.html", "scene/points.json", "scene/evidence.json"))
  value <- structure(
    list(
      schema_version = "rlearnxr-build-2",
      lesson_id = lesson$id,
      output_dir = output_dir,
      evidence_hash = lesson$evidence$analysis$artifact_hash,
      files = files,
      checks = check_lesson(output_dir, write_report = TRUE, strict = FALSE)
    ),
    class = c("rlearnxr_build", "list")
  )
  value
}

#' @export
print.rlearnxr_build <- function(x, ...) {
  cat("<rlearnxr_build>", x$lesson_id, "\n")
  cat("Output:", x$output_dir, "\n")
  cat("Evidence hash:", x$evidence_hash, "\n")
  cat("Checks:", sum(x$checks$status == "PASS"), "PASS,", sum(x$checks$status == "FAIL"), "FAIL\n")
  invisible(x)
}

#' @export
summary.rlearnxr_build <- function(object, ...) {
  list(
    lesson_id = object$lesson_id,
    output_dir = object$output_dir,
    evidence_hash = object$evidence_hash,
    files = object$files,
    checks = table(object$checks$status)
  )
}

#' @export
as.data.frame.rlearnxr_build <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    artifact = basename(x$files),
    path = x$files,
    exists = file.exists(x$files),
    stringsAsFactors = FALSE
  )
}

evidence_ids_by_observation <- function(evidence) {
  split(evidence$values$evidence_id, evidence$values$observation_id)
}
