# Demo / package parity release — September 3, 2026

Production: https://rclaimlab-review.pages.dev/  
Cloudflare production deployment: `fac412c3`  
Verified preview: `e060253a`  
Package source: `323684f00495c350a1d1020ce9393e06046da30f` on
`codex/v2.1-role-workflows`. Main was not changed.

## Implemented

- Shared four-mode launcher markup, labels, role paths, icons and responsive CSS.
- One package-bundled 300-row synthetic dataset and four canonical plans.
- Shiny example inputs, generated plans and hosted activity prompts match.
- Complete, source-verified local R rerun functions for all four roles, including
  descriptive analysis and reviewer workflows. No source rows or secrets embedded.
- Fresh public builds from the exact GitHub-installed package; no copied stale
  role bundles or public-only Guided prompt overrides.
- Immutable install command, public release inventory, route/checksum checks,
  legacy links and local mode-change guidance.
- Expanded Font Awesome attribution with the complete upstream license.

## Verification actually performed

| Check | Result |
|---|---|
| Windows R 4.6.1 package check | Status OK, 0 errors/warnings/notes |
| Package tests | 831 passed, 1 expected optional-dependency skip |
| Existing 10 lesson strict checks | Passed; existing lesson files not rebuilt |
| Four role Quarto reports | Rendered successfully in isolated copies |
| Exact GitHub SHA clean install | Successful, isolated library |
| Four exported R scripts in fresh R process | Same evidence tables and bundle hashes |
| Complete local release inventory | All generated file checksums matched |
| Preview and production HTTP checks | Four roles, legacy URLs, 404 behavior, immutable ref and selected artifact checksums passed |
| Real Shiny browser flow | Scientist: example/import/plan/four approvals/run/result |
| Browser interaction | Mode selection, own-data instructions, reviewer navigation, 2D and subgroup stage |
| Launcher visuals | Desktop 1440x920, mobile 390x844, native keyboard radio navigation, no page-width overflow, buttons >=44px |

Two static-export defects (dropped head/styles and escaped role descriptions)
and a standalone icon class mismatch were caught on preview and fixed before
production. HTTP checks alone did not catch these; browser review remains a gate.

Evidence in the local workspace:

- `output/parity-check-323684f/rclaimlab.Rcheck/00check.log`
- `output/parity-check-323684f/rclaimlab.Rcheck/tests/testthat.Rout`
- `output/parity-github-323684f/` (isolated exact-ref install)
- `output/cloudflare-parity-323684f/` (identical preview/production payload)
- `output/parity-quarto-20260903/`
- `output/parity-update-preview-20260903/public-final-desktop.png`
- `output/parity-update-preview-20260903/public-final-mobile.png`
- `output/parity-update-preview-20260903/shiny-desktop.png`
- `output/parity-update-preview-20260903/shiny-mobile.png`
- `output/parity-update-preview-20260903/shiny-scientist-result.png`

The running local wizard at http://127.0.0.1:8791/ was restarted with the exact
GitHub-installed package. Default user libraries were not overwritten.

## Honest limits

Hosted mode workspaces remain precompiled examples, not a remote R or Shiny
service. Own-data import and full R execution happen locally. The hosted example
therefore opens directly, while local example execution still requires explicit
review and approval. Mode switching does not automatically migrate personal claims.
The earlier demo videos and generated reference lesson folders are historical
artifacts; this change does not claim to rerecord videos or rewrite interventions.
Full cross-OS, real screen-reader, independent educator and real learner validation
remain separate release gates. This is not a CRAN or research-effectiveness claim.
