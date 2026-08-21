# RFC 0001: Evidence Compiler

Status: implemented on `codex/v2-evidence-compiler`, pending second-maintainer review.

## Problem

Version 1 can render R data in a browser, but code, marks, explanations, transfer work, and reproducibility records do not share a formal analytical identity. A visual update could therefore drift from its source evidence without a contract failure.

## Decision

R owns statistical computation. Analysis adapters emit `rlearnxr-evidence-2` with stable observation, dimension, and evidence IDs. Lesson and renderer artifacts consume those IDs. Learner receipts cite the same IDs and artifact hash.

## Public API

`lesson_spec()`, `task_spec()`, `representation_spec()`, `as_rlearnxr_evidence()`, `compile_lesson()`, `check_lesson()`, and receipt read/write/validate functions form the v2 contract.

## Consequences

- v2 is breaking and has no long deprecation bridge.
- `v1.1.0` remains the frozen previous API.
- Browser code becomes a renderer and interaction recorder, not a statistics engine.
- Schema changes require two maintainers and migrated fixtures.

## Acceptance evidence

- Five official adapters pass the same contract tests.
- PCA provides the canonical analysis-to-receipt vertical slice.
- Five reference lessons clean-build with Evidence IR.
- Table and 3D marks expose identical evidence IDs.
- Static fallback remains functional if WebR or 3D rendering fails.
