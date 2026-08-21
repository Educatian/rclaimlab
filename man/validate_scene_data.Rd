% Generated manually for the small MVP package.
\name{validate_scene_data}
\alias{validate_scene_data}
\title{Validate and normalize the R-LearnXR scene data contract}
\description{Checks a data frame and returns stable observation IDs, labels, and x, y, and z scene columns.}
\usage{
validate_scene_data(data, x = "x", y = "y", z = "z", labels = NULL,
                    observation_ids = NULL, min_rows = 3L)
}
\arguments{
  \item{data}{A data frame containing three numeric coordinate columns.}
  \item{x, y, z}{Names of the columns used for the scene axes.}
  \item{labels}{Optional point labels.}
  \item{observation_ids}{Optional stable observation identifiers.}
  \item{min_rows}{Minimum number of observations required.}
}
\value{A data frame with exactly \code{observation_id}, \code{label}, \code{x}, \code{y}, and \code{z} columns.}
\examples{
scene <- validate_scene_data(data.frame(id = c("a", "b", "c"),
  horizontal = c(-1, 0, 1), vertical = c(0, 1, 0), depth = c(1, 0, -1)),
  x = "horizontal", y = "vertical", z = "depth", labels = c("a", "b", "c"))
}
