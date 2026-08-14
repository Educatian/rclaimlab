root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "utils.R"))
source(file.path(root, "R", "zzz.R"))
source(file.path(root, "R", "lesson_bundle.R"))
source(file.path(root, "R", "scene_contract.R"))
source(file.path(root, "R", "lesson_manifest.R"))
source(file.path(root, "R", "render_scene.R"))

lesson_dir <- file.path(root, "examples", "mtcars-efficiency")
dir.create(file.path(lesson_dir, "data"), recursive = TRUE, showWarnings = FALSE)
cars <- mtcars
set.seed(2026)
cars$label <- rownames(cars)
scene_data <- data.frame(
  label = cars$label,
  x = as.numeric(scale(cars$mpg)),
  y = as.numeric(scale(cars$hp)),
  z = as.numeric(scale(cars$wt)),
  stringsAsFactors = FALSE
)
utils::write.csv(scene_data, file.path(lesson_dir, "data", "mtcars_efficiency_scene.csv"), row.names = FALSE)
render_scene(
  scene_data, x = "x", y = "y", z = "z", labels = scene_data$label,
  output_dir = file.path(lesson_dir, "scene"),
  title = "mtcars efficiency data space", overwrite = TRUE
)
write_lesson_manifest(
  lesson_dir, lesson_id = "mtcars-efficiency", title = "Vehicle efficiency data space",
  dataset_file = "data/mtcars_efficiency_scene.csv",
  dataset_source = "Derived from the built-in mtcars dataset distributed with R.",
  dataset_license = "R distribution licensing and attribution terms apply; see the R COPYING files.",
  overwrite = TRUE
)
cat("Built mtcars efficiency reference lesson.\n")
