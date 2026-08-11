render_scene <- function(data, x, y, z, labels = NULL, output_dir = "scene",
                         title = "R-LearnXR 3D Scene", overwrite = FALSE) {
  if (!is.data.frame(data)) stop("data must be a data.frame", call. = FALSE)
  axes <- c(x, y, z)
  if (length(axes) != 3L || any(!nzchar(axes)) || any(!axes %in% names(data))) {
    stop("x, y, and z must name three columns in data", call. = FALSE)
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
  if (!is.character(title) || length(title) != 1L) stop("title must be one character string", call. = FALSE)

  ensure_dir(output_dir)
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
