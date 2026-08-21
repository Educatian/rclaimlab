test_that("data profiling makes fit and privacy risks inspectable", {
  data <- data.frame(
    learner_id = c("a", "b", "c", "d"),
    score = c(1, 2, NA, 4),
    engagement = c(0.2, 0.5, 0.4, 0.8),
    time = c(4, 3, 2, 1),
    group = c("x", "x", "y", "y"),
    stringsAsFactors = FALSE
  )
  profile <- profile_learning_data(data, intent = "explore", grouping = "group", time = "time")
  expect_s3_class(profile, "rlearnxr_data_profile")
  expect_equal(profile$rows, 4)
  expect_true(profile$columns$possible_identifier[profile$columns$column == "learner_id"])
  expect_match(paste(profile$warnings, collapse = " "), "Missing values")
  expect_match(paste(profile$warnings, collapse = " "), "identifiers")
  expect_match(paste(profile$warnings, collapse = " "), "dependence")
  expect_equal(profile$columns$role[profile$columns$column == "group"], "grouping")
  expect_true(any(profile$recommendations$available))
  expect_equal(as.data.frame(profile), profile$columns)
  expect_equal(summary(profile)$missing_cells, 1)
  expect_output(print(profile), "rlearnxr_data_profile")
})

test_that("outcomes produce transparent regression recommendations", {
  binary <- transform(iris, passed = rep(c("no", "yes"), length.out = nrow(iris)))
  glm_recommendations <- recommend_lesson_analysis(binary, outcome = "passed", intent = "classify")
  expect_true(glm_recommendations$available[glm_recommendations$analysis == "glm"])
  expect_true(glm_recommendations$recommended[glm_recommendations$analysis == "glm"])

  lm_recommendations <- recommend_lesson_analysis(mtcars, outcome = "mpg", intent = "explain")
  expect_true(lm_recommendations$available[lm_recommendations$analysis == "lm"])
  expect_true(lm_recommendations$recommended[lm_recommendations$analysis == "lm"])
})

test_that("recommendation starts from intent and respects dependence", {
  expect_equal(
    recommend_lesson_analysis(iris, intent = "explore")$analysis[
      recommend_lesson_analysis(iris, intent = "explore")$recommended
    ],
    "data_view"
  )
  expect_equal(
    recommend_lesson_analysis(iris, intent = "reduce")$analysis[
      recommend_lesson_analysis(iris, intent = "reduce")$recommended
    ],
    "prcomp"
  )
  repeated <- transform(mtcars, learner_id = rep(letters[1:8], length.out = nrow(mtcars)))
  recommendation <- recommend_lesson_analysis(
    repeated, outcome = "mpg", intent = "explain", grouping = "learner_id"
  )
  expect_true(recommendation$available[recommendation$analysis == "lm"])
  expect_false(recommendation$recommended[recommendation$analysis == "lm"])
  expect_true(recommendation$recommended[recommendation$analysis == "data_view"])
  expect_match(recommendation$caution[recommendation$analysis == "lm"], "grouped")
})

test_that("lesson_from_data builds the complete learning contract", {
  lesson <- lesson_from_data(
    iris[1:20, ], analysis = "prcomp",
    dimensions = names(iris)[1:4], title = "Iris learner data",
    question = "Which measurements vary together, and which flowers have contrasting PCA scores?",
    intent = "reduce", unit_of_analysis = "one iris flower"
  )
  expect_s3_class(lesson, "rlearnxr_lesson")
  expect_equal(vapply(lesson$tasks, `[[`, character(1), "type"),
               c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce"))
  expect_equal(lesson$evidence$metadata$wizard$analysis, "prcomp")
  expect_equal(lesson$evidence$metadata$wizard$original_rows, 20)
  expect_gte(length(lesson$evidence$metadata$wizard$generated_r_code), 8)
  expect_match(paste(lesson$evidence$metadata$wizard$generated_r_code, collapse = "\n"), "complete.cases", fixed = TRUE)
  expect_equal(lesson$evidence$metadata$pedagogy$analysis, "prcomp")
  expect_match(lesson$tasks[[5]]$prompt, "component")
  expect_named(lesson$tasks[[5]]$criteria, c("point", "component", "direction", "limitation"))
  expect_true(any(vapply(
    lesson$evidence$metadata$pedagogy$diagnostics,
    function(item) identical(item$id, "scaling"), logical(1)
  )))
  browser_contract <- rlearnxr:::lesson_scene_contract(lesson)
  expect_true(all(c("observation_id", "label", "PC1", "PC2", "PC3") %in% browser_contract$evidence_table$columns))
  expect_equal(length(browser_contract$evidence_table$rows), 20)
  explanations <- vapply(browser_contract$command_explanations, `[[`, character(1), "explanation")
  expect_match(explanations[[4]], "retained source-row")
  expect_match(explanations[[5]], "Creates the analysis data")
  expect_true(validate_lesson_spec(lesson))
  expect_true(validate_rlearnxr_evidence(lesson$evidence))

  output <- tempfile("wizard-build-")
  build <- compile_lesson(lesson, output)
  expect_s3_class(build, "rlearnxr_build")
  expect_true(file.exists(file.path(output, "scene", "index.html")))
  expect_true(all(build$checks$status != "FAIL"))
  html <- paste(readLines(file.path(output, "scene", "index.html"), warn = FALSE), collapse = "\n")
  expect_match(html, "Which measurements vary together", fixed = TRUE)
  expect_match(html, "rlearnxr-browser-contract-1", fixed = TRUE)
  expect_match(html, '"component":"Names a principal component"', fixed = TRUE)
  expect_match(html, 'id="compiled-evidence-body"', fixed = TRUE)
  qmd <- paste(readLines(file.path(output, "index.qmd"), warn = FALSE), collapse = "\n")
  expect_match(qmd, "Unit of analysis", fixed = TRUE)
  expect_match(qmd, "PCA summarizes variance", fixed = TRUE)
})

test_that("all supported wizard adapters create evidence", {
  binary <- transform(iris[1:30, ], passed = rep(c("no", "yes"), 15))
  lessons <- list(
    data_view = lesson_from_data(
      iris[1:20, ], "data_view", dimensions = names(iris)[1:3],
      question = "What descriptive patterns appear across these measurements?", intent = "explore"
    ),
    lm = lesson_from_data(
      mtcars, "lm", dimensions = c("wt", "hp"), outcome = "mpg",
      question = "How are weight and horsepower associated with fuel efficiency?", intent = "explain"
    ),
    glm = lesson_from_data(
      binary, "glm", dimensions = c("Sepal.Length", "Petal.Length"), outcome = "passed",
      question = "How do the measurements relate to the probability of passing?", intent = "classify"
    ),
    kmeans = lesson_from_data(
      iris[1:20, ], "kmeans", dimensions = names(iris)[1:3], clusters = 3,
      question = "What tentative groups appear in the standardized measurements?", intent = "cluster"
    )
  )
  expect_equal(vapply(lessons, function(value) value$evidence$analysis$engine, character(1)),
               c(data_view = "data.frame", lm = "lm", glm = "glm", kmeans = "kmeans"))
  expect_true(all(c("fitted", "residual", "interval_low", "interval_high") %in%
                    rlearnxr:::lesson_scene_contract(lessons$lm)$evidence_table$columns))
  expect_true(all(c("predicted_probability", "predicted_class") %in%
                    rlearnxr:::lesson_scene_contract(lessons$glm)$evidence_table$columns))
  expect_true(all(c("cluster", "distance_to_centroid") %in%
                    rlearnxr:::lesson_scene_contract(lessons$kmeans)$evidence_table$columns))

  source_data <- list(data_view = iris[1:20, ], lm = mtcars, glm = binary, kmeans = iris[1:20, ])
  for (name in names(lessons)) {
    source_env <- new.env(parent = environment(as_rlearnxr_evidence))
    source_env$learner_data <- source_data[[name]]
    eval(parse(text = lessons[[name]]$evidence$metadata$wizard$generated_r_code), envir = source_env)
    expect_s3_class(source_env$evidence, "rlearnxr_evidence")
    expect_equal(as.data.frame(source_env$evidence), as.data.frame(lessons[[name]]$evidence), tolerance = 1e-10)
  }
})

test_that("missingness and invalid role decisions fail clearly", {
  missing <- data.frame(x = c(1, NA, 3), y = 3:1, z = 4:6)
  expect_error(lesson_from_data(missing, "data_view", dimensions = c("x", "y")), "question")
  expect_error(lesson_from_data(
    missing, "data_view", dimensions = c("x", "y"),
    question = "How do x and y vary?"
  ), "missing values")
  complete <- lesson_from_data(
    missing, "data_view", dimensions = c("x", "y"), na_action = "complete",
    question = "How do x and y vary?"
  )
  expect_equal(complete$evidence$metadata$wizard$compiled_rows, 2)
  expect_equal(complete$evidence$metadata$wizard$omitted_source_rows, 2)
  expect_error(lesson_from_data(
    iris, "lm", dimensions = "Sepal.Length",
    question = "What explains the outcome?", intent = "explain"
  ), "outcome")
  duplicate_ids <- transform(iris[1:4, ], label = "same")
  expect_error(lesson_from_data(
    duplicate_ids, "data_view", dimensions = names(iris)[1:2], id_column = "label",
    question = "How do these measurements vary?"
  ), "unique")
})

test_that("Lesson Wizard remains an optional Shiny surface", {
  expect_true(is.function(run_lesson_wizard))
  skip_if_not_installed("shiny")
  app <- rlearnxr:::build_lesson_wizard_app(data = iris[1:10, ])
  expect_s3_class(app, "shiny.appobj")
  expect_true(is.function(app$serverFuncSource))
})
