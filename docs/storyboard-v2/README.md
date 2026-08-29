# R-ClaimLab progressive-disclosure UX storyboard

This storyboard preserves the existing dataset, lesson, workflow, evidence, role, receipt, and handoff capabilities while reorganizing them around one primary decision per scene.

## Experience arc

| Scene | User question | Primary action | Complexity held back |
|---|---|---|---|
| 01 | What am I here to do? | Choose guided lesson, own data, or review | Dataset and workflow settings |
| 02 | Where is my data? | Choose Local, Hugging Face, or Kaggle | Profiling and analysis methods |
| 03 | Is this data ready? | Confirm source, license, unit, and missingness | Modeling controls |
| 04 | What do I want to learn? | Approve question, variable roles, and method | Workflow activities |
| 05 | Which professional lens fits? | Choose Analyst, Scientist, Reviewer, or Guided Learning | Full role-specific task list |
| 06 | What will run? | Review grouped workflow and approve execution | Full DAG details behind disclosure |
| 07 | What do I do now? | Complete one focused activity | Completed and future activities collapsed |
| 08 | Why does this result exist? | Trace and cite one evidence item | Unrelated provenance branches |
| 09 | What can I defensibly claim? | Revise and accept one evidence-backed claim | Additional rubrics and claims |
| 10 | What do I keep or pass on? | Open report, download receipt, or hand off | Secondary exports in a collapsed group |

## Interaction rules

1. Show one primary action per viewport.
2. Group authoring into four stable phases: Data, Question, Workflow, Evidence.
3. Collapse completed and future activities; expand only the current activity.
4. Keep Table, 2D, and 3D as modes of one evidence view, not separate dashboards.
5. Put explanations, criteria, provenance, and exports in contextual drawers or command bars.
6. Require explicit approval before import transformations or analysis execution.
7. Keep the same source-record and evidence selections across representations and roles.
8. Use calm completion states; reproducibility and handoff are the reward, not visual celebration.
9. Preserve keyboard, semantic-table, reduced-motion, 200% zoom, mobile, and offline paths.
10. Keep raw data, credentials, and telemetry out of compiled artifacts and receipts.

## Images

- `01-start-with-purpose.png`
- `02-choose-data-source.png`
- `03-review-data-profile.png`
- `04-approve-analysis-plan.png`
- `05-choose-role-lens.png`
- `06-review-workflow-path.png`
- `07-focused-analysis-workspace.png`
- `08-trace-evidence.png`
- `09-build-defensible-claim.png`
- `10-handoff-and-receipt.png`

Generated with the built-in image generation tool using the current R-ClaimLab desktop workspace as a visual reference. Each file is a single 16:9 scene rather than a multi-panel storyboard sheet.

## Implementation status

All ten scenes are implemented on the v2.1 workflow branch.

- Scenes 01–06 are the local `run_workflow_wizard()` authoring flow.
- Scene 07 is the compiled Focus workspace.
- Scenes 08–10 are the Trace evidence, Build claim, and Handoff modes.
- Purpose, source, and role cards use Font Awesome icons supplied through
  Shiny; icons are decorative and retain adjacent text labels.
- `scripts/browser_workflow_wizard_smoke_test.ps1` captures scenes 01–07 and
  the 390 px authoring route.
- `scripts/browser_role_workflow_smoke_test.ps1` captures scenes 08–10 and
  verifies Table, 2D, 3D, keyboard, tablet, mobile, and 200% text paths.
- `scripts/build_storyboard_comparisons.py` places each storyboard source and
  implemented browser state on one comparison board for visual QA.
