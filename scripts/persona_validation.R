root <- normalizePath(".", winslash = "/", mustWork = TRUE)
clean_lib <- file.path(tempdir(), "rclaimlab-persona-clean-library")
dir.create(clean_lib, recursive = TRUE, showWarnings = FALSE)

install.packages(root, repos = NULL, type = "source", lib = clean_lib, quiet = TRUE)
if (!dir.exists(file.path(clean_lib, "rclaimlab"))) {
  stop("Posit Cloud proxy installation did not create the package in the clean library.")
}
.libPaths(c(clean_lib, .libPaths()))
library(rclaimlab, lib.loc = clean_lib)

api_ok <- all(c("check_lesson", "render_scene", "scaffold_lesson") %in%
  getNamespaceExports("rclaimlab"))

lessons <- list.dirs(file.path(root, "examples"), full.names = TRUE, recursive = FALSE)
lesson_results <- vapply(lessons, function(path) {
  result <- rclaimlab::check_lesson(path, strict = TRUE, write_report = FALSE, write_json = FALSE)
  all(as.character(result$status) == "PASS")
}, logical(1))

resolve_quarto <- function(value = Sys.getenv("QUARTO_PATH", unset = "")) {
  if (nzchar(value) && dir.exists(value)) {
    candidates <- file.path(value, c("quarto", "quarto.exe"))
    existing <- candidates[file.exists(candidates)]
    if (length(existing)) value <- existing[[1]]
  }
  if (nzchar(value) && file.exists(value)) {
    return(normalizePath(value, winslash = "/"))
  }
  unname(Sys.which("quarto")[[1]])
}

quarto <- resolve_quarto()
if (!nzchar(quarto)) {
  candidates <- file.path(root, ".tools", "quarto-1.10.18", "bin", c("quarto", "quarto.exe"))
  existing <- candidates[file.exists(candidates)]
  if (length(existing)) quarto <- normalizePath(existing[[1]], winslash = "/")
}
if (!nzchar(quarto)) stop("Posit Cloud proxy requires Quarto for render verification.")

render_results <- vapply(lessons, function(path) {
  status <- system2(quarto, c("render", shQuote(path)), stdout = FALSE, stderr = FALSE)
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
