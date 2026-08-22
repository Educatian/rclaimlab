# Migrating from v1.1.0 to v2

Version 2 is intentionally breaking. The `v1.1.0` tag preserves the original scene/manifest API.

1. Convert the source data or fitted model with `as_rclaimlab_evidence()`.
2. Define learning tasks with `task_spec()` in the canonical sequence.
3. Create a `lesson_spec()` with table, 2D, and 3D representation specifications.
4. Run `compile_lesson()` instead of treating `render_scene()` as the complete authoring pipeline.
5. Replace v1 manifests and receipts with schema version 2 artifacts.
6. Run `check_lesson(strict = TRUE)` and inspect the Evidence IR check.

There is no long-lived compatibility wrapper. Existing lessons are rebuilt once from their R source so that stable evidence IDs become authoritative.
