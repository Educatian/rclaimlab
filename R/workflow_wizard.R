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
  back_button <- function(id) shiny::actionButton(id, "Back", icon = shiny::icon("arrow-left"), class = "rw-button rw-button-secondary")
  next_button <- function(id, label) shiny::actionButton(id, label, icon = shiny::icon("arrow-right"), class = "rw-button rw-button-primary")
  choice_copy <- function(icon, title, description) {
    shiny::tags$span(class = "rw-choice-copy",
      shiny::tags$span(class = "rw-choice-icon", `aria-hidden` = "true", shiny::icon(icon)),
      shiny::tags$span(class = "rw-choice-text", shiny::tags$strong(title), shiny::tags$small(description))
    )
  }
  summary_cell <- function(label, value, icon = "circle-info") shiny::tags$div(
    shiny::tags$span(class = "rw-summary-icon", `aria-hidden` = "true", shiny::icon(icon)),
    shiny::tags$span(label), shiny::tags$strong(value)
  )
  icon_heading <- function(icon, title) shiny::tags$h2(
    shiny::tags$span(class = "rw-heading-icon", `aria-hidden` = "true", shiny::icon(icon)), title
  )
  icon_note <- function(icon, title, copy) shiny::tags$div(
    class = "rw-icon-note",
    shiny::tags$span(class = "rw-note-icon", `aria-hidden` = "true", shiny::icon(icon)),
    shiny::tags$div(shiny::tags$strong(title), shiny::tags$small(copy))
  )
  drag_drop_script <- paste0(
    "(function(){",
    "function setDropStatus(text,state){var status=document.getElementById('local-drop-status');if(status){status.textContent=text;status.dataset.state=state||'idle';}}",
    "function initLocalDrop(){var input=document.getElementById('local_file');if(!input||input.dataset.dropReady==='true')return;",
    "var zone=input.closest('.form-group');if(!zone)return;input.dataset.dropReady='true';zone.classList.add('rw-dropzone');zone.tabIndex=0;",
    "zone.setAttribute('role','group');zone.setAttribute('aria-label','Upload a local CSV, TSV, or Parquet file by drag and drop or file browser');input.setAttribute('aria-describedby','local-drop-status');",
    "function clearDrag(){zone.classList.remove('is-dragover');}",
    "['dragenter','dragover'].forEach(function(name){zone.addEventListener(name,function(event){event.preventDefault();event.stopPropagation();zone.classList.add('is-dragover');setDropStatus('Release to add this file locally.','drag');});});",
    "zone.addEventListener('dragleave',function(event){if(!zone.contains(event.relatedTarget)){clearDrag();setDropStatus('Drag a file here or choose Browse.','idle');}});",
    "zone.addEventListener('drop',function(event){event.preventDefault();event.stopPropagation();clearDrag();var files=event.dataTransfer&&event.dataTransfer.files;if(!files||!files.length)return;var file=files[0];",
    "if(files.length!==1){zone.classList.remove('has-file');zone.classList.add('drop-error');setDropStatus('Drop one file at a time.','error');return;}",
    "if(!/\\.(csv|tsv|parquet)$/i.test(file.name)){zone.classList.remove('has-file');zone.classList.add('drop-error');setDropStatus('Unsupported file. Choose CSV, TSV, or Parquet.','error');return;}",
    "try{input.files=files;}catch(error){zone.classList.add('drop-error');setDropStatus('This browser could not attach the dropped file. Use Browse instead.','error');return;}input.dispatchEvent(new Event('change',{bubbles:true}));zone.classList.remove('drop-error');zone.classList.add('has-file');setDropStatus(file.name+' added locally. Select Inspect source to continue.','success');});",
    "input.addEventListener('change',function(){var file=input.files&&input.files[0];if(file){zone.classList.remove('drop-error');zone.classList.add('has-file');setDropStatus(file.name+' added locally. Select Inspect source to continue.','success');}});",
    "zone.addEventListener('keydown',function(event){if(event.target!==zone)return;if(event.key==='Enter'||event.key===' '){event.preventDefault();input.click();}});}",
    "document.addEventListener('DOMContentLoaded',initLocalDrop);document.addEventListener('shiny:connected',initLocalDrop);new MutationObserver(initLocalDrop).observe(document.documentElement,{childList:true,subtree:true});",
    "})();"
  )

  ui <- shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      shiny::tags$style(shiny::HTML(paste(workflow_wizard_css(), workflow_launcher_css()))),
      shiny::tags$script(shiny::HTML(
        "Shiny.addCustomMessageHandler('rclaimlab-step', function(message) { document.body.classList.toggle('rw-launcher-active', message.step === 1); var ids = ['nav_data','nav_question','nav_workflow','nav_evidence']; ids.forEach(function(id) { var node = document.getElementById(id); if (!node) return; var enabled = id === 'nav_data' || (id === 'nav_question' && message.hasDataset) || (id === 'nav_workflow' && message.hasDataset) || (id === 'nav_evidence' && message.hasWorkflow); node.classList.toggle('active', id === message.phase); node.classList.toggle('disabled', !enabled); node.setAttribute('aria-disabled', enabled ? 'false' : 'true'); node.tabIndex = enabled ? 0 : -1; }); });"
      )),
      shiny::tags$script(shiny::HTML(drag_drop_script))
    ),
    shiny::tags$a(class = "rw-skip", href = "#rw-main", "Skip to current step"),
    shiny::tags$header(class = "rw-topbar",
      shiny::tags$div(class = "rw-brand", shiny::tags$img(class = "rw-brand-logo", src = workflow_template_asset_uri(file.path("icons", "rclaimlab-mark.svg"), "image/svg+xml"), alt = ""), shiny::tags$div(shiny::tags$strong("R-ClaimLab"), shiny::tags$small("Progressive workflow builder"))),
      shiny::tags$div(class = "rw-local", shiny::icon("shield-halved"), "Local / no telemetry")
    ),
    shiny::tags$div(class = "rw-app",
      shiny::tags$aside(class = "rw-rail", `aria-label` = "Authoring progress",
        shiny::tags$div(class = "rw-rail-head", shiny::tags$span(class = "rw-eyebrow", "Build workflow"), shiny::tags$h2("Authoring steps"), shiny::tags$p("One decision at a time")),
        shiny::tags$nav(class = "rw-phase-list",
          shiny::tags$a(id = "nav_data", href = "#", role = "button", class = "rw-phase active action-button shiny-bound-input", shiny::tags$span(`aria-hidden` = "true", shiny::icon("database")), shiny::tags$strong("Data"), shiny::tags$small("Mode, source, profile")),
          shiny::tags$a(id = "nav_question", href = "#", role = "button", class = "rw-phase action-button shiny-bound-input", shiny::tags$span(`aria-hidden` = "true", shiny::icon("bullseye")), shiny::tags$strong("Question"), shiny::tags$small("Goal and variable roles")),
          shiny::tags$a(id = "nav_workflow", href = "#", role = "button", class = "rw-phase action-button shiny-bound-input", shiny::tags$span(`aria-hidden` = "true", shiny::icon("diagram-project")), shiny::tags$strong("Workflow"), shiny::tags$small("Role, method, activities")),
          shiny::tags$a(id = "nav_evidence", href = "#", role = "button", class = "rw-phase action-button shiny-bound-input", shiny::tags$span(`aria-hidden` = "true", shiny::icon("link")), shiny::tags$strong("Evidence"), shiny::tags$small("Run, receipt, handoff"))
        ),
        shiny::tags$div(class = "rw-rail-note", shiny::tags$strong("Nothing runs until approval"), shiny::tags$p("Source choices, transformations, variable roles, and methods remain reviewable."))
      ),
      shiny::tags$main(id = "rw-main", class = "rw-main",
        screen(1, "Start with a purpose", "What do you want to do today?",
          "Choose the outcome first. R-ClaimLab reveals only the controls needed for that path.",
          workflow_launcher(local = TRUE)
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
              shiny::conditionalPanel("input.provider == 'local'",
                shiny::fileInput("local_file", shiny::tags$span(class = "rw-upload-label", shiny::tags$span(class = "rw-upload-icon", `aria-hidden` = "true", shiny::icon("arrow-up-from-bracket")), shiny::tags$strong("Drop a CSV, TSV, or Parquet file"), shiny::tags$small("Your file stays in this local R session")), accept = c(".csv", ".tsv", ".parquet")),
                shiny::tags$p(id = "local-drop-status", class = "rw-drop-status", role = "status", `aria-live` = "polite", "Drag a file here or choose Browse."),
                shiny::actionButton("try_example", "Try synthetic practice data", icon = shiny::icon("flask"), class = "rw-button rw-button-secondary"),
                shiny::helpText("300 artificial rows for practice only. No real people or external download.")
              ),
              shiny::conditionalPanel("input.provider != 'local'",
                shiny::textInput("dataset_id", "Dataset ID", placeholder = "owner/dataset"),
                shiny::textInput("revision", "Pinned revision or version", placeholder = "Required for publication"),
                shiny::conditionalPanel("input.provider == 'huggingface'", shiny::fluidRow(shiny::column(6, shiny::textInput("config", "Config", placeholder = "default")), shiny::column(6, shiny::textInput("split", "Split", placeholder = "train")))),
                shiny::textInput("source_file", "File", placeholder = "Optional CSV, TSV, or Parquet file")
              ),
              shiny::actionButton("inspect_source", "Inspect source", icon = shiny::icon("magnifying-glass"), class = "rw-button rw-button-primary"), shiny::uiOutput("source_status")
            ),
            shiny::tags$div(class = "rw-guardrails", icon_note("box-archive", "250 MB limit", "Large downloads stop for review"), icon_note("laptop", "Processed locally", "Analysis stays in your R session"), icon_note("key", "Credentials protected", "Keys are never stored")),
            shiny::tags$aside(class = "rw-inline-guide", icon_heading("clipboard-check", "Before you continue"), shiny::tags$div(class = "rw-guide-list", icon_note("file-contract", "License", "Confirm reuse terms"), icon_note("clock-rotate-left", "Revision", "Pin remote sources"), icon_note("shield-halved", "Privacy", "No telemetry or upload")))
          ),
          shiny::tagList(back_button("wizard_back_2"), next_button("wizard_next_2", "Preview data"))
        ),
        screen(3, "Data / Profile", "Know your data before modeling", "Confirm the source, unit of observation, and missing-value rules.",
          shiny::tagList(
            shiny::uiOutput("manifest_summary"), shiny::uiOutput("data_stats"),
            shiny::tags$section(class = "rw-table-card", shiny::tags$div(class = "rw-section-title", shiny::tags$h2("Data preview"), shiny::tags$span("Representative rows from the 100-row preview")), shiny::tableOutput("preview_table")),
            shiny::tags$div(class = "rw-profile-grid",
              shiny::tags$section(class = "rw-table-card", shiny::tags$div(class = "rw-section-title", shiny::tags$h2("Column profile"), shiny::tags$span("Type, missingness, distinct values")), shiny::tableOutput("profile_table")),
              shiny::tags$aside(class = "rw-decision-card", shiny::tags$h2("Review decisions"), shiny::textInput("unit_of_observation", "Unit of observation", placeholder = "What does one row represent?"), shiny::textInput("missing_tokens", "Missing value tokens", placeholder = "?, N/A"), shiny::helpText("Parsed NA counts only values already recognized as missing. Candidate tokens change only after you approve them."), shiny::numericInput("max_rows", "Maximum analysis rows", value = 10000L, min = 20L, max = 10000L), shiny::actionButton("import_source", "Import selected data locally", class = "rw-button rw-button-primary"), shiny::uiOutput("import_status"))
            )
          ),
          shiny::tagList(back_button("wizard_back_3"), next_button("wizard_next_3", "Confirm data profile"))
        ),
        screen(4, "Question", "Turn a goal into an analysis plan", "Define a question, assign variable roles, and inspect the suggested method.",
          shiny::tags$div(class = "rw-plan-layout",
            shiny::tags$div(class = "rw-plan-main",
              shiny::textAreaInput("question", "What do you want to learn from this data?", rows = 3, placeholder = "What can this evidence support?"),
              shiny::tags$div(class = "rw-role-grid",
                shiny::tags$section(class = "rw-variable-card", icon_heading("bullseye", "Outcome"), shiny::tags$p("The variable to explain or predict."), shiny::selectInput("outcome", "Outcome variable", choices = character())),
                shiny::tags$section(class = "rw-variable-card", icon_heading("sliders", "Predictors"), shiny::tags$p("Variables that may help explain the outcome."), shiny::selectizeInput("predictors", "Analysis variables", choices = character(), multiple = TRUE)),
                shiny::tags$section(class = "rw-variable-card", icon_heading("people-group", "Review slice"), shiny::tags$p("A group used for review, not automatic decisions."), shiny::selectizeInput("slice_by", "Grouping variables", choices = character(), multiple = TRUE))
              ),
              shiny::uiOutput("method_suggestion")
            ),
            shiny::tags$aside(class = "rw-approval-preview", icon_heading("user-check", "Decisions to approve"), shiny::tags$p("Review every decision before R runs."), shiny::uiOutput("decision_approval_status"))
          ),
          shiny::tagList(back_button("wizard_back_4"), next_button("wizard_next_4", "Review mode and method"))
        ),
        screen(5, "Workflow / Method", "Confirm your mode and method", "Your mode determines the activity path. Changing the method may generate different evidence from the same source.",
          shiny::tagList(
            shiny::actionButton("change_mode", "Change mode", icon = shiny::icon("arrow-left"), class = "rw-button rw-button-secondary"),
            shiny::uiOutput("role_detail"),
            shiny::tags$section(class = "rw-method-card", shiny::tags$div(shiny::tags$span(class = "rw-eyebrow", "Analysis plan"), shiny::tags$h2("Choose the method to review")), shiny::selectInput("analysis", "Analysis method", choices = c("Automatic rule" = "auto", "Descriptive" = "describe", "Linear model" = "lm", "Binary GLM" = "glm"))),
            shiny::actionButton("create_workflow", "Create reviewable workflow", class = "rw-button rw-button-primary"), shiny::uiOutput("workflow_summary")
          ),
          shiny::tagList(back_button("wizard_back_5"), next_button("wizard_next_5", "Review workflow path"))
        ),
        screen(6, "Workflow / Approval", "Review the path before you run it", "The full DAG remains available, while this view shows only the active stages for the approved path.",
          shiny::tagList(
            shiny::uiOutput("workflow_path"),
            shiny::uiOutput("execution_error"),
            shiny::tags$div(class = "rw-review-grid",
              shiny::tags$section(class = "rw-approval-list", icon_heading("user-check", "Human approvals"), shiny::checkboxInput("approve_question", "I approve the analytical question and decision boundary."), shiny::checkboxInput("approve_roles", "I approve outcome, predictors, and review slices."), shiny::checkboxInput("approve_method", "I approve the statistical method and limitations."), shiny::checkboxInput("approve_missing", "I approve missing-value and retained-row rules."), shiny::uiOutput("approval_status")),
              shiny::tags$aside(class = "rw-ready-card", icon_heading("circle-play", "Ready to run"), shiny::tags$dl(shiny::tags$div(shiny::tags$dt(shiny::icon("laptop"), " Execution"), shiny::tags$dd("Local R")), shiny::tags$div(shiny::tags$dt(shiny::icon("dice"), " Seed"), shiny::tags$dd("2026")), shiny::tags$div(shiny::tags$dt(shiny::icon("shield-halved"), " Telemetry"), shiny::tags$dd("None")), shiny::tags$div(shiny::tags$dt(shiny::icon("box-archive"), " Output"), shiny::tags$dd("Portable HTML + Quarto"))), shiny::textInput("output_dir", "Output directory", value = output_dir))
            )
          ),
          shiny::tagList(back_button("wizard_back_6"), shiny::actionButton("build_workflow", "Run approved workflow", class = "rw-button rw-button-primary"))
        ),
        screen(7, "Evidence / Ready", "Your workflow is ready to open", "The compiled workspace starts in Focus mode and keeps Trace, Claim, Receipt, and Handoff one click away.",
          shiny::tagList(shiny::uiOutput("build_status"), shiny::tags$section(class = "rw-completion-list",
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("circle-check")), shiny::tags$strong("Data approved"), shiny::tags$span("Source and roles recorded")),
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("rotate")), shiny::tags$strong("Analysis executed"), shiny::tags$span("Seed and environment recorded")),
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("link")), shiny::tags$strong("Evidence linked"), shiny::tags$span("Table, 2D, 3D share IDs")),
            shiny::tags$div(shiny::tags$span(class = "rw-completion-icon", `aria-hidden` = "true", shiny::icon("file-shield")), shiny::tags$strong("Receipt ready"), shiny::tags$span("Activity work remains pending"))))
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
    published_paths <- character()
    current_href <- shiny::reactiveVal(NULL)
    session$onSessionEnded(function() {
      for (prefix in published_paths) shiny::removeResourcePath(prefix)
    })
    approval_flags <- shiny::reactiveValues(question = FALSE, roles = FALSE, method = FALSE, missing = FALSE)
    for (key in c("question", "roles", "method", "missing")) local({
      approval_key <- key
      shiny::observeEvent(input[[paste0("approve_", approval_key)]], {
        approval_flags[[approval_key]] <- isTRUE(input[[paste0("approve_", approval_key)]])
      }, ignoreInit = TRUE)
    })
    reset_plan <- function() {
      current_workflow(NULL); current_build(NULL); current_href(NULL)
      for (key in c("question", "roles", "method", "missing")) approval_flags[[key]] <- FALSE
      for (id in c("approve_question", "approve_roles", "approve_method", "approve_missing")) {
        shiny::updateCheckboxInput(session, id, value = FALSE)
      }
    }
    shiny::observeEvent(list(input$role, input$question, input$outcome, input$predictors,
                            input$slice_by, input$analysis, input$missing_tokens,
                            input$unit_of_observation), {
      reset_plan()
    }, ignoreInit = TRUE, priority = 100)
    shiny::observeEvent(list(input$provider, input$local_file, input$dataset_id,
                            input$revision, input$config, input$split, input$source_file), {
      current_source(NULL); current_manifest(NULL); current_preview(NULL)
      current_dataset(NULL); current_profile(NULL); reset_plan()
    }, ignoreInit = TRUE, priority = 110)
    shiny::observeEvent(input$max_rows, {
      current_dataset(NULL); current_profile(NULL); reset_plan()
    }, ignoreInit = TRUE, priority = 100)
    output$current_step <- shiny::renderText(current_step())
    shiny::outputOptions(output, "current_step", suspendWhenHidden = FALSE)
    shiny::observe({
      step <- current_step()
      phase <- if (step <= 3L) "nav_data" else if (step == 4L) "nav_question" else if (step <= 6L) "nav_workflow" else "nav_evidence"
      session$sendCustomMessage("rclaimlab-step", list(step = step, phase = phase, hasDataset = !is.null(current_dataset()), hasWorkflow = !is.null(current_workflow())))
    })

    go <- function(id, step) shiny::observeEvent(input[[id]], current_step(step), ignoreInit = TRUE)
    go("wizard_back_2", 1L); go("wizard_back_3", 2L); go("wizard_back_4", 3L); go("wizard_back_5", 4L); go("wizard_back_6", 5L)
    go("nav_data", 1L)
    shiny::observeEvent(input$nav_question, { if (!is.null(current_dataset())) current_step(4L) }, ignoreInit = TRUE)
    shiny::observeEvent(input$nav_workflow, { if (!is.null(current_dataset())) current_step(5L) }, ignoreInit = TRUE)
    shiny::observeEvent(input$nav_evidence, { if (!is.null(current_workflow())) current_step(6L) }, ignoreInit = TRUE)
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
    go("change_mode", 1L)
    output$purpose_detail <- shiny::renderUI({
      workflow_launcher_detail(input$role %||% "guided_learning")
    })

    source_from_input <- function() {
      if (input$provider == "local") {
        if (is.null(input$local_file)) stop("Choose a local tabular file", call. = FALSE)
        dataset_source("local", input$local_file$datapath)
      } else dataset_source(input$provider, input$dataset_id,
        revision = empty_to_null(input$revision), config = if (input$provider == "huggingface") empty_to_null(input$config) else NULL,
        split = if (input$provider == "huggingface") empty_to_null(input$split) else NULL, file = empty_to_null(input$source_file))
    }
    shiny::observeEvent(input$inspect_source, {
      source_error(NULL)
      current_dataset(NULL); current_profile(NULL); reset_plan()
      value <- tryCatch({
        source <- source_from_input(); manifest <- inspect_dataset(source)
        current_source(source); current_manifest(manifest); current_preview(preview_dataset(source, 100L)); TRUE
      }, error = function(error) { source_error(conditionMessage(error)); FALSE })
      if (!value) { current_source(NULL); current_manifest(NULL); current_preview(NULL) }
    })
    load_example <- function() {
      reset_plan(); source_error(NULL); current_dataset(NULL); current_profile(NULL)
      source <- workflow_demo_source()
      current_source(source); current_manifest(inspect_dataset(source))
      current_preview(preview_dataset(source, 100L))
      current_step(3L)
    }
    shiny::observeEvent(input$try_example, load_example())
    shiny::observeEvent(input$launch_example, load_example())
    output$source_status <- shiny::renderUI({
      if (!is.null(source_error())) return(shiny::tags$p(class = "rw-error", source_error()))
      if (!is.null(current_manifest())) shiny::tags$p(class = "rw-success", "Source metadata and preview are ready.")
    })
    output$manifest_summary <- shiny::renderUI({
      value <- current_manifest(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Inspect a source first."))
      shiny::tags$div(class = "rw-manifest",
        summary_cell("Dataset", basename(value$id %||% "Selected source"), "database"),
        summary_cell("Revision", value$revision %||% "Unresolved", "clock-rotate-left"),
        summary_cell("License", if (is.null(value$license) || is.na(value$license)) "Unknown / review required" else value$license, "file-contract"),
        summary_cell("Publication", if (isTRUE(value$publishable)) "Eligible" else "Needs metadata", if (isTRUE(value$publishable)) "circle-check" else "triangle-exclamation"))
    })
    output$preview_table <- shiny::renderTable({ utils::head(current_preview(), 8L) }, striped = TRUE, bordered = FALSE, spacing = "xs")
    shiny::observeEvent(input$import_source, {
      import_error(NULL)
      reset_plan()
      value <- tryCatch({
        dataset <- import_dataset(current_source(), max_rows = input$max_rows)
        current_dataset(dataset); profile <- profile_dataset(dataset); current_profile(profile)
        columns <- names(dataset$data)
        example <- identical(current_source()$id, workflow_demo_source()$id)
        preset <- if (example) workflow_demo(input$role %||% "guided_learning") else NULL
        shiny::updateSelectInput(session, "outcome", choices = c("None" = "", columns), selected = if (example) preset$analysis$outcome %||% "" else "")
        shiny::updateSelectizeInput(session, "predictors", choices = columns, selected = if (example) preset$analysis$predictors else utils::head(columns, min(4L, length(columns))), server = TRUE)
        shiny::updateSelectizeInput(session, "slice_by", choices = columns, selected = if (example) preset$analysis$slice_by else character(), server = TRUE)
        if (example) {
          shiny::updateTextAreaInput(session, "question", value = preset$analysis$question)
          shiny::updateSelectInput(session, "analysis", selected = preset$analysis$method)
          shiny::updateTextInput(session, "missing_tokens", value = "")
        }
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
      shiny::tags$div(class = "rw-stat-strip",
        summary_cell(if (is.null(dataset)) "Preview rows" else "Imported rows", format(rows, big.mark = ","), "table-list"),
        summary_cell("Columns", cols, "table-columns"),
        summary_cell("Parsed NA", paste0(missing, "%"), "circle-question"),
        summary_cell("Source", current_manifest()$provider %||% "Pending", "database"))
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
      dataset <- current_dataset()
      outcome_values <- if (!is.null(dataset) && !is.null(outcome) && outcome %in% names(dataset$data)) dataset$data[[outcome]] else NULL
      unique_outcomes <- unique(outcome_values[!is.na(outcome_values)])
      descriptive_role <- input$role %in% c("guided_learning", "data_analyst")
      recommendation <- if (descriptive_role || is.null(outcome)) "describe" else if (length(unique_outcomes) == 2L) "glm" else if (is.numeric(outcome_values)) "lm" else "describe"
      labels <- c(describe = "Descriptive evidence", lm = "Linear model (lm)", glm = "Binary GLM (glm)")
      method_key <- if (selected == "auto") recommendation else selected
      reason <- if (descriptive_role && selected == "auto") {
        "This mode defaults to descriptive evidence. Select a model explicitly if it fits your question."
      } else if (is.null(outcome)) {
        "No outcome is assigned, so the workflow starts with distributions and comparisons."
      } else if (recommendation == "glm") {
        paste0("'", outcome, "' has two observed levels, so a binary GLM is the reviewable default.")
      } else if (recommendation == "lm") {
        paste0("'", outcome, "' is numeric, so a linear model is the reviewable default.")
      } else {
        paste0("'", outcome, "' is not a binary or numeric outcome, so the workflow begins with descriptive evidence.")
      }
      status <- if (selected == "auto") "Recommended - approval pending" else "Selected explicitly - approval pending"
      shiny::tags$section(class = "rw-suggestion-card",
        shiny::tags$span(class = "rw-suggestion-icon", `aria-hidden` = "true", shiny::icon("wand-magic-sparkles")),
        shiny::tags$div(shiny::tags$span(class = "rw-eyebrow", "Suggested method"), shiny::tags$h2(labels[[method_key]] %||% method_key)),
        shiny::tags$p(reason, shiny::tags$small(" R does not execute until all four approvals are recorded.")),
        shiny::tags$span(class = "rw-pending-badge", shiny::icon("clock"), status))
    })
    output$decision_approval_status <- shiny::renderUI({
      outcome <- empty_to_null(input$outcome)
      decisions <- list(
        list(label = "Question", ready = nzchar(trimws(input$question %||% "")), detail = if (nzchar(trimws(input$question %||% ""))) "Recorded" else "Add a bounded question"),
        list(label = "Variable roles", ready = !is.null(outcome) || length(input$predictors %||% character()) > 0L, detail = if (!is.null(outcome)) paste("Outcome:", outcome) else "Descriptive path"),
        list(label = "Missing values", ready = !is.null(current_dataset()), detail = if (!is.null(current_dataset())) "Review before execution" else "Import data first"),
        list(label = "Method", ready = FALSE, detail = "Approval occurs before execution")
      )
      shiny::tags$ul(lapply(decisions, function(item) shiny::tags$li(
        class = if (item$ready) "ready" else "pending",
        shiny::tags$span(class = "rw-decision-icon", `aria-hidden` = "true", shiny::icon(if (item$ready) "circle-check" else "clock")),
        shiny::tags$span(shiny::tags$strong(item$label), shiny::tags$small(item$detail))
      )))
    })
    output$role_detail <- shiny::renderUI({
      role <- input$role %||% "guided_learning"
      details <- workflow_role_presentation(role)
      shiny::tags$div(class = "rw-role-detail", shiny::tags$span(class = "rw-eyebrow", details$path),
        shiny::tags$h2(workflow_role_label(role)), shiny::tags$p(details$goal),
        shiny::tags$strong(details$output),
        shiny::tags$small("The source stays linked. Activities and analysis evidence depend on your approved plan."))
    })
    shiny::observeEvent(input$create_workflow, {
      workflow_error(NULL)
      reset_plan()
      tryCatch({
        outcome <- empty_to_null(input$outcome)
        tokens <- trimws(strsplit(input$missing_tokens %||% "", ",", fixed = TRUE)[[1]])
        tokens <- tokens[nzchar(tokens)]
        workflow <- workflow_from_dataset(current_dataset(), role = input$role, outcome = outcome,
          predictors = input$predictors, slice_by = input$slice_by, analysis = input$analysis,
          question = empty_to_null(input$question), missing_values = tokens,
          title = paste(workflow_role_label(input$role), "workflow"))
        if (identical(current_source()$id, workflow_demo_source()$id)) {
          preset <- workflow_demo(input$role)
          if (identical(workflow$analysis, preset$analysis)) workflow <- preset
        }
        workflow$analysis$unit_of_observation <- empty_to_null(input$unit_of_observation)
        current_workflow(workflow)
      }, error = function(error) { workflow_error(conditionMessage(error)); current_workflow(NULL) })
    })
    output$workflow_summary <- shiny::renderUI({
      if (!is.null(workflow_error())) return(shiny::tags$p(class = "rw-error", workflow_error()))
      value <- current_workflow(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Create a workflow after reviewing its inputs."))
      shiny::tagList(shiny::tags$p(class = "rw-success", workflow_role_label(value$role), " workflow created with ", length(value$activities), " activities."),
        shiny::tags$details(class = "rw-activity-details", shiny::tags$summary("Show all activities"), shiny::tags$ol(lapply(value$activities, function(activity) shiny::tags$li(shiny::tags$strong(workflow_activity_presentation(value$role, activity$type)$label), ": ", activity$prompt)))))
    })
    output$workflow_path <- shiny::renderUI({
      value <- current_workflow(); if (is.null(value)) return(shiny::tags$p(class = "rw-error", "Create a workflow first."))
      views <- lapply(value$activities, function(activity) workflow_activity_presentation(value$role, activity$type))
      phases <- vapply(views, `[[`, character(1), "phase")
      # Run-length grouping preserves DAG order, including reviewer reproduction.
      group_ids <- cumsum(c(TRUE, phases[-1L] != phases[-length(phases)]))
      shiny::tagList(
        shiny::tags$p(class = "rw-muted", "Planned activities in execution order. Analysis has not run; outputs below are expected, not completed."),
        shiny::tags$div(class = "rw-path", lapply(unique(group_ids), function(group) {
          indices <- which(group_ids == group)
          shiny::tags$section(
            shiny::tags$span(class = "rw-stage-icon", `aria-hidden` = "true", shiny::icon(switch(value$activities[[indices[[1L]]]]$type, frame = "bullseye", inspect = "shield-halved", split = "code-branch", diagnose = "chart-line", explain = "comment", challenge = "arrows-rotate", communicate = "file-lines", "diagram-project"))),
            shiny::tags$h2(phases[[indices[[1L]]]]),
            shiny::tags$ol(start = indices[[1L]], lapply(indices, function(index) {
              activity <- value$activities[[index]]
              shiny::tags$li(`data-activity-id` = activity$id,
                `data-input-artifacts` = paste(activity$input_artifacts, collapse = ","),
                `data-output-types` = activity$output_type,
                shiny::tags$strong(views[[index]]$label),
                shiny::tags$details(shiny::tags$summary("Input, task, and output"),
                  shiny::tags$p(activity$prompt),
                  shiny::tags$dl(class = "rw-io",
                    shiny::tags$div(shiny::tags$dt("Input"), shiny::tags$dd(
                      if (length(activity$input_artifacts)) paste(activity$input_artifacts, collapse = ", ") else "Question and approved plan")),
                    shiny::tags$div(shiny::tags$dt("Expected output"), shiny::tags$dd(paste(activity$output_type, views[[index]]$note, sep = ": "))),
                    shiny::tags$div(shiny::tags$dt("Criteria"), shiny::tags$dd(paste(activity$criteria, collapse = "; "))))))
            })))
        })))
    })
    approvals_ready <- shiny::reactive(all(vapply(c("question", "roles", "method", "missing"),
      function(key) isTRUE(approval_flags[[key]]), logical(1))))
    output$approval_status <- shiny::renderUI({
      if (approvals_ready()) shiny::tags$p(class = "rw-success", "All execution approvals are recorded.") else shiny::tags$p(class = "rw-muted", "All four approvals are required before R execution.")
    })
    output$execution_error <- shiny::renderUI({
      if (!is.null(build_error())) shiny::tags$p(class = "rw-error", role = "alert", build_error())
    })
    shiny::observeEvent(input$build_workflow, {
      build_error(NULL)
      tryCatch({
        if (is.null(current_workflow())) stop("Create a workflow first", call. = FALSE)
        if (!approvals_ready()) stop("All four approvals are required", call. = FALSE)
        workflow <- approve_workflow(current_workflow()); run <- run_workflow(workflow)
        parent <- normalizePath(input$output_dir, winslash = "/", mustWork = FALSE)
        dir.create(parent, recursive = TRUE, showWarnings = FALSE)
        destination <- tempfile(pattern = paste0(workflow$id, "-"), tmpdir = parent)
        build <- compile_workflow(run, destination); write_workflow_receipt(run, destination)
        # A parent landing page is portable; only its local-session return link
        # is meaningful while this Shiny process is running.
        landing <- paste0('<!doctype html><html lang="en"><meta charset="utf-8"><title>Change mode</title>',
          '<h1>Choose another mode</h1><p><a href="../">Return to the local R wizard</a></p>',
          '<p>For an exported folder, open RStudio and run <code>rclaimlab::run_workflow_wizard()</code>.</p></html>')
        writeLines(landing, file.path(destination, "index.html"))
        primary <- workflow_primary_artifact(run$bundle)
        evidence <- run$bundle$artifacts[[primary]]
        contract <- workflow_browser_contract(run, primary, evidence,
          workflow_visual_sample(as.data.frame(evidence), 1000L, workflow$analysis$seed))
        writeLines(workflow_html(workflow$title, contract, "../index.html"), file.path(destination, "app", "index.html"), useBytes = TRUE)
        prefix <- paste0("workspace-", basename(tempfile()))
        shiny::addResourcePath(prefix, normalizePath(destination, winslash = "/", mustWork = TRUE))
        published_paths <- c(published_paths, prefix)
        current_href(paste0(prefix, "/app/index.html"))
        current_build(build); current_step(7L)
      }, error = function(error) { build_error(conditionMessage(error)); current_build(NULL) })
    })
    output$build_status <- shiny::renderUI({
      if (!is.null(build_error())) return(shiny::tags$p(class = "rw-error", build_error()))
      value <- current_build(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Run the approved workflow to create the portable workspace."))
      shiny::tags$div(class = "rw-build", shiny::tags$span(class = "rw-eyebrow", "Compiled successfully"), shiny::tags$h2("Open the focused evidence workspace"), shiny::tags$p(sum(value$checks$status == "PASS"), " reproducibility checks passed."), shiny::tags$code(basename(value$output_dir)), shiny::tags$a(class = "rw-button rw-button-primary", href = current_href(), target = "_blank", rel = "noopener", "Open portable workspace"))
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
  ".rw-local{display:inline-flex;align-items:center;gap:6px}.rw-button .fa-solid{margin-right:7px}.rw-choice-icon{width:46px;height:46px;font-size:18px}.rw-choice-copy{grid-template-columns:48px minmax(0,1fr)}.rw-heading-icon{display:inline-grid;place-items:center;width:30px;height:30px;margin-right:8px;border-radius:8px;background:var(--soft-blue);color:var(--blue);font-size:12px;vertical-align:middle}.rw-upload-label{display:grid;justify-items:center;gap:6px}.rw-upload-label strong,.rw-upload-label small{display:block}.rw-upload-label small{color:var(--muted);font-size:10px;font-weight:500}.rw-upload-icon{display:grid;place-items:center;width:56px;height:56px;margin-bottom:4px;border-radius:50%;background:#fff;color:var(--blue);font-size:22px;box-shadow:0 6px 18px rgba(23,87,215,.13)}.rw-guardrails{display:grid;grid-template-columns:repeat(3,minmax(0,1fr))}.rw-guardrails .rw-icon-note{padding:9px 10px}.rw-icon-note{display:grid;grid-template-columns:32px minmax(0,1fr);align-items:center;gap:9px;min-width:0}.rw-note-icon{display:grid!important;place-items:center;width:32px;height:32px;padding:0!important;border:0!important;border-radius:9px!important;background:var(--soft-blue)!important;color:var(--blue)!important;font-size:12px!important}.rw-icon-note strong,.rw-icon-note small{display:block}.rw-icon-note strong{font-size:10px}.rw-icon-note small{margin-top:2px;color:var(--muted);font-size:9px}.rw-guide-list{display:grid;gap:0}.rw-guide-list .rw-icon-note{padding:11px 0;border-top:1px solid var(--line)}.rw-manifest .rw-summary-icon,.rw-stat-strip .rw-summary-icon{display:grid;place-items:center;width:32px;height:32px;margin-bottom:8px;border-radius:9px;background:var(--soft-blue);color:var(--blue);font-size:13px;text-transform:none}.rw-suggestion-icon{display:grid!important;place-items:center;flex:0 0 46px;width:46px;height:46px;border-radius:12px;background:#fff;color:var(--blue)!important;font-size:18px!important;box-shadow:0 5px 16px rgba(23,87,215,.11)}.rw-suggestion-card p small{display:block;margin-top:4px}.rw-pending-badge{display:inline-flex!important;align-items:center;gap:5px;white-space:nowrap}.rw-approval-preview li{display:grid;grid-template-columns:28px minmax(0,1fr);align-items:center;gap:8px}.rw-decision-icon{grid-row:1/3;display:grid;place-items:center;width:27px;height:27px;border-radius:8px;background:#fff;color:var(--amber)}.rw-approval-preview li.ready .rw-decision-icon{background:var(--green-soft);color:var(--green)}.rw-approval-preview li span:last-child,.rw-approval-preview li strong,.rw-approval-preview li small{display:block}.rw-approval-preview li small{margin-top:2px;color:var(--muted);font-size:9px}.rw-path section{min-height:230px}.rw-stage-icon{width:42px!important;height:42px!important;font-size:16px!important}.rw-io{margin:12px 0 0}.rw-io>div{padding:8px 0;border-top:1px solid var(--line)}.rw-io dt{color:var(--blue);font-size:8px;font-weight:850;text-transform:uppercase}.rw-io dd{margin:3px 0 0;overflow-wrap:anywhere;color:var(--muted);font-size:8px}.rw-ready-card dt{display:inline-flex;align-items:center;gap:4px}.rw-ready-card dt .fa-solid{color:var(--blue)}@media(max-width:820px){.rw-guardrails{grid-template-columns:1fr}.rw-choice-icon{width:40px;height:40px}.rw-choice-copy{grid-template-columns:42px minmax(0,1fr)}}",
  "@media(max-width:820px){.rw-phase-list{scrollbar-width:none;scroll-snap-type:x proximity}.rw-phase-list::-webkit-scrollbar{display:none}.rw-phase{scroll-snap-align:start}}",
  ".rw-purpose-options .radio-inline,.rw-source-options .radio-inline,.rw-role-options .radio-inline{position:relative;padding:18px 50px 18px 18px}.rw-purpose-options input[type=radio],.rw-source-options input[type=radio],.rw-role-options input[type=radio]{position:absolute;top:18px;right:18px;width:18px;height:18px;margin:0;accent-color:var(--blue)}.rw-source-options .radio-inline{padding-top:16px;padding-bottom:16px}.rw-source-options input[type=radio]{top:16px}@media(max-width:520px){.rw-purpose-options .radio-inline,.rw-source-options .radio-inline,.rw-role-options .radio-inline{padding:16px 46px 16px 16px}.rw-purpose-options input[type=radio],.rw-source-options input[type=radio],.rw-role-options input[type=radio]{top:16px;right:16px}}",
  ".rw-source-panel .rw-dropzone{position:relative;cursor:copy;transition:border-color .16s ease,background-color .16s ease,box-shadow .16s ease}.rw-source-panel .rw-dropzone:focus-visible{outline:3px solid rgba(23,87,215,.22);outline-offset:3px}.rw-source-panel .rw-dropzone.is-dragover{border:2px solid var(--blue);background:#eaf2ff;box-shadow:0 0 0 4px rgba(23,87,215,.12)}.rw-source-panel .rw-dropzone.has-file{border-color:#82c5a0;background:var(--green-soft)}.rw-source-panel .rw-dropzone.drop-error{border-color:#d96d63;background:#fff1f0}.rw-drop-status{min-height:22px;margin:8px 0 0;color:var(--muted);font-size:10px;text-align:center}.rw-drop-status[data-state=drag]{color:var(--blue);font-weight:800}.rw-drop-status[data-state=success]{color:var(--green);font-weight:800}.rw-drop-status[data-state=error]{color:#9a2b21;font-weight:800}.rw-dropzone.has-file .rw-upload-icon{background:var(--green);color:#fff}.rw-dropzone.is-dragover .rw-upload-icon{transform:translateY(-3px)}@media(prefers-reduced-motion:reduce){.rw-source-panel .rw-dropzone,.rw-dropzone .rw-upload-icon{transition:none}}",
  ".rw-brand-logo{display:block;width:38px;height:38px;border-radius:10px}.rw-phase.disabled{pointer-events:none;opacity:.48}.rw-phase.disabled:hover,.rw-phase.disabled:focus{background:transparent;color:var(--muted)}.rw-suggestion-card{display:grid;grid-template-columns:46px minmax(150px,.72fr) minmax(220px,1.3fr) auto;align-items:center}.rw-suggestion-card>div{min-width:0}.rw-suggestion-card p{min-width:0;overflow-wrap:anywhere}.rw-pending-badge{max-width:210px;white-space:normal;text-align:right}@media(max-width:1100px){.rw-suggestion-card{grid-template-columns:46px minmax(0,1fr)}.rw-suggestion-card p,.rw-suggestion-card .rw-pending-badge{grid-column:2;max-width:none;text-align:left}}@media(max-width:820px){.rw-suggestion-card{display:grid;grid-template-columns:42px minmax(0,1fr)}.rw-suggestion-card .rw-suggestion-icon{grid-row:1/4}.rw-suggestion-card p,.rw-suggestion-card .rw-pending-badge{grid-column:2}}",
  ".rw-purpose-options .shiny-options-group{grid-template-columns:repeat(2,minmax(0,1fr))}.rw-button{min-height:44px;white-space:normal}.rw-mode-path{font-size:13px;line-height:1.8;overflow-wrap:anywhere}.rw-path{grid-template-columns:repeat(auto-fit,minmax(min(100%,230px),1fr));align-items:start}.rw-path ol{margin:0;padding-left:20px}.rw-path li{padding:10px 0;overflow-wrap:anywhere}.rw-path li+li{border-top:1px solid var(--line)}.rw-path li>strong{font-size:13px}.rw-path summary{min-height:44px;display:flex;align-items:center;color:var(--blue);font-size:12px;cursor:pointer}.rw-path p,.rw-io dd{font-size:12px}.rw-path details:focus-within{outline:2px solid var(--blue);outline-offset:3px}.rw-purpose-options .radio-inline:focus-within{outline:3px solid var(--blue);outline-offset:3px}@media(max-width:520px){.rw-purpose-options .shiny-options-group{grid-template-columns:1fr}}",
  ".rw-approval-list .checkbox label{min-height:44px;display:flex;align-items:center;padding-left:28px}.rw-approval-list .checkbox input{margin-top:0;margin-left:-24px;width:18px;height:18px}.rw-path section{box-shadow:none}",
  sep = ""
)
