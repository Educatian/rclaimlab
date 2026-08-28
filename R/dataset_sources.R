#' Declare a local or public dataset source
#'
#' Dataset source objects describe where tabular data live without downloading
#' them. Credentials are deliberately not accepted or stored by this API.
#'
#' @param provider One of `local`, `huggingface`, or `kaggle`.
#' @param id Local file path or provider dataset identifier.
#' @param revision Immutable Hugging Face revision or Kaggle version.
#' @param config,split,file Optional provider-specific selection.
#' @return An object of class `rclaimlab_dataset_source`.
#' @export
dataset_source <- function(provider = c("local", "huggingface", "kaggle"), id,
                           revision = NULL, config = NULL, split = NULL,
                           file = NULL) {
  provider <- match.arg(provider)
  assert_scalar_text(id, "id")
  for (field in c("revision", "config", "split", "file")) {
    value <- get(field)
    if (!is.null(value)) assert_scalar_text(value, field)
  }
  if (provider != "local" && !grepl("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", id)) {
    stop("remote dataset id must use the form owner/name", call. = FALSE)
  }
  if (provider == "local" && !is.null(file)) {
    stop("local sources use id as the file path; file must be NULL", call. = FALSE)
  }
  structure(
    list(
      schema_version = "rclaimlab-dataset-source-1",
      provider = provider, id = id, revision = revision,
      config = config, split = split, file = file
    ),
    class = c("rclaimlab_dataset_source", "list")
  )
}

#' Inspect a dataset without importing its rows
#'
#' @param source A `rclaimlab_dataset_source`.
#' @return An object of class `rclaimlab_dataset_manifest`.
#' @export
inspect_dataset <- function(source) {
  validate_dataset_source(source)
  value <- switch(
    source$provider,
    local = inspect_local_dataset(source),
    huggingface = inspect_huggingface_dataset(source),
    kaggle = inspect_kaggle_dataset(source)
  )
  value <- structure(value, class = c("rclaimlab_dataset_manifest", "list"))
  validate_dataset_manifest(value)
  value
}

#' Preview bounded rows from a dataset source
#'
#' @param source A dataset source.
#' @param rows Number of rows, from 1 to 100.
#' @return A data frame.
#' @export
preview_dataset <- function(source, rows = 100L) {
  validate_dataset_source(source)
  rows <- as.integer(rows)
  if (length(rows) != 1L || is.na(rows) || rows < 1L || rows > 100L) {
    stop("rows must be one integer between 1 and 100", call. = FALSE)
  }
  if (source$provider == "huggingface" && !is.null(source$revision) && !is.null(source$file)) {
    dataset <- import_dataset(source, max_rows = max(2L, rows), sample = "head", cache = TRUE)
    return(dataset$data[seq_len(min(rows, nrow(dataset$data))), , drop = FALSE])
  }
  if (source$provider == "huggingface") return(preview_huggingface_dataset(source, rows))
  dataset <- import_dataset(source, max_rows = rows, sample = "head", cache = TRUE)
  dataset$data[seq_len(min(rows, nrow(dataset$data))), , drop = FALSE]
}

#' Import a bounded public tabular dataset
#'
#' @param source A dataset source.
#' @param columns Optional columns retained after import.
#' @param max_rows Maximum imported rows.
#' @param sample Deterministic sampling or first rows.
#' @param seed Sampling seed.
#' @param cache Whether remote downloads use the user cache.
#' @param max_download_mb Maximum remote file size.
#' @return An object of class `rclaimlab_dataset`.
#' @export
import_dataset <- function(source, columns = NULL, max_rows = 10000L,
                           sample = c("deterministic", "head"), seed = 2026L,
                           cache = TRUE, max_download_mb = 250) {
  validate_dataset_source(source)
  sample <- match.arg(sample)
  max_rows <- as.integer(max_rows)
  if (length(max_rows) != 1L || is.na(max_rows) || max_rows < 2L) {
    stop("max_rows must be one integer greater than or equal to 2", call. = FALSE)
  }
  max_download_mb <- as.numeric(max_download_mb)
  if (length(max_download_mb) != 1L || is.na(max_download_mb) || max_download_mb <= 0) {
    stop("max_download_mb must be one positive number", call. = FALSE)
  }
  manifest <- inspect_dataset(source)
  imported <- switch(
    source$provider,
    local = import_local_source(source),
    huggingface = import_huggingface_source(source, manifest, cache, max_download_mb),
    kaggle = import_kaggle_source(source, manifest, cache, max_download_mb)
  )
  data <- imported$data
  reject_unsupported_tabular_data(data)
  if (!is.null(columns)) {
    columns <- unique(as.character(columns))
    if (!length(columns) || any(!columns %in% names(data))) {
      stop("columns must name fields in the imported data", call. = FALSE)
    }
    data <- data[columns]
  }
  original_rows <- nrow(data)
  source_rows <- seq_len(original_rows)
  if (original_rows > max_rows) {
    if (sample == "head") {
      keep <- seq_len(max_rows)
    } else {
      keep <- with_preserved_seed(seed, sort(base::sample.int(original_rows, max_rows)))
    }
    data <- data[keep, , drop = FALSE]
    source_rows <- source_rows[keep]
  }
  fingerprint <- evidence_hash(list(
    provider = source$provider,
    id = if (source$provider == "local") basename(source$id) else source$id,
    revision = manifest$revision, file = imported$file,
    content_md5 = imported$content_md5
  ))
  record_ids <- sprintf("src-%s-%08d", substr(fingerprint, 1L, 12L), source_rows)
  value <- structure(
    list(
      schema_version = "rclaimlab-dataset-1",
      data = data,
      source = source,
      manifest = manifest,
      source_fingerprint = fingerprint,
      source_record_id = record_ids,
      source_row = source_rows,
      import = list(
        original_rows = original_rows, imported_rows = nrow(data),
        columns = names(data), sample = sample, seed = as.integer(seed),
        max_rows = max_rows, file = imported$file,
        content_md5 = imported$content_md5, cached = isTRUE(imported$cached)
      )
    ),
    class = c("rclaimlab_dataset", "list")
  )
  validate_rclaimlab_dataset(value)
  value
}

#' Profile imported data while preserving source provenance
#'
#' @param x An `rclaimlab_dataset` or data frame.
#' @param outcome,intent,grouping,time Passed to `profile_learning_data()`.
#' @return An `rclaimlab_data_profile` with dataset provenance.
#' @export
profile_dataset <- function(x, outcome = NULL, intent = "explore",
                            grouping = NULL, time = NULL) {
  if (inherits(x, "rclaimlab_dataset")) {
    validate_rclaimlab_dataset(x)
    profile <- profile_learning_data(x$data, outcome, intent, grouping, time)
    profile$source <- list(
      provider = x$source$provider,
      id = if (x$source$provider == "local") basename(x$source$id) else x$source$id,
      revision = x$manifest$revision, license = x$manifest$license,
      fingerprint = x$source_fingerprint, citation = x$manifest$citation
    )
    profile$source_record_id <- x$source_record_id
    profile$schema_version <- "rclaimlab-dataset-profile-1"
    return(profile)
  }
  profile_learning_data(x, outcome, intent, grouping, time)
}

validate_dataset_source <- function(x) {
  if (!inherits(x, "rclaimlab_dataset_source") ||
      !identical(x$schema_version, "rclaimlab-dataset-source-1") ||
      !(x$provider %in% c("local", "huggingface", "kaggle"))) {
    stop("source must be a valid rclaimlab_dataset_source", call. = FALSE)
  }
  invisible(TRUE)
}

validate_dataset_manifest <- function(x) {
  required <- c("schema_version", "provider", "id", "revision", "files",
                "license", "citation", "source_url", "publishable")
  if (!inherits(x, "rclaimlab_dataset_manifest") ||
      !all(required %in% names(x)) ||
      !identical(x$schema_version, "rclaimlab-dataset-manifest-1")) {
    stop("dataset manifest does not satisfy rclaimlab-dataset-manifest-1", call. = FALSE)
  }
  invisible(TRUE)
}

validate_rclaimlab_dataset <- function(x) {
  if (!inherits(x, "rclaimlab_dataset") ||
      !identical(x$schema_version, "rclaimlab-dataset-1") ||
      !is.data.frame(x$data) || nrow(x$data) < 2L ||
      length(x$source_record_id) != nrow(x$data) ||
      anyDuplicated(x$source_record_id)) {
    stop("dataset does not satisfy rclaimlab-dataset-1", call. = FALSE)
  }
  invisible(TRUE)
}

inspect_local_dataset <- function(source) {
  path <- normalizePath(source$id, winslash = "/", mustWork = TRUE)
  info <- file.info(path)
  list(
    schema_version = "rclaimlab-dataset-manifest-1", provider = "local",
    id = basename(path), revision = unname(tools::md5sum(path)),
    files = data.frame(file = basename(path), size = info$size, stringsAsFactors = FALSE),
    license = NA_character_, citation = NA_character_, source_url = NA_character_,
    publishable = FALSE, local_path = path
  )
}

inspect_huggingface_dataset <- function(source) {
  base <- "https://datasets-server.huggingface.co"
  id_query <- utils::URLencode(source$id, reserved = TRUE)
  hub_url <- paste0("https://huggingface.co/api/datasets/", source$id)
  if (!is.null(source$revision)) hub_url <- paste0(hub_url, "/revision/", utils::URLencode(source$revision, reserved = TRUE))
  hub <- http_json(hub_url)
  validity <- http_json(paste0(base, "/is-valid?dataset=", id_query))
  if (!isTRUE(validity$viewer) && !isTRUE(validity$preview) && !isTRUE(validity$parquet)) {
    stop("Hugging Face Dataset Viewer cannot serve this public tabular dataset", call. = FALSE)
  }
  splits <- http_json(paste0(base, "/splits?dataset=", id_query))
  size <- tryCatch(http_json(paste0(base, "/size?dataset=", id_query)), error = function(error) list())
  revision <- as.character(hub$sha %||% source$revision %||% NA_character_)
  split_records <- as.data.frame(splits$splits %||% data.frame(), stringsAsFactors = FALSE)
  selected_config <- source$config %||% if (nrow(split_records)) as.character(split_records$config[[1]]) else "default"
  selected_split <- source$split %||% if (nrow(split_records)) as.character(split_records$split[[1]]) else "train"
  parquet <- tryCatch(
    http_json(paste0(base, "/parquet?dataset=", id_query)),
    error = function(error) list(parquet_files = list())
  )
  files <- as.data.frame(parquet$parquet_files %||% data.frame(), stringsAsFactors = FALSE)
  if (nrow(files)) {
    files <- files[files$config == selected_config & files$split == selected_split, , drop = FALSE]
    files <- data.frame(
      file = as.character(files$filename), size = as.numeric(files$size),
      url = as.character(files$url), config = as.character(files$config),
      split = as.character(files$split), stringsAsFactors = FALSE
    )
  } else files <- data.frame(
    file = character(), size = numeric(), url = character(),
    config = character(), split = character(), stringsAsFactors = FALSE
  )
  if (!is.null(source$file)) {
    siblings <- hub$siblings %||% list()
    siblings <- if (is.data.frame(siblings) && "rfilename" %in% names(siblings)) {
      as.character(siblings$rfilename)
    } else {
      vapply(siblings, function(item) as.character(item$rfilename %||% ""), character(1))
    }
    if (!(source$file %in% siblings)) {
      stop("selected Hugging Face file does not exist at the resolved revision", call. = FALSE)
    }
    pinned_file <- data.frame(
      file = source$file, size = NA_real_,
      url = paste0("https://huggingface.co/datasets/", source$id, "/resolve/", revision, "/", source$file),
      config = selected_config, split = selected_split, stringsAsFactors = FALSE
    )
    files <- rbind(pinned_file, files[files$file != source$file, , drop = FALSE])
  }
  card <- hub$cardData %||% list()
  license <- collapse_metadata_text(card$license)
  if (is.na(license)) {
    license_tag <- as.character(hub$tags %||% character())
    license_tag <- license_tag[grepl("^license:", license_tag)]
    if (length(license_tag)) license <- sub("^license:", "", license_tag[[1]])
  }
  citation <- collapse_metadata_text(card$citation)
  statistics <- tryCatch(
    http_json(paste0(base, "/statistics?dataset=", id_query,
                     "&config=", utils::URLencode(selected_config, reserved = TRUE),
                     "&split=", utils::URLencode(selected_split, reserved = TRUE))),
    error = function(error) list()
  )
  list(
    schema_version = "rclaimlab-dataset-manifest-1", provider = "huggingface",
    id = source$id, revision = revision, config = selected_config, split = selected_split,
    files = files, license = license, citation = citation,
    source_url = paste0("https://huggingface.co/datasets/", source$id,
                        if (!is.na(revision) && nzchar(revision)) paste0("/tree/", revision) else ""),
    publishable = !is.null(source$revision) && !is.null(source$file) &&
      !is.na(revision) && nzchar(revision) && !is.na(license) && nzchar(license),
    viewer = list(validity = validity, size = size, statistics = statistics)
  )
}

preview_huggingface_dataset <- function(source, rows) {
  manifest <- inspect_huggingface_dataset(source)
  query <- paste0(
    "https://datasets-server.huggingface.co/rows?dataset=", utils::URLencode(source$id, reserved = TRUE),
    "&config=", utils::URLencode(manifest$config, reserved = TRUE),
    "&split=", utils::URLencode(manifest$split, reserved = TRUE),
    "&offset=0&length=", rows
  )
  payload <- http_json(query, simplify = FALSE)
  records <- lapply(payload$rows %||% list(), `[[`, "row")
  rows_to_data_frame(records)
}

import_huggingface_source <- function(source, manifest, cache, max_download_mb) {
  file_record <- NULL
  if (!is.null(source$file)) {
    revision <- manifest$revision
    if (is.na(revision) || !nzchar(revision)) stop("Hugging Face import requires a resolved revision", call. = FALSE)
    url <- paste0("https://huggingface.co/datasets/", source$id, "/resolve/", revision, "/", source$file)
    file_record <- list(file = source$file, url = url, size = NA_real_)
  } else if (nrow(manifest$files)) {
    file_record <- as.list(manifest$files[1L, , drop = FALSE])
    file_record <- lapply(file_record, function(value) value[[1]])
  } else {
    stop("no importable CSV or Parquet file was found; select file explicitly", call. = FALSE)
  }
  download_tabular_url(file_record$url, file_record$file, manifest, cache, max_download_mb)
}

inspect_kaggle_dataset <- function(source) {
  kaggle <- kaggle_executable()
  metadata_dir <- tempfile("rclaimlab-kaggle-metadata-")
  dir.create(metadata_dir, recursive = TRUE)
  on.exit(unlink(metadata_dir, recursive = TRUE, force = TRUE), add = TRUE)
  status <- system2(kaggle, c("datasets", "metadata", source$id, "-p", shQuote(metadata_dir)),
                    stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
    stop("Kaggle metadata request failed. Run 'kaggle auth login' and verify dataset access. ",
         paste(status, collapse = " "), call. = FALSE)
  }
  metadata_file <- file.path(metadata_dir, "dataset-metadata.json")
  if (!file.exists(metadata_file)) stop("Kaggle CLI did not return dataset metadata", call. = FALSE)
  metadata <- jsonlite::fromJSON(metadata_file, simplifyVector = FALSE)
  resources <- metadata$resources %||% list()
  files <- if (length(resources)) data.frame(
    file = vapply(resources, function(x) as.character(x$path %||% x$name %||% ""), character(1)),
    size = vapply(resources, function(x) suppressWarnings(as.numeric(x$totalBytes %||% NA_real_)), numeric(1)),
    stringsAsFactors = FALSE
  ) else data.frame(file = character(), size = numeric(), stringsAsFactors = FALSE)
  license <- collapse_metadata_text(metadata$licenses %||% metadata$license)
  revision <- source$revision %||% as.character(metadata$datasetVersionNumber %||% NA_character_)
  list(
    schema_version = "rclaimlab-dataset-manifest-1", provider = "kaggle",
    id = source$id, revision = revision, files = files, license = license,
    citation = collapse_metadata_text(metadata$subtitle %||% metadata$title),
    source_url = paste0("https://www.kaggle.com/datasets/", source$id),
    publishable = !is.na(revision) && nzchar(revision) && !is.na(license) && nzchar(license)
  )
}

import_kaggle_source <- function(source, manifest, cache, max_download_mb) {
  kaggle <- kaggle_executable()
  cache_dir <- dataset_cache_dir(source, manifest, cache)
  ensure_dir(cache_dir)
  marker <- file.path(cache_dir, ".complete")
  cached <- file.exists(marker)
  if (!cached) {
    status <- system2(kaggle, c("datasets", "download", "-d", source$id, "-p", shQuote(cache_dir)),
                      stdout = TRUE, stderr = TRUE)
    if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
      stop("Kaggle download failed. Run 'kaggle auth login' and verify dataset access. ",
           paste(status, collapse = " "), call. = FALSE)
    }
    archives <- list.files(cache_dir, pattern = "\\.zip$", full.names = TRUE, ignore.case = TRUE)
    if (!length(archives)) stop("Kaggle download did not produce a ZIP archive", call. = FALSE)
    if (sum(file.info(archives)$size, na.rm = TRUE) > max_download_mb * 1024^2) {
      stop("Kaggle archive exceeds max_download_mb", call. = FALSE)
    }
    for (archive in archives) safe_unzip(archive, cache_dir, max_download_mb * 4)
    writeLines("complete", marker, useBytes = TRUE)
  }
  candidates <- list.files(cache_dir, recursive = TRUE, full.names = TRUE,
                           pattern = "\\.(csv|tsv|parquet)$", ignore.case = TRUE)
  candidates <- candidates[!grepl("(^|[/\\\\])\\.", substring(candidates, nchar(cache_dir) + 2L))]
  selected <- select_tabular_file(candidates, source$file)
  data <- read_tabular_file(selected)
  list(data = data, file = basename(selected), content_md5 = unname(tools::md5sum(selected)), cached = cached)
}

import_local_source <- function(source) {
  path <- normalizePath(source$id, winslash = "/", mustWork = TRUE)
  list(data = read_tabular_file(path), file = basename(path),
       content_md5 = unname(tools::md5sum(path)), cached = FALSE)
}

download_tabular_url <- function(url, filename, manifest, cache, max_download_mb) {
  cache_source <- list(provider = manifest$provider, id = manifest$id, file = filename)
  cache_dir <- dataset_cache_dir(cache_source, manifest, cache)
  ensure_dir(cache_dir)
  destination <- file.path(cache_dir, basename(filename))
  cached <- file.exists(destination)
  if (!cached) {
    maximum_bytes <- max_download_mb * 1024^2
    handle <- curl::new_handle(
      timeout = 60L, failonerror = TRUE,
      maxfilesize_large = maximum_bytes,
      useragent = "rclaimlab/2.1"
    )
    tryCatch(
      curl::curl_fetch_disk(url, destination, handle = handle),
      error = function(error) {
        unlink(destination, force = TRUE)
        stop("dataset download failed or exceeded max_download_mb: ", conditionMessage(error), call. = FALSE)
      }
    )
  }
  size <- file.info(destination)$size
  if (is.na(size) || size > max_download_mb * 1024^2) {
    if (!cached) unlink(destination, force = TRUE)
    stop("downloaded file exceeds max_download_mb", call. = FALSE)
  }
  list(data = read_tabular_file(destination), file = basename(destination),
       content_md5 = unname(tools::md5sum(destination)), cached = cached)
}

read_tabular_file <- function(path) {
  extension <- tolower(tools::file_ext(path))
  value <- switch(
    extension,
    csv = utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                          fileEncoding = "UTF-8-BOM"),
    tsv = utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE,
                            fileEncoding = "UTF-8-BOM"),
    parquet = {
      if (!requireNamespace("arrow", quietly = TRUE)) {
        stop("Parquet import requires the optional 'arrow' package; install it or select CSV", call. = FALSE)
      }
      as.data.frame(arrow::read_parquet(path), stringsAsFactors = FALSE)
    },
    stop("supported tabular files are CSV, TSV, and Parquet", call. = FALSE)
  )
  if (!is.data.frame(value) || nrow(value) < 2L || ncol(value) < 1L) {
    stop("imported tabular data must contain at least two rows and one column", call. = FALSE)
  }
  value
}

reject_unsupported_tabular_data <- function(data) {
  if (!is.data.frame(data) || any(vapply(data, is.list, logical(1)))) {
    stop("nested or list columns are not supported in v2.1 tabular workflows", call. = FALSE)
  }
  if (anyDuplicated(names(data)) || any(!nzchar(names(data)))) {
    stop("imported columns must have unique non-empty names", call. = FALSE)
  }
  invisible(TRUE)
}

http_json <- function(url, simplify = TRUE, attempts = 3L) {
  attempts <- as.integer(attempts)
  if (length(attempts) != 1L || is.na(attempts) || attempts < 1L || attempts > 3L) {
    stop("attempts must be one integer from 1 to 3", call. = FALSE)
  }
  response <- NULL
  for (attempt in seq_len(attempts)) {
    handle <- curl::new_handle(
      timeout = 15L, useragent = "rclaimlab/2.1",
      http_content_decoding = TRUE, accept_encoding = "gzip, deflate"
    )
    response <- tryCatch(curl::curl_fetch_memory(url, handle = handle), error = identity)
    if (inherits(response, "error")) {
      if (attempt < attempts) {
        Sys.sleep(0.25 * attempt)
        next
      }
      stop("dataset service request failed: ", conditionMessage(response), call. = FALSE)
    }
    retryable <- response$status_code %in% c(429L, 500L, 502L, 503L, 504L)
    if (retryable && attempt < attempts) {
      Sys.sleep(0.25 * attempt)
      next
    }
    break
  }
  if (response$status_code < 200L || response$status_code >= 300L) {
    stop("dataset service returned HTTP ", response$status_code, call. = FALSE)
  }
  text <- iconv(rawToChar(response$content), from = "UTF-8", to = "UTF-8", sub = "byte")
  tryCatch(
    jsonlite::fromJSON(text, simplifyVector = simplify),
    error = function(error) {
      repaired <- escape_json_string_controls(response$content)
      if (identical(repaired, text)) stop(error)
      jsonlite::fromJSON(repaired, simplifyVector = simplify)
    }
  )
}

escape_json_string_controls <- function(content) {
  bytes <- as.integer(content)
  output <- raw()
  in_string <- FALSE
  escaped <- FALSE
  replacement <- c(
    `8` = "\\b", `9` = "\\t", `10` = "\\n",
    `12` = "\\f", `13` = "\\r"
  )
  for (byte in bytes) {
    if (in_string && !escaped && byte < 32L) {
      token <- replacement[[as.character(byte)]] %||%
        sprintf("\\u%04x", byte)
      output <- c(output, charToRaw(token))
      escaped <- FALSE
      next
    }
    output <- c(output, as.raw(byte))
    if (escaped) {
      escaped <- FALSE
    } else if (in_string && byte == 92L) {
      escaped <- TRUE
    } else if (byte == 34L) {
      in_string <- !in_string
    }
  }
  rawToChar(output)
}

rows_to_data_frame <- function(records) {
  if (!length(records)) stop("dataset preview returned no rows", call. = FALSE)
  names_union <- unique(unlist(lapply(records, names), use.names = FALSE))
  columns <- lapply(names_union, function(name) {
    values <- lapply(records, function(row) row[[name]] %||% NA)
    if (any(vapply(values, is.list, logical(1)))) {
      stop("nested or list columns are not supported in v2.1 tabular workflows", call. = FALSE)
    }
    unlist(values, recursive = FALSE, use.names = FALSE)
  })
  names(columns) <- names_union
  as.data.frame(columns, check.names = FALSE, stringsAsFactors = FALSE)
}

kaggle_executable <- function() {
  executable <- Sys.which("kaggle")
  if (!nzchar(executable)) {
    stop("Kaggle import requires the official 'kaggle' CLI; install it and run 'kaggle auth login'", call. = FALSE)
  }
  executable
}

safe_unzip <- function(archive, destination, max_unpacked_mb) {
  listing <- utils::unzip(archive, list = TRUE)
  names <- gsub("\\\\", "/", listing$Name)
  unsafe <- grepl("^/|^[A-Za-z]:|(^|/)\\.\\.(/|$)", names)
  nested <- grepl("\\.(zip|tar|tgz|gz|7z)$", names, ignore.case = TRUE)
  if (any(unsafe)) stop("archive contains an unsafe path", call. = FALSE)
  if (any(nested)) stop("nested archives are not supported", call. = FALSE)
  if (sum(listing$Length, na.rm = TRUE) > max_unpacked_mb * 1024^2) {
    stop("archive exceeds the unpacked size limit", call. = FALSE)
  }
  utils::unzip(archive, exdir = destination)
  invisible(TRUE)
}

select_tabular_file <- function(candidates, requested = NULL) {
  if (!length(candidates)) stop("no CSV, TSV, or Parquet file was found", call. = FALSE)
  if (!is.null(requested)) {
    match <- candidates[basename(candidates) == basename(requested)]
    if (length(match) != 1L) stop("requested dataset file was not found or was ambiguous", call. = FALSE)
    return(match)
  }
  if (length(candidates) != 1L) {
    stop("dataset contains multiple tabular files; select one with source$file", call. = FALSE)
  }
  candidates[[1]]
}

dataset_cache_dir <- function(source, manifest, cache) {
  if (!isTRUE(cache)) return(tempfile("rclaimlab-dataset-"))
  key <- evidence_hash(list(
    provider = source$provider %||% manifest$provider,
    id = source$id %||% manifest$id,
    revision = manifest$revision,
    file = source$file %||% NULL
  ))
  file.path(tools::R_user_dir("rclaimlab", "cache"), "datasets", key)
}

collapse_metadata_text <- function(value) {
  if (is.null(value) || !length(value)) return(NA_character_)
  if (is.list(value)) value <- unlist(value, recursive = TRUE, use.names = FALSE)
  value <- paste(as.character(value), collapse = "; ")
  if (!nzchar(trimws(value))) NA_character_ else value
}

with_preserved_seed <- function(seed, code) {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  previous <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (had_seed) assign(".Random.seed", previous, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(as.integer(seed))
  force(code)
}

#' @export
print.rclaimlab_dataset_source <- function(x, ...) {
  cat("<rclaimlab_dataset_source>", x$provider, x$id, "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_dataset_source <- function(object, ...) unclass(object)

#' @export
print.rclaimlab_dataset_manifest <- function(x, ...) {
  cat("<rclaimlab_dataset_manifest>", x$provider, x$id, "\n")
  cat("Revision:", x$revision %||% "unresolved", " License:", x$license %||% "unknown", "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_dataset_manifest <- function(object, ...) {
  list(provider = object$provider, id = object$id, revision = object$revision,
       files = nrow(object$files), license = object$license,
       publishable = object$publishable)
}

#' @export
as.data.frame.rclaimlab_dataset_manifest <- function(x, row.names = NULL, optional = FALSE, ...) x$files

#' @export
print.rclaimlab_dataset <- function(x, ...) {
  cat("<rclaimlab_dataset>", nrow(x$data), "rows x", ncol(x$data), "columns\n")
  cat("Source:", x$source$provider, x$source$id, " Fingerprint:", x$source_fingerprint, "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_dataset <- function(object, ...) {
  list(rows = nrow(object$data), columns = ncol(object$data),
       source = object$source$id, provider = object$source$provider,
       revision = object$manifest$revision, fingerprint = object$source_fingerprint)
}

#' @export
as.data.frame.rclaimlab_dataset <- function(x, row.names = NULL, optional = FALSE, ...) x$data
