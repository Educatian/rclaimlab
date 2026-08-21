test_that("data profiling makes fit and privacy risks inspectable", {
  data <- data.frame(
    learner_id = c("a", "b", "c", "d"),
    score = c(1, 2, NA, 4),
    time = c(4, 3, 2, 1),
    group = c("x", "x", "y", "y"),
    stringsAsFactors = FALSE
  )
  profile <- profile_learning_data(data)
  expect_s3_class(profile, "rlearnxr_data_profile")
  expect_equal(profile$rows, 4)
  expect_true(profile$columns$possible_identifier[profile$columns$column == "learner_id"])
  expect_match(paste(profile$warnings, collapse = " "), "Missing values")
  expect_match(paste(profile$warnings, collapse = " "), "identifiers")
  expect_true(any(profile$recommendations$available))
  expect_equal(as.data.frame(profile), profile$columns)
  expect_equal(summary(profile)$missing_cells, 1)
  expect_output(print(profile), "rlearnxr_data_profile")
})

test_that("outcomes produce transparent regression recommendations", {
  binary <- transform(iris, passed = rep(c("no", "yes"), length.out = nrow(iris)))
  glm_recommendations <- recommend_lesson_analysis(binary, outcome = "passed")
  expect_true(glm_recommendations$available[glm_recommendations$analysis == "glm"])
  expect_true(glm_recommendations$recommended[glm_recommendations$analysis == "glm"])

  lm_recommendations <- recommend_lesson_analysis(mtcars, outcome = "mpg")
  expect_true(lm_recommendations$available[lm_recommendations$analysis == "lm"])
  expect_true(lm_recommendations$recommended[lm_recommendations$analysis == "lm"])
})

test_that("lesson_from_data builds the complete learning contract", {
  lesson <- lesson_from_data(
    iris[1:20, ], analysis = "prcomp",
    dimensions = names(iris)[1:4], title = "Iris learner data"
  )
  expect_s3_class(lesson, "rlearnxr_lesson")
  expect_equal(vapply(lesson$tasks, `[[`, character(1), "type"),
               c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce"))
  expect_equal(lesson$evidence$metadata$wizard$analysis, "prcomp")
  expect_equal(lesson$evidence$metadata$wizard$original_rows, 20)
  expect_length(lesson$evidence$metadata$wizard$generated_r_code, 4)
  expect_true(validate_lesson_spec(lesson))
  expect_true(validate_rlearnxr_evidence(lesson$evidence))

  output <- tempfile("wizard-build-")
  build <- compile_lesson(lesson, output)
  expect_s3_class(build, "rlearnxr_build")
  expect_true(file.exists(file.path(output, "scene", "index.html")))
  expect_true(all(build$checks$status != "FAIL"))
})

test_that("all supported wizard adapters create evidence", {
  binary <- transform(iris[1:30, ], passed = rep(c("no", "yes"), 15))
  lessons <- list(
    data_view = lesson_from_data(iris[1:20, ], "data_view", dimensions = names(iris)[1:3]),
    lm = lesson_from_data(mtcars, "lm", dimensions = c("wt", "hp"), outcome = "mpg"),
    glm = lesson_from_data(binary, "glm", dimensions = c("Sepal.Length", "Petal.Length"), outcome = "passed"),
    kmeans = lesson_from_data(iris[1:20, ], "kmeans", dimensions = names(iris)[1:3], clusters = 3)
  )
  expect_equal(vapply(lessons, function(value) value$evidence$analysis$engine, character(1)),
               c(data_view = "data.frame", lm = "lm", glm = "glm", kmeans = "kmeans"))
})

test_that("missingness and invalid role decisions fail clearly", {
  missing <- data.frame(x = c(1, NA, 3), y = 3:1, z = 4:6)
  expect_error(lesson_from_data(missing, "data_view", dimensions = c("x", "y")), "missing values")
  complete <- lesson_from_data(missing, "data_view", dimensions = c("x", "y"), na_action = "complete")
  expect_equal(complete$evidence$metadata$wizard$compiled_rows, 2)
  expect_equal(complete$evidence$metadata$wizard$omitted_source_rows, 2)
  expect_error(lesson_from_data(iris, "lm", dimensions = "Sepal.Length"), "outcome")
  duplicate_ids <- transform(iris[1:4, ], label = "same")
  expect_error(lesson_from_data(duplicate_ids, "data_view", dimensions = names(iris)[1:2], id_column = "label"), "unique")
})

test_that("Lesson Wizard remains an optional Shiny surface", {
  expect_true(is.function(run_lesson_wizard))
  skip_if_not_installed("shiny")
  app <- rlearnxr:::build_lesson_wizard_app(data = iris[1:10, ])
  expect_s3_class(app, "shiny.appobj")
  expect_true(is.function(app$serverFuncSource))
})
