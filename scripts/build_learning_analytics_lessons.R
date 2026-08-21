root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "load_rlearnxr_source.R"), chdir = FALSE)

education <- function(minutes, objectives, materials) list(
  audience = "introductory learning analytics and data science learners",
  estimated_minutes = minutes,
  prerequisites = c("basic data-frame vocabulary", "read a simple plot"),
  objectives = objectives,
  sequence = rlearnxr_learning_stages(),
  assessment = "Use the method-specific claim, evidence, limitation, repair, and transfer criteria.",
  instructor_materials = materials,
  accessibility_alternative = "semantic table and keyboard path",
  extension_activities = c("change one feature", "document a validity or privacy limitation")
)

build_learning_analytics <- function() {
  lesson_dir <- file.path(root, "examples", "learning-analytics")
  input_file <- "data/learning_events.csv"
  events <- read.csv(file.path(lesson_dir, input_file), stringsAsFactors = FALSE)
  lesson <- lesson_from_data(
    events, analysis = "data_view",
    dimensions = c("revision_count", "transfer_score", "hint_rate"),
    id_column = "event_id", grouping = "learner_id", time = "session",
    question = "How do revision activity, transfer performance, and hint use vary across repeated synthetic learner sessions?",
    intent = "explore", unit_of_analysis = "one synthetic learner-session summary",
    decision_context = "choosing a reversible instructional support or deciding that the evidence is insufficient",
    title = "Learning analytics event-to-construct evidence", id = "learning-analytics"
  )
  compile_lesson(lesson, lesson_dir, overwrite = TRUE)
  write_reference_data_license(
    lesson_dir,
    "Synthetic R-LearnXR repeated-session event summaries.",
    "CC0-style synthetic instructional data.",
    "No real learner records are included, and the IDs are fictional."
  )
  write_lesson_manifest(
    lesson_dir, lesson_id = "learning-analytics", title = lesson$title,
    evidence_file = "evidence.json", evidence_hash = lesson$evidence$analysis$artifact_hash,
    dataset_file = input_file,
    dataset_source = "Synthetic R-LearnXR repeated-session event summaries.",
    dataset_license = "CC0-style synthetic instructional data; no real learner records.",
    education = education(30L, c(
      "distinguish an event from a learning construct",
      "describe within- and between-learner patterns without ignoring repeated observations",
      "state a privacy, dependence, or construct-validity limitation"
    ), c("README.md", "../../docs/curriculum/learning-analytics-edm-lab.md")),
    overwrite = TRUE
  )
}

build_edm <- function() {
  lesson_dir <- file.path(root, "examples", "edm-patterns")
  input_file <- "data/edm_features.csv"
  features <- read.csv(file.path(lesson_dir, input_file), stringsAsFactors = FALSE)
  lesson <- lesson_from_data(
    features, analysis = "kmeans",
    dimensions = c("practice_minutes", "revision_count", "transfer_score"),
    id_column = "profile", clusters = 3L,
    question = "What tentative patterns appear after standardizing these synthetic learning features, and how sensitive is the interpretation?",
    intent = "cluster", unit_of_analysis = "one synthetic, de-identified learner profile",
    decision_context = "method critique and reversible support design, never automatic learner classification",
    title = "Educational data mining pattern evidence", id = "edm-patterns"
  )
  compile_lesson(lesson, lesson_dir, overwrite = TRUE)
  write_reference_data_license(
    lesson_dir,
    "Synthetic R-LearnXR feature profiles.",
    "CC0-style synthetic instructional data.",
    "No real learner records are included, and profiles must not be used for learner classification."
  )
  write_lesson_manifest(
    lesson_dir, lesson_id = "edm-patterns", title = lesson$title,
    evidence_file = "evidence.json", evidence_hash = lesson$evidence$analysis$artifact_hash,
    dataset_file = input_file,
    dataset_source = "Synthetic R-LearnXR feature profiles.",
    dataset_license = "CC0-style synthetic instructional data; no real learner records.",
    education = education(30L, c(
      "explain why scale, k, seed, and multiple starts matter for k-means",
      "use centroid distance as descriptive evidence",
      "state a stability, fairness, or validity limitation"
    ), c("README.md", "../../docs/curriculum/learning-analytics-edm-lab.md")),
    overwrite = TRUE
  )
}

build_learning_analytics()
build_edm()
cat("Built question-first Learning Analytics and EDM reference lessons.\n")
