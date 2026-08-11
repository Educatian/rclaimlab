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
  output_dir = "scene"
)
```

Scale coordinates to a comparable range and keep the original analytical values in the lesson narrative when scaling changes their meaning.

## 4. Design the learning loop

Every reference lesson should include:

1. Orient: state the goal and relevant context.
2. Predict: ask for a falsifiable expectation.
3. Explore: let the learner inspect points through pointer, keyboard, or table controls.
4. Explain: require a claim linked to coordinate evidence.
5. Transfer: ask the learner to apply the same reasoning to another point or dataset.

## 5. Check and render

```r
rlearnxr::check_lesson("my-lesson")
```

Then restore the project environment and render with Quarto. Inspect the generated report and browser screenshot before publishing.

## 6. Prepare a contribution

Document the dataset license, learner audience, estimated time, known accessibility limits, and a short instructor note. Follow `CONTRIBUTING.md`.
