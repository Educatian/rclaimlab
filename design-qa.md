# Design QA

Final result: **passed**

## Test setup

- Source: `output/figma/rlearnxr-explore-screen.png`
- Implementation: `output/demo/02-explore.png`
- Combined comparison: `output/design-qa/comparison-pass-2.png`
- Target state: Explore, step 3 of 5
- Source viewport: 1440 × 920
- Browser viewport: 1440 × 920 override; rendered content area 1425 × 910 because of browser scrollbars
- Pixel density: 1

## Pass history

### Pass 1

The first implementation matched the overall three-column structure but had three actionable differences:

- The plot points were too tightly clustered compared with the Figma reference.
- The learning companion was vertically crowded and clipped the explanation area.
- Repeated rounded cards, pill buttons, and shadows made the layout feel more like a generated dashboard than a working instructional tool.

Fixes:

- Increased the scene projection scale and reduced camera distance.
- Compacted fields and section spacing.
- Replaced the companion card stack with one task panel and internal dividers.
- Introduced semantic color, spacing, radius, and elevation tokens.
- Reserved full pills for status and tags; changed actions to 8 px controls.
- Flattened the controls and accessible-table containers.

### Pass 2

No actionable P0, P1, or P2 visual defects remain.

## Final surface review

| Surface | Result | Notes |
|---|---|---|
| Typography | Pass | Dense product typography, clear labels, and stable hierarchy match the design intent. |
| Spacing and layout | Pass | Header, rail, scene, and companion align; mobile sections remain available. |
| Colors and tokens | Pass | Semantic tokens replace repeated visual values and preserve Figma's blue/teal/orange hierarchy. |
| Assets and data | Pass | The canvas uses real lesson data; no placeholder assets are visible. |
| Copy and content | Pass | Copy reflects the working Predict–Explore–Explain–Transfer workflow. |
| Interaction states | Pass | Current/done steps, focus, validation, transfer, completion, and restart states work. |
| Accessibility | Pass | Keyboard canvas, semantic table, labels, focus styles, live regions, and reduced motion are present. |

## Intentional deviations from Figma

- The implementation includes a visible Restart lesson action, real multiline fields, feedback text, and an accessible data table because the Figma source was a static visual reference.
- The companion uses internal dividers instead of three floating cards to improve product density and reduce visual noise.
- The canvas is a live projection generated from R data, so exact point positions differ from the static reference while preserving the same visual grammar.

