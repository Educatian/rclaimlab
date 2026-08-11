# R-LearnXR: Reproducible R-Based Virtual Laboratories for Data Science Education

## Executive summary

R-LearnXR will provide open educational infrastructure for creating reproducible, browser-based virtual data laboratories with R and Quarto. Many data-science lessons ask learners to interpret multivariate results, yet existing interactive examples are often tied to a single course, depend on opaque hosted services, or omit reproducibility and accessible alternatives. R-LearnXR addresses this gap with an R package, reusable Quarto templates, browser-based 3D exploration modules, automated reproducibility checks, and contributor training for R educators.

An implemented prototype already demonstrates the core learning loop and reduces delivery risk: learners predict a pattern, inspect data in a keyboard-operable 3D view or semantic table, explain their evidence, and transfer their reasoning to another point. The grant will harden this prototype into community-ready infrastructure, add reusable lesson-authoring primitives and examples, conduct an educator/learner pilot, and publish contributor onboarding materials. We request $10,000 for a six-month project beginning in January 2027.

## Signatories

### Project team

- **Jewoong Moon — Project Lead / primary contractor.** Product direction, learning-experience design, R and Quarto integration, reproducibility workflow, documentation, and project reporting. Public project artifacts will be linked from the repository.
- **[Name to confirm] — Co-lead / core project team.** Recommended profile: R package maintenance, statistics education, accessibility, or empirical learning evaluation. Responsible for independent review, pilot oversight, and at least one milestone deliverable.

### Contributors

To be completed with people who contribute code, lesson examples, accessibility review, or proposal feedback but are not responsible for the core delivery plan.

### Consulted

To be completed before submission with at least two R educators or maintainers who review the need, API, scope, or reuse plan.

## The problem

R educators can readily publish text, code, and two-dimensional graphics through Quarto, but creating reusable interactive laboratories for multivariate reasoning remains difficult. A lesson author must coordinate R data preparation, interactive rendering, learner prompts, accessible alternatives, reproducible environments, and publishing. These pieces are usually assembled ad hoc. The result is duplicated effort, fragile examples, and interactive content that is hard for other instructors to adapt.

The problem affects instructors, package authors, workshop organizers, and learners. Instructors need a maintainable path from an R analysis to an interactive lesson. Learners need interactions that support evidence-based reasoning instead of passive visualization, including a non-pointer path when a 3D canvas is inaccessible. Maintainers need examples that can be checked automatically rather than manually repaired whenever data, packages, or publishing tools change.

Solving this problem will let the R community share virtual laboratories as open educational resources. An instructor could start from a documented template, map three variables from an R data frame into a browser scene, add prediction and explanation prompts, verify the build, and publish through an ordinary Quarto workflow. Community contributors could improve the package, author domain-specific lessons, translate materials, and reuse the checks in other educational projects.

Existing R packages provide excellent analysis, visualization, WebGL, Shiny, and publishing capabilities. R-LearnXR does not replace them. It supplies a focused educational layer that connects data preparation, learner workflow, accessibility, reproducibility, and contribution practices. The browser-first design also avoids making headsets or proprietary hardware a requirement.

## The proposal

### Overview

R-LearnXR will become a small, well-scoped R package and Quarto lesson framework. Its primary value is not a single 3D demo; it is a reusable contract for turning R results into inspectable learning evidence. The framework will keep R as the source of data and analysis, produce portable browser artifacts, expose a semantic table alongside the visual scene, and check lessons for reproducibility and accessibility markers.

### Minimum viable product

The community-ready release will include:

1. An R package with stable functions to scaffold lessons, render browser-based 3D scenes, and run lesson checks.
2. A Quarto lesson template implementing Orient–Predict–Explore–Explain–Transfer.
3. At least three openly licensed example lessons using public R datasets.
4. Automated checks for data licenses, deterministic seeds, environment locks, portable paths, required learning-loop elements, accessible alternatives, and artifact hashes.
5. An authoring guide, accessibility guide, contributor pathway, pilot protocol, and issue templates.
6. Continuous integration that runs package tests, lesson checks, and Quarto renders.

### Architecture

R prepares and validates analysis data. The package writes a small JSON artifact and a dependency-free HTML/JavaScript scene generated from a maintained template. Quarto embeds or links that scene in a lesson document. The scene provides the learner interaction and semantic table. A checker reads the lesson project and writes a machine-readable or human-readable report. CI repeats those checks and renders the example lessons.

This separation keeps the statistical workflow in R, the lesson structure in Quarto, and the interaction in a portable browser artifact. It avoids a required application server and makes hosting possible through ordinary static-site infrastructure.

### Assumptions and recovery

- **Assumption: educators value 3D exploration for selected multivariate tasks.** The pilot will test task fit rather than assume novelty equals learning value. If a task does not benefit from 3D, the template will support a table-first or 2D alternative.
- **Assumption: dependency-free browser output is maintainable.** The package will keep the renderer narrow and test key interactions. If advanced WebGL becomes necessary, it will be evaluated as an optional adapter rather than a required dependency.
- **Assumption: instructors can author concise evidence prompts.** Contributor training will include examples, a rubric, and editable prompt patterns.
- **Risk: scope expands into a general XR platform.** The grant scope excludes headset-native applications, multiplayer environments, user accounts, and cloud analytics.
- **Risk: limited community adoption during the grant.** Success will emphasize validated reuse intent, pilot completion, documentation quality, and contributor-ready infrastructure rather than inflated usage claims.

### External dependencies

Core dependencies are R, Quarto, standard browser APIs, and openly licensed example datasets. Package development uses `testthat`; the reference PCA lesson uses `palmerpenguins`. The project will pin the R package environment with `renv` and document data and content licenses. No proprietary hosted service or headset is required for learners.

## Project plan and budget

| Milestone | Target | Deliverables | Budget |
|---|---|---|---:|
| 1. Package and API hardening | Jan 31, 2027 | Stable API, error handling, tests, release checklist | $2,200 |
| 2. Reusable lesson system | Mar 15, 2027 | Quarto template, three example lessons, authoring primitives | $2,300 |
| 3. Reproducibility and accessibility checks | Apr 15, 2027 | Extended checker, CI reports, keyboard/table validation | $2,000 |
| 4. Pilot and contributor onboarding | May 31, 2027 | Educator/learner pilot, usability findings, contributor training | $2,000 |
| 5. Community release and reporting | Jun 30, 2027 | Public release, documentation site, blog-ready report, roadmap | $1,500 |
| **Total** |  |  | **$10,000** |

Funding is allocated to direct labor tied to milestone deliverables. The project will not charge indirect costs, travel, lodging, food, publication fees, or personal hardware. Code will use an OSI-approved license and educational content will use a Creative Commons license. Work will be public on GitHub, with issues and contribution templates available from project startup.

## Success

### Definition of done

- Package functions and lesson checks pass in continuous integration.
- Three complete lessons render from a locked environment.
- Every example offers keyboard operation and a semantic data alternative.
- Authoring, accessibility, contribution, and pilot documentation is published.
- A tagged release and archived project report are publicly available.

### Measuring success

- At least two instructors or maintainers document a concrete reuse or review outcome.
- At least one structured pilot is completed and summarized without exposing private learner data.
- At least 80% of pilot participants complete the core Predict–Explore–Explain task without facilitator intervention; this target will be interpreted cautiously for a small pilot.
- All identified critical accessibility defects are fixed or documented before release.
- At least one contributor outside the core team completes an issue, lesson adaptation, or documentation improvement.

### Future work

Future contributors could add domain-specific lesson packs, localization, optional WebXR adapters, more visualization types, and integrations with existing R visualization packages. These extensions remain outside the grant MVP so the funded work can deliver a stable, reusable foundation.

