# Penguin PCA Reference Lesson

This is the authentic-domain reference lesson for R-ClaimLab. It uses openly licensed Palmer Penguins measurements and principal component analysis to demonstrate when a third coordinate can change an interpretation.

## Reproduce

1. Restore dependencies from the repository `renv.lock`.
2. Run `Rscript scripts/build_penguin_pca_lesson.R` from the repository root.
3. Render with `quarto render examples/penguin-pca`.
4. Run `Rscript scripts/check_all_lessons.R`.

## Intended learners

Introductory data-science learners who have seen standardized variables and need practice interpreting PCA scores as evidence rather than treating the plot as decoration.

The flagship lesson includes an [educator guide](educator-guide.md), [answer key](answer-key.md), [assessment rubric](assessment-rubric.md), [accessible alternative](accessible-alternative.md), and [extension activities](extension-activities.md).
