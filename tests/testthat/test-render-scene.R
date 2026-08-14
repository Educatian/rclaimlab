test_that("render_scene creates an accessible complete learning loop", {
  output <- tempfile("rlearnxr-scene-")
  data <- data.frame(
    x = c(-0.5, 0, 0.5),
    y = c(0.25, -0.25, 0.1),
    z = c(0.1, -0.1, 0.3),
    label = c("alpha", "beta", "gamma")
  )

  result <- render_scene(data, "x", "y", "z", labels = data$label, output_dir = output)
  html <- paste(readLines(result$index, warn = FALSE), collapse = "\n")

  expect_true(file.exists(result$points))
  expect_match(html, 'id="prediction-input"', fixed = TRUE)
  expect_match(html, 'id="r-code-editor"', fixed = TRUE)
  expect_match(html, 'id="run-r-code"', fixed = TRUE)
  expect_match(html, 'webr.r-wasm.org', fixed = TRUE)
  expect_match(html, 'id="check-sync"', fixed = TRUE)
  expect_match(html, 'id="download-qmd"', fixed = TRUE)
  expect_match(html, 'id="download-receipt"', fixed = TRUE)
  expect_match(html, 'id="explanation-input"', fixed = TRUE)
  expect_match(html, 'id="points-table"', fixed = TRUE)
  expect_match(html, 'tabindex="0"', fixed = TRUE)
  expect_match(html, 'id="complete-lesson"', fixed = TRUE)
  expect_match(html, 'id="scene-contract-title"', fixed = TRUE)
  expect_match(html, 'id="r-transform-summary"', fixed = TRUE)
  expect_match(html, 'id="r-error-guidance"', fixed = TRUE)
  expect_match(html, 'id="educator-mode-link"', fixed = TRUE)
  expect_match(html, 'id="authoring-checklist"', fixed = TRUE)
  expect_match(html, 'strict = TRUE', fixed = TRUE)
  expect_match(html, 'Browser evidence is not the project release gate', fixed = TRUE)
  expect_match(html, 'id="r-error-fix-example"', fixed = TRUE)
  expect_match(html, 'Download learner .qmd', fixed = TRUE)
  expect_match(html, 'id="ai-provider-status"', fixed = TRUE)
  expect_match(html, 'optional demo', fixed = TRUE)
  expect_match(html, 'function friendlyRError(error)', fixed = TRUE)
  expect_match(html, 'rlearnxr::scaffold_lesson', fixed = TRUE)
  expect_match(html, 'WebR 0.6.0', fixed = TRUE)
  expect_match(html, 'id="ai-tab"', fixed = TRUE)
  expect_match(html, 'id="generate-ai-brief"', fixed = TRUE)
  expect_match(html, 'id="copy-ai-code"', fixed = TRUE)
  expect_match(html, 'id="download-ai-brief"', fixed = TRUE)
  expect_match(html, 'function localAIBrief(prompt)', fixed = TRUE)
  expect_match(html, 'function learningReceipt()', fixed = TRUE)
  expect_match(html, 'private_data_sent_to_ai: false', fixed = TRUE)
  expect_match(html, 'function aiProvenance()', fixed = TRUE)
  expect_match(html, 'response_format: "rlearnxr_visualization_brief"', fixed = TRUE)
  expect_match(html, 'wrap="soft"', fixed = TRUE)
  expect_match(html, 'white-space: pre-wrap', fixed = TRUE)
  expect_match(html, 'function projectionMetrics(width, height)', fixed = TRUE)
  expect_match(html, 'id="scene-panel"[\\s\\S]*class="scene-tools"', perl = TRUE)
  expect_match(html, '@media (max-width: 1024px)', fixed = TRUE)
  expect_match(html, '@media (max-width: 560px)', fixed = TRUE)
  expect_match(html, '@media (max-width: 360px)', fixed = TRUE)
  expect_match(html, 'cell.dataset.label = labels[valueIndex]', fixed = TRUE)
  expect_false(grepl("below the average on y", html, fixed = TRUE))
})

test_that("render_scene rejects invalid data", {
  expect_error(render_scene(list(x = 1), "x", "y", "z"), "data must be")
  expect_error(render_scene(data.frame(x = 1, y = 2, z = 3), "x", "y", "z"), "at least three rows")
  expect_error(render_scene(data.frame(x = 1:3, y = 2:4, z = 3:5), "x", "x", "z"), "three columns")
  expect_error(render_scene(data.frame(x = 1:3, y = 2:4, z = 3:5), "x", "y", "z", labels = c("a", "a", "b")), "unique")
  expect_error(render_scene(data.frame(x = 1:3, y = 2:4, z = 3:5), "x", "y", "z", title = " "), "non-empty")
  expect_error(
    render_scene(data.frame(x = 1:3, y = 2:4, z = c(1, NA_real_, 3)), "x", "y", "z"),
    "cannot contain NA"
  )
})

test_that("validate_scene_data normalizes named axes and labels", {
  data <- data.frame(
    id = c("a", "b", "c"),
    horizontal = c(-1, 0, 1),
    vertical = c(0, 1, 0),
    depth = c(1, 0, -1)
  )
  scene <- validate_scene_data(
    data, x = "horizontal", y = "vertical", z = "depth", labels = data$id
  )
  expect_named(scene, c("label", "x", "y", "z"))
  expect_equal(scene$label, c("a", "b", "c"))
  expect_equal(scene$x, c(-1, 0, 1))
  expect_error(validate_scene_data(data, "horizontal", "horizontal", "depth"), "three columns")
  expect_error(validate_scene_data(data, "horizontal", "vertical", "depth", labels = c("a", "a", "c")), "unique")
})

test_that("render_scene protects existing artifacts unless overwrite is explicit", {
  output <- tempfile("rlearnxr-overwrite-")
  data <- data.frame(x = 1:3, y = 3:1, z = c(0, 1, 0))
  render_scene(data, "x", "y", "z", output_dir = output)
  expect_error(render_scene(data, "x", "y", "z", output_dir = output), "already exists")
  expect_silent(render_scene(data, "x", "y", "z", output_dir = output, overwrite = TRUE))
})
