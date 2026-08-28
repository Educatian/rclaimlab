#' Draft reviewable workflow wording with an optional provider callback
#'
#' The callback receives schema and aggregate profile information only. It must
#' return a list containing `title`, `question`, and named `prompts`. Statistical
#' methods, code, evidence, and approvals cannot be changed by this function.
#'
#' @param workflow Workflow specification.
#' @param provider Optional function receiving a safe request list.
#' @param include_rows Must remain `FALSE` in v2.1.
#' @return A reviewable `rclaimlab_workflow_draft`.
#' @export
draft_workflow_text <- function(workflow, provider = NULL, include_rows = FALSE) {
  validate_workflow_spec(workflow)
  if (isTRUE(include_rows)) stop("v2.1 workflow drafting does not send raw rows", call. = FALSE)
  request <- workflow_draft_request(workflow)
  response <- if (is.null(provider)) {
    list(
      title = workflow$title,
      question = workflow$analysis$question %||% workflow$goal,
      prompts = stats::setNames(
        vapply(workflow$activities, `[[`, character(1), "prompt"),
        vapply(workflow$activities, `[[`, character(1), "id")
      ),
      model = "deterministic-template"
    )
  } else {
    if (!is.function(provider)) stop("provider must be NULL or a function", call. = FALSE)
    provider(request)
  }
  if (!is.list(response) || !all(c("title", "question", "prompts") %in% names(response))) {
    stop("workflow draft provider must return title, question, and prompts", call. = FALSE)
  }
  assert_scalar_text(as.character(response$title), "draft title")
  assert_scalar_text(as.character(response$question), "draft question")
  prompts <- unlist(response$prompts, use.names = TRUE)
  activity_ids <- vapply(workflow$activities, `[[`, character(1), "id")
  if (is.null(names(prompts)) || any(!names(prompts) %in% activity_ids) || any(!nzchar(prompts))) {
    stop("workflow draft prompts must be non-empty and keyed by activity id", call. = FALSE)
  }
  structure(
    list(
      schema_version = "rclaimlab-workflow-draft-1",
      workflow_id = workflow$id, title = as.character(response$title),
      question = as.character(response$question), prompts = prompts,
      provider = as.character(response$model %||% "provider-callback"),
      request_hash = evidence_hash(request), response_hash = evidence_hash(response),
      changes_method = FALSE, changes_evidence = FALSE, approved = FALSE
    ),
    class = c("rclaimlab_workflow_draft", "list")
  )
}

workflow_draft_request <- function(workflow) {
  dataset <- workflow$dataset
  columns <- if (is.null(dataset)) data.frame() else data.frame(
    name = names(dataset$data),
    type = vapply(dataset$data, learning_column_type, character(1)),
    missing_percent = vapply(dataset$data, function(x) round(100 * mean(is.na(x)), 1), numeric(1)),
    distinct = vapply(dataset$data, function(x) length(unique(x[!is.na(x)])), integer(1)),
    stringsAsFactors = FALSE
  )
  list(
    response_format = "rclaimlab-workflow-draft-1",
    workflow = list(id = workflow$id, role = workflow$role, goal = workflow$goal),
    columns = columns,
    analysis = list(
      method_locked = workflow$analysis$method %||% "lesson",
      outcome = workflow$analysis$outcome %||% NULL,
      predictors = workflow$analysis$predictors %||% character()
    ),
    allowed = c("title", "question", "activity prompts"),
    prohibited = c("raw rows", "method changes", "R code", "evidence changes", "automatic approval")
  )
}
