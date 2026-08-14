# R-LearnXR end-user rehearsal audit

Date: 2026-08-14  
Public commit: `41d6ac9`  
Public tag: [`v0.1.0-rc.3`](https://github.com/Educatian/rlearnxr/tree/v0.1.0-rc.3)

## Verdict

The Windows command-line equivalent of the RStudio onboarding flow is ready: a fresh GitHub clone and a fresh R library can install the package, load the exported API, render all three lessons, and pass strict checks. The browser smoke flow also passes on a collision-resistant default server port.

The RStudio Desktop GUI itself was not run because it is not installed in this environment. macOS, Posit Cloud, corporate proxy, and screen-reader runs remain external validation environments.

## Step-by-step evidence

| Step | User action | Result |
|---:|---|---|
| 1 | Run `scripts/diagnose_environment.R --strict` | PASS: R 4.6.1, Git, repository-local Quarto, remotes, renv, and palmerpenguins detected |
| 2 | Clone `https://github.com/Educatian/rlearnxr.git` from public `main` | PASS: public `main` resolves to `41d6ac9` |
| 3 | Build and install the cloned package into an empty library | PASS: package version `0.1.0` and all public validators load |
| 4 | Run `remotes::install_github("Educatian/rlearnxr")` without `ref` | PASS: default `main` now installs the current package |
| 5 | Run package smoke and testthat checks | PASS |
| 6 | Run strict checks for `lesson`, `penguin-pca`, and `mtcars-efficiency` | PASS for every check |
| 7 | Render all three Quarto lessons | PASS |
| 8 | Run the browser smoke flow | PASS: AI brief, mobile overflow, keyboard scene controls, and semantic table |

## Browser evidence

![Desktop browser smoke](../../playwright/rlearnxr-browser-smoke-desktop.png)

![Mobile browser smoke](../../playwright/rlearnxr-browser-smoke-mobile.png)

The screenshots show the updated R-LearnXR brand line, the R-powered laboratory, the optional AI brief, and the mobile layout. Screenshot evidence does not establish full WCAG conformance or learning effectiveness.

## Rehearsal commands

```r
install.packages("remotes")
remotes::install_github("Educatian/rlearnxr", upgrade = "never")
library(rlearnxr)
packageVersion("rlearnxr")
```

For authoring, clone the repository in RStudio with **File > New Project > Version Control > Git**, open `rlearnxr.Rproj`, run `renv::restore(prompt = FALSE)`, and then run `remotes::install_local(".")`. The complete path is documented in [`docs/end-user-quick-start.md`](../../../docs/end-user-quick-start.md).

## Remaining external gates

- RStudio Desktop GUI run on Windows with a human user
- macOS clean clone and install
- Posit Cloud or Workbench project clone and render
- Network-blocked WebR first-run recovery
- Corporate proxy and permission-denied recovery
- Independent screen-reader pass
- Novice learner and R educator pilot
