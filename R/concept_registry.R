#' Inspect the supported statistics and visualization curriculum
#'
#' The registry distinguishes tested package capabilities from partial or
#' planned curriculum. It prevents documentation from treating a concept mention
#' as an implemented Evidence Adapter.
#'
#' @return A data frame with one row per curriculum capability.
#' @export
rlearnxr_concept_registry <- function() {
  data.frame(
    concept_id = c(
      "question-provenance", "learning-event-preparation", "numeric-description",
      "categorical-description", "bivariate-exploration", "correlation",
      "bootstrap-uncertainty", "two-group-comparison", "anova", "chi-square",
      "linear-regression", "classification", "pca", "clustering",
      "table-representation", "plot2d-representation", "scene3d-representation",
      "probability-distributions", "longitudinal-multilevel"
    ),
    concept = c(
      "Question, unit, and provenance", "Learning-event aggregation",
      "Numeric center, spread, percentile, and histogram",
      "Categorical count and proportion", "Bivariate numeric exploration",
      "Correlation with paired evidence", "Bootstrap sampling variability",
      "Two-group t test", "Analysis of variance", "Chi-square association",
      "Linear regression", "Binary classification", "Principal component analysis",
      "K-means clustering", "Semantic evidence table", "Two-dimensional evidence plot",
      "Three-dimensional evidence scene", "Theoretical probability distributions",
      "Longitudinal and multilevel models"
    ),
    implementation = c(
      "lesson_spec + receipt", "prepare_learning_events", "numeric_summary",
      "table", "data.frame", "cor.test", "bootstrap_mean", "t.test", "aov",
      "chisq.test", "lm", "glm", "prcomp", "kmeans", "table", "plot2d",
      "scene3d", NA, NA
    ),
    status = c(rep("tested", 17L), "planned", "planned"),
    evidence_level = c(
      rep("automated contract and runtime test", 17L),
      "curriculum documentation only", "explicit scope boundary"
    ),
    stringsAsFactors = FALSE
  )
}
