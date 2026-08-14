# Extension Activities — Penguin PCA

## A. Change the sample

Use all complete penguins instead of the deterministic 24-point sample. Compare the loading directions and ask whether the same PC3 interpretation remains stable.

## B. Change the scaling decision

Run `prcomp(..., center = TRUE, scale. = FALSE)` and compare the scores. Which variable now has more influence because of its units? What claim should be revised?

## C. Inspect loadings

```r
round(pca$rotation[, 1:3], 2)
```

Write one sentence for each component that names at least two contributing original variables.

## D. Compare visualization grammars

Create a 2D PC1/PC2 plot and compare it with the table and 3D scene. Identify one insight that is easier in 2D and one relationship that PC3 reveals.

## E. Design a new lesson

Replace penguin measurements with an openly licensed dataset. Keep the same module contract: question, prediction, R transformation, accessible evidence, explanation, transfer, ethics, and reproducibility.
