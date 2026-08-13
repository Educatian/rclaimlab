write_json_object <- function(value, path) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    json <- jsonlite::toJSON(value, auto_unbox = TRUE, pretty = TRUE, null = "null")
    writeLines(as.character(json), path, useBytes = TRUE)
    return(invisible(path))
  }
  if (is.list(value) && !is.null(names(value))) {
    fields <- vapply(names(value), function(name) {
      paste0('"', json_escape(name), '":', json_value(value[[name]]))
    }, character(1))
    writeLines(paste0("{", paste(fields, collapse = ","), "}"), path, useBytes = TRUE)
    return(invisible(path))
  }
  stop("writing a manifest requires the optional jsonlite package", call. = FALSE)
}

json_value <- function(value) {
  if (is.null(value)) return("null")
  if (length(value) > 1L && is.atomic(value) && is.null(names(value))) {
    return(paste0("[", paste(vapply(as.list(value), json_value, character(1)), collapse = ","), "]"))
  }
  if (is.logical(value) && length(value) == 1L) return(ifelse(is.na(value), "null", ifelse(value, "true", "false")))
  if (is.numeric(value) && length(value) == 1L) return(ifelse(is.na(value), "null", json_number(value)))
  if (is.character(value) && length(value) == 1L) return(if (is.na(value)) "null" else paste0('"', json_escape(value), '"'))
  if (is.atomic(value) && !is.null(names(value))) {
    fields <- vapply(names(value), function(name) paste0('"', json_escape(name), '":', json_value(value[[name]])), character(1))
    return(paste0("{", paste(fields, collapse = ","), "}"))
  }
  if (is.list(value) && is.null(names(value))) return(paste0("[", paste(vapply(value, json_value, character(1)), collapse = ","), "]"))
  if (is.list(value)) {
    fields <- vapply(names(value), function(name) paste0('"', json_escape(name), '":', json_value(value[[name]])), character(1))
    return(paste0("{", paste(fields, collapse = ","), "}"))
  }
  "null"
}

lesson_bundle_files <- function(path, include_receipt = TRUE) {
  candidates <- c(
    "lesson-manifest.json", "index.qmd", "_quarto.yml", "README.md",
    "DATA_LICENSE.md", "renv.lock", "data", "R", "scene", "checks"
  )
  files <- unlist(lapply(candidates, function(candidate) {
    target <- file.path(path, candidate)
    if (dir.exists(target)) list.files(target, recursive = TRUE, full.names = TRUE, include.dirs = FALSE)
    else if (file.exists(target)) target else character()
  }), use.names = FALSE)
  files <- unique(files[file.exists(files)])
  if (!isTRUE(include_receipt)) {
    root <- normalizePath(path, winslash = "/")
    files <- files[!grepl("^checks[/\\\\]learning-receipt\\.json$", substring(normalizePath(files, winslash = "/"), nchar(root) + 2L))]
  }
  files
}

copy_lesson_tree <- function(source, destination, include_receipt = TRUE) {
  files <- lesson_bundle_files(source, include_receipt = include_receipt)
  if (!length(files)) stop("lesson contains no exportable files", call. = FALSE)
  for (file in files) {
    relative <- substring(normalizePath(file, winslash = "/"), nchar(normalizePath(source, winslash = "/")) + 2L)
    target <- file.path(destination, relative)
    ensure_dir(dirname(target))
    file.copy(file, target, overwrite = TRUE)
  }
  invisible(destination)
}

export_lesson_bundle <- function(path = ".", output = NULL, zip = FALSE,
                                 include_receipt = TRUE, overwrite = FALSE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (!dir.exists(path)) stop("lesson path does not exist", call. = FALSE)
  if (!file.exists(file.path(path, "lesson-manifest.json"))) {
    write_lesson_manifest(path, overwrite = TRUE)
  }
  if (is.null(output)) output <- file.path(dirname(path), paste0(basename(path), "-bundle"))
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  if (isTRUE(zip) || grepl("\\.zip$", output, ignore.case = TRUE)) {
    zip_path <- if (grepl("\\.zip$", output, ignore.case = TRUE)) output else paste0(output, ".zip")
    if (file.exists(zip_path) && !isTRUE(overwrite)) stop("bundle already exists; use overwrite = TRUE", call. = FALSE)
    staging <- tempfile("rlearnxr-bundle-")
    ensure_dir(staging)
    copy_lesson_tree(path, staging, include_receipt = include_receipt)
    old_wd <- getwd()
    setwd(staging)
    on.exit(setwd(old_wd), add = TRUE)
    utils::zip(zipfile = zip_path, files = list.files(staging, recursive = TRUE, full.names = FALSE), flags = "-q", extras = "-r", zip = "zip")
    setwd(old_wd)
    unlink(staging, recursive = TRUE, force = TRUE)
    return(invisible(zip_path))
  }
  if (dir.exists(output) && length(list.files(output, all.files = TRUE, no.. = TRUE)) > 0L && !isTRUE(overwrite)) {
    stop("bundle directory is not empty; use overwrite = TRUE", call. = FALSE)
  }
  ensure_dir(output)
  copy_lesson_tree(path, output, include_receipt = include_receipt)
  invisible(output)
}

import_datasandbox_bundle <- function(bundle, output = "rlearnxr-imported-lesson", overwrite = FALSE) {
  if (!file.exists(bundle) && !dir.exists(bundle)) stop("DataSandbox bundle was not found", call. = FALSE)
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  if ((dir.exists(output) && length(list.files(output, all.files = TRUE, no.. = TRUE)) > 0L) && !isTRUE(overwrite)) {
    stop("output directory is not empty; use overwrite = TRUE", call. = FALSE)
  }
  ensure_dir(output)
  if (dir.exists(bundle)) {
    copy_lesson_tree(bundle, output)
    return(invisible(output))
  }
  if (grepl("\\.zip$", bundle, ignore.case = TRUE)) {
    utils::unzip(bundle, exdir = output)
    return(invisible(output))
  }
  if (!grepl("\\.json$", bundle, ignore.case = TRUE)) stop("bundle must be a directory, ZIP, or portable JSON bundle", call. = FALSE)
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("importing a portable bundle requires the optional jsonlite package", call. = FALSE)
  payload <- jsonlite::fromJSON(bundle, simplifyVector = FALSE)
  if (is.null(payload$schema_version) || payload$schema_version != "rlearnxr-bundle-1") {
    stop("unsupported portable bundle schema", call. = FALSE)
  }
  if (is.null(payload$files) || !is.list(payload$files)) stop("portable bundle has no files", call. = FALSE)
  for (relative in names(payload$files)) {
    target <- file.path(output, relative)
    ensure_dir(dirname(target))
    writeLines(as.character(payload$files[[relative]]), target, useBytes = TRUE)
  }
  invisible(output)
}
