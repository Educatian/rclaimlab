root <- normalizePath(".", winslash = "/", mustWork = TRUE)
quarto <- Sys.which("quarto")
if (!nzchar(quarto)) stop("Quarto CLI is required to render reference lessons", call. = FALSE)

lessons <- list.dirs(file.path(root, "examples"), full.names = TRUE, recursive = FALSE)
lessons <- lessons[file.exists(file.path(lessons, "_quarto.yml"))]
if (!length(lessons)) stop("No reference lessons were found", call. = FALSE)

for (lesson in lessons) {
  status <- system2(quarto, c("render", shQuote(lesson)))
  if (!identical(status, 0L)) stop("Quarto render failed for ", basename(lesson), call. = FALSE)
}
cat("Rendered", length(lessons), "R-ClaimLab reference lessons.\n")
