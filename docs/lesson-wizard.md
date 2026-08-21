# Lesson Wizard

The Lesson Wizard turns a local CSV or R data frame into a reviewable R-LearnXR lesson. It is a guided authoring surface over the Evidence Compiler, not an automatic curriculum generator.

```r
library(rlearnxr)
run_lesson_wizard()
```

The workflow has four explicit decisions:

1. Add local data. The file is read only by the local Shiny process.
2. Review variable types, missingness, constant columns, and possible identifiers.
3. Approve the adapter, outcome, numeric dimensions, observation label, seed, missing-value rule, and learning stages.
4. Compile Evidence IR, semantic data, Quarto source, the learner scene, and checks.

The same process can run in an R script:

```r
data <- read.csv("learner-data.csv", stringsAsFactors = FALSE)
profile <- profile_learning_data(data)
recommend_lesson_analysis(profile)

lesson <- lesson_from_data(
  data,
  analysis = "prcomp",
  dimensions = c("engagement", "practice", "assessment"),
  title = "Learning activity evidence",
  na_action = "fail"
)

compile_lesson(lesson, "learning-activity-evidence")
```

`analysis = "auto"` applies deterministic eligibility rules. It favors binary logistic regression for an approved two-level outcome, linear regression for an approved numeric outcome, principal component analysis for multivariate numeric data, and direct numeric exploration otherwise. This recommendation establishes technical fit only. It does not decide whether a method is educationally or substantively appropriate.

By default, the generated lesson includes Orient, Predict, Run R, Explore, Explain, Repair, Transfer, and Reproduce. Every generated analysis stores its selected variables, missing-value rule, generated R code, source-row accounting, seed, and artifact hash in Evidence IR.
