render_scene <- function(data, x, y, z, labels = NULL, output_dir = "scene",
                         title = "R-LearnXR 3D Scene", overwrite = FALSE) {
  scene_data <- validate_scene_data(data, x, y, z, labels)
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
      '{"x":', json_number(scene_data$x[i]),
      ',"y":', json_number(scene_data$y[i]),
      ',"z":', json_number(scene_data$z[i]),
      ',"label":"', json_escape(scene_data$label[i]), '"}'
    )
  }, character(1))
  points_json <- paste0("[", paste(points, collapse = ","), "]")
  writeLines(points_json, file.path(output_dir, "points.json"), useBytes = TRUE)
  writeLines(scene_html(title, points_json), file.path(output_dir, "index.html"), useBytes = TRUE)
  invisible(list(index = file.path(output_dir, "index.html"), points = file.path(output_dir, "points.json")))
}
