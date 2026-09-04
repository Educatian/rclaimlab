# Shared display metadata. Statistical contracts and activity IDs stay in R.
workflow_presentation_registry <- function() {
  jsonlite::fromJSON(workflow_template_path("workflow-presentation.json"),
                     simplifyVector = FALSE)
}

workflow_role_presentation <- function(role) {
  workflow_presentation_registry()$profiles[[role %||% "data_scientist"]]
}

workflow_activity_presentation <- function(role, type) {
  registry <- workflow_presentation_registry()
  value <- registry$overrides[[role]][[type]] %||% registry$common[[type]]
  if (is.null(value)) value <- list(gsub("_", " ", type), "Activities",
                                   "Record a task note", "note", "Task note")
  stats::setNames(value, c("label", "phase", "action", "target", "note"))
}
