# Design QA

final result: passed

## Test setup

- Figma reference: `output/figma/rlearnxr-explore-screen.png`
- Desktop R success: `output/ui-improved/03-desktop-r-success.jpg`
- Desktop 3D success: `output/ui-improved/04-desktop-scene-success.jpg`
- Mobile entry, R, and 3D states: `output/ui-improved/05-mobile-top.jpg`, `06-mobile-r.jpg`, `07-mobile-scene.jpg`
- Side-by-side comparison: `output/ui-improved/08-design-qa-contact-sheet.png`
- Tested flow: Predict → Run real R → verify checks → inspect synchronized 3D result
- Tested viewports: desktop 1440 × 810 and mobile 390 × 844

## Audit findings and fixes

| Severity | Finding | Implemented fix | Evidence |
|---|---|---|---|
| P1 | The post-R camera fit clipped some returned points. | Projection bounds now fit the current R result and clamp labels inside the canvas. | Five returned points are visible in desktop and mobile 3D captures. |
| P1 | Scene controls remained visible in the R tab. | Scene controls and the accessible selector now live inside the scene tab panel. | The R success capture contains only code and execution controls. |
| P2 | The desktop shell behaved like a long page and retained stale scroll positions. | Desktop uses a viewport-height app shell with internal regions; view changes reset the main workspace. | The final desktop capture shows the full title and workspace without body scrolling. |
| P2 | The R editor exposed a black gap and mobile horizontal scrolling. | Starter code uses readable short lines; the editor wraps softly and scrolls vertically only. | Mobile R capture shows no horizontal scrollbar. |
| P2 | Completed prediction work competed with the active R task. | Saved predictions collapse into a compact summary with an Edit action. | Desktop R and 3D captures preserve context without a large inactive form. |
| P2 | Mobile progression was hard to scan. | The six steps use a 3 × 2 grid and view changes return to the top of the page. | Both mobile captures show all six steps and the current state. |

## Final surface review

| Surface | Result | Notes |
|---|---|---|
| Typography | Pass | Compact technical typography, hierarchy, and code treatment match a working analysis product. |
| Spacing and layout | Pass | Desktop shell, learning rail, workspace, and companion align; mobile has no page-level horizontal overflow. |
| Colors and tokens | Pass | Blue, teal, orange, and semantic state colors preserve the Figma intent with accessible contrast. |
| R learning surface | Pass | Editable R, WebR runtime state, console, four checks, exports, and 3D synchronization are connected. |
| Copy and content | Pass | Copy clearly follows Predict → Run R → Explore → Explain → Reproduce. |
| Interaction states | Pass | Ready, running, success, error, edit, restart, download, selection, and completion states are implemented. |
| Responsiveness | Pass | Desktop and mobile flows remain readable, usable, and free of clipped controls. |
| Accessibility | Pass | Semantic tabs, labelled inputs, focus indicators, keyboard canvas, live regions, reduced motion, and an accessible data selector are present. |

## Post-audit learning-evidence review

The product-design audit identified one remaining risk: the strongest learning signal was distributed across the R editor, checks, and updated scene. The implementation now makes the causal chain visible in one result state:

- `Evidence reveal` reports the baseline and returned row counts, the removed point, and the transformation summary.
- `Claim / Evidence / Code` connects the selected point to an interpretable coordinate and the supporting R line.
- `Reproducible run` pins the runtime, seed, returned rows, and artifact hash beside the console.
- The AI panel now presents a four-step `Intent -> Review -> Run -> Inspect` workflow, keeping generated code reviewable and optional.

## Current implementation evidence

- Desktop post-run: `output/audit/design-improvements/02-evidence-reveal-desktop.png`
- AI review flow: `output/audit/design-improvements/03-ai-review-flow.png`
- Mobile result connection: `output/audit/design-improvements/07-mobile-evidence-connection.png`
- Mobile overflow check: 390 px viewport, `scrollWidth == clientWidth`
- Package tests: `pkgload::load_all('.')` plus `testthat::test_dir('tests/testthat')` passed
- Strict lesson checks: all three reference lessons passed with the pinned Quarto binary
- Final browser QA: keyboard canvas controls, labelled inputs, landmarks, reduced-motion CSS, and 200% zoom with no horizontal overflow

## Intentional deviations from Figma

- The implementation adds a real WebR editor, console, checks, reproducibility record, downloads, and a six-step learning path because the Figma source is a static visual reference.
- The companion uses internal dividers and a compact saved state to support sustained work at desktop density.
- Point positions are produced by learner-executed R, so the canvas preserves the Figma visual grammar while adapting to live data.

## Brand title pass

- Official project title: **R-LearnXR: From R Code to Evidence**.
- Grant subtitle: *A Reproducible R Framework for Interactive Data Learning*.
- The package and repository identifier remain `rlearnxr` for compatibility.
- The lesson shell now uses the concise brand line `From R code to evidence` beneath `R-LearnXR`.
- Browser evidence: `output/audit/design-improvements/13-browser-title-desktop.png` and `14-browser-title-mobile.png`.
- Responsive result: 390 px viewport, `scrollWidth == clientWidth == 375`; no clipping or horizontal overflow.
