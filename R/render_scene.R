render_scene <- function(data, x, y, z, labels = NULL, output_dir = "scene",
                         title = "R-LearnXR 3D Scene", overwrite = FALSE) {
  if (!is.data.frame(data)) stop("data must be a data.frame", call. = FALSE)
  axes <- c(x, y, z)
  if (!is.character(axes) || length(axes) != 3L || any(!nzchar(axes)) ||
      anyDuplicated(axes) || any(!axes %in% names(data))) {
    stop("x, y, and z must name three columns in data", call. = FALSE)
  }
  if (nrow(data) < 3L) {
    stop("data must contain at least three rows", call. = FALSE)
  }
  if (any(!vapply(data[axes], is.numeric, logical(1)))) {
    stop("x, y, and z columns must be numeric", call. = FALSE)
  }
  if (any(!is.finite(as.matrix(data[axes])))) {
    stop("x, y, and z columns cannot contain NA or non-finite values", call. = FALSE)
  }
  if (is.null(labels)) labels <- rownames(data) %||% paste0("point-", seq_len(nrow(data)))
  labels <- as.character(labels)
  if (length(labels) != nrow(data)) stop("labels must match the number of rows", call. = FALSE)
  if (anyNA(labels) || any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    stop("labels must be non-empty, non-missing, and unique", call. = FALSE)
  }
  if (!is.character(title) || length(title) != 1L || is.na(title) || !nzchar(trimws(title))) {
    stop("title must be one non-empty character string", call. = FALSE)
  }

  ensure_dir(output_dir)
  output_files <- file.path(output_dir, c("points.json", "index.html"))
  if (!isTRUE(overwrite) && any(file.exists(output_files))) {
    stop("scene output already exists; use overwrite = TRUE to replace it", call. = FALSE)
  }
  points <- vapply(seq_len(nrow(data)), function(i) {
    paste0(
      '{"x":', json_number(data[[x]][i]),
      ',"y":', json_number(data[[y]][i]),
      ',"z":', json_number(data[[z]][i]),
      ',"label":"', json_escape(labels[i]), '"}'
    )
  }, character(1))
  points_json <- paste0("[", paste(points, collapse = ","), "]")
  writeLines(points_json, file.path(output_dir, "points.json"), useBytes = TRUE)
  writeLines(scene_html(title, points_json), file.path(output_dir, "index.html"), useBytes = TRUE)
  invisible(list(index = file.path(output_dir, "index.html"), points = file.path(output_dir, "points.json")))
}
