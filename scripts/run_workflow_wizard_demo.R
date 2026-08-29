args <- commandArgs(trailingOnly = TRUE)
port <- if (length(args)) as.integer(args[[1]]) else 8786L

full_args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", full_args[grepl("^--file=", full_args)])
script_path <- normalizePath(file_arg[[1]], winslash = "/", mustWork = TRUE)
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(root, quiet = TRUE)
} else {
  library(rclaimlab)
}

run_workflow_wizard(
  output_dir = file.path(root, "output", "workflow-wizard-smoke"),
  host = "127.0.0.1",
  port = port,
  launch.browser = FALSE,
  quiet = TRUE
)
