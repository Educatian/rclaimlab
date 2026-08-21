# R-LearnXR: From R Code to Evidence

**A Reproducible R Framework for Interactive Data Learning**

## Executive summary

R-LearnXR will provide a small, reusable R Evidence Compiler and Quarto authoring framework for reproducible data-science lessons. Many lessons ask learners to interpret analytical results, yet code, tables, graphics, prompts, assessment, and provenance often maintain separate copies of the evidence. R-LearnXR addresses this infrastructure gap by converting existing R analysis objects into an Evidence Intermediate Representation whose stable IDs connect semantic tables, 2D and optional 3D views, learner explanations, repairs, transfer tasks, and reproducibility receipts.

An implemented v2 release candidate already demonstrates the complete R-object-to-receipt workflow. Authors state a question, analytical intent, unit of analysis, outcome, grouping/time structure, and decision context before approving an adapter. Learners then complete Orient, Predict, Run R, Explore, Explain, Repair, Transfer, and Reproduce against method-specific prompts and criteria. Ten reference lessons cover contributor training, foundational description and inference, PCA, linear regression, repeated-session Learning Analytics, and k-means Educational Data Mining. The grant will fund external review, API and release hardening, CRAN-ready checks, contributor onboarding, and a small educator/learner feasibility pilot. The optional AI Visual Brief is unfunded and not required. We request $10,000 for a six-month funded release phase beginning in January 2027, within the longer 24-month research-software roadmap.

## Signatories

### Project team

- **Jewoong Moon — Project Lead / primary contractor.** Product direction, learning-experience design, R and Quarto integration, reproducibility workflow, documentation, and project reporting. Public project artifacts will be linked from the repository.
- **Additional core team members: optional and to be added if confirmed.** The Project Lead can deliver the scoped six-month MVP as the primary contractor; any confirmed collaborator will receive a named responsibility and be added with consent.

### Contributors

To be completed with people who contribute code, lesson examples, accessibility review, or proposal feedback but are not responsible for the core delivery plan.

### Consulted

To be completed before submission with at least two R educators or maintainers who review the need, API, scope, or reuse plan.

## The problem

R educators can readily publish text, code, and two-dimensional graphics through Quarto, but creating reusable interactive laboratories for multivariate reasoning remains difficult. A lesson author must coordinate R data preparation, interactive rendering, learner prompts, accessible alternatives, reproducible environments, and publishing. These pieces are usually assembled ad hoc. The result is duplicated effort, fragile examples, and interactive content that is hard for other instructors to adapt.

The problem affects instructors, package authors, workshop organizers, and learners. Instructors need a maintainable path from an R analysis to an interactive lesson. Learners need interactions that support evidence-based reasoning instead of passive visualization, including a non-pointer path when a 3D canvas is inaccessible. Maintainers need examples that can be checked automatically rather than manually repaired whenever data, packages, or publishing tools change.

Solving this problem will let the R community share virtual laboratories as open educational resources. An instructor could start from a documented template, map three variables from an R data frame into a browser scene, add prediction and explanation prompts, verify the build, and publish through an ordinary Quarto workflow. Community contributors could improve the package, author domain-specific lessons, translate materials, and reuse the checks in other educational projects.

Existing R packages provide excellent analysis, visualization, WebGL, Shiny, and publishing capabilities. R-LearnXR does not replace them. It supplies a focused package-level educational layer that connects data preparation, learner workflow, accessibility, reproducibility, and contribution practices. The browser-first design also avoids making headsets or proprietary hardware a requirement. The 3D view is progressive enhancement; the package contract, R source, Quarto lesson, JSON artifact, and semantic table are the durable core. The optional LLM adapter is reviewable, bounded, and outside the funded MVP.

## The proposal

### Overview

R-LearnXR will become a small, well-scoped R package and Quarto lesson framework. Its primary value is the Evidence Compiler, not a single 3D demo. A data-frame, `prcomp`, `lm`, `glm`, or `kmeans` adapter converts an existing result into linked evidence. The browser renders that evidence and the R-authored learning contract but does not own statistical rules. The grant-period release will also validate an open artifact bridge against a separate DataSandbox test copy without changing the live intervention repository or introducing a shared database, LMS identity layer, or research-data pipeline.

### Funded release scope

The community-ready release will include:

1. An R package with stable Evidence Adapter, lesson specification, compiler, receipt, and checker functions, including edge-case validation and JSON reports.
2. A Quarto and browser template implementing Orient–Predict–Run R–Explore–Explain–Repair–Transfer–Reproduce from one serialized task contract.
3. Five openly licensed or synthetic example lessons covering contributor training, PCA, regression, Learning Analytics, and Educational Data Mining.
4. Strict checks for substantive data licenses, deterministic seeds, environment locks, portable paths, required learning-loop elements, accessible alternatives, and artifact hashes, plus a real-browser keyboard/responsive smoke test.
5. A documented DataSandbox exchange contract and adapter with a portable manifest, source-data handoff, learning receipt, privacy boundary, and import/export examples.
6. An authoring guide, accessibility guide, contributor pathway, pilot protocol, and issue templates.
7. Continuous integration that runs package tests, lesson checks, and Quarto renders.

### Architecture

R fits or receives the analysis object, creates Evidence IR, assigns stable observation/dimension/evidence IDs, and serializes the question, tasks, criteria, diagnostics, cautions, source, seed, versions, retained rows, and artifact hash. The maintained HTML/JavaScript laboratory consumes that contract. A pinned WebR runtime lets learners transform the compiled evidence locally, validates the returned `scene` data frame, and synchronizes its points with the canvas, semantic table, observation text, and browser-run record. Quarto embeds or links the laboratory. A checker writes machine-readable and human-readable reports. CI repeats those checks and builds all ten lessons.

This separation keeps the statistical workflow in R, the lesson structure in Quarto, and the interaction in a portable browser artifact. WebR preserves authentic R execution without a required application server, making hosting possible through ordinary static-site infrastructure.

### Assumptions and recovery

- **Assumption: educators value 3D exploration for selected multivariate tasks.** The pilot will test task fit rather than assume novelty equals learning value. If a task does not benefit from 3D, the template will support a table-first or 2D alternative.
- **Assumption: a pinned WebR browser runtime is maintainable.** The package will pin the tested WebR release, expose a clear loading/error state, and evaluate self-hosting the release assets during hardening. If advanced WebGL becomes necessary, it will be evaluated as an optional adapter rather than a required dependency.
- **Assumption: instructors can author concise evidence prompts.** Contributor training will include examples, a rubric, and editable prompt patterns.
- **Risk: scope expands into a general XR platform.** The grant scope excludes headset-native applications, multiplayer environments, user accounts, and cloud analytics.
- **Risk: limited community adoption during the grant.** Success will emphasize validated reuse intent, pilot completion, documentation quality, and contributor-ready infrastructure rather than inflated usage claims.

### External dependencies

Core dependencies are R, Quarto, WebR, standard browser APIs, and openly licensed example datasets. Package development uses `testthat`; the reference PCA lesson uses `palmerpenguins`. The project pins WebR 0.6.0 in the prototype, will pin the R package environment with `renv`, and documents data and content licenses. WebR is currently loaded from its public runtime URL for first-run browser execution; offline vendor/self-host support is not claimed as complete. No proprietary hosted service, application server, or headset is required for learners.

## Project plan and budget

| Milestone | Target | Deliverables | Budget |
|---|---|---|---:|
| 1. Package and API hardening | Jan 31, 2027 | Stable API, edge-case tests, release checklist | $2,800 |
| 2. Reusable lesson system | Mar 15, 2027 | Quarto authoring primitives and one community-authored lesson adaptation | $2,400 |
| 3. Reproducibility and browser accessibility checks | Apr 15, 2027 | Strict checker, JSON reports, CI, keyboard/overflow smoke test | $2,200 |
| 4. Validation, release, and maintenance | Jun 30, 2027 | Educator/learner feasibility pilot, contributor training, release, report | $2,600 |
| **Total** |  |  | **$10,000** |

Funding is allocated to direct labor tied to milestone deliverables. Existing v2 compiler code, UI refinement, narration, screenshots, and the ten current lessons are in-kind feasibility evidence and are not charged retroactively. The project will not charge indirect costs, travel, lodging, food, publication fees, or personal hardware. Code will use an OSI-approved license and educational content will use a Creative Commons license. Work will be public on GitHub, with issues and contribution templates available from project startup.

## Success

### Definition of done

- Package functions and lesson checks pass in continuous integration.
- Five complete lessons render from documented, locked environments; the grant will validate reuse and add a community-authored lesson or adapter.
- Every example offers keyboard operation and a semantic data alternative.
- Authoring, accessibility, contribution, and pilot documentation is published.
- A tagged release and archived project report are publicly available.

### Measuring success

- Two R educators or maintainers complete a documented API/scope review with concrete reuse or review outcomes.
- Five novice learners and two instructors are invited to the structured feasibility protocol; results record completed sessions, task times, interventions, and drop-offs without exposing private data.
- At least four of five novice learners complete the core Predict–Run R–Explore–Explain task without facilitator intervention, reported as raw counts and limitations; smaller recruitment is reported as not estimable.
- All critical accessibility defects found by the browser smoke test or external review are fixed or documented before release.
- At least one contributor outside the core team completes an issue, lesson adaptation, or documentation improvement.

### Future work

Future contributors could add domain-specific lesson packs, localization, optional WebXR adapters, more visualization types, and integrations with existing R visualization packages. These extensions remain outside the grant MVP so the funded work can deliver a stable, reusable foundation.
