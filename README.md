# R-ClaimLab — From R Code to Evidence

**A reproducible R framework for interactive data learning.**

R-ClaimLab is an R Evidence Compiler for reproducible data-science education. It converts existing R analysis objects into linked evidence that can be rendered as a semantic table, 2D plot, optional 3D scene, Quarto lesson, and learning receipt. Every representation uses the same observation, dimension, and evidence identifiers.

```text
R analysis object -> Evidence Adapter -> Evidence IR -> Lesson Compiler
                  -> table / 2D / 3D / Quarto -> learning receipt

Public tabular data now follows an additional role-adaptive route:

```text
Local / Hugging Face / Kaggle source -> inspect and approve
-> Data Analyst -> Data Scientist -> Model Reviewer
-> evidence bundle + role report + workflow receipt
```
```

## Grant demo

[![R-ClaimLab direct-interaction demo verification frames](https://raw.githubusercontent.com/Educatian/rclaimlab/main/output/demo/video-verification-contact-sheet.png)](https://github.com/Educatian/rclaimlab/blob/main/output/demo/rclaimlab-demo-higgsfield-en.mp4)

[Watch the 103-second narrated direct-interaction demo](https://github.com/Educatian/rclaimlab/blob/main/output/demo/rclaimlab-demo-higgsfield-en.mp4), open the [caption-only review version](https://github.com/Educatian/rclaimlab/blob/main/output/demo/rclaimlab-demo-captioned-preview.mp4), or download the [English captions](https://github.com/Educatian/rclaimlab/blob/main/output/demo/rclaimlab-demo-en.srt). The English narration was generated through Higgsfield with the `Ainsley` voice and Seed Speech engine; [generation provenance](https://github.com/Educatian/rclaimlab/blob/main/output/demo/rclaimlab-higgsfield-generation.json) records the model, timing, and artifact hashes.

Grant preparation materials:

- [Application preparation checklist](grant/application-prep.md)
- [ISC proposal draft](grant/isc-proposal-draft.md)
- [Rendered working-draft PDF](output/pdf/rclaimlab-isc-proposal-working-draft.pdf)
- [Team and budget decisions](grant/team-budget-checklist.md)
- [Grant-readiness scorecard](GRANT_READINESS.md)
- [Community validation status](community/validation-status.md)
- [DataSandbox continuation bridge](docs/datasandbox-bridge.md)
- [Optional LLM visualization adapter](docs/llm-adapter.md)
- [Learner experience storyboard](docs/storyboards/learner-experience-v1.md)

## What works now

- `as_rclaimlab_evidence()` supports numeric summaries, frequency tables,
  correlation, bootstrap means, t tests, ANOVA, chi-square, `data.frame`,
  `prcomp`, `lm`, `glm`, and `kmeans` evidence without reimplementing the
  underlying statistical methods.
- `rclaimlab_concept_registry()` reports which curriculum capabilities are
  tested and which remain planned.
- `prepare_learning_events()` converts repeated event rows into auditable
  learner-level features before modeling.
- `lesson_spec()`, `task_spec()`, and `representation_spec()` define the public authoring contract.
- `compile_lesson()` creates Evidence IR, Quarto source, a synchronized semantic
  table, true 2D plot and 3D scene, a v2 manifest, and reproducibility checks.
- `profile_learning_data()` and `lesson_from_data()` turn a learner- or educator-supplied data frame into a question-first lesson plan without hiding the unit of analysis, outcome, grouping/time structure, method, variables, missing-value rule, diagnostics, cautions, or provenance.
- `run_lesson_wizard()` provides a local CSV workflow for approving an analysis and compiling the full Orient, Predict, Run R, Explore, Explain, Repair, Transfer, and Reproduce sequence.
- `dataset_source()`, `inspect_dataset()`, `preview_dataset()`, and
  `import_dataset()` provide bounded local, Hugging Face, and Kaggle tabular
  ingestion without storing credentials in package objects or artifacts.
- `workflow_from_dataset()`, `approve_workflow()`, `run_workflow()`, and
  `continue_workflow()` preserve the guided lesson as one profile while adding
  Data Analyst, Data Scientist, and Model Reviewer handoffs over one traceable
  evidence bundle.
- `compile_workflow()` creates a portable role workspace with source manifest,
  profile, workflow specification, evidence registry, R script, Quarto report,
  table/2D/3D browser interface, and strict checks.

- `scaffold_lesson()` creates a small Quarto lesson project.
- `write_lesson_manifest()` and `write_learning_receipt()` preserve course/session provenance, attempt number, consent, and reproducibility metadata.
- `import_datasandbox_bundle()` and `export_lesson_bundle()` provide a portable handoff between DataSandbox activities and an R-ClaimLab lesson folder or ZIP.
- `render_scene()` creates `scene/index.html`, `scene/points.json`, and `scene/evidence.json` from three numeric columns.
- A pinned WebR 0.6.0 runtime executes learner-edited R without an application server.
- The R lab shows the `scene` contract, explains the starter pipeline, reports transformation evidence, and gives beginner-friendly error recovery while retaining the technical R console.
- Successful R output updates the scene, accessible table, selected-point evidence, artifact hash, and reproducibility record.
- The complete learner loop supports prediction, real R execution, synchronized table/2D/3D exploration, evidence-based explanation, transfer, export, and completion.
- The optional AI Visual Brief tab turns a natural-language visualization request into reviewable R code and a WebR-backed 3D result; the core remains usable without an LLM provider.
- Pointer, keyboard, mobile, and accessible data-table paths expose the same analytical evidence.
- `check_lesson()` writes advisory or strict Markdown, JSON, session, and generated-artifact reports; strict mode is the release gate.
- `examples/lesson/` is the contributor-training lesson; `examples/penguin-pca/` is the authentic analysis lesson.
- `examples/mtcars-efficiency/` is a third, dependency-light reference lesson for multivariate vehicle-efficiency reasoning.
- `examples/statistics-distribution/`, `examples/statistics-association/`,
  `examples/statistics-bootstrap/`, `examples/statistics-groups/`, and
  `examples/statistics-categories/` make the foundational adapters directly
  teachable through the same eight-stage learner loop.
- `examples/learning-analytics/` and `examples/edm-patterns/` are executable synthetic-data application lessons for the Learning Analytics and Educational Data Mining tracks.
- `examples/index.html` is the learner-facing course home generated by `render_course_catalog()`. It provides module filtering, executable lesson links, blueprint links, and browser-local progress without an account.
- `docs/curriculum/statistics-modules.md` maps the introductory statistics pathway to Learning Analytics and Educational Data Mining application modules, with executable reference lessons for both application tracks.
- `docs/curriculum/r-foundations-micro-lessons.md` provides short beginner R activities; `examples/penguin-pca/` includes a full educator pack, answer key, rubric, accessible alternative, and extensions.
- `docs/research/learning-analytics-edm-data-science-education.md` records the literature-to-design translation and primary references.
- `validate_scene_data()`, `validate_lesson_manifest()`, and `validate_learning_receipt()` expose the package contracts so authors and CI can fail early with actionable errors.
- `run_rclaimlab_shiny()` provides an optional local educator console; Shiny is not required for learners or static deployment.
- Learners can download a local JSON learning receipt containing their evidence and reproducibility metadata; the optional AI adapter sends only the public scene schema and prompt.
- GitHub Actions validates the package and all ten reference lessons on Linux, Windows, and macOS, rehearses a clean public-main install, and runs real-browser interaction plus offline WebR fallback smoke tests.

## Choose your path

- **New to the app:** follow the screenshot-led [Beginner guide](docs/beginner-guide.html). It explains what to type, what each command creates, what the output means, and where to go next.
- **Explore the course:** open [`examples/index.html`](examples/index.html) and choose a module; RStudio is not required for learners.
- **Explore a lesson directly:** open the browser scene when you already know the lesson path.
- **Use the package:** install the public release candidate with `remotes::install_github()`.
- **Author a lesson:** clone the repository as an RStudio Project, restore `renv`, and install the local package.
- **Contribute:** use the repository project, run diagnosis and strict checks, then open a focused pull request.

Start with the screenshot-led [Beginner guide](docs/beginner-guide.html), then keep the compact [End-user quick start](docs/end-user-quick-start.md) as a command reference. Run `Rscript scripts/diagnose_environment.R` when a tool or dependency is unclear. The no-local-GUI validation plan is in [External validation](docs/external-validation.md), and the latest clean-install and browser evidence is recorded in the [end-user rehearsal audit](output/audit/end-user-rehearsal/end-user-rehearsal.md).

The optional Shiny educator console is documented in [Optional Shiny educator shell](docs/shiny-educator-shell.md). It is a local authoring and release-review surface over the same R package contracts, not a replacement for the portable Quarto/WebR learner experience.

## Visual preview

![R-ClaimLab browser-based 3D demo](https://raw.githubusercontent.com/Educatian/rclaimlab/main/output/playwright/rclaimlab-3d-demo.png)

## Figma UI reference

The Explore lesson interface was refined in [Figma](https://www.figma.com/design/jZ0W2ieUoSRwZtrMUKru8g) before being translated back into the browser demo. The image below is the current tested implementation, not a static design promise.

![R-ClaimLab Explore lesson UI](https://raw.githubusercontent.com/Educatian/rclaimlab/main/output/figma/rclaimlab-explore-screen.png)

## Run the v2 development branch

### Install v1.1.0 or the v2 branch

```r
install.packages("remotes")
remotes::install_github(
  "Educatian/rclaimlab",
  ref = "v1.1.0",
  upgrade = "never"
)
library(rclaimlab)
packageVersion("rclaimlab")
```

The stable public release remains `v1.1.0` until every v2 release gate passes. To evaluate the Evidence Compiler branch, install `ref = "codex/v2-evidence-compiler"` after that branch is published.

```r
library(rclaimlab)

fit <- prcomp(iris[, 1:4], scale. = TRUE)
evidence <- as_rclaimlab_evidence(fit)

stages <- c("orient", "predict", "run_r", "explore", "explain", "repair", "transfer", "reproduce")
tasks <- lapply(stages, function(stage) {
  task_spec(paste0("pca-", stage), stage, paste("Complete the", stage, "stage"))
})

lesson <- lesson_spec(
  "iris-pca", "Iris PCA evidence",
  outcomes = c("Interpret a PCA score", "Explain linked evidence", "Transfer the interpretation"),
  evidence = evidence,
  tasks = tasks
)
compile_lesson(lesson, "iris-pca-lesson")
```

To create a lesson from a local CSV with guided decisions, run:

```r
library(rclaimlab)
run_lesson_wizard()

# The same workflow is available without Shiny.
learner_data <- read.csv("my-data.csv")
profile_learning_data(learner_data, intent = "reduce")
lesson <- lesson_from_data(
  learner_data,
  analysis = "auto",
  question = "Which measured variables vary together, and which observations contrast?",
  intent = "reduce",
  unit_of_analysis = "one de-identified observation"
)
compile_lesson(lesson, "my-data-lesson")
```

To turn a pinned public dataset into a cross-role workflow, run:

```r
source <- dataset_source(
  "huggingface",
  "scikit-learn/adult-census-income",
  revision = "fbeef6ec0e6fd88a5028b94683144000a6b380d5",
  split = "train",
  file = "adult.csv"
)

manifest <- inspect_dataset(source)
preview_dataset(source, rows = 10)
dataset <- import_dataset(source, max_rows = 10000, seed = 2026)

workflow <- workflow_from_dataset(
  dataset,
  role = "data_scientist",
  goal = "predict",
  outcome = "income",
  predictors = c("age", "education.num", "hours.per.week"),
  slice_by = "sex",
  analysis = "glm",
  missing_values = c("?", " ?"),
  seed = 2026
)

workflow <- approve_workflow(workflow, publication = TRUE)
run <- run_workflow(workflow)
build <- compile_workflow(run, "adult-income-workflow", publish = TRUE)
check_workflow(build$output_dir, strict = TRUE, publish = TRUE)
```

The example is an educational audit case, not a fairness certification or a
system for individual decisions. See the [external data and role workflow
guide](docs/external-data-workflows.md) for the analyst-to-reviewer handoff,
Kaggle prerequisites, cache behavior, exact limits, and error recovery.

The wizard makes deterministic recommendations, not autonomous statistical claims. It starts with the analytical question and intended learning goal. The author still approves the unit of analysis, outcome, grouping/time structure, dimensions, missing-value rule, learning stages, and adapter before compilation. Declared grouping or repeated time prevents the simple `lm` and `glm` adapters from being automatically recommended.

The course home also includes a browser-local educator view: import learner-initiated R-ClaimLab receipt JSON files to inspect lesson-level completion and reproducibility counts without uploading raw learner responses.

### Clone for RStudio authoring

Use **File > New Project > Version Control > Git** and enter `https://github.com/Educatian/rclaimlab.git`. Open the resulting `rclaimlab.Rproj`, then run:

```r
source("scripts/diagnose_environment.R")
install.packages(c("remotes", "renv"))
renv::restore(prompt = FALSE)
remotes::install_local(".", upgrade = "never")
```

From this directory, run:

```r
source("R/utils.R")
source("R/zzz.R")
source("R/render_scene.R")
source("R/scaffold_lesson.R")
source("R/check_lesson.R")
check_lesson("examples/lesson")

# Import a local DataSandbox handoff, then release it as a lesson bundle
import_datasandbox_bundle("datasandbox-demo.rclaimlab.bundle.json", "imported-lesson")
check_lesson("imported-lesson", strict = TRUE)
export_lesson_bundle("imported-lesson", zip = TRUE)
```

Open `examples/lesson/scene/index.html` in a browser. The first R execution loads the pinned WebR runtime from its documented public URL; subsequent executions stay in the tab. The static scene, R source, JSON artifact, and semantic table remain the authoritative fallback when WebR is unavailable. In a Quarto-enabled environment, run `quarto render examples/lesson` to render the lesson page.

Build and check every lesson from the repository root:

```powershell
Rscript scripts/build_all_lessons.R
Rscript scripts/check_all_lessons.R
Rscript scripts/render_all_lessons.R
```

Contributor onboarding starts in [CONTRIBUTING.md](CONTRIBUTING.md). The authoring, accessibility, pilot, release, and roadmap documents make the v1 scope reusable community infrastructure rather than a one-off demonstration.

## v2 scope boundary

The v2 release candidate intentionally does not include a native headset application, multiplayer networking, an LMS, offline WebR vendoring, LLM training, grouped/longitudinal model adapters, or a general-purpose 3D grammar for every R plot. AI Visual Brief is optional, reviewable, and not a grant deliverable. The implemented scope is a static course shell, ten v2 contract reference lessons, a statistics-to-learning-analytics/EDM curriculum map, reusable authoring contracts, and CI evidence. Human learner pilots, physical screen-reader passes, authenticated Posit Cloud rehearsal, external contributions, CRAN, DOI, and JOSS remain external release or research gates until linked evidence exists.

## License

Software is MIT licensed. Original educational content and templates are CC BY 4.0; datasets retain the licenses documented in each lesson. See [CONTENT_LICENSE.md](CONTENT_LICENSE.md).

## Development QA rule

Every feature change should include both code verification and a visual artifact: run the R smoke/package checks, open the relevant browser lesson, save a screenshot under `output/playwright/`, and inspect the screenshot before handoff.
