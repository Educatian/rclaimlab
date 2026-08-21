% Generated manually for the optional educator shell.
\name{run_rlearnxr_shiny}
\alias{run_rlearnxr_shiny}
\title{Launch the optional R-LearnXR Shiny educator console}
\description{
  Launches a local Shiny console for selecting reference modules, validating
  the course catalog, opening a lesson, and running the strict lesson check.
  The learner-facing Quarto/WebR lesson remains usable without Shiny.
}
\usage{
run_rlearnxr_shiny(
  lesson_dir = NULL,
  catalog = default_course_catalog(),
  host = "127.0.0.1",
  port = getOption("shiny.port"),
  launch.browser = interactive(),
  quiet = FALSE
)
}
\arguments{
  \item{lesson_dir}{Optional repository root or lesson folder used for local checks and browser links.}
  \item{catalog}{A course catalog satisfying \code{validate_course_catalog()}.}
  \item{host}{Local interface passed to \code{shiny::runApp()}.}
  \item{port}{Port passed to \code{shiny::runApp()}.}
  \item{launch.browser}{Whether Shiny should open the local browser automatically.}
  \item{quiet}{Whether to suppress the Shiny startup message.}
}
\details{
  The function has an optional dependency on the \pkg{shiny} package. It
  deliberately delegates validation to the package contracts instead of
  creating a second lesson or checking implementation. Use
  \code{install.packages("shiny")} before calling it.
}
\examples{
if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
  run_rlearnxr_shiny(lesson_dir = "path/to/rlearnxr")
}
}
