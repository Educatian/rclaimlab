# R-LearnXR MVP

R-LearnXR is an open-source prototype for reproducible, browser-based R laboratories built with Quarto, WebR, and interactive 3D scenes. The MVP treats 3D/XR as an optional evidence layer. Learners edit and execute real R code in the browser, send the resulting data frame into the 3D view, explain coordinate evidence, and export the work as reproducible R or Quarto source.

## Grant demo

[![R-LearnXR English narrated demo verification frames](output/demo/video-verification-contact-sheet.png)](output/demo/rlearnxr-demo-en.mp4)

[Watch the 103-second English narrated and captioned demo](output/demo/rlearnxr-demo-en.mp4) or download the [English captions](output/demo/rlearnxr-demo-en.srt). The narration is AI-generated with ElevenLabs using the voice `Alice — Clear, Engaging Educator`.

Grant preparation materials:

- [Application preparation checklist](grant/application-prep.md)
- [ISC proposal draft](grant/isc-proposal-draft.md)
- [Team and budget decisions](grant/team-budget-checklist.md)
- [Grant-readiness scorecard](GRANT_READINESS.md)
- [Community validation status](community/validation-status.md)

## What works now

- `scaffold_lesson()` creates a small Quarto lesson project.
- `render_scene()` creates `scene/index.html` and `scene/points.json` from three numeric columns.
- A pinned WebR 0.6.0 runtime executes learner-edited R without an application server.
- Successful R output updates the scene, accessible table, selected-point evidence, artifact hash, and reproducibility record.
- The complete learner loop supports prediction, real R execution, 3D exploration, evidence-based explanation, transfer, export, and completion.
- Pointer, keyboard, mobile, and accessible data-table paths expose the same analytical evidence.
- `check_lesson()` writes a Markdown report, session information, and generated-artifact hashes.
- `examples/lesson/` is the contributor-training lesson; `examples/penguin-pca/` is the authentic analysis lesson.
- GitHub Actions checks the R package, rebuilds both lessons, renders Quarto, and uploads the reports.

## Visual preview

![R-LearnXR browser-based 3D demo](output/playwright/rlearnxr-3d-demo.png)

## Figma UI reference

The Explore lesson interface was refined in [Figma](https://www.figma.com/design/jZ0W2ieUoSRwZtrMUKru8g) before being translated back into the browser demo.

![R-LearnXR Explore lesson UI](output/figma/rlearnxr-explore-screen.png)

## Run the MVP

From this directory, run:

```r
source("R/utils.R")
source("R/zzz.R")
source("R/render_scene.R")
source("R/scaffold_lesson.R")
source("R/check_lesson.R")
check_lesson("examples/lesson")
```

Open `examples/lesson/scene/index.html` in a browser. The first R execution downloads the pinned WebR runtime; subsequent executions stay in the tab. In a Quarto-enabled environment, run `quarto render examples/lesson` to render the lesson page.

Build and check every lesson from the repository root:

```powershell
Rscript scripts/build_all_lessons.R
Rscript scripts/check_all_lessons.R
quarto render examples/lesson
quarto render examples/penguin-pca
```

Contributor onboarding starts in [CONTRIBUTING.md](CONTRIBUTING.md). The authoring, accessibility, pilot, and roadmap documents turn the MVP into reusable community infrastructure rather than a one-off demonstration.

## Scope boundary

This MVP intentionally does not include a native headset application, multiplayer networking, an LMS, offline WebR vendoring, or a general-purpose 3D grammar for every R plot. Those are future extensions, not release criteria for the first grant-sized milestone.

## License

MIT. Educational content and future lesson datasets should carry their own explicit open licenses.

## Development QA rule

Every feature change should include both code verification and a visual artifact: run the R smoke/package checks, open the relevant browser lesson, save a screenshot under `output/playwright/`, and inspect the screenshot before handoff.
