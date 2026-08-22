# Authoring an R-ClaimLab Lesson

## 1. Define the learning decision

Write the analytical question, unit of analysis, intended learning goal, and one outcome a learner can demonstrate. Declare the outcome, grouping/nesting, and time/sequence variables before choosing a method. Three-dimensional presentation should support that decision rather than decorate an ordinary chart.

For a statistics concept, start from the pathway in [`docs/curriculum/statistics-modules.md`](curriculum/statistics-modules.md). Choose the concept, the learner decision, the evidence boundary, and the transfer task before choosing a chart or 3D scene.

## 2. Profile data and approve the method

```r
profile <- rclaimlab::profile_learning_data(
  learner_data,
  outcome = "transfer_score",
  intent = "explain",
  grouping = "learner_id",
  time = "session"
)
rclaimlab::recommend_lesson_analysis(profile)
```

Availability is not the same as appropriateness. Declaring grouping or repeated time prevents the core `lm` and `glm` adapters from being automatically recommended because those adapters do not model dependence.

## 3. Compile the lesson contract

```r
lesson <- rclaimlab::lesson_from_data(
  learner_data,
  analysis = "auto",
  dimensions = c("revision_count", "transfer_score", "hint_rate"),
  id_column = "event_id",
  grouping = "learner_id",
  time = "session",
  question = "How do revision activity, transfer performance, and hint use vary across repeated sessions?",
  intent = "explore",
  unit_of_analysis = "one de-identified learner-session summary",
  decision_context = "choosing reversible instructional support"
)
rclaimlab::compile_lesson(lesson, "my-lesson")
```

This is the preferred v2 path. It compiles Evidence IR, the semantic table, method diagnostics, exact task prompts and criteria, Quarto source, browser scene, and receipt contract from one R object.

## 4. Scaffold a fully custom project

```r
rclaimlab::scaffold_lesson("my-lesson", title = "My R-ClaimLab Lesson")
```

Keep raw or generated source data in `data/`, lesson prose in `index.qmd`, and generated browser artifacts in `scene/`.

## 5. Use the lower-level scene renderer when needed

```r
rclaimlab::render_scene(
  data = lesson_data,
  x = "x",
  y = "y",
  z = "z",
  labels = lesson_data$label,
  output_dir = "scene",
  overwrite = TRUE
)
```

Before rendering, authors can validate and normalize the scene contract directly:

```r
scene <- rclaimlab::validate_scene_data(
  lesson_data, x = "measure_1", y = "measure_2", z = "measure_3",
  labels = lesson_data$observation_id
)
```

The returned object always has unique `label`, numeric `x`, `y`, and `z` columns. This makes the contract explicit before browser artifacts are generated.

`render_scene()` is a lower-level renderer, not the complete v2 authoring pipeline. Scale coordinates to a comparable range and keep the original analytical values in the lesson narrative when scaling changes their meaning.

## 6. Review the learning loop

Every reference lesson should include:

1. Orient: state the goal and relevant context.
2. Predict: ask for a falsifiable expectation.
3. Run R: provide a small editable pipeline that returns `scene` with `label`, `x`, `y`, and `z` columns.
4. Explore: let the learner inspect the R result through pointer, keyboard, or table controls.
5. Explain: require a claim linked to coordinate evidence.
6. Repair: revise a claim after a missing criterion or assumption is identified.
7. Transfer: apply the same reasoning to a different observation.
8. Reproduce: verify source, seed, versions, retained rows, and hashes before exporting `.R`, `.qmd`, or receipt artifacts.

The generated browser lab pins WebR 0.6.0 and validates the returned data frame before changing the visual scene. Keep starter code short, use a deterministic seed, and ensure at least three finite observations remain after learner filtering.

Use [`docs/curriculum/module-authoring-template.md`](curriculum/module-authoring-template.md) to add objectives, vocabulary, misconceptions, educator prompts, assessment, accessibility, ethics, and extension activities. A rendered scene without these learning materials is not a complete educational module.

### R teaching and provenance checklist

- Show the `scene` contract near the editor: `label` identifies a point and `x`, `y`, and `z` are numeric coordinates.
- Explain every generated analysis command, including selected columns, retained rows, labels, model fit, and Evidence Adapter conversion.
- Make the analytical change visible by reporting the returned row count, filter rule, and any scaling step.
- Keep the technical R error available, but provide a plain-language fix first for beginners.
- Record the WebR version, R runtime, seed, returned row count, and artifact hash in the lesson evidence.
- Let learners download the browser-generated learning receipt after a run; it contains task IDs, criterion results, prediction, explanation, selected evidence IDs, code, browser hash, and compiled evidence hash but does not transmit private data to the optional AI adapter.
- Include the package reuse path so an educator can connect `scaffold_lesson()`, `render_scene()`, and `check_lesson()` to their own workflow.

## 7. Check and render

```r
rclaimlab::check_lesson("my-lesson", strict = TRUE)
```

Then restore the project environment and render with Quarto. Inspect the generated report and browser screenshot before publishing.

## 8. Prepare a contribution

Document the dataset license, learner audience, estimated time, known accessibility limits, and a short instructor note. Follow `CONTRIBUTING.md`.
