test_that("foundational statistics adapters preserve observations and test evidence", {
  numeric_evidence <- as_rlearnxr_evidence(mtcars$mpg, variable = "mpg")
  expect_equal(numeric_evidence$analysis$engine, "numeric_summary")
  expect_equal(numeric_evidence$metadata$summary$mean, mean(mtcars$mpg))
  expect_true(all(c("mpg", "centered_value", "percentile") %in% numeric_evidence$dimensions$label))

  count_evidence <- as_rlearnxr_evidence(table(iris$Species))
  expect_equal(count_evidence$analysis$engine, "table")
  expect_equal(sum(as.data.frame(count_evidence)$count), nrow(iris))

  paired <- mtcars[1:12, ]
  correlation <- stats::cor.test(paired$wt, paired$mpg)
  correlation_evidence <- as_rlearnxr_evidence(
    correlation, data = paired, x_column = "wt", y_column = "mpg"
  )
  expect_equal(correlation_evidence$analysis$engine, "cor.test")
  expect_equal(correlation_evidence$metadata$test$p_value, correlation$p.value)
  expect_error(as_rlearnxr_evidence(correlation), "requires data")

  groups <- transform(mtcars, transmission = factor(am, labels = c("automatic", "manual")))
  comparison <- stats::t.test(mpg ~ transmission, data = groups)
  comparison_evidence <- as_rlearnxr_evidence(
    comparison, data = groups, x_column = "mpg", group = "transmission"
  )
  expect_equal(comparison_evidence$analysis$engine, "t.test")
  expect_true(all(c("value", "centered_value", "comparison") %in% comparison_evidence$dimensions$label))

  contingency <- table(iris$Species, cut(iris$Sepal.Width, 2))
  chi <- suppressWarnings(stats::chisq.test(contingency))
  chi_evidence <- as_rlearnxr_evidence(chi)
  expect_equal(chi_evidence$analysis$engine, "chisq.test")
  expect_true(all(c("count", "expected_count", "standardized_residual") %in% chi_evidence$dimensions$label))
})

test_that("ANOVA and bootstrap have explicit contracts instead of silent fallbacks", {
  fit <- stats::aov(mpg ~ factor(cyl), data = mtcars)
  evidence <- as_rlearnxr_evidence(fit)
  expect_equal(evidence$analysis$engine, "aov")
  expect_true("anova_table" %in% names(evidence$metadata))
  expect_true(all(c("observed", "group_mean", "residual") %in% evidence$dimensions$label))

  first <- bootstrap_mean(mtcars$mpg, times = 40L, seed = 18L)
  second <- bootstrap_mean(mtcars$mpg, times = 40L, seed = 18L)
  expect_equal(first$estimates, second$estimates)
  bootstrap_evidence <- as_rlearnxr_evidence(first)
  expect_equal(bootstrap_evidence$analysis$engine, "bootstrap_mean")
  expect_equal(bootstrap_evidence$metadata$times, 40L)
  expect_error(bootstrap_mean(1, times = 40), "at least two")
  expect_error(bootstrap_mean(1:3, times = 10), "greater than or equal")
  expect_error(bootstrap_mean(1:3, seed = c(1, 2)), "seed")
  expect_error(as_rlearnxr_evidence(c(1, Inf)), "finite")
  expect_error(as_rlearnxr_evidence(as.table(c(0, 0))), "positive total")
  expect_error(as_rlearnxr_evidence(as.table(c(3, -1))), "non-negative")
})

test_that("foundational hypothesis-test adapters reject ambiguous inputs", {
  paired <- data.frame(x = 1:2, y = 2:3)
  correlation <- stats::cor.test(mtcars$wt, mtcars$mpg)
  expect_error(
    as_rlearnxr_evidence(correlation, data = paired,
                         x_column = "x", y_column = "y"),
    "three complete"
  )

  comparison <- transform(mtcars, transmission = factor(am))
  two_sample <- stats::t.test(mpg ~ transmission, data = comparison)
  expect_error(
    as_rlearnxr_evidence(two_sample, data = transform(comparison, mpg = as.character(mpg)),
                         x_column = "mpg", group = "transmission"),
    "numeric x_column"
  )
  expect_error(
    as_rlearnxr_evidence(two_sample, data = comparison[1:2, ],
                         x_column = "mpg", group = "transmission"),
    "three complete"
  )
  expect_error(
    as_rlearnxr_evidence(two_sample, data = transform(comparison, transmission = factor(cyl)),
                         x_column = "mpg", group = "transmission"),
    "exactly two levels"
  )

  one_sample <- stats::t.test(mtcars$mpg, mu = 20)
  one_sample_evidence <- as_rlearnxr_evidence(
    one_sample, data = mtcars, x_column = "mpg", labels = rep("duplicate", nrow(mtcars))
  )
  expect_equal(one_sample_evidence$analysis$engine, "t.test")
  expect_equal(one_sample_evidence$observations$label[[1]], "observation-0001")
  expect_error(
    as_rlearnxr_evidence(stats::wilcox.test(mtcars$mpg)),
    "unsupported htest"
  )
})

test_that("the wizard compiles foundational methods with runnable source", {
  comparison_data <- transform(mtcars, transmission = factor(am, labels = c("automatic", "manual")))
  category_data <- transform(iris, width_band = cut(Sepal.Width, 2), species = Species)
  lessons <- list(
    describe = lesson_from_data(
      mtcars, "describe", dimensions = "mpg", question = "What is typical fuel efficiency?", intent = "describe"
    ),
    correlation = lesson_from_data(
      mtcars, "correlation", dimensions = c("wt", "mpg"), question = "How are weight and mileage paired?", intent = "explore"
    ),
    bootstrap = lesson_from_data(
      mtcars, "bootstrap", dimensions = "mpg", question = "How stable is the sample mean?", intent = "infer"
    ),
    t_test = lesson_from_data(
      comparison_data, "t_test", outcome = "mpg", grouping = "transmission",
      question = "How does mileage differ by transmission?", intent = "compare"
    ),
    aov = lesson_from_data(
      mtcars, "aov", outcome = "mpg", grouping = "cyl",
      question = "How does mileage vary across cylinder groups?", intent = "compare"
    ),
    chi_square = lesson_from_data(
      category_data, "chi_square", outcome = "species", grouping = "width_band",
      question = "Are species and width band associated?", intent = "compare"
    )
  )
  expect_equal(
    vapply(lessons, function(value) value$evidence$analysis$engine, character(1)),
    c(describe = "numeric_summary", correlation = "cor.test", bootstrap = "bootstrap_mean",
      t_test = "t.test", aov = "aov", chi_square = "chisq.test")
  )
  expect_error(
    lesson_from_data(
      mtcars, "bootstrap", dimensions = "mpg",
      question = "How stable is the mean?", intent = "infer", bootstrap_times = 10L
    ),
    "bootstrap_times"
  )
  source_data <- list(
    describe = mtcars, correlation = mtcars, bootstrap = mtcars,
    t_test = comparison_data, aov = mtcars, chi_square = category_data
  )
  for (name in names(lessons)) {
    source_env <- new.env(parent = environment(as_rlearnxr_evidence))
    source_env$learner_data <- source_data[[name]]
    eval(parse(text = lessons[[name]]$evidence$metadata$wizard$generated_r_code), envir = source_env)
    expect_s3_class(source_env$evidence, "rlearnxr_evidence")
    expect_equal(as.data.frame(source_env$evidence), as.data.frame(lessons[[name]]$evidence), tolerance = 1e-10, info = name)
  }
})

test_that("learning events aggregate locally with a reviewable recipe", {
  events <- data.frame(
    learner = c("a", "a", "b", "b", "b"),
    event = c("open", "submit", "open", "hint", "submit"),
    score = c(0, 1, 0, 0, 1), duration = c(2, 8, 3, 4, 9),
    time = as.POSIXct("2026-01-01", tz = "UTC") + c(0, 20, 2, 8, 30),
    course = "course-1", stringsAsFactors = FALSE
  )
  features <- prepare_learning_events(
    events, learner = "learner", event = "event", outcome = "score",
    time = "time", duration = "duration", grouping = "course"
  )
  expect_s3_class(features, "rlearnxr_learning_features")
  expect_equal(features$event_count, c(2, 3))
  expect_equal(features$outcome_last, c(1, 1))
  expect_equal(features$active_span, c(20, 28))
  expect_equal(attr(features, "rlearnxr_recipe")$source_rows, 5)
  expect_output(print(features), "5 events")
  expect_error(prepare_learning_events(transform(events, learner = NA), "learner"), "complete")
})

test_that("concept registry separates tested scope from planned scope", {
  registry <- rlearnxr_concept_registry()
  expect_equal(anyDuplicated(registry$concept_id), 0L)
  expect_true(all(c("tested", "planned") %in% registry$status))
  expect_equal(registry$status[registry$concept_id == "plot2d-representation"], "tested")
  expect_equal(registry$status[registry$concept_id == "longitudinal-multilevel"], "planned")
})
