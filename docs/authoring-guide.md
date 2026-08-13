# Authoring an R-LearnXR Lesson

## 1. Define the learning decision

Write one outcome a learner can demonstrate, such as: “Use x, y, and z evidence to explain why two observations differ.” Three-dimensional presentation should support that decision rather than decorate an ordinary chart.

## 2. Scaffold the project

```r
rlearnxr::scaffold_lesson("my-lesson", title = "My R-LearnXR Lesson")
```

Keep raw or generated source data in `data/`, lesson prose in `index.qmd`, and generated browser artifacts in `scene/`.

## 3. Generate the scene

```r
rlearnxr::render_scene(
  data = lesson_data,
  x = "x",
  y = "y",
  z = "z",
  labels = lesson_data$label,
  output_dir = "scene",
  overwrite = TRUE
)
```

Scale coordinates to a comparable range and keep the original analytical values in the lesson narrative when scaling changes their meaning.

## 4. Design the learning loop

Every reference lesson should include:

1. Orient: state the goal and relevant context.
2. Predict: ask for a falsifiable expectation.
3. Run R: provide a small editable pipeline that returns `scene` with `label`, `x`, `y`, and `z` columns.
4. Explore: let the learner inspect the R result through pointer, keyboard, or table controls.
5. Explain: require a claim linked to coordinate evidence.
6. Reproduce: select a comparison point and export the work as `.R` or `.qmd` source.

The generated browser lab pins WebR 0.6.0 and validates the returned data frame before changing the visual scene. Keep starter code short, use a deterministic seed, and ensure at least three finite observations remain after learner filtering.

### R teaching and provenance checklist

- Show the `scene` contract near the editor: `label` identifies a point and `x`, `y`, and `z` are numeric coordinates.
- Explain the pipeline in three learner-sized moves: create data, transform or scale coordinates, and filter observations.
- Make the analytical change visible by reporting the returned row count, filter rule, and any scaling step.
- Keep the technical R error available, but provide a plain-language fix first for beginners.
- Record the WebR version, R runtime, seed, returned row count, and artifact hash in the lesson evidence.
- Include the package reuse path so an educator can connect `scaffold_lesson()`, `render_scene()`, and `check_lesson()` to their own workflow.

## 5. Check and render

```r
rlearnxr::check_lesson("my-lesson", strict = TRUE)
```

Then restore the project environment and render with Quarto. Inspect the generated report and browser screenshot before publishing.

## 6. Prepare a contribution

Document the dataset license, learner audience, estimated time, known accessibility limits, and a short instructor note. Follow `CONTRIBUTING.md`.
