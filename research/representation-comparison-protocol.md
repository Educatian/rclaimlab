# Representation comparison protocol

Status: implementation-ready protocol, not yet a completed human-subjects study.

## Governance first

Obtain an IRB determination or non-research determination before recruitment. Preregister hypotheses, exclusions, scoring rules, stopping rules, and analysis code. Store consented research data outside the package repository; keep identity keys separate from response data.

## Design

Recruit approximately 60 learners. Use a counterbalanced within-subject design. Assign equivalent PCA, regression, and clustering tasks to table, 2D, and 3D representations with a Latin-square order. Do not describe 3D as superior in recruitment, instruction, or analysis.

Primary outcomes are an evidence-explanation rubric and transfer to a new case. Secondary outcomes are correctness, completion time, cognitive load, usability, and R self-efficacy. Record prior R experience and accessibility needs as planned moderators.

## Formative gate

Before the comparison study, run five learner sessions and two instructor sessions. Stop release-candidate promotion for any P0 data-loss/accessibility issue or P1 issue that prevents a full keyboard/table pathway. Log design changes and rerun affected tasks.

## Analysis

Use mixed-effects models with participant and task as grouping factors where justified. Report uncertainty and representation-by-task interactions. Treat null or heterogeneous effects as informative. Do not use the study to make unsupported claims that spatial rendering improves learning in general.
