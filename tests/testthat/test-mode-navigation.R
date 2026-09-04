test_that("mode navigation is optional and rejects unsafe destinations", {
  plain <- rclaimlab:::workflow_html("Standalone", list())
  expect_false(grepl("{{MODE_HOME_LINK}}", plain, fixed = TRUE))
  expect_false(grepl('class="mode-home"', plain, fixed = TRUE))
  linked <- rclaimlab:::workflow_html("Hosted", list(), "../../../index.html")
  expect_match(linked, 'href="../../../index.html"', fixed = TRUE)
  expect_match(linked, "Change mode", fixed = TRUE)
  expect_match(linked, "const RCLAIMLAB_PRESENTATION", fixed = TRUE)
  expect_match(linked, 'aria-label="Shared workspace tools"', fixed = TRUE)
  expect_match(linked, 'id="activity-action"', fixed = TRUE)
  expect_match(linked, 'id="task-note"', fixed = TRUE)
  expect_match(linked, "receipt.decisions.task_notes = state.taskNotes", fixed = TRUE)
  for (bad in list("https://example.com", "javascript:alert(1)", "//example.com", "../x\" onclick=\"x", NA_character_, character())) {
    expect_error(rclaimlab:::workflow_html("Unsafe", list(), bad), "relative parent")
  }
})
