# External data and role-adaptive workflows

This guide turns a public tabular dataset into traceable Data Analyst, Data
Scientist, and Model Reviewer work. The original Guided Learning route remains
available for structured instruction. All analysis and caching happen in the
local R process. No telemetry, raw-row upload, or credential storage is added.

For the progressive authoring interface, run `run_workflow_wizard()`. It reveals
one decision at a time across Data, Question, Workflow, and Evidence phases,
then opens the same portable artifacts produced by the scriptable API below.
The compiled workspace starts in Focus mode; provenance, claim revision, and
handoff are separate modes so that the full workflow never becomes one crowded
dashboard.

## What the learner or practitioner does

1. Declare a local, Hugging Face, or Kaggle source.
2. inspect its files, revision, license, citation, and bounded preview.
3. Import at most 10,000 rows with a deterministic seed.
4. Approve the question, outcome, predictors, missing tokens, method, and review
   slices.
5. Run a role-specific workflow in R.
6. Inspect linked evidence in a table, 2D view, or optional 3D view.
7. Write a claim, limitation, and handoff decision.
8. Download a browser-local receipt and reproduce the R analysis.

The same `source_record_id` links an imported row to model evidence, the role
activity that used it, and the receipt. Different analyses have different
artifact and evidence IDs. Their lineage is connected through the source record
instead of pretending that distinct results are identical.

## RStudio rehearsal with Hugging Face

Open the `rclaimlab.Rproj` file. Run each block in the Console and inspect the
returned object before moving to the next block.

```r
library(rclaimlab)

source <- dataset_source(
  provider = "huggingface",
  id = "scikit-learn/adult-census-income",
  revision = "fbeef6ec0e6fd88a5028b94683144000a6b380d5",
  split = "train",
  file = "adult.csv"
)
```

`source` is a declaration only. It contains no data or token. The revision is a
real immutable repository commit verified on August 27, 2026. A previously
proposed `77dbee...` value returns 404 and must not be used.

```r
manifest <- inspect_dataset(source)
manifest
preview <- preview_dataset(source, rows = 10)
View(preview)
```

Check that the license is `cc0-1.0`, the resolved revision matches the requested
commit, `adult.csv` is present, and `publishable` is `TRUE`. For a pinned source,
the preview is read from the selected file at that commit. It is not silently
taken from a newer Dataset Viewer conversion.

```r
dataset <- import_dataset(
  source,
  max_rows = 10000,
  sample = "deterministic",
  seed = 2026,
  cache = TRUE,
  max_download_mb = 250
)
profile <- profile_dataset(dataset, outcome = "income", intent = "classify")
summary(dataset)
profile$columns
```

The full file is downloaded to the R user cache. At most 10,000 sampled rows
enter analysis, and at most 1,000 evidence rows enter the browser view. The full
compiled evidence table remains paginated and downloadable. Values such as
`" ?"` are not changed automatically.

```r
scientist <- workflow_from_dataset(
  dataset,
  role = "data_scientist",
  goal = "predict",
  outcome = "income",
  predictors = c("age", "education.num", "hours.per.week"),
  slice_by = "sex",
  analysis = "glm",
  question = paste(
    "How well does a transparent educational GLM classify held-out records,",
    "and where should a reviewer challenge its use?"
  ),
  missing_values = c("?", " ?"),
  seed = 2026
)
scientist
```

At this point no model has run. Review `summary(scientist)` and
`as.data.frame(scientist)`. Confirm that the prediction unit is one historical
record and that this educational case is not an individual decision system.

```r
scientist <- approve_workflow(
  scientist,
  question = TRUE,
  variable_roles = TRUE,
  method = TRUE,
  missing_values = TRUE,
  publication = TRUE
)
scientist_run <- run_workflow(scientist)
summary(scientist_run)
```

The GLM uses a seed-recorded stratified 80/20 split. The evidence stores holdout
accuracy, sensitivity, specificity, and Brier score, together with baseline,
factor levels, omitted rows, and review slices. A slice with fewer than 20
records is suppressed. A displayed slice is a review signal, not a fairness
certification.

```r
build <- compile_workflow(
  scientist_run,
  "adult-income-scientist",
  publish = TRUE
)
check_workflow(build$output_dir, strict = TRUE, publish = TRUE)
browseURL(file.path(build$output_dir, "app", "index.html"))
```

The output includes:

```text
source-manifest.json
dataset-profile.json
workflow-spec.json
evidence/index.json
evidence/artifacts/*.json
data/evidence-table.csv
analysis/workflow.R
report/index.qmd
app/index.html
checks/workflow-report.json
```

The browser workspace works from `file://`. Select an activity, switch among
table, 2D, and 3D evidence views, select an observation, write a bounded claim,
inspect deliverables, and download the local receipt.

## Cross-role handoff

```r
reviewer <- continue_workflow(scientist_run, role = "model_reviewer")
reviewer <- approve_workflow(reviewer, publication = TRUE)
reviewer_run <- run_workflow(reviewer)

review_build <- compile_workflow(
  reviewer_run,
  "adult-income-review",
  publish = TRUE
)

write_workflow_receipt(
  reviewer_run,
  review_build$output_dir,
  claims = list(
    main = "The holdout evidence supports only a bounded educational comparison."
  ),
  limitations = c(
    "Historical census labels and group differences do not establish causality.",
    "The selected GLM is not authorized for individual decisions."
  ),
  unresolved_issues = "External validity and threshold consequences require review.",
  approval = "revision_requested"
)
```

`continue_workflow()` references the upstream bundle hash and adds only new
artifacts. It does not copy or silently mutate the scientist evidence.

## Kaggle path

Install and authenticate the official Kaggle command-line client outside R:

```powershell
pip install kaggle
kaggle auth login
```

Then declare and inspect a public tabular dataset:

```r
source <- dataset_source(
  "kaggle",
  "owner/dataset",
  revision = "3",
  file = "selected.csv"
)
manifest <- inspect_dataset(source)
dataset <- import_dataset(source)
```

R-ClaimLab invokes only the official client. It does not accept a Kaggle token
argument. Downloads are unpacked in a bounded cache after checks for path
traversal, absolute paths, nested archives, and excessive unpacked size.

## Error recovery and boundaries

- A Hugging Face 404 usually means the dataset ID, revision, split, or file is
  wrong. Do not replace the revision with `main` for a published artifact.
- A 429 or timeout is a service condition. Retry after connectivity returns; a
  cached pinned file remains usable.
- Parquet requires the optional `arrow` package. Select CSV when `arrow` is not
  available.
- Nested/list columns, duplicate column names, files over 250 MB, and imports
  that exceed the approved limits stop with an error.
- Gated, private, image, audio, and free-form natural-language datasets are
  outside v2.1.
- Optional AI drafting receives column names, types, missingness, aggregates,
  role, and goal only. It cannot choose a method, change evidence, or approve a
  workflow.

Run `run_workflow_wizard()` for the same sequence in the optional Shiny authoring
surface. The wizard still requires all four analytical approvals before R
execution.
