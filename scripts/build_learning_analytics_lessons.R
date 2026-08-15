root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "utils.R"))
source(file.path(root, "R", "zzz.R"))
source(file.path(root, "R", "lesson_bundle.R"))
source(file.path(root, "R", "scene_contract.R"))
source(file.path(root, "R", "lesson_manifest.R"))
source(file.path(root, "R", "render_scene.R"))

build_one <- function(lesson_id, title, input_file, source, license, education) {
  lesson_dir <- file.path(root, "examples", lesson_id)
  raw <- read.csv(file.path(lesson_dir, input_file), stringsAsFactors = FALSE)
  set.seed(2026)
  if (lesson_id == "learning-analytics") {
    scene_data <- data.frame(label = raw$profile, x = as.numeric(scale(raw$revision_count)), y = as.numeric(scale(raw$transfer_score)), z = as.numeric(scale(1 - raw$hint_rate)))
  } else {
    scene_data <- data.frame(label = raw$profile, x = as.numeric(scale(raw$practice_minutes)), y = as.numeric(scale(raw$revision_count)), z = as.numeric(scale(raw$transfer_score)))
  }
  utils::write.csv(scene_data, file.path(lesson_dir, "data", paste0(lesson_id, "_scene.csv")), row.names = FALSE)
  render_scene(scene_data, "x", "y", "z", labels = scene_data$label, output_dir = file.path(lesson_dir, "scene"), title = title, overwrite = TRUE)
  write_lesson_manifest(lesson_dir, lesson_id = lesson_id, title = title, dataset_file = input_file, dataset_source = source, dataset_license = license, education = education, overwrite = TRUE)
}

education <- function(minutes, objectives, materials) list(
  audience = "introductory learning analytics and data science learners",
  estimated_minutes = minutes,
  prerequisites = c("basic data-frame vocabulary", "read a simple plot"),
  objectives = objectives,
  sequence = c("orient", "predict", "run_r", "explore", "explain", "transfer", "reproduce"),
  assessment = "Use the reusable claim-evidence-limitation-transfer rubric.",
  instructor_materials = materials,
  accessibility_alternative = "semantic table and keyboard path",
  extension_activities = c("change one feature", "document a validity or privacy limitation")
)

build_one("learning-analytics", "Learning analytics event-to-construct data space", "data/learning_events.csv", "Synthetic R-LearnXR activity profiles.", "CC0-style synthetic instructional data; no real learner records.", education(25L, c("distinguish an event from a learning construct", "describe a synthetic learner-safe pattern", "state a privacy or validity limitation"), c("README.md", "../docs/curriculum/learning-analytics-edm-lab.md")))
build_one("edm-patterns", "Educational data mining feature space", "data/edm_features.csv", "Synthetic R-LearnXR feature profiles.", "CC0-style synthetic instructional data; no real learner records.", education(25L, c("compare clustering and prediction as discovery tools", "explain a standardized feature-space pattern", "state a fairness or validity limitation"), c("README.md", "../docs/curriculum/learning-analytics-edm-lab.md")))
cat("Built Learning Analytics and EDM reference lessons.\n")
