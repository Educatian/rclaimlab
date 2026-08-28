root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "utils.R"))
source(file.path(root, "R", "zzz.R"))
source(file.path(root, "R", "lesson_bundle.R"))
source(file.path(root, "R", "evidence_adapters.R"))
source(file.path(root, "R", "lesson_manifest.R"))
source(file.path(root, "R", "check_lesson.R"))

lessons <- list.dirs(file.path(root, "examples"), full.names = TRUE, recursive = FALSE)
lessons <- lessons[file.exists(file.path(lessons, "lesson-spec.json"))]
reports <- lapply(lessons, function(lesson) {
  result <- check_lesson(lesson, strict = TRUE)
  result$lesson <- basename(lesson)
  result
})
report <- do.call(rbind, reports)
print(report[, c("lesson", "check", "status", "message")], row.names = FALSE)
if (any(report$status == "FAIL")) quit(status = 1)
