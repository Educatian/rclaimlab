\name{course-catalog}
\alias{default_course_catalog}
\alias{validate_course_catalog}
\alias{render_course_catalog}
\title{Build a learner-facing R-LearnXR course home}
\description{Create a validated, static course home that indexes executable lessons, curriculum blueprints, and browser-local learner progress without requiring an account or server.}
\usage{
default_course_catalog()

validate_course_catalog(catalog)

render_course_catalog(catalog = default_course_catalog(), output_dir = "course",
  overwrite = FALSE)
}
\arguments{
  \item{catalog}{A course catalog list following the rlearnxr-course-1 schema.}
  \item{output_dir}{Directory for the static course home and JSON catalog.}
  \item{overwrite}{Whether existing course outputs may be replaced.}
}
\value{\code{default_course_catalog()} returns a catalog list. Validation returns invisibly. Rendering returns the output paths invisibly.}
\details{The generated course home is a static HTML artifact. It supports filtering, module links, browser-local progress, keyboard access, reduced motion, and a curriculum/authoring-blueprint distinction. It does not transmit learner data or require an LMS identity.}
\examples{
if (FALSE) {
  catalog <- default_course_catalog()
  validate_course_catalog(catalog)
  render_course_catalog(catalog, "course", overwrite = TRUE)
}
}
