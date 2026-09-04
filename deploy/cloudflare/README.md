# Cloudflare public demo build

The public entry is https://rclaimlab-review.pages.dev/. The four workspaces are
`/modes/{guided,analyst,scientist,reviewer}/app/`; legacy `/app/` and its artifact
URLs remain the reviewer example.

Build from the exact tested package commit, in a NEW output directory:

```powershell
$releaseRef = git rev-parse HEAD
Rscript deploy/cloudflare/build-modes.R output/cloudflare-release-NEW $releaseRef
wrangler pages deploy output/cloudflare-release-NEW --project-name rclaimlab-review --branch parity-preview --commit-hash $releaseRef --commit-dirty=true
./deploy/cloudflare/check.ps1 -BaseUrl https://PREVIEW.rclaimlab-review.pages.dev
```

To build with an isolated installed package, set `RCLAIMLAB_LIBRARY` to its
library directory first. Otherwise the builder uses current source through
pkgload; the caller must ensure it corresponds to the supplied commit.
The release process tests a clean GitHub install of that exact SHA before deployment.

All four modes are now freshly compiled from package-owned presets. The public
launcher uses the same component and CSS as Shiny. No historical output folder,
handcrafted mode page, or deployment-specific guided task override is required.
The older `prepare.ps1`, `index.html` and `modes.*` files are historical only;
they are not inputs to the current builder and must not be deployed instead.

Validate desktop/mobile, keyboard use, mode changes and workspace interactions.
Deploy the IDENTICAL checked directory with `--branch codex-v2.1-role-workflows`
(the Pages production branch, different from the Git branch's slash), then run
`check.ps1` against production. Do not deploy the repository, caches, screenshots,
or development scripts. `release-manifest.json` records the full commit, package
version, fixture checksum and all generated artifact MD5 checksums.

Every mode includes a complete `analysis/workflow.R`. Sourcing defines
`reproduce_workflow()`; calling it explicitly runs the recorded plan locally.
The hosted demo remains precompiled: no upload service, remote Shiny process,
general R interpreter, or automatic transfer of personal receipts across roles.
See [the user guide](../../docs/demo-package-parity.md) for the boundary and commands.

`node deploy/cloudflare/test-presentation.cjs` validates shared display mappings
and runtime syntax. Official deployment reference:
https://developers.cloudflare.com/pages/get-started/direct-upload/
