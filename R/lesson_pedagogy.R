learning_intents <- function() {
  c(
    explore = "Describe and compare observations",
    describe = "Summarize one numeric variable",
    compare = "Compare outcomes across groups",
    infer = "Quantify sampling uncertainty",
    reduce = "Summarize several variables",
    explain = "Explain variation in a numeric outcome",
    classify = "Estimate a two-level outcome",
    cluster = "Explore possible groups"
  )
}

normalize_learning_context <- function(data, question, intent = "explore",
                                       unit_of_analysis = "one row in the supplied data",
                                       outcome = NULL, id_column = NULL,
                                       grouping = NULL, time = NULL,
                                       decision_context = "learning and interpretation") {
  assert_scalar_text(question, "question")
  intent <- match.arg(intent, names(learning_intents()))
  assert_scalar_text(unit_of_analysis, "unit_of_analysis")
  assert_scalar_text(decision_context, "decision_context")
  roles <- list(outcome = outcome, id = id_column, grouping = grouping, time = time)
  for (role in names(roles)) {
    value <- roles[[role]]
    if (!is.null(value) && (length(value) != 1L || is.na(value) || !(value %in% names(data)))) {
      stop(role, " must name one column in data", call. = FALSE)
    }
  }
  list(
    question = trimws(question),
    intent = intent,
    intent_label = unname(learning_intents()[[intent]]),
    unit_of_analysis = trimws(unit_of_analysis),
    outcome = outcome,
    id_column = id_column,
    grouping = grouping,
    time = time,
    decision_context = trimws(decision_context),
    dependence_warning = !is.null(grouping) || !is.null(time)
  )
}

analysis_teaching_contract <- function(analysis, context, evidence, model,
                                       prepared, dimensions, outcome, seed,
                                       clusters = NULL) {
  diagnostic <- function(id, label, value, interpretation, status = "review") {
    list(id = id, label = label, value = as.character(value), status = status,
         interpretation = interpretation)
  }
  cautions <- character()
  misconceptions <- character()
  diagnostics <- list()

  if (analysis == "describe") {
    summary_values <- evidence$metadata$summary
    diagnostics <- list(
      diagnostic("sample-size", "Retained observations", summary_values$n, "All summaries refer to these complete observations.", "ready"),
      diagnostic("center", "Mean / median", sprintf("%.3f / %.3f", summary_values$mean, summary_values$median), "Compare both when the distribution is skewed or has unusual values.", "review"),
      diagnostic("spread", "SD / IQR", sprintf("%.3f / %.3f", summary_values$sd, summary_values$iqr), "Standard deviation and IQR describe spread differently.", "review"),
      diagnostic("range", "Minimum / maximum", sprintf("%.3f / %.3f", summary_values$minimum, summary_values$maximum), "Inspect extremes before calling them errors or outliers.", "review")
    )
    cautions <- c("A sample summary does not establish a population value.", "Center and spread should be interpreted with the distribution shape.")
    misconceptions <- c("The mean is not necessarily a typical observed value, especially in a skewed distribution.")
  } else if (analysis == "correlation") {
    estimate <- unname(model$estimate)
    diagnostics <- list(
      diagnostic("correlation", "Correlation estimate", sprintf("%.3f", estimate), "The sign gives direction and the magnitude gives linear or monotonic association strength.", "review"),
      diagnostic("interval", "95% confidence interval", if (is.null(model$conf.int)) "not available" else paste(sprintf("%.3f", model$conf.int), collapse = " to "), "The interval represents uncertainty in the population association under the test assumptions.", "review"),
      diagnostic("pairs", "Complete pairs", nrow(prepared), "Each plotted pair contributes to the estimate.", "ready")
    )
    cautions <- c("Correlation does not establish causation.", "Outliers, nonlinear form, restricted range, and dependence can change the estimate.")
    misconceptions <- c("A correlation near zero does not rule out a nonlinear relationship.")
  } else if (analysis == "bootstrap") {
    diagnostics <- list(
      diagnostic("observed", "Observed sample mean", sprintf("%.3f", model$observed), "This is the statistic recomputed across resamples.", "ready"),
      diagnostic("resamples", "Bootstrap resamples", model$times, paste0("Seed ", seed, " makes the instructional resampling distribution reproducible."), "ready"),
      diagnostic("interval", "Percentile interval", paste(sprintf("%.3f", model$interval), collapse = " to "), "This interval summarizes bootstrap sampling variability for the mean.", "review")
    )
    cautions <- c("Bootstrap results inherit limitations of the observed sample and resampling rule.", "A 95% interval is not a 95% probability that this fixed interval contains the parameter.")
    misconceptions <- c("More resamples stabilize the simulation; they do not increase the original sample size.")
  } else if (analysis == "t_test") {
    diagnostics <- list(
      diagnostic("difference", "Estimated group means", paste(names(model$estimate), sprintf("%.3f", model$estimate), collapse = "; "), "Interpret the estimated difference with its direction and units.", "review"),
      diagnostic("interval", "95% difference interval", paste(sprintf("%.3f", model$conf.int), collapse = " to "), "The interval communicates uncertainty around the mean difference.", "review"),
      diagnostic("statistic", "t statistic / p-value", paste0(sprintf("%.3f", unname(model$statistic)), " / ", format.pval(model$p.value, digits = 3)), "A p-value is evidence against the null model, not the probability that the null is true.", "review")
    )
    cautions <- c("Statistical significance is not practical importance.", "The design and independence assumptions determine which population claim is justified.")
    misconceptions <- c("A non-significant result does not prove that the groups are identical.")
  } else if (analysis == "aov") {
    table <- evidence$metadata$anova_table
    diagnostics <- list(
      diagnostic("groups", "Compared groups", length(unique(prepared[[context$grouping]])), "The omnibus test compares variation between and within these groups.", "ready"),
      diagnostic("f-statistic", "Omnibus F statistic", sprintf("%.3f", table[["F value"]][[1]]), "A larger F indicates more between-group variation relative to within-group variation.", "review"),
      diagnostic("p-value", "Omnibus p-value", format.pval(table[["Pr(>F)"]][[1]], digits = 3), "The omnibus result does not identify which group pairs differ.", "review")
    )
    cautions <- c("A significant ANOVA does not identify the differing groups or establish causation.", "Inspect residual assumptions and use planned or multiplicity-aware follow-up comparisons.")
    misconceptions <- c("ANOVA is not simply several uncorrected t tests.")
  } else if (analysis == "chi_square") {
    expected <- as.numeric(model$expected)
    diagnostics <- list(
      diagnostic("cells", "Contingency cells", length(model$observed), "Observed and expected counts are linked cell by cell.", "ready"),
      diagnostic("expected", "Smallest expected count", sprintf("%.2f", min(expected)), "Small expected counts can make the chi-square approximation unreliable.", if (any(expected < 5)) "warning" else "ready"),
      diagnostic("statistic", "Chi-square / p-value", paste0(sprintf("%.3f", unname(model$statistic)), " / ", format.pval(model$p.value, digits = 3)), "Use standardized residuals to locate cells contributing to the omnibus association.", "review")
    )
    cautions <- c("Association between categorical variables does not establish causation.", "Expected-count assumptions and the sampling design must be checked.")
    misconceptions <- c("A significant chi-square result does not mean every cell differs meaningfully from expectation.")
  } else if (analysis == "data_view") {
    diagnostics <- list(
      diagnostic("rows", "Complete observations", nrow(prepared), "The evidence describes the retained rows only.", "ready"),
      diagnostic("dimensions", "Compared variables", paste(dimensions, collapse = ", "), "Variables remain on their original scales.", "review")
    )
    cautions <- c("Visible association is not evidence of causation.", "Different variable scales can dominate spatial distance.")
    misconceptions <- c("A point that looks distant is not automatically unusual in the original construct.")
  } else if (analysis == "prcomp") {
    variance <- (model$sdev ^ 2) / sum(model$sdev ^ 2)
    pc1_loading <- model$rotation[, 1]
    loading_name <- names(which.max(abs(pc1_loading)))[[1]]
    diagnostics <- list(
      diagnostic("pc1-variance", "PC1 variance explained", sprintf("%.1f%%", 100 * variance[[1]]), "This is variance summarized, not outcome importance.", "ready"),
      diagnostic("components", "Components retained in evidence", min(3L, length(variance)), "Interpret scores together with loadings and explained variance.", "review"),
      diagnostic("scaling", "Input scaling", "centered and standardized", "Scaling prevents large-unit variables from dominating PCA.", "ready"),
      diagnostic("pc1-loading", "Largest absolute PC1 loading", paste0(loading_name, " = ", sprintf("%.3f", pc1_loading[[loading_name]])), "The sign may reverse; interpret this variable together with the other loadings.", "review")
    )
    cautions <- c("Component signs are arbitrary and may reverse without changing the solution.", "PCA summarizes variance; it does not identify causes or latent constructs by itself.")
    misconceptions <- c("A high component score is not the same as a high value on every original variable.", "A loading describes a variable; a score describes an observation.")
  } else if (analysis == "lm") {
    fit_summary <- summary(model)
    cooks <- stats::cooks.distance(model)
    influence_cutoff <- 4 / max(1, stats::nobs(model))
    diagnostics <- list(
      diagnostic("r-squared", "R-squared", sprintf("%.3f", fit_summary$r.squared), "Report fit together with residual and uncertainty evidence.", "review"),
      diagnostic("residual", "Residual standard error", sprintf("%.3f", fit_summary$sigma), "Residuals show where observed outcomes differ from fitted values.", "review"),
      diagnostic("influence", "Largest Cook's distance", sprintf("%.3f", max(cooks, na.rm = TRUE)), paste0("Compare with the teaching flag 4/n = ", sprintf("%.3f", influence_cutoff), "; this is a review cue, not an automatic deletion rule."), "review"),
      diagnostic("interval", "Uncertainty representation", "95% fitted-mean interval", "An interval communicates uncertainty; it does not guarantee a future individual outcome.", "review"),
      diagnostic("linearity", "Residual-fitted correlation", sprintf("%.3f", evidence$metadata$diagnostics$residual_fitted_correlation), "A strong residual trend is a cue to inspect linearity and model form.", "review"),
      diagnostic("spread-pattern", "Absolute-residual/fitted correlation", sprintf("%.3f", evidence$metadata$diagnostics$absolute_residual_fitted_correlation), "A strong trend is a cue to inspect non-constant residual spread.", "review")
    )
    cautions <- c("Regression coefficients describe conditional association unless the design supports a causal claim.")
    misconceptions <- c("A fitted value is not the observed outcome.", "A small residual does not validate every model assumption.")
  } else if (analysis == "glm") {
    response <- model$model[[1]]
    event_level <- if (is.factor(response)) levels(response)[[2]] else "1"
    reference_level <- if (is.factor(response)) levels(response)[[1]] else "0"
    prevalence <- mean(as.numeric(response) - 1)
    classification <- evidence$metadata$classification
    diagnostics <- list(
      diagnostic("event", "Modeled event", event_level, "Probabilities refer to this event level.", "ready"),
      diagnostic("reference", "Reference level", reference_level, "Coefficients compare the modeled event with this level.", "ready"),
      diagnostic("prevalence", "Event prevalence", sprintf("%.1f%%", 100 * prevalence), "Compare predictions with the observed class balance.", "review"),
      diagnostic("threshold", "Instructional threshold", "0.50", "A threshold is a decision rule, not a natural boundary.", "review"),
      diagnostic("convergence", "Model convergence", isTRUE(model$converged), "Non-convergence invalidates probability interpretation.", if (isTRUE(model$converged)) "ready" else "warning"),
      diagnostic("accuracy", "Accuracy", sprintf("%.3f", classification$accuracy), "Compare accuracy with prevalence, sensitivity, and specificity.", "review"),
      diagnostic("sensitivity-specificity", "Sensitivity / specificity", paste(sprintf("%.3f", c(classification$sensitivity, classification$specificity)), collapse = " / "), "Threshold changes trade off missed events and false alarms.", "review"),
      diagnostic("brier", "Brier score", sprintf("%.3f", classification$brier_score), "This proper score evaluates probability error, not only thresholded classes.", "review")
    )
    cautions <- c("Predicted probability is not certainty.", "Classification thresholds should reflect consequences and class balance.")
    misconceptions <- c("The second factor level is the modeled event; alphabetical coding can change the interpretation.")
  } else if (analysis == "kmeans") {
    ratio <- if (is.finite(model$totss) && model$totss > 0) model$betweenss / model$totss else NA_real_
    diagnostics <- list(
      diagnostic("scaling", "Input scaling", "standardized", "K-means distances are computed after centering and scaling.", "ready"),
      diagnostic("cluster-size", "Cluster sizes", paste(model$size, collapse = ", "), "Very small clusters may be unstable or idiosyncratic.", "review"),
      diagnostic("separation", "Between-cluster variance ratio", sprintf("%.3f", ratio), "Use this as descriptive evidence, not proof of natural groups.", "review"),
      diagnostic("initialization", "Random starts", "25", paste0("Seed ", seed, " and multiple starts reduce initialization dependence."), "ready"),
      diagnostic("stability", "Sensitivity across k and seeds", sprintf("seed minimum %.3f; mean %.3f", evidence$metadata$stability$minimum, evidence$metadata$stability$mean), "Pairwise co-membership agreement is label-invariant across five additional seeds; still compare plausible k values.", "review")
    )
    cautions <- c("K-means always returns the requested number of clusters.", "Cluster labels are descriptive and should not be treated as learner identities.")
    misconceptions <- c("A cluster is not automatically a real population or an instructional diagnosis.")
  }

  if (isTRUE(context$dependence_warning)) {
    cautions <- c(cautions, paste0(
      "The data declare ",
      if (!is.null(context$grouping)) paste0("grouping by ", context$grouping) else "no grouping variable",
      if (!is.null(context$time)) paste0(" and time by ", context$time) else "",
      ". Core lm/glm adapters do not model this dependence; treat inferential results as instructional until an appropriate grouped or longitudinal model is used."
    ))
  }

  prompts <- method_task_prompts(analysis, context, dimensions, outcome)
  criteria <- method_task_criteria(analysis)
  outcomes <- method_learning_outcomes(analysis, context)
  list(
    analysis = analysis,
    question = context$question,
    context = context,
    diagnostics = diagnostics,
    cautions = unique(cautions),
    misconceptions = unique(misconceptions),
    prompts = prompts,
    criteria = criteria,
    outcomes = outcomes
  )
}

method_task_prompts <- function(analysis, context, dimensions, outcome) {
  unit <- context$unit_of_analysis
  question <- context$question
  common <- c(
    orient = paste0("State why ", unit, " is the unit of observation, identify each variable role, and restate the question: ", question),
    reproduce = "Verify the analysis source, seed, R and package versions, evidence hash, and retained-row decision before sharing the lesson."
  )
  specific <- switch(
    analysis,
    describe = c(
      predict = paste0("Predict the center, spread, and shape of ", dimensions[[1]], " before inspecting its distribution evidence."),
      run_r = "Run the numeric-summary adapter and inspect mean, median, SD, IQR, percentile, and histogram evidence.",
      explore = "Compare exact values, centered values, and percentiles in the table and 2D plot before using the 3D view.",
      explain = "Describe the distribution using one center, one spread, and one shape or unusual-value observation.",
      repair = "Check whether the selected center and spread match the distribution shape and retained observations.",
      transfer = "Apply the same center-spread-shape reasoning to a different part of the distribution."
    ),
    correlation = c(
      predict = paste0("Predict the direction and form of association between ", paste(dimensions, collapse = " and "), "."),
      run_r = "Run cor.test() and connect the estimate and interval to the complete paired observations.",
      explore = "Inspect paired values, the 2D form, and each observation's standardized association contribution.",
      explain = "State the correlation direction and magnitude, cite paired evidence, and state a non-causal limitation.",
      repair = "Check form, outliers, range, uncertainty, and dependence before revising the association claim.",
      transfer = "Test whether the same association interpretation holds for a different paired observation."
    ),
    bootstrap = c(
      predict = paste0("Predict how much bootstrap means for ", dimensions[[1]], " will vary around the observed sample mean."),
      run_r = "Resample with replacement using the recorded seed and construct the bootstrap distribution and percentile interval.",
      explore = "Compare bootstrap estimates, deviations, and percentiles across the table and 2D plot.",
      explain = "Explain what the bootstrap interval says about sampling variability and what it does not include.",
      repair = "Separate original sample size from number of resamples and revise any probability claim about the fixed interval.",
      transfer = "Compare a different resample estimate with the observed statistic and interval."
    ),
    t_test = c(
      predict = paste0("Predict the direction and practical size of the difference in ", outcome, " between the two groups."),
      run_r = "Run the two-sample t test and connect group outcomes to the estimated difference, interval, statistic, and p-value.",
      explore = "Inspect group-coded outcomes and within-group deviations before reading the omnibus test evidence.",
      explain = "Report the direction and interval for the mean difference, then state a design or practical-importance limitation.",
      repair = "Correct any claim that treats the p-value as the probability that the null hypothesis is true.",
      transfer = "Apply the group-comparison reasoning to a different observation without turning it into an individual causal claim."
    ),
    aov = c(
      predict = paste0("Predict how ", outcome, " may differ across the declared groups before running ANOVA."),
      run_r = "Run aov(), inspect between- and within-group variation, and connect each outcome to its fitted group mean and residual.",
      explore = "Compare observed outcomes, fitted group means, and residuals across representations.",
      explain = "Interpret the omnibus F evidence and state why it does not identify every differing pair or a causal effect.",
      repair = "Check residual assumptions and remove unsupported pairwise or causal conclusions.",
      transfer = "Apply observed-versus-group-mean reasoning to a different observation."
    ),
    chi_square = c(
      predict = "Predict which category combinations may appear more or less often than expected under independence.",
      run_r = "Build the contingency table, run chisq.test(), and connect observed counts, expected counts, and standardized residuals.",
      explore = "Compare cells in the semantic table and 2D plot, prioritizing large absolute standardized residuals.",
      explain = "Identify a contributing cell, compare observed with expected count, and state an association-not-causation limitation.",
      repair = "Check expected counts and remove claims that every cell or every individual follows the omnibus pattern.",
      transfer = "Apply observed-versus-expected reasoning to a different contingency cell."
    ),
    data_view = c(
      predict = paste0("Predict one descriptive pattern among ", paste(dimensions, collapse = ", "), " before inspecting the evidence."),
      run_r = "Run the visible R evidence transformation and confirm that row identities and selected variables remain linked.",
      explore = "Select one observation and compare its original-scale values across the semantic table, 2D view, and 3D scene.",
      explain = "Make a descriptive claim about the selected observation, cite a variable and direction, and state what the pattern cannot establish.",
      repair = "Check the exact value and scale, then remove any causal or population-level overclaim.",
      transfer = "Apply the same descriptive rule to a different observation and identify where the pattern changes."
    ),
    prcomp = c(
      predict = "Predict which original variables may vary together and which observations may separate before running PCA.",
      run_r = "Inspect centering and scaling, run PCA, and connect component scores to loadings and explained variance.",
      explore = "Select one observation and compare its component scores with the loading and variance evidence.",
      explain = "Explain the selected observation's component position, cite a component and direction, and state a PCA limitation.",
      repair = "Distinguish observation scores from variable loadings and verify the variance evidence before revising the claim.",
      transfer = "Compare a different observation on the same component and explain whether the interpretation transfers."
    ),
    lm = c(
      predict = paste0("Predict the direction of association between ", paste(dimensions, collapse = ", "), " and ", outcome, "."),
      run_r = "Inspect the model formula, run the linear model, and connect fitted values, residuals, intervals, and provenance.",
      explore = "Select one observation and compare its fitted value, residual, and interval evidence in the full compiled evidence table.",
      explain = "Explain the selected observation using its fitted value and residual, then state an uncertainty or causal limitation.",
      repair = "Check residual, influence, independence, and interval evidence before revising the association claim.",
      transfer = "Apply the fitted-versus-observed reasoning to a different observation and compare uncertainty."
    ),
    glm = c(
      predict = paste0("Predict how ", paste(dimensions, collapse = ", "), " may change the probability of the modeled ", outcome, " event."),
      run_r = "Verify the modeled event and reference level, run logistic regression, and inspect probability and threshold evidence.",
      explore = "Select one observation and compare its predicted probability and predicted class in the full compiled evidence table with the declared threshold.",
      explain = "Explain the selected probability, name the modeled event and threshold, and state why probability is not certainty.",
      repair = "Check event coding, class balance, threshold choice, and uncertainty before revising the classification claim.",
      transfer = "Apply the probability-and-threshold reasoning to a different observation and compare the decision."
    ),
    kmeans = c(
      predict = paste0("Predict a possible grouping pattern across standardized ", paste(dimensions, collapse = ", "), "."),
      run_r = "Inspect scaling, seed, requested k, and multiple random starts before creating cluster evidence.",
      explore = "Select one observation and inspect its cluster and distance-to-centroid in the full compiled evidence table.",
      explain = "Explain the selected cluster assignment using centroid distance and state a stability or interpretation limitation.",
      repair = "Check scaling, cluster size, initialization, and the requested k before revising the grouping claim.",
      transfer = "Compare a different observation's cluster and centroid distance without treating the label as an identity."
    )
  )
  c(orient = common[["orient"]], specific, reproduce = common[["reproduce"]])
}

method_task_criteria <- function(analysis) {
  explain <- switch(
    analysis,
    describe = c(point = "Names a selected observation", center = "Cites a center", spread = "Cites a spread", limitation = "States a sample or shape limitation"),
    correlation = c(point = "Names a paired observation", association = "Cites direction or magnitude", pair = "Cites paired evidence", limitation = "States a non-causal limitation"),
    bootstrap = c(point = "Names a resample", estimate = "Cites a bootstrap estimate", interval = "Interprets sampling variability or interval", limitation = "States a sample or interval limitation"),
    t_test = c(point = "Names an observation or group", difference = "Cites a mean difference or interval", inference = "Interprets test evidence correctly", limitation = "States a design or practical limitation"),
    aov = c(point = "Names an observation or group", variation = "Cites group mean, residual, or F evidence", omnibus = "Keeps the conclusion omnibus", limitation = "States an assumption or causal limitation"),
    chi_square = c(point = "Names a contingency cell", observed = "Cites observed and expected counts", residual = "Interprets a standardized residual", limitation = "States an assumption or causal limitation"),
    data_view = c(point = "Names the selected observation", axis = "Cites a displayed variable or axis", direction = "States the value or direction", limitation = "States a descriptive limitation"),
    prcomp = c(point = "Names the selected observation", component = "Names a principal component", direction = "States the component direction", limitation = "States a PCA limitation"),
    lm = c(point = "Names the selected observation", fitted = "Cites a fitted value", residual = "Interprets a residual or interval", limitation = "States an uncertainty or causal limitation"),
    glm = c(point = "Names the selected observation", probability = "Cites a predicted probability", threshold = "Names the event or threshold", limitation = "States that probability is not certainty"),
    kmeans = c(point = "Names the selected observation", cluster = "Names the assigned cluster", distance = "Cites centroid distance", limitation = "States a stability or interpretation limitation")
  )
  list(
    orient = c(meaning = "Defines the unit of observation and variable roles", question = "Connects the data to the stated question"),
    predict = c(prediction = "Records a falsifiable expectation before inspection"),
    run_r = c(execution = "Connects visible R source to the compiled artifact"),
    explore = c(selection = "Selects an observation using a stable evidence ID"),
    explain = explain,
    repair = c(revision = "Corrects the identified evidence or assumption problem"),
    transfer = c(point = "Uses a different observation", comparison = "Compares the method-specific evidence", limitation = "Keeps the interpretation within its evidence boundary"),
    reproduce = c(provenance = "Verifies source, seed, version, retained rows, and artifact hash")
  )
}

method_learning_outcomes <- function(analysis, context) {
  c(
    paste0("Use the ", analysis, " adapter to address: ", context$question),
    "Explain one observation with linked analytical evidence and an explicit limitation",
    "Repair and transfer the interpretation while preserving reproducibility"
  )
}

analysis_command_explanations <- function(source, analysis) {
  vapply(source, function(line) {
    if (grepl("^set.seed", line)) {
      "Fixes the random seed so stochastic methods and downstream artifacts can be reproduced."
    } else if (grepl("^#", line)) {
      "Names the local input data object used by the generated analysis."
    } else if (grepl("complete.cases", line, fixed = TRUE)) {
      "Records the retained source-row positions after the explicit complete-case rule."
    } else if (grepl("analysis_data <-", line, fixed = TRUE)) {
      "Creates the analysis data from the retained source rows and approved columns."
    } else if (grepl("analysis_columns", line, fixed = TRUE)) {
      "Declares the exact variables needed for the analysis, outcome, and stable labels."
    } else if (grepl("labels <-", line, fixed = TRUE)) {
      "Creates stable observation labels from the approved ID column or original source-row position."
    } else if (grepl("factor\\(", line)) {
      "Makes the two outcome levels and their ordering explicit before logistic regression."
    } else if (grepl("summary|variable =", line)) {
      "Creates linked value, centered-value, percentile, center, spread, and histogram evidence for one numeric variable."
    } else if (grepl("cor.test", line, fixed = TRUE)) {
      "Computes the correlation test while retaining the paired observations used by the estimate."
    } else if (grepl("bootstrap_mean", line, fixed = TRUE)) {
      "Resamples the observed values with replacement using the recorded seed and computes a mean for each resample."
    } else if (grepl("t.test", line, fixed = TRUE)) {
      "Compares the numeric outcome across exactly two declared groups and returns a difference interval and test evidence."
    } else if (grepl("^fit <- aov", line)) {
      "Partitions outcome variation into between-group and within-group evidence with an explicit ANOVA model."
    } else if (grepl("contingency|chisq.test", line)) {
      "Builds observed category counts and compares them with expected counts under independence."
    } else if (grepl("prcomp", line, fixed = TRUE)) {
      "Centers and standardizes the selected variables, then computes principal-component scores and loadings."
    } else if (grepl("^fit <- lm", line)) {
      "Fits the approved linear model formula to the selected outcome and predictors."
    } else if (grepl("^fit <- glm", line)) {
      "Fits a binomial logistic model whose probabilities refer to the declared event level."
    } else if (grepl("scale\\(", line)) {
      "Centers and scales the selected variables before distance-based clustering."
    } else if (grepl("kmeans", line, fixed = TRUE)) {
      "Runs k-means with the approved number of clusters and 25 random starts."
    } else if (grepl("as_rclaimlab_evidence", line, fixed = TRUE)) {
      paste0("Converts the existing ", analysis, " result into linked Evidence IR without reimplementing the statistical method.")
    } else {
      "Creates a visible, reviewable step in the compiled R analysis pipeline."
    }
  }, character(1), USE.NAMES = FALSE)
}

lesson_scene_contract <- function(lesson) {
  tasks <- lapply(lesson$tasks, function(task) {
    list(id = task$id, type = task$type, prompt = task$prompt,
         criteria = as.list(task$criteria), evidence_required = task$evidence_required)
  })
  names(tasks) <- vapply(lesson$tasks, `[[`, character(1), "type")
  pedagogy <- lesson$evidence$metadata$pedagogy %||% list()
  wizard <- lesson$evidence$metadata$wizard %||% list()
  dimensions <- lesson$evidence$dimensions$label
  analysis_source <- wizard$generated_r_code %||% character()
  evidence_table <- as.data.frame(lesson$evidence)
  evidence_rows <- lapply(seq_len(nrow(evidence_table)), function(index) {
    as.list(evidence_table[index, , drop = FALSE])
  })
  representations <- lapply(lesson$representations, function(representation) {
    list(
      type = representation$type, dimensions = representation$dimensions,
      fallback = representation$fallback, title = representation$title
    )
  })
  visualization_metadata <- lesson$evidence$metadata[intersect(
    names(lesson$evidence$metadata),
    c("histogram", "summary", "table_dimensions", "table_levels", "classification", "test")
  )]
  list(
    schema_version = "rclaimlab-browser-contract-1",
    lesson_id = lesson$id,
    title = lesson$title,
    outcomes = lesson$outcomes,
    question = pedagogy$question %||% lesson$title,
    analysis = lesson$evidence$analysis$engine,
    representations = representations,
    visualization_metadata = visualization_metadata,
    axis_labels = as.list(stats::setNames(c(dimensions[seq_len(min(3L, length(dimensions)))], rep("", max(0L, 3L - length(dimensions))))[1:3], c("x", "y", "z"))),
    seed = lesson$evidence$analysis$seed,
    evidence_hash = lesson$evidence$analysis$artifact_hash,
    tasks = tasks,
    diagnostics = pedagogy$diagnostics %||% list(),
    cautions = pedagogy$cautions %||% character(),
    misconceptions = pedagogy$misconceptions %||% character(),
    context = pedagogy$context %||% wizard$context %||% list(),
    analysis_source = analysis_source,
    evidence_table = list(columns = names(evidence_table), rows = evidence_rows),
    command_explanations = lapply(seq_along(analysis_source), function(index) list(
      code = analysis_source[[index]],
      explanation = analysis_command_explanations(analysis_source[[index]], lesson$evidence$analysis$engine)[[1]]
    ))
  )
}

default_scene_contract <- function(title) {
  stages <- c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
  context <- list(question = "What pattern is visible in these data?", unit_of_analysis = "one plotted observation")
  prompts <- method_task_prompts("data_view", context, c("x", "y", "z"), NULL)
  criteria <- method_task_criteria("data_view")
  tasks <- lapply(stages, function(stage) list(
    id = paste0("scene-", stage), type = stage, prompt = prompts[[stage]],
    criteria = as.list(criteria[[stage]] %||% character()),
    evidence_required = stage %in% c("explore", "explain", "repair", "transfer")
  ))
  names(tasks) <- stages
  list(
    schema_version = "rclaimlab-browser-contract-1", lesson_id = "scene", title = title,
    outcomes = c("Describe linked evidence", "State a limitation"),
    question = "What pattern is visible in these data?", analysis = "data.frame",
    axis_labels = list(x = "Horizontal variable", y = "Vertical variable", z = "Depth variable"), seed = 2026L,
    evidence_hash = NULL, tasks = tasks, diagnostics = list(),
    cautions = "Visible association is not evidence of causation.",
    misconceptions = character(), context = list(unit_of_analysis = "one plotted observation"),
    analysis_source = character(), command_explanations = list(),
    evidence_table = list(columns = character(), rows = list()), visualization_metadata = list(),
    representations = list(
      list(type = "table", fallback = "text", title = "Evidence table"),
      list(type = "plot2d", fallback = "table", title = "Two-dimensional evidence"),
      list(type = "scene3d", fallback = "table", title = "Three-dimensional evidence")
    )
  )
}
