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
  step_card <- function(number, title, content) shiny::tags$section(
    class = "rw-step", shiny::tags$div(class = "rw-step-number", number),
    shiny::tags$div(class = "rw-step-content", shiny::tags$h2(title), content)
  )
  ui <- shiny::fluidPage(
    shiny::tags$head(shiny::tags$style(shiny::HTML(workflow_wizard_css()))),
    shiny::tags$header(class = "rw-topbar",
      shiny::tags$div(class = "rw-brand", shiny::tags$span("R"), shiny::tags$div(shiny::tags$strong("R-ClaimLab"), shiny::tags$small("External data to role workflow"))),
      shiny::tags$div(class = "rw-local", "Local R; credentials are never stored")
    ),
    shiny::tags$main(class = "rw-shell",
      shiny::tags$div(class = "rw-hero", shiny::tags$span("WORKFLOW WIZARD"),
        shiny::tags$h1("Turn a public dataset into traceable data-science work"),
        shiny::tags$p("Inspect the source, approve the analysis boundary, and compile an Analyst, Data Scientist, or Model Reviewer workspace.")),
      step_card("01", "Choose source", shiny::tagList(
        shiny::radioButtons("provider", NULL, inline = TRUE,
          choices = c("Local CSV/TSV/Parquet" = "local", "Hugging Face" = "huggingface", "Kaggle" = "kaggle")),
        shiny::conditionalPanel("input.provider == 'local'", shiny::fileInput("local_file", "Tabular file", accept = c(".csv", ".tsv", ".parquet"))),
        shiny::conditionalPanel("input.provider != 'local'", shiny::textInput("dataset_id", "Dataset ID", placeholder = "owner/dataset"),
          shiny::textInput("revision", "Pinned revision/version", placeholder = "Required for publication"),
          shiny::fluidRow(shiny::column(4, shiny::textInput("config", "Config", placeholder = "default")),
                          shiny::column(4, shiny::textInput("split", "Split", placeholder = "train")),
                          shiny::column(4, shiny::textInput("source_file", "File", placeholder = "Optional")))) ,
        shiny::actionButton("inspect_source", "Inspect source", class = "btn-primary"), shiny::uiOutput("source_status")
      )),
      step_card("02", "Preview and license", shiny::tagList(
        shiny::uiOutput("manifest_summary"), shiny::tableOutput("preview_table"),
        shiny::numericInput("max_rows", "Maximum analysis rows", value = 10000L, min = 20L, max = 10000L),
        shiny::actionButton("import_source", "Import selected data locally"), shiny::uiOutput("import_status")
      )),
      step_card("03", "Profile and missingness", shiny::tagList(
        shiny::tableOutput("profile_table"),
        shiny::textInput("missing_tokens", "Explicit missing tokens (comma separated)", placeholder = "?, N/A"),
        shiny::helpText("No token is changed until this field is approved in step 06." )
      )),
      step_card("04", "Question and variable roles", shiny::tagList(
        shiny::textAreaInput("question", "Analytical question", rows = 2, placeholder = "What can this evidence support?"),
        shiny::selectInput("outcome", "Outcome", choices = character()),
        shiny::selectizeInput("predictors", "Predictors / analysis variables", choices = character(), multiple = TRUE),
        shiny::selectizeInput("slice_by", "Review slices (explicit only)", choices = character(), multiple = TRUE)
      )),
      step_card("05", "Role and method", shiny::tagList(
        shiny::radioButtons("role", NULL, inline = TRUE, choices = c("Data Analyst" = "data_analyst", "Data Scientist" = "data_scientist", "Model Reviewer" = "model_reviewer")),
        shiny::selectInput("analysis", "Analysis", choices = c("Automatic rule" = "auto", "Descriptive" = "describe", "Linear model" = "lm", "Binary GLM" = "glm")),
        shiny::actionButton("create_workflow", "Create reviewable workflow"), shiny::uiOutput("workflow_summary")
      )),
      step_card("06", "Review and approve", shiny::tagList(
        shiny::checkboxInput("approve_question", "I approve the analytical question and decision boundary."),
        shiny::checkboxInput("approve_roles", "I approve the outcome, predictors, and review slices."),
        shiny::checkboxInput("approve_method", "I approve the statistical method and its limitations."),
        shiny::checkboxInput("approve_missing", "I approve the missing-value and retained-row rule."),
        shiny::uiOutput("approval_status")
      )),
      step_card("07", "Build and open", shiny::tagList(
        shiny::textInput("output_dir", "Output directory", value = output_dir),
        shiny::actionButton("build_workflow", "Run R and compile workflow", class = "btn-success"),
        shiny::uiOutput("build_status")
      ))
    )
  )
  server <- function(input, output, session) {
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

    source_from_input <- function() {
      if (input$provider == "local") {
        if (is.null(input$local_file)) stop("Choose a local tabular file", call. = FALSE)
        dataset_source("local", input$local_file$datapath)
      } else dataset_source(
        input$provider, input$dataset_id,
        revision = empty_to_null(input$revision), config = empty_to_null(input$config),
        split = empty_to_null(input$split), file = empty_to_null(input$source_file)
      )
    }
    shiny::observeEvent(input$inspect_source, {
      source_error(NULL)
      value <- tryCatch({
        source <- source_from_input(); manifest <- inspect_dataset(source)
        current_source(source); current_manifest(manifest)
        current_preview(preview_dataset(source, 100L)); TRUE
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
        shiny::tags$div(shiny::tags$span("Revision"), shiny::tags$strong(value$revision %||% "Unresolved")),
        shiny::tags$div(shiny::tags$span("License"), shiny::tags$strong(value$license %||% "Unknown")),
        shiny::tags$div(shiny::tags$span("Publication"), shiny::tags$strong(if (isTRUE(value$publishable)) "Eligible" else "Needs metadata"))
      )
    })
    output$preview_table <- shiny::renderTable({ current_preview() }, striped = TRUE, bordered = TRUE, spacing = "xs")
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
    output$profile_table <- shiny::renderTable({
      value <- current_profile(); if (is.null(value)) return(NULL)
      value$columns[c("column", "type", "missing_percent", "distinct", "role")]
    }, striped = TRUE, bordered = TRUE, spacing = "xs")
    shiny::observeEvent(input$create_workflow, {
      workflow_error(NULL)
      tryCatch({
        outcome <- empty_to_null(input$outcome)
        tokens <- trimws(strsplit(input$missing_tokens %||% "", ",", fixed = TRUE)[[1]])
        tokens <- tokens[nzchar(tokens)]
        workflow <- workflow_from_dataset(
          current_dataset(), role = input$role, outcome = outcome,
          predictors = input$predictors, slice_by = input$slice_by,
          analysis = input$analysis, question = empty_to_null(input$question),
          missing_values = tokens
        )
        current_workflow(workflow)
      }, error = function(error) { workflow_error(conditionMessage(error)); current_workflow(NULL) })
    })
    output$workflow_summary <- shiny::renderUI({
      if (!is.null(workflow_error())) return(shiny::tags$p(class = "rw-error", workflow_error()))
      value <- current_workflow(); if (is.null(value)) return(shiny::tags$p(class = "rw-muted", "Create a workflow after approving its inputs."))
      shiny::tagList(shiny::tags$p(class = "rw-success", workflow_role_label(value$role), " workflow created with ", length(value$activities), " activities."),
        shiny::tags$ol(lapply(value$activities, function(activity) shiny::tags$li(shiny::tags$strong(activity$type), ": ", activity$prompt))))
    })
    approvals_ready <- shiny::reactive(isTRUE(input$approve_question) && isTRUE(input$approve_roles) && isTRUE(input$approve_method) && isTRUE(input$approve_missing))
    output$approval_status <- shiny::renderUI({
      if (approvals_ready()) shiny::tags$p(class = "rw-success", "All execution approvals are recorded.")
      else shiny::tags$p(class = "rw-muted", "All four approvals are required before R execution.")
    })
    shiny::observeEvent(input$build_workflow, {
      build_error(NULL)
      tryCatch({
        if (is.null(current_workflow())) stop("Create a workflow first", call. = FALSE)
        if (!approvals_ready()) stop("All four approvals are required", call. = FALSE)
        workflow <- approve_workflow(current_workflow())
        run <- run_workflow(workflow)
        destination <- file.path(normalizePath(input$output_dir, winslash = "/", mustWork = FALSE), workflow$id)
        build <- compile_workflow(run, destination, overwrite = TRUE)
        write_workflow_receipt(run, destination)
        current_build(build)
      }, error = function(error) { build_error(conditionMessage(error)); current_build(NULL) })
    })
    output$build_status <- shiny::renderUI({
      if (!is.null(build_error())) return(shiny::tags$p(class = "rw-error", build_error()))
      value <- current_build(); if (is.null(value)) return(NULL)
      shiny::tags$div(class = "rw-build", shiny::tags$strong("Workflow compiled"),
        shiny::tags$code(value$output_dir), shiny::tags$p(sum(value$checks$status == "PASS"), " checks passed."),
        shiny::tags$a(href = paste0("file:///", gsub(" ", "%20", file.path(value$output_dir, "app", "index.html"), fixed = TRUE)), target = "_blank", "Open portable workspace"))
    })
  }
  shiny::shinyApp(ui, server)
  # nocov end
}

empty_to_null <- function(value) {
  if (is.null(value) || length(value) != 1L || is.na(value) || !nzchar(trimws(value))) NULL else trimws(value)
}

workflow_wizard_css <- function() paste(
  "*{box-sizing:border-box}body{margin:0;background:#f5f7fb;color:#172033;font:14px/1.5 system-ui,-apple-system,Segoe UI,sans-serif}",
  ".container-fluid{padding:0}.rw-topbar{display:flex;justify-content:space-between;align-items:center;gap:16px;padding:12px 24px;border-bottom:1px solid #d9e0ea;background:#fff}.rw-brand{display:flex;align-items:center;gap:10px}.rw-brand>span{display:grid;place-items:center;width:34px;height:34px;border-radius:9px;background:#2156c7;color:#fff;font-weight:850}.rw-brand strong,.rw-brand small{display:block}.rw-brand small,.rw-local,.rw-muted{color:#5d687c;font-size:11px}",
  ".rw-shell{max-width:1040px;margin:auto;padding:32px 20px 60px}.rw-hero{margin-bottom:24px}.rw-hero>span{color:#2156c7;font-size:10px;font-weight:850;letter-spacing:.08em}.rw-hero h1{max-width:760px;margin:6px 0;font-size:clamp(26px,5vw,44px);line-height:1.05}.rw-hero p{max-width:760px;color:#5d687c}",
  ".rw-step{display:grid;grid-template-columns:52px minmax(0,1fr);gap:16px;margin-top:12px;padding:20px;border:1px solid #d9e0ea;border-radius:12px;background:#fff;box-shadow:0 12px 32px rgba(30,48,78,.06)}.rw-step-number{display:grid;place-items:center;width:42px;height:42px;border-radius:50%;background:#eaf1ff;color:#2156c7;font-weight:850}.rw-step-content{min-width:0}.rw-step-content h2{margin:5px 0 14px;font-size:19px}",
  ".rw-manifest{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin-bottom:12px}.rw-manifest>div{min-width:0;padding:10px;border:1px solid #d9e0ea;border-radius:8px}.rw-manifest span,.rw-manifest strong{display:block;overflow-wrap:anywhere}.rw-manifest span{color:#5d687c;font-size:9px;text-transform:uppercase}.rw-success{padding:8px 10px;border-left:3px solid #157347;background:#eaf7ef;color:#0b5c36}.rw-error{padding:8px 10px;border-left:3px solid #b42318;background:#fff1f0;color:#8b1b13}.rw-build{display:grid;gap:6px;margin-top:12px;padding:14px;border:1px solid #a9d6bd;border-radius:8px;background:#edf8f2}.rw-build code{overflow-wrap:anywhere}",
  "table{display:block;max-width:100%;overflow:auto}input,textarea,.selectize-input{max-width:100%}@media(max-width:640px){.rw-topbar{padding:10px 14px}.rw-local{display:none}.rw-shell{padding:22px 12px 50px}.rw-step{grid-template-columns:1fr;padding:15px}.rw-step-number{width:34px;height:34px}.rw-manifest{grid-template-columns:1fr}}",
  sep = ""
)
