# R-LearnXR Reference Lesson

This lesson is the first end-to-end example for the MVP. It uses a six-point openly created toy dataset so that the artifact can be rendered and inspected without credentials or external services.

The toy data and lesson text are released under CC0 for reuse in demonstrations and contributor training.

See [educator-guide.md](educator-guide.md) for facilitation prompts and connect this warm-up to the [statistics module pathway](../../docs/curriculum/statistics-modules.md).

## Reproduce

1. Install R and Quarto.
2. From the repository root, run `Rscript scripts/build_demo.R` if the scene needs to be regenerated.
3. Run `quarto render examples/lesson`.
4. Run `Rscript scripts/check_lesson.R` or call `rlearnxr::check_lesson()` after installing the package.
