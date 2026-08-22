#' Prepare repeated learning events for an evidence lesson
#'
#' Aggregates event-level rows to one row per learner without silently treating
#' repeated events as independent learners. The result can be passed directly
#' to `profile_learning_data()` or `lesson_from_data()`.
#'
#' @param data Event-level data frame.
#' @param learner Column identifying the learner or analysis unit.
#' @param event Optional event-type column.
#' @param outcome Optional numeric or categorical outcome column.
#' @param time Optional numeric, Date, or date-time sequence column.
#' @param duration Optional non-negative numeric duration column.
#' @param grouping Optional stable class, course, or site column.
#' @return A data frame of auditable learner-level features with an aggregation
#'   recipe stored in the `rclaimlab_recipe` attribute.
#' @export
prepare_learning_events <- function(data, learner, event = NULL, outcome = NULL,
                                    time = NULL, duration = NULL, grouping = NULL) {
  if (!is.data.frame(data) || !nrow(data)) stop("data must be a non-empty data.frame", call. = FALSE)
  assert_scalar_text(learner, "learner")
  optional <- Filter(Negate(is.null), list(event = event, outcome = outcome, time = time, duration = duration, grouping = grouping))
  columns <- c(learner, unlist(optional, use.names = FALSE))
  if (any(!columns %in% names(data))) stop("event columns were not found in data: ", paste(setdiff(columns, names(data)), collapse = ", "), call. = FALSE)
  learner_values <- as.character(data[[learner]])
  if (anyNA(learner_values) || any(!nzchar(trimws(learner_values)))) stop("learner identifiers must be complete and non-empty", call. = FALSE)
  if (!is.null(duration) && (!is.numeric(data[[duration]]) || any(data[[duration]] < 0, na.rm = TRUE))) {
    stop("duration must name a non-negative numeric column", call. = FALSE)
  }
  if (!is.null(time) && !is.numeric(data[[time]]) && !inherits(data[[time]], c("Date", "POSIXct", "POSIXlt"))) {
    stop("time must name a numeric, Date, or date-time column", call. = FALSE)
  }
  indices <- split(seq_len(nrow(data)), learner_values)
  first_value <- function(value) {
    available <- value[!is.na(value)]
    if (length(available)) available[[1]] else NA
  }
  last_value <- function(value, order_index = seq_along(value)) {
    available <- order_index[!is.na(value[order_index])]
    if (!length(available)) return(NA)
    value[available[[length(available)]]]
  }
  rows <- lapply(names(indices), function(id) {
    index <- indices[[id]]
    order_index <- if (is.null(time)) seq_along(index) else order(data[[time]][index], na.last = TRUE)
    row <- list(learner_id = id, event_count = length(index))
    if (!is.null(event)) row$unique_event_types <- length(unique(data[[event]][index][!is.na(data[[event]][index])]))
    if (!is.null(duration)) {
      row$total_duration <- sum(data[[duration]][index], na.rm = TRUE)
      row$mean_duration <- if (all(is.na(data[[duration]][index]))) NA_real_ else mean(data[[duration]][index], na.rm = TRUE)
    }
    if (!is.null(outcome)) {
      values <- data[[outcome]][index]
      if (is.numeric(values)) row$outcome_mean <- if (all(is.na(values))) NA_real_ else mean(values, na.rm = TRUE)
      row$outcome_last <- last_value(values, order_index)
    }
    if (!is.null(time)) {
      values <- data[[time]][index]
      finite_values <- values[!is.na(values)]
      row$active_span <- if (length(finite_values) >= 2L) as.numeric(max(finite_values) - min(finite_values)) else 0
    }
    if (!is.null(grouping)) {
      values <- data[[grouping]][index]
      row$group <- first_value(values)
      row$group_inconsistent <- length(unique(values[!is.na(values)])) > 1L
    }
    as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  names(result)[names(result) == "learner_id"] <- learner
  attr(result, "rclaimlab_recipe") <- list(
    source_rows = nrow(data), output_rows = nrow(result), learner = learner,
    event = event, outcome = outcome, time = time, duration = duration,
    grouping = grouping, ordering = if (is.null(time)) "source row order" else time,
    privacy = "No identifiers or rows were transmitted; aggregation ran in local R."
  )
  class(result) <- c("rclaimlab_learning_features", class(result))
  result
}

#' @export
print.rclaimlab_learning_features <- function(x, ...) {
  recipe <- attr(x, "rclaimlab_recipe")
  cat("<rclaimlab_learning_features>", nrow(x), "units from", recipe$source_rows, "events\n")
  NextMethod("print")
  invisible(x)
}
