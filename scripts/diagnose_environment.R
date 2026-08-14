args <- commandArgs(trailingOnly = TRUE)
strict <- "--strict" %in% args

report <- data.frame(
  check = character(),
  status = character(),
  value = character(),
  action = character(),
  stringsAsFactors = FALSE
)

add_check <- function(check, status, value, action = "") {
  report <<- rbind(report, data.frame(
    check = check,
    status = status,
    value = value,
    action = action,
    stringsAsFactors = FALSE
  ))
}

r_version <- paste(R.version$major, R.version$minor, sep = ".")
r_ok <- getRversion() >= "4.1.0"
add_check(
  "R",
  if (r_ok) "PASS" else "FAIL",
  R.version.string,
  if (r_ok) "" else "Install R 4.1 or newer."
)

check_command <- function(name, label, required = FALSE, action = "", fallback = character()) {
  value <- Sys.which(name)[[1]]
  if (!nzchar(value) && length(fallback)) {
    existing <- fallback[file.exists(fallback)]
    if (length(existing)) value <- normalizePath(existing[[1]], winslash = "/")
  }
  present <- nzchar(value)
  status <- if (present) "PASS" else if (required || strict) "FAIL" else "WARN"
  add_check(label, status, if (present) value else "not found", if (present) "" else action)
}

check_command("git", "Git", required = FALSE, action = "Install Git before cloning from GitHub.")
quarto_candidates <- file.path(
  getwd(), ".tools", "quarto-1.10.18", "bin", c("quarto", "quarto.exe")
)
check_command(
  "quarto",
  "Quarto CLI",
  required = FALSE,
  action = "Install Quarto before rendering lessons.",
  fallback = quarto_candidates
)

for (pkg in c("remotes", "renv")) {
  present <- requireNamespace(pkg, quietly = TRUE)
  add_check(
    pkg,
    if (present) "PASS" else if (strict) "FAIL" else "WARN",
    if (present) as.character(packageVersion(pkg)) else "not installed",
    if (present) "" else paste0("Run install.packages(\"", pkg, "\").")
  )
}

penguins_present <- requireNamespace("palmerpenguins", quietly = TRUE)
add_check(
  "palmerpenguins",
  if (penguins_present) "PASS" else "WARN",
  if (penguins_present) as.character(packageVersion("palmerpenguins")) else "not installed",
  if (penguins_present) "" else "Install palmerpenguins to render the PCA reference lesson."
)

web_url <- "https://webr.r-wasm.org/v0.6.0/webr.mjs"
add_check("WebR runtime", "INFO", web_url, "The browser needs network access on first Run R.")

print(report, row.names = FALSE)
failures <- report$status == "FAIL"
if (any(failures)) {
  cat("\nEnvironment diagnosis found required setup failures.\n")
  quit(status = 1)
}
cat("\nEnvironment diagnosis completed. WARN means an optional or authoring dependency is not installed.\n")
