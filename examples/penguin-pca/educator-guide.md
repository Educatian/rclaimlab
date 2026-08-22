# Educator Guide — Penguin PCA

## Teaching purpose

This is the flagship R-ClaimLab lesson for multivariate reasoning. The 3D scene is not the objective; it is a controlled way to test whether a third coordinate changes a learner's interpretation.

## 20-minute facilitation plan

| Time | Activity | Instructor move | Learner evidence |
|---|---|---|---|
| 0–3 min | Orient and predict | Ask what one row and one variable represent; collect the PC3 prediction before code | written prediction |
| 3–7 min | Run R | Ask learners to locate `complete.cases()`, `scale. = TRUE`, and `set.seed()` | pipeline annotation |
| 7–12 min | Explore | Require one point from the scene or table; ask for sign, magnitude, and component | selected coordinate |
| 12–16 min | Explain | Use the sentence frame; challenge “positive = good” interpretations | evidence-based claim |
| 16–19 min | Transfer | Compare Adelie 4 and Chinstrap 13 or choose another pair | comparison + limitation |
| 19–20 min | Reproduce | Open the receipt and identify runtime, seed, rows, and hash | exit ticket |

## Prompts that keep the lesson conceptual

- “What question did this transformation make easier to ask?”
- “Which information disappeared when we reduced four measurements to three components?”
- “Would the same conclusion hold if we changed the sample or omitted standardization?”
- “What does this score support, and what would be an overclaim?”

## Facilitation for novice R learners

Do not start by explaining eigenvectors. Use the sequence: original measurements → comparable scale → new direction → observation score → evidence sentence. Offer `docs/curriculum/r-foundations-micro-lessons.md` as a warm-up.

## Accessibility route

Invite all learners to use the table first if spatial rotation is distracting or unavailable. The expected reasoning is identical: select a row, cite a coordinate, compare, and state a limitation. Read the axes and coordinates aloud only as labels, not as an instruction to infer a value from color or depth.

## Common failure recovery

- **Learner says “PC1 is body mass”:** explain that a component is a weighted direction involving several original variables; inspect loadings.
- **Learner says “positive means better”:** explain that PCA signs are orientation conventions, not value judgments.
- **Learner compares unscaled raw variables:** ask which variable would dominate because of its unit.
- **Learner treats close points as identical:** ask what PC3 or the table reveals.
- **WebR is unavailable:** use the saved scene, source R code, and table fallback; record the runtime limitation in the receipt.

## Debrief

Close by asking learners to distinguish three claims:

1. **Descriptive:** these observations have different scores.
2. **Interpretive:** the score direction is associated with a pattern in the original measurements.
3. **Causal:** the measurements caused a biological outcome — not supported by this lesson alone.
