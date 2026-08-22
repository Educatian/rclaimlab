# Accessibility Baseline

R-ClaimLab treats XR and 3D interaction as progressive enhancement. A lesson is not accepted if its learning goal requires a mouse, headset, color perception, or spatial vision.

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

## Automated browser pass

Run `powershell -ExecutionPolicy Bypass -File scripts/browser_smoke_test.ps1 -StartServer`. It checks mobile horizontal overflow, the optional AI brief path, keyboard focus and scene controls, and the semantic point table in a real browser. The script does not claim screen-reader or WCAG conformance.

## Manual verification before publishing

Run the complete task with keyboard only, including tab navigation, code editing, R execution, table point selection, explanation checking, and completion. Repeat at 200% zoom, with reduced motion enabled, and with a screen reader or accessibility tree inspection. Confirm that the plain-language R error appears before the technical trace, that focus remains visible after switching between the 3D and R views, and that the mobile layout does not require horizontal scrolling. Also test the first-run WebR loading path with a blocked network so the lesson documents its offline limitation clearly.
