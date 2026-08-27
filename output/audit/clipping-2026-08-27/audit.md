# R-ClaimLab clipping audit — 2026-08-27

## Scope

- Reference lesson states: Evidence Views, R Code Lab, AI Visual Brief
- Course home
- Viewports: 1440×900, 1024×768, 640×720, 390×844, 320×700
- Stress state: long learner orientation and prediction text saved at 390×844

## Findings repaired

- Method and observation tags truncated with ellipsis.
- Learning-path labels carried ellipsis rules below 1120px.
- Saved predictions were limited to two lines.
- R code toolbar labels, runtime values, hashes, and AI metadata were truncated.
- The mobile title row allowed the non-wrapping step counter to widen the document.
- Narrow layouts needed stable wrapping for tabs, action buttons, metadata grids, and top-bar status.

## Verification result

| Surface/state | Viewports checked | Document overflow | Visible text clipping |
|---|---:|---:|---:|
| Evidence Views | 5 | 0 | 0 |
| R Code Lab | 5 | 0 | 0 |
| AI Visual Brief | 5 | 0 | 0 |
| Course home | 5 | 0 | 0 |
| Long learner input | 390×844 | 0 | 0 |

The scanner excludes intentional `.sr-only` accessibility clipping and permits scrollable source-code/table regions. It flags visible ellipsis, line clamp, hidden text overflow, and document-level horizontal overflow.

## Automated checks

- R testthat suite: PASS
- Ten strict reference-lesson checks: PASS
- Posit Cloud clean-room persona validation and Quarto rendering: PASS
- Source tarball boundary: PASS (76 members; no local workspace artifacts)

## Screenshot note

The in-app browser's screenshot command timed out on both the lesson and the canvas-free course page. Layout verification therefore used live DOM geometry and computed-style measurements rather than a saved image. No external browser automation or desktop capture was used.
