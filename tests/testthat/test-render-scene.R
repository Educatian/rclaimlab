test_that("render_scene creates an accessible complete learning loop", {
  output <- tempfile("rlearnxr-scene-")
  data <- data.frame(
    x = c(-0.5, 0.5),
    y = c(0.25, -0.25),
    z = c(0.1, -0.1),
    label = c("alpha", "beta")
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
  expect_match(html, 'id="explanation-input"', fixed = TRUE)
  expect_match(html, 'id="points-table"', fixed = TRUE)
  expect_match(html, 'tabindex="0"', fixed = TRUE)
  expect_match(html, 'id="complete-lesson"', fixed = TRUE)
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
  expect_error(
    render_scene(data.frame(x = 1, y = 2, z = NA_real_), "x", "y", "z"),
    "cannot contain NA"
  )
})
