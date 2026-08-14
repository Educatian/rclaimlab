# R-LearnXR MVP

R-LearnXR is an open-source prototype for reproducible, browser-based R laboratories built with Quarto, WebR, and interactive 3D scenes. The MVP treats 3D/XR as an optional evidence layer. Learners edit and execute real R code in the browser, send the resulting data frame into the 3D view, explain coordinate evidence, and export the work as reproducible R or Quarto source.

## Grant demo

[![R-LearnXR English narrated demo verification frames](output/demo/video-verification-contact-sheet.png)](output/demo/rlearnxr-demo-en.mp4)

[Watch the 103-second direct-interaction, English narrated and captioned demo](output/demo/rlearnxr-demo-en.mp4) or download the [English captions](output/demo/rlearnxr-demo-en.srt). The narration is AI-generated with ElevenLabs using the voice `Alice — Clear, Engaging Educator`.

Grant preparation materials:

- [Application preparation checklist](grant/application-prep.md)
- [ISC proposal draft](grant/isc-proposal-draft.md)
- [Rendered working-draft PDF](output/pdf/rlearnxr-isc-proposal-working-draft.pdf)
- [Team and budget decisions](grant/team-budget-checklist.md)
- [Grant-readiness scorecard](GRANT_READINESS.md)
- [Community validation status](community/validation-status.md)
- [DataSandbox continuation bridge](docs/datasandbox-bridge.md)
- [Optional LLM visualization adapter](docs/llm-adapter.md)

## What works now

- `scaffold_lesson()` creates a small Quarto lesson project.
- `write_lesson_manifest()` and `write_learning_receipt()` preserve course/session provenance, attempt number, consent, and reproducibility metadata.
- `import_datasandbox_bundle()` and `export_lesson_bundle()` provide a portable handoff between DataSandbox activities and an R-LearnXR lesson folder or ZIP.
- `render_scene()` creates `scene/index.html` and `scene/points.json` from three numeric columns.
- A pinned WebR 0.6.0 runtime executes learner-edited R without an application server.
- The R lab shows the `scene` contract, explains the starter pipeline, reports transformation evidence, and gives beginner-friendly error recovery while retaining the technical R console.
- Successful R output updates the scene, accessible table, selected-point evidence, artifact hash, and reproducibility record.
- The complete learner loop supports prediction, real R execution, 3D exploration, evidence-based explanation, transfer, export, and completion.
- The optional AI Visual Brief tab turns a natural-language visualization request into reviewable R code and a WebR-backed 3D result; the core remains usable without an LLM provider.
- Pointer, keyboard, mobile, and accessible data-table paths expose the same analytical evidence.
- `check_lesson()` writes advisory or strict Markdown, JSON, session, and generated-artifact reports; strict mode is the release gate.
- `examples/lesson/` is the contributor-training lesson; `examples/penguin-pca/` is the authentic analysis lesson.
- `examples/mtcars-efficiency/` is a third, dependency-light reference lesson for multivariate vehicle-efficiency reasoning.
- `validate_scene_data()`, `validate_lesson_manifest()`, and `validate_learning_receipt()` expose the package contracts so authors and CI can fail early with actionable errors.
- Learners can download a local JSON learning receipt containing their evidence and reproducibility metadata; the optional AI adapter sends only the public scene schema and prompt.
- GitHub Actions checks the R package, rebuilds all three reference lessons, runs strict lesson checks, renders Quarto, and runs a real-browser keyboard/responsive smoke test.

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

# Import a local DataSandbox handoff, then release it as a lesson bundle
import_datasandbox_bundle("datasandbox-demo.rlearnxr.bundle.json", "imported-lesson")
check_lesson("imported-lesson", strict = TRUE)
export_lesson_bundle("imported-lesson", zip = TRUE)
```

Open `examples/lesson/scene/index.html` in a browser. The first R execution loads the pinned WebR runtime from its documented public URL; subsequent executions stay in the tab. The static scene, R source, JSON artifact, and semantic table remain the authoritative fallback when WebR is unavailable. In a Quarto-enabled environment, run `quarto render examples/lesson` to render the lesson page.

Build and check every lesson from the repository root:

```powershell
Rscript scripts/build_all_lessons.R
Rscript scripts/check_all_lessons.R
quarto render examples/lesson
quarto render examples/penguin-pca
```

Contributor onboarding starts in [CONTRIBUTING.md](CONTRIBUTING.md). The authoring, accessibility, pilot, and roadmap documents turn the MVP into reusable community infrastructure rather than a one-off demonstration.

## Scope boundary

This MVP intentionally does not include a native headset application, multiplayer networking, an LMS, offline WebR vendoring, LLM training, or a general-purpose 3D grammar for every R plot. AI Visual Brief is optional, reviewable, and not a grant deliverable. These are future extensions, not release criteria for the first grant-sized milestone.

## License

Software is MIT licensed. Original educational content and templates are CC BY 4.0; datasets retain the licenses documented in each lesson. See [CONTENT_LICENSE.md](CONTENT_LICENSE.md).

## Development QA rule

Every feature change should include both code verification and a visual artifact: run the R smoke/package checks, open the relevant browser lesson, save a screenshot under `output/playwright/`, and inspect the screenshot before handoff.
