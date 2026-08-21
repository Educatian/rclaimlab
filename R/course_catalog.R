default_course_catalog <- function() {
  list(
    schema_version = "rlearnxr-course-1",
    course_id = "rlearnxr-foundations",
    title = "From R code to evidence",
    subtitle = "A reproducible pathway through statistics, learning analytics, and educational data mining.",
    outcomes = c(
      "Frame a data question and identify an evidence boundary.",
      "Run and explain a reproducible R transformation.",
      "Use a visual or tabular representation to support a claim.",
      "Transfer the reasoning to a new observation and document the result."
    ),
    modules = list(
      list(id = "r-foundations", track = "R foundations", level = "Beginner", title = "Make a data claim", minutes = 10L,
           description = "Learn the R-LearnXR loop: predict, run a real R transformation, select evidence, and explain a limitation.",
           concepts = c("data frames", "filtering", "evidence sentences"), lesson_path = "lesson/scene/index.html", status = "ready"),
      list(id = "statistics-distribution", track = "Statistics", level = "Beginner", title = "Describe a distribution", minutes = 15L,
           description = "Connect center, spread, distribution shape, and individual observations without overstating the sample.",
           concepts = c("center", "spread", "distribution", "outliers"), lesson_path = "statistics-distribution/scene/index.html", status = "ready"),
      list(id = "statistics-association", track = "Statistics", level = "Beginner", title = "Reason about correlation", minutes = 20L,
           description = "Use paired evidence to interpret direction, strength, form, and limits of an association.",
           concepts = c("scatterplot", "correlation", "form", "outliers"), lesson_path = "statistics-association/scene/index.html", status = "ready"),
      list(id = "statistics-bootstrap", track = "Statistics", level = "Intermediate", title = "See sampling variability", minutes = 20L,
           description = "Inspect a bootstrap distribution and explain what its interval can and cannot establish.",
           concepts = c("resampling", "sampling variability", "confidence interval"), lesson_path = "statistics-bootstrap/scene/index.html", status = "ready"),
      list(id = "statistics-groups", track = "Statistics", level = "Intermediate", title = "Compare group variation", minutes = 25L,
           description = "Relate individual outcomes, group means, residuals, and the omnibus analysis-of-variance result.",
           concepts = c("group means", "within-group variation", "ANOVA"), lesson_path = "statistics-groups/scene/index.html", status = "ready"),
      list(id = "statistics-categories", track = "Statistics", level = "Intermediate", title = "Inspect categorical association", minutes = 25L,
           description = "Compare observed and expected counts and identify cells that drive a chi-square association.",
           concepts = c("contingency table", "expected counts", "standardized residuals"), lesson_path = "statistics-categories/scene/index.html", status = "ready"),
      list(id = "statistics-pca", track = "Statistics", level = "Intermediate", title = "Find structure with PCA", minutes = 20L,
           description = "Standardize penguin measurements, inspect principal components, and defend what a multivariate coordinate does and does not mean.",
           concepts = c("standardization", "PCA", "variation"), lesson_path = "penguin-pca/scene/index.html", status = "ready"),
      list(id = "statistics-efficiency", track = "Statistics", level = "Intermediate", title = "Explain efficiency patterns", minutes = 15L,
           description = "Compare vehicle observations across weight, power, and efficiency while separating association from a causal claim.",
           concepts = c("association", "comparison", "limitations"), lesson_path = "mtcars-efficiency/scene/index.html", status = "ready"),
      list(id = "learning-analytics", track = "Learning analytics", level = "Intermediate", title = "From event to learning construct", minutes = 25L,
           description = "Translate an event log into a transparent construct, audit missingness, and choose a learner-safe descriptive summary.",
           concepts = c("event logs", "construct validity", "privacy"), lesson_path = "learning-analytics/scene/index.html", status = "ready"),
      list(id = "edm-patterns", track = "Educational data mining", level = "Intermediate", title = "Discover patterns responsibly", minutes = 25L,
           description = "Compare clustering and prediction as discovery tools, then document uncertainty, fairness, and intervention limits.",
           concepts = c("clustering", "prediction", "ethics"), lesson_path = "edm-patterns/scene/index.html", status = "ready")
    )
  )
}

validate_course_catalog <- function(catalog) {
  if (!is.list(catalog)) stop("course catalog must be a list", call. = FALSE)
  required <- c("schema_version", "course_id", "title", "subtitle", "outcomes", "modules")
  missing <- setdiff(required, names(catalog))
  if (length(missing)) stop("course catalog is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  if (!identical(as.character(catalog$schema_version), "rlearnxr-course-1")) {
    stop("unsupported course catalog schema; expected rlearnxr-course-1", call. = FALSE)
  }
  if (!length(catalog$outcomes) || length(catalog$modules) < 1L) {
    stop("course catalog must include outcomes and at least one module", call. = FALSE)
  }
  modules <- catalog$modules
  if (!is.list(modules)) stop("course catalog modules must be a list", call. = FALSE)
  required_module <- c("id", "track", "level", "title", "minutes", "description", "concepts", "lesson_path", "status")
  ids <- character()
  for (module in modules) {
    if (!is.list(module)) stop("each course module must be a list", call. = FALSE)
    missing_module <- setdiff(required_module, names(module))
    if (length(missing_module)) stop("course module is missing: ", paste(missing_module, collapse = ", "), call. = FALSE)
    if (!length(module$id) || module$id %in% ids) stop("course module ids must be non-empty and unique", call. = FALSE)
    if (length(module$minutes) != 1L || is.na(suppressWarnings(as.numeric(module$minutes))) || as.numeric(module$minutes) < 1) {
      stop("course module minutes must be a positive number", call. = FALSE)
    }
    if (!length(module$concepts) || !length(module$lesson_path)) stop("course module needs concepts and lesson_path", call. = FALSE)
    ids <- c(ids, as.character(module$id))
  }
  invisible(TRUE)
}

course_template_path <- function() {
  search_roots <- unique(c(
    RLEARNXR_SOURCE_ROOT,
    normalizePath(".", winslash = "/", mustWork = TRUE),
    dirname(normalizePath(".", winslash = "/", mustWork = TRUE))
  ))
  source_candidates <- file.path(search_roots, "inst", "templates", "course.html")
  source_path <- source_candidates[file.exists(source_candidates)][1]
  if (length(source_path) && !is.na(source_path)) return(source_path)
  installed <- system.file("templates", "course.html", package = "rlearnxr")
  if (nzchar(installed) && file.exists(installed)) return(installed)
  stop("R-LearnXR course template was not found", call. = FALSE)
}

render_course_catalog <- function(catalog = default_course_catalog(), output_dir = "course",
                                  overwrite = FALSE) {
  validate_course_catalog(catalog)
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  ensure_dir(output_dir)
  outputs <- file.path(output_dir, c("index.html", "course-catalog.json"))
  if (!isTRUE(overwrite) && any(file.exists(outputs))) {
    stop("course catalog output already exists; use overwrite = TRUE to replace it", call. = FALSE)
  }
  catalog_json <- as.character(jsonlite::toJSON(
    catalog, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"
  ))
  template <- paste(readLines(course_template_path(), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  template <- gsub("{{TITLE}}", html_escape(catalog$title), template, fixed = TRUE)
  template <- sub("{{CATALOG_JSON}}", catalog_json, template, fixed = TRUE)
  writeLines(template, outputs[[1]], useBytes = TRUE)
  writeLines(catalog_json, outputs[[2]], useBytes = TRUE)
  invisible(list(index = outputs[[1]], catalog = outputs[[2]]))
}
