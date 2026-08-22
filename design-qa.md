# Design QA

final result: passed

## Test setup

- Figma reference: `output/figma/rclaimlab-explore-screen.png`
- Desktop implementation: `output/playwright/rclaimlab-browser-smoke-desktop.png`
- Linked semantic table and 2D states: `output/playwright/rclaimlab-browser-smoke-table.png`, `output/playwright/rclaimlab-browser-smoke-2d.png`
- Mobile implementation: `output/playwright/rclaimlab-browser-smoke-mobile.png`
- Direct-interaction verification sheet: `output/demo/video-verification-contact-sheet.png`
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

- Desktop post-run: `output/audit/persona-validation/03-learner-r-verified.png`
- Linked evidence flow: `output/audit/persona-validation/04-learner-explain.png`
- Mobile result connection: `output/playwright/rclaimlab-browser-smoke-mobile.png`
- Mobile overflow check: 390 px viewport, `scrollWidth == clientWidth`
- Package tests: `pkgload::load_all('.')` plus `testthat::test_dir('tests/testthat')` passed
- Strict lesson checks: all ten reference lessons passed; Quarto rendering is verified in continuous integration
- Final browser QA: keyboard canvas controls, labelled inputs, landmarks, reduced-motion CSS, and 200% zoom with no horizontal overflow

## Intentional deviations from Figma

- The implementation adds a real WebR editor, console, checks, reproducibility record, downloads, and an eight-step learning path because the Figma source is a static visual reference.
- The companion uses internal dividers and a compact saved state to support sustained work at desktop density.
- Point positions are produced by learner-executed R, so the canvas preserves the Figma visual grammar while adapting to live data.

## Brand title pass

- Official project title: **R-ClaimLab: From R Code to Evidence**.
- Grant subtitle: *A Reproducible R Framework for Interactive Data Learning*.
- The package and repository identifier remain `rclaimlab` for compatibility.
- The lesson shell now uses the concise brand line `From R code to evidence` beneath `R-ClaimLab`.
- Browser evidence: `output/playwright/rclaimlab-browser-smoke-desktop.png` and `rclaimlab-browser-smoke-mobile.png`.
- Responsive result: 390 px viewport, `scrollWidth == clientWidth == 375`; no clipping or horizontal overflow.

## Storyboard completion pass

Date: 2026-08-22

Reference design: Figma file `jZ0W2ieUoSRwZtrMUKru8g`, explore lesson node `1:13`

Implementation reference: `inst/templates/scene.html`

The Figma-grounded shell and the current 1440 by 920 browser implementation retain the same three-part instructional hierarchy: learning path, dominant laboratory scene, and learning companion. The current implementation uses the repository's semantic tokens, compact instructional density, rectangular controls, visible focus states, and a single primary scene.

| Priority | Finding | Resolution |
|---|---|---|
| P0 | Orient appeared complete without learner evidence | Added validated, persisted Orient response |
| P0 | Explanation omitted a distinct limitation criterion | Added four criteria and a gated Repair step |
| P0 | Selecting a second point could satisfy Transfer | Added required transfer comparison response |
| P0 | Lesson and course completion were independent | Added evidence-backed local progress synchronization |
| P1 | Six-step rail hid the repair and transfer structure | Expanded to eight visible, responsive learning steps |
| P1 | Completion lacked an inspectable final state | Added provenance summary, downloads, receipt, and next-module handoff |
| P2 | Narrow layouts risked crowded step labels | Added 8, 4, and 2-column rail breakpoints and verified zero document overflow at 375 CSS pixels |

Final checks:

- Desktop 1440 by 920: no component collision or clipped primary control observed.
- Mobile 390 by 844 override: no horizontal document overflow; explanation criteria, transfer response, downloads, and receipt remain usable.
- Essential learning content remains visible on mobile. No instructional section was hidden to fit the viewport.
- Focus outlines are deliberately visible for keyboard navigation.
- Current evidence is stored in `output/audit/persona-validation/`, `output/playwright/`, and `docs/storyboards/assets/`.
