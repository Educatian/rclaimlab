# Runtime dependency boundary

R-LearnXR is static-site-friendly v1 infrastructure, but its first browser execution currently imports WebR 0.6.0 from `https://webr.r-wasm.org/v0.6.0/webr.mjs`. The package records the tested version in the lesson UI and reproducibility export; the repository does not vendor the WebR runtime and claims offline fallback, not offline R execution.

For repository authors, RStudio's Git integration requires a local Git installation. Quarto is required to render lesson pages, while the package API itself can be installed from GitHub with `remotes::install_github()` or from a cloned checkout with `remotes::install_local(".")`. Run `Rscript scripts/diagnose_environment.R` before setup so missing tools are visible.

This is an explicit release limitation:

- Author-side R rendering, Quarto output, the JSON scene artifact, and the semantic table remain available without WebR execution.
- A lesson host must disclose that first-run R execution requires network access to the pinned WebR asset.
- CI and release checks must exercise the browser path with the pinned URL; a changed runtime is a release decision, not an incidental dependency update.
- Self-hosting or integrity metadata for WebR assets is future hardening work and is not counted as completed in the grant proposal.
