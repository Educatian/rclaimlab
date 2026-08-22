script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[[1]]) else "scripts/build_demo.R"
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = FALSE)
source(file.path(root, "scripts", "load_rclaimlab_source.R"), chdir = FALSE)
data <- read.csv(file.path(root, "examples", "lesson", "data", "learning_points.csv"), stringsAsFactors = FALSE)
lesson <- lesson_from_data(
  data, analysis = "data_view", dimensions = c("x", "y", "z"), id_column = "label",
  question = "How does one stable observation stay linked across the table, 2D view, 3D scene, explanation, and receipt?",
  intent = "explore", unit_of_analysis = "one synthetic contributor-training observation",
  title = "R-ClaimLab reference data space", id = "lesson"
)
compile_lesson(
  lesson,
  output_dir = file.path(root, "examples", "lesson"),
  overwrite = TRUE
)
write_reference_data_license(
  file.path(root, "examples", "lesson"),
  "Synthetic contributor-training points bundled with R-ClaimLab.",
  "CC0-style synthetic instructional data.",
  "No real learner or participant records are included."
)
write_lesson_manifest(
  file.path(root, "examples", "lesson"), lesson_id = "lesson",
  title = "R-ClaimLab reference data space",
  dataset_file = "data/learning_points.csv",
  dataset_source = "Synthetic contributor-training points bundled with R-ClaimLab.",
  dataset_license = "CC0",
  overwrite = TRUE
)
cat("Built reference scene.\n")
