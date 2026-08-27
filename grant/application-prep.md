# R Consortium ISC 2026-2 application preparation

Status checked: 2026-08-27.

Project title: **R-ClaimLab: From R Code to Evidence**

Grant subtitle: *A Reproducible R Framework for Interactive Data Learning*

## Submission window

- Call opens: September 1, 2026. The official page does not state an opening time, so treat this as an all-day date.
- Submission deadline: October 1, 2026 at 11:59 PM US Eastern Time, equivalent to 8:59 PM Pacific Daylight Time.
- Decision notification: November 1, 2026.
- Award acceptance and contracting deadline: December 1, 2026.

Calendar events were verified for the opening date and exact Pacific-time deadline; decision and contract-acceptance reminders were also added.

## Current form status

The linked Google Form currently displays `Submit an ISC grant proposal 2026-1` and says that submissions are closed. The 2026-2 form is expected to become available on September 1. Because the closed form does not expose its questions, preparation should follow the required official proposal template and recheck the live form when it opens.

Official sources:

- [ISC Grant Program and submission form](https://r-consortium.org/all-projects/callforproposals.html)
- [Required proposal template](https://github.com/RConsortium/isc-proposal)
- [Current rendered final PDF](../output/pdf/rclaimlab-isc-proposal-final.pdf)
- [Standard individual consultant agreement](https://r-consortium.org/rc-docs/Individual-Consultant-Agreement-for-R-Consortium-ISC-Projects-20170622.pdf)

## Files to prepare

The official process requires one self-contained PDF, 2–5 pages. The template repository recommends roughly 500–2,500 words.

- [x] Final 2–5 page PDF
- [x] Public proposal or project repository URL
- [x] Project lead contact information
- [ ] Project lead contact is ready; Yeonji Jung is designated as proposed co-lead, with written public-attribution consent, January-June 2027 availability, and deliverable-package-4 acceptance still pending
- [x] Public evidence of prior work and delivery capacity
- [x] Total request in USD, justified by milestone-level labor; the current proposal requests $10,000
- [x] Milestone-level budget and delivery dates
- [x] Open-source and content licenses
- [ ] Community feedback, consulted people, and letters or comments of support
- [x] Risk, assumption, dependency, and recovery plan
- [x] Measurable definition of done and adoption indicators

The public call does not state a per-project award ceiling. Treat $10,000 as the proposed, milestone-justified request—not as a published maximum—and verify any amount field or cap in the live 2026-2 form on September 1.

## Official proposal sections

### Executive summary

Fit the entire argument on one page: problem, proposed approach, beneficiaries, major deliverables, timeline, and total budget.

### Signatories

List the core project team, contributors to the proposal, and people consulted. The template permits a single project lead; add additional core team members only when confirmed and consented. The standard contract governs the primary contractor and any payment arrangements.

### The problem

Answer all six points requested by the template:

1. What is the problem?
2. Who is affected?
3. Why is it important?
4. What becomes possible if it is solved?
5. What existing R packages, learning tools, or prior attempts exist?
6. Why is this reusable infrastructure rather than one local course?

### The proposal

Describe the high-level value and concrete actions, then include:

- Minimum viable product
- Architecture
- Assumptions that could invalidate the plan
- External dependencies
- Likely failure modes and recovery actions

### Project plan

Include startup, technical delivery, community/dissemination work, and a milestone-based budget. The template says most funding should be labor and does not cover indirect costs, travel, lodging, food, publication fees, or personal hardware.

### Success

Separate deliverable completion from adoption evidence:

- Definition of done: artifacts that can be objectively checked
- Measuring success: pilot completion, reuse, contributors, issues, and accessibility outcomes
- Future work: what can be extended by the R community after the grant

## R-ClaimLab evidence already available

- Working R package API for scaffolding, rendering, and checking lessons
- Reusable Quarto lesson structure
- Ten runnable reference lessons spanning contributor workflow, foundational statistics, PCA, regression, Learning Analytics, and Educational Data Mining
- Keyboard-operable 3D scene and semantic data-table alternative
- Predict–Run R–Explore–Explain–Reproduce learner workflow
- Pinned WebR runtime with learner-edited code, synchronized 3D output, semantic table, and `.R`/`.qmd` export; first-run network dependency is documented and offline execution is not claimed
- Advisory and strict reproducibility/lesson checks with Markdown and JSON output
- Real-browser keyboard/responsive smoke test with saved desktop and mobile screenshots
- `renv.lock`, CI workflow, contribution guide, code of conduct, authoring guide, runtime-dependency note, and pilot protocol
- Desktop and mobile QA screenshots

## Submission gates still open

- Written consent, January-June 2027 availability, and deliverable-package-4 ownership for any publicly named co-lead
- Two or more R/Quarto educators or maintainers who complete the structured review; name only with permission
- At least one short learner or instructor pilot with task, barrier, and facilitator-help evidence
- Canonical budget is fixed at $2,800 / $2,400 / $2,200 / $2,600; copy this map to the live form
- Public repository URL and clean-clone install check are complete; create a current GitHub Release and recheck the live form before submission
- English narrated and captioned demo is available, including a direct-interaction browser recording
- Concise budget justification tied to future, not already completed, work
- Final application-form field check on or after September 1

Public tracking:

- [Community reviewers](https://github.com/Educatian/rclaimlab/issues/2)
- [Learner and instructor pilot](https://github.com/Educatian/rclaimlab/issues/3)
- [Prototype release and stable demo URL](https://github.com/Educatian/rclaimlab/issues/4)
- [September 1 live-form audit](https://github.com/Educatian/rclaimlab/issues/5)

## Recommended preparation schedule

| Date | Action |
|---|---|
| Aug 11–16 | Publish repository, replace the screenshot montage with a direct-interaction demo, and finish technical QA |
| Aug 17–23 | Invite two community reviewers and run a small pilot |
| Aug 24–31 | Confirm co-lead role; obtain two R/Quarto reviews and one short pilot; incorporate findings |
| Sep 1 | Inspect the live 2026-2 form and map every field to the prepared material |
| Sep 2–15 | Obtain named support and finalize milestone budget |
| Sep 16–24 | Independent review for clarity, scope, and delivery risk |
| Sep 25–28 | Final PDF, links, accessibility, and attachment checks |
| Sep 29 | Target submission date; keep two days of buffer |
| Oct 1, 8:59 PM PDT | Absolute deadline |
