root <- normalizePath(".", winslash = "/", mustWork = TRUE)
clean_lib <- file.path(tempdir(), "rlearnxr-persona-clean-library")
dir.create(clean_lib, recursive = TRUE, showWarnings = FALSE)

r_bin <- file.path(R.home("bin"), "R")
install_status <- system2(
  r_bin,
  c("CMD", "INSTALL", "--no-multiarch", "--library", shQuote(clean_lib), shQuote(root)),
  stdout = FALSE,
  stderr = FALSE
)
if (!identical(install_status, 0L)) {
  stop("Posit Cloud proxy could not install the package into its clean library.")
}
.libPaths(c(clean_lib, .libPaths()))
library(rlearnxr, lib.loc = clean_lib)

api_ok <- all(c("check_lesson", "render_scene", "scaffold_lesson") %in%
  getNamespaceExports("rlearnxr"))

lessons <- list.dirs(file.path(root, "examples"), full.names = TRUE, recursive = FALSE)
lesson_results <- vapply(lessons, function(path) {
  result <- rlearnxr::check_lesson(path, strict = TRUE, write_report = FALSE, write_json = FALSE)
  all(as.character(result$status) == "PASS")
}, logical(1))

quarto <- Sys.which("quarto")[[1]]
if (!nzchar(quarto)) {
  candidates <- file.path(root, ".tools", "quarto-1.10.18", "bin", c("quarto", "quarto.exe"))
  existing <- candidates[file.exists(candidates)]
  if (length(existing)) quarto <- normalizePath(existing[[1]], winslash = "/")
}
if (!nzchar(quarto)) stop("Posit Cloud proxy requires Quarto for render verification.")

render_results <- vapply(lessons, function(path) {
  status <- system2(quarto, c("render", path), stdout = FALSE, stderr = FALSE)
  identical(status, 0L)
}, logical(1))

report <- data.frame(
  persona = c("Posit Cloud clean-room proxy", rep("Reference lesson", length(lessons))),
  check = c("package install and exported API", basename(lessons)),
  status = c(if (api_ok && all(lesson_results) && all(render_results)) "PASS" else "FAIL", ifelse(lesson_results & render_results, "PASS", "FAIL")),
  stringsAsFactors = FALSE
)
print(report, row.names = FALSE)
write.csv(report, file.path(root, "output", "audit", "persona-validation", "posit-cloud-proxy.csv"), row.names = FALSE)
if (any(report$status == "FAIL")) quit(status = 1)
cat("Posit Cloud clean-room proxy passed: clean package install, strict lesson checks, and Quarto rendering.\n")
