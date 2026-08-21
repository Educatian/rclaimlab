root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "utils.R"))
source(file.path(root, "R", "zzz.R"))
source(file.path(root, "R", "lesson_bundle.R"))
source(file.path(root, "R", "evidence_adapters.R"))
source(file.path(root, "R", "scene_contract.R"))
source(file.path(root, "R", "lesson_manifest.R"))
source(file.path(root, "R", "render_scene.R"))

if (!requireNamespace("palmerpenguins", quietly = TRUE)) {
  stop("Install palmerpenguins before building the reference lesson", call. = FALSE)
}

metrics <- c("bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g")
penguins <- palmerpenguins::penguins[, c("species", metrics)]
penguins <- penguins[stats::complete.cases(penguins), ]
row.names(penguins) <- NULL

set.seed(2026)
selected <- unlist(lapply(split(seq_len(nrow(penguins)), penguins$species), function(index) {
  index[unique(round(seq(1, length(index), length.out = 8)))]
}), use.names = FALSE)
lesson_penguins <- penguins[selected, ]

pca <- stats::prcomp(lesson_penguins[, metrics], center = TRUE, scale. = TRUE)
scores <- pca$x[, 1:3, drop = FALSE]
scale_factor <- max(abs(scores))
scene_data <- data.frame(
  x = scores[, 1] / scale_factor,
  y = scores[, 2] / scale_factor,
  z = scores[, 3] / scale_factor,
  label = paste(lesson_penguins$species, seq_len(nrow(lesson_penguins))),
  species = lesson_penguins$species,
  stringsAsFactors = FALSE
)

lesson_dir <- file.path(root, "examples", "penguin-pca")
dir.create(file.path(lesson_dir, "data"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(scene_data, file.path(lesson_dir, "data", "penguin_pca_points.csv"), row.names = FALSE)
render_scene(
  scene_data,
  x = "x",
  y = "y",
  z = "z",
  labels = scene_data$label,
  output_dir = file.path(lesson_dir, "scene"),
  title = "Penguin morphology PCA data space",
  overwrite = TRUE
)
write_lesson_manifest(
  lesson_dir, lesson_id = "penguin-pca", title = "Penguin morphology PCA",
  dataset_file = "data/penguin_pca_points.csv", dataset_source = "palmerpenguins R package",
  dataset_license = "CC0",
  education = list(
    audience = "introductory data-science learners", estimated_minutes = 20L,
    prerequisites = c("mean and standard deviation", "read a two-dimensional scatterplot", "basic R assignment syntax"),
    objectives = c("explain why variables are standardized before PCA", "interpret a PCA score as a multivariate coordinate", "compare PC1, PC2, and PC3 with an evidence-based limitation", "reproduce the scene from deterministic R code"),
    sequence = c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce"),
    assessment = "assessment-rubric.md", instructor_materials = c("educator-guide.md", "answer-key.md"),
    accessibility_alternative = "accessible-alternative.md", extension_activities = c("extension-activities.md")
  ), overwrite = TRUE
)
cat("Built penguin PCA reference lesson.\n")
