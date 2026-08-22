# Learning Analytics and EDM Lab Modules

This track teaches learners to analyze learning data without turning people into scores. All examples in the v1 course use synthetic or openly licensed data. The browser stores work locally and exposes the evidence and limitation boundary to the learner.

## LA01 — From event to construct

Learners distinguish an observable event from the construct they hope to understand.

| Event | Possible measure | What it cannot prove by itself |
|---|---|---|
| Number of R runs | persistence or debugging activity | motivation, ability, or learning |
| Time on task | time spent in the activity | attention or comprehension |
| Prediction text | prior reasoning | correctness without a rubric |
| Explanation with coordinate | evidence use | durable conceptual learning |
| Transfer completion | application in a new case | general mastery across contexts |

**Activity:** mark each event as observable, interpreted, or claimed. Then choose one additional piece of evidence needed before acting.

## LA02 — Descriptive learning analytics

Learners compare distributions of attempts, explanation evidence, and transfer completion across synthetic groups. They report counts and uncertainty rather than ranking learners.

**R sequence:** inspect → group → summarize → visualize → state limitation.

**Output:** a learner-facing summary card with the question, denominator, statistic, visualization, and limitation.

## LA03 — Feedback and intervention

Learners choose a reversible support action from visible evidence:

- offer a vocabulary hint,
- show the table alternative,
- provide a smaller R step,
- invite a second attempt,
- or take no action because the evidence is insufficient.

The module explicitly rejects automatic labels such as “at risk” or “low ability.”

## EDM01 — Feature engineering

Learners aggregate event-level records into learner-level features, documenting the time window, missing values, denominator, and whether the feature is available before the outcome.

```r
features <- aggregate(
  cbind(run_count, explanation_length, transfer_success) ~ learner_group,
  data = events,
  FUN = mean
)
```

**Critical question:** “Could this feature leak the answer into the prediction?”

## EDM02 — Pattern discovery

Learners compare two clustering choices or two event sequences and test whether the pattern changes when scaling or the number of clusters changes. A cluster is presented as a descriptive pattern, never as a learner diagnosis.

## EDM03 — Transparent prediction

Learners inspect a simple classification rule, confusion matrix, false positives, false negatives, and subgroup differences. The goal is model critique and educational decision-making, not deploying a high-stakes predictor.

## EDM04 — Ethics and learner agency

Before any analysis, learners answer:

1. What is the educational purpose?
2. Is the data necessary and consented?
3. Who can see the result?
4. Can the learner inspect or contest it?
5. What harm could a false positive or false negative cause?
6. What is the deletion/retention boundary?

## Capstone

Design an R-ClaimLab activity that connects one statistical concept to one educational decision. Submit:

- learning question and objectives,
- data dictionary and provenance,
- R/Quarto analysis,
- accessible visual/table path,
- evidence-based claim and limitation,
- reversible intervention or no-action decision,
- reproducibility report and learning receipt.

The capstone rubric is in `examples/penguin-pca/assessment-rubric.md` and is reusable across modules.
