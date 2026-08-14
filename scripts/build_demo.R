script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[[1]]) else "scripts/build_demo.R"
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
source(file.path(root, "R", "zzz.R"))
source(file.path(root, "R", "scene_contract.R"))
source(file.path(root, "R", "render_scene.R"))
data <- read.csv(file.path(root, "examples", "lesson", "data", "learning_points.csv"), stringsAsFactors = FALSE)
render_scene(
  data,
  x = "x",
  y = "y",
  z = "z",
  labels = data$label,
  output_dir = file.path(root, "examples", "lesson", "scene"),
  title = "R-LearnXR reference data space",
  overwrite = TRUE
)
cat("Built reference scene.\n")
