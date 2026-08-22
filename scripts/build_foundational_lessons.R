root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "load_rclaimlab_source.R"), chdir = FALSE)

build_foundational_lesson <- function(id, title, data, analysis, question, intent,
                                      concepts, objectives, dimensions = NULL,
                                      outcome = NULL, grouping = NULL, minutes = 20L,
                                      bootstrap_times = 1000L) {
  lesson_dir <- file.path(root, "examples", id)
  data_dir <- file.path(lesson_dir, "data")
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  input_file <- "data/source.csv"
  utils::write.csv(data, file.path(lesson_dir, input_file), row.names = FALSE)
  lesson <- lesson_from_data(
    data, analysis = analysis, dimensions = dimensions, outcome = outcome,
    grouping = grouping, question = question, intent = intent,
    unit_of_analysis = "one observation in a built-in R teaching dataset",
    decision_context = "statistical reasoning practice, not a causal or population claim",
    title = title, id = id, bootstrap_times = bootstrap_times
  )
  compile_lesson(lesson, lesson_dir, overwrite = TRUE)
  write_reference_data_license(
    lesson_dir,
    "Derived from a built-in R teaching dataset by scripts/build_foundational_lessons.R.",
    "R distribution licensing and attribution terms apply; see the R COPYING files."
  )
  write_lesson_manifest(
    lesson_dir, lesson_id = id, title = title,
    evidence_file = "evidence.json", evidence_hash = lesson$evidence$analysis$artifact_hash,
    dataset_file = input_file,
    dataset_source = "Built-in R teaching data generated deterministically by the repository build script.",
    dataset_license = "R distribution licensing and attribution terms apply; see the R COPYING files.",
    education = list(
      audience = "introductory statistics and data-science learners",
      estimated_minutes = as.integer(minutes),
      prerequisites = c("read a data table", "identify variables and observations"),
      objectives = objectives,
      sequence = rclaimlab_learning_stages(),
      assessment = "Use the method-specific claim, evidence, limitation, repair, and transfer criteria.",
      instructor_materials = c("README.md", "../../docs/curriculum/statistics-modules.md"),
      accessibility_alternative = "semantic table and keyboard path",
      extension_activities = c("change one analytical choice", "compare the resulting receipt")
    ),
    overwrite = TRUE
  )
}

cars <- mtcars
cars$transmission <- factor(cars$am, labels = c("automatic", "manual"))
cars$cylinder_group <- factor(cars$cyl)

build_foundational_lesson(
  "statistics-distribution", "Describe a distribution with linked evidence", cars,
  "describe", "What is typical fuel efficiency, how variable is it, and which observations shape that description?",
  "describe", c("center", "spread", "distribution", "outliers"),
  c("describe center and spread together", "link a distribution claim to an observation", "state the sample boundary"),
  dimensions = "mpg", minutes = 15L
)
build_foundational_lesson(
  "statistics-association", "Reason about correlation with paired evidence", cars,
  "correlation", "How are vehicle weight and fuel efficiency associated, and which paired observations constrain that claim?",
  "explore", c("scatterplot", "correlation", "form", "outliers"),
  c("interpret direction and strength", "inspect paired evidence", "separate association from causation"),
  dimensions = c("wt", "mpg"), minutes = 20L
)
build_foundational_lesson(
  "statistics-bootstrap", "See sampling variability through bootstrap evidence", cars,
  "bootstrap", "How stable is the observed mean fuel efficiency under resampling, and what uncertainty remains?",
  "infer", c("sampling variability", "bootstrap", "confidence interval"),
  c("interpret a bootstrap distribution", "read an interval without certainty language", "state the sample and resampling boundary"),
  dimensions = "mpg", minutes = 20L, bootstrap_times = 200L
)
build_foundational_lesson(
  "statistics-groups", "Compare groups with analysis-of-variance evidence", cars,
  "aov", "How does fuel efficiency vary across cylinder groups, and what does the omnibus comparison leave unresolved?",
  "compare", c("group means", "within-group variation", "ANOVA", "omnibus test"),
  c("compare group and within-group variation", "interpret the omnibus test", "avoid unsupported pairwise or causal claims"),
  outcome = "mpg", grouping = "cylinder_group", minutes = 25L
)

flowers <- iris
flowers$width_band <- cut(flowers$Sepal.Width, breaks = 3L, labels = c("narrow", "middle", "wide"))
build_foundational_lesson(
  "statistics-categories", "Inspect categorical association cell by cell", flowers,
  "chi_square", "Are species and sepal-width band associated, and which observed-versus-expected cells support the conclusion?",
  "compare", c("contingency table", "expected count", "chi-square", "standardized residual"),
  c("compare observed and expected counts", "identify influential cells", "state association without causal language"),
  outcome = "Species", grouping = "width_band", minutes = 25L
)

cat("Built foundational statistics reference lessons.\n")
