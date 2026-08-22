# R-ClaimLab in-browser UI audit

Date: 2026-08-11

Overall verdict: **Needs another polish pass.** The visual language is coherent, but the page still behaves like a long document containing several tools rather than one focused learning workspace.

## Flow health

1. **Desktop R lab before execution — Needs work**
   - Evidence: `02-top.png`
   - The three-column hierarchy is understandable.
   - Long generated R vectors create an avoidable horizontal scrollbar.
   - The saved prediction remains the strongest card even though the learner is already on Run R.
   - The entire document scrolls, so the product header disappears instead of the workspace behaving like an application shell.

2. **Desktop R execution success — Needs work**
   - Evidence: `04-r-success.png`
   - Runtime, checks, seed, hash, and row count make the success state credible.
   - The code column stretches to the result column height, leaving a large empty dark block below the actions.
   - 3D-only controls remain below the R lab, so the active view and available controls do not match.

3. **Desktop updated 3D scene — Critical visualization issue**
   - Evidence: `10-desktop-scene-success.png`
   - The runtime reports five returned rows and the accessible table contains five rows, but only two points are visible in the canvas.
   - The post-transform camera does not fit the new point bounds; learners can mistake clipped points for filtered-out data.
   - Axis lines dominate the sparse visible points.

4. **Mobile R workflow — Needs work**
   - Evidence: `06-mobile-results.png`, `07-mobile-r-middle.png`, `08-mobile-companion.png`
   - There is no horizontal page overflow and controls remain usable.
   - The progress rail exposes only the first three steps without a clear continuation cue.
   - The goal, R editor, results, generic 3D controls, accessible table, and companion are stacked into a very long route.
   - Long code lines are clipped inside the editor and the export actions split into a visually heavy second row.

5. **Mobile updated 3D scene — Needs work**
   - Evidence: `09-mobile-scene.png`
   - The canvas is touch-sized and the tabs are understandable.
   - The selected-point label collides with the bottom legend and is partially clipped.
   - Five returned rows are still not represented as five visible points.

## Highest-impact changes

1. Auto-fit the 3D camera to the learner-generated point bounds after every successful R run; clamp point labels within the plot.
2. Put 3D controls and the accessible table inside the 3D tab panel so they disappear in the R tab.
3. Turn the desktop into a viewport-height application shell with internal main/companion scrolling and a persistent top bar.
4. Remove R-editor horizontal scrolling by formatting generated vectors across short lines; stop the code column from stretching into an empty dark area.
5. Collapse completed companion stages into compact summaries, then emphasize only the current task.
6. On mobile, replace the wide step rail and persistent goal card with a compact current-step header; progressively disclose results and companion stages.

## Accessibility and evidence limits

- Semantic headings, tabs, status regions, labelled textareas, keyboard canvas access, and an accessible table are present.
- The mobile horizontal step list needs a visible overflow/continuation cue and a focus-order check with keyboard or screen reader testing.
- Screenshot review cannot prove screen-reader announcements, keyboard focus order, touch gesture quality, or contrast ratios. Those require separate interaction and automated accessibility tests.
- No application errors appeared in the console. WebR emitted only its expected nested-REPL limitation warning.
