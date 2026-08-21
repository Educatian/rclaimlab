root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "load_rlearnxr_source.R"), chdir = FALSE)

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

lesson_penguins$label <- paste(lesson_penguins$species, seq_len(nrow(lesson_penguins)))

lesson_dir <- file.path(root, "examples", "penguin-pca")
dir.create(file.path(lesson_dir, "data"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(lesson_penguins, file.path(lesson_dir, "data", "penguin_pca_source.csv"), row.names = FALSE)
lesson <- lesson_from_data(
  lesson_penguins, analysis = "prcomp", dimensions = metrics, id_column = "label",
  question = "Which morphology measurements vary together, and which penguins have contrasting principal-component scores?",
  intent = "reduce", unit_of_analysis = "one penguin with complete morphology measurements",
  decision_context = "learning to interpret multivariate variation without treating PCA as a species classifier",
  title = "Penguin morphology PCA", id = "penguin-pca"
)
compile_lesson(lesson, lesson_dir, overwrite = TRUE)
write_reference_data_license(
  lesson_dir,
  "palmerpenguins R package; the instructional subset contains complete morphology records.",
  "CC0, following the palmerpenguins dataset documentation."
)
write_lesson_manifest(
  lesson_dir, lesson_id = "penguin-pca", title = "Penguin morphology PCA",
  evidence_file = "evidence.json", evidence_hash = lesson$evidence$analysis$artifact_hash,
  dataset_file = "data/penguin_pca_source.csv", dataset_source = "palmerpenguins R package",
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
