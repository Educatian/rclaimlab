\name{lesson-bridge}
\alias{export_lesson_bundle}
\alias{import_datasandbox_bundle}
\title{Exchange portable lesson bundles}
\description{
  Export or import portable lesson folders and DataSandbox bundle artifacts.
  Manifest and receipt functions have dedicated documentation pages.
}
\usage{
export_lesson_bundle(path = ".", output = NULL, zip = FALSE,
  include_receipt = TRUE, overwrite = FALSE)

import_datasandbox_bundle(bundle, output = "rclaimlab-imported-lesson",
  overwrite = FALSE)
}
\arguments{
  \item{path}{Lesson directory.}
  \item{bundle}{A DataSandbox portable JSON bundle, ZIP, or lesson directory.}
  \item{output}{Output directory or ZIP path.}
  \item{overwrite}{Whether an existing artifact may be replaced.}
  \item{zip}{Whether to create a ZIP bundle.}
  \item{include_receipt}{Whether to include the learning receipt in an export.}
}
\details{
  JSON bundle parsing uses \pkg{jsonlite}. Exported lesson folders remain plain
  files and are inspectable without a service dependency.
}
\value{The path to the written or imported artifact, invisibly.}
\examples{
if (FALSE) {
  import_datasandbox_bundle("datasandbox-demo.rclaimlab.bundle.json", "lesson")
  export_lesson_bundle("lesson", zip = TRUE)
}
}
