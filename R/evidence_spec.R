#' Define one learning task
#'
#' @param id Stable task identifier.
#' @param type One stage in the R-LearnXR evidence-building sequence.
#' @param prompt Learner-facing instruction.
#' @param criteria Named character vector describing completion criteria.
#' @param evidence_required Whether the task must cite evidence from the compiled analysis.
#' @return An object of class `rlearnxr_task`.
#' @export
task_spec <- function(id, type, prompt, criteria = character(), evidence_required = TRUE) {
  type <- match.arg(
    type,
    c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
  )
  assert_scalar_text(id, "id")
  assert_scalar_text(prompt, "prompt")
  criteria_names <- names(criteria)
  criteria <- as.character(criteria)
  names(criteria) <- criteria_names
  if (length(criteria) && (is.null(names(criteria)) || any(!nzchar(names(criteria))))) {
    stop("criteria must be a named character vector", call. = FALSE)
  }
  structure(
    list(
      id = id,
      type = type,
      prompt = prompt,
      criteria = criteria,
      evidence_required = isTRUE(evidence_required)
    ),
    class = c("rlearnxr_task", "list")
  )
}

#' Define an evidence representation
#'
#' @param type Representation type: semantic table, two-dimensional plot, or three-dimensional scene.
#' @param dimensions Optional evidence dimension identifiers used by the representation.
#' @param fallback Required non-spatial fallback representation.
#' @param title Human-readable representation title.
#' @return An object of class `rlearnxr_representation`.
#' @export
representation_spec <- function(type = c("table", "plot2d", "scene3d"), dimensions = NULL,
                                fallback = "table", title = NULL) {
  type <- match.arg(type)
  fallback <- match.arg(fallback, c("table", "text"))
  if (!is.null(dimensions)) {
    dimensions <- as.character(dimensions)
    if (!length(dimensions) || anyNA(dimensions) || any(!nzchar(dimensions))) {
      stop("dimensions must contain non-empty identifiers", call. = FALSE)
    }
  }
  if (is.null(title)) title <- switch(type, table = "Evidence table", plot2d = "Two-dimensional evidence", scene3d = "Three-dimensional evidence")
  assert_scalar_text(title, "title")
  structure(
    list(type = type, dimensions = dimensions, fallback = fallback, title = title),
    class = c("rlearnxr_representation", "list")
  )
}

#' Define a compilable R-LearnXR lesson
#'
#' @param id Stable lesson identifier.
#' @param title Human-readable lesson title.
#' @param outcomes Character vector of measurable learning outcomes.
#' @param evidence An `rlearnxr_evidence` object.
#' @param tasks List of `task_spec()` objects.
#' @param representations List of `representation_spec()` objects.
#' @param accessibility Accessibility contract for generated representations.
#' @param content_license Reuse license for original lesson content.
#' @return An object of class `rlearnxr_lesson`.
#' @export
lesson_spec <- function(id, title, outcomes, evidence = NULL, tasks = list(),
                        representations = list(
                          representation_spec("table"),
                          representation_spec("plot2d"),
                          representation_spec("scene3d")
                        ),
                        accessibility = list(
                          semantic_table = TRUE,
                          keyboard_path = TRUE,
                          text_alternative = TRUE,
                          reduced_motion = TRUE
                        ),
                        content_license = "CC BY 4.0") {
  assert_scalar_text(id, "id")
  assert_scalar_text(title, "title")
  outcomes <- as.character(outcomes)
  if (!length(outcomes) || anyNA(outcomes) || any(!nzchar(trimws(outcomes)))) {
    stop("outcomes must contain at least one non-empty learning outcome", call. = FALSE)
  }
  if (!is.null(evidence) && !inherits(evidence, "rlearnxr_evidence")) {
    stop("evidence must be an rlearnxr_evidence object", call. = FALSE)
  }
  if (length(tasks) && any(!vapply(tasks, inherits, logical(1), what = "rlearnxr_task"))) {
    stop("tasks must contain task_spec() objects", call. = FALSE)
  }
  if (!length(representations) || any(!vapply(representations, inherits, logical(1), what = "rlearnxr_representation"))) {
    stop("representations must contain representation_spec() objects", call. = FALSE)
  }
  if (!is.list(accessibility) || !isTRUE(accessibility$semantic_table) || !isTRUE(accessibility$keyboard_path)) {
    stop("accessibility must require a semantic table and keyboard path", call. = FALSE)
  }
  assert_scalar_text(content_license, "content_license")
  value <- structure(
    list(
      schema_version = "rlearnxr-lesson-2",
      id = id,
      title = title,
      outcomes = outcomes,
      evidence = evidence,
      tasks = tasks,
      representations = representations,
      accessibility = accessibility,
      content_license = content_license
    ),
    class = c("rlearnxr_lesson", "list")
  )
  validate_lesson_spec(value)
  value
}

#' Validate an R-LearnXR lesson specification
#'
#' @param x A lesson specification.
#' @return Invisibly returns `TRUE` when valid.
#' @export
validate_lesson_spec <- function(x) {
  if (!inherits(x, "rlearnxr_lesson")) stop("x must be an rlearnxr_lesson", call. = FALSE)
  if (!identical(x$schema_version, "rlearnxr-lesson-2")) stop("unsupported lesson specification schema", call. = FALSE)
  task_ids <- vapply(x$tasks, `[[`, character(1), "id")
  if (anyDuplicated(task_ids)) stop("lesson task ids must be unique", call. = FALSE)
  task_types <- vapply(x$tasks, `[[`, character(1), "type")
  canonical <- c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
  if (length(task_types) && is.unsorted(match(task_types, canonical), strictly = FALSE)) {
    stop("lesson tasks must follow the evidence-building sequence", call. = FALSE)
  }
  invisible(TRUE)
}

#' @export
print.rlearnxr_lesson <- function(x, ...) {
  cat("<rlearnxr_lesson>", x$id, "\n")
  cat("Title:", x$title, "\n")
  cat("Outcomes:", length(x$outcomes), " Tasks:", length(x$tasks), " Representations:", length(x$representations), "\n")
  invisible(x)
}

#' @export
summary.rlearnxr_lesson <- function(object, ...) {
  list(
    id = object$id,
    title = object$title,
    outcomes = object$outcomes,
    task_types = vapply(object$tasks, `[[`, character(1), "type"),
    representation_types = vapply(object$representations, `[[`, character(1), "type"),
    evidence_hash = if (is.null(object$evidence)) NA_character_ else object$evidence$analysis$artifact_hash
  )
}

#' @export
as.data.frame.rlearnxr_lesson <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    task_id = vapply(x$tasks, `[[`, character(1), "id"),
    task_type = vapply(x$tasks, `[[`, character(1), "type"),
    prompt = vapply(x$tasks, `[[`, character(1), "prompt"),
    evidence_required = vapply(x$tasks, `[[`, logical(1), "evidence_required"),
    stringsAsFactors = FALSE
  )
}

assert_scalar_text <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    stop(name, " must be one non-empty character string", call. = FALSE)
  }
  invisible(TRUE)
}
