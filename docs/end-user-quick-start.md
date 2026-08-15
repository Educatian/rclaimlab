# R-LearnXR end-user quick start

R-LearnXR has three different entry paths. Choose the shortest path for the job.

## Path A: explore a lesson

Use the hosted or local `scene/index.html` page. RStudio, Git, and Quarto are not required for the learner-facing browser experience. The first **Run R** action downloads the pinned WebR runtime, so the browser needs network access on first use.

For the full v1 learner experience, open `examples/index.html`. It is the course home: filter the module library, open an executable lesson or curriculum blueprint, and mark local progress. Progress stays in this browser and can be reset at any time.

## Path B: install the package from GitHub

This path is for an R user who wants the package API but does not need to edit the repository.

```r
install.packages("remotes")
remotes::install_github(
  "Educatian/rlearnxr",
  ref = "v1.1.0",
  upgrade = "never"
)

library(rlearnxr)
packageVersion("rlearnxr")
```

The `ref` pins the public v1.1.0 release. The default `main` branch is aligned with this release; use the `ref` when you need an immutable installation.

## Path C: clone and author in RStudio

Posit supports cloning a remote repository through **File > New Project > Version Control > Git**. Enter:

```text
https://github.com/Educatian/rlearnxr.git
```

Then open the cloned project in RStudio and run the following in the Console:

```r
source("scripts/diagnose_environment.R")
install.packages(c("remotes", "renv"))
renv::restore(prompt = FALSE)
remotes::install_local(".", upgrade = "never")

library(rlearnxr)
packageVersion("rlearnxr")
rlearnxr::check_lesson("examples/lesson", strict = TRUE)
```

If the project is on a release tag, use the Git pane or the terminal to check out `v1.1.0` before installing locally. Do not edit the live `main` branch directly when preparing a contribution.

## First authoring loop

```powershell
Rscript scripts/build_all_lessons.R
Rscript scripts/check_all_lessons.R
quarto render examples/lesson
```

Open `examples/lesson/scene/index.html`, run the starter R code, inspect the 3D scene and semantic table, then export the R or Quarto source. A successful first run should show the WebR version, deterministic seed, returned row count, artifact hash, and four browser checks.

## Prerequisites

| Task | Required | Check |
|---|---|---|
| Package API | R >= 4.1 | `R.version.string` |
| Clone from GitHub | Git | `Sys.which("git")` |
| Install from GitHub/local source | `remotes` | `requireNamespace("remotes", quietly = TRUE)` |
| Restore the locked author environment | `renv` | `requireNamespace("renv", quietly = TRUE)` |
| Render Quarto lessons | Quarto CLI | `quarto check` |
| Penguin PCA example | `palmerpenguins` | `requireNamespace("palmerpenguins", quietly = TRUE)` |
| Browser R execution | Network on first run | open the lesson and select **Run R** |

Run `Rscript scripts/diagnose_environment.R` before troubleshooting. It reports missing tools without hiding the actual next action.

## Common recovery actions

- **`git` is not found:** install Git for Windows or use the hosted browser demo instead.
- **`quarto` is not found:** install Quarto, restart RStudio, and run `quarto check`.
- **The package version is old:** check `packageVersion("rlearnxr")`, then reinstall with `ref = "v1.1.0"`.
- **`renv::restore()` prompts or fails:** run it from the repository root and inspect the first unavailable package or mirror URL.
- **WebR does not start:** confirm browser network access to the pinned WebR URL; the static scene, table, and source exports remain available as fallbacks.
- **Windows path errors:** clone to a short user-owned path without cloud-sync or permission restrictions, such as `C:/Users/<you>/Documents/rlearnxr`.
- **Only the browser demo is needed:** skip RStudio and open the lesson scene directly.

To rehearse the network-failure path locally, run `powershell -ExecutionPolicy Bypass -File scripts/browser_offline_smoke_test.ps1 -StartServer`. The same check runs on a GitHub-hosted Windows runner, so local GUI manipulation is not required. See [External validation](external-validation.md) for the remote workflow and artifacts.

## Definition of a successful rehearsal

A clean user environment is ready when a user can clone or install the current public version, see the expected package version, restore dependencies, render one lesson, run real R in the browser, inspect the table fallback, and produce a strict PASS report without editing project internals.

The release process repeats this check on GitHub-hosted Windows, macOS, and Linux runners before claiming cross-platform onboarding success. Posit Cloud, screen-reader, and human pilot checks remain separate external gates.
