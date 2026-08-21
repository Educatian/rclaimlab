run_rlearnxr_shiny <- function(lesson_dir = NULL, catalog = default_course_catalog(),
                               host = "127.0.0.1", port = getOption("shiny.port"),
                               launch.browser = interactive(), quiet = FALSE) {
  app <- build_rlearnxr_shiny_app(lesson_dir = lesson_dir, catalog = catalog)
  shiny::runApp(app, host = host, port = port, launch.browser = launch.browser, quiet = quiet)
}

build_rlearnxr_shiny_app <- function(lesson_dir = NULL, catalog = default_course_catalog()) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop(
      "The optional Shiny shell requires the 'shiny' package. Install it with install.packages('shiny').",
      call. = FALSE
    )
  }
  validate_course_catalog(catalog)

  if (!is.null(lesson_dir)) {
    lesson_dir <- normalizePath(lesson_dir, winslash = "/", mustWork = FALSE)
    if (!dir.exists(lesson_dir)) stop("lesson_dir does not exist", call. = FALSE)
  }

  modules <- catalog$modules
  module_ids <- vapply(modules, function(module) as.character(module$id), character(1))
  module_titles <- vapply(modules, function(module) {
    paste0(module$title, " (", module$track, ")")
  }, character(1))
  names(module_titles) <- module_ids

  selected_module_id <- function(module_id) {
    if (length(module_id) != 1L || is.na(module_id) || !(module_id %in% module_ids)) {
      return(module_ids[[1L]])
    }
    as.character(module_id)
  }

  module_path <- function(module_id) {
    if (is.null(lesson_dir)) return(NULL)
    module <- modules[[match(selected_module_id(module_id), module_ids)]]
    relative <- sub("/scene/index\\.html$", "", module$lesson_path)
    roots <- unique(c(lesson_dir, file.path(lesson_dir, "examples")))
    for (root in roots) {
      candidate <- normalizePath(file.path(root, relative), winslash = "/", mustWork = FALSE)
      if (file.exists(file.path(candidate, "lesson-manifest.json"))) return(candidate)
    }
    if (file.exists(file.path(lesson_dir, "lesson-manifest.json"))) return(lesson_dir)
    NULL
  }

  open_lesson_href <- function(module_id) {
    module_id <- selected_module_id(module_id)
    path <- module_path(module_id)
    if (!is.null(path)) {
      scene <- file.path(path, "scene", "index.html")
      if (file.exists(scene)) return(paste0("file:///", gsub("\\\\", "/", scene)))
    }
    modules[[match(module_id, module_ids)]]$lesson_path
  }

  app_ui <- shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$title("R-LearnXR educator console"),
      shiny::tags$style(shiny::HTML("\n        body { background:#f6f7f9; color:#17202a; font-family:Inter,system-ui,sans-serif; }\n        .container-fluid { max-width:1180px; padding:28px 24px 48px; }\n        .rlearnxr-header { border-bottom:1px solid #d9dee7; margin-bottom:22px; padding-bottom:18px; }\n        .rlearnxr-header h1 { font-size:28px; margin:0 0 6px; letter-spacing:-.02em; }\n        .rlearnxr-header p { color:#566273; margin:0; }\n        .rlearnxr-panel { background:#fff; border:1px solid #d9dee7; border-radius:10px; padding:18px; margin-bottom:16px; }\n        .rlearnxr-panel h3 { font-size:16px; margin-top:0; }\n        .btn { min-height:44px; border-radius:8px; }\n        .btn + .btn { margin-top:8px; }\n        .rlearnxr-status { border-left:4px solid #2368a2; background:#eef6fc; padding:12px 14px; }\n        .rlearnxr-pass { color:#176b45; font-weight:600; }\n        .rlearnxr-fail { color:#a62828; font-weight:600; }\n        .rlearnxr-muted { color:#566273; }\n        table.dataTable { width:100% !important; }\n      "))
    ),
    shiny::tags$style(shiny::HTML(".shiny-text-output{overflow-wrap:anywhere;white-space:pre-wrap}.shiny-table-output{max-width:100%;overflow-x:auto}.shiny-table-output table{min-width:620px}@media(max-width:600px){.container-fluid{padding:20px 14px 36px}.rlearnxr-panel{padding:14px}.rlearnxr-header h1{font-size:25px}}")),
    shiny::div(class = "rlearnxr-header",
      shiny::h1("R-LearnXR educator console"),
      shiny::p("Author, inspect, and release a reproducible R lesson. The learner-facing lesson remains a portable Quarto/WebR page.")
    ),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::h3("Lesson workspace"),
        shiny::selectInput("module_id", "Reference module", choices = module_titles),
        shiny::actionButton("validate_catalog", "Validate course catalog", class = "btn-primary"),
        shiny::actionButton("check_lesson", "Run strict lesson check"),
        shiny::uiOutput("open_lesson"),
        shiny::tags$hr(),
        shiny::p(class = "rlearnxr-muted",
          if (is.null(lesson_dir)) {
            "Start the console with lesson_dir = the repository root to enable local lesson checks and browser links."
          } else {
            paste("Workspace:", lesson_dir)
          }
        )
      ),
      shiny::mainPanel(
        shiny::uiOutput("module_summary"),
        shiny::div(class = "rlearnxr-panel",
          shiny::h3("Catalog contract"),
          shiny::verbatimTextOutput("catalog_status")
        ),
        shiny::div(class = "rlearnxr-panel",
          shiny::h3("Strict lesson evidence"),
          shiny::uiOutput("check_summary"),
          shiny::tableOutput("check_table")
        ),
        shiny::div(class = "rlearnxr-panel",
          shiny::h3("Architecture boundary"),
          shiny::p("R remains the authoring and analysis source. Quarto provides the lesson structure. WebR executes learner-edited code in the browser. This optional Shiny shell coordinates educator tasks; it is not required to publish or complete a lesson."),
          shiny::tags$code("scaffold_lesson()  \u2192  render_scene()  \u2192  check_lesson(strict = TRUE)")
        )
      )
    )
  )

  app_server <- function(input, output, session) {
    catalog_status <- shiny::reactiveVal("Catalog has not been checked yet.")
    check_result <- shiny::reactiveVal(NULL)

    output$module_summary <- shiny::renderUI({
      module <- modules[[match(selected_module_id(input$module_id), module_ids)]]
      shiny::div(class = "rlearnxr-panel",
        shiny::h3(module$title),
        shiny::p(module$description),
        shiny::p(shiny::strong("Track: "), module$track, " \u00b7 ", module$minutes, " minutes \u00b7 ", module$level),
        shiny::p(shiny::strong("Concepts: "), paste(module$concepts, collapse = ", ")),
        shiny::p(shiny::strong("Learning loop: "), "orient \u2192 predict \u2192 run R \u2192 explore \u2192 explain \u2192 transfer \u2192 reproduce")
      )
    })

    output$open_lesson <- shiny::renderUI({
      shiny::tags$a(
        class = "btn btn-default btn-block",
        href = open_lesson_href(input$module_id),
        target = "_blank",
        rel = "noopener",
        "Open selected lesson"
      )
    })

    shiny::observeEvent(input$validate_catalog, {
      result <- tryCatch({
        validate_course_catalog(catalog)
        "PASS: course catalog satisfies the rlearnxr-course-1 contract."
      }, error = function(error) paste0("FAIL: ", conditionMessage(error)))
      catalog_status(result)
    })

    shiny::observeEvent(input$check_lesson, {
      path <- module_path(input$module_id)
      if (is.null(path)) {
        check_result(data.frame(
          check = "lesson_path", status = "WARN",
          message = "No local lesson folder was resolved. Start with lesson_dir = the repository root.",
          stringsAsFactors = FALSE
        ))
        return()
      }
      check_result(tryCatch(
        check_lesson(path, write_report = FALSE, strict = TRUE),
        error = function(error) data.frame(
          check = "runtime", status = "FAIL", message = conditionMessage(error),
          stringsAsFactors = FALSE
        )
      ))
    })

    output$catalog_status <- shiny::renderText(catalog_status())

    output$check_table <- shiny::renderTable({
      result <- check_result()
      if (is.null(result)) return(NULL)
      result[, c("check", "status", "message"), drop = FALSE]
    }, striped = TRUE, bordered = TRUE, hover = TRUE, spacing = "s")

    output$check_summary <- shiny::renderUI({
      result <- check_result()
      if (is.null(result)) return(shiny::p(class = "rlearnxr-muted", "Run the strict check to inspect release evidence."))
      failed <- sum(result$status == "FAIL")
      warning_count <- sum(result$status == "WARN")
      if (failed == 0L && warning_count == 0L) {
        shiny::div(class = "rlearnxr-status rlearnxr-pass", "PASS: no strict failures or warnings.")
      } else {
        shiny::div(class = "rlearnxr-status rlearnxr-fail", paste0("Needs attention: ", failed, " failure(s), ", warning_count, " warning(s)."))
      }
    })
  }

  shiny::shinyApp(ui = app_ui, server = app_server)
}
