# Community validation status

This file distinguishes implemented evidence from external evidence that cannot be claimed until it occurs.

## Implemented and internally verified

- Reusable R package rendering API
- Quarto lesson templates and three runnable reference lessons
- Browser-only 3D interaction with an accessible table alternative
- Predict–Explore–Explain–Transfer learning loop
- Reproducibility checks, `renv.lock`, CI workflow, and lesson reports
- Contributor guide, authoring guide, code of conduct, pilot protocol, and usability form
- Statistics concept pathway, R foundations micro-lessons, LA/EDM application modules, flagship PCA educator pack, answer key, rubric, and accessible alternative
- Literature-to-design note for Learning Analytics, Educational Data Mining, and Data Science Education
- Keyboard, mobile, and browser flow checks
- Synthetic novice-learner and screen-reader accessibility-tree proxy run; see [persona validation](../output/audit/persona-validation/persona-validation.md)

## External evidence still required

- At least two instructors or maintainers confirming reuse intent
- A small learner pilot using the documented protocol
- Recorded completion, usability, and accessibility findings
- Public repository engagement or an R community partner statement

No partner, learner, adoption, or community-impact claim should be marked complete until supporting evidence is linked here.

The synthetic persona run is an engineering regression guard only. It must not be counted as learner, educator, screen-reader, or Posit Cloud user evidence.

## Evidence register

Add one row only after the linked evidence exists. Public summaries should be aggregated and must not include learner names or raw private feedback.

| Evidence | Target | Status | Public link or repository path |
|---|---:|---|---|
| R/Quarto educator review | 2 reviewers | Recruiting | [Issue #2](https://github.com/Educatian/rlearnxr/issues/2) |
| Novice learner pilot | 5 learners | Recruiting | [Issue #3](https://github.com/Educatian/rlearnxr/issues/3) |
| Instructor authoring task | 2 instructors | Recruiting | [Issue #3](https://github.com/Educatian/rlearnxr/issues/3) |
| Concrete reuse statement | 2 statements | Recruiting | [Issue #2](https://github.com/Educatian/rlearnxr/issues/2) |
| External contribution | 1 issue, lesson, or documentation change | Open | Pending |
| Public v1 release | 1 tag and clean-clone install | Complete after v1.0.0 workflow pass | [v1.0.0](https://github.com/Educatian/rlearnxr/tree/v1.0.0) |

## Claim gate

Before submission, the proposal may state that external validation is planned. It may state that validation is completed only when this file links an aggregated pilot report and attributable reviewer or partner evidence.
