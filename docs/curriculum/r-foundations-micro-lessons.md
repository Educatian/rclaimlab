# R Foundations Micro-Lessons

These four 5-minute activities prepare a novice learner for the longer R-ClaimLab reference lessons. They teach statistical reasoning and R syntax together, but the learner makes a claim before seeing the code.

## R01 — What is one row?

**Concept:** observational unit, variable, data frame.  
**Goal:** identify what each row represents before calculating anything.

```r
str(penguins)
names(penguins)
head(penguins, 3)
```

**Prompt:** “If one row is one penguin, which columns describe the penguin and which column names a group?”

**Exit ticket:** write one sentence beginning, “In this table, one row represents …”

## R02 — Filter without hiding the question

**Concept:** conditioning, subgroup comparison, missingness.

```r
complete <- penguins[complete.cases(penguins), ]
adelie <- complete[complete$species == "Adelie", ]
mean(adelie$body_mass_g)
```

**Prompt:** “What changed when we filtered, and which population can this mean describe?”

**Misconception repair:** a subgroup mean is not automatically the mean of every penguin or every population.

## R03 — Center, spread, and standardize

**Concept:** center, variability, scale, comparability.

```r
mean(penguins$body_mass_g, na.rm = TRUE)
sd(penguins$body_mass_g, na.rm = TRUE)
z_mass <- as.numeric(scale(penguins$body_mass_g))
range(z_mass, na.rm = TRUE)
```

**Prompt:** “Why might kilograms and millimeters need a common scale before a multivariate comparison?”

**Transfer:** choose a second variable and predict whether its standardized values will have the same spread.

## R04 — Turn a result into evidence

**Concept:** data frame contract, coordinate interpretation, reproducibility.

```r
scene <- data.frame(
  label = c("A", "B", "C"),
  x = c(-0.8, 0.1, 0.7),
  y = c(0.4, -0.2, 0.6),
  z = c(-0.1, 0.8, 0.2)
)
set.seed(2026)
scene
```

**Sentence frame:** “Point ___ is ___ on the ___ axis (coordinate ___), so I infer ___; I cannot infer ___ from this coordinate alone.”

**Required receipt evidence:** prediction, selected point, coordinate claim, code, seed, runtime, and artifact hash.

## Instructor use

Use one micro-lesson as a warm-up before `examples/penguin-pca/`. Ask learners to keep their original prediction visible, then revisit it after the third coordinate is revealed. The purpose is conceptual transfer, not memorizing `prcomp()` syntax.
