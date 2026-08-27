root <- normalizePath(".", winslash = "/", mustWork = TRUE)
audit_dir <- tempfile("rclaimlab-source-tarball-")
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)
on.exit({
  setwd(root)
  unlink(audit_dir, recursive = TRUE, force = TRUE)
}, add = TRUE)
setwd(audit_dir)

r_command <- file.path(R.home("bin"), "R")
status <- system2(
  r_command,
  c("CMD", "build", shQuote(root), "--no-build-vignettes"),
  stdout = TRUE,
  stderr = TRUE
)
build_status <- attr(status, "status")
if (!is.null(build_status) && build_status != 0L) {
  stop("R CMD build failed:\n", paste(status, collapse = "\n"), call. = FALSE)
}

tarballs <- list.files(audit_dir, pattern = "^rclaimlab_.*[.]tar[.]gz$", full.names = TRUE)
if (length(tarballs) != 1L) {
  stop("Expected exactly one rclaimlab source tarball; found ", length(tarballs), call. = FALSE)
}

members <- utils::untar(tarballs[[1]], list = TRUE)
forbidden <- grepl(
  "/(?:tmp|output|[.]tools|[.]git|test-results|.*[.]Rcheck)(?:/|$)",
  members,
  perl = TRUE
)
if (any(forbidden)) {
  stop(
    "Source tarball contains excluded local workspace paths:\n",
    paste(members[forbidden], collapse = "\n"),
    call. = FALSE
  )
}

required <- c("DESCRIPTION", "NAMESPACE", "R/evidence_adapters.R", "inst/templates/scene.html")
missing <- required[!vapply(required, function(path) any(endsWith(members, paste0("/", path))), logical(1))]
if (length(missing)) {
  stop("Source tarball is missing required package files: ", paste(missing, collapse = ", "), call. = FALSE)
}

cat("Source tarball boundary passed:", length(members), "members and no local workspace artifacts.\n")
