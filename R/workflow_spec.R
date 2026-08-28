workflow_activity_types <- function() c(
  "frame", "inspect", "clean", "transform", "describe", "compare",
  "split", "baseline", "fit", "diagnose", "evaluate", "slice",
  "explain", "challenge", "revise", "communicate", "reproduce",
  "handoff", "approve"
)

workflow_roles <- function() c(
  "data_analyst", "data_scientist", "model_reviewer", "guided_learning"
)

#' Define one role-adaptive workflow activity
#'
#' @param id Stable activity identifier.
#' @param type Activity type from the workflow registry.
#' @param prompt User-facing instruction.
#' @param criteria Named completion criteria.
#' @param depends_on IDs of prerequisite activities.
#' @param evidence_required Whether completion must cite compiled evidence.
#' @param input_artifacts Planned artifact IDs consumed by the activity.
#' @param output_type Output contract label.
#' @return An `rclaimlab_activity`.
#' @export
activity_spec <- function(id, type, prompt, criteria = character(),
                          depends_on = character(), evidence_required = TRUE,
                          input_artifacts = character(), output_type = "decision") {
  assert_scalar_text(id, "id")
  type <- match.arg(type, workflow_activity_types())
  assert_scalar_text(prompt, "prompt")
  assert_scalar_text(output_type, "output_type")
  criteria_names <- names(criteria)
  criteria <- as.character(criteria)
  names(criteria) <- criteria_names
  if (length(criteria) && (is.null(names(criteria)) || any(!nzchar(names(criteria))))) {
    stop("criteria must be a named character vector", call. = FALSE)
  }
  depends_on <- unique(as.character(depends_on))
  input_artifacts <- unique(as.character(input_artifacts))
  if (anyNA(depends_on) || any(!nzchar(depends_on)) ||
      anyNA(input_artifacts) || any(!nzchar(input_artifacts))) {
    stop("depends_on and input_artifacts must contain non-empty identifiers", call. = FALSE)
  }
  structure(
    list(
      id = id, type = type, prompt = prompt, criteria = criteria,
      depends_on = depends_on, evidence_required = isTRUE(evidence_required),
      input_artifacts = input_artifacts, output_type = output_type
    ),
    class = c("rclaimlab_activity", "list")
  )
}

#' Define a role-adaptive evidence workflow
#'
#' @param id,title,role,goal Workflow identity and analytical purpose.
#' @param dataset Imported dataset, or `NULL` for a converted legacy lesson.
#' @param activities Ordered activity specifications.
#' @param representations Evidence representations.
#' @param deliverables Named deliverable descriptions.
#' @param artifact_plan Planned artifact identifiers referenced by activities.
#' @param approvals Explicit author approvals required before execution.
#' @param analysis Analysis configuration.
#' @return An `rclaimlab_workflow`.
#' @export
workflow_spec <- function(id, title, role, goal, dataset, activities,
                          representations = list(
                            representation_spec("table"),
                            representation_spec("plot2d"),
                            representation_spec("scene3d")
                          ),
                          deliverables, artifact_plan = character(),
                          approvals = list(
                            question = FALSE, variable_roles = FALSE,
                            method = FALSE, missing_values = FALSE,
                            publication = FALSE
                          ), analysis = list()) {
  assert_scalar_text(id, "id")
  assert_scalar_text(title, "title")
  role <- match.arg(role, workflow_roles())
  assert_scalar_text(goal, "goal")
  if (!is.null(dataset) && !inherits(dataset, "rclaimlab_dataset")) {
    stop("dataset must be an rclaimlab_dataset or NULL", call. = FALSE)
  }
  if (!length(activities) || any(!vapply(activities, inherits, logical(1), what = "rclaimlab_activity"))) {
    stop("activities must contain activity_spec() objects", call. = FALSE)
  }
  if (!length(representations) || any(!vapply(representations, inherits, logical(1), what = "rclaimlab_representation"))) {
    stop("representations must contain representation_spec() objects", call. = FALSE)
  }
  if (!is.list(deliverables) || !length(deliverables) || is.null(names(deliverables)) || any(!nzchar(names(deliverables)))) {
    stop("deliverables must be a non-empty named list", call. = FALSE)
  }
  artifact_plan <- unique(as.character(artifact_plan))
  required_approvals <- c("question", "variable_roles", "method", "missing_values", "publication")
  approvals <- utils::modifyList(stats::setNames(as.list(rep(FALSE, length(required_approvals))), required_approvals), approvals)
  approvals <- lapply(approvals[required_approvals], isTRUE)
  value <- structure(
    list(
      schema_version = "rclaimlab-workflow-1", id = id, title = title,
      role = role, goal = goal, dataset = dataset, activities = activities,
      representations = representations, deliverables = deliverables,
      artifact_plan = artifact_plan, approvals = approvals,
      analysis = analysis, upstream = NULL
    ),
    class = c("rclaimlab_workflow", "list")
  )
  validate_workflow_spec(value)
  value
}

#' Validate a role-adaptive workflow specification
#'
#' @param x Workflow specification.
#' @return Invisibly returns `TRUE`.
#' @export
validate_workflow_spec <- function(x) {
  if (!inherits(x, "rclaimlab_workflow") || !identical(x$schema_version, "rclaimlab-workflow-1")) {
    stop("x must satisfy rclaimlab-workflow-1", call. = FALSE)
  }
  ids <- vapply(x$activities, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("workflow activity ids must be unique", call. = FALSE)
  for (activity in x$activities) {
    missing_dependencies <- setdiff(activity$depends_on, ids)
    if (length(missing_dependencies)) {
      stop("activity '", activity$id, "' has unknown dependencies: ", paste(missing_dependencies, collapse = ", "), call. = FALSE)
    }
    missing_artifacts <- setdiff(activity$input_artifacts, x$artifact_plan)
    if (length(missing_artifacts)) {
      stop("activity '", activity$id, "' references unplanned artifacts: ", paste(missing_artifacts, collapse = ", "), call. = FALSE)
    }
  }
  if (workflow_has_cycle(x$activities)) stop("workflow activity graph contains a cycle", call. = FALSE)
  required <- switch(
    x$role,
    data_analyst = c("frame", "inspect", "communicate", "handoff"),
    data_scientist = c("frame", "inspect", "split", "fit", "evaluate", "handoff"),
    model_reviewer = c("inspect", "challenge", "reproduce", "approve"),
    guided_learning = c("frame", "inspect", "explain", "reproduce")
  )
  types <- vapply(x$activities, `[[`, character(1), "type")
  missing_types <- setdiff(required, types)
  if (length(missing_types)) {
    stop("role '", x$role, "' requires activities: ", paste(missing_types, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

workflow_has_cycle <- function(activities) {
  dependencies <- stats::setNames(lapply(activities, `[[`, "depends_on"), vapply(activities, `[[`, character(1), "id"))
  state <- stats::setNames(rep(0L, length(dependencies)), names(dependencies))
  visit <- function(id) {
    if (state[[id]] == 1L) return(TRUE)
    if (state[[id]] == 2L) return(FALSE)
    state[[id]] <<- 1L
    if (any(vapply(dependencies[[id]], visit, logical(1)))) return(TRUE)
    state[[id]] <<- 2L
    FALSE
  }
  any(vapply(names(dependencies), visit, logical(1)))
}

#' Convert a supported object to a workflow
#'
#' @param x Object to convert.
#' @param ... Conversion arguments.
#' @export
as_rclaimlab_workflow <- function(x, ...) UseMethod("as_rclaimlab_workflow")

#' @export
as_rclaimlab_workflow.default <- function(x, ...) {
  stop("no R-ClaimLab workflow converter is available for class: ", paste(class(x), collapse = "/"), call. = FALSE)
}

#' @export
as_rclaimlab_workflow.rclaimlab_lesson <- function(x, ...) {
  validate_lesson_spec(x)
  mapping <- c(
    orient = "frame", predict = "frame", run_r = "transform", explore = "inspect",
    explain = "explain", repair = "revise", transfer = "challenge", reproduce = "reproduce"
  )
  activities <- lapply(seq_along(x$tasks), function(index) {
    task <- x$tasks[[index]]
    activity_spec(
      id = task$id, type = unname(mapping[[task$type]]), prompt = task$prompt,
      criteria = task$criteria,
      depends_on = if (index > 1L) x$tasks[[index - 1L]]$id else character(),
      evidence_required = task$evidence_required,
      input_artifacts = if (task$evidence_required) "lesson-evidence" else character(),
      output_type = if (task$type == "reproduce") "reproducibility_receipt" else "learning_response"
    )
  })
  value <- workflow_spec(
    id = x$id, title = x$title, role = "guided_learning",
    goal = "build and transfer an evidence-linked explanation", dataset = NULL,
    activities = activities, representations = x$representations,
    deliverables = list(learning_receipt = "Evidence-linked learning receipt"),
    artifact_plan = "lesson-evidence",
    approvals = list(question = TRUE, variable_roles = TRUE, method = TRUE, missing_values = TRUE),
    analysis = list(evidence = x$evidence)
  )
  value$legacy_lesson <- x
  value
}

#' @export
print.rclaimlab_workflow <- function(x, ...) {
  cat("<rclaimlab_workflow>", x$id, "\n")
  cat("Role:", x$role, " Activities:", length(x$activities), " Goal:", x$goal, "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_workflow <- function(object, ...) {
  list(id = object$id, title = object$title, role = object$role, goal = object$goal,
       activity_types = vapply(object$activities, `[[`, character(1), "type"),
       approvals = object$approvals, deliverables = names(object$deliverables))
}

#' @export
as.data.frame.rclaimlab_workflow <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    id = vapply(x$activities, `[[`, character(1), "id"),
    type = vapply(x$activities, `[[`, character(1), "type"),
    prompt = vapply(x$activities, `[[`, character(1), "prompt"),
    evidence_required = vapply(x$activities, `[[`, logical(1), "evidence_required"),
    stringsAsFactors = FALSE
  )
}
