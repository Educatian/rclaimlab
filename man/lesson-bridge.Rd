\name{lesson-bridge}
\alias{export_lesson_bundle}
\alias{import_datasandbox_bundle}
\alias{read_lesson_manifest}
\alias{write_learning_receipt}
\alias{write_lesson_manifest}
\title{Exchange manifests, receipts, and lesson bundles}
\description{
  Create and exchange portable provenance artifacts between R-LearnXR and a
  DataSandbox learning workflow. The functions use browser-local or local-file
  data by default and do not require a server or LMS identity.
}
\usage{
write_lesson_manifest(path = ".", lesson_id = NULL, title = NULL,
  source_platform = "rlearnxr", source_project = NULL, course_id = NULL,
  session_id = NULL, block_id = NULL, activity_id = NULL,
  dataset_file = NULL, dataset_source = NULL, dataset_license = NULL,
  required_columns = c("label", "x", "y", "z"), seed = 2026,
  web_r_version = "0.6.0", storage = "browser-local",
  export_consent_required = TRUE, research_use = "separate-consent",
  education = NULL,
  overwrite = TRUE)

read_lesson_manifest(path = ".")

write_learning_receipt(path = ".", attempt_number = 1, prediction = "",
  explanation = "", source_platform = "rlearnxr", course_id = NULL,
  session_id = NULL, block_id = NULL, activity_id = NULL, seed = 2026,
  input_data = NULL, scene_files = c("scene/index.html", "scene/points.json"),
  outcome = "in_progress", consent = "local-only", overwrite = TRUE)

export_lesson_bundle(path = ".", output = NULL, zip = FALSE,
  include_receipt = TRUE, overwrite = FALSE)

import_datasandbox_bundle(bundle, output = "rlearnxr-imported-lesson",
  overwrite = FALSE)
}
\arguments{
  \item{path}{Lesson directory.}
  \item{bundle}{A DataSandbox portable JSON bundle, ZIP, or lesson directory.}
  \item{output}{Output directory or ZIP path.}
  \item{lesson_id}{Stable identifier for the lesson.}
  \item{title}{Human-readable lesson title.}
  \item{overwrite}{Whether an existing artifact may be replaced.}
  \item{zip}{Whether to create a ZIP bundle.}
  \item{include_receipt}{Whether to include the learning receipt in an export.}
  \item{attempt_number}{Learner attempt number.}
  \item{prediction}{Learner's pre-evidence prediction.}
  \item{explanation}{Learner's evidence-based explanation.}
  \item{source_platform,source_project,course_id,session_id,block_id,activity_id}{Provenance identifiers.}
  \item{dataset_file,dataset_source,dataset_license}{Dataset provenance fields.}
  \item{required_columns}{Columns required by the lesson scene contract.}
  \item{seed}{Reproducibility seed.}
  \item{web_r_version}{Pinned WebR runtime version.}
  \item{storage,research_use,consent,export_consent_required}{Privacy metadata.}
  \item{education}{Optional learner-facing objectives, sequence, assessment, accessibility, and instructor-material metadata.}
  \item{input_data}{Optional input data file to hash.}
  \item{scene_files}{Scene files to hash in the learning receipt.}
  \item{outcome}{Learning receipt outcome label.}
}
\details{
  JSON parsing for import and manifest reading uses the optional \pkg{jsonlite}
  package. Exported lesson folders remain plain files and are inspectable without
  a service dependency.
}
\value{The path to the written or imported artifact, invisibly.}
\examples{
if (FALSE) {
  write_lesson_manifest("lesson", source_platform = "datasandbox-toolkit")
  import_datasandbox_bundle("datasandbox-demo.rlearnxr.bundle.json", "lesson")
  check_lesson("lesson", strict = TRUE)
}
}
