#' Write a local role-adaptive workflow receipt
#'
#' @param run Completed workflow run.
#' @param path Output directory or JSON path.
#' @param attempt_number Attempt number.
#' @param activity_state,evidence_selections,claims,decisions User-controlled evidence.
#' @param limitations,unresolved_issues Review notes.
#' @param handoff Handoff metadata for the next role.
#' @param approval Human approval state.
#' @param overwrite Whether an existing file may be replaced.
#' @return A `rclaimlab_workflow_receipt`.
#' @export
write_workflow_receipt <- function(run, path = ".", attempt_number = 1L,
                                   activity_state = list(), evidence_selections = list(),
                                   claims = list(), decisions = list(),
                                   limitations = character(), unresolved_issues = character(),
                                   handoff = list(), approval = "pending",
                                   overwrite = TRUE) {
  if (!inherits(run, "rclaimlab_workflow_run")) stop("run must be an rclaimlab_workflow_run", call. = FALSE)
  validate_evidence_bundle(run$bundle)
  attempt_number <- as.integer(attempt_number)
  if (length(attempt_number) != 1L || is.na(attempt_number) || attempt_number < 1L) {
    stop("attempt_number must be one positive integer", call. = FALSE)
  }
  output <- if (grepl("\\.json$", path, ignore.case = TRUE)) path else file.path(path, "checks", "workflow-receipt.json")
  ensure_dir(dirname(output))
  if (file.exists(output) && !isTRUE(overwrite)) stop("workflow receipt already exists; use overwrite = TRUE", call. = FALSE)
  source <- run$bundle$source %||% list(provider = "legacy", id = run$workflow$id, revision = NA_character_, fingerprint = NA_character_)
  source_code <- paste(run$execution$source_code %||% character(), collapse = "\n")
  receipt <- structure(
    list(
      receipt_version = "1.0", schema_version = "rclaimlab-workflow-receipt-1",
      generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      workflow_id = run$workflow$id, role = run$workflow$role,
      attempt_number = attempt_number, activity_state = activity_state,
      approvals = run$workflow$approvals,
      analysis = list(
        question = run$workflow$analysis$question %||% run$workflow$goal,
        method = run$workflow$analysis$method %||% "lesson",
        outcome = run$workflow$analysis$outcome %||% NULL,
        predictors = run$workflow$analysis$predictors %||% character(),
        missing_values = run$workflow$analysis$missing_values %||% character()
      ),
      evidence_selections = evidence_selections, claims = claims,
      decisions = decisions, limitations = as.character(limitations),
      unresolved_issues = as.character(unresolved_issues),
      source = source,
      evidence = list(bundle_hash = run$bundle$bundle_hash, artifacts = run$bundle$registry),
      handoff = handoff, approval = as.character(approval),
      reproducibility = list(
        seed = run$workflow$analysis$seed %||% 2026L,
        r_version = paste(R.version$major, R.version$minor, sep = "."),
        packages = list(rclaimlab = current_rclaimlab_version()),
        source_code_hash = evidence_hash(source_code)
      ),
      privacy = list(storage = "local", telemetry = FALSE, raw_data_embedded = FALSE)
    ),
    class = c("rclaimlab_workflow_receipt", "list")
  )
  validate_workflow_receipt(receipt)
  write_json_object(unclass(receipt), output)
  attr(receipt, "path") <- normalizePath(output, winslash = "/", mustWork = FALSE)
  receipt
}

#' Read a workflow receipt
#'
#' @param path Receipt JSON path or compiled workflow directory.
#' @export
read_workflow_receipt <- function(path = ".") {
  receipt_path <- if (dir.exists(path)) file.path(path, "checks", "workflow-receipt.json") else path
  if (!file.exists(receipt_path)) stop("workflow receipt was not found", call. = FALSE)
  value <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
  value <- structure(value, class = c("rclaimlab_workflow_receipt", "list"))
  validate_workflow_receipt(value)
  attr(value, "path") <- normalizePath(receipt_path, winslash = "/")
  value
}

#' Validate a workflow receipt
#'
#' @param receipt Receipt object or JSON path.
#' @export
validate_workflow_receipt <- function(receipt) {
  value <- if (is.character(receipt)) read_workflow_receipt(receipt) else receipt
  required <- c(
    "receipt_version", "schema_version", "workflow_id", "role", "attempt_number",
    "activity_state", "approvals", "analysis", "evidence_selections", "claims",
    "decisions", "limitations", "unresolved_issues", "source", "evidence",
    "handoff", "approval", "reproducibility", "privacy"
  )
  if (!inherits(value, "rclaimlab_workflow_receipt") ||
      !identical(as.character(value$schema_version), "rclaimlab-workflow-receipt-1") ||
      length(setdiff(required, names(value)))) {
    stop("receipt must satisfy rclaimlab-workflow-receipt-1", call. = FALSE)
  }
  if (!(value$role %in% workflow_roles())) stop("workflow receipt contains an unsupported role", call. = FALSE)
  if (is.null(value$evidence$bundle_hash) || !nzchar(as.character(value$evidence$bundle_hash))) {
    stop("workflow receipt must reference an evidence bundle hash", call. = FALSE)
  }
  if (!identical(value$privacy$telemetry, FALSE) || !identical(value$privacy$raw_data_embedded, FALSE)) {
    stop("workflow receipt privacy must disable telemetry and raw-data embedding", call. = FALSE)
  }
  serialized <- jsonlite::toJSON(unclass(value), auto_unbox = TRUE, null = "null")
  if (grepl("(KAGGLE_API_TOKEN|HF_TOKEN|OPENAI_API_KEY|Bearer[[:space:]])", serialized, ignore.case = TRUE)) {
    stop("workflow receipt appears to contain a credential", call. = FALSE)
  }
  invisible(TRUE)
}

#' Convert a legacy learning receipt to a guided-learning workflow receipt
#'
#' @param x Existing `rclaimlab_receipt`.
#' @return A workflow receipt object.
#' @export
as_workflow_receipt <- function(x) {
  validate_learning_receipt(x)
  structure(
    list(
      receipt_version = "1.0", schema_version = "rclaimlab-workflow-receipt-1",
      generated_at = x$generated_at %||% format(Sys.time(), tz = "UTC", usetz = TRUE),
      workflow_id = x$activity_id %||% x$course_id %||% "guided-learning",
      role = "guided_learning", attempt_number = x$attempt_number,
      activity_state = list(outcome = x$outcome),
      approvals = list(question = TRUE, variable_roles = TRUE, method = TRUE, missing_values = TRUE, publication = FALSE),
      analysis = list(question = "guided learning", method = "lesson", outcome = NULL, predictors = character(), missing_values = character()),
      evidence_selections = list(evidence_point = x$evidence_point, transfer_point = x$transfer_point),
      claims = list(prediction = x$prediction, explanation = x$explanation, transfer = x$transfer_response),
      decisions = list(), limitations = character(), unresolved_issues = character(),
      source = list(provider = "rclaimlab", id = x$course_id %||% "guided-learning", revision = NA_character_, fingerprint = NA_character_),
      evidence = list(bundle_hash = x$evidence$artifact_hash %||% "legacy-unlinked", artifacts = list()),
      handoff = list(), approval = "learning-complete",
      reproducibility = x$reproducibility,
      privacy = list(storage = "local", telemetry = FALSE, raw_data_embedded = FALSE)
    ),
    class = c("rclaimlab_workflow_receipt", "list")
  )
}

#' @export
print.rclaimlab_workflow_receipt <- function(x, ...) {
  cat("<rclaimlab_workflow_receipt>", x$workflow_id, "\n")
  cat("Role:", x$role, " Approval:", x$approval, " Bundle:", x$evidence$bundle_hash, "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_workflow_receipt <- function(object, ...) {
  list(workflow_id = object$workflow_id, role = object$role,
       attempt_number = object$attempt_number, approval = object$approval,
       bundle_hash = object$evidence$bundle_hash,
       unresolved_issues = object$unresolved_issues)
}

#' @export
as.data.frame.rclaimlab_workflow_receipt <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    workflow_id = x$workflow_id, role = x$role, attempt_number = x$attempt_number,
    approval = x$approval, bundle_hash = x$evidence$bundle_hash,
    stringsAsFactors = FALSE
  )
}
