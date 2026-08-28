root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Building the role workflow demo requires the development dependency 'pkgload'.")
}
pkgload::load_all(root, quiet = TRUE)

demo_root <- file.path(root, "examples", "role-workflows")
dir.create(demo_root, recursive = TRUE, showWarnings = FALSE)
fixture_path <- file.path(demo_root, "synthetic-workflow-data.csv")

set.seed(2026)
rows <- 300L
age <- sample(18:70, rows, replace = TRUE)
hours <- round(pmax(8, stats::rnorm(rows, 39, 8)), 1)
education <- factor(sample(c("secondary", "college", "graduate"), rows, replace = TRUE,
                           prob = c(.42, .38, .20)))
group <- factor(rep(c("A", "B", "C"), length.out = rows))
linear_predictor <- -4.1 + .035 * age + .045 * hours +
  ifelse(education == "graduate", .9, ifelse(education == "college", .35, 0))
outcome <- factor(ifelse(stats::runif(rows) < stats::plogis(linear_predictor), "event", "reference"),
                  levels = c("reference", "event"))
fixture <- data.frame(age, hours, education, group, outcome, stringsAsFactors = FALSE)
utils::write.csv(fixture, fixture_path, row.names = FALSE, na = "")

dataset <- import_dataset(dataset_source("local", fixture_path), max_rows = rows, seed = 2026L)

analyst <- workflow_from_dataset(
  dataset, role = "data_analyst", goal = "describe",
  predictors = c("age", "hours"),
  question = "What descriptive patterns should be carried into modeling?",
  seed = 2026L, title = "Synthetic workforce evidence: analyst"
)
analyst_run <- run_workflow(approve_workflow(analyst))

scientist <- continue_workflow(
  analyst_run, role = "data_scientist", outcome = "outcome",
  predictors = c("age", "hours", "education"), slice_by = "group",
  analysis = "glm",
  question = "How well does the approved GLM classify held-out synthetic records?",
  seed = 2026L, title = "Synthetic workforce evidence: data scientist"
)
scientist_run <- run_workflow(approve_workflow(scientist))

reviewer <- continue_workflow(
  scientist_run, role = "model_reviewer",
  title = "Synthetic workforce evidence: model reviewer"
)
reviewer_run <- run_workflow(approve_workflow(reviewer))

runs <- list(analyst = analyst_run, scientist = scientist_run, reviewer = reviewer_run)
for (name in names(runs)) {
  destination <- file.path(demo_root, name)
  build <- compile_workflow(runs[[name]], destination, overwrite = TRUE)
  write_workflow_receipt(
    runs[[name]], destination,
    claims = list(status = "Demo claim pending human review."),
    limitations = "Synthetic records demonstrate workflow behavior, not a population claim.",
    handoff = list(next_role = if (name == "analyst") "data_scientist" else if (name == "scientist") "model_reviewer" else "complete"),
    approval = if (name == "reviewer") "revision_requested" else "handoff_ready"
  )
  check_workflow(destination, strict = TRUE)
}

cat("Built analyst, scientist, and reviewer workflow demos under examples/role-workflows.\n")
