RLEARNXR_SOURCE_ROOT <- local({
  source_file <- tryCatch(sys.frame(1)$ofile, error = function(error) NULL)
  if (is.null(source_file) || !nzchar(source_file)) return("")
  dirname(dirname(normalizePath(source_file, winslash = "/", mustWork = FALSE)))
})

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

scene_template_path <- function() {
  working_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  search_roots <- unique(c(
    RLEARNXR_SOURCE_ROOT,
    working_root,
    dirname(working_root),
    dirname(dirname(working_root)),
    dirname(dirname(dirname(working_root)))
  ))
  source_candidates <- c(
    file.path(search_roots, "inst", "templates", "scene.html")
  )
  source_path <- source_candidates[file.exists(source_candidates)][1]
  if (length(source_path) && !is.na(source_path)) return(source_path)

  installed <- system.file("templates", "scene.html", package = "rlearnxr")
  if (nzchar(installed) && file.exists(installed)) return(installed)

  stop("R-LearnXR scene template was not found", call. = FALSE)
}

scene_html <- function(title, points_json, learning_contract = NULL) {
  template <- paste(
    readLines(scene_template_path(), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  template <- sub("{{TITLE}}", html_escape(title), template, fixed = TRUE)
  template <- sub("{{POINTS_JSON}}", points_json, template, fixed = TRUE)
  if (is.null(learning_contract)) learning_contract <- default_scene_contract(title)
  contract_json <- jsonlite::toJSON(
    learning_contract, auto_unbox = TRUE, null = "null", na = "null", digits = NA
  )
  contract_json <- gsub("<", "\\u003c", contract_json, fixed = TRUE)
  sub("{{LESSON_JSON}}", contract_json, template, fixed = TRUE)
}
