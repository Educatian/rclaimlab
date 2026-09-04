# Shared launcher markup: Shiny is an optional authoring/build dependency only.
workflow_launcher <- function(local = TRUE) {
  roles <- c("guided_learning", "data_analyst", "data_scientist", "model_reviewer")
  icons <- c("graduation-cap", "chart-column", "chart-line", "shield-halved")
  copy <- lapply(seq_along(roles), function(i) shiny::tags$span(class = "rw-choice-copy",
    shiny::tags$span(class = "rw-choice-icon", `aria-hidden` = "true", shiny::icon(icons[[i]])),
    shiny::tags$span(class = "rw-choice-text", shiny::tags$strong(workflow_role_label(roles[[i]])),
      shiny::tags$small(workflow_role_presentation(roles[[i]])$goal))))
  shiny::tags$div(class = "rw-launcher",
    shiny::tags$div(class = "rw-purpose-layout",
      shiny::tags$div(class = "rw-purpose-main",
        shiny::tags$div(class = "rw-purpose-options", shiny::radioButtons("role", "Choose your mode",
          choiceNames = copy, choiceValues = roles, selected = "guided_learning", inline = TRUE)),
        shiny::tags$p(class = "rw-launcher-note", "One dataset, different responsibilities. Start with an example or bring your own data.")),
      shiny::tags$aside(class = "rw-launcher-companion", `aria-label` = "Selected mode",
        if (local) shiny::uiOutput("purpose_detail") else shiny::tags$div(id = "purpose_detail", workflow_launcher_detail("guided_learning")),
        shiny::tags$div(class = "rw-launcher-actions",
          shiny::actionButton("launch_example", "Open example", icon = shiny::icon("flask"), class = "rw-button rw-button-primary"),
          shiny::actionButton("wizard_next_1", "Use my data", icon = shiny::icon("database"), class = "rw-button rw-button-secondary")),
        shiny::tags$p(class = "rw-launcher-note", if (local)
          "Local R: review this fixed example and explicitly approve before execution." else
          "Browser demo: precomputed R evidence. Your own data and full R execution use the local package."))))
}

workflow_launcher_detail <- function(role) {
  details <- workflow_role_presentation(role)
  labels <- vapply(workflow_role_profile(role)$steps, function(type)
    workflow_activity_presentation(role, type)$label, character(1))
  shiny::tags$div(class = "rw-purpose-detail", shiny::tags$h2(workflow_role_label(role)),
    shiny::tags$p(details$goal), shiny::tags$p(class = "rw-mode-path", paste(labels, collapse = " \u2192 ")),
    shiny::tags$strong(paste("Your output:", details$output)))
}

workflow_launcher_css <- function() paste(readLines(
  workflow_template_path("workflow-launcher.css"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

workflow_launcher_page <- function(release_ref) {
  if (!grepl("^[a-f0-9]{40}$", release_ref)) stop("A full tested Git commit is required", call. = FALSE)
  roles <- c(guided = "guided_learning", analyst = "data_analyst", scientist = "data_scientist", reviewer = "model_reviewer")
  views <- lapply(roles, function(role) list(role = role, html = as.character(workflow_launcher_detail(role))))
  script <- paste(readLines(workflow_template_path("workflow-launcher.js"), warn = FALSE), collapse = "\n")
  font <- workflow_template_asset_uri(file.path("icons", "fa-solid-900.woff2"), "font/woff2")
  font_css <- paste0("@font-face{font-family:launcher-icons;src:url('", font, "')} .fas,.fa-solid{font-family:launcher-icons;font-style:normal;font-weight:900}.fa-graduation-cap:before{content:'\\f19d'}.fa-chart-column:before{content:'\\e0e3'}.fa-chart-line:before{content:'\\f201'}.fa-shield-halved:before{content:'\\f3ed'}.fa-flask:before{content:'\\f0c3'}.fa-database:before{content:'\\f1c0'}")
  # tags$head is extracted into htmltools dependencies and lost by as.character.
  # This portable document therefore owns its literal head, with no runtime deps.
  page <- shiny::tags$html(lang = "en", shiny::HTML(paste0(
    '<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">',
    '<title>Choose your mode | R-ClaimLab</title><style>',
    paste(workflow_wizard_css(), workflow_launcher_css(), font_css), '</style></head>')),
    shiny::tags$body(class = "rw-public-launcher",
      shiny::tags$a(class = "rw-skip", href = "#rw-main", "Skip to mode chooser"),
      shiny::tags$header(class = "rw-topbar", shiny::tags$div(class = "rw-brand",
        shiny::tags$img(class = "rw-brand-logo", src = workflow_template_asset_uri(file.path("icons", "rclaimlab-mark.svg"), "image/svg+xml"), alt = ""),
        shiny::tags$strong("R-ClaimLab")), shiny::tags$span("Browser demo / local receipt")),
      shiny::tags$main(id = "rw-main", class = "rw-screen",
        shiny::tags$header(class = "rw-screen-head", shiny::tags$span(class = "rw-eyebrow", "Start with a purpose"),
          shiny::tags$h1("What do you want to do today?"),
          shiny::tags$p("Choose the outcome first. R-ClaimLab reveals only the controls needed for that path.")),
        workflow_launcher(FALSE),
        shiny::tags$section(id = "own-data", hidden = "hidden", tabindex = "-1",
          shiny::tags$h2("Use your data in local R"),
          shiny::tags$p("Install this exact demo version, open the wizard, choose a mode, then select Local file, Hugging Face, or Kaggle. Review the source, variables, method and four approvals before execution."),
          shiny::tags$pre(shiny::tags$code(id = "install-code", paste0(
            "install.packages(c('remotes', 'shiny'))\nremotes::install_github('Educatian/rclaimlab@", release_ref,
            "', upgrade = 'never')\nrclaimlab::run_workflow_wizard()"))),
          shiny::tags$p("This hosted demo does not upload or analyze your private files. Kaggle requires the official CLI; Parquet requires arrow.")),
        shiny::tags$footer(class = "rw-launcher-note", "Synthetic practice data, not real people. ",
          shiny::tags$a(href = "synthetic-workflow-data.csv", "Download the example CSV"), " \u00b7 ",
          shiny::tags$a(href = "release-manifest.json", "Build and source version"))),
      shiny::tags$script(shiny::HTML(paste0("const RCLAIMLAB_LAUNCHER=", gsub("<", "\\u003c", jsonlite::toJSON(views, auto_unbox = TRUE), fixed = TRUE), ";\n", script)))))
  paste0("<!doctype html>\n", as.character(page))
}
