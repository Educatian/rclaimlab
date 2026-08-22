#' Convert an R analysis object into linked learning evidence
#'
#' `as_rclaimlab_evidence()` is the extension point for R-ClaimLab analysis
#' adapters. Methods preserve stable observation, dimension, and evidence IDs so
#' that tables, plots, scenes, explanations, and receipts refer to the same
#' analytical evidence.
#'
#' @param x An R data or model object.
#' @param ... Method-specific arguments.
#' @return An object of class `rclaimlab_evidence`.
#' @export
as_rclaimlab_evidence <- function(x, ...) UseMethod("as_rclaimlab_evidence")

#' @export
as_rclaimlab_evidence.default <- function(x, ...) {
  stop(
    "no R-ClaimLab evidence adapter is available for class: ",
    paste(class(x), collapse = "/"),
    call. = FALSE
  )
}

#' @param dimensions Numeric columns to compile as evidence dimensions.
#' @param labels Optional observation labels.
#' @param seed Deterministic analysis seed recorded in provenance.
#' @param units Optional named units for evidence dimensions.
#' @param analysis_call Optional source call recorded in provenance.
#' @export
as_rclaimlab_evidence.data.frame <- function(x, dimensions = NULL, labels = NULL,
                                            seed = 2026L, units = NULL,
                                            analysis_call = NULL, ...) {
  if (is.null(dimensions)) dimensions <- names(x)[vapply(x, is.numeric, logical(1))]
  dimensions <- as.character(dimensions)
  if (length(dimensions) < 1L || any(!dimensions %in% names(x))) {
    stop("data.frame evidence requires at least one named numeric dimension", call. = FALSE)
  }
  if (any(!vapply(x[dimensions], is.numeric, logical(1)))) {
    stop("all evidence dimensions must be numeric", call. = FALSE)
  }
  if (!nrow(x)) stop("evidence data cannot be empty", call. = FALSE)
  if (any(!is.finite(as.matrix(x[dimensions])))) {
    stop("evidence dimensions cannot contain NA or non-finite values", call. = FALSE)
  }
  if (is.null(labels)) {
    labels <- if ("label" %in% names(x)) x$label else rownames(x)
    if (is.null(labels) || length(labels) != nrow(x) || any(!nzchar(labels))) labels <- paste0("observation-", seq_len(nrow(x)))
  }
  build_rclaimlab_evidence(
    values = x[dimensions],
    labels = labels,
    engine = "data.frame",
    analysis_call = analysis_call %||% "as_rclaimlab_evidence(data.frame)",
    seed = seed,
    roles = rep("variable", length(dimensions)),
    units = units,
    metadata = list(source_columns = dimensions)
  )
}

#' @export
as_rclaimlab_evidence.prcomp <- function(x, labels = NULL, components = NULL,
                                        seed = 2026L, ...) {
  scores <- as.data.frame(x$x, stringsAsFactors = FALSE)
  if (is.null(components)) components <- names(scores)[seq_len(min(3L, ncol(scores)))]
  components <- as.character(components)
  if (length(components) < 2L || any(!components %in% names(scores))) {
    stop("prcomp evidence requires at least two score components", call. = FALSE)
  }
  if (is.null(labels)) labels <- rownames(scores)
  explained <- x$sdev^2 / sum(x$sdev^2)
  metadata <- list(
    loadings = unclass(x$rotation),
    standard_deviation = unname(x$sdev),
    explained_variance = stats::setNames(unname(explained), colnames(x$rotation)),
    center = x$center,
    scale = x$scale
  )
  build_rclaimlab_evidence(
    scores[components], labels, "prcomp", deparse_analysis_call(x$call, "stats::prcomp"),
    seed, roles = rep("component_score", length(components)), metadata = metadata
  )
}

#' @export
as_rclaimlab_evidence.lm <- function(x, labels = NULL, seed = 2026L, ...) {
  frame <- stats::model.frame(x)
  observed <- stats::model.response(frame)
  if (!is.numeric(observed)) stop("lm evidence requires a numeric response", call. = FALSE)
  prediction <- stats::predict(x, se.fit = TRUE)
  values <- data.frame(
    observed = as.numeric(observed),
    fitted = as.numeric(stats::fitted(x)),
    residual = as.numeric(stats::residuals(x)),
    interval_low = as.numeric(prediction$fit - 1.96 * prediction$se.fit),
    interval_high = as.numeric(prediction$fit + 1.96 * prediction$se.fit)
  )
  if (is.null(labels)) labels <- rownames(frame)
  fitted_values <- as.numeric(stats::fitted(x))
  residual_values <- as.numeric(stats::residuals(x))
  diagnostics <- list(
    residual_fitted_correlation = suppressWarnings(stats::cor(residual_values, fitted_values)),
    absolute_residual_fitted_correlation = suppressWarnings(stats::cor(abs(residual_values), fitted_values)),
    maximum_leverage = max(stats::hatvalues(x), na.rm = TRUE),
    shapiro_p_value = if (length(residual_values) >= 3L && length(residual_values) <= 5000L) stats::shapiro.test(residual_values)$p.value else NA_real_
  )
  build_rclaimlab_evidence(
    values, labels, "lm", deparse_analysis_call(x$call, "stats::lm"), seed,
    roles = c("outcome", "fitted", "residual", "uncertainty", "uncertainty"),
    metadata = list(
      coefficients = stats::setNames(unname(stats::coef(x)), names(stats::coef(x))),
      sigma = summary(x)$sigma, diagnostics = diagnostics
    )
  )
}

#' @param threshold Classification threshold recorded by the `glm` adapter.
#' @export
as_rclaimlab_evidence.glm <- function(x, labels = NULL, seed = 2026L,
                                     threshold = 0.5, ...) {
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold) || threshold <= 0 || threshold >= 1) {
    stop("threshold must be one number between zero and one", call. = FALSE)
  }
  frame <- stats::model.frame(x)
  observed <- stats::model.response(frame)
  if (is.factor(observed)) observed <- as.numeric(observed) - 1
  link <- stats::predict(x, type = "link", se.fit = TRUE)
  probability <- stats::fitted(x)
  lower <- x$family$linkinv(link$fit - 1.96 * link$se.fit)
  upper <- x$family$linkinv(link$fit + 1.96 * link$se.fit)
  predicted_class <- as.numeric(probability >= threshold)
  truth <- as.numeric(observed)
  true_positive <- sum(predicted_class == 1 & truth == 1)
  true_negative <- sum(predicted_class == 0 & truth == 0)
  false_positive <- sum(predicted_class == 1 & truth == 0)
  false_negative <- sum(predicted_class == 0 & truth == 1)
  safe_ratio <- function(numerator, denominator) if (denominator > 0) numerator / denominator else NA_real_
  values <- data.frame(
    observed = as.numeric(observed),
    predicted_probability = as.numeric(probability),
    residual = as.numeric(stats::residuals(x, type = "deviance")),
    probability_low = as.numeric(lower),
    probability_high = as.numeric(upper),
    predicted_class = predicted_class
  )
  if (is.null(labels)) labels <- rownames(frame)
  build_rclaimlab_evidence(
    values, labels, "glm", deparse_analysis_call(x$call, "stats::glm"), seed,
    roles = c("outcome", "probability", "residual", "uncertainty", "uncertainty", "classification"),
    metadata = list(
      coefficients = stats::setNames(unname(stats::coef(x)), names(stats::coef(x))),
      family = x$family$family,
      link = x$family$link,
      threshold = threshold,
      classification = list(
        true_positive = true_positive, true_negative = true_negative,
        false_positive = false_positive, false_negative = false_negative,
        accuracy = mean(predicted_class == truth),
        sensitivity = safe_ratio(true_positive, true_positive + false_negative),
        specificity = safe_ratio(true_negative, true_negative + false_positive),
        brier_score = mean((probability - truth)^2)
      )
    )
  )
}

#' @param data Numeric data used to estimate the `kmeans` object.
#' @export
as_rclaimlab_evidence.kmeans <- function(x, data, dimensions = NULL, labels = NULL,
                                        seed = 2026L, ...) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  if (nrow(data) != length(x$cluster)) stop("data rows must match the kmeans cluster assignments", call. = FALSE)
  if (is.null(dimensions)) dimensions <- names(data)[vapply(data, is.numeric, logical(1))]
  dimensions <- as.character(dimensions)
  if (length(dimensions) < 2L || any(!dimensions %in% names(data)) || any(!vapply(data[dimensions], is.numeric, logical(1)))) {
    stop("kmeans evidence requires at least two numeric dimensions", call. = FALSE)
  }
  matrix_data <- as.matrix(data[dimensions])
  if (any(!is.finite(matrix_data))) stop("kmeans evidence data cannot contain NA or non-finite values", call. = FALSE)
  centers <- as.matrix(x$centers[, dimensions, drop = FALSE])
  distance <- vapply(seq_len(nrow(matrix_data)), function(i) {
    sqrt(sum((matrix_data[i, ] - centers[x$cluster[[i]], ])^2))
  }, numeric(1))
  previous_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (is.null(previous_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
    } else assign(".Random.seed", previous_seed, envir = .GlobalEnv)
  }, add = TRUE)
  baseline_pairs <- outer(x$cluster, x$cluster, `==`)
  sensitivity_seeds <- as.integer(seed) + seq_len(5L)
  agreement <- vapply(sensitivity_seeds, function(candidate_seed) {
    set.seed(candidate_seed)
    candidate <- stats::kmeans(matrix_data, centers = nrow(centers), nstart = 10L)
    mean(outer(candidate$cluster, candidate$cluster, `==`) == baseline_pairs)
  }, numeric(1))
  values <- data.frame(data[dimensions], cluster = as.numeric(x$cluster), distance_to_centroid = distance, check.names = FALSE)
  if (is.null(labels)) labels <- rownames(data)
  build_rclaimlab_evidence(
    values, labels, "kmeans", "stats::kmeans", seed,
    roles = c(rep("feature", length(dimensions)), "cluster", "distance"),
    metadata = list(
      centers = unclass(x$centers), size = unname(x$size), tot_withinss = unname(x$tot.withinss),
      stability = list(
        metric = "pairwise co-membership agreement", seeds = sensitivity_seeds,
        agreement = agreement, minimum = min(agreement), mean = mean(agreement)
      )
    )
  )
}

build_rclaimlab_evidence <- function(values, labels, engine, analysis_call, seed,
                                    roles = NULL, units = NULL, metadata = list()) {
  values <- as.data.frame(values, stringsAsFactors = FALSE, check.names = FALSE)
  if (!nrow(values) || ncol(values) < 1L) stop("evidence must contain rows and at least one dimension", call. = FALSE)
  if (any(!vapply(values, is.numeric, logical(1))) || any(!is.finite(as.matrix(values)))) {
    stop("evidence values must be finite numeric columns", call. = FALSE)
  }
  labels <- as.character(labels)
  if (length(labels) != nrow(values) || anyNA(labels) || any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    stop("evidence labels must be non-empty, unique, and match the observations", call. = FALSE)
  }
  dimension_names <- names(values)
  if (is.null(roles)) roles <- rep("variable", ncol(values))
  roles <- rep_len(as.character(roles), ncol(values))
  if (is.null(units)) units <- rep(NA_character_, ncol(values))
  if (!is.null(names(units))) units <- units[dimension_names]
  units <- rep_len(as.character(units), ncol(values))
  observation_ids <- sprintf("obs-%04d", seq_len(nrow(values)))
  dimension_ids <- sprintf("dim-%03d", seq_len(ncol(values)))
  observations <- data.frame(observation_id = observation_ids, label = labels, source_row = seq_len(nrow(values)), stringsAsFactors = FALSE)
  dimensions <- data.frame(dimension_id = dimension_ids, label = dimension_names, role = roles, unit = units, stringsAsFactors = FALSE)
  long <- do.call(rbind, lapply(seq_along(dimension_ids), function(j) {
    data.frame(
      evidence_id = sprintf("ev-%04d-%03d", seq_len(nrow(values)), j),
      observation_id = observation_ids,
      dimension_id = dimension_ids[[j]],
      value = as.numeric(values[[j]]),
      stringsAsFactors = FALSE
    )
  }))
  links <- long[c("evidence_id", "observation_id", "dimension_id")]
  links$source_type <- "analysis_result"
  links$source_ref <- paste0(engine, ":", links$observation_id, ":", links$dimension_id)
  packages <- list(rclaimlab = current_rclaimlab_version())
  payload <- list(
    schema_version = "rclaimlab-evidence-2",
    analysis = list(
      engine = engine,
      call = paste(analysis_call, collapse = " "),
      seed = as.integer(seed),
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      packages = packages
    ),
    observations = observations,
    dimensions = dimensions,
    values = long,
    links = links,
    metadata = metadata
  )
  payload$analysis$artifact_hash <- evidence_hash(payload)
  value <- structure(payload, class = c("rclaimlab_evidence", "list"))
  validate_rclaimlab_evidence(value)
  value
}

#' Validate linked R-ClaimLab evidence
#'
#' @param x An evidence object.
#' @return Invisibly returns `TRUE` when the Evidence IR contract is valid.
#' @export
validate_rclaimlab_evidence <- function(x) {
  if (!inherits(x, "rclaimlab_evidence")) stop("x must be an rclaimlab_evidence object", call. = FALSE)
  if (!identical(x$schema_version, "rclaimlab-evidence-2")) stop("unsupported evidence schema", call. = FALSE)
  required_analysis <- c("engine", "call", "seed", "r_version", "packages", "artifact_hash")
  if (!all(required_analysis %in% names(x$analysis))) stop("evidence analysis provenance is incomplete", call. = FALSE)
  if (anyDuplicated(x$observations$observation_id) || anyDuplicated(x$dimensions$dimension_id) || anyDuplicated(x$values$evidence_id)) {
    stop("evidence identifiers must be unique", call. = FALSE)
  }
  if (!all(x$values$observation_id %in% x$observations$observation_id) ||
      !all(x$values$dimension_id %in% x$dimensions$dimension_id)) {
    stop("evidence values contain dangling observation or dimension links", call. = FALSE)
  }
  if (!identical(x$values$evidence_id, x$links$evidence_id)) stop("evidence provenance links are not synchronized", call. = FALSE)
  if (any(!is.finite(x$values$value))) stop("evidence values must be finite", call. = FALSE)
  invisible(TRUE)
}

#' @export
as.data.frame.rclaimlab_evidence <- function(x, row.names = NULL, optional = FALSE, ...) {
  validate_rclaimlab_evidence(x)
  matrix_values <- matrix(NA_real_, nrow = nrow(x$observations), ncol = nrow(x$dimensions))
  row_index <- match(x$values$observation_id, x$observations$observation_id)
  column_index <- match(x$values$dimension_id, x$dimensions$dimension_id)
  matrix_values[cbind(row_index, column_index)] <- x$values$value
  colnames(matrix_values) <- make.unique(x$dimensions$label)
  data.frame(x$observations[c("observation_id", "label")], matrix_values, check.names = FALSE, stringsAsFactors = FALSE)
}

#' @export
print.rclaimlab_evidence <- function(x, ...) {
  cat("<rclaimlab_evidence>", x$analysis$engine, "\n")
  cat("Observations:", nrow(x$observations), " Dimensions:", nrow(x$dimensions), "\n")
  cat("Hash:", x$analysis$artifact_hash, "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_evidence <- function(object, ...) {
  list(
    schema_version = object$schema_version,
    engine = object$analysis$engine,
    observations = nrow(object$observations),
    dimensions = object$dimensions,
    artifact_hash = object$analysis$artifact_hash,
    metadata = object$metadata
  )
}

#' @param x_dimension,y_dimension Dimensions used by the base R preview plot.
#' @export
plot.rclaimlab_evidence <- function(x, x_dimension = x$dimensions$dimension_id[[1]],
                                   y_dimension = if (nrow(x$dimensions) >= 2L) x$dimensions$dimension_id[[2]] else NULL, ...) {
  table <- as.data.frame(x)
  x_index <- match(x_dimension, x$dimensions$dimension_id)
  y_index <- if (is.null(y_dimension)) NA_integer_ else match(y_dimension, x$dimensions$dimension_id)
  if (is.na(x_index) || (!is.null(y_dimension) && is.na(y_index))) stop("plot dimensions were not found in the evidence object", call. = FALSE)
  y <- if (is.na(y_index)) seq_len(nrow(table)) else table[[y_index + 2L]]
  y_label <- if (is.na(y_index)) "Observation order" else x$dimensions$label[[y_index]]
  graphics::plot(
    table[[x_index + 2L]], y,
    xlab = x$dimensions$label[[x_index]], ylab = y_label, ...
  )
  graphics::text(table[[x_index + 2L]], y, labels = table$label, pos = 3, cex = 0.75)
  invisible(x)
}

evidence_hash <- function(value) {
  json <- jsonlite::toJSON(value, auto_unbox = TRUE, dataframe = "rows", null = "null", na = "null", digits = NA)
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)
  writeLines(as.character(json), path, useBytes = TRUE)
  unname(tools::md5sum(path))
}

current_rclaimlab_version <- function() {
  description <- tryCatch(suppressWarnings(read.dcf("DESCRIPTION")), error = function(...) NULL)
  if (!is.null(description) && "Version" %in% colnames(description)) return(unname(description[1, "Version"]))
  installed <- tryCatch(as.character(utils::packageVersion("rclaimlab")), error = function(...) NULL)
  if (!is.null(installed)) return(installed)
  "2.0.0-dev"
}

#' Read an Evidence IR artifact
#'
#' @param path Path to an `evidence.json` artifact.
#' @return An object of class `rclaimlab_evidence`.
#' @export
read_rclaimlab_evidence <- function(path) {
  if (!file.exists(path)) stop("evidence artifact was not found", call. = FALSE)
  value <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE, simplifyMatrix = TRUE)
  value <- structure(value, class = c("rclaimlab_evidence", "list"))
  validate_rclaimlab_evidence(value)
  value
}

#' Write an Evidence IR artifact
#'
#' @param x An `rclaimlab_evidence` object.
#' @param path Destination JSON path.
#' @param overwrite Whether to replace an existing file.
#' @return Invisibly returns the normalized output path.
#' @export
write_rclaimlab_evidence <- function(x, path, overwrite = FALSE) {
  validate_rclaimlab_evidence(x)
  if (file.exists(path) && !isTRUE(overwrite)) stop("evidence artifact already exists; use overwrite = TRUE", call. = FALSE)
  ensure_dir(dirname(path))
  write_json_object(unclass(x), path)
  invisible(normalizePath(path, winslash = "/", mustWork = FALSE))
}

deparse_analysis_call <- function(call, fallback) {
  if (is.null(call)) fallback else paste(deparse(call, width.cutoff = 500L), collapse = " ")
}
