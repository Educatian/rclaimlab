# R-ClaimLab Statistics and Educational Data Pathway

R-ClaimLab does not claim to teach every branch of statistics. It provides a reusable introductory pathway for data-science statistics, then connects the same workflow to Learning Analytics (LA) and Educational Data Mining (EDM). Each module turns one statistical concept into a learner decision, an editable R activity, an evidence view, an explanation prompt, and a reproducible receipt.

## Design rules

- Start with an authentic question, not a function name.
- Teach concepts before syntax; show the R code only after the learner has made a prediction.
- Use 3D only when a third coordinate changes an interpretation. Every visual activity has a table and keyboard path.
- Separate description, explanation, prediction, and intervention. A model output is not automatically a causal claim.
- Make uncertainty, missingness, measurement choices, and data provenance visible.
- End with communication and reproducibility: claim, evidence, limitation, source code, and receipt.

## Core statistics modules

| ID | Module | Core concept | Learner decision | R practice | Evidence artifact |
|---|---|---|---|---|---|
| S01 | Ask a Data Question | population, unit, variable, provenance | Is this a statistical question and what would count as evidence? | `str()`, `names()`, `summary()` | question map + data dictionary |
| S02 | Data Types and Tidy Structure | categorical/numeric, missingness, tidy rows | What does one row mean and what information is lost? | `factor()`, `is.na()`, `subset()` | data dictionary + missingness note |
| S03 | Distributions | center, spread, skew, outliers | What is typical and how variable is it? | `hist()`, `quantile()`, `boxplot()` | distribution claim with limitation |
| S04 | Sampling and Uncertainty | sample, population, bootstrap intuition | How stable is this estimate under repeated samples? | `sample()`, `replicate()`, `quantile()` | interval interpretation, not certainty claim |
| S05 | Association | covariance, correlation, confounding | Do two variables move together, and what does that not prove? | `cor()`, grouped summaries | paired evidence explanation |
| S06 | Regression and Prediction | slope, residual, error, extrapolation | How useful is a prediction and where does it fail? | `lm()`, `predict()`, residual checks | prediction + error analysis |
| S07 | Classification and Evaluation | class, threshold, confusion matrix | What counts as a correct or harmful decision? | `ifelse()`, sensitivity/specificity, accuracy | metric trade-off card |
| S08 | Multivariate Reasoning | scale, dimensions, PCA scores/loadings | Does a third dimension change the story? | `scale()`, `prcomp()` | PCA coordinate explanation |
| S09 | Clustering and Segmentation | similarity, distance, cluster instability | Is this group real, useful, or an artifact of choices? | `dist()`, `kmeans()` | cluster critique + sensitivity check |
| S10 | Communicating Variation | visual encoding, uncertainty, audience | Can another person understand the claim without overreading the plot? | `plot()`, labels, annotation | accessible explanation + alt text |
| S11 | Reproducible Analysis | seed, environment, artifact, provenance | Can another learner reproduce and audit the result? | `set.seed()`, Quarto, `check_lesson()` | source bundle + reproducibility report |

## Learning Analytics and EDM application track

These modules reuse S01–S11 rather than replacing them with a dashboard.

| ID | Application module | Statistical focus | Learner activity | Guardrail |
|---|---|---|---|---|
| LA01 | What is a Learning Trace? | operationalization and measurement | Map events such as attempts, time, explanation, and transfer to constructs | An event is not the construct itself |
| LA02 | Descriptive Learning Analytics | distributions and comparison | Compare completion, error, and transfer patterns across synthetic groups | No ranking or deficit label |
| LA03 | Feedback and Intervention | association, uncertainty, decision rules | Choose a low-risk support action from learner-visible evidence | Human review; no high-stakes automation |
| EDM01 | Feature Engineering | tidy data, aggregation, missingness | Build learner-level features from event rows | Document aggregation windows and missing data |
| EDM02 | Pattern Discovery | clustering and sequence reasoning | Compare behavioral patterns and test sensitivity to choices | Patterns are hypotheses, not diagnoses |
| EDM03 | Predictive Modeling | classification, validation, calibration | Evaluate a transparent model and inspect false positives/negatives | No hidden labels or unsupported causal claims |
| EDM04 | Fairness and Data Ethics | subgroup variation and uncertainty | Audit whether a metric behaves differently across groups | Consent, minimization, privacy, learner agency |
| EDM05 | Communicate an Educational Action | synthesis and limitations | Write what to do, why, for whom, and what evidence is missing | An intervention must be reversible and reviewable |

## Current implementation map

- `rclaimlab_concept_registry()`: authoritative machine-readable distinction between tested and planned curriculum capabilities.
- `as_rclaimlab_evidence.numeric()`: S03 center, spread, percentile, and histogram evidence.
- `as_rclaimlab_evidence.table()`: S02/S03 categorical counts and proportions.
- `as_rclaimlab_evidence.htest()`: S04–S07 paired correlation, t-test, and chi-square evidence when the required source data are supplied.
- `bootstrap_mean()`: S04 deterministic resampling distribution and percentile interval.
- `as_rclaimlab_evidence.aov()`: explicit ANOVA evidence; `aov` objects no longer fall through to the generic `lm` contract.
- `prepare_learning_events()`: local event-to-learner aggregation with a reviewable recipe for LA/EDM authoring.
- `examples/lesson/`: S01/S02/S05/S11 plus the complete browser learning loop; contributor-training reference.
- `examples/statistics-distribution/`: S03 numeric summary and histogram lesson.
- `examples/statistics-association/`: S05 paired correlation lesson.
- `examples/statistics-bootstrap/`: S04 resampling and interval lesson.
- `examples/statistics-groups/`: S03/S04 group variation and ANOVA lesson.
- `examples/statistics-categories/`: S02/S05 observed-versus-expected chi-square lesson.
- `examples/penguin-pca/`: S08 flagship authentic-domain lesson; the first full 20-minute instructional exemplar.
- `examples/mtcars-efficiency/`: S03/S05/S08/S10 applied multivariate reference lesson.
- `docs/curriculum/r-foundations-micro-lessons.md`: short beginner R sequence supporting S01–S05 and S11.
- `docs/curriculum/learning-analytics-edm-lab.md`: LA/EDM application modules with synthetic-data safeguards.
- `docs/curriculum/module-authoring-template.md`: reusable authoring contract for adding future modules.

Every compiled lesson now exposes the same evidence IDs through a semantic table,
a true two-dimensional plot, and a three-dimensional scene when those
representations are declared. Theoretical probability distributions and
longitudinal/multilevel model adapters remain planned scope; they are not marked
as implemented merely because curriculum prose mentions them.

## Module completion contract

A module is not complete because its scene renders. It must include:

1. A learner-facing question and 2–4 measurable objectives.
2. A prerequisite and vocabulary list.
3. A predict–run–explore–explain–transfer activity.
4. At least one common misconception and a plain-language correction.
5. An accessible table/keyboard path and a non-visual explanation route.
6. An assessment rubric or exit ticket.
7. Data provenance, privacy/ethics boundary, and reproducibility metadata.
8. Educator notes, answer guidance, and one extension activity.

This contract is intentionally stronger than a visualization checklist: it keeps the R package useful as open educational infrastructure rather than as a gallery of 3D demos.
