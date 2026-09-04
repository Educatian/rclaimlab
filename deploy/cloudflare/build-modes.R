# Clean-build every role from the installed package or current source.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || !grepl("^[a-f0-9]{40}$", args[[2]])) {
  stop("Usage: Rscript deploy/cloudflare/build-modes.R NEW_DIRECTORY FULL_COMMIT_SHA")
}
destination <- args[[1]]
release_ref <- args[[2]]
if (dir.exists(destination)) stop("Use a new destination; existing builds are preserved.")
library_path <- Sys.getenv("RCLAIMLAB_LIBRARY")
if (nzchar(library_path)) library(rclaimlab, lib.loc = library_path) else pkgload::load_all(".", quiet = TRUE)
dir.create(destination, recursive = TRUE)
roles <- c(guided = "guided_learning", analyst = "data_analyst",
           scientist = "data_scientist", reviewer = "model_reviewer")
runs <- list()
for (mode in names(roles)) {
  workflow <- rclaimlab:::workflow_demo(roles[[mode]])
  run <- run_workflow(approve_workflow(workflow))
  target <- file.path(destination, "modes", mode)
  build <- compile_workflow(run, target)
  write_workflow_receipt(run, target)
  primary <- rclaimlab:::workflow_primary_artifact(run$bundle)
  evidence <- run$bundle$artifacts[[primary]]
  contract <- rclaimlab:::workflow_browser_contract(run, primary, evidence,
    rclaimlab:::workflow_visual_sample(as.data.frame(evidence), 1000L, workflow$analysis$seed))
  writeLines(rclaimlab:::workflow_html(workflow$title, contract, "../../../index.html"),
    file.path(target, "app/index.html"), useBytes = TRUE)
  stopifnot(file.copy(rclaimlab:::workflow_demo_source()$id,
    file.path(target, "data/synthetic-workflow-data.csv")))
  check_workflow(target, strict = TRUE)
  runs[[mode]] <- list(mode = mode, role = workflow$role, workflow_id = workflow$id,
    activities = length(workflow$activities), bundle_hash = run$bundle$bundle_hash,
    url = paste0("modes/", mode, "/app/"))
}
# Preserve previously shared root reviewer artifact URLs from the NEW build.
reviewer <- file.path(destination, "modes/reviewer")
for (file in list.files(reviewer, recursive = TRUE, full.names = FALSE)) {
  target <- file.path(destination, file)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(reviewer, file), target))
}
html <- readLines(file.path(destination, "app/index.html"), warn = FALSE)
html <- sub('href="../../../index.html"', 'href="../index.html"', html, fixed = TRUE)
writeLines(html, file.path(destination, "app/index.html"), useBytes = TRUE)
writeLines(rclaimlab:::workflow_launcher_page(release_ref), file.path(destination, "index.html"), useBytes = TRUE)
stopifnot(file.copy("deploy/cloudflare/404.html", file.path(destination, "404.html")))
stopifnot(file.copy(rclaimlab:::workflow_template_path("icons/LICENSE.txt"), file.path(destination, "font-license.txt")))
stopifnot(file.copy(rclaimlab:::workflow_demo_source()$id, file.path(destination, "synthetic-workflow-data.csv")))
jsonlite::write_json(unname(runs), file.path(destination, "modes-manifest.json"), pretty = TRUE, auto_unbox = TRUE)
files <- list.files(destination, recursive = TRUE)
manifest <- list(schema_version = "rclaimlab-release-1", package = "rclaimlab",
  version = as.character(utils::packageVersion("rclaimlab")), git_commit = release_ref,
  r_version = as.character(getRversion()), environment = "precompiled-public-demo",
  runtime = list(remote_r = FALSE, uploads = FALSE, telemetry = FALSE),
  preset = list(id = "synthetic-workforce-300", rows = 300L,
    md5 = unname(tools::md5sum(rclaimlab:::workflow_demo_source()$id))),
  files = stats::setNames(as.list(unname(tools::md5sum(file.path(destination, files)))), files))
jsonlite::write_json(manifest, file.path(destination, "release-manifest.json"), pretty = TRUE, auto_unbox = TRUE)
check_workflow(destination, strict = TRUE)
cat("Built all four modes and legacy reviewer from one package:", release_ref, "\n")
