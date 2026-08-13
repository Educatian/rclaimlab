\name{check_lesson}
\alias{check_lesson}
\title{Check a lesson project for reproducibility conditions}
\description{Checks required files, portable paths, deterministic seeds, an environment lockfile shape, licensing, structural accessibility markers, and Quarto availability. Markdown, session, and machine-readable JSON reports can also be written to the lesson project.}
\usage{check_lesson(path = ".", write_report = TRUE, strict = FALSE, write_json = TRUE)}
\arguments{
  \item{path}{Path to the lesson project.}
  \item{write_report}{Logical; write \code{checks/reproducibility-report.md} when \code{TRUE}.}
  \item{strict}{Logical; convert warnings to failures for release/CI checks.}
  \item{write_json}{Logical; write \code{checks/reproducibility-report.json} when \code{write_report} is \code{TRUE}.}
}
\value{A data frame with one row per check and columns \code{check}, \code{status}, and \code{message}.}
\examples{
\dontrun{check_lesson("examples/lesson")}
}
