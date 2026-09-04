# Export a complete, explicit local rerun recipe without rows, tokens, or paths.
workflow_reproduction_source <- function(workflow, dataset) {
  literal <- function(x) paste(deparse(x, width.cutoff = 100L), collapse = "\n")
  spec <- workflow_public_spec(workflow)
  spec$approvals <- NULL
  spec$upstream <- NULL
  spec$handoff_from <- NULL
  spec$dataset <- NULL
  spec$legacy <- NULL
  spec_text <- paste(utils::capture.output(dput(spec)), collapse = "\n")
  synthetic <- identical(dataset$import$content_md5,
    unname(tools::md5sum(workflow_demo_source()$id)))
  default <- if (synthetic) 'system.file("extdata", "synthetic-workflow-data.csv", package = "rclaimlab")' else 'Sys.getenv("RCLAIMLAB_SOURCE_FILE", unset = "")'
  c(
    "# R-ClaimLab: complete local reproduction recipe (no network or uploads).",
    "# RStudio: source('workflow.R'); result <- reproduce_workflow()",
    "# Own data: result <- reproduce_workflow('path/to/original.csv')",
    "# Supply the original downloaded file, not the derived evidence-table.csv.",
    "# Sourcing defines a function only. Calling it approves this recorded plan.",
    "# A handoff rerun recomputes analysis; it does not recreate human review decisions.",
    paste0("# Created with rclaimlab ", as.character(utils::packageVersion("rclaimlab")), "; R ", getRversion()),
    paste0("reproduce_workflow <- function(source_file = ", default, ", output_dir = NULL) {"),
    "  if (!requireNamespace('rclaimlab', quietly = TRUE)) stop('Install rclaimlab first.')",
    "  if (!nzchar(source_file) || !file.exists(source_file)) stop('Supply the original source file; nothing was downloaded.')",
    paste0("  expected_md5 <- ", literal(dataset$import$content_md5)),
    "  if (!identical(unname(tools::md5sum(source_file)), expected_md5)) stop('Source content differs from the approved file.')",
    "  # 1. Import the exact columns with the recorded sampling settings.",
    paste0("  dataset <- rclaimlab::import_dataset(rclaimlab::dataset_source('local', source_file), columns = ", literal(dataset$import$columns), ","),
    paste0("    max_rows = ", dataset$import$max_rows, "L, sample = ", literal(dataset$import$sample), ", seed = ", dataset$import$seed, "L)"),
    "  # 2. Restore the reviewed activity DAG and analysis settings, not raw rows.",
    paste0("  specification <- ", spec_text),
    "  specification$dataset <- dataset",
    "  # The public specification is an S3 workflow contract.",
    "  class(specification) <- c('rclaimlab_workflow', 'list')",
    "  # 3. Explicitly approve and execute locally. R performs splitting and fitting.",
    "  result <- rclaimlab::run_workflow(rclaimlab::approve_workflow(specification))",
    "  print(result)",
    "  # 4. Inspect evidence in R; optionally compile to a NEW destination.",
    "  if (!is.null(output_dir)) rclaimlab::compile_workflow(result, output_dir)",
    "  invisible(result)",
    "}"
  )
}
