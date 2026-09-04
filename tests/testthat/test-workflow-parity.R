test_that("all mode exports rerun complete approved plans", {
  for (role in c("guided_learning", "data_analyst", "data_scientist", "model_reviewer")) {
    workflow <- rclaimlab:::workflow_demo(role)
    expect_equal(nrow(workflow$dataset$data), 300L)
    expect_error(run_workflow(workflow), "approvals")
    run <- run_workflow(approve_workflow(workflow))
    environment <- new.env(parent = globalenv())
    eval(parse(text = run$execution$source_code), environment)
    replay <- environment$reproduce_workflow()
    expect_identical(replay$workflow$analysis, run$workflow$analysis)
    expect_identical(replay$workflow$activities, run$workflow$activities, ignore_attr = TRUE)
    expect_identical(replay$dataset$source_record_id, run$dataset$source_record_id)
    for (id in names(run$bundle$artifacts)) {
      expect_equal(as.data.frame(replay$bundle$artifacts[[id]]), as.data.frame(run$bundle$artifacts[[id]]))
    }
    expect_identical(replay$bundle$bundle_hash, run$bundle$bundle_hash)
    expect_error(environment$reproduce_workflow(tempfile()), "original source")
    bad <- tempfile(fileext = ".csv")
    writeLines(c("a,b", "1,2"), bad)
    expect_error(environment$reproduce_workflow(bad), "Source content differs")
    expect_false(any(grepl(normalizePath(tempdir(), winslash = "/"), run$execution$source_code, fixed = TRUE)))
  }
})

test_that("launcher and preset definitions are shared and install ref is immutable", {
  skip_if_not_installed("shiny")
  local <- as.character(rclaimlab:::workflow_launcher(TRUE))
  public <- rclaimlab:::workflow_launcher_page(strrep("a", 40))
  for (role in c("guided_learning", "data_analyst", "data_scientist", "model_reviewer")) {
    expect_match(local, paste0('value="', role, '"'), fixed = TRUE)
    expect_match(public, paste0('value="', role, '"'), fixed = TRUE)
    expect_match(public, rclaimlab:::workflow_role_presentation(role)$goal, fixed = TRUE)
  }
  expect_match(public, paste0("Educatian/rclaimlab@", strrep("a", 40)), fixed = TRUE)
  expect_error(rclaimlab:::workflow_launcher_page("main"), "full tested Git commit")
  expect_match(public, "precomputed R evidence", fixed = TRUE)
  expect_match(public, "<head><meta charset=", fixed = TRUE)
  expect_match(public, "<style>", fixed = TRUE)
  expect_match(public, "@font-face", fixed = TRUE)
  expect_match(public, ".fas,.fa-solid{font-family:launcher-icons", fixed = TRUE)
  json <- sub(".*const RCLAIMLAB_LAUNCHER=", "", public)
  json <- strsplit(json, ";\n", fixed = TRUE)[[1]][[1]]
  view <- jsonlite::fromJSON(json)$guided$html
  expect_match(view, '<div class="rw-purpose-detail">', fixed = TRUE)
  expect_false(grepl("\\u003c", view, fixed = TRUE))
})

test_that("Shiny example plans match all four compiled demo plans", {
  skip_if_not_installed("shiny")
  app <- rclaimlab:::build_workflow_wizard_app(tempfile())
  shiny::testServer(app$serverFuncSource(), {
    session$setInputs(provider = "local", max_rows = 10000L, role = "guided_learning")
    expect_null(current_source())
    for (role in c("guided_learning", "data_analyst", "data_scientist", "model_reviewer")) {
      preset <- rclaimlab:::workflow_demo(role)
      session$setInputs(role = role)
      session$setInputs(launch_example = role)
      session$setInputs(import_source = role)
      expect_equal(nrow(current_dataset()$data), 300L)
      # Browser acknowledgement of the preset updates.
      session$setInputs(outcome = preset$analysis$outcome %||% "", predictors = preset$analysis$predictors,
        slice_by = preset$analysis$slice_by, analysis = preset$analysis$method,
        question = preset$analysis$question, missing_tokens = "", unit_of_observation = "")
      session$setInputs(create_workflow = role)
      expect_null(workflow_error())
      expect_identical(current_workflow()$id, preset$id)
      expect_identical(current_workflow()$activities, preset$activities)
      expect_identical(current_workflow()$analysis, preset$analysis)
      expect_false(approvals_ready())
    }
  })
})
