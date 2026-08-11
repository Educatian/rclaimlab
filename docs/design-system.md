# R-LearnXR design system

R-LearnXR uses a compact instructional-workspace pattern: progress on the left, evidence in the center, and learner reasoning on the right. The interface should feel like a research or analytics product rather than a promotional landing page.

## Foundations

The canonical tokens live in `inst/templates/scene.html`.

| Category | Tokens | Use |
|---|---|---|
| Surface | `--color-canvas`, `--color-surface`, `--color-surface-subtle`, `--color-surface-active` | Page, shell, panels, current state |
| Text | `--color-text`, `--color-text-muted` | Primary and secondary content |
| Action | `--color-primary`, `--color-primary-hover`, `--color-primary-soft` | Main action, hover, selected state |
| Feedback | `--color-success`, `--color-warning`, `--color-danger`, `--color-teal` | Completion, explanation, errors, observations |
| Structure | `--color-border`, `--color-border-strong` | Dividers and field boundaries |
| Spacing | `--space-1` through `--space-8` | 4 px base scale |
| Radius | `--radius-control`, `--radius-panel`, `--radius-shell` | 8 px controls, 12 px panels, 16 px shell |
| Elevation | `--shadow-panel`, `--shadow-shell` | Primary scene and app shell only |

Typography uses Inter when available and the operating system sans-serif stack otherwise. Body copy is 11–13 px because the UI is a dense learning workspace; the page title is 25–32 px. Labels use restrained uppercase and tracking only for navigation and instructional stages.

## Components

### Application shell

The three-column desktop shell contains a single top bar. At tablet widths, the learning rail becomes a horizontal progress strip. At mobile widths, sections stack without removing learning context.

### Learning path

Step rows have three states: pending, current, and done. The current step uses the primary-soft background; completed steps use the success color. Step buttons remain keyboard focusable and scroll their target into view.

### Interactive scene

The scene is the only elevated work panel. It contains concise instructions, the keyboard-enabled canvas, a point callout, and a compact legend. Controls below are a toolbar separated by a divider rather than another card.

### R code lab

The center work panel switches between the 3D result and an R code lab through rectangular tabs. The lab keeps the dark editor and light execution report inside one bounded workspace. A successful run shows four explicit checks, the WebR version, deterministic seed, artifact hash, and row count before the learner returns to the updated scene.

### Learning companion

The companion is one persistent task panel with internal sections. Prediction is highlighted as the current task; Observe, Explain, and Transfer use dividers. This avoids nested-card visual noise while preserving the learning sequence.

### Fields and actions

Fields have visible labels, an 8 px radius, a strong boundary, and inline status. Primary actions use solid blue; secondary actions use blue-soft with a border; completion uses success green. Full pills are reserved for status and selected-point tags.

### Accessible data alternative

Every 3D view exposes a semantic table with row headers and explicit Inspect actions. The table is an equivalent interaction path, not supplementary documentation.

## Interaction and feedback

- Pointer: drag to rotate, wheel to zoom, click a point.
- Keyboard: arrows rotate, plus/minus zoom, Home resets.
- Prediction is stored locally in the browser.
- Learner R code is executed by a pinned WebR runtime and must return a valid `scene` data frame.
- Successful R execution synchronizes the canvas, accessible table, observation text, and reproducibility record.
- Explanation feedback checks for an evidence-bearing axis or coordinate reference.
- Transfer appears only after explanation criteria are met; completion stays locked until a different comparison point is selected.

## Anti-patterns

- Multiple floating cards for one continuous form
- Pill-shaped primary buttons
- Shadows on every container
- Decorative gradients or glass surfaces
- Placeholder-only form labels
- Hiding the companion or progress path on mobile
- Static controls that imply functionality

## Figma-to-code workflow

1. Inspect node `1:13` and the relevant child node in the reference Figma file.
2. Capture the exact Figma state and viewport.
3. Map Figma values to the semantic tokens above.
4. Implement in the source template, not generated files.
5. Run the full learner flow and keyboard checks.
6. Capture desktop and mobile screenshots.
7. Record side-by-side findings and intentional deviations in `design-qa.md`.
