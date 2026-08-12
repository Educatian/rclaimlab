# R Consortium ISC 2026-2 application preparation

Status checked: 2026-08-11.

## Submission window

- Call opens: September 1, 2026. The official page does not state an opening time, so treat this as an all-day date.
- Submission deadline: October 1, 2026 at 11:59 PM US Eastern Time, equivalent to 8:59 PM Pacific Daylight Time.
- Decision notification: November 1, 2026.
- Award acceptance and contracting deadline: December 1, 2026.

Calendar events were created for the opening date and the exact Pacific-time deadline.

## Current form status

The linked Google Form currently displays `Submit an ISC grant proposal 2026-1` and says that submissions are closed. The 2026-2 form is expected to become available on September 1. Because the closed form does not expose its questions, preparation should follow the required official proposal template and recheck the live form when it opens.

Official sources:

- [ISC Grant Program and submission form](https://r-consortium.org/all-projects/callforproposals.html)
- [Required proposal template](https://github.com/RConsortium/isc-proposal)
- [Standard individual consultant agreement](https://r-consortium.org/rc-docs/Individual-Consultant-Agreement-for-R-Consortium-ISC-Projects-20170622.pdf)

## Files to prepare

The official process requires one self-contained PDF, 2–5 pages. The template repository recommends roughly 500–2,500 words.

- [ ] Final 2–5 page PDF
- [ ] Public proposal or project repository URL
- [ ] Project lead contact information
- [ ] Core project team and co-lead roles
- [ ] Public evidence of prior work and delivery capacity
- [ ] Total request in USD, no more than $10,000
- [ ] Milestone-level budget and delivery dates
- [ ] Open-source and content licenses
- [ ] Community feedback, consulted people, and letters or comments of support
- [ ] Risk, assumption, dependency, and recovery plan
- [ ] Measurable definition of done and adoption indicators

## Official proposal sections

### Executive summary

Fit the entire argument on one page: problem, proposed approach, beneficiaries, major deliverables, timeline, and total budget.

### Signatories

List the core project team, contributors to the proposal, and people consulted. The template explicitly allows multiple project team members. Use one `Project Lead / primary contractor` and list a second person as `Co-lead / core project team`; the standard contract appears to use one contractor, so confirm split-payment arrangements with `proposal@r-consortium.org` if needed.

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

## R-LearnXR evidence already available

- Working R package API for scaffolding, rendering, and checking lessons
- Reusable Quarto lesson structure
- Two runnable lessons, including a `palmerpenguins` PCA example
- Keyboard-operable 3D scene and semantic data-table alternative
- Predict–Run R–Explore–Explain–Reproduce learner workflow
- Pinned WebR runtime with learner-edited code, automatic checks, synchronized 3D output, and `.R`/`.qmd` export
- Automated reproducibility and lesson checks
- `renv.lock`, CI workflow, contribution guide, code of conduct, authoring guide, and pilot protocol
- Desktop and mobile QA screenshots

## Evidence still needed before submission

- Name and confirmation of the co-lead or core team member
- Two or more R educators/maintainers who have reviewed the proposal
- At least one short pilot or structured usability session
- Public repository URL is available; a public pre-release or release tag is still needed
- English narrated and captioned demo is available, including a direct-interaction browser recording
- Concise budget justification tied to future—not already completed—work
- Final application-form field check on or after September 1

## Recommended preparation schedule

| Date | Action |
|---|---|
| Aug 11–16 | Publish repository, replace the screenshot montage with a direct-interaction demo, and finish technical QA |
| Aug 17–23 | Recruit co-lead and two community reviewers; run a small pilot |
| Aug 24–31 | Incorporate feedback; compress proposal to 2–5 pages |
| Sep 1 | Inspect the live 2026-2 form and map every field to the prepared material |
| Sep 2–15 | Obtain named support and finalize milestone budget |
| Sep 16–24 | Independent review for clarity, scope, and delivery risk |
| Sep 25–28 | Final PDF, links, accessibility, and attachment checks |
| Sep 29 | Target submission date; keep two days of buffer |
| Oct 1, 8:59 PM PDT | Absolute deadline |
