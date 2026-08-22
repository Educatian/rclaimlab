# Replace `example_model` with the S3 class produced by an existing R method.
as_rclaimlab_evidence.example_model <- function(x, labels = NULL, seed = 2026L, ...) {
  # Extract existing model results. Do not refit or reimplement the method here.
  values <- data.frame(
    dimension_one = as.numeric(x$result_one),
    dimension_two = as.numeric(x$result_two)
  )
  if (is.null(labels)) labels <- rownames(values)

  rclaimlab:::build_rclaimlab_evidence(
    values = values,
    labels = labels,
    engine = "example_model",
    analysis_call = paste(deparse(x$call), collapse = " "),
    seed = seed,
    roles = c("result", "result"),
    metadata = list(method_metadata = x$metadata)
  )
}
