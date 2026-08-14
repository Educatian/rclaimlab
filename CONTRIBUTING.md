# Contributing to R-LearnXR

R-LearnXR welcomes contributions from R educators, package developers, accessibility reviewers, and learners. Contributions may be code, lesson content, documentation, translations, datasets, usability findings, or reproducibility reports.

## Start here

1. Read `docs/authoring-guide.md` and `docs/accessibility.md`.
2. Read `docs/end-user-quick-start.md` and run `Rscript scripts/diagnose_environment.R`.
3. Run `Rscript scripts/smoke_test.R`.
4. Build all three reference lessons with `Rscript scripts/build_all_lessons.R`.
5. Run `Rscript scripts/check_all_lessons.R`.
6. Run `powershell -ExecutionPolicy Bypass -File scripts/browser_smoke_test.ps1 -StartServer` for the automated browser pass, then open each generated scene and test pointer, keyboard, mobile, and data-table paths.

## Pull request expectations

- Keep a contribution focused on one problem.
- Add or update a reproducible example.
- Include an openly licensed dataset or a script that creates the data.
- Add tests for changed R behavior.
- Add a browser screenshot under `output/playwright/` for visible changes.
- State the learner goal and accessibility fallback in the pull request.

## Lesson acceptance checklist

- The learning goal names an observable learner outcome.
- A learner can predict, explore, explain, receive feedback, and complete the lesson.
- The 3D view has a keyboard path and an accessible table alternative.
- The analysis is ordinary R code with a deterministic seed when randomness is used.
- `renv.lock`, Quarto configuration, source data, data license, and reproducibility report are present.
- No credentials, private data, or machine-specific paths are included.

## Community review

Use the issue templates for bugs, lesson proposals, and accessibility findings. Be specific, kind, and evidence-based. The project follows `CODE_OF_CONDUCT.md`.
