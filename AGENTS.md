# R-ClaimLab UI implementation rules

These rules apply to every Figma-driven or learner-facing UI change in this repository.

## Source of truth

- The runtime UI is generated from `inst/templates/scene.html`; update that template instead of editing generated lesson HTML.
- The reference Figma file is `jZ0W2ieUoSRwZtrMUKru8g`, with the explore lesson rooted at node `1:13`.
- Before changing layout or visual styling, inspect the exact Figma node and compare an implementation screenshot at the same viewport and learner state.
- Generated React or Tailwind from Figma is reference material only. Translate it to semantic HTML, CSS custom properties, and dependency-free JavaScript.

## Design tokens

- IMPORTANT: use the semantic CSS variables declared in `:root` in `inst/templates/scene.html`.
- Colors use `--color-*`; spacing uses the 4 px `--space-*` scale; radii use `--radius-*`; elevation uses `--shadow-*`.
- Add a token before repeating a new visual value. Hardcoded values are allowed only for canvas plotting geometry, data-series colors, and one-off responsive breakpoints.
- Use `--radius-control` for fields and buttons, `--radius-panel` for content panels, and `--radius-shell` only for the application shell. Reserve full pills for compact status or tag elements.

## Component patterns

- Keep one dominant interactive scene and one learning companion. Do not turn every paragraph or action into a separate card.
- Use borders and section dividers for hierarchy before adding shadows. Only the shell and primary scene may use elevation.
- Buttons use at least a 44 px target, visible hover and focus states, and a rectangular 8 px radius unless they are status chips.
- Inputs need visible labels, concise placeholders, persisted learner state, and inline status feedback.
- Reuse the existing step rail, scene panel, companion sections, button variants, fields, status chip, data table, and feedback patterns.

## Learning experience

- Preserve the full Orient → Predict → Explore → Explain → Transfer loop.
- Visible controls in the core learner journey must work with realistic data.
- Feedback must reference the selected point or entered evidence; do not use decorative or fake success states.
- Mobile layouts must retain the learning path, scene, companion, and accessible data alternative.

## Accessibility and QA

- Meet WCAG 2.2 AA contrast, keyboard operation, reduced-motion preference, semantic landmarks, labels, and live-region feedback.
- Never hide essential content only to make a screenshot fit.
- For each material UI change, capture desktop and mobile screenshots and run the browser interaction flow.
- Compare the Figma reference and implementation side by side at 1440 × 920, record findings in `design-qa.md`, and fix all actionable P0–P2 issues before completion.
- Run the R package tests, lesson checks, Quarto renders, and `R CMD check` after template changes.

## Product-quality guardrails

- Avoid gratuitous gradients, glass effects, oversized headings, excessive pill buttons, generic marketing copy, and repeated rounded cards.
- Prefer compact, task-focused information density suitable for an instructional analytics tool.
- Keep copy specific to the learner action and data evidence.
- Do not add a frontend framework or icon library for a small visual adjustment.

