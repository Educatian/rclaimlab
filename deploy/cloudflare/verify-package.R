# Run in a fresh Rscript process, not a pkgload development session.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
library(rclaimlab)
root <- args[[2]]
manifest <- jsonlite::fromJSON(file.path(root, "release-manifest.json"))
installed_ref <- utils::packageDescription("rclaimlab")$RemoteSha
stopifnot(identical(installed_ref, manifest$git_commit))
for (mode in c("guided", "analyst", "scientist", "reviewer")) {
  folder <- file.path(root, "modes", mode)
  environment <- new.env(parent = globalenv())
  source(file.path(folder, "analysis/workflow.R"), local = environment)
  result <- environment$reproduce_workflow()
  index <- jsonlite::fromJSON(file.path(folder, "evidence/index.json"))
  stopifnot(identical(result$bundle$bundle_hash, index$bundle_hash))
  for (id in names(result$bundle$artifacts)) {
    expected <- read_rclaimlab_evidence(file.path(folder, "evidence/artifacts", paste0(id, ".json")))
    stopifnot(isTRUE(all.equal(as.data.frame(result$bundle$artifacts[[id]]), as.data.frame(expected))))
  }
  check_workflow(folder, strict = TRUE, write_report = FALSE)
  cat("PASS clean installed-package replay:", mode, "\n")
}
for (file in names(manifest$files)) {
  stopifnot(identical(unname(tools::md5sum(file.path(root, file))), manifest$files[[file]]))
}
cat("PASS exact install ref and complete release checksum inventory:", installed_ref, "\n")
