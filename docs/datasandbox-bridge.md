# DataSandbox bridge test copy

R-LearnXR is the reproducible R/Quarto lesson layer for a DataSandbox learning artifact. The bridge is developed and tested in a separate copy of DataSandbox at `datasandbox-rlearnxr-test`; the live intervention repository remains unchanged.

## Flow

```text
DataSandbox activity
  -> explicit local export
  -> lesson-manifest.json + source CSV + chart spec + learning receipt
  -> R-LearnXR author maps fields and adds render_scene()
  -> strict reproducibility check
  -> Quarto lesson and accessible browser scene
```

## DataSandbox export

In the separate test copy's Dashboard, choose **Export R-LearnXR lesson**. The browser downloads a `.rlearnxr.bundle.json` file containing:

- `lesson-manifest.json` with course/session/block/activity provenance;
- `data/source.csv` with the learner-selected dataset;
- `source/chart-spec.json` with the original DataSandbox chart;
- `source/datasandbox-project.json` with the local project artifact;
- `checks/learning-receipt.json` with attempt and consent metadata;
- a starter `index.qmd`, `README.md`, and `DATA_LICENSE.md`.

The bundle is local-first and starts with `consent: local-only`. Export is an authoring handoff, not research data collection. A human must review licensing, personally identifying content, and the scene field mapping before publication. This adapter is currently a package-development fixture, not a change to the live intervention.

## R-LearnXR import and release

```r
rlearnxr::import_datasandbox_bundle(
  "datasandbox-course-completions.rlearnxr.bundle.json",
  output = "course-completions-lesson"
)

rlearnxr::write_learning_receipt(
  "course-completions-lesson",
  attempt_number = 2,
  prediction = "The high-volume group may not be the most satisfying.",
  explanation = "The chart shows volume and satisfaction moving in different directions.",
  outcome = "complete"
)

rlearnxr::check_lesson("course-completions-lesson", strict = TRUE)
rlearnxr::export_lesson_bundle("course-completions-lesson", zip = TRUE)
```

The importer intentionally does not guess the 3D mapping. If the source data is not already scene-ready, the manifest records `scene_ready: false` and the author must select or derive `label`, `x`, `y`, and `z`. This keeps the R step visible and teachable.

## Privacy boundary

- DataSandbox keeps learner records in browser storage by default.
- The bridge is activated by an explicit export action.
- Research use remains separately consented.
- R-LearnXR has no required server, LMS identity, or D1 dependency.
