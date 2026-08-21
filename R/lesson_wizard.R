#' Profile learner-supplied data for lesson authoring
#'
#' `profile_learning_data()` inspects a local data frame without selecting a
#' statistical method. The profile makes missingness, variable roles, possible
#' identifiers, and supported Evidence Compiler adapters visible before a lesson
#' is created.
#'
#' @param data A data frame supplied by a learner or educator.
#' @param outcome Optional outcome column used to refine analysis recommendations.
#' @param intent Intended analytical learning goal. See `recommend_lesson_analysis()`.
#' @param grouping Optional grouping or nesting column.
#' @param time Optional time or sequence column.
#' @return An object of class `rlearnxr_data_profile`.
#' @export
profile_learning_data <- function(data, outcome = NULL, intent = "explore",
                                  grouping = NULL, time = NULL) {
  if (!is.data.frame(data)) stop("data must be a data.frame", call. = FALSE)
  if (nrow(data) < 2L || ncol(data) < 1L) {
    stop("learning data must contain at least two rows and one column", call. = FALSE)
  }
  if (!is.null(outcome) && (length(outcome) != 1L || is.na(outcome) || !(outcome %in% names(data)))) {
    stop("outcome must name one column in data", call. = FALSE)
  }
  intent <- match.arg(intent, names(learning_intents()))
  for (role in c("grouping", "time")) {
    value <- get(role)
    if (!is.null(value) && (length(value) != 1L || is.na(value) || !(value %in% names(data)))) {
      stop(role, " must name one column in data", call. = FALSE)
    }
  }

  column_type <- vapply(data, learning_column_type, character(1))
  missing <- vapply(data, function(value) sum(is.na(value)), integer(1))
  distinct <- vapply(data, function(value) length(unique(value[!is.na(value)])), integer(1))
  possible_identifier <- grepl(
    "(^|_)(id|name|email|phone|address|ssn|student|learner)(_|$)",
    tolower(names(data))
  )
  role <- ifelse(possible_identifier, "possible identifier", "candidate variable")
  if (!is.null(time)) role[names(data) == time] <- "time"
  if (!is.null(grouping)) role[names(data) == grouping] <- "grouping"
  if (!is.null(outcome)) role[names(data) == outcome] <- "outcome"
  columns <- data.frame(
    column = names(data),
    type = column_type,
    missing = missing,
    missing_percent = round(100 * missing / nrow(data), 1),
    distinct = distinct,
    constant = distinct <= 1L,
    possible_identifier = possible_identifier,
    role = role,
    stringsAsFactors = FALSE
  )
  recommendations <- lesson_analysis_recommendations(data, outcome, intent, grouping, time)
  warnings <- character()
  if (any(missing > 0L)) {
    warnings <- c(warnings, "Missing values require an explicit fail or complete-case decision before compilation.")
  }
  if (any(possible_identifier)) {
    warnings <- c(warnings, "Possible identifiers were detected. Use synthetic or de-identified data for a published lesson.")
  }
  if (any(columns$constant)) {
    warnings <- c(warnings, "Constant columns cannot be used as analysis dimensions.")
  }
  if (!is.null(grouping) || !is.null(time)) {
    warnings <- c(warnings, "Grouped or repeated observations were declared. Core lm/glm adapters do not model dependence, so regression is not automatically recommended.")
  }
  value <- structure(
    list(
      schema_version = "rlearnxr-data-profile-2",
      rows = nrow(data),
      columns = columns,
      outcome = outcome,
      intent = intent,
      grouping = grouping,
      time = time,
      recommendations = recommendations,
      warnings = unique(warnings),
      data = data
    ),
    class = c("rlearnxr_data_profile", "list")
  )
  value
}

#' Recommend supported lesson analyses
#'
#' Recommendations are deterministic rules based on the author's analytical
#' intent, declared data structure, variable types, and sample size. Availability
#' is kept separate from recommendation so a runnable method is not presented as
#' substantively appropriate by default.
#'
#' @param x A data frame or `rlearnxr_data_profile`.
#' @param outcome Optional outcome column.
#' @param intent One of `explore`, `reduce`, `explain`, `classify`, or `cluster`.
#' @param grouping Optional grouping or nesting column.
#' @param time Optional time or sequence column.
#' @return A data frame of supported analysis choices and rationale.
#' @export
recommend_lesson_analysis <- function(x, outcome = NULL, intent = "explore",
                                      grouping = NULL, time = NULL) {
  if (inherits(x, "rlearnxr_data_profile")) {
    data <- x$data
    if (is.null(outcome)) outcome <- x$outcome
    if (missing(intent)) intent <- x$intent %||% "explore"
    if (is.null(grouping)) grouping <- x$grouping
    if (is.null(time)) time <- x$time
  } else {
    data <- x
  }
  if (!is.data.frame(data)) stop("x must be a data.frame or rlearnxr_data_profile", call. = FALSE)
  intent <- match.arg(intent, names(learning_intents()))
  lesson_analysis_recommendations(data, outcome, intent, grouping, time)
}

#' Create a complete evidence-linked lesson from local data
#'
#' `lesson_from_data()` is the programmatic counterpart of the guided Lesson
#' Wizard. It applies one existing R method, converts the result through an
#' Evidence Adapter, and creates all eight default learning stages.
#'
#' @param data A local data frame.
#' @param analysis One of `auto`, `describe`, `data_view`, `correlation`,
#'   `bootstrap`, `t_test`, `aov`, `chi_square`, `prcomp`, `lm`, `glm`, or
#'   `kmeans`.
#' @param dimensions Numeric columns used as variables, dimensions, or predictors.
#' @param outcome Outcome column for model or group-comparison adapters.
#' @param id_column Optional unique observation-label column.
#' @param question Required educational or analytical question that the lesson addresses.
#' @param intent Intended analytical learning goal.
#' @param unit_of_analysis Plain-language definition of what one row represents.
#' @param grouping Optional grouping or nesting column.
#' @param time Optional time or sequence column.
#' @param decision_context Intended educational use of the evidence.
#' @param title Lesson title.
#' @param id Stable lesson identifier. By default it is derived from `title`.
#' @param outcomes Optional measurable learning outcomes.
#' @param stages Ordered learning stages to include.
#' @param seed Deterministic seed recorded in Evidence IR.
#' @param clusters Number of clusters for `kmeans`.
#' @param bootstrap_times Number of resamples for `bootstrap`.
#' @param na_action Either `fail` or `complete` for explicit complete-case use.
#' @return An object of class `rlearnxr_lesson` ready for `compile_lesson()`.
#' @export
lesson_from_data <- function(data, analysis = "auto", dimensions = NULL,
                             outcome = NULL, id_column = NULL,
                             question = NULL, intent = "explore",
                             unit_of_analysis = "one row in the supplied data",
                             grouping = NULL, time = NULL,
                             decision_context = "learning and interpretation",
                             title = "My data evidence lesson", id = NULL,
                             outcomes = NULL,
                             stages = rlearnxr_learning_stages(), seed = 2026L,
                             clusters = 3L, bootstrap_times = 1000L,
                             na_action = c("fail", "complete")) {
  context <- normalize_learning_context(
    data, question = question, intent = intent,
    unit_of_analysis = unit_of_analysis, outcome = outcome,
    id_column = id_column, grouping = grouping, time = time,
    decision_context = decision_context
  )
  profile <- profile_learning_data(
    data, outcome = outcome, intent = context$intent,
    grouping = grouping, time = time
  )
  analysis <- match.arg(analysis, c(
    "auto", "describe", "data_view", "correlation", "bootstrap",
    "t_test", "aov", "chi_square", "prcomp", "lm", "glm", "kmeans"
  ))
  bootstrap_times <- as.integer(bootstrap_times)
  if (length(bootstrap_times) != 1L || is.na(bootstrap_times) || bootstrap_times < 20L) {
    stop("bootstrap_times must be one integer greater than or equal to 20", call. = FALSE)
  }
  na_action <- match.arg(na_action)
  if (analysis == "auto") analysis <- recommended_analysis_id(profile$recommendations)
  available <- profile$recommendations
  row <- available[available$analysis == analysis, , drop = FALSE]
  if (!nrow(row) || !isTRUE(row$available[[1]])) {
    reason <- if (nrow(row)) row$reason[[1]] else "the method is not supported"
    stop("analysis '", analysis, "' is not available: ", reason, call. = FALSE)
  }

  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  numeric_columns <- setdiff(numeric_columns, c(outcome, id_column, grouping, time))
  dimension_free <- analysis %in% c("t_test", "aov", "chi_square")
  if (is.null(dimensions)) {
    dimensions <- if (dimension_free) character()
    else if (analysis %in% c("describe", "bootstrap")) numeric_columns[seq_len(min(1L, length(numeric_columns)))]
    else if (analysis == "correlation") numeric_columns[seq_len(min(2L, length(numeric_columns)))]
    else numeric_columns
  }
  dimensions <- unique(as.character(dimensions))
  if (dimension_free) dimensions <- character()
  if (!dimension_free && (!length(dimensions) || any(!dimensions %in% names(data)) ||
      any(!vapply(data[dimensions], is.numeric, logical(1))))) {
    stop("dimensions must name numeric columns in data", call. = FALSE)
  }
  minimum_dimensions <- if (analysis %in% c("data_view", "correlation", "prcomp", "kmeans")) 2L else if (dimension_free) 0L else 1L
  if (!dimension_free && length(dimensions) < minimum_dimensions) {
    stop("analysis '", analysis, "' requires at least ", minimum_dimensions, " numeric dimension(s)", call. = FALSE)
  }
  if (analysis %in% c("lm", "glm", "t_test", "aov", "chi_square") && (is.null(outcome) || !(outcome %in% names(data)))) {
    stop("analysis '", analysis, "' requires an outcome column", call. = FALSE)
  }
  if (analysis %in% c("t_test", "aov", "chi_square") && (is.null(grouping) || !(grouping %in% names(data)))) {
    stop("analysis '", analysis, "' requires a grouping column", call. = FALSE)
  }
  if (!is.null(id_column) && (length(id_column) != 1L || !(id_column %in% names(data)))) {
    stop("id_column must name one column in data", call. = FALSE)
  }

  required_columns <- unique(c(dimensions, outcome, id_column, grouping, time))
  keep <- stats::complete.cases(data[required_columns])
  if (!all(keep) && na_action == "fail") {
    stop(sum(!keep), " row(s) contain missing values in selected columns; set na_action = 'complete' to use complete cases", call. = FALSE)
  }
  source_rows <- which(keep)
  prepared <- data[keep, , drop = FALSE]
  if (nrow(prepared) < 2L) stop("fewer than two complete rows remain", call. = FALSE)
  if (length(dimensions)) {
    finite <- vapply(prepared[dimensions], function(value) all(is.finite(value)), logical(1))
    if (!all(finite)) stop("selected numeric dimensions contain non-finite values", call. = FALSE)
    variable <- vapply(prepared[dimensions], function(value) length(unique(value)) > 1L, logical(1))
    if (!all(variable)) stop("selected dimensions must vary across observations", call. = FALSE)
  }

  labels <- wizard_observation_labels(prepared, id_column, source_rows)
  model <- NULL
  evidence <- switch(
    analysis,
    describe = as_rlearnxr_evidence(prepared[[dimensions[[1]]]], labels = labels, variable = dimensions[[1]], seed = seed),
    data_view = as_rlearnxr_evidence(
      prepared[dimensions], dimensions = dimensions, labels = labels, seed = seed,
      analysis_call = wizard_analysis_source(analysis, dimensions, outcome, seed, clusters, id_column, grouping, bootstrap_times)
    ),
    correlation = {
      model <- stats::cor.test(prepared[[dimensions[[1]]]], prepared[[dimensions[[2]]]])
      as_rlearnxr_evidence(model, data = prepared, x_column = dimensions[[1]],
                           y_column = dimensions[[2]], labels = labels, seed = seed)
    },
    bootstrap = {
      model <- bootstrap_mean(prepared[[dimensions[[1]]]], times = bootstrap_times, seed = seed)
      as_rlearnxr_evidence(model)
    },
    t_test = {
      if (!is.numeric(prepared[[outcome]])) stop("t_test requires a numeric outcome", call. = FALSE)
      if (length(unique(prepared[[grouping]])) != 2L) stop("t_test requires exactly two groups", call. = FALSE)
      model <- stats::t.test(prepared[[outcome]] ~ factor(prepared[[grouping]]))
      as_rlearnxr_evidence(model, data = prepared, x_column = outcome,
                           group = grouping, labels = labels, seed = seed)
    },
    aov = {
      if (!is.numeric(prepared[[outcome]])) stop("aov requires a numeric outcome", call. = FALSE)
      if (length(unique(prepared[[grouping]])) < 2L) stop("aov requires at least two groups", call. = FALSE)
      model_data <- data.frame(outcome = prepared[[outcome]], group = factor(prepared[[grouping]]))
      model <- stats::aov(outcome ~ group, data = model_data)
      as_rlearnxr_evidence(model, labels = labels, seed = seed)
    },
    chi_square = {
      contingency <- table(prepared[[grouping]], prepared[[outcome]])
      if (any(dim(contingency) < 2L)) stop("chi_square requires at least two levels in both variables", call. = FALSE)
      model <- suppressWarnings(stats::chisq.test(contingency))
      as_rlearnxr_evidence(model, seed = seed)
    },
    prcomp = {
      model <- stats::prcomp(prepared[dimensions], center = TRUE, scale. = TRUE)
      as_rlearnxr_evidence(model, labels = labels, seed = seed)
    },
    lm = {
      model_data <- wizard_model_data(prepared, dimensions, outcome, binary = FALSE)
      model <- stats::lm(outcome ~ ., data = model_data)
      as_rlearnxr_evidence(model, labels = labels, seed = seed)
    },
    glm = {
      model_data <- wizard_model_data(prepared, dimensions, outcome, binary = TRUE)
      model <- stats::glm(outcome ~ ., data = model_data, family = stats::binomial())
      as_rlearnxr_evidence(model, labels = labels, seed = seed)
    },
    kmeans = {
      clusters <- as.integer(clusters)
      if (length(clusters) != 1L || is.na(clusters) || clusters < 2L || clusters >= nrow(prepared)) {
        stop("clusters must be at least 2 and smaller than the number of complete rows", call. = FALSE)
      }
      set.seed(as.integer(seed))
      scaled_data <- as.data.frame(scale(prepared[dimensions]))
      names(scaled_data) <- dimensions
      model <- stats::kmeans(scaled_data, centers = clusters, nstart = 25L)
      as_rlearnxr_evidence(model, data = scaled_data, dimensions = dimensions, labels = labels, seed = seed)
    }
  )

  source_code <- wizard_analysis_source(analysis, dimensions, outcome, seed, clusters, id_column, grouping, bootstrap_times)
  pedagogy <- analysis_teaching_contract(
    analysis, context, evidence, model, prepared, if (length(dimensions)) dimensions else grouping,
    outcome, seed, clusters
  )
  evidence$analysis$call <- paste(source_code, collapse = " ")
  evidence$metadata$wizard <- list(
    analysis = analysis,
    source_columns = dimensions,
    outcome = outcome,
    id_column = id_column,
    original_rows = nrow(data),
    compiled_rows = nrow(prepared),
    omitted_source_rows = setdiff(seq_len(nrow(data)), source_rows),
    na_action = na_action,
    context = context,
    generated_r_code = source_code
  )
  evidence$metadata$pedagogy <- pedagogy
  hash_payload <- unclass(evidence)
  hash_payload$analysis$artifact_hash <- NULL
  evidence$analysis$artifact_hash <- evidence_hash(hash_payload)
  validate_rlearnxr_evidence(evidence)

  if (is.null(id)) id <- lesson_id_from_title(title)
  if (is.null(outcomes)) outcomes <- pedagogy$outcomes
  stages <- match.arg(stages, rlearnxr_learning_stages(), several.ok = TRUE)
  stages <- rlearnxr_learning_stages()[rlearnxr_learning_stages() %in% stages]
  tasks <- lapply(stages, wizard_task_spec, analysis = analysis,
                  context = context, pedagogy = pedagogy)
  lesson <- lesson_spec(
    id = id,
    title = title,
    outcomes = outcomes,
    evidence = evidence,
    tasks = tasks
  )
  lesson$authoring <- list(
    method = "lesson_wizard",
    profile_schema = profile$schema_version,
    analysis_recommendations = profile$recommendations,
    warnings = profile$warnings,
    context = context,
    diagnostics = pedagogy$diagnostics,
    cautions = pedagogy$cautions,
    misconceptions = pedagogy$misconceptions
  )
  lesson
}

#' @export
print.rlearnxr_data_profile <- function(x, ...) {
  cat("<rlearnxr_data_profile>", x$rows, "rows x", nrow(x$columns), "columns\n")
  cat("Available adapters:", paste(x$recommendations$analysis[x$recommendations$available], collapse = ", "), "\n")
  cat("Warnings:", length(x$warnings), "\n")
  invisible(x)
}

#' @export
summary.rlearnxr_data_profile <- function(object, ...) {
  available <- object$recommendations[object$recommendations$available, , drop = FALSE]
  list(
    rows = object$rows,
    columns = nrow(object$columns),
    numeric_columns = sum(object$columns$type %in% c("integer", "numeric", "binary numeric")),
    missing_cells = sum(object$columns$missing),
    available_adapters = object$recommendations$analysis[object$recommendations$available],
    recommended_adapter = if (nrow(available)) recommended_analysis_id(object$recommendations) else NA_character_,
    warnings = object$warnings
  )
}

#' @export
as.data.frame.rlearnxr_data_profile <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$columns
}

#' Run the local Lesson Wizard
#'
#' The wizard reads data into the local R session, never sends data to an
#' external service, and compiles a portable lesson through `lesson_from_data()`.
#'
#' @param data Optional data frame loaded when the app starts.
#' @param output_dir Optional parent directory for compiled lessons.
#' @param host,port,launch.browser,quiet Passed to `shiny::runApp()`.
#' @return Runs a Shiny application. Called for its side effect.
#' @export
run_lesson_wizard <- function(data = NULL, output_dir = NULL,
                              host = "127.0.0.1", port = getOption("shiny.port"),
                              launch.browser = interactive(), quiet = FALSE) {
  app <- build_lesson_wizard_app(data = data, output_dir = output_dir)
  shiny::runApp(app, host = host, port = port, launch.browser = launch.browser, quiet = quiet)
}

build_lesson_wizard_app <- function(data = NULL, output_dir = NULL) {
  # The optional Shiny surface is exercised by browser_wizard_smoke_test.ps1.
  # nocov start
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The optional Lesson Wizard requires the 'shiny' package. Install it with install.packages('shiny').", call. = FALSE)
  }
  if (!is.null(data) && !is.data.frame(data)) stop("data must be a data.frame", call. = FALSE)
  if (!is.null(output_dir)) output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)

  app_ui <- shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$title("R-LearnXR Lesson Wizard"),
      shiny::tags$style(shiny::HTML(wizard_css()))
    ),
    shiny::tags$a(class = "wizard-skip", href = "#wizard-main", "Skip to lesson design"),
    shiny::div(class = "wizard-shell",
      shiny::tags$header(class = "wizard-header",
        shiny::div(class = "wizard-brand", shiny::span(class = "wizard-mark", "R"), "R-LearnXR"),
        shiny::h1("Turn a local dataset into an evidence lesson"),
        shiny::p("Inspect the data, approve an analysis, and compile an eight-stage learning experience. Your data stays in this R session.")
      ),
      shiny::tags$main(id = "wizard-main",
        shiny::div(class = "wizard-steps", role = "list", `aria-label` = "Lesson Wizard steps",
          wizard_step("1", "Add data", "Local CSV or built-in example", "active"),
          wizard_step("2", "Review fit", "Types, missingness, and method", ""),
          wizard_step("3", "Design lesson", "Variables and learning stages", ""),
          wizard_step("4", "Build", "Portable evidence artifacts", "")
        ),
        shiny::div(class = "wizard-layout",
          shiny::tags$section(class = "wizard-card wizard-source", `aria-labelledby` = "source-title",
            shiny::div(class = "wizard-card-heading", shiny::span(class = "eyebrow", "Step 1"), shiny::h2(id = "source-title", "Choose learner data")),
            shiny::fileInput("data_file", "Upload a CSV", accept = c("text/csv", ".csv"), buttonLabel = "Choose CSV", placeholder = "No file selected"),
            shiny::checkboxInput("header", "First row contains column names", TRUE),
            shiny::actionButton("use_example", "Use iris example", class = "btn-default wizard-secondary"),
            shiny::p(class = "wizard-privacy", shiny::strong("Local by design."), " The wizard does not call an external analytics or AI service."),
            shiny::uiOutput("data_status")
          ),
          shiny::div(class = "wizard-workspace",
            shiny::tags$section(class = "wizard-card", `aria-labelledby` = "profile-title",
              shiny::div(class = "wizard-card-heading", shiny::span(class = "eyebrow", "Step 2"), shiny::h2(id = "profile-title", "Review the data fit")),
              shiny::uiOutput("profile_summary"),
              shiny::div(class = "wizard-table-wrap", shiny::tableOutput("column_profile")),
              shiny::uiOutput("profile_warnings"),
              shiny::div(class = "wizard-table-wrap", shiny::tableOutput("analysis_recommendations"))
            ),
            shiny::tags$section(class = "wizard-card", `aria-labelledby` = "design-title",
              shiny::div(class = "wizard-card-heading", shiny::span(class = "eyebrow", "Step 3"), shiny::h2(id = "design-title", "Design the lesson")),
              shiny::div(class = "wizard-form-grid",
                shiny::textInput("lesson_title", "Lesson title", value = "My data evidence lesson", width = "100%"),
                shiny::selectInput(
                  "intent", "Analytical learning goal",
                  choices = stats::setNames(names(learning_intents()), unname(learning_intents())),
                  selected = "explore", selectize = FALSE
                ),
                shiny::div(class = "wizard-form-wide", shiny::textAreaInput(
                  "question", "Educational or analytical question",
                  value = "What pattern in these data is worth explaining?", rows = 2, width = "100%"
                )),
                shiny::div(class = "wizard-form-wide", shiny::textInput(
                  "unit_of_analysis", "What does one row represent?",
                  value = "one observation in the supplied data", width = "100%"
                )),
                shiny::selectInput("outcome", "Outcome variable", choices = c("Add data first" = ""), selected = "", selectize = FALSE),
                shiny::selectInput("grouping", "Grouping or nesting variable", choices = c("None" = ""), selected = "", selectize = FALSE),
                shiny::selectInput("time", "Time or sequence variable", choices = c("None" = ""), selected = "", selectize = FALSE),
                shiny::selectInput("analysis", "Analysis adapter", choices = c("Add data first" = ""), selected = "", selectize = FALSE),
                shiny::selectInput("id_column", "Observation label", choices = c("Generated labels" = ""), selected = "", selectize = FALSE),
                shiny::selectizeInput("dimensions", "Numeric dimensions or predictors", choices = character(), selected = character(), multiple = TRUE),
                shiny::numericInput("seed", "Reproducibility seed", value = 2026, min = 1, step = 1),
                shiny::conditionalPanel("input.analysis == 'kmeans'", shiny::numericInput("clusters", "Number of clusters", value = 3, min = 2, step = 1)),
                shiny::selectInput("na_action", "Missing-value rule", choices = c("Stop and review" = "fail", "Use complete rows" = "complete"), selected = "fail"),
                shiny::div(class = "wizard-form-wide", shiny::textAreaInput(
                  "decision_context", "How will this evidence be used?",
                  value = "learning and interpretation, not automated decisions", rows = 2, width = "100%"
                ))
              ),
              shiny::checkboxGroupInput(
                "stages", "Learning stages",
                choices = stats::setNames(rlearnxr_learning_stages(), wizard_stage_labels()),
                selected = rlearnxr_learning_stages(), inline = TRUE
              ),
              shiny::actionButton("preview_lesson", "Review lesson plan", class = "btn-primary wizard-primary"),
              shiny::uiOutput("lesson_preview")
            ),
            shiny::tags$section(class = "wizard-card wizard-build", `aria-labelledby` = "build-title",
              shiny::div(class = "wizard-card-heading", shiny::span(class = "eyebrow", "Step 4"), shiny::h2(id = "build-title", "Compile and inspect")),
              shiny::p(class = "wizard-muted", "The compiler writes Evidence IR, a semantic table, Quarto source, the interactive scene, and reproducibility checks from one R object."),
              shiny::actionButton("build_lesson", "Build portable lesson", class = "btn-primary wizard-primary"),
              shiny::uiOutput("build_result")
            )
          )
        )
      )
    )
  )

  app_server <- function(input, output, session) {
    current_data <- shiny::reactiveVal(data)
    current_name <- shiny::reactiveVal(if (is.null(data)) NULL else "Provided R data frame")
    preview_value <- shiny::reactiveVal(NULL)
    build_value <- shiny::reactiveVal(NULL)
    resource_alias <- paste0("rlearnxr-wizard-", gsub("[^A-Za-z0-9]", "", session$token))

    session$onSessionEnded(function() {
      try(shiny::removeResourcePath(resource_alias), silent = TRUE)
    })

    shiny::observeEvent(input$data_file, {
      value <- tryCatch(
        utils::read.csv(input$data_file$datapath, header = isTRUE(input$header), stringsAsFactors = FALSE, check.names = FALSE),
        error = function(error) error
      )
      if (inherits(value, "error")) {
        shiny::showNotification(conditionMessage(value), type = "error")
      } else {
        current_data(value)
        current_name(input$data_file$name)
        preview_value(NULL)
        build_value(NULL)
      }
    })

    shiny::observeEvent(input$use_example, {
      current_data(datasets::iris)
      current_name("iris built-in example")
      preview_value(NULL)
      build_value(NULL)
    })

    profile <- shiny::reactive({
      shiny::req(current_data())
      profile_learning_data(
        current_data(), outcome = null_if_empty(input$outcome),
        intent = null_if_empty(input$intent) %||% "explore",
        grouping = null_if_empty(input$grouping), time = null_if_empty(input$time)
      )
    })

    active_recommendations <- shiny::reactive({
      shiny::req(current_data())
      recommend_lesson_analysis(
        current_data(), outcome = null_if_empty(input$outcome),
        intent = null_if_empty(input$intent) %||% "explore",
        grouping = null_if_empty(input$grouping), time = null_if_empty(input$time)
      )
    })

    output$data_status <- shiny::renderUI({
      if (is.null(current_data())) return(shiny::div(class = "wizard-empty", "Add a CSV to begin. No analysis has been selected."))
      shiny::div(class = "wizard-ready", shiny::span(`aria-hidden` = "true", "\u2713"), paste(current_name(), "is ready."))
    })

    output$profile_summary <- shiny::renderUI({
      if (is.null(current_data())) return(shiny::p(class = "wizard-empty", "The variable profile will appear after data are added."))
      value <- profile()
      numeric_count <- sum(value$columns$type %in% c("integer", "numeric", "binary numeric"))
      shiny::div(class = "wizard-metrics",
        wizard_metric(format(value$rows, big.mark = ","), "Rows"),
        wizard_metric(nrow(value$columns), "Columns"),
        wizard_metric(numeric_count, "Numeric"),
        wizard_metric(sum(value$columns$missing), "Missing cells")
      )
    })

    output$column_profile <- shiny::renderTable({
      shiny::req(current_data())
      value <- profile()$columns
      data.frame(
        Variable = value$column,
        Type = value$type,
        Missing = paste0(value$missing, " (", value$missing_percent, "%)"),
        Distinct = value$distinct,
        Role = value$role,
        Review = ifelse(value$possible_identifier, "Possible identifier", ifelse(value$constant, "Constant", "Ready")),
        check.names = FALSE
      )
    }, striped = FALSE, bordered = FALSE, spacing = "s", rownames = FALSE)

    output$profile_warnings <- shiny::renderUI({
      shiny::req(current_data())
      warnings <- profile()$warnings
      if (!length(warnings)) return(shiny::div(class = "wizard-note wizard-note-success", "No structural data warnings detected."))
      shiny::div(class = "wizard-note", shiny::strong("Review before building"), shiny::tags$ul(lapply(warnings, shiny::tags$li)))
    })

    output$analysis_recommendations <- shiny::renderTable({
      shiny::req(current_data())
      value <- active_recommendations()
      data.frame(
        Method = value$label,
        Status = ifelse(value$available, ifelse(value$recommended, "Recommended", "Available"), "Unavailable"),
        Why = value$reason,
        Check = value$caution,
        check.names = FALSE
      )
    }, striped = FALSE, bordered = FALSE, spacing = "s", rownames = FALSE)

    shiny::observeEvent(current_data(), {
      shiny::req(current_data())
      value <- current_data()
      available <- profile()$recommendations
      available <- available[available$available, , drop = FALSE]
      numeric_columns <- names(value)[vapply(value, is.numeric, logical(1))]
      title <- paste(tools::toTitleCase(gsub("[-_]", " ", tools::file_path_sans_ext(current_name() %||% "my data"))), "evidence lesson")
      shiny::updateTextInput(session, "lesson_title", value = title)
      shiny::updateSelectInput(session, "outcome", choices = c("None" = "", names(value)))
      shiny::updateSelectInput(session, "grouping", choices = c("None" = "", names(value)), selected = "")
      shiny::updateSelectInput(session, "time", choices = c("None" = "", names(value)), selected = "")
      shiny::updateSelectInput(session, "id_column", choices = c("Generated labels" = "", names(value)), selected = "")
      shiny::updateSelectInput(
        session, "analysis", choices = stats::setNames(available$analysis, available$label),
        selected = recommended_analysis_id(available)
      )
      shiny::updateSelectizeInput(
        session, "dimensions", choices = numeric_columns,
        selected = numeric_columns, server = FALSE
      )
    }, ignoreInit = FALSE)

    shiny::observeEvent(list(current_data(), input$outcome, input$intent, input$grouping, input$time), {
      shiny::req(current_data(), !is.null(input$outcome), input$analysis, input$dimensions, input$intent)
      recommendations <- recommend_lesson_analysis(
        current_data(), outcome = null_if_empty(input$outcome), intent = input$intent,
        grouping = null_if_empty(input$grouping), time = null_if_empty(input$time)
      )
      available <- recommendations[recommendations$available, , drop = FALSE]
      numeric_columns <- names(current_data())[vapply(current_data(), is.numeric, logical(1))]
      numeric_columns <- setdiff(numeric_columns, c(
        null_if_empty(input$outcome), null_if_empty(input$grouping), null_if_empty(input$time)
      ))
      shiny::updateSelectInput(
        session, "analysis",
        choices = stats::setNames(available$analysis, available$label),
        selected = recommended_analysis_id(available)
      )
      shiny::updateSelectizeInput(
        session, "dimensions", choices = numeric_columns,
        selected = numeric_columns, server = FALSE
      )
    }, ignoreInit = FALSE)

    create_lesson <- function() {
      shiny::req(current_data(), input$analysis, input$lesson_title, input$question,
                 input$unit_of_analysis, input$dimensions, input$stages)
      lesson_from_data(
        current_data(), analysis = input$analysis, dimensions = input$dimensions,
        outcome = null_if_empty(input$outcome), id_column = null_if_empty(input$id_column),
        question = input$question, intent = input$intent,
        unit_of_analysis = input$unit_of_analysis,
        grouping = null_if_empty(input$grouping), time = null_if_empty(input$time),
        decision_context = input$decision_context,
        title = input$lesson_title, seed = input$seed,
        clusters = input$clusters %||% 3L, na_action = input$na_action,
        stages = input$stages
      )
    }

    shiny::observeEvent(input$preview_lesson, {
      value <- tryCatch(create_lesson(), error = function(error) error)
      preview_value(value)
      if (inherits(value, "error")) shiny::showNotification(conditionMessage(value), type = "error")
    })

    output$lesson_preview <- shiny::renderUI({
      value <- preview_value()
      if (is.null(value)) return(NULL)
      if (inherits(value, "error")) return(shiny::div(class = "wizard-note wizard-note-error", conditionMessage(value)))
      task_types <- vapply(value$tasks, `[[`, character(1), "type")
      shiny::div(class = "wizard-preview",
        shiny::div(class = "wizard-ready", shiny::span(`aria-hidden` = "true", "\u2713"), "Lesson contract is valid."),
        shiny::h3(value$title),
        shiny::p(shiny::strong("Question: "), value$evidence$metadata$pedagogy$question),
        shiny::p(shiny::strong("Evidence adapter: "), value$evidence$analysis$engine),
        shiny::p(shiny::strong("Evidence hash: "), shiny::tags$code(value$evidence$analysis$artifact_hash)),
        shiny::div(class = "wizard-stage-pills", lapply(wizard_stage_labels(task_types), function(label) shiny::span(label))),
        shiny::tags$details(
          shiny::tags$summary("Inspect method-specific diagnostics and cautions"),
          shiny::tags$ul(lapply(value$evidence$metadata$pedagogy$diagnostics, function(item) {
            shiny::tags$li(shiny::strong(paste0(item$label, ": ")), item$value, " ", item$interpretation)
          })),
          shiny::tags$ul(lapply(value$evidence$metadata$pedagogy$cautions, shiny::tags$li))
        ),
        shiny::tags$details(shiny::tags$summary("Inspect generated R code"), shiny::pre(paste(value$evidence$metadata$wizard$generated_r_code, collapse = "\n")))
      )
    })

    shiny::observeEvent(input$build_lesson, {
      lesson <- tryCatch(create_lesson(), error = function(error) error)
      if (inherits(lesson, "error")) {
        build_value(lesson)
        shiny::showNotification(conditionMessage(lesson), type = "error")
        return()
      }
      parent <- output_dir %||% file.path(tempdir(), "rlearnxr-wizard-builds")
      path <- file.path(parent, lesson$id)
      value <- tryCatch(compile_lesson(lesson, path, overwrite = TRUE), error = function(error) error)
      if (!inherits(value, "error")) {
        try(shiny::removeResourcePath(resource_alias), silent = TRUE)
        shiny::addResourcePath(resource_alias, value$output_dir)
      }
      build_value(value)
    })

    output$build_result <- shiny::renderUI({
      value <- build_value()
      if (is.null(value)) return(shiny::div(class = "wizard-empty", "Review the lesson plan, then build the portable artifacts."))
      if (inherits(value, "error")) return(shiny::div(class = "wizard-note wizard-note-error", conditionMessage(value)))
      failed <- sum(value$checks$status == "FAIL")
      shiny::div(class = "wizard-build-result",
        shiny::div(class = if (failed) "wizard-note wizard-note-error" else "wizard-note wizard-note-success",
          if (failed) paste(failed, "compiler checks need attention.") else "Build complete. All compiler checks passed."
        ),
        shiny::div(class = "wizard-metrics",
          wizard_metric(length(value$files), "Artifacts"),
          wizard_metric(sum(value$checks$status == "PASS"), "Checks passed"),
          wizard_metric(sum(value$checks$status == "WARN"), "Warnings"),
          wizard_metric(sum(value$checks$status == "FAIL"), "Failures")
        ),
        shiny::p(class = "wizard-path", value$output_dir),
        shiny::tags$a(class = "btn btn-primary wizard-primary", href = paste0("/", resource_alias, "/scene/index.html"), target = "_blank", rel = "noopener", "Open learner lesson")
      )
    })
  }

  shiny::shinyApp(ui = app_ui, server = app_server)
  # nocov end
}

learning_column_type <- function(value) {
  distinct <- unique(value[!is.na(value)])
  if (is.logical(value)) return("binary logical")
  if (is.numeric(value) && length(distinct) == 2L) return("binary numeric")
  if (is.integer(value)) return("integer")
  if (is.numeric(value)) return("numeric")
  if (inherits(value, c("Date", "POSIXct", "POSIXlt"))) return("date/time")
  if (is.factor(value) || length(distinct) <= 12L) return("categorical")
  "text"
}

lesson_analysis_recommendations <- function(data, outcome = NULL,
                                             intent = "explore",
                                             grouping = NULL, time = NULL) {
  intent <- match.arg(intent, names(learning_intents()))
  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  numeric_predictors <- setdiff(numeric_columns, c(outcome, grouping, time))
  variable_numeric <- numeric_columns[vapply(data[numeric_columns], function(value) length(unique(value[!is.na(value)])) > 1L, logical(1))]
  variable_predictors <- setdiff(variable_numeric, c(outcome, grouping, time))
  complete_numeric <- if (length(variable_predictors)) sum(stats::complete.cases(data[variable_predictors])) else 0L
  outcome_exists <- !is.null(outcome) && outcome %in% names(data)
  outcome_levels <- if (outcome_exists) length(unique(data[[outcome]][!is.na(data[[outcome]])])) else 0L
  outcome_binary <- outcome_exists && outcome_levels == 2L
  outcome_numeric <- outcome_exists && is.numeric(data[[outcome]]) && !outcome_binary
  grouping_exists <- !is.null(grouping) && grouping %in% names(data)
  grouping_levels <- if (grouping_exists) length(unique(data[[grouping]][!is.na(data[[grouping]])])) else 0L

  available <- c(
    describe = length(variable_predictors) >= 1L,
    data_view = length(variable_predictors) >= 2L,
    correlation = length(variable_predictors) >= 2L && complete_numeric >= 3L,
    bootstrap = length(variable_predictors) >= 1L && complete_numeric >= 5L,
    t_test = outcome_numeric && grouping_levels == 2L,
    aov = outcome_numeric && grouping_levels >= 2L,
    chi_square = outcome_exists && grouping_levels >= 2L && grouping_levels <= 12L &&
      outcome_levels >= 2L && outcome_levels <= 12L,
    prcomp = length(variable_predictors) >= 2L && complete_numeric >= 3L,
    lm = outcome_numeric && length(numeric_predictors) >= 1L,
    glm = outcome_binary && length(numeric_predictors) >= 1L,
    kmeans = length(variable_predictors) >= 2L && complete_numeric >= 4L
  )
  recommended <- rep(FALSE, length(available))
  names(recommended) <- names(available)
  dependence <- !is.null(grouping) || !is.null(time)
  target <- switch(
    intent,
    explore = if (available[["data_view"]]) "data_view" else "describe",
    describe = "describe",
    compare = if (available[["aov"]]) "aov" else if (available[["data_view"]]) "data_view" else "describe",
    infer = "bootstrap",
    reduce = "prcomp",
    explain = if (outcome_numeric && !dependence) "lm" else "data_view",
    classify = if (outcome_binary && !dependence) "glm" else "data_view",
    cluster = "kmeans"
  )
  if (isTRUE(available[[target]])) recommended[[target]] <- TRUE
  if (!any(recommended) && isTRUE(available[["data_view"]])) recommended[["data_view"]] <- TRUE
  if (!any(recommended) && isTRUE(available[["describe"]])) recommended[["describe"]] <- TRUE
  label <- c(
    describe = "Describe one numeric variable", data_view = "Explore numeric dimensions",
    correlation = "Correlation with paired evidence", bootstrap = "Bootstrap a sample mean",
    t_test = "Compare two group means", aov = "Analysis of variance",
    chi_square = "Chi-square association", prcomp = "Principal component analysis",
    lm = "Linear regression", glm = "Binary logistic regression", kmeans = "K-means clustering"
  )
  reason <- c(
    describe = if (available[["describe"]]) "Starts with center, spread, percentile, and distribution evidence for one numeric variable." else "Requires one varying numeric column.",
    data_view = if (available[["data_view"]]) "Safest starting point for describing observations without adding a model." else "Requires at least two varying numeric columns.",
    correlation = if (available[["correlation"]]) "Connects a correlation estimate to the paired observations that produced it." else "Requires two varying numeric columns and three complete pairs.",
    bootstrap = if (available[["bootstrap"]]) "Uses resampled means to make sampling variability and interval interpretation visible." else "Requires one varying numeric column and at least five complete rows.",
    t_test = if (available[["t_test"]]) "Compares a numeric outcome across exactly two declared groups." else "Select a numeric outcome and a grouping variable with exactly two levels.",
    aov = if (available[["aov"]]) "Partitions numeric outcome variation across the declared groups." else "Select a numeric outcome and a grouping variable with at least two levels.",
    chi_square = if (available[["chi_square"]]) "Compares observed and expected counts for two categorical variables." else "Select categorical outcome and grouping variables with at least two levels each.",
    prcomp = if (available[["prcomp"]]) "Available when the question is about summarizing shared variation across numeric variables." else "Requires at least two varying numeric columns and three complete rows.",
    lm = if (available[["lm"]]) paste0("Available for a numeric outcome", if (dependence) "; not recommended because grouped or repeated observations were declared." else ".") else "Select a non-binary numeric outcome and at least one numeric predictor.",
    glm = if (available[["glm"]]) paste0("Available for a two-level outcome", if (dependence) "; not recommended because grouped or repeated observations were declared." else ".") else "Select a two-level outcome and at least one numeric predictor.",
    kmeans = if (available[["kmeans"]]) "Available when the question is explicitly about tentative groups in standardized numeric data." else "Requires at least two varying numeric columns and four complete rows."
  )
  caution <- c(
    describe = "A sample summary describes retained observations; it does not establish a population value.",
    data_view = "Describe patterns only; visible proximity does not establish causation.",
    correlation = "Correlation measures paired association, not causation; inspect form, outliers, and dependence.",
    bootstrap = "A bootstrap interval reflects the observed sample and resampling rule, not every source of uncertainty.",
    t_test = "Interpret the mean difference with its interval, assumptions, design, and practical importance.",
    aov = "A significant omnibus F test does not identify which groups differ or establish causation.",
    chi_square = "Inspect expected counts and standardized residuals; association does not establish causation.",
    prcomp = "PCA summarizes variance and requires score, loading, scaling, and variance evidence.",
    lm = if (dependence) "Use a grouped or longitudinal model for inferential work." else "Check residuals, influence, independence, and uncertainty.",
    glm = if (dependence) "Use a grouped or longitudinal model for inferential work." else "Declare the modeled event, reference level, class balance, and threshold.",
    kmeans = "Scale variables, use multiple starts, and check whether conclusions change across k or seed."
  )
  data.frame(
    analysis = names(available), label = unname(label[names(available)]),
    available = unname(available), recommended = unname(recommended),
    reason = unname(reason[names(available)]),
    caution = unname(caution[names(available)]),
    intent = intent,
    stringsAsFactors = FALSE
  )
}

recommended_analysis_id <- function(recommendations) {
  available <- recommendations[recommendations$available, , drop = FALSE]
  if (!nrow(available)) stop("no supported analysis is available for these data", call. = FALSE)
  recommended <- available$analysis[available$recommended]
  if (length(recommended)) recommended[[1]] else available$analysis[[1]]
}

wizard_observation_labels <- function(data, id_column, source_rows) {
  if (is.null(id_column)) return(sprintf("observation-%04d", source_rows))
  labels <- as.character(data[[id_column]])
  if (anyNA(labels) || any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    stop("id_column values must be non-empty and unique", call. = FALSE)
  }
  labels
}

wizard_model_data <- function(data, dimensions, outcome, binary = FALSE) {
  value <- data.frame(outcome = data[[outcome]], data[dimensions], check.names = TRUE)
  names(value) <- make.names(c("outcome", dimensions), unique = TRUE)
  names(value)[[1]] <- "outcome"
  if (binary) {
    levels <- sort(unique(as.character(value$outcome)))
    value$outcome <- factor(as.character(value$outcome), levels = levels)
  } else {
    if (!is.numeric(value$outcome)) stop("linear regression requires a numeric outcome", call. = FALSE)
    value$outcome <- as.numeric(value$outcome)
  }
  value
}

wizard_analysis_source <- function(analysis, dimensions, outcome, seed, clusters,
                                   id_column = NULL, grouping = NULL,
                                   bootstrap_times = 1000L) {
  quoted_dimensions <- paste(sprintf('"%s"', gsub('"', '\\"', dimensions, fixed = TRUE)), collapse = ", ")
  analysis_columns <- unique(c(dimensions, outcome, id_column, grouping))
  quoted_columns <- paste(sprintf('"%s"', gsub('"', '\\"', analysis_columns, fixed = TRUE)), collapse = ", ")
  header <- c(
    paste0("set.seed(", as.integer(seed), ")"),
    "# learner_data is the local CSV data frame",
    paste0("analysis_columns <- c(", quoted_columns, ")"),
    "source_rows <- which(complete.cases(learner_data[analysis_columns]))",
    "analysis_data <- learner_data[source_rows, analysis_columns, drop = FALSE]",
    if (is.null(id_column)) {
      'labels <- sprintf("observation-%04d", source_rows)'
    } else {
      paste0('labels <- as.character(analysis_data[["', gsub('"', '\\"', id_column, fixed = TRUE), '"]])')
    }
  )
  quoted_outcome <- if (is.null(outcome)) "" else gsub('"', '\\"', outcome, fixed = TRUE)
  code <- switch(
    analysis,
    describe = paste0('evidence <- as_rlearnxr_evidence(analysis_data[["', dimensions[[1]], '"]], labels = labels, variable = "', dimensions[[1]], '")'),
    data_view = paste0("evidence <- as_rlearnxr_evidence(analysis_data[c(", quoted_dimensions, ")], dimensions = c(", quoted_dimensions, "), labels = labels)"),
    correlation = c(
      paste0('fit <- cor.test(analysis_data[["', dimensions[[1]], '"]], analysis_data[["', dimensions[[2]], '"]])'),
      paste0('evidence <- as_rlearnxr_evidence(fit, data = analysis_data, x_column = "', dimensions[[1]], '", y_column = "', dimensions[[2]], '", labels = labels)')
    ),
    bootstrap = c(
      paste0('fit <- bootstrap_mean(analysis_data[["', dimensions[[1]], '"]], times = ', as.integer(bootstrap_times), ', seed = ', as.integer(seed), ')'),
      "evidence <- as_rlearnxr_evidence(fit)"
    ),
    t_test = c(
      paste0('analysis_data[["', grouping, '"]] <- factor(analysis_data[["', grouping, '"]])'),
      paste0('fit <- t.test(analysis_data[["', outcome, '"]] ~ analysis_data[["', grouping, '"]])'),
      paste0('evidence <- as_rlearnxr_evidence(fit, data = analysis_data, x_column = "', outcome, '", group = "', grouping, '", labels = labels)')
    ),
    aov = c(
      paste0('analysis_data[["', grouping, '"]] <- factor(analysis_data[["', grouping, '"]])'),
      paste0('fit <- aov(reformulate("', grouping, '", response = "', outcome, '"), data = analysis_data)'),
      "evidence <- as_rlearnxr_evidence(fit, labels = labels)"
    ),
    chi_square = c(
      paste0('contingency <- table(analysis_data[["', grouping, '"]], analysis_data[["', outcome, '"]])'),
      "fit <- suppressWarnings(chisq.test(contingency))",
      "evidence <- as_rlearnxr_evidence(fit)"
    ),
    prcomp = c(paste0("fit <- prcomp(analysis_data[c(", quoted_dimensions, ")], center = TRUE, scale. = TRUE)"), "evidence <- as_rlearnxr_evidence(fit, labels = labels)"),
    lm = c(
      paste0('fit <- lm(reformulate(c(', quoted_dimensions, '), response = "', quoted_outcome, '"), data = analysis_data)'),
      "evidence <- as_rlearnxr_evidence(fit, labels = labels)"
    ),
    glm = c(
      paste0('analysis_data[["', quoted_outcome, '"]] <- factor(as.character(analysis_data[["', quoted_outcome, '"]]), levels = sort(unique(as.character(analysis_data[["', quoted_outcome, '"]]))) )'),
      paste0('fit <- glm(reformulate(c(', quoted_dimensions, '), response = "', quoted_outcome, '"), data = analysis_data, family = binomial())'),
      "evidence <- as_rlearnxr_evidence(fit, labels = labels)"
    ),
    kmeans = c(
      paste0("scaled_data <- as.data.frame(scale(analysis_data[c(", quoted_dimensions, ")]))"),
      paste0("fit <- kmeans(scaled_data, centers = ", as.integer(clusters), ", nstart = 25)"),
      "evidence <- as_rlearnxr_evidence(fit, data = scaled_data, labels = labels)"
    )
  )
  c(header, code)
}

rlearnxr_learning_stages <- function() {
  c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
}

wizard_stage_labels <- function(stages = rlearnxr_learning_stages()) {
  labels <- c(orient = "Orient", predict = "Predict", run_r = "Run R", explore = "Explore", explain = "Explain", repair = "Repair", transfer = "Transfer", reproduce = "Reproduce")
  unname(labels[stages])
}

wizard_task_spec <- function(stage, analysis, context, pedagogy) {
  prompts <- pedagogy$prompts
  criteria <- pedagogy$criteria[[stage]] %||% character()
  task_spec(
    id = paste0("wizard-", stage), type = stage, prompt = prompts[[stage]],
    criteria = criteria, evidence_required = stage %in% c("explore", "explain", "repair", "transfer")
  )
}

wizard_outcomes <- function(analysis) {
  c(
    paste0("Interpret evidence produced by the ", analysis, " adapter"),
    "Explain a claim using stable observation and evidence identifiers",
    "Repair and transfer an interpretation while preserving reproducibility"
  )
}

lesson_id_from_title <- function(title) {
  assert_scalar_text(title, "title")
  value <- tolower(trimws(title))
  value <- gsub("[^a-z0-9]+", "-", value)
  value <- gsub("(^-+|-+$)", "", value)
  if (!nzchar(value)) value <- "wizard-lesson"
  substr(value, 1L, 64L)
}

null_if_empty <- function(value) {
  if (is.null(value) || length(value) != 1L || is.na(value) || !nzchar(value)) NULL else value
}

# Browser-only HTML helpers are covered by the Lesson Wizard E2E test.
# nocov start
wizard_step <- function(number, title, copy, state) {
  shiny::div(class = paste("wizard-step", state), role = "listitem",
    shiny::span(class = "wizard-step-number", number),
    shiny::div(shiny::strong(title), shiny::span(copy))
  )
}

wizard_metric <- function(value, label) {
  shiny::div(class = "wizard-metric", shiny::strong(value), shiny::span(label))
}

wizard_css <- function() {
  paste(readLines(wizard_template_path(), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

wizard_template_path <- function() {
  roots <- unique(c(RLEARNXR_SOURCE_ROOT, normalizePath(".", winslash = "/", mustWork = TRUE)))
  candidates <- file.path(roots, "inst", "templates", "wizard.css")
  found <- candidates[file.exists(candidates)][1]
  if (length(found) && !is.na(found)) return(found)
  installed <- system.file("templates", "wizard.css", package = "rlearnxr")
  if (nzchar(installed)) return(installed)
  stop("R-LearnXR Lesson Wizard stylesheet was not found", call. = FALSE)
}
# nocov end
