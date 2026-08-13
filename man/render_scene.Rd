\name{render_scene}
\alias{render_scene}
\title{Render a self-contained browser-based 3D scene}
\description{Converts three numeric columns of a data frame into JSON and a dependency-free HTML canvas scene.}
\usage{
render_scene(
  data, x, y, z, labels = NULL, output_dir = "scene",
  title = "R-LearnXR 3D Scene", overwrite = FALSE
)
}
\arguments{
  \item{data}{A data frame.}
  \item{x, y, z}{Names of three numeric columns.}
  \item{labels}{Optional character labels, one per row.}
  \item{output_dir}{Directory in which to write the scene files.}
  \item{title}{Scene title.}
\item{overwrite}{Logical; replace existing scene files when \code{TRUE}.}
}
\value{Invisibly, a list containing paths to the generated HTML and JSON files.}
\examples{
demo <- data.frame(x = c(-1, 0, 1), y = c(0, 1, 0), z = c(1, 0, -1))
\dontrun{render_scene(demo, "x", "y", "z", output_dir = tempfile())}
}
