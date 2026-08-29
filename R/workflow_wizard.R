#' Run the local role-adaptive Workflow Wizard
#'
#' The wizard imports public tabular data into the local R process, requires
#' explicit approval of question, variable roles, method, and missing-value
#' handling, and then compiles a portable role workspace.
#'
#' @param output_dir Default parent directory for compiled workflows.
#' @param host,port,launch.browser,quiet Passed to `shiny::runApp()`.
#' @return Runs a Shiny app for its side effect.
#' @export
run_workflow_wizard <- function(output_dir = file.path(getwd(), "rclaimlab-workflows"),
                                host = "127.0.0.1", port = getOption("shiny.port"),
                                launch.browser = interactive(), quiet = FALSE) {
  app <- build_workflow_wizard_app(output_dir)
  shiny::runApp(app, host = host, port = port, launch.browser = launch.browser, quiet = quiet)
}

build_workflow_wizard_app <- function(output_dir) {
  # nocov start
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The Workflow Wizard requires the optional 'shiny' package", call. = FALSE)
  }
  screen <- function(step, eyebrow, title, subtitle, body, footer = NULL) {
    shiny::conditionalPanel(
      condition = sprintf("output.current_step == %d", step),
      shiny::tags$section(
        class = "rw-screen", `data-storyboard-scene` = sprintf("%02d", step),
        shiny::tags$header(class = "rw-screen-head",
          shiny::tags$span(class = "rw-eyebrow", eyebrow),
          shiny::tags$h1(title), shiny::tags$p(subtitle)
        ),
        shiny::tags$div(class = "rw-screen-body", body),
        if (!is.null(footer)) shiny::tags$footer(class = "rw-screen-footer", footer)
      )
    )
  }
  back_button <- function(id) shiny::actionButton(id, "Back", class = "rw-button rw-button-secondary")
  next_button <- function(id, label) shiny::actionButton(id, label, class = "rw-button rw-button-primary")
  choice_copy <- function(icon, title, description) {
    shiny::tags$span(class = "rw-choice-copy",
      shiny::tags$span(class = "rw-choice-icon", `aria-hidden` = "true", shiny::icon(icon)),
      shiny::tags$span(class = "rw-choice-text", shiny::tags$strong(title), shiny::tags$small(description))
    )
  }
  summary_cell <- function(label, value, icon) shiny::tags$div(
    shiny::tags$span(class = "rw-summary-icon", `aria-hidden` = "true", shiny::icon(icon)),
    shiny::tags$span(label), shiny::tags$strong(value)
  )

  ui <- shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      shiny::tags$style(shiny::HTML(workflow_wizard_css())),
      shiny::tags$script(shiny::HTML(
        "Shiny.addCustomMessageHandler('rclaimlab-step', function(message) { var ids = ['nav_data','nav_question','nav_workflow','nav_evidence']; ids.forEach(function(id) { var node = document.getElementById(id); if (node) node.classList.toggle('active', id === message.phase); }); });"
      ))
    ),
    shiny::tags$a(class = "rw-skip", href = "#rw-main", "Skip to current step"),
    shiny::tags$header(class = "rw-topbar",
      shiny::tags$div(class = "rw-brand", shiny::tags$span("R"), shiny::tags$div(shiny::tags$strong("R-ClaimLab"), shiny::tags$small("Progressive workflow builder"))),
      shiny::tags$div(class = "rw-local", "Local / no telemetry")
    ),
    shiny::tags$div(class = "rw-app",
      shiny::tags$aside(class = "rw-rail", `aria-label` = "Authoring progress",
        shiny::tags$div(class = "rw-rail-head", shiny::tags$span(class = "rw-eyebrow", "Build workflow"), shiny::tags$h2("Four calm phases"), shiny::tags$p("One decision at a time")),
        shiny::tags$nav(class = "rw-phase-list",
          shiny::tags$a(id = "nav_data", href = "#", role = "button", class = "rw-phase active action-button shiny-bound-input", shiny::tags$span("01"), shiny::tags$strong("Data"), shiny::tags$small("Purpose, source, profile")),
          shiny::tags$a(id = "nav_question", href = "#", role = "button", class = "rw-phase action-button shiny-bound-input", shiny::tags$span("02"), shiny::tags$strong("Question"), shiny::tags$small("Goal and variable roles")),
          shiny::tags$a(id = "nav_workflow", href = "#", role = "button", class = "rw-phase action-button shiny-bound-input", shiny::tags$span("03"), shiny::tags$strong("Workflow"), shiny::tags$small("Role, method, activities")),
          shiny::tags$a(id = "nav_evidence", href = "#", role = "button", class = "rw-phase action-button shiny-bound-input", shiny::tags$span("04"), shiny::tags$strong("Evidence"), shiny::tags$small("Run, receipt, handoff"))
        ),
        shiny::tags$div(class = "rw-rail-note", shiny::tags$strong("Nothing runs until approval"), shiny::tags$p("Source choices, transformations, variable roles, and methods remain reviewable."))
      ),
      shiny::tags$main(id = "rw-main", class = "rw-main",
        screen(1, "Start with a purpose", "What do you want to do today?",
          "Choose the outcome first. R-ClaimLab reveals only the controls needed for that path.",
          shiny::tags$div(class = "rw-purpose-layout",
            shiny::tags$div(class = "rw-purpose-main",
              shiny::tags$div(class = "rw-purpose-options",
                shiny::radioButtons("purpose", NULL, selected = "build", inline = TRUE,
                  choiceNames = list(
                    choice_copy("graduation-cap", "Learn with a guided lesson", "Follow a step-by-step lesson with example data."),
                    choice_copy("database", "Build from my data", "Import or connect a dataset and create a workflow."),
                    choice_copy("shield-halved", "Review an existing workflow", "Trace evidence, challenge claims, and approve limits.")
                  ),
                  choiceValues = c("guided", "build", "review"))
              ),
              shiny::uiOutput("purpose_detail"),
              shiny::tags$section(class = "rw-recent-placeholder", shiny::tags$h2("Continue recent work"), shiny::tags$p("Your saved local workflows will appear here. No recent work yet."))
            ),
            shiny::tags$section(class = "rw-output-preview", shiny::tags$h2("What you will get"),
              shiny::tags$div(summary_cell("Evidence", "Evidence-linked analysis", "chart-line"), summary_cell("Communication", "Role-ready report", "file-lines"), summary_cell("Reproducibility", "Workflow receipt", "shield")))
          ),
          shiny::tagList(shiny::tags$span(class = "rw-footer-note", "Your choice can be changed before analysis."), next_button("wizard_next_1", "Choose data source"))
        ),
        screen(2, "Data / Source", "Bring data in safely", "Choose one source. Preview, license, and privacy checks happen before import.",
          shiny::tagList(
            shiny::tags$div(class = "rw-source-options", shiny::radioButtons("provider", NULL, selected = "local", inline = TRUE,
              choiceNames = list(
                choice_copy("file-csv", "Local file", "CSV, TSV, or Parquet"),
                choice_copy("cloud-arrow-down", "Hugging Face", "Pinned public dataset"),
                choice_copy("terminal", "Kaggle", "Official CLI connection")
              ),
              choiceValues = c("local", "huggingface", "kaggle"))),
            shiny::tags$div(class = "rw-source-panel",
              shiny::conditionalPanel("input.provider == 'local'", shiny::fileInput("local_file", "Drop a CSV, TSV, or Parquet file", accept = c(".csv", ".tsv", ".parquet"))),
              shiny::conditionalPanel("input.provider != 'local'",
                shiny::textInput("dataset_id", "Dataset ID", placeholder = "owner/dataset"),
                shiny::textInput("revision", "Pinned revision or version", placeholder = "Required for publication"),
                shiny::fluidRow(shiny::column(4, shiny::textInput("config", "Config", placeholder = "default")), shiny::column(4, shiny::textInput("split", "Split", placeholder = "train")), shiny::column(4, shiny::textInput("source_file", "File", placeholder = "Optional")))
              ),
              shiny::actionButton("inspect_source", "Inspect source", class = "rw-button rw-button-primary"), shiny::uiOutput("source_status")
            ),
            shiny::tags$div(class = "rw-guardrails", shiny::tags$span("Up to 250 MB"), shiny::tags$span("Processed locally"), shiny::tags$span("Credentials never stored")),
            shiny::tags$aside(class = "rw-inline-guide", shiny::tags$h2("Before you continue"), shiny::tags$dl(shiny::tags$div(shiny::tags$dt("License"), shiny::tags$dd("Confirm reuse terms")), shiny::tags$div(shiny::tags$dt("Revision"), shiny::tags$dd("Pin remote sources")), shiny::tags$div(shiny::tags$dt("Privacy"), shiny::tags$dd("No telemetry or upload"))))
          ),
          shiny::tagList(back_button("wizard_back_2"), next_button("wizard_next_2", "Preview data"))
        ),
        screen(3, "Data / Profile", "Know your data before modeling", "Confirm the source, unit of observation, and missing-value rules.",
          shiny::tagList(
            shiny::uiOutput("manifest_summary"), shiny::uiOutput("data_stats"),
            shiny::tags$section(class = "rw-table-card", shiny::tags$div(class = "rw-section-title", shiny::tags$h2("Data preview"), shiny::tags$span("Representative rows from the 100-row preview")), shiny::tableOutput("preview_table")),
            shiny::tags$div(class = "rw-profile-grid",
              shiny::tags$section(class = "rw-table-card", shiny::tags$div(class = "rw-section-title", shiny::tags$h2("Column profile"), shiny::tags$span("Type, missingness, distinct values")), shiny::tableOutput("profile_table")),
              shiny::tags$aside(class = "rw-decision-card", shiny::tags$h2("Review decisions"), shiny::textInput("unit_of_observation", "Unit of observation", placeholder = "What does one row represent?"), shiny::textInput("missing_tokens", "Missing value tokens", placeholder = "?, N/A"), shiny::numericInput("max_rows", "Maximum analysis rows", value = 10000L, min = 20L, max = 10000L), shiny::actionButton("import_source", "Import selected data locally", class = "rw-button rw-button-primary"), shiny::uiOutput("import_status"))
            )
          ),
          shiny::tagList(back_button("wizard_back_3"), next_button("wizard_next_3", "Confirm data profile"))
        ),
        screen(4, "Question", "Turn a goal into an analysis plan", "Define a question, assign variable roles, and inspect the suggested method.",
          shiny::tags$div(class = "rw-plan-layout",
            shiny::tags$div(class = "rw-plan-main",
              shiny::textAreaInput("question", "What do you want to learn from this data?", rows = 3, placeholder = "What can this evidence support?"),
              shiny::tags$div(class = "rw-role-grid",
                shiny::tags$section(class = "rw-variable-card", shiny::tags$h2("Outcome"), shiny::tags$p("The variable to explain or predict."), shiny::selectInput("outcome", NULL, choices = character())),
                shiny::tags$section(class = "rw-variable-card", shiny::tags$h2("Predictors"), shiny::tags$p("Variables that may help explain the outcome."), shiny::selectizeInput("predictors", NULL, choices = character(), multiple = TRUE)),
                shiny::tags$section(class = "rw-variable-card", shiny::tags$h2("Review slice"), shiny::tags$p("A group used for review, not automatic decisions."), shiny::selectizeInput("slice_by", NULL, choices = character(), multiple = TRUE))
              ),
              shiny::uiOutput("method_suggestion")
            ),
            shiny::tags$aside(class = "rw-approval-preview", shiny::tags$h2("Decisions to approve"), shiny::tags$p("Review every decision before R runs."), shiny::tags$ul(shiny::tags$li("Question recorded"), shiny::tags$li("Variable roles recorded"), shiny::tags$li("Missing-value handling"), shiny::tags$li("Method remains pending")))
          ),
          shiny::tagList(back_button("wizard_back_4"), next_button("wizard_next_4", "Choose role lens"))
        ),
        screen(5, "Workflow / Role", "Choose the lens for this work", "The role changes activities and deliverables, not the underlying data or evidence.",
          shiny::tagList(
            shiny::tags$div(class = "rw-role-options", shiny::radioButtons("role", NULL, selected = "data_scientist", inline = TRUE,
              choiceNames = list(
                choice_copy("chart-column", "Data Analyst", "Summaries, comparisons, evidence tables"),
                choice_copy("chart-line", "Data Scientist", "Models, diagnostics, evaluation metrics"),
                choice_copy("shield-halved", "Model Reviewer", "Reproduction, limits, approval status"),
                choice_copy("book-open", "Guided Learning", "Lessons, practice tasks, checkpoints")
              ),
              choiceValues = c("data_analyst", "data_scientist", "model_reviewer", "guided_learning"))),
            shiny::uiOutput("role_detail"),
            shiny::tags$section(class = "rw-method-card", shiny::tags$div(shiny::tags$span(class = "rw-eyebrow", "Approved analysis"), shiny::tags$h2("Choose the method to review")), shiny::selectInput("analysis", NULL, choices = c("Automatic rule" = "auto", "Descriptive" = "describe", "Linear model" = "lm", "Binary GLM" = "glm"))),
            shiny::actionButton("create_workflow", "Create reviewable workflow", class = "rw-button rw-button-primary"), shiny::uiOutput("workflow_summary")
          ),
          shiny::tagList(back_button("wizard_back_5"), next_button("wizard_next_5", "Review workflow path"))
        ),
        screen(6, "Workflow / Approval", "Review the path before you run it", "The full DAG remains available, but the default view groups work into five understandable stages.",
          shiny::tagList(
            shiny::uiOutput("workflow_path"),
            shiny::tags$div(class = "rw-review-grid",
              shiny::tags$section(class = "rw-approval-list", shiny::tags$h2("Human approvals"), shiny::checkboxInput("approve_question", "I approve the analytical question and decision boundary."), shiny::checkboxInput("approve_roles", "I approve outcome, predictors, and review slices."), shiny::checkboxInput("approve_method", "I approve the statistical method and limitations."), shiny::checkboxInput("approve_missing", "I approve missing-value and retained-row rules."), shiny::uiOutput("approval_status")),
              shiny::tags$aside(class = "rw-ready-card", shiny::tags$h2("Ready to run"), shiny::tags$dl(shiny::tags$div(shiny::tags$dt("Execution"), shiny::tags$dd("Local R")), shiny::tags$div(shiny::tags$dt("Seed"), shiny::tags$dd("2026")), shiny::tags$div(shiny::tags$dt("Telemetry"), shiny::tags$dd("None")), shiny::tags$div(shiny::tags$dt("Output"), shiny::tags$dd("Portable HTML + Quarto"))), shiny::textInput("output_dir", "Output directory", value = output_dir))
            )
          ),
          shiny::tagList(back_button("wizard_back_6"), shiny::actionButton("build_workflow", "Run approved workflow", class = "rw-button rw-button-primary"))
        ),
        screen(7, "Evidence / Ready", "Your workflow is ready to open", "The compiled workspace starts in Focus mode and keeps Trace, Claim, Receipt, and Handoff one click away.",
          shiny::tagList(shiny::uiOutput("build_status"), shiny::tags$section(class = "rw-completion-list",
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("circle-check")), shiny::tags$strong("Data approved"), shiny::tags$span("Source and roles recorded")),
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("rotate")), shiny::tags$strong("Analysis reproduced"), shiny::tags$span("Seed and environment recorded")),
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("link")), shiny::tags$strong("Evidence linked"), shiny::tags$span("Table, 2D, 3D share IDs")),
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("file-shield")), shiny::tags$strong("Receipt ready"), shiny::tags$span("Local-only handoff"))))
        )
      )
    )
  )

  server <- function(input, output, session) {
    current_step <- shiny::reactiveVal(1L)
    current_source <- shiny::reactiveVal(NULL)
    current_manifest <- shiny::reactiveVal(NULL)
    current_preview <- shiny::reactiveVal(NULL)
    current_dataset <- shiny::reactiveVal(NULL)
    current_profile <- shiny::reactiveVal(NULL)
    current_workflow <- shiny::reactiveVal(NULL)
    current_build <- shiny::reactiveVal(NULL)
    source_error <- shiny::reactiveVal(NULL)
    import_error <- shiny::reactiveVal(NULL)
    workflow_error <- shiny::reactiveVal(NULL)
    build_error <- shiny::reactiveVal(NULL)
    output$current_step <- shiny::renderText(current_step())
    shiny::outputOptions(output, "current_step", suspendWhenHidden = FALSE)
    shiny::observe({
      step <- current_step()
      phase <- if (step <= 3L) "nav_data" else if (step == 4L) "nav_question" else if (step <= 6L) "nav_workflow" else "nav_evidence"
      session$sendCustomMessage("rclaimlab-step", list(phase = phase))
    })

    go <- function(id, step) shiny::observeEvent(input[[id]], current_step(step), ignoreInit = TRUE)
    go("wizard_back_2", 1L); go("wizard_back_3", 2L); go("wizard_back_4", 3L); go("wizard_back_5", 4L); go("wizard_back_6", 5L)
    go("nav_data", 1L); go("nav_question", 4L); go("nav_workflow", 5L); go("nav_evidence", 6L)
    shiny::observeEvent(input$wizard_next_1, current_step(2L))
    shiny::observeEvent(input$wizard_next_2, {
      if (is.null(current_manifest())) source_error("Inspect a source before previewing data.") else current_step(3L)
    })
    shiny::observeEvent(input$wizard_next_3, {
      if (is.null(current_dataset())) import_error("Import and profile the selected data before continuing.") else current_step(4L)
    })
    shiny::observeEvent(input$wizard_next_4, current_step(5L))
    shiny::observeEvent(input$wizard_next_5, {
      if (is.null(current_workflow())) workflow_error("Create a reviewable workflow before approval.") else current_step(6L)
    })
    shiny::observeEvent(input$purpose, {
      selected <- switch(input$purpose, guided = "guided_learning", review = "model_reviewer", "data_scientist")
      shiny::updateRadioButtons(session, "role", selected = selected)
    }, ignoreInit = FALSE)

    output$purpose_detail <- shiny::renderUI({
      details <- switch(input$purpose,
        guided = c("Learn by prediction, exploration, explanation, repair, transfer, and reproduction.", "Guided Learning"),
        review = c("Open evidence as a reviewer and challenge claims, slices, and limitations.", "Model Reviewer"),
        c("Import a table, approve an analysis plan, and generate a role-ready workspace.", "Data Scientist")
      )
      shiny::tags$div(class = "rw-purpose-detail", shiny::tags$strong(details[[2]]), shiny::tags$p(details[[1]]), shiny::tags$span("Recommended path selected"))
    })

    source_from_input <- function() {
      if (input$provider == "local") {
        if (is.null(input$local_file)) stop("Choose a local tabular file", call. = FALSE)
        dataset_source("local", input$local_file$datapath)
      } else dataset_source(input$provider, input$dataset_id,
        revision = empty_to_null(input$revision), config = empty_to_null(input$config),
        split = empty_to_null(input$split), file = empty_to_null(input$source_file))
    }
    shiny::observeEvent(input$inspect_source, {
      source_error(NULL)
      value <- tryCatch({
        source <- source_from_input(); manifest <- inspect_dataset(source)
        current_source(source); current_manifest(manifest); current_preview(preview_dataset(source, 100L)); TRUE
      }, error = function(error) { source_error(conditionMessage(error)); FALSE })
      if (!value) { current_manifest(NULL); current_preview(NULL) }
    })
    output$source_status <- shiny::renderUI({
      if (!is.null(source_error())) return(shiny::tags$p(class = "rw-error", source_error()))
      if (!is.null(current_manifest())) shiny::tags$p(class = "rw-success", "Source metadata and preview are ready.")
    })
    output$manifest_summary <- shiny::renderUI({
      value <- current_manifest(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Inspect a source first."))
      shiny::tags$div(class = "rw-manifest",
        shiny::tags$div(shiny::tags$span("Dataset"), shiny::tags$strong(basename(value$id %||% "Selected source"))),
        shiny::tags$div(shiny::tags$span("Revision"), shiny::tags$strong(value$revision %||% "Unresolved")),
        shiny::tags$div(shiny::tags$span("License"), shiny::tags$strong(value$license %||% "Unknown")),
        shiny::tags$div(shiny::tags$span("Publication"), shiny::tags$strong(if (isTRUE(value$publishable)) "Eligible" else "Needs metadata")))
    })
    output$preview_table <- shiny::renderTable({ utils::head(current_preview(), 8L) }, striped = TRUE, bordered = FALSE, spacing = "xs")
    shiny::observeEvent(input$import_source, {
      import_error(NULL)
      value <- tryCatch({
        dataset <- import_dataset(current_source(), max_rows = input$max_rows)
        current_dataset(dataset); profile <- profile_dataset(dataset); current_profile(profile)
        columns <- names(dataset$data)
        shiny::updateSelectInput(session, "outcome", choices = c("None" = "", columns))
        shiny::updateSelectizeInput(session, "predictors", choices = columns, selected = utils::head(columns, min(4L, length(columns))), server = TRUE)
        shiny::updateSelectizeInput(session, "slice_by", choices = columns, selected = character(), server = TRUE)
        TRUE
      }, error = function(error) { import_error(conditionMessage(error)); FALSE })
      if (!value) { current_dataset(NULL); current_profile(NULL) }
    })
    output$import_status <- shiny::renderUI({
      if (!is.null(import_error())) return(shiny::tags$p(class = "rw-error", import_error()))
      value <- current_dataset(); if (!is.null(value)) shiny::tags$p(class = "rw-success", nrow(value$data), " rows imported into local R; raw data remain local.")
    })
    output$data_stats <- shiny::renderUI({
      dataset <- current_dataset(); profile <- current_profile(); preview <- current_preview()
      rows <- if (!is.null(dataset)) nrow(dataset$data) else if (!is.null(preview)) nrow(preview) else 0L
      cols <- if (!is.null(dataset)) ncol(dataset$data) else if (!is.null(preview)) ncol(preview) else 0L
      missing <- if (!is.null(dataset)) round(mean(is.na(dataset$data)) * 100, 1) else 0
      shiny::tags$div(class = "rw-stat-strip", summary_cell("Rows", format(rows, big.mark = ",")), summary_cell("Columns", cols), summary_cell("Missing values", paste0(missing, "%")), summary_cell("Source", current_manifest()$provider %||% "Pending"))
    })
    output$profile_table <- shiny::renderTable({
      value <- current_profile()
      if (!is.null(value)) return(value$columns[c("column", "type", "missing_percent", "distinct", "role")])
      preview <- current_preview()
      if (is.null(preview)) return(NULL)
      data.frame(
        column = names(preview),
        type = vapply(preview, function(column) class(column)[[1]], character(1)),
        missing_percent = vapply(preview, function(column) round(mean(is.na(column)) * 100, 1), numeric(1)),
        distinct = vapply(preview, function(column) length(unique(column[!is.na(column)])), integer(1)),
        role = "Review",
        check.names = FALSE
      )
    }, striped = TRUE, bordered = FALSE, spacing = "xs")

    output$method_suggestion <- shiny::renderUI({
      outcome <- empty_to_null(input$outcome)
      selected <- input$analysis %||% "auto"
      method <- if (selected != "auto") selected else if (is.null(outcome)) "Descriptive evidence" else "Outcome-aware recommendation"
      shiny::tags$section(class = "rw-suggestion-card", shiny::tags$div(shiny::tags$span(class = "rw-eyebrow", "Suggested method"), shiny::tags$h2(method)), shiny::tags$p("The method remains a reviewable recommendation. R does not execute until all approvals are recorded."), shiny::tags$span("Why this method?"))
    })
    output$role_detail <- shiny::renderUI({
      details <- switch(input$role,
        data_analyst = c("Explore and summarize evidence", "Analysis brief / Evidence table / Decision log"),
        model_reviewer = c("Reproduce, challenge, and approve claims", "Review report / Limitations / Approval state"),
        guided_learning = c("Learn by prediction, explanation, repair, and transfer", "Lesson / Practice / Learning receipt"),
        c("Fit, diagnose, evaluate, and communicate models", "R script / Model card / Evaluation evidence"))
      shiny::tags$div(class = "rw-role-detail", shiny::tags$span(class = "rw-eyebrow", "Selected lens"), shiny::tags$h2(workflow_role_label(input$role)), shiny::tags$p(details[[1]]), shiny::tags$strong(details[[2]]), shiny::tags$small("Your data and evidence stay the same."))
    })
    shiny::observeEvent(input$create_workflow, {
      workflow_error(NULL)
      tryCatch({
        outcome <- empty_to_null(input$outcome)
        tokens <- trimws(strsplit(input$missing_tokens %||% "", ",", fixed = TRUE)[[1]])
        tokens <- tokens[nzchar(tokens)]
        workflow <- workflow_from_dataset(current_dataset(), role = input$role, outcome = outcome,
          predictors = input$predictors, slice_by = input$slice_by, analysis = input$analysis,
          question = empty_to_null(input$question), missing_values = tokens)
        current_workflow(workflow)
      }, error = function(error) { workflow_error(conditionMessage(error)); current_workflow(NULL) })
    })
    output$workflow_summary <- shiny::renderUI({
      if (!is.null(workflow_error())) return(shiny::tags$p(class = "rw-error", workflow_error()))
      value <- current_workflow(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Create a workflow after reviewing its inputs."))
      shiny::tagList(shiny::tags$p(class = "rw-success", workflow_role_label(value$role), " workflow created with ", length(value$activities), " activities."),
        shiny::tags$details(class = "rw-activity-details", shiny::tags$summary("Show all activities"), shiny::tags$ol(lapply(value$activities, function(activity) shiny::tags$li(shiny::tags$strong(activity$type), ": ", activity$prompt)))))
    })
    output$workflow_path <- shiny::renderUI({
      value <- current_workflow(); if (is.null(value)) return(shiny::tags$p(class = "rw-error", "Create a workflow first."))
      groups <- c("Prepare", "Split", "Model", "Evaluate", "Communicate")
      group_icons <- c(Prepare = "file-circle-check", Split = "code-branch", Model = "chart-line", Evaluate = "clipboard-check", Communicate = "comments")
      types <- vapply(value$activities, `[[`, character(1), "type")
      map_group <- function(type) {
        if (type %in% c("frame", "inspect", "clean", "transform", "describe", "compare", "verify_source")) "Prepare"
        else if (type == "split") "Split"
        else if (type %in% c("baseline", "fit", "diagnose")) "Model"
        else if (type %in% c("evaluate", "slice", "explain", "challenge", "revise", "reproduce")) "Evaluate"
        else "Communicate"
      }
      assigned <- vapply(types, map_group, character(1))
      shiny::tags$div(class = "rw-path", lapply(groups, function(group) {
        activity_names <- gsub("_", " ", types[assigned == group], fixed = TRUE)
        shiny::tags$section(class = if (group == "Model") "active" else NULL, shiny::tags$span(`aria-hidden` = "true", shiny::icon(group_icons[[group]])), shiny::tags$h2(group), shiny::tags$p(if (length(activity_names)) paste(activity_names, collapse = " / ") else "No separate activity"))
      }))
    })
    approvals_ready <- shiny::reactive(isTRUE(input$approve_question) && isTRUE(input$approve_roles) && isTRUE(input$approve_method) && isTRUE(input$approve_missing))
    output$approval_status <- shiny::renderUI({
      if (approvals_ready()) shiny::tags$p(class = "rw-success", "All execution approvals are recorded.") else shiny::tags$p(class = "rw-muted", "All four approvals are required before R execution.")
    })
    shiny::observeEvent(input$build_workflow, {
      build_error(NULL)
      tryCatch({
        if (is.null(current_workflow())) stop("Create a workflow first", call. = FALSE)
        if (!approvals_ready()) stop("All four approvals are required", call. = FALSE)
        workflow <- approve_workflow(current_workflow()); run <- run_workflow(workflow)
        destination <- file.path(normalizePath(input$output_dir, winslash = "/", mustWork = FALSE), workflow$id)
        build <- compile_workflow(run, destination, overwrite = TRUE); write_workflow_receipt(run, destination)
        current_build(build); current_step(7L)
      }, error = function(error) { build_error(conditionMessage(error)); current_build(NULL) })
    })
    output$build_status <- shiny::renderUI({
      if (!is.null(build_error())) return(shiny::tags$p(class = "rw-error", build_error()))
      value <- current_build(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Run the approved workflow to create the portable workspace."))
      shiny::tags$div(class = "rw-build", shiny::tags$span(class = "rw-eyebrow", "Compiled successfully"), shiny::tags$h2("Open the focused evidence workspace"), shiny::tags$p(sum(value$checks$status == "PASS"), " reproducibility checks passed."), shiny::tags$code(basename(value$output_dir)), shiny::tags$a(class = "rw-button rw-button-primary", href = paste0("file:///", gsub(" ", "%20", file.path(value$output_dir, "app", "index.html"), fixed = TRUE)), target = "_blank", "Open portable workspace"))
    })
  }
  shiny::shinyApp(ui, server)
  # nocov end
}

empty_to_null <- function(value) {
  if (is.null(value) || length(value) != 1L || is.na(value) || !nzchar(trimws(value))) NULL else trimws(value)
}

workflow_wizard_css <- function() paste(
  ".rw-completion-icon{display:grid!important;place-items:center;width:34px;height:34px;margin:0 auto 9px;border-radius:50%;background:var(--green-soft);color:var(--green)!important;font-size:14px!important}",
  ".rw-source-panel .form-group:has(#local_file){width:100%;max-width:none}",
  "@media(min-width:1101px){.rw-source-options,.rw-source-panel,.rw-guardrails{margin-right:280px}}",
  ":root{--ink:#121b31;--muted:#5c6880;--line:#dbe2ed;--surface:#fff;--soft:#f6f8fc;--soft-blue:#eef4ff;--blue:#1757d7;--blue-dark:#0f43aa;--green:#13804b;--green-soft:#edf8f1;--amber:#a65a00;--radius:14px;--shadow:0 12px 30px rgba(31,49,84,.07)}*{box-sizing:border-box}body{margin:0;background:var(--soft);color:var(--ink);font:14px/1.5 'Segoe UI Variable','Segoe UI',system-ui,sans-serif}.container-fluid{padding:0}.rw-skip{position:fixed;z-index:99;top:8px;left:8px;transform:translateY(-160%);padding:8px 12px;border:2px solid var(--blue);border-radius:8px;background:#fff;color:var(--blue)}.rw-skip:focus{transform:none}.rw-topbar{position:sticky;z-index:20;top:0;display:flex;justify-content:space-between;align-items:center;gap:16px;min-height:68px;padding:11px 22px;border-bottom:1px solid var(--line);background:#fff}.rw-brand{display:flex;align-items:center;gap:10px}.rw-brand>span{display:grid;place-items:center;width:38px;height:38px;border-radius:10px;background:var(--blue);color:#fff;font-weight:850}.rw-brand strong,.rw-brand small{display:block}.rw-brand small,.rw-local,.rw-muted{color:var(--muted);font-size:11px}.rw-local{padding:5px 11px;border:1px solid var(--line);border-radius:999px;font-weight:750}.rw-app{display:grid;grid-template-columns:224px minmax(0,1fr);min-height:calc(100vh - 68px)}.rw-rail{position:sticky;top:68px;align-self:start;height:calc(100vh - 68px);padding:24px 16px;border-right:1px solid var(--line);background:#fff}.rw-rail-head h2{margin:4px 0;font-size:19px}.rw-rail-head p{margin:0 0 18px;color:var(--muted);font-size:11px}.rw-eyebrow{display:block;color:var(--blue);font-size:10px;font-weight:850;letter-spacing:.09em;text-transform:uppercase}.rw-phase-list{display:grid;gap:5px}.rw-phase{display:grid;grid-template-columns:28px minmax(0,1fr);column-gap:9px;padding:10px;border-radius:9px;color:var(--muted);text-decoration:none}.rw-phase:hover,.rw-phase:focus,.rw-phase.active{background:var(--soft-blue);color:var(--blue);text-decoration:none}.rw-phase>span{grid-row:1/3;display:grid;place-items:center;width:26px;height:26px;border:1px solid var(--line);border-radius:50%;font-size:9px;font-weight:850}.rw-phase strong,.rw-phase small{display:block}.rw-phase strong{font-size:11px}.rw-phase small{font-size:9px}.rw-rail-note{margin-top:24px;padding:13px;border:1px solid #efc999;border-radius:10px;background:#fff8ee}.rw-rail-note strong{color:var(--amber);font-size:10px}.rw-rail-note p{margin:4px 0;color:#74420c;font-size:9px}.rw-main{min-width:0}.rw-screen{max-width:1280px;margin:auto;padding:38px 34px 60px}.rw-screen-head{margin-bottom:24px}.rw-screen-head h1{max-width:920px;margin:6px 0;font-size:clamp(30px,4vw,48px);line-height:1.05;letter-spacing:-.04em}.rw-screen-head p{max-width:760px;margin:0;color:var(--muted)}.rw-screen-body{min-width:0}.rw-screen-footer{position:sticky;bottom:0;z-index:10;display:flex;align-items:center;justify-content:space-between;gap:14px;margin:28px -34px -60px;padding:14px 34px;border-top:1px solid var(--line);background:rgba(255,255,255,.98)}.rw-button{display:inline-flex;align-items:center;justify-content:center;min-height:42px;padding:9px 16px;border-radius:9px;font-weight:800;text-decoration:none}.rw-button-primary{border:1px solid var(--blue);background:var(--blue);color:#fff}.rw-button-primary:hover,.rw-button-primary:focus{background:var(--blue-dark);color:#fff}.rw-button-secondary{border:1px solid #c8d2e1;background:#fff;color:var(--ink)}.rw-footer-note{color:var(--muted);font-size:10px}.rw-purpose-options .form-group,.rw-source-options .form-group,.rw-role-options .form-group{margin:0}.rw-purpose-options .shiny-options-group,.rw-source-options .shiny-options-group,.rw-role-options .shiny-options-group{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.rw-role-options .shiny-options-group{grid-template-columns:repeat(2,minmax(0,1fr))}.rw-purpose-options .radio-inline,.rw-source-options .radio-inline,.rw-role-options .radio-inline{display:flex;align-items:flex-start;min-height:112px;margin:0!important;padding:18px;border:1px solid var(--line);border-radius:var(--radius);background:#fff;font-size:15px;font-weight:800;box-shadow:var(--shadow)}.rw-source-options .radio-inline{min-height:76px}.rw-role-options .radio-inline{min-height:118px}.rw-purpose-options .radio-inline:has(input:checked),.rw-source-options .radio-inline:has(input:checked),.rw-role-options .radio-inline:has(input:checked){border-color:var(--blue);box-shadow:0 0 0 1px var(--blue)}.rw-purpose-options input,.rw-source-options input,.rw-role-options input{margin:4px 9px 0 0}.rw-choice-copy{display:grid;grid-template-columns:38px minmax(0,1fr);gap:10px;min-width:0}.rw-choice-icon{display:grid;place-items:center;width:36px;height:36px;border-radius:50%;background:var(--soft-blue);color:var(--blue);font-size:15px}.rw-choice-text{display:grid;gap:5px;min-width:0}.rw-choice-copy strong{font-size:14px}.rw-choice-copy small{color:var(--muted);font-size:10px;font-weight:500}.rw-purpose-layout{display:grid;grid-template-columns:minmax(0,1fr) 280px;gap:16px}.rw-purpose-detail,.rw-role-detail{margin-top:16px;padding:18px;border:1px solid #aac3f3;border-radius:var(--radius);background:var(--soft-blue)}.rw-purpose-detail p,.rw-role-detail p{margin:5px 0;color:var(--muted)}.rw-purpose-detail span,.rw-role-detail small{color:var(--blue);font-size:10px;font-weight:750}.rw-output-preview,.rw-recent-placeholder{margin-top:18px;padding:18px;border:1px solid var(--line);border-radius:var(--radius);background:#fff}.rw-purpose-layout .rw-output-preview{margin-top:0}.rw-output-preview h2,.rw-recent-placeholder h2{margin:0 0 12px;font-size:17px}.rw-recent-placeholder p{margin:0;padding:18px;border-radius:9px;background:var(--soft);color:var(--muted);font-size:10px}.rw-output-preview>div{display:grid;grid-template-columns:repeat(3,minmax(0,1fr))}.rw-purpose-layout .rw-output-preview>div{grid-template-columns:1fr}.rw-output-preview>div>div{padding:12px}.rw-output-preview>div>div+div{border-left:1px solid var(--line)}.rw-purpose-layout .rw-output-preview>div>div+div{border-top:1px solid var(--line);border-left:0}.rw-output-preview span,.rw-output-preview strong{display:block}.rw-output-preview span{color:var(--muted);font-size:9px;text-transform:uppercase}.rw-output-preview .rw-summary-icon{display:grid;place-items:center;width:34px;height:34px;margin-bottom:9px;border-radius:50%;background:var(--soft-blue);color:var(--blue);font-size:14px;text-transform:none}.rw-output-preview strong{margin-top:3px;font-size:11px}.rw-source-panel,.rw-table-card,.rw-decision-card,.rw-variable-card,.rw-suggestion-card,.rw-approval-preview,.rw-method-card,.rw-ready-card,.rw-approval-list,.rw-build{margin-top:16px;padding:18px;border:1px solid var(--line);border-radius:var(--radius);background:#fff;box-shadow:var(--shadow)}.rw-source-panel{max-width:900px}.rw-source-panel .form-group:has(#local_file){display:grid;place-items:center;min-height:170px;padding:24px;border:1px dashed #9db2d1;border-radius:12px;background:var(--soft-blue);text-align:center}.rw-source-panel .form-group:has(#local_file) .input-group{max-width:360px}.rw-source-panel .row{margin:0 -8px}.rw-source-panel .col-sm-4{padding:0 8px}.rw-guardrails{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}.rw-guardrails span{padding:6px 9px;border:1px solid var(--line);border-radius:8px;background:#fff;color:var(--muted);font-size:10px}.rw-inline-guide{position:absolute;right:34px;top:170px;width:260px;padding:18px;border:1px solid var(--line);border-radius:var(--radius);background:#fff}.rw-inline-guide h2{margin:0 0 10px;font-size:17px}.rw-inline-guide dl{margin:0}.rw-inline-guide dl>div{padding:10px 0;border-top:1px solid var(--line)}.rw-inline-guide dt{font-size:10px}.rw-inline-guide dd{margin:3px 0;color:var(--muted);font-size:9px}.rw-manifest,.rw-stat-strip{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));border:1px solid var(--line);border-radius:var(--radius);background:#fff;overflow:hidden}.rw-manifest>div,.rw-stat-strip>div{min-width:0;padding:13px}.rw-manifest>div+div,.rw-stat-strip>div+div{border-left:1px solid var(--line)}.rw-manifest span,.rw-manifest strong,.rw-stat-strip span,.rw-stat-strip strong{display:block;overflow-wrap:anywhere}.rw-manifest span,.rw-stat-strip span{color:var(--muted);font-size:9px;text-transform:uppercase}.rw-manifest strong,.rw-stat-strip strong{margin-top:4px;font-size:12px}.rw-stat-strip{margin-top:12px}.rw-profile-grid,.rw-review-grid{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:16px}.rw-section-title{display:flex;align-items:center;justify-content:space-between;gap:12px}.rw-section-title h2{margin:0;font-size:17px}.rw-section-title span{color:var(--muted);font-size:9px}.rw-table-card{overflow:auto}.rw-table-card table{min-width:620px;font-size:10px}.rw-table-card th{color:var(--muted);font-size:8px;text-transform:uppercase}.rw-table-card td,.rw-table-card th{padding:8px!important;border-color:var(--line)!important}.rw-decision-card h2,.rw-variable-card h2,.rw-approval-preview h2,.rw-method-card h2,.rw-ready-card h2,.rw-approval-list h2,.rw-build h2{margin:0 0 10px;font-size:17px}.rw-plan-layout{display:grid;grid-template-columns:minmax(0,1fr) 260px;gap:16px}.rw-role-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.rw-variable-card p{min-height:36px;color:var(--muted);font-size:10px}.rw-suggestion-card{display:flex;align-items:center;gap:18px;border-color:#aac3f3;background:var(--soft-blue)}.rw-suggestion-card>div{min-width:180px}.rw-suggestion-card h2{margin:4px 0;font-size:17px}.rw-suggestion-card p{flex:1;margin:0;color:var(--muted);font-size:10px}.rw-suggestion-card>span{color:var(--blue);font-size:10px;font-weight:800}.rw-approval-preview{box-shadow:none}.rw-plan-layout .rw-approval-preview{margin-top:0}.rw-approval-preview>p{color:var(--muted);font-size:10px}.rw-approval-preview ul{display:flex;flex-wrap:wrap;gap:8px;margin:0;padding:0;list-style:none}.rw-plan-layout .rw-approval-preview ul{display:grid}.rw-approval-preview li{padding:9px 10px;border-radius:8px;background:var(--soft);font-size:10px}.rw-role-detail strong,.rw-role-detail small{display:block}.rw-method-card{display:flex;align-items:center;justify-content:space-between;gap:20px}.rw-method-card .form-group{min-width:260px;margin:0}.rw-activity-details{margin-top:12px}.rw-activity-details summary{color:var(--blue);font-size:10px;font-weight:800;cursor:pointer}.rw-activity-details ol{color:var(--muted);font-size:10px}.rw-path{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:9px}.rw-path section{min-height:145px;padding:15px;border:1px solid var(--line);border-radius:var(--radius);background:#fff}.rw-path section.active{border-color:var(--blue);box-shadow:0 0 0 1px var(--blue)}.rw-path section>span{display:grid;place-items:center;width:34px;height:34px;border-radius:50%;background:var(--soft-blue);color:var(--blue);font-size:13px;font-weight:850}.rw-path h2{margin:12px 0 5px;font-size:14px}.rw-path p{color:var(--muted);font-size:9px}.rw-ready-card dl{margin:0}.rw-ready-card dl>div{display:flex;justify-content:space-between;gap:10px;padding:9px 0;border-top:1px solid var(--line)}.rw-ready-card dt{color:var(--muted);font-size:9px}.rw-ready-card dd{margin:0;font-size:10px;font-weight:750}.rw-success,.rw-error,.rw-muted{margin-top:10px;padding:9px 11px;border-radius:8px;font-size:10px}.rw-success{border-left:3px solid var(--green);background:var(--green-soft);color:#0b5c36}.rw-error{border-left:3px solid #b42318;background:#fff1f0;color:#8b1b13}.rw-muted{background:var(--soft)}.rw-build{display:grid;gap:8px;text-align:center}.rw-build code{overflow-wrap:anywhere;color:var(--muted);font-size:9px}.rw-build .rw-button{justify-self:center}.rw-completion-list{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));margin-top:16px;border:1px solid var(--line);border-radius:var(--radius);background:#fff;overflow:hidden}.rw-completion-list>div{padding:18px;text-align:center}.rw-completion-list>div+div{border-left:1px solid var(--line)}.rw-completion-list strong,.rw-completion-list span{display:block}.rw-completion-list strong{font-size:11px}.rw-completion-list span{margin-top:4px;color:var(--muted);font-size:9px}input,textarea,.selectize-input{max-width:100%}.form-control{border-color:#c8d2e1;border-radius:8px;box-shadow:none}.form-control:focus,.selectize-input.focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(23,87,215,.15)}@media(max-width:1100px){.rw-inline-guide{position:static;width:auto;margin-top:14px}.rw-purpose-layout,.rw-plan-layout{grid-template-columns:1fr}.rw-role-options .shiny-options-group{grid-template-columns:repeat(2,minmax(0,1fr))}.rw-path{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:820px){.rw-topbar{position:relative}.rw-app{display:block}.rw-rail{position:relative;top:auto;height:auto;border-right:0;border-bottom:1px solid var(--line)}.rw-phase-list{display:flex;overflow-x:auto}.rw-phase{flex:0 0 170px}.rw-rail-note{display:none}.rw-screen{padding:24px 14px 70px}.rw-screen-footer{margin:24px -14px -70px;padding:12px 14px}.rw-profile-grid,.rw-review-grid{grid-template-columns:1fr}.rw-purpose-options .shiny-options-group,.rw-source-options .shiny-options-group{grid-template-columns:1fr}.rw-role-grid{grid-template-columns:1fr}.rw-suggestion-card,.rw-method-card{align-items:flex-start;flex-direction:column}.rw-method-card .form-group{width:100%;min-width:0}.rw-completion-list{grid-template-columns:repeat(2,minmax(0,1fr))}.rw-completion-list>div:nth-child(3){border-top:1px solid var(--line);border-left:0}.rw-completion-list>div:nth-child(4){border-top:1px solid var(--line)}}@media(max-width:520px){.rw-local,.rw-brand small{display:none}.rw-screen-head h1{font-size:32px}.rw-role-options .shiny-options-group,.rw-manifest,.rw-stat-strip,.rw-path,.rw-completion-list{grid-template-columns:1fr}.rw-manifest>div+div,.rw-stat-strip>div+div,.rw-completion-list>div+div{border-top:1px solid var(--line);border-left:0}.rw-screen-footer{align-items:stretch;flex-direction:column-reverse}.rw-screen-footer .rw-button{width:100%}.rw-footer-note{text-align:center}.rw-output-preview>div{grid-template-columns:1fr}.rw-output-preview>div>div+div{border-top:1px solid var(--line);border-left:0}.rw-role-options .radio-inline{min-height:68px}}@media(prefers-reduced-motion:reduce){*,*::before,*::after{scroll-behavior:auto!important;transition:none!important}}",
  sep = ""
)
