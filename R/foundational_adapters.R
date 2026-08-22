#' Bootstrap a sample mean for an uncertainty lesson
#'
#' @param x Finite numeric observations.
#' @param times Number of bootstrap samples.
#' @param seed Reproducibility seed.
#' @return An object that can be passed to `as_rclaimlab_evidence()`.
#' @export
bootstrap_mean <- function(x, times = 1000L, seed = 2026L) {
  x <- as.numeric(x)
  times <- as.integer(times)
  seed <- as.integer(seed)
  if (length(x) < 2L || any(!is.finite(x))) {
    stop("x must contain at least two finite numeric observations", call. = FALSE)
  }
  if (length(times) != 1L || is.na(times) || times < 20L) {
    stop("times must be one integer greater than or equal to 20", call. = FALSE)
  }
  if (length(seed) != 1L || is.na(seed)) stop("seed must be one integer", call. = FALSE)
  set.seed(seed)
  estimates <- replicate(times, mean(sample(x, length(x), replace = TRUE)))
  structure(
    list(
      statistic = "mean", observed = mean(x), estimates = as.numeric(estimates),
      interval = unname(stats::quantile(estimates, c(0.025, 0.975), names = FALSE)),
      sample_size = length(x), times = times, seed = seed
    ),
    class = c("rclaimlab_bootstrap", "list")
  )
}

#' @param variable Learner-facing variable name.
#' @export
as_rclaimlab_evidence.numeric <- function(x, labels = NULL, variable = "value",
                                         seed = 2026L, ...) {
  x <- as.numeric(x)
  if (length(x) < 2L || any(!is.finite(x))) {
    stop("numeric evidence requires at least two finite observations", call. = FALSE)
  }
  assert_scalar_text(variable, "variable")
  if (is.null(labels)) labels <- names(x)
  if (is.null(labels) || length(labels) != length(x) || any(!nzchar(labels))) {
    labels <- sprintf("observation-%04d", seq_along(x))
  }
  histogram <- graphics::hist(x, plot = FALSE, breaks = "Sturges")
  values <- data.frame(
    value = x,
    centered_value = x - mean(x),
    percentile = (rank(x, ties.method = "average") - 0.5) / length(x)
  )
  names(values)[[1]] <- variable
  build_rclaimlab_evidence(
    values, labels, "numeric_summary", paste0("summary(", variable, ")"), seed,
    roles = c("value", "centered_value", "percentile"),
    metadata = list(
      variable = variable,
      summary = list(
        n = length(x), mean = mean(x), median = stats::median(x), sd = stats::sd(x),
        iqr = stats::IQR(x), minimum = min(x), maximum = max(x),
        quartiles = unname(stats::quantile(x, c(0.25, 0.5, 0.75), names = FALSE))
      ),
      histogram = list(
        breaks = unname(histogram$breaks), counts = unname(histogram$counts),
        density = unname(histogram$density), mids = unname(histogram$mids)
      )
    )
  )
}

#' @export
as_rclaimlab_evidence.table <- function(x, seed = 2026L, ...) {
  if (!length(x) || any(!is.finite(as.numeric(x))) || any(as.numeric(x) < 0) || sum(x) <= 0) {
    stop("table evidence requires finite non-negative counts with a positive total", call. = FALSE)
  }
  observed <- as.numeric(x)
  cells <- as.data.frame(x, responseName = "count", stringsAsFactors = FALSE)
  labels <- apply(cells[setdiff(names(cells), "count")], 1, paste, collapse = " x ")
  total <- sum(observed)
  if (length(dim(x)) >= 2L) {
    expected <- as.numeric(outer(rowSums(x), colSums(x)) / total)
    residual <- ifelse(expected > 0, (observed - expected) / sqrt(expected), 0)
    values <- data.frame(
      count = observed, proportion = observed / total,
      expected_count = expected, standardized_residual = residual
    )
    roles <- c("count", "proportion", "expected", "residual")
  } else {
    values <- data.frame(
      count = observed, proportion = observed / total,
      cumulative_proportion = cumsum(observed) / total
    )
    roles <- c("count", "proportion", "cumulative_proportion")
  }
  build_rclaimlab_evidence(
    values, make.unique(labels), "table", "table(data)", seed, roles = roles,
    metadata = list(
      table_dimensions = dim(x), table_levels = dimnames(x), total = total,
      source_cells = cells
    )
  )
}

#' @export
as_rclaimlab_evidence.aov <- function(x, labels = NULL, seed = 2026L, ...) {
  frame <- stats::model.frame(x)
  observed <- stats::model.response(frame)
  if (!is.numeric(observed)) stop("aov evidence requires a numeric response", call. = FALSE)
  fitted <- as.numeric(stats::fitted(x))
  residual <- as.numeric(stats::residuals(x))
  residual_sd <- stats::sd(residual)
  standardized <- if (is.finite(residual_sd) && residual_sd > 0) residual / residual_sd else rep(0, length(residual))
  if (is.null(labels)) labels <- rownames(frame)
  table <- as.data.frame(summary(x)[[1]], check.names = FALSE)
  table$term <- rownames(table)
  rownames(table) <- NULL
  build_rclaimlab_evidence(
    data.frame(observed, group_mean = fitted, residual, standardized_residual = standardized),
    labels, "aov", deparse_analysis_call(x$call, "stats::aov"), seed,
    roles = c("outcome", "group_mean", "residual", "standardized_residual"),
    metadata = list(anova_table = table, coefficients = unname(stats::coef(x)))
  )
}

#' @param data Original data used by a correlation or t test. Chi-square
#'   results retain their observed table and do not require this argument.
#' @param x_column,y_column Numeric columns used by a correlation test, or the
#'   numeric outcome column used by a t test.
#' @param group Optional two-level group column used by a two-sample t test.
#' @export
as_rclaimlab_evidence.htest <- function(x, data = NULL, x_column = NULL,
                                       y_column = NULL, group = NULL,
                                       labels = NULL, seed = 2026L, ...) {
  method <- tolower(x$method %||% "")
  test <- compact_test_metadata(x)
  if (grepl("chi-squared", method, fixed = TRUE) && !is.null(x$observed)) {
    evidence <- as_rclaimlab_evidence(as.table(x$observed), seed = seed)
  } else if (grepl("correlation", method, fixed = TRUE)) {
    if (!is.data.frame(data) || is.null(x_column) || is.null(y_column) ||
        any(!c(x_column, y_column) %in% names(data))) {
      stop("correlation evidence requires data plus x_column and y_column", call. = FALSE)
    }
    complete <- stats::complete.cases(data[c(x_column, y_column)])
    values <- data[complete, c(x_column, y_column), drop = FALSE]
    if (nrow(values) < 3L || any(!vapply(values, is.numeric, logical(1))) ||
        any(!is.finite(as.matrix(values)))) {
      stop("correlation evidence requires at least three complete finite numeric pairs", call. = FALSE)
    }
    values$standardized_product <- as.numeric(scale(values[[1]])) * as.numeric(scale(values[[2]]))
    if (is.null(labels)) labels <- rownames(data)[complete]
    evidence <- build_rclaimlab_evidence(
      values, foundational_labels(labels, nrow(values)), "cor.test",
      deparse_analysis_call(x$call, "stats::cor.test"), seed,
      roles = c("variable", "variable", "association_contribution")
    )
  } else if (grepl("t-test", method, fixed = TRUE)) {
    if (!is.data.frame(data) || is.null(x_column) || !(x_column %in% names(data)) ||
        !is.numeric(data[[x_column]])) {
      stop("t-test evidence requires data and a numeric x_column", call. = FALSE)
    }
    columns <- c(x_column, group)
    complete <- stats::complete.cases(data[columns])
    outcome <- data[[x_column]][complete]
    if (length(outcome) < 3L || any(!is.finite(outcome))) {
      stop("t-test evidence requires at least three complete finite outcomes", call. = FALSE)
    }
    if (!is.null(group)) {
      groups <- factor(data[[group]][complete])
      if (nlevels(groups) != 2L) stop("t-test group must contain exactly two levels", call. = FALSE)
      centered <- outcome - stats::ave(outcome, groups, FUN = mean)
      group_code <- as.numeric(groups) - 1
    } else {
      null <- as.numeric(x$null.value %||% 0)
      centered <- outcome - mean(outcome)
      group_code <- outcome - null
    }
    evidence <- build_rclaimlab_evidence(
      data.frame(value = outcome, centered_value = centered, comparison = group_code),
      foundational_labels(labels %||% rownames(data)[complete], length(outcome)),
      "t.test", deparse_analysis_call(x$call, "stats::t.test"), seed,
      roles = c("outcome", "centered_value", "comparison")
    )
  } else {
    stop("unsupported htest method: ", x$method %||% "unknown", call. = FALSE)
  }
  evidence$analysis$engine <- if (grepl("chi-squared", method, fixed = TRUE)) "chisq.test" else evidence$analysis$engine
  evidence$metadata$test <- test
  refresh_evidence_hash(evidence)
}

#' @export
as_rclaimlab_evidence.rclaimlab_bootstrap <- function(x, ...) {
  estimates <- as.numeric(x$estimates)
  evidence <- build_rclaimlab_evidence(
    data.frame(
      bootstrap_mean = estimates,
      deviation = estimates - x$observed,
      percentile = (rank(estimates, ties.method = "average") - 0.5) / length(estimates)
    ),
    sprintf("resample-%04d", seq_along(estimates)), "bootstrap_mean",
    paste0("bootstrap_mean(x, times = ", x$times, ", seed = ", x$seed, ")"),
    x$seed, roles = c("estimate", "deviation", "percentile"),
    metadata = list(
      statistic = x$statistic, observed = x$observed, interval = x$interval,
      sample_size = x$sample_size, times = x$times
    )
  )
  evidence
}

foundational_labels <- function(labels, size) {
  labels <- as.character(labels)
  if (length(labels) != size || anyNA(labels) || any(!nzchar(labels)) || anyDuplicated(labels)) {
    labels <- sprintf("observation-%04d", seq_len(size))
  }
  labels
}

compact_test_metadata <- function(x) {
  numeric_field <- function(value) {
    if (is.null(value)) return(NULL)
    as.list(stats::setNames(as.numeric(value), names(value) %||% seq_along(value)))
  }
  Filter(Negate(is.null), list(
    method = x$method, alternative = x$alternative, data_name = x$data.name,
    statistic = numeric_field(x$statistic), parameter = numeric_field(x$parameter),
    estimate = numeric_field(x$estimate), null_value = numeric_field(x$null.value),
    p_value = as.numeric(x$p.value), confidence_interval = unname(x$conf.int)
  ))
}

refresh_evidence_hash <- function(evidence) {
  payload <- unclass(evidence)
  payload$analysis$artifact_hash <- NULL
  evidence$analysis$artifact_hash <- evidence_hash(payload)
  validate_rclaimlab_evidence(evidence)
  evidence
}
