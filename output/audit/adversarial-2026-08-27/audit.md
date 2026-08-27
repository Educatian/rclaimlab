# R-ClaimLab adversarial audit — 2026-08-27

## Scope and target

This audit challenged the package, ten reference lessons, learner-facing browser flow, responsive behavior, clean-install workflow, release boundary, grant claims, budget language, and final five-page PDF. The primary learner target was a novice R user who must move from a prediction to executed R evidence, explanation, transfer, and a reproducibility receipt without relying on the 3D view.

## Findings resolved

| Area | Adversarial finding | Resolution | Verification |
|---|---|---|---|
| Learning guidance | The interface exposed stages but did not tell a novice what to do next at the point of action. | Added a visible stage-specific guidance banner for Orient, Predict, Run R, Explore, Explain, Repair, Transfer, and Reproduce. | Completed the full browser flow from Orient to receipt. |
| Evidence state | A default point was labelled “Selected observation” before the learner selected evidence. | The initial state is now “Preview observation”; an explicit table, 2D, or 3D selection changes it to “Selected observation”. | Verified after a real WebR run and table selection. |
| Content rendering | A scalar misconception string could be treated as an array and show only its first character. | Normalized scalar and array lesson metadata before rendering. | Added regression assertions and visually confirmed the complete method tip. |
| Readability | Several labels were too small and learning goals were compressed into a dense sentence. | Increased critical label/control sizes and rendered goals as a semantic list. | Inspected desktop, 390 px, and 320 px states. |
| Responsive layout | Narrow layouts were at risk of text/control overflow. | Retained the existing responsive system, enlarged controls within it, and checked the revised states at 390 px and 320 px. | No horizontal document overflow at either width. |
| Windows/Posit proxy | A lesson path containing spaces was not quoted for Quarto. `QUARTO_PATH` also failed when it named a directory instead of an executable. | Quoted render targets and resolved either a Quarto directory or executable path in validation, rendering, and environment diagnostics. | Clean-library install, exported API, strict checks, and renders passed for all ten lessons. |
| Release boundary | Checking the dirty workspace directly could include local audit/build artifacts and create misleading failures. | Added a source-tarball boundary checker and CI gate; clarified release documentation. | Source tarball contained 76 allowed members and no local workspace artifacts. |
| Grant evidence | Readiness overstated the adapter count and core coverage, and internal notes implied an award ceiling not published on the official page. | Replaced claims with measured values and explicit uncertainty: ten registered adapters, 90.85% overall coverage, 96.77% contract coverage, and no published per-project ceiling. | Cross-checked code registration, coverage output, and official call language. |
| Team/budget language | Naming a co-lead could imply confirmed consent, compensation, or a second contractor. | Identified Jewoong Moon as proposed primary contractor; made Yeonji Jung’s Co-Lead role, availability, milestone acceptance, public attribution, and any compensation contingent on written confirmation and contract/institutional requirements. | Confirmed in the proposal source and rendered PDF. |

## Verification evidence

- Package tests: 396 passed, 0 failed, 0 warnings, 1 intentional Shiny skip.
- Lesson contracts: 180 of 180 checks passed across ten lessons.
- Clean-environment persona: package install, exported API, strict checks, and Quarto rendering passed for all ten lessons.
- R source package: `R CMD check --as-cran --no-manual` passed on Windows R 4.6.1 with only the expected `New submission` NOTE when vignettes were built normally.
- Learner journey: Predict → WebR 0.6.0 execution → linked table evidence → four explanation criteria → transfer → reproducibility receipt completed.
- Responsive states: desktop, 390 px, and 320 px reviewed; no horizontal overflow observed.
- Proposal: five pages, visually inspected page by page; budget totals $10,000 and the team-status caveat remains visible.

## Current scores

| Dimension | Score | Basis |
|---|---:|---|
| R package and Evidence Compiler | 5/5 | Tested public contracts, ten adapters, deterministic artifacts, source-package gate. |
| Learner workflow and educational usefulness | 5/5 for implemented scope | End-to-end evidence reasoning loop works with real browser-side R execution and non-3D alternatives. |
| Responsive UI and interaction | 5/5 for tested viewports | Full core flow plus desktop, 390 px, and 320 px checks. |
| Reproducibility and release engineering | 5/5 locally | Clean install, ten renders, source tarball check, and CRAN-style check pass. |
| Proposal clarity and feasibility | 5/5 as a draft | Five-page self-contained narrative, scoped deliverables, explicit assumptions, and non-retroactive budget. |
| External validation readiness | 3/5 | Protocols and forms exist, but real people and written confirmations cannot be simulated as completed evidence. |

## External-only gates before submission

1. Obtain Yeonji Jung’s written permission for public Co-Lead attribution, January–June 2027 availability, Milestone 4 ownership, and the allowed compensation/contract arrangement.
2. Complete two short R/Quarto reviews and record how each finding changed the proposal or issue tracker.
3. Run at least one real novice session, then complete the planned five-learner/two-instructor feasibility sample if feasible and institutionally permitted.
4. Complete an actual screen-reader review; automated semantic and keyboard checks are not a substitute.
5. On or after the call opens, verify the live application form, attachment fields, applicant/contractor requirements, and any budget constraints not stated on the public call page.
6. Push the reviewed changes and require the public CI matrix to pass on the resulting commit before submission.

No completed human validation, endorsement, screen-reader certification, or award ceiling is claimed by this audit.
