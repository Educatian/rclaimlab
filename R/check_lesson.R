check_lesson <- function(path = ".", write_report = TRUE, strict = FALSE,
                         write_json = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  results <- data.frame(check = character(), status = character(), message = character(), stringsAsFactors = FALSE)
  add <- function(check, status, message) {
    results <<- rbind(results, data.frame(check = check, status = status, message = message, stringsAsFactors = FALSE))
  }
  require_file <- function(relative, label = relative) {
    if (file.exists(file.path(path, relative))) add(label, "PASS", paste0(relative, " exists"))
    else add(label, "FAIL", paste0(relative, " is missing"))
  }

  require_file("_quarto.yml", "project_config")
  require_file("index.qmd", "lesson_entrypoint")
  require_file("scene/index.html", "browser_scene")
  require_file("lesson-manifest.json", "lesson_manifest")
  if (file.exists(file.path(path, "lesson-manifest.json"))) {
    manifest_check <- tryCatch({
      validate_lesson_manifest(path)
      TRUE
    }, error = function(error) error)
    if (isTRUE(manifest_check)) add("manifest_contract", "PASS", "lesson manifest satisfies the version 2 contract")
    else add("manifest_contract", "FAIL", conditionMessage(manifest_check))
  }
  receipt_path <- file.path(path, "checks", "learning-receipt.json")
  if (file.exists(receipt_path)) {
    receipt_check <- tryCatch({
      validate_learning_receipt(receipt_path)
      TRUE
    }, error = function(error) error)
    if (isTRUE(receipt_check)) add("receipt_contract", "PASS", "learning receipt satisfies the version 2 contract")
    else add("receipt_contract", "FAIL", conditionMessage(receipt_check))
  }

  evidence_path <- file.path(path, "scene", "evidence.json")
  root_evidence_path <- file.path(path, "evidence.json")
  declared_evidence_path <- if (file.exists(root_evidence_path)) root_evidence_path else evidence_path
  if (file.exists(declared_evidence_path)) {
    evidence_check <- tryCatch({
      read_rlearnxr_evidence(declared_evidence_path)
      TRUE
    }, error = function(error) error)
    if (isTRUE(evidence_check)) add("evidence_ir", "PASS", "Evidence IR satisfies rlearnxr-evidence-2")
    else add("evidence_ir", "FAIL", conditionMessage(evidence_check))
  } else {
    add("evidence_ir", "FAIL", "evidence.json is missing")
  }

  license_candidates <- c("DATA_LICENSE.md", "DATA_LICENSE", "LICENSE.md", "LICENSE")
  license_path <- file.path(path, license_candidates)[file.exists(file.path(path, license_candidates))][1]
  license_text <- if (length(license_path) && !is.na(license_path)) {
    paste(readLines(license_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  } else ""
  license_is_substantive <- nchar(trimws(license_text)) >= 100 &&
    grepl("source|provenance|dataset|data", license_text, ignore.case = TRUE) &&
    grepl("license|CC0|CC BY|MIT|public domain|permission", license_text, ignore.case = TRUE)
  if (license_is_substantive) {
    add("data_license", "PASS", "lesson data source, provenance, and reuse terms are documented")
  } else if (length(license_path) && !is.na(license_path)) {
    add("data_license", "WARN", "a license file exists but still appears to be a starter or incomplete note")
  } else {
    add("data_license", "FAIL", "add DATA_LICENSE.md with source and reuse terms")
  }

  data_dir <- file.path(path, "data")
  if (dir.exists(data_dir) && length(list.files(data_dir, all.files = TRUE, no.. = TRUE)) > 0) {
    add("data_presence", "PASS", "data directory contains at least one file")
  } else {
    add("data_presence", "WARN", "data directory is empty; add a small, openly licensed example dataset")
  }

  qmd <- list.files(path, pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE, include.dirs = FALSE)
  code_files <- c(qmd, list.files(path, pattern = "\\.R$", recursive = TRUE, full.names = TRUE, include.dirs = FALSE))
  code_text <- if (length(code_files)) paste(vapply(code_files, function(f) paste(readLines(f, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n") else ""
  if (grepl("[A-Za-z]:[\\\\/]", code_text, perl = TRUE) || grepl("/Users/|/home/", code_text, perl = TRUE)) {
    add("portable_paths", "FAIL", "code appears to contain an absolute machine-specific path")
  } else {
    add("portable_paths", "PASS", "no common absolute local paths detected")
  }
  if (grepl("set.seed\\s*\\(", code_text, perl = TRUE)) {
    add("deterministic_seed", "PASS", "a deterministic seed is declared")
  } else {
    add("deterministic_seed", "WARN", "no set.seed() found; add one when randomness affects lesson output")
  }
  education_markers <- c("learning objectives", "predict", "explain", "transfer")
  if (all(vapply(education_markers, grepl, logical(1), x = tolower(code_text), fixed = TRUE))) {
    add("education_content", "PASS", "lesson prose includes objectives, prediction, explanation, and transfer activities")
  } else {
    add("education_content", "FAIL", "lesson prose must include learning objectives, predict, explain, and transfer activities")
  }
  lock_candidates <- unique(c(
    file.path(path, "renv.lock"),
    file.path(dirname(path), "renv.lock"),
    file.path(dirname(dirname(path)), "renv.lock")
  ))
  lock_path <- lock_candidates[file.exists(lock_candidates)][1]
  if (length(lock_path) && !is.na(lock_path)) {
    lock_text <- paste(readLines(lock_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    lock_is_shaped <- grepl('"R"', lock_text, fixed = TRUE) && grepl('"Packages"', lock_text, fixed = TRUE)
    if (lock_is_shaped) {
      add("environment_lock", "PASS", "renv.lock found and contains the expected R and Packages sections")
    } else {
      add("environment_lock", "WARN", "renv.lock exists but does not contain the expected R and Packages sections")
    }
  } else {
    add("environment_lock", "WARN", "renv.lock is absent from the lesson or repository root")
  }

  scene_path <- file.path(path, "scene", "index.html")
  scene_text <- if (file.exists(scene_path)) paste(readLines(scene_path, warn = FALSE), collapse = "\n") else ""
  accessible_markers <- c('tabindex="0"', 'id="points-table"', 'aria-live="polite"', '<textarea')
  if (all(vapply(accessible_markers, grepl, logical(1), x = scene_text, fixed = TRUE))) {
    add("accessible_structure", "PASS", "keyboard canvas, live feedback, text inputs, and a data table markers are present")
  } else {
    add("accessible_structure", "FAIL", "scene is missing a required keyboard, feedback, input, or table marker")
  }

  fallback_markers <- c('id="points-table"', 'id="download-r"', 'id="download-qmd"', 'id="download-receipt"')
  if (all(vapply(fallback_markers, grepl, logical(1), x = scene_text, fixed = TRUE))) {
    add("static_fallback", "PASS", "table, source, and learning receipt exports remain available without the visual runtime")
  } else {
    add("static_fallback", "FAIL", "scene is missing a non-3D fallback or learner export path")
  }

  ai_safety_markers <- c('credentials: "omit"', 'private_data_sent_to_ai: false', 'function validateAIBrief(brief)')
  if (all(vapply(ai_safety_markers, grepl, logical(1), x = scene_text, fixed = TRUE))) {
    add("ai_safety_markers", "PASS", "optional AI path omits browser credentials, records the privacy boundary, and validates returned code")
  } else {
    add("ai_safety_markers", "FAIL", "optional AI path is missing a required privacy or code-validation marker")
  }

  learning_markers <- c(
    'id="prediction-input"', 'id="r-code-editor"', 'id="run-r-code"',
    'webr.r-wasm.org', 'id="check-sync"', 'id="check-explanation"',
    'id="transfer-card"', 'id="complete-lesson"'
  )
  if (all(vapply(learning_markers, grepl, logical(1), x = scene_text, fixed = TRUE))) {
    add("learning_loop", "PASS", "predict, run R, explore, explain, reproduce, and completion controls are present")
  } else {
    add("learning_loop", "FAIL", "scene does not contain the complete learner loop")
  }

  artifact_files <- file.path(path, c("scene/index.html", "scene/points.json", if (file.exists(root_evidence_path)) "evidence.json" else "scene/evidence.json"))
  artifact_files <- artifact_files[file.exists(artifact_files)]
  if (length(artifact_files) == 3L) {
    hashes <- unname(tools::md5sum(artifact_files))
    add("artifact_hash", "PASS", paste(hashes, collapse = ", "))
  } else {
    add("artifact_hash", "FAIL", "scene, point, and Evidence IR artifacts are required")
  }

  quarto_env <- Sys.getenv("QUARTO_PATH", unset = "")
  quarto <- if (nzchar(quarto_env) && file.exists(quarto_env)) quarto_env else Sys.which("quarto")
  if (nzchar(quarto)) add("quarto_available", "PASS", "Quarto CLI found")
  else add("quarto_available", "WARN", "Quarto CLI was not found; CI must render the lesson before release")

  if (isTRUE(strict) && any(results$status == "WARN")) {
    results$status[results$status == "WARN"] <- "FAIL"
  }

  if (write_report) {
    ensure_dir(file.path(path, "checks"))
    markdown_message <- function(value) gsub("|", "\\\\|", value, fixed = TRUE)
    lines <- c(
      "# R-LearnXR reproducibility report", "",
      paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      paste0("Mode: ", if (isTRUE(strict)) "strict (warnings fail)" else "advisory"), "",
      "| Check | Status | Message |", "|---|---|---|",
      apply(results, 1, function(row) paste0("| ", row[["check"]], " | ", row[["status"]], " | ", markdown_message(row[["message"]]), " |")), "",
      "This report checks project hygiene and structural accessibility markers. PASS does not guarantee identical results on every operating system or replace a browser assistive-technology audit."
    )
    writeLines(lines, file.path(path, "checks", "reproducibility-report.md"), useBytes = TRUE)
    session <- c(
      paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      utils::capture.output(utils::sessionInfo())
    )
    writeLines(sub("[ \\t]+$", "", session, perl = TRUE), file.path(path, "checks", "session-info.txt"), useBytes = TRUE)
    if (isTRUE(write_json)) {
      quote_json <- function(value) paste0('"', json_escape(value), '"')
      check_json <- apply(results, 1, function(row) paste0(
        "{\"check\":", quote_json(row[["check"]]),
        ",\"status\":", quote_json(row[["status"]]),
        ",\"message\":", quote_json(row[["message"]]), "}"
      ))
      report_json <- c(
        "{",
        paste0("  \"report_version\": \"1\",\n"),
        paste0("  \"path\": ", quote_json("."), ",\n"),
        paste0("  \"strict\": ", if (isTRUE(strict)) "true" else "false", ",\n"),
        paste0("  \"checks\": [", paste(check_json, collapse = ","), "]\n"),
        "}"
      )
      writeLines(report_json, file.path(path, "checks", "reproducibility-report.json"), useBytes = TRUE)
    }
  }
  class(results) <- c("rlearnxr_checks", class(results))
  results
}
