\name{render_scene}
\alias{render_scene}
\title{Render a self-contained browser-based 3D scene}
\description{Converts three numeric columns into linked point JSON, Evidence IR, and a dependency-free HTML learning scene.}
\usage{
render_scene(
  data, x, y, z, labels = NULL, observation_ids = NULL,
  evidence_ids = NULL, output_dir = "scene",
  title = "R-ClaimLab 3D Scene", learning_contract = NULL,
  min_rows = 3L, overwrite = FALSE
)
}
\arguments{
  \item{data}{A data frame.}
  \item{x, y, z}{Names of three numeric columns.}
  \item{labels}{Optional character labels, one per row.}
  \item{observation_ids}{Optional stable observation identifiers, one per row.}
  \item{evidence_ids}{Optional list of evidence identifiers keyed by observation.}
  \item{output_dir}{Directory in which to write the scene files.}
  \item{title}{Scene title.}
  \item{learning_contract}{Optional \code{rclaimlab_lesson} or browser-contract list used to render method-specific prompts, criteria, diagnostics, and provenance.}
  \item{min_rows}{Minimum number of observations accepted by the renderer. The compiler may lower this for table/2D-first aggregate evidence.}
  \item{overwrite}{Logical; replace existing scene files when \code{TRUE}.}
}
\value{Invisibly, a list containing paths to the generated HTML, point JSON, and Evidence IR files.}
\examples{
demo <- data.frame(x = c(-1, 0, 1), y = c(0, 1, 0), z = c(1, 0, -1))
\dontrun{render_scene(demo, "x", "y", "z", output_dir = tempfile())}
}
