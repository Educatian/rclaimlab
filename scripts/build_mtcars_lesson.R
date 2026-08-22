root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "load_rclaimlab_source.R"), chdir = FALSE)

lesson_dir <- file.path(root, "examples", "mtcars-efficiency")
dir.create(file.path(lesson_dir, "data"), recursive = TRUE, showWarnings = FALSE)
cars <- mtcars
set.seed(2026)
cars$label <- rownames(cars)
utils::write.csv(cars, file.path(lesson_dir, "data", "mtcars_efficiency_source.csv"), row.names = FALSE)
lesson <- lesson_from_data(
  cars, analysis = "lm", dimensions = c("hp", "wt"), outcome = "mpg", id_column = "label",
  question = "How are horsepower and vehicle weight associated with fuel efficiency, and where does the linear model fit poorly?",
  intent = "explain", unit_of_analysis = "one vehicle model in the built-in mtcars dataset",
  decision_context = "learning to critique an association model, not making a causal vehicle-design claim",
  title = "Vehicle efficiency model evidence", id = "mtcars-efficiency"
)
compile_lesson(lesson, lesson_dir, overwrite = TRUE)
write_reference_data_license(
  lesson_dir,
  "The built-in mtcars dataset distributed with R.",
  "R distribution licensing and attribution terms apply; see the R COPYING files."
)
write_lesson_manifest(
  lesson_dir, lesson_id = "mtcars-efficiency", title = "Vehicle efficiency data space",
  evidence_file = "evidence.json", evidence_hash = lesson$evidence$analysis$artifact_hash,
  dataset_file = "data/mtcars_efficiency_source.csv",
  dataset_source = "Derived from the built-in mtcars dataset distributed with R.",
  dataset_license = "R distribution licensing and attribution terms apply; see the R COPYING files.",
  education = list(
    audience = "introductory data-science learners",
    estimated_minutes = 15L,
    prerequisites = c("mean and standard deviation", "read a scatterplot"),
    objectives = c(
      "interpret standardized mpg, horsepower, and weight coordinates",
      "distinguish association from a causal claim",
      "communicate one multivariate vehicle comparison with a limitation"
    ),
    sequence = c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce"),
    assessment = "Use the reusable R-ClaimLab claim-evidence-limitation-transfer rubric.",
    instructor_materials = c("README.md"),
    accessibility_alternative = "semantic table and keyboard path",
    extension_activities = c("compare scaling choices", "fit a simple regression")
  ),
  overwrite = TRUE
)
cat("Built mtcars efficiency reference lesson.\n")
