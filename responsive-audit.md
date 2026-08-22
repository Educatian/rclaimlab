# Responsive UI Audit

## Scope

- Surface: reference R-ClaimLab lesson
- Flow: learning path → 3D data space → R code lab → accessible point selector
- Widths tested: 1440, 1200, 1120, 1025, 1024, 1000, 960, 900, 800, 760, 600, 480, 390, 360, and 320 px
- Evidence: `output/playwright/rclaimlab-browser-smoke-desktop.png` and `output/playwright/rclaimlab-browser-smoke-mobile.png`
- Method-specific mobile evidence: `output/playwright/rclaimlab-browser-smoke-method-contract-mobile.png`

## Findings and fixes

1. **Tablet learning path — fixed**
   - Before: the six steps used a horizontally scrolling row and DONE/CURRENT labels crossed button boundaries between roughly 761 and 1000 px.
   - Fix: compact six-column treatment above the tablet breakpoint and a 3 × 2 grid below it; tablet state words are represented through color and `aria-current` without crowding the label.

2. **Tablet workspace — fixed**
   - Before: the main workspace and companion remained side by side at 800 px, leaving the R editor and results in unusably narrow columns.
   - Fix: the app switches to a single-column document layout at 1024 px; the code workspace and results stack at full content width.

3. **Mobile navigation and status — fixed**
   - Before: the status chip wrapped, Reproduce was ellipsized, and view-tab labels split across lines at 320 px.
   - Fix: the compact header removes secondary brand copy, the learning path becomes a 2 × 3 grid below 360 px, and equal-width no-wrap tabs hide the secondary REAL R tag only at the narrowest width.

4. **Learner-generated text — fixed**
   - Before: long unbroken prediction text could force a flex item beyond its intended width.
   - Fix: flex children can shrink and learner text uses safe anywhere wrapping inside the saved-summary card.

5. **Accessible point selector — fixed**
   - Before: the table required horizontal scrolling on narrow phones.
   - Fix: below 560 px, each row becomes a labelled data card with a full-width Inspect action.

## Verification

- Page-level horizontal overflow: 0 px at every tested width.
- Learning-path horizontal overflow: 0 px at every tested width.
- R editor horizontal overflow: 0 px at every tested width.
- Mobile accessible data card overflow: 0 px at 320 px.
- Long unbroken learner prediction overflow: 0 px at 320 px.
- Automated package tests: full `testthat` suite passed, with the optional Shiny runtime test skipped when Shiny is unavailable.
- Browser, offline, course-home, beginner-guide, and persona smoke tests: passed.

## Evidence limits

The browser checks confirm visible reflow, text containment, interactive tab behavior, and measured horizontal overflow. They do not by themselves establish full WCAG conformance or screen-reader behavior across every platform.
