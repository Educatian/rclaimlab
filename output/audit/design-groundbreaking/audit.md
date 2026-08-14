# R-LearnXR design audit: making the learning moment distinctive

Date: 2026-08-13
Surface: `examples/lesson/scene/index.html`
Capture URL: `http://127.0.0.1:8772/examples/lesson/scene/index.html`

## Captured flow

1. Predict start (`01-predict-start.png`): the learner sees the workflow, 3D evidence space, and prediction prompt.
2. R authoring (`02-r-code-lab.png`): the learner sees the `scene` data contract and an editable R pipeline.
3. AI visual brief (`03-ai-visual-brief.png`): the learner can describe an analytical goal in natural language.
4. R execution result (`04-r-run-result.png`): WebR returns transformed rows, PASS checks, a hash, and synchronized scene evidence.

## Findings

- The strongest current asset is the real causal loop: prediction -> edited R -> returned rows -> visual evidence -> explanation. This is more defensible and more distinctive than a generic 3D canvas.
- The first viewport is visually polished and calm, but the 3D scene currently reads as the hero. The learning claim is distributed across the left path, center scene, and right companion, so the “why this changed” moment is not yet dominant.
- The successful R state contains high-value evidence, but the transformation summary, PASS checks, hash, and updated scene are split across the scroll. The breakthrough moment should be a single “R changed the evidence” state.
- The AI Visual Brief is interesting, but its current “optional demo” treatment makes it feel like a side feature. It should be framed as a constrained bridge from intent to reviewable R, never as an AI chatbot.

## Recommended design direction

1. Make the transformation the hero: show a before/after scene comparison with removed points ghosted, retained points highlighted, and a one-line delta such as `6 rows -> 5 rows because abs(x) >= 0.25`.
2. Add a “claim / evidence / code” triad. Every selected point should expose the learner claim, the exact coordinate evidence, and the R line that produced it.
3. Introduce a visible provenance ribbon after a successful run: `R 4.6.0 · seed 2026 · 5 rows · hash 0432fdbcb0be`. This turns reproducibility into a learner-facing design object.
4. Use controlled surprise: let the learner change one threshold, preview the predicted effect, then reveal the actual delta. The reveal is the memorable moment, not animation alone.
5. Reframe AI as “Describe -> Review R -> Run -> Inspect”. The generated brief should show the request, assumptions, code, and validation status in one auditable card.
6. Add an educator “reuse proof” state showing `scaffold_lesson() -> render_scene() -> check_lesson(strict = TRUE) -> quarto render` as a compact release pathway, with a copyable starter lesson.

## Accessibility and product constraints

- Preserve the semantic table as an equal evidence surface, not a fallback hidden below the 3D canvas.
- Keep keyboard focus on the changed point and announce row-count/hash changes in the live region.
- Avoid particle effects, camera motion, or color-only before/after encoding; use labels, outlines, and text deltas.
- Keep the AI path optional, local-first, and visibly reviewable; no claim should depend on model output.

## Limits

This audit covers the captured desktop states and DOM-visible interaction. It does not establish screen-reader conformance, long-session cognitive load, or a mobile breakpoint audit.
