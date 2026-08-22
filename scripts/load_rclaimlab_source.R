rclaimlab_source_root <- if (exists("root", inherits = FALSE)) {
  normalizePath(root, winslash = "/", mustWork = TRUE)
} else {
  normalizePath(".", winslash = "/", mustWork = TRUE)
}
rclaimlab_source_files <- c(
  "utils.R", "zzz.R", "lesson_bundle.R", "evidence_spec.R",
  "evidence_adapters.R", "foundational_adapters.R", "learning_events.R",
  "concept_registry.R", "scene_contract.R", "lesson_manifest.R",
  "lesson_pedagogy.R", "render_scene.R", "check_lesson.R",
  "compile_lesson.R", "lesson_wizard.R"
)
for (rclaimlab_source_file in rclaimlab_source_files) {
  source(file.path(rclaimlab_source_root, "R", rclaimlab_source_file), chdir = FALSE)
}
rm(rclaimlab_source_file, rclaimlab_source_files)

write_reference_data_license <- function(lesson_dir, source, reuse_terms, privacy_note = NULL) {
  lines <- c(
    "# Data License and Provenance", "",
    paste0("**Source:** ", source), "",
    paste0("**Reuse terms:** ", reuse_terms), ""
  )
  if (!is.null(privacy_note)) lines <- c(lines, paste0("**Privacy:** ", privacy_note), "")
  lines <- c(
    lines,
    "The compiled Evidence IR records the source call, retained-row decision, seed, R and package versions, and artifact hash.",
    "R-ClaimLab software is MIT licensed. Original lesson narrative is CC BY 4.0."
  )
  writeLines(lines, file.path(lesson_dir, "DATA_LICENSE.md"), useBytes = TRUE)
}
