# Question-first Lesson Wizard

The Lesson Wizard turns a local CSV or R data frame into a reviewable R-ClaimLab lesson. It is a guided authoring surface over the Evidence Compiler, not an automatic curriculum or statistical-decision generator.

```r
library(rclaimlab)
run_lesson_wizard()
```

## Authoring sequence

1. Add local data. The file is read only by the local Shiny process.
2. State the educational or analytical question and choose an intent: explore, reduce, explain, classify, or cluster.
3. Declare what one row represents, the outcome if any, a grouping or nesting column, time or sequence, and the intended use of the evidence.
4. Review variable types, missingness, constant columns, possible identifiers, and dependence cautions.
5. Approve the adapter, numeric dimensions, observation label, seed, missing-value rule, and learning stages.
6. Preview the generated R source, method diagnostics, misconceptions, prompts, and completion criteria.
7. Compile Evidence IR, semantic data, Quarto source, the learner scene, receipt contract, and checks.

The same process can run in an R script:

```r
data <- read.csv("learner-data.csv", stringsAsFactors = FALSE)
profile <- profile_learning_data(
  data,
  intent = "explore",
  grouping = "learner_id",
  time = "session"
)
recommend_lesson_analysis(profile)

lesson <- lesson_from_data(
  data,
  analysis = "auto",
  dimensions = c("revision_count", "transfer_score", "hint_rate"),
  id_column = "event_id",
  grouping = "learner_id",
  time = "session",
  question = "How do revision activity, transfer performance, and hint use vary across repeated sessions?",
  intent = "explore",
  unit_of_analysis = "one de-identified learner-session summary",
  decision_context = "choosing reversible instructional support",
  title = "Learning activity evidence",
  na_action = "fail"
)

compile_lesson(lesson, "learning-activity-evidence")
```

## Recommendation contract

`analysis = "auto"` uses the declared intent, not the number or type of columns alone:

| Intent | Default adapter when eligible | Required author check |
|---|---|---|
| Explore | Direct data view | scale, missingness, and descriptive-only claim |
| Reduce | PCA | scaling, scores versus loadings, and variance explained |
| Explain | Linear regression | numeric outcome, residuals, influence, intervals, and causal boundary |
| Classify | Binary logistic regression | modeled event, reference, balance, threshold, and uncertainty |
| Cluster | K-means | scaling, requested k, random starts, size, and stability |

If grouping or time is declared, the simple `lm` and `glm` adapters remain technically available but are not recommended automatically. The core package does not model grouped or longitudinal dependence. Authors should either use descriptive exploration or contribute a suitable adapter.

## Compiled learning contract

By default, every lesson contains Orient, Predict, Run R, Explore, Explain, Repair, Transfer, and Reproduce. The browser renders the exact prompts and criteria serialized by R. The exported receipt preserves task IDs, criterion results, the learner-selected observation and evidence IDs, generated source, runtime seed, browser artifact hash, and compiled evidence hash.

The recommendation is a transparent teaching scaffold. It is not a claim that the selected method answers the substantive question, supports causal inference, or is appropriate for a consequential decision.
