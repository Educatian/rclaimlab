#' Validate and normalize the R-LearnXR scene data contract
#'
#' @param data A data frame containing three numeric coordinate columns.
#' @param x,y,z Names of the columns used for the three scene axes.
#' @param labels Optional point labels. If omitted, an existing `label` column,
#'   row names, or stable point names are used.
#' @param observation_ids Optional stable Evidence IR observation identifiers.
#' @param min_rows Minimum number of observations required for a meaningful scene.
#' @return A data frame with exactly `label`, `x`, `y`, and `z` columns.
#' @export
validate_scene_data <- function(data, x = "x", y = "y", z = "z", labels = NULL,
                                observation_ids = NULL, min_rows = 3L) {
  if (!is.data.frame(data)) stop("data must be a data.frame", call. = FALSE)
  axes <- c(x, y, z)
  if (!is.character(axes) || length(axes) != 3L || anyNA(axes) ||
      any(!nzchar(axes)) || anyDuplicated(axes) || any(!axes %in% names(data))) {
    stop("x, y, and z must name three columns in data", call. = FALSE)
  }
  if (length(min_rows) != 1L || is.na(min_rows) || min_rows < 3L) {
    stop("min_rows must be one integer greater than or equal to 3", call. = FALSE)
  }
  if (nrow(data) < min_rows) {
    minimum_label <- if (min_rows == 3L) "three" else as.character(min_rows)
    stop("data must contain at least ", minimum_label, " rows", call. = FALSE)
  }
  if (any(!vapply(data[axes], is.numeric, logical(1)))) {
    stop("x, y, and z columns must be numeric", call. = FALSE)
  }
  coordinates <- data[axes]
  if (any(!is.finite(as.matrix(coordinates)))) {
    stop("x, y, and z columns cannot contain NA or non-finite values", call. = FALSE)
  }
  if (is.null(labels)) {
    labels <- if ("label" %in% names(data)) data$label else {
      row_names <- rownames(data)
      if (!is.null(row_names) && length(row_names) == nrow(data) &&
          all(nzchar(row_names))) row_names else paste0("point-", seq_len(nrow(data)))
    }
  }
  if (length(labels) != nrow(data)) stop("labels must match the number of rows", call. = FALSE)
  labels <- as.character(labels)
  if (anyNA(labels) || any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    stop("labels must be non-empty, non-missing, and unique", call. = FALSE)
  }
  if (is.null(observation_ids)) {
    observation_ids <- if ("observation_id" %in% names(data)) data$observation_id else sprintf("obs-%04d", seq_len(nrow(data)))
  }
  observation_ids <- as.character(observation_ids)
  if (length(observation_ids) != nrow(data) || anyNA(observation_ids) ||
      any(!nzchar(trimws(observation_ids))) || anyDuplicated(observation_ids)) {
    stop("observation_ids must be non-empty, non-missing, unique, and match the rows", call. = FALSE)
  }
  data.frame(
    observation_id = observation_ids,
    label = labels,
    x = as.numeric(data[[x]]),
    y = as.numeric(data[[y]]),
    z = as.numeric(data[[z]]),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
