# R Educator Mockup Review

Date: 2026-08-12
Persona: R Educator who teaches introductory data science/R/Quarto and wants to turn an existing analysis into a short, reproducible, accessible lesson without hand-wiring JavaScript.

## Review objective

Evaluate whether an educator can discover the authoring path, understand the R-to-3D contract, run and debug real R code, interpret reproducibility evidence, and hand the result off to a Quarto project.

## Task walkthrough and evidence

### 1. Enter the reference lesson and identify the educator path

Evidence: [01 educator entry](01-educator-entry-clean.png)

Strengths:

- The learner-facing goal, six-step learning path, R lab, and accessibility-oriented interaction are immediately legible.
- The product communicates that the experience is a reference lesson rather than a generic dashboard.

Issue:

- The entry point is learner-first. There is no explicit `For educators`, `Author a lesson`, or `Open authoring guide` action. An R Educator has to infer that the R Code Lab contains an authoring bridge.

Accessibility risk/limit:

- The semantic structure is visible in the browser snapshot, but this screenshot cannot establish screen-reader announcement order or whether the educator task is discoverable without visual scanning.

### 2. Find the R-to-3D contract and package workflow

Evidence: [02 R Code Lab](02-r-code-lab.png)

Strengths:

- `scene <- data.frame(label, x, y, z)` is a strong, concrete contract.
- The UI explains the role of labels and numeric axes in plain language.
- The package workflow is shown in the same place as the interactive proof: `scaffold_lesson()`, `render_scene()`, and `check_lesson()`.
- The browser dependency boundary is disclosed: WebR runs in the tab and no R server or headset is required.

Issues:

- The package workflow is visually subordinate to the learner lab and does not expose the recommended release command `check_lesson(..., strict = TRUE)`.
- There is no direct link from the card to `docs/authoring-guide.md`, `docs/runtime-dependencies.md`, `CONTENT_LICENSE.md`, or the contribution workflow.
- The phrase “pins WebR 0.6.0” is useful for technical reviewers but does not tell an educator what to do when the first-run runtime cannot load.

### 3. Edit and run real R code

Evidence: [03 R editor visible](03-r-editor-visible.png)

Strengths:

- The bridge is tangible: a real editable R script, a real R console, a visible run action, and `.R`/`.qmd` downloads.
- The UI gives a deterministic seed and makes the returned scene rows and artifact hash visible.
- This is credible evidence for the grant’s R-first positioning; the 3D view is downstream of the R result rather than a disconnected animation.

Issues:

- At 1280×720, the educator needs to scroll to see the editor and its reproducibility panel. The authoring flow is therefore not fully scannable in one viewport.
- `Download .qmd` has no explanation of its contents, destination, or how it maps to a local Quarto project.
- The editor does not show the relationship between this browser script and the generated `index.qmd`/`scene/` project structure.

### 4. Verify a successful execution

Evidence: [04 R run success](04-r-run-success.png)

Strengths:

- The success state is unusually strong for a prototype: R runtime, seed, artifact hash, row count, console output, and four automatic checks are all visible.
- “R execution verified” plus “R engine · execution passed” provides clear positive feedback.
- The result offers a next action, “View updated 3D space,” preserving the R → scene → evidence sequence.

Issue:

- The top-level “Reproducibility ready”/“R execution verified” language can be read as project release validation. In reality, the browser checks do not replace the local strict `check_lesson()` report, Quarto render, license review, or CI.

### 5. Recover from invalid R code

Evidence: [05 error recovery](05-r-error-recovery.png)

Strengths:

- The failure state is visually distinct and announces “Try this fix.”
- The technical console remains available, while the plain-language message says that the pipeline returned no scene and should be run again.
- Automatic checks separate PASS, FIX, and PENDING instead of presenting a misleading all-or-nothing failure.

Issues:

- The recovery guidance still says “Check the technical console for the failing line,” which is appropriate for an R educator but not sufficiently actionable for a beginner-facing lesson. It should name the expected output contract and show a minimal repair snippet.
- The captured test intentionally inserted an escaped newline, so the console error is a parse error. The UI correctly surfaces it, but it does not normalize or explain the line-level cause.
- The stale artifact hash and previous row count remain visible after failure. They are useful provenance, but should be explicitly labeled “last successful run” to avoid confusion.

### 6. Check narrow-screen author usability

Evidence: [06 mobile R lab](06-mobile-r-lab.png)

Strengths:

- The 390×844 viewport preserves the learning path, R lab tabs, contract card, and initial execution state without visible horizontal clipping.
- The tabs collapse their labels cleanly and the R lab remains identifiable.

Limits:

- The screenshot only covers the upper portion of the mobile flow; it does not prove that the code editor, console, download controls, table, and error state remain usable at the bottom of the page.
- A phone is not the primary authoring target. The important follow-up is a narrow laptop/tablet layout with keyboard and download testing.

## R Educator scorecard

| Dimension | Score | Evidence-based assessment |
|---|---:|---|
| Discoverability of author mode | 2/5 | No explicit educator entry or author CTA; authoring is discovered inside a learner tab. |
| R authenticity | 5/5 | Real R execution, visible console, deterministic seed, scene contract, and downstream 3D update. |
| Authoring continuity | 3/5 | Package commands and downloads exist, but the browser lesson is not clearly connected to the Quarto project structure. |
| Reproducibility handoff | 3/5 | Strong browser evidence, but release-level `strict=TRUE`, Quarto, license, and CI boundaries are not in the UI. |
| Error recovery | 4/5 | Good state separation and actionable direction; needs a concrete minimal repair example. |
| Accessibility communication | 4/5 | Skip link, named regions, semantic tabs/table path, keyboard path, and visible statuses are strong; screen-reader/zoom/reduced-motion behavior is not proven by this audit. |
| Responsive author usability | 4/5 | No clipping in the captured mobile upper flow; full editor/download flow still needs a dedicated narrow-layout pass. |

Overall R Educator fit: **3.6/5**. The technical proof is grant-ready for an MVP demonstration; the author onboarding and release handoff are not yet educator-ready enough for a community infrastructure claim.

## Prioritized improvements

1. Add a persistent `For educators: author a lesson` link near the lesson identity and inside the R Code Lab.
2. Add an “Authoring checklist” card with the exact path: `scaffold_lesson()` → edit `index.qmd` → `render_scene(..., overwrite = TRUE)` → `check_lesson(..., strict = TRUE)` → `quarto render`.
3. Link the card to the authoring guide, runtime-dependency note, content/data license, accessibility guide, and contribution guide.
4. Split status language into `Browser preview ready` and `Project release checks pending/passed` so the prototype cannot overclaim reproducibility.
5. Label downloads with their role, e.g. “Download learner `.qmd`” and “Download analysis `.R`,” and explain how to place them in a scaffolded lesson.
6. Improve the error state with a minimal valid `scene` repair snippet and label retained provenance as “last successful run.”
7. Mark the AI Visual Brief as optional and non-blocking in the educator flow, keeping the R/package/Quarto path visibly primary.

## Verdict

This mockup is a convincing R-language learning demonstration and a credible R-package proof-of-concept. An R Educator can see authentic R execution and reproducibility evidence, but must still reverse-engineer how to author, validate, license, and publish a reusable Quarto lesson. The next improvement should be author-mode discoverability and the project-level release checklist, not more 3D polish.

## Follow-up verification after feedback implementation

The implementation pass addressed the prioritized findings and was rechecked in the real browser.

1. **Educator entry** — [07 educator authoring entry](07-educator-authoring-entry.png): the top-bar `For educators: author a lesson` action opens the R lab and focuses the authoring handoff card.
2. **Authoring handoff** — [07 educator authoring entry](07-educator-authoring-entry.png): the card now shows the complete `scaffold_lesson()` → `render_scene(..., overwrite = TRUE)` → `check_lesson(..., strict = TRUE)` → `quarto render` path and links to the authoring, runtime, license, and accessibility references.
3. **Successful browser proof** — [08 updated R success](08-updated-r-success.png): browser checks are explicitly labeled, the record is labeled “Last successful browser run,” and the UI distinguishes browser evidence from the local release gate.
4. **Error recovery** — [09 updated R error recovery](09-updated-r-error-recovery.png): the error status changes to `Browser preview needs attention`, the technical console remains available, and the UI supplies a minimal valid `scene` repair example.
5. **Responsive author view** — [10 mobile authoring flow](10-mobile-authoring-flow.png): the authoring card, download explanations, and release note remain in the narrow layout without horizontal clipping in the captured viewport. The reset path was also corrected so `Start over` returns the top status to `Browser preview ready`.

Follow-up score: **4.6/5** for R Educator fit. Discoverability and authoring continuity are now strong. Remaining evidence limits are screen-reader announcement order, 200% zoom, reduced-motion behavior, and a local Quarto CLI run; Quarto was not installed in this environment, so `check_all_lessons.R` reports only `quarto_available` as a release-environment failure.
