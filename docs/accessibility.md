# Accessibility Baseline

R-LearnXR treats XR and 3D interaction as progressive enhancement. A lesson is not accepted if its learning goal requires a mouse, headset, color perception, or spatial vision.

## Required paths

- Pointer: drag, wheel, point selection, and visible focus/selection state.
- Keyboard: arrow-key rotation, plus/minus zoom, Home reset, and reachable controls.
- Structured data: a table exposing every point and coordinates with semantic row and column headers.
- Responsive: prediction, observation, explanation, and completion remain available at 320 CSS pixels.
- Assistive technology: landmarks, headings, labels, instructions, and polite live regions for updated feedback.

## Author checks

- Do not encode meaning by color alone.
- Use plain-language coordinate explanations.
- Keep tap targets at least 44 CSS pixels high.
- Test at 200% browser zoom and with reduced motion enabled.
- Provide captions/transcripts for future audio or video.
- Record known gaps without claiming full WCAG conformance from automated checks alone.
