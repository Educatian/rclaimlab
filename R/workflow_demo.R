# One reference dataset and plan for local authoring, tests, and the public demo.
workflow_demo_source <- function() {
  path <- system.file("extdata", "synthetic-workflow-data.csv", package = "rclaimlab")
  if (!nzchar(path)) stop("The installed package is missing its synthetic fixture", call. = FALSE)
  dataset_source("local", path)
}

workflow_demo <- function(role = "guided_learning") {
  dataset <- import_dataset(workflow_demo_source(), seed = 2026L)
  model <- role %in% c("data_scientist", "model_reviewer")
  workflow_from_dataset(dataset, role = role,
    analysis = if (model) "glm" else "describe",
    outcome = if (model) "outcome" else NULL,
    predictors = if (model) c("age", "hours", "education") else c("age", "hours"),
    slice_by = if (role == "guided_learning") character() else "group",
    seed = 2026L, id = paste0("synthetic-workforce-", gsub("_", "-", role)),
    title = paste("Synthetic workforce:", workflow_role_label(role)),
    question = if (model) "How well does the approved GLM classify held-out synthetic records?" else
      "What can age and hours tell us, and what do these synthetic records not establish?")
}
