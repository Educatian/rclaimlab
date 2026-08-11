# R-LearnXR Persona and Grant-Fit Audit

Date: 2026-08-11

## Overall verdict

R-LearnXR is a strong thematic fit for the R Consortium ISC program, but the current build is only sufficient as a technical proof of concept. It demonstrates a focused R package, a browser-based 3D scene, a Quarto lesson scaffold, and automated project-hygiene checks. It does not yet demonstrate a complete learning loop, contributor adoption, or fully reproducible execution.

Recommended status: **continue toward submission, but do not present the current screen as a completed educational framework.** Position it as an implemented MVP and complete the priority gaps below before the proposal deadline.

## Audit scope

- Learner flow: enter the Explore screen, understand the task, predict, rotate and inspect data, explain, and receive feedback.
- Accessibility and responsive flow: use the lesson with keyboard interaction and at a 390 x 844 mobile viewport.
- Instructor/contributor flow: scaffold a lesson, regenerate a scene, and run reproducibility checks.
- Grant fit: compare the current artifacts with the official ISC criteria of broad R-community impact, focused scope and clear deliverables, and low-to-medium risk with demonstrable value.

Official sources:

- [R Consortium ISC Call for Proposals](https://r-consortium.org/all-projects/callforproposals.html)
- [First-round 2026 technical grant awards](https://r-consortium.org/posts/r-consortium-awards-first-round-of-2026-technical-grants/)

## Persona findings

### 1. Novice data-science learner

Goal: understand how a point's x, y, and z position supports an interpretation.

Health: **partially usable**.

Strengths:

- The learning goal, progress, interaction instructions, and selected-point coordinates are visible on desktop.
- Drag rotation, reset, and point hover work.
- The browser-only design lowers the entry barrier by avoiding headset setup.

Blocking gaps:

- Prediction and explanation surfaces are styled `div` elements, not editable inputs; the page contains zero input, textarea, or editable controls.
- `Check explanation` produces no visible state, feedback, or text change.
- Learning-path steps are not navigable.
- After hovering `share` with y = 0.85, the observation sentence still says the point is below average on y. Coordinates update, but the pedagogical explanation does not.
- There is no completion state, saved response, or transfer task.

### 2. Keyboard, screen-reader, or mobile learner

Goal: complete the same learning task without precise pointer control and on a narrow screen.

Health: **not yet usable**.

Strengths:

- The page has a main landmark, complementary regions, headings, button semantics, and a canvas aria-label.
- The 390 px layout avoids horizontal overflow.

Blocking gaps:

- The canvas has `tabIndex = -1` and only supports pointer drag, pointer hover, and wheel zoom.
- The prediction and explanation prompts are not keyboard focusable.
- There is no accessible data table or non-canvas equivalent for the plotted values.
- At 390 x 844, both the learning path and the entire learning companion are hidden, removing the learning goal, prediction, observation, explanation, and feedback flow.

### 3. Instructor and open-source contributor

Goal: create a lesson, regenerate it, verify it, and adapt or contribute it.

Health: **promising technical skeleton**.

Strengths:

- `scaffold_lesson()`, `render_scene()`, and `check_lesson()` provide a compact, understandable API.
- The smoke test passes and current project checks report no failures.
- The generated scene has no runtime web dependency and uses portable paths plus a deterministic seed.
- The package and code are MIT-licensed.

Blocking gaps:

- Only one toy reference lesson exists; it does not demonstrate a real analysis outcome or classroom use case.
- `renv.lock` is absent, and Quarto is not available in the current environment, so the advertised end-to-end reproducibility claim has not been demonstrated here.
- No public Git remote is configured, so community reuse, issue participation, and contributor history cannot yet be inspected.
- Contributor training, authoring guidance, lesson schema, accessibility guidance, and extension points are not yet delivered.

## Grant-fit scorecard

| ISC fit dimension | Current score | Evidence | Main gap |
|---|---:|---|---|
| R technical/social infrastructure | 4/5 | R package API, Quarto scaffold, checks, reusable browser scene | Community-facing release and adoption evidence |
| Focused scope and clear deliverables | 4/5 | Three bounded package functions and one reference lesson | Define acceptance criteria for each grant deliverable |
| Low-to-medium implementation risk | 4/5 | Working package, passing smoke test, dependency-free scene | Quarto/renv CI and cross-platform test evidence |
| Demonstrable value to R users | 3/5 | Working 3D inspection and lesson scaffold | Real R analysis lesson and user-task completion |
| Broad R-community impact | 2/5 | General-purpose concept and open license | Named partner communities, pilots, reuse commitments |
| Reproducible workflow | 3/5 | Seed, portable paths, automated report | Missing lockfile and verified Quarto render |
| Education and contributor capacity | 2/5 | Learning UI concept and README | Functional pedagogy, contributor curriculum, author docs |

Overall: **22/35 (63%) — strong fit, incomplete evidence.**

## Priority work before submission

### Must demonstrate

1. Complete one learner loop: editable prediction, data interaction, editable explanation, meaningful feedback, and completion state.
2. Generate observation and feedback text from the selected point so coordinates and explanation cannot contradict one another.
3. Preserve the learning companion on mobile with a stacked or collapsible layout.
4. Add keyboard controls for the 3D view and an accessible data-table alternative.
5. Add `renv.lock`, install Quarto in CI, render the reference lesson, and archive the reproducibility report as a build artifact.
6. Publish a public repository with `CONTRIBUTING.md`, a code of conduct, issue templates, an authoring tutorial, and explicit educational-content licensing.

### Strong proposal evidence

1. Replace or supplement the toy points with one authentic, openly licensed R lesson showing why 3D exploration improves a specific interpretation task.
2. Run a small formative test with at least five novice learners and two instructors; report task completion, comprehension, usability friction, and intended reuse.
3. Obtain two short letters or GitHub statements from R educators, R-Ladies/R user groups, package maintainers, or instructors who would pilot or contribute lessons.
4. Frame XR as an optional progressive enhancement. Keep browser, keyboard, and static/table fallbacks as the funded infrastructure baseline.

## Evidence captured

1. `01-learner-entry-desktop.png` — desktop entry and information hierarchy; health: good visual orientation.
2. `02-explanation-dead-end.png` — explanation button focus with no resulting feedback or state change; health: blocked learning loop.
3. `03-explore-after-rotation.png` — scene changes after pointer drag; health: working core interaction.
4. `04-hover-data-feedback-mismatch.png` — hovered point updates coordinates but not the explanatory sentence; health: misleading feedback.
5. `05-mobile-learner-entry.png` — narrow viewport hides the learning path and companion; health: blocked mobile learning flow.

## Evidence limits

- This was an expert heuristic and functional audit, not a moderated study with representative participants.
- Screen-reader output, color-contrast ratios, zoom beyond the tested viewport, reduced-motion behavior, and headset/WebXR behavior were not verified.
- Quarto rendering could not be tested because the CLI is unavailable in the current environment.
