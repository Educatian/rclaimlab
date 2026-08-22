# Optional Shiny educator shell

R-ClaimLab is not a Shiny-only application. The core release is a portable R package with Quarto lesson templates, browser-based WebR execution, a semantic table fallback, and reproducibility checks. This keeps learner access compatible with static hosting and does not require an application server.

The optional `run_rclaimlab_shiny()` entry point is an educator and authoring console. It provides:

- reference-module selection across Statistics, Learning Analytics, and Educational Data Mining;
- course-catalog contract validation;
- a link to the selected lesson;
- a strict `check_lesson()` report for local release rehearsal; and
- a visible explanation of the R → Quarto → WebR architecture boundary.

Install the optional dependency and start the console from an RStudio project:

```r
install.packages("shiny")
remotes::install_local(".", upgrade = "never")

library(rclaimlab)
run_rclaimlab_shiny(lesson_dir = ".")
```

The console does not upload learner data, create accounts, or replace the static lesson. It is intentionally local and uses the same exported package contracts as the command-line and CI workflows. If the repository is hosted as a static site, learners continue to open `examples/index.html` and the lesson `scene/index.html` without Shiny.

For a clean release rehearsal:

```r
run_rclaimlab_shiny(
  lesson_dir = ".",
  launch.browser = TRUE
)
```

Select a module, run **Validate course catalog**, then run **Run strict lesson check**. A strict PASS is necessary evidence for release, but it does not replace a human learner pilot, screen-reader pass, or Posit Cloud check.
