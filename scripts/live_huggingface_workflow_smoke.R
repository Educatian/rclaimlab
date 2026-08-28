if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("The live workflow smoke test requires the development dependency 'pkgload'.")
}
pkgload::load_all(".", quiet = TRUE)

source <- dataset_source(
  "huggingface", "scikit-learn/adult-census-income",
  revision = "fbeef6ec0e6fd88a5028b94683144000a6b380d5",
  split = "train", file = "adult.csv"
)
manifest <- inspect_dataset(source)
stopifnot(
  identical(manifest$revision, "fbeef6ec0e6fd88a5028b94683144000a6b380d5"),
  identical(manifest$license, "cc0-1.0"),
  isTRUE(manifest$publishable)
)
preview <- preview_dataset(source, rows = 5L)
stopifnot(nrow(preview) == 5L, all(c("age", "income") %in% names(preview)))

dataset <- import_dataset(source, max_rows = 1000L, seed = 2026L)
workflow <- workflow_from_dataset(
  dataset, "data_scientist", outcome = "income",
  predictors = c("age", "education.num", "hours.per.week"),
  slice_by = "sex", analysis = "glm", missing_values = c("?", " ?"),
  seed = 2026L, title = "Pinned Adult Census live smoke"
)
run <- run_workflow(approve_workflow(workflow, publication = TRUE))
stopifnot(
  identical(run$execution$mode, "glm"),
  "model-evidence" %in% run$bundle$registry$artifact_id,
  isTRUE(validate_evidence_bundle(run$bundle))
)
cat("Pinned Hugging Face inspect, preview, import, GLM, and lineage smoke passed.\n")
