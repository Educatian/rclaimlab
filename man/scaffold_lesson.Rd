\name{scaffold_lesson}
\alias{scaffold_lesson}
\title{Create a Quarto lesson scaffold}
\description{Creates a small Quarto website project with a reference lesson, data directory, scene directory, checks directory, minimal renv lockfile, and reproduction instructions.}
\usage{scaffold_lesson(path = "rclaimlab-lesson", title = "R-ClaimLab Lesson", overwrite = FALSE)}
\arguments{
  \item{path}{Directory to create.}
  \item{title}{Lesson title.}
  \item{overwrite}{Logical; allow an existing non-empty directory.}
}
\value{Invisibly, the normalized lesson path.}
\examples{
\dontrun{scaffold_lesson(tempdir())}
}
