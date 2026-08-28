#' Create a role-adaptive workflow from imported data
#'
#' @param dataset Imported `rclaimlab_dataset`.
#' @param role Data analyst, data scientist, or model reviewer.
#' @param goal Analytical goal.
#' @param outcome Optional outcome column.
#' @param predictors Optional predictor or analysis columns.
#' @param slice_by Explicit review grouping columns.
#' @param analysis `auto`, `describe`, `lm`, or `glm`.
#' @param question Reviewable analytical question.
#' @param missing_values Explicit character tokens treated as missing.
#' @param seed Reproducibility seed.
#' @param title,id Workflow identity.
#' @return An unapproved `rclaimlab_workflow`.
#' @export
workflow_from_dataset <- function(dataset,
                                  role = c("data_analyst", "data_scientist", "model_reviewer"),
                                  goal = NULL, outcome = NULL, predictors = NULL,
                                  slice_by = character(), analysis = "auto",
                                  question = NULL, missing_values = character(),
                                  seed = 2026L, title = NULL, id = NULL) {
  validate_rclaimlab_dataset(dataset)
  role <- match.arg(role)
  data <- dataset$data
  if (!is.null(outcome) && !(outcome %in% names(data))) stop("outcome was not found in the dataset", call. = FALSE)
  slice_by <- unique(as.character(slice_by))
  if (any(!slice_by %in% names(data))) stop("slice_by columns were not found in the dataset", call. = FALSE)
  candidates <- setdiff(names(data), c(outcome, slice_by))
  identifier <- grepl("(^|_)(id|name|email|phone|address|ssn)(_|$)", tolower(candidates))
  candidates <- candidates[!identifier]
  if (is.null(predictors)) predictors <- utils::head(candidates, 8L)
  predictors <- unique(as.character(predictors))
  if (!length(predictors) || any(!predictors %in% names(data))) stop("predictors must name dataset columns", call. = FALSE)
  if (any(predictors %in% outcome)) stop("predictors cannot duplicate outcome", call. = FALSE)
  if (is.null(goal)) goal <- if (role == "data_analyst") "describe" else if (role == "data_scientist") "predict" else "audit"
  goal <- match.arg(goal, c("describe", "compare", "predict", "audit"))
  if (analysis == "auto") {
    analysis <- if (role == "data_analyst") "describe" else {
      if (is.null(outcome)) stop("data scientist and reviewer workflows require an outcome", call. = FALSE)
      if (is.numeric(data[[outcome]]) && length(unique(data[[outcome]][!is.na(data[[outcome]])])) > 2L) "lm" else "glm"
    }
  }
  analysis <- match.arg(analysis, c("describe", "lm", "glm"))
  if (analysis %in% c("lm", "glm") && is.null(outcome)) stop("model workflows require an outcome", call. = FALSE)
  if (analysis == "glm" && length(unique(data[[outcome]][!is.na(data[[outcome]])])) != 2L) {
    stop("glm workflow requires a two-level outcome", call. = FALSE)
  }
  if (is.null(question)) question <- workflow_default_question(role, goal, outcome, predictors)
  assert_scalar_text(question, "question")
  missing_values <- unique(as.character(missing_values))
  if (is.null(title)) title <- paste(workflow_role_label(role), "workflow for", dataset$manifest$id)
  if (is.null(id)) id <- lesson_id_from_title(title)
  profile <- workflow_role_profile(role)
  activities <- workflow_profile_activities(profile, question)
  value <- workflow_spec(
    id = id, title = title, role = role, goal = goal, dataset = dataset,
    activities = activities,
    deliverables = profile$deliverables,
    artifact_plan = profile$artifact_plan,
    analysis = list(
      method = analysis, question = question, outcome = outcome,
      predictors = predictors, slice_by = slice_by,
      missing_values = missing_values, seed = as.integer(seed),
      split = list(train = 0.8, test = 0.2, stratified = analysis == "glm"),
      threshold = 0.5, minimum_slice_n = 20L
    )
  )
  value
}

#' Record the explicit approvals required to execute a workflow
#'
#' @param workflow Workflow specification.
#' @param question,variable_roles,method,missing_values,publication Approval flags.
#' @return Updated workflow.
#' @export
approve_workflow <- function(workflow, question = TRUE, variable_roles = TRUE,
                             method = TRUE, missing_values = TRUE,
                             publication = FALSE) {
  validate_workflow_spec(workflow)
  workflow$approvals <- list(
    question = isTRUE(question), variable_roles = isTRUE(variable_roles),
    method = isTRUE(method), missing_values = isTRUE(missing_values),
    publication = isTRUE(publication)
  )
  workflow
}

#' Execute an approved workflow locally in R
#'
#' @param workflow Approved workflow specification.
#' @return An `rclaimlab_workflow_run` containing an evidence bundle.
#' @export
run_workflow <- function(workflow) {
  validate_workflow_spec(workflow)
  required <- c("question", "variable_roles", "method", "missing_values")
  missing <- required[!vapply(workflow$approvals[required], isTRUE, logical(1))]
  if (length(missing)) stop("workflow execution requires approvals: ", paste(missing, collapse = ", "), call. = FALSE)
  if (workflow$role == "guided_learning") {
    evidence <- workflow$analysis$evidence
    bundle <- new_evidence_bundle(workflow$id, NULL)
    bundle <- add_evidence_artifact(bundle, "lesson-evidence", evidence, "guided_learning", character(), character())
    return(new_workflow_run(workflow, NULL, bundle, list(mode = "legacy_lesson")))
  }
  dataset <- workflow$dataset
  validate_rclaimlab_dataset(dataset)
  prepared <- prepare_workflow_data(dataset, workflow$analysis)
  bundle <- workflow$upstream %||% new_evidence_bundle(workflow$id, dataset)
  profile_evidence <- workflow_profile_evidence(prepared$data, prepared$record_ids, workflow$analysis)
  if (!("dataset-profile" %in% bundle$registry$artifact_id)) {
    bundle <- add_evidence_artifact(
      bundle, "dataset-profile", profile_evidence, workflow$role,
      character(), activity_id_for_type(workflow, "inspect")
    )
  }
  result <- switch(
    workflow$role,
    data_analyst = run_analyst_workflow(workflow, prepared, bundle),
    data_scientist = run_model_workflow(workflow, prepared, bundle),
    model_reviewer = run_reviewer_workflow(workflow, prepared, bundle)
  )
  new_workflow_run(workflow, dataset, result$bundle, result$execution)
}

#' Continue an existing run as a different data-science role
#'
#' @param previous_run Completed workflow run.
#' @param role Next role.
#' @param ... Overrides passed to `workflow_from_dataset()`.
#' @return A new, unapproved workflow linked to the previous evidence bundle.
#' @export
continue_workflow <- function(previous_run, role = c("data_scientist", "model_reviewer"), ...) {
  if (!inherits(previous_run, "rclaimlab_workflow_run")) stop("previous_run must be an rclaimlab_workflow_run", call. = FALSE)
  if (is.null(previous_run$dataset)) stop("legacy learning runs cannot be continued as data-science roles", call. = FALSE)
  role <- match.arg(role)
  defaults <- previous_run$workflow$analysis
  arguments <- list(
    dataset = previous_run$dataset, role = role,
    goal = if (role == "model_reviewer") "audit" else "predict",
    outcome = defaults$outcome, predictors = defaults$predictors,
    slice_by = defaults$slice_by, analysis = defaults$method,
    question = defaults$question, missing_values = defaults$missing_values,
    seed = defaults$seed,
    title = paste(workflow_role_label(role), "handoff from", previous_run$workflow$title)
  )
  overrides <- list(...)
  arguments[names(overrides)] <- overrides
  value <- do.call(workflow_from_dataset, arguments)
  value$upstream <- previous_run$bundle
  value$handoff_from <- list(
    workflow_id = previous_run$workflow$id,
    role = previous_run$workflow$role,
    bundle_hash = previous_run$bundle$bundle_hash
  )
  value
}

new_evidence_bundle <- function(workflow_id, dataset) {
  source <- if (is.null(dataset)) NULL else list(
    provider = dataset$source$provider,
    id = if (dataset$source$provider == "local") basename(dataset$source$id) else dataset$source$id,
    revision = dataset$manifest$revision, fingerprint = dataset$source_fingerprint
  )
  value <- structure(
    list(
      schema_version = "rclaimlab-evidence-bundle-1", workflow_id = workflow_id,
      source = source,
      registry = data.frame(
        artifact_id = character(), artifact_hash = character(), engine = character(),
        role = character(), activity_id = character(), stringsAsFactors = FALSE
      ),
      artifacts = list(), dependencies = list(), lineage = list(), bundle_hash = NA_character_
    ),
    class = c("rclaimlab_evidence_bundle", "list")
  )
  refresh_bundle_hash(value)
}

add_evidence_artifact <- function(bundle, id, evidence, role, depends_on, activity_id) {
  validate_evidence_bundle(bundle)
  validate_rclaimlab_evidence(evidence)
  assert_scalar_text(id, "artifact id")
  if (id %in% bundle$registry$artifact_id) stop("evidence bundle artifact id must be unique", call. = FALSE)
  if (length(setdiff(depends_on, bundle$registry$artifact_id))) stop("artifact dependency was not found in the bundle", call. = FALSE)
  bundle$registry <- rbind(bundle$registry, data.frame(
    artifact_id = id, artifact_hash = evidence$analysis$artifact_hash,
    engine = evidence$analysis$engine, role = role,
    activity_id = paste(activity_id, collapse = ","), stringsAsFactors = FALSE
  ))
  bundle$artifacts[[id]] <- evidence
  bundle$dependencies[[id]] <- as.character(depends_on)
  bundle$lineage[[id]] <- data.frame(
    source_record_id = evidence$observations$observation_id,
    observation_id = evidence$observations$observation_id,
    evidence_id = vapply(evidence$observations$observation_id, function(observation) {
      paste(evidence$values$evidence_id[evidence$values$observation_id == observation], collapse = ",")
    }, character(1)),
    stringsAsFactors = FALSE
  )
  refresh_bundle_hash(bundle)
}

#' Validate a multi-artifact evidence bundle
#'
#' @param x Evidence bundle.
#' @return Invisibly returns `TRUE`.
#' @export
validate_evidence_bundle <- function(x) {
  if (!inherits(x, "rclaimlab_evidence_bundle") ||
      !identical(x$schema_version, "rclaimlab-evidence-bundle-1") ||
      anyDuplicated(x$registry$artifact_id) ||
      !identical(sort(names(x$artifacts) %||% character()), sort(x$registry$artifact_id))) {
    stop("x must satisfy rclaimlab-evidence-bundle-1", call. = FALSE)
  }
  if (length(x$artifacts)) {
    invisible(lapply(x$artifacts, validate_rclaimlab_evidence))
    recorded <- stats::setNames(x$registry$artifact_hash, x$registry$artifact_id)
    actual <- vapply(x$artifacts, function(evidence) evidence$analysis$artifact_hash, character(1))
    if (!identical(unname(recorded[names(actual)]), unname(actual))) stop("bundle artifact hashes are not synchronized", call. = FALSE)
  }
  invisible(TRUE)
}

refresh_bundle_hash <- function(bundle) {
  payload <- unclass(bundle)
  payload$bundle_hash <- NULL
  bundle$bundle_hash <- evidence_hash(payload)
  bundle
}

prepare_workflow_data <- function(dataset, analysis) {
  data <- dataset$data
  for (column in names(data)[vapply(data, is.character, logical(1))]) {
    if (length(analysis$missing_values)) data[[column]][data[[column]] %in% analysis$missing_values] <- NA_character_
    data[[column]] <- factor(data[[column]])
  }
  selected <- unique(c(analysis$outcome, analysis$predictors, analysis$slice_by))
  selected <- selected[!is.na(selected) & nzchar(selected)]
  complete <- stats::complete.cases(data[selected])
  if (sum(complete) < if (analysis$method %in% c("lm", "glm")) 20L else 2L) {
    stop("too few complete rows remain for the approved workflow", call. = FALSE)
  }
  list(
    data = droplevels(data[complete, , drop = FALSE]),
    record_ids = dataset$source_record_id[complete],
    omitted_record_ids = dataset$source_record_id[!complete],
    original_rows = nrow(data), retained_rows = sum(complete)
  )
}

workflow_profile_evidence <- function(data, record_ids, analysis) {
  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  numeric_columns <- setdiff(numeric_columns, analysis$outcome)
  if (!length(numeric_columns) && !is.null(analysis$outcome) && is.numeric(data[[analysis$outcome]])) numeric_columns <- analysis$outcome
  if (!length(numeric_columns)) {
    encoded <- as.numeric(data[[analysis$predictors[[1]]]])
    frame <- data.frame(profile_value = encoded)
  } else {
    numeric_columns <- utils::head(numeric_columns, 3L)
    frame <- data[numeric_columns]
  }
  as_rclaimlab_evidence(frame, labels = record_ids, observation_ids = record_ids,
                        seed = analysis$seed, analysis_call = "profile_dataset(data)")
}

run_analyst_workflow <- function(workflow, prepared, bundle) {
  analysis <- workflow$analysis
  numeric <- analysis$predictors[vapply(prepared$data[analysis$predictors], is.numeric, logical(1))]
  if (!length(numeric) && !is.null(analysis$outcome) && is.numeric(prepared$data[[analysis$outcome]])) numeric <- analysis$outcome
  if (!length(numeric)) {
    value <- as.numeric(prepared$data[[analysis$predictors[[1]]]])
    frame <- data.frame(category_code = value)
  } else frame <- prepared$data[utils::head(numeric, 3L)]
  evidence <- as_rclaimlab_evidence(
    frame, labels = prepared$record_ids, observation_ids = prepared$record_ids,
    seed = analysis$seed, analysis_call = "analyst_describe(data)"
  )
  evidence$metadata$workflow <- list(
    question = analysis$question, omitted_records = prepared$omitted_record_ids,
    limitation = "Descriptive evidence does not establish a causal or population claim."
  )
  evidence <- refresh_evidence_hash(evidence)
  bundle <- add_evidence_artifact(bundle, "analyst-evidence", evidence, workflow$role,
                                  "dataset-profile", activity_id_for_type(workflow, c("describe", "compare", "explain")))
  list(bundle = bundle, execution = list(mode = "descriptive", retained_rows = prepared$retained_rows))
}

run_model_workflow <- function(workflow, prepared, bundle) {
  analysis <- workflow$analysis
  split <- workflow_split(prepared$data[[analysis$outcome]], analysis$method, analysis$seed)
  train <- prepared$data[split$train, , drop = FALSE]
  test <- prepared$data[split$test, , drop = FALSE]
  formula <- stats::reformulate(analysis$predictors, response = analysis$outcome)
  model <- if (analysis$method == "lm") {
    stats::lm(formula, data = train)
  } else {
    train[[analysis$outcome]] <- ensure_binary_factor(train[[analysis$outcome]], levels(prepared$data[[analysis$outcome]]))
    test[[analysis$outcome]] <- ensure_binary_factor(test[[analysis$outcome]], levels(train[[analysis$outcome]]))
    stats::glm(formula, data = train, family = stats::binomial())
  }
  test_ids <- prepared$record_ids[split$test]
  evidence <- as_rclaimlab_evidence(
    model, newdata = test, truth = test[[analysis$outcome]], labels = test_ids,
    observation_ids = test_ids, seed = analysis$seed, threshold = analysis$threshold
  )
  baseline <- if (analysis$method == "glm") {
    truth <- as.numeric(test[[analysis$outcome]]) - 1
    max(mean(truth), 1 - mean(truth))
  } else sqrt(mean((test[[analysis$outcome]] - mean(train[[analysis$outcome]]))^2))
  evidence$metadata$workflow <- list(
    question = analysis$question,
    split = list(train_record_ids = prepared$record_ids[split$train], test_record_ids = test_ids,
                 train_n = nrow(train), test_n = nrow(test), seed = analysis$seed,
                 stratified = analysis$method == "glm"),
    baseline = list(metric = if (analysis$method == "glm") "majority_accuracy" else "mean_rmse", value = baseline),
    factor_levels = lapply(train[analysis$predictors], function(x) if (is.factor(x)) levels(x) else NULL),
    omitted_records = prepared$omitted_record_ids
  )
  if (length(analysis$slice_by)) {
    evidence$metadata$workflow$slices <- workflow_slice_metrics(
      evidence, test[analysis$slice_by], analysis$method, analysis$minimum_slice_n
    )
  }
  evidence <- refresh_evidence_hash(evidence)
  bundle <- add_evidence_artifact(bundle, "model-evidence", evidence, workflow$role,
                                  "dataset-profile", activity_id_for_type(workflow, c("fit", "evaluate", "slice")))
  list(
    bundle = bundle,
    execution = list(
      mode = analysis$method, formula = paste(deparse(formula), collapse = " "),
      train_n = nrow(train), test_n = nrow(test), baseline = baseline,
      source_code = workflow_model_source(analysis, formula)
    )
  )
}

run_reviewer_workflow <- function(workflow, prepared, bundle) {
  if (!("model-evidence" %in% bundle$registry$artifact_id)) {
    modeled <- run_model_workflow(workflow, prepared, bundle)
    bundle <- modeled$bundle
  }
  model_evidence <- bundle$artifacts[["model-evidence"]]
  metrics <- model_evidence$metadata$classification %||%
    model_evidence$metadata$evaluation %||% list(metric = 0)
  numeric_metrics <- unlist(metrics, recursive = TRUE, use.names = TRUE)
  numeric_metrics <- suppressWarnings(as.numeric(numeric_metrics))
  numeric_metrics <- numeric_metrics[is.finite(numeric_metrics)]
  if (!length(numeric_metrics)) numeric_metrics <- 0
  review_frame <- data.frame(metric_value = numeric_metrics)
  rownames(review_frame) <- NULL
  review_ids <- sprintf("review-%03d", seq_along(numeric_metrics))
  review <- as_rclaimlab_evidence(
    review_frame, labels = review_ids, observation_ids = review_ids,
    seed = workflow$analysis$seed, analysis_call = "review_model_evidence(bundle)"
  )
  review$metadata$review <- list(
    source_artifact = model_evidence$analysis$artifact_hash,
    status = "requires_human_approval",
    limitations = c(
      "Subgroup metrics are review signals, not a fairness certification.",
      "Predictive evidence does not establish causality or justify individual decisions."
    )
  )
  review <- refresh_evidence_hash(review)
  bundle <- add_evidence_artifact(bundle, "review-evidence", review, workflow$role,
                                  "model-evidence", activity_id_for_type(workflow, c("challenge", "approve")))
  list(bundle = bundle, execution = list(mode = "review", reviewed_hash = model_evidence$analysis$artifact_hash))
}

workflow_split <- function(outcome, method, seed) {
  n <- length(outcome)
  train_size <- max(2L, floor(0.8 * n))
  if (method == "glm") {
    groups <- split(seq_len(n), outcome)
    train <- unlist(lapply(seq_along(groups), function(index) {
      group <- groups[[index]]
      with_preserved_seed(seed + index, sort(sample(group, max(1L, floor(0.8 * length(group))))))
    }), use.names = FALSE)
    train <- sort(unique(train))
  } else train <- with_preserved_seed(seed, sort(sample.int(n, train_size)))
  test <- setdiff(seq_len(n), train)
  if (length(test) < 2L) stop("workflow split leaves fewer than two holdout rows", call. = FALSE)
  list(train = train, test = test)
}

ensure_binary_factor <- function(x, declared_levels = NULL) {
  if (is.factor(x)) {
    levels <- if (length(declared_levels)) declared_levels else levels(x)
    return(factor(x, levels = levels))
  }
  factor(x)
}

workflow_slice_metrics <- function(evidence, slices, method, minimum_n) {
  table <- as.data.frame(evidence)
  results <- list()
  suppressed <- list()
  for (column in names(slices)) {
    groups <- split(seq_len(nrow(table)), slices[[column]], drop = TRUE)
    for (group in names(groups)) {
      index <- groups[[group]]
      key <- paste(column, group, sep = "=")
      if (length(index) < minimum_n) {
        suppressed[[key]] <- list(n = length(index), reason = "below minimum_slice_n")
      } else if (method == "glm") {
        truth <- table$observed[index]
        predicted <- table$predicted_class[index]
        results[[key]] <- list(
          n = length(index), accuracy = mean(predicted == truth),
          brier_score = mean((table$predicted_probability[index] - truth)^2)
        )
      } else {
        residual <- table$residual[index]
        results[[key]] <- list(n = length(index), rmse = sqrt(mean(residual^2)), mae = mean(abs(residual)))
      }
    }
  }
  list(results = results, suppressed = suppressed, minimum_n = minimum_n,
       interpretation = "Review signal only; not a fairness certification.")
}

workflow_role_profile <- function(role) {
  switch(
    role,
    data_analyst = list(
      steps = c("frame", "inspect", "clean", "describe", "compare", "explain", "communicate", "handoff"),
      artifact_plan = c("dataset-profile", "analyst-evidence"),
      deliverables = list(analysis_brief = "Evidence-linked analysis brief", evidence_table = "Portable evidence table", decision_log = "Decision and limitation log")
    ),
    data_scientist = list(
      steps = c("frame", "inspect", "clean", "split", "baseline", "fit", "diagnose", "evaluate", "slice", "communicate", "handoff"),
      artifact_plan = c("dataset-profile", "model-evidence"),
      deliverables = list(r_script = "Reproducible R analysis", model_card = "Model evaluation card", evaluation = "Holdout evidence")
    ),
    model_reviewer = list(
      steps = c("inspect", "reproduce", "diagnose", "challenge", "slice", "revise", "approve"),
      artifact_plan = c("dataset-profile", "model-evidence", "review-evidence"),
      deliverables = list(review_report = "Evidence review report", limitations = "Risk and limitation log", approval = "Human approval state")
    )
  )
}

workflow_profile_activities <- function(profile, question) {
  artifact_for <- function(type) {
    if (type %in% c("inspect", "clean")) "dataset-profile"
    else if (type %in% c("describe", "compare", "explain")) "analyst-evidence"
    else if (type %in% c("split", "baseline", "fit", "diagnose", "evaluate", "slice", "communicate", "challenge", "reproduce")) "model-evidence"
    else if (type %in% c("revise", "approve")) "review-evidence"
    else character()
  }
  lapply(seq_along(profile$steps), function(index) {
    type <- profile$steps[[index]]
    artifact <- intersect(artifact_for(type), profile$artifact_plan)
    activity_spec(
      id = sprintf("%02d-%s", index, type), type = type,
      prompt = workflow_activity_prompt(type, question),
      criteria = workflow_activity_criteria(type),
      depends_on = if (index > 1L) sprintf("%02d-%s", index - 1L, profile$steps[[index - 1L]]) else character(),
      evidence_required = length(artifact) > 0L,
      input_artifacts = artifact,
      output_type = workflow_activity_output(type)
    )
  })
}

workflow_activity_prompt <- function(type, question) {
  prompts <- c(
    frame = paste0("State the decision boundary and question: ", question),
    inspect = "Inspect source, license, row meaning, variable roles, missingness, and possible identifiers.",
    clean = "Approve explicit missing-value and retained-row decisions without silently changing source data.",
    transform = "Run the approved transformation and preserve row lineage.",
    describe = "Describe center, spread, shape, counts, and unusual observations using linked evidence.",
    compare = "Compare relevant groups or variables without making a causal claim.",
    split = "Inspect the deterministic train/test split and confirm the unit of prediction.",
    baseline = "Compare the approved model with a transparent baseline.",
    fit = "Fit the approved R model and retain formula, factor encoding, and seed.",
    diagnose = "Inspect method-specific diagnostics and identify failure signals.",
    evaluate = "Evaluate holdout performance and connect each metric to model evidence.",
    slice = "Inspect explicitly selected subgroup slices and suppress underpowered groups.",
    explain = "Write a claim that cites evidence and states a limitation.",
    challenge = "Challenge the strongest claim using provenance, diagnostics, and alternative explanations.",
    revise = "Revise claims or request changes where evidence is insufficient.",
    communicate = "Prepare a concise evidence-linked brief for the next role.",
    reproduce = "Re-run the recorded source, split, and analysis contract before review.",
    handoff = "Package evidence, decisions, limitations, unresolved issues, and reproducibility metadata.",
    approve = "Record human approval or request revision; do not infer approval from metrics."
  )
  unname(prompts[[type]])
}

workflow_activity_criteria <- function(type) {
  common <- list(
    frame = c(question = "Question and decision boundary are explicit"),
    inspect = c(source = "Source and license reviewed", unit = "Unit of observation identified"),
    evaluate = c(metric = "Uses holdout evidence", baseline = "Compares a baseline"),
    challenge = c(counterevidence = "Names counterevidence or uncertainty", limitation = "States a decision limitation"),
    handoff = c(evidence = "Includes artifact hashes", limitation = "Includes unresolved limitations"),
    approve = c(human = "Approval is explicitly human-recorded")
  )
  common[[type]] %||% c(completion = paste("Completes", type, "with traceable evidence"))
}

workflow_activity_output <- function(type) {
  if (type == "handoff") "handoff"
  else if (type == "approve") "approval"
  else if (type %in% c("communicate", "explain", "challenge", "revise")) "claim"
  else "decision"
}

workflow_default_question <- function(role, goal, outcome, predictors) {
  if (role == "data_analyst") paste0("What evidence patterns are visible across ", paste(utils::head(predictors, 3L), collapse = ", "), "?")
  else if (role == "data_scientist") paste0("How well can the approved predictors estimate ", outcome, " on held-out observations?")
  else paste0("Are the evidence, diagnostics, and limitations sufficient to support the claim about ", outcome, "?")
}

workflow_role_label <- function(role) tools::toTitleCase(gsub("_", " ", role))

activity_id_for_type <- function(workflow, type) {
  type <- as.character(type)
  ids <- vapply(workflow$activities, `[[`, character(1), "id")
  types <- vapply(workflow$activities, `[[`, character(1), "type")
  ids[types %in% type]
}

workflow_model_source <- function(analysis, formula) c(
  paste0("set.seed(", analysis$seed, ")"),
  "# Deterministic 80/20 split recorded in workflow-spec.json",
  paste0("model <- stats::", analysis$method, "(", paste(deparse(formula), collapse = " "),
         if (analysis$method == "glm") ", data = train, family = stats::binomial())" else ", data = train)"),
  "predictions <- stats::predict(model, newdata = test)",
  "# Inspect evidence/artifacts/model-evidence.json for linked holdout evidence."
)

new_workflow_run <- function(workflow, dataset, bundle, execution) {
  validate_evidence_bundle(bundle)
  structure(
    list(
      schema_version = "rclaimlab-workflow-run-1", workflow = workflow,
      dataset = dataset, bundle = bundle, execution = execution,
      completed_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    class = c("rclaimlab_workflow_run", "list")
  )
}

#' @export
print.rclaimlab_evidence_bundle <- function(x, ...) {
  cat("<rclaimlab_evidence_bundle>", x$workflow_id, "\n")
  cat("Artifacts:", nrow(x$registry), " Hash:", x$bundle_hash, "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_evidence_bundle <- function(object, ...) {
  list(workflow_id = object$workflow_id, artifacts = object$registry,
       source = object$source, bundle_hash = object$bundle_hash)
}

#' @export
print.rclaimlab_workflow_run <- function(x, ...) {
  cat("<rclaimlab_workflow_run>", x$workflow$id, "\n")
  cat("Role:", x$workflow$role, " Artifacts:", nrow(x$bundle$registry), "\n")
  invisible(x)
}

#' @export
summary.rclaimlab_workflow_run <- function(object, ...) {
  list(workflow = summary(object$workflow), execution = object$execution,
       bundle_hash = object$bundle$bundle_hash, artifacts = object$bundle$registry)
}

#' @export
as.data.frame.rclaimlab_workflow_run <- function(x, row.names = NULL, optional = FALSE, ...) x$bundle$registry
