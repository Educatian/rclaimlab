# Public demo and local R package: one source of truth

See the [September 3 release verification](parity-release-20260903.md) for the
deployed commit, completed tests and remaining external-validation boundaries.

The current reference experience starts with Guided Learning, Data Analyst,
Data Scientist, or Model Reviewer. Mode determines the activity path, evidence,
actions and deliverable; the common tool menu is not a learning sequence.

## Try the same example locally

1. Open https://rclaimlab-review.pages.dev/ and choose **Use my data**.
2. Copy its install command. It names a full Git commit, not a moving branch.
3. Run `rclaimlab::run_workflow_wizard()` in RStudio.
4. Choose a mode and **Open example**. Review the synthetic source preview.
5. Select **Import selected data locally**: all 300 rows are imported. Continue
   to the question screen; the example question, variables and method are filled.
6. Review the method, create the workflow and inspect its activity path.
7. Explicitly approve all four decisions, then build and open the workspace.

The hosted example skips local import and approval because its fixed synthetic
analysis has already been compiled. It uses exactly the same preset. It does
not upload your files or run an arbitrary R analysis on a server. Local Shiny
supports CSV/TSV/Parquet and the existing public Hugging Face / Kaggle adapters.
Parquet requires `arrow`; Kaggle uses the official CLI and local authentication.

## R export, step by step

Download `analysis/workflow.R` in any mode. In RStudio:

```r
source("workflow.R")                 # Defines a function; does not run analysis
result <- reproduce_workflow()        # Runs the bundled synthetic example locally
result$bundle$registry                # Lists evidence and artifact hashes
as.data.frame(result$bundle$artifacts[[1]])
```

For your own data, call `reproduce_workflow("path/to/original.csv")`. Supply the
original imported/downloaded file, not `evidence-table.csv`. The function checks
the file checksum before importing the recorded columns and deterministic sample.
It then restores the recorded activity DAG and analysis settings, approves that
fixed plan explicitly, and calls the local R engine. The engine performs the
train/test split, factor handling, model fit, probability prediction and evaluation.

Optionally pass `output_dir = "new-rerun-folder"` to compile a fresh portable
workspace. Existing output is not overwritten by default. Reproduction of a
handoff recomputes the analysis; it does not certify or recreate another person's
claims, review or approvals. A renamed source or a different R/package environment
can change provenance hashes even if numerical results agree.

No raw data, credentials or local absolute paths are included in the script.
Scripts and receipts are local files. A hosted example's **Change mode** link
returns to the public chooser; a local result offers a return to its live wizard
and a command fallback when opened outside that local session.

## Maintainer parity gate

- `test-workflow-parity.R`: four presets, Shiny plans, rerun evidence and hash
  equality, wrong-source rejection, shared launcher, immutable install reference.
- `test-workflow-wizard-server.R`: four roles, approval/reset gates and outputs.
- `deploy/cloudflare/build-modes.R`: fresh builds only, no old output dependency.
- `deploy/cloudflare/check.ps1`: public routes, source scripts and manifest hashes.
- `release-manifest.json`: package version, exact Git commit, R version, source
  fixture checksum and generated artifact checksums. It is an integrity inventory,
  not a cryptographic signature or proof of external human validation.

Real learner, independent R/Quarto and screen-reader reviews remain separate
release gates. Shared UI and automated parity checks do not replace those reviews.
