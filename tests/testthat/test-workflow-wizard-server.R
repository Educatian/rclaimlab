test_that("Shiny plans and builds all four modes from local data", {
  skip_if_not_installed("shiny")
  path <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(age = 20:99, hours = rep(30:49, 4),
                             score = (20:99) * 1.3 + sin(20:99)), path, row.names = FALSE)
  root <- tempfile("wizard-output-")
  app <- rclaimlab:::build_workflow_wizard_app(root)
  shiny::testServer(app$serverFuncSource(), {
    session$setInputs(provider = "local", local_file = list(datapath = path),
                      role = "guided_learning", max_rows = 10000,
                      analysis = "auto", question = "What patterns are supported?",
                      predictors = c("age", "hours"), outcome = "", output_dir = root)
    session$setInputs(inspect_source = 1)
    expect_null(source_error())
    session$setInputs(import_source = 1)
    expect_null(import_error())
    for (role in c("guided_learning", "data_analyst", "data_scientist", "model_reviewer")) {
      session$setInputs(role = role, outcome = if (role %in% c("data_scientist", "model_reviewer")) "score" else "")
      session$setInputs(create_workflow = match(role, c("guided_learning", "data_analyst", "data_scientist", "model_reviewer")))
      expect_null(workflow_error())
      expect_identical(current_workflow()$role, role)
      view <- output$workflow_path$html
      labels <- vapply(current_workflow()$activities, function(a) rclaimlab:::workflow_activity_presentation(role, a$type)$label, character(1))
      for (label in labels) expect_match(view, htmltools::htmlEscape(label), fixed = TRUE)
      if (role == "guided_learning") {
        expect_match(current_workflow()$activities[[1]]$prompt, "predict")
        expect_match(current_workflow()$activities[[6]]$prompt, "different dataset")
      }
      session$setInputs(approve_question = FALSE, approve_roles = FALSE,
                        approve_method = FALSE, approve_missing = FALSE)
      session$setInputs(build_workflow = paste0(role, "-blocked"))
      expect_null(current_build())
      expect_match(build_error(), "four approvals")
      expect_match(output$execution_error$html, "four approvals")
      session$setInputs(approve_question = TRUE, approve_roles = TRUE,
                        approve_method = TRUE, approve_missing = TRUE)
      session$setInputs(build_workflow = role)
      expect_null(build_error())
      expect_s3_class(current_build(), "rclaimlab_workflow_build")
      expect_match(current_href(), "^workspace-[^/]+/app/index.html$")
      expect_true(file.exists(file.path(current_build()$output_dir, "app", "index.html")))
      first <- current_build()$output_dir
      session$setInputs(build_workflow = paste0(role, "-second"))
      expect_false(identical(first, current_build()$output_dir))
      expect_true(file.exists(file.path(first, "app", "index.html")))
      session$setInputs(question = paste("Changed question", role))
      expect_null(current_workflow())
      expect_null(current_build())
      expect_false(approvals_ready())
    }
    session$setInputs(revision = "changed")
    expect_null(current_dataset())
    expect_null(current_manifest())
    session$setInputs(try_example = 1)
    expect_equal(nrow(current_preview()), 100L)
    expect_equal(current_step(), 3L)
    expect_false(current_manifest()$publishable)
  })
})
