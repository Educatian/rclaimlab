# R-ClaimLab storyboard implementation QA

final result: passed

## Scope

- Visual source: `docs/storyboard-v2/01-start-with-purpose.png` through
  `docs/storyboard-v2/10-handoff-and-receipt.png`.
- Implemented authoring states: `output/playwright/rclaimlab-storyboard-01-purpose.png`
  through `output/playwright/rclaimlab-storyboard-07-ready.png`.
- Implemented workspace states: `output/playwright/rclaimlab-role-workflow-desktop.png`
  and `output/playwright/rclaimlab-storyboard-08-trace.png` through
  `output/playwright/rclaimlab-storyboard-10-handoff.png`.
- Same-input comparison boards: `output/playwright/design-qa/scene-01-comparison.jpg`
  through `scene-10-comparison.jpg`.

## Browser states and viewports

| Surface | Viewport or state | Result |
|---|---|---|
| Workflow Wizard | 1440 x 920, scenes 01-07 | Passed |
| Workflow Wizard | 390 x 844 | Passed, no horizontal overflow |
| Compiled workspace | 1440 x 920, Focus/Trace/Claim/Handoff | Passed |
| Compiled workspace | 760 x 900 | Passed |
| Compiled workspace | 390 x 844 | Passed, no clipping |
| Compiled workspace | 200% root text at 760 x 900 | Passed |
| Evidence views | Table, 2D, 3D | Passed with linked selection |
| Keyboard path | Evidence row focus and Enter selection | Passed |
| Browser console | Error-level messages after main flow | None observed |

## Iteration log

### Iteration 1

- P1: the 100-row data preview created a 4,000 px page and obscured the decision
  hierarchy. Fixed by showing eight representative rows and retaining the full
  100-row preview only in R state.
- P1: Shiny's generated action-link wrapper collapsed phase labels into the
  circular number slot. Fixed with explicit action-button anchors and a custom
  active-phase message.
- P1: the initial upload control and role cards were materially simpler than the
  storyboard. Fixed with the large dashed upload target, 2 x 2 role cards,
  contextual descriptions, and a right-side approval panel.
- P2: non-ASCII separators rendered as `<U+00B7>` under a C locale. Replaced
  authoring-shell separators with ASCII-safe labels.

### Iteration 2

- P1: the right-side source guidance panel overlapped the Kaggle source card.
  Fixed by reserving a 280 px desktop guidance column.
- P2: purpose, source, role, path, and completion cards lacked the storyboard's
  visual anchors. Added real Font Awesome icons through Shiny, marked decorative
  and retained adjacent text labels.
- P2: the compiled success screen exposed an unnecessary absolute local path.
  Fixed by displaying only the workflow directory name while preserving the
  local link target.

### Final comparison

- P0: none.
- P1: none.
- P2: none.
- Intentional P3 differences: exact icon glyphs, dataset values, and wording
  differ where the implementation uses live workflow contracts rather than the
  illustrative storyboard data. Information hierarchy, layout regions, primary
  actions, and state transitions match the storyboard intent.

## Functional evidence

- `scripts/browser_workflow_wizard_smoke_test.ps1` completes upload, inspect,
  profile, question, role, approval, compile, ready, and mobile paths.
- `scripts/browser_role_workflow_smoke_test.ps1` completes Focus, Trace, Claim,
  Handoff, Table, 2D, 3D, keyboard, responsive, and 200% text paths.
- All package unit and contract tests pass after the redesign.
