# External validation without local GUI control

R-LearnXR can be validated outside the developer's current work window. The primary route is the public GitHub Actions workflow at `.github/workflows/check.yml`; it uses disposable GitHub-hosted runners and does not require Computer Use, RStudio Desktop, or a locally controlled browser window.

## What runs remotely

Every push, pull request, manual dispatch, and weekly scheduled run performs:

1. R package checks on Ubuntu, Windows, and macOS.
2. Rebuilds and strict-checks all ten reference lessons.
3. Renders all ten Quarto lessons.
4. Clones and installs `Educatian/rlearnxr` from public `main` into a clean R library and verifies the exported API.
5. Runs a real Chromium interaction smoke test for keyboard controls, mobile width, the AI brief, and the semantic table.
6. Runs the network-blocked WebR fallback test on a hosted Windows runner.
7. Runs the synthetic novice-learner flow through completion and a screen-reader accessibility-tree proxy.
8. Runs the Posit Cloud clean-room proxy with a temporary library, strict checks, and Quarto rendering.

The workflow stores rendered lesson reports and browser screenshots as GitHub Actions artifacts. A reviewer can inspect the run summary and download evidence without opening the developer's local project.

## How to trigger it

The workflow runs automatically after a public push or pull request. For an explicit release rehearsal, use the GitHub Actions **Run workflow** control or the GitHub CLI:

```powershell
gh workflow run "R-LearnXR external validation" --repo Educatian/rlearnxr --ref main
gh run list --repo Educatian/rlearnxr --workflow "R-LearnXR external validation" --limit 1
```

The repository is public, so this validation does not require sharing a local desktop session. It does require GitHub-hosted runner availability and the repository's Actions permission to remain enabled.

## What this proves

This provides independent environment evidence for installation, package contracts, lesson generation, Quarto rendering, responsive browser interaction, keyboard interaction, and first-run WebR failure recovery. It is stronger than a screenshot because the checks execute from a clean runner and fail the workflow when an assertion breaks.

## What still needs people or a separate service

- Posit Cloud or Workbench project cloning and rendering, if that deployment target is part of the grant promise.
- A screen-reader pass with NVDA, VoiceOver, or JAWS.
- Novice learner and R educator pilot sessions, including task success and comprehension evidence.
- Corporate proxy, locked-down browser, and institution-specific permission recovery.

These are not suitable for unattended CI because they require an account, assistive technology, institutional network, or human judgment. They should be reported as explicit external gates, not presented as completed by automated CI. The synthetic persona proxy report is useful for pre-screening regressions, but it does not replace these human or account-based checks.
