# R-LearnXR v2 Evidence Compiler quality summary

Date: 2026-08-20 Pacific / 2026-08-21 UTC

## R package

- Full test suite: PASS, 235 expectations with one intentional optional-dependency skip.
- Overall line/expression coverage: 85.18%.
- Evidence Compiler core coverage: 95.83%.
- `R CMD check --no-manual`: Status OK.
- `R CMD check --as-cran --no-manual`: one incoming-feasibility NOTE only because this is a new submission; no package-code, documentation, example, test, or vignette problems.
- Clean tarball install: PASS for development version 2.0.0.900 and `prcomp` evidence construction.
- pkgdown build: PASS, including all four vignettes and public API reference pages.

## Reference lessons

- Five lesson source builds: PASS.
- Five strict lesson checks: PASS for all 18 checks per lesson.
- Five Quarto renders: PASS.
- Each lesson includes `lesson-manifest.json` version 2.0 and `scene/evidence.json` schema `rlearnxr-evidence-2`.

## Browser interaction

- Desktop viewport 1440 x 920: no horizontal overflow or visible boundary overflow.
- Mobile viewport 390 x 844: no horizontal overflow and no element outside the viewport boundary.
- WebR execution: deterministic seed, valid scene data frame, finite axes, and scene synchronization all PASS.
- First table/scene observation: `obs-0001`.
- Linked values: `ev-0001-001`, `ev-0001-002`, and `ev-0001-003`.
- Explanation rubric: point, axis, direction, and limitation all PASS.
- Browser receipt markers: `receipt_version` 2.0 and `schema_version` `rlearnxr-receipt-2`.

## Screenshots

- `desktop-1440.png`: initial full desktop laboratory.
- `evidence-linked-explanation.png`: WebR-updated scene, semantic evidence table, and passing explanation rubric.
- `mobile-390.png`: responsive learner flow at 390 px.

Automated checks do not replace a human screen-reader review, authenticated Posit Cloud rehearsal, second-maintainer schema review, IRB determination, or real learner/instructor pilot.
