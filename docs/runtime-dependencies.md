# Runtime dependency boundary

R-LearnXR is a static-site-friendly prototype, but its first browser execution currently imports WebR 0.6.0 from `https://webr.r-wasm.org/v0.6.0/webr.mjs`. The package records the tested version in the lesson UI and reproducibility export; the repository does not yet vendor the WebR runtime or claim offline execution.

This is an explicit release limitation:

- Author-side R rendering, Quarto output, the JSON scene artifact, and the semantic table remain available without WebR execution.
- A lesson host must disclose that first-run R execution requires network access to the pinned WebR asset.
- CI and release checks must exercise the browser path with the pinned URL; a changed runtime is a release decision, not an incidental dependency update.
- Self-hosting or integrity metadata for WebR assets is future hardening work and is not counted as completed in the grant proposal.
