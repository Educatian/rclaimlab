# R-ClaimLab 2.x Roadmap

The roadmap is governed by one architectural commitment: R owns analytical truth, the Evidence Compiler preserves stable evidence identifiers, and browser components render and collect learning interactions.

| Window | Product milestone | Acceptance evidence |
|---|---|---|
| 2026 Aug | v2.1 role-adaptive vertical slice | pinned public tabular source, Analyst/Scientist/Reviewer handoff, evidence bundle, workflow receipt, responsive browser checks |
| 2026 Aug-Sep | Freeze v1.1.0 and publish the v2 RFC | public branch, RFC, reviewer and pilot protocols |
| 2027 Jan-Mar | Evidence Compiler core | S3 contracts, Evidence IR, data-frame/PCA adapters, canonical PCA vertical slice |
| 2027 Apr-Jun | Education and extension API | lm/glm/kmeans adapters, three render modes, author and adapter vignettes, formative fixes |
| 2027 Jul-Dec | CRAN and public ecosystem | 3-OS and 3-R-version checks, pkgdown, citation/DOI readiness, contributor onboarding |
| 2028 Jan-Jun | Representation comparison | prior determination, preregistration, counterbalanced protocol, separate consented data store |
| 2028 Jul-Aug | JOSS and sustainability | JOSS submission bundle, archive release, succession and schema governance |

Release 2.1 requires ten clean reference lessons, three clean role-workflow
demos, no R CMD check errors or warnings, deterministic evidence artifacts,
table/2D/3D identity synchronization, keyboard and semantic-table paths, and a
second-maintainer API or schema review. A first CRAN submission may retain the
standard new-submission NOTE; it is not treated as a software defect.

The implemented v2.1 source boundary covers public tabular CSV, TSV, and
Parquet data from local files, Hugging Face, and Kaggle. It includes explicit
approvals, bounded local import, source-record lineage, analyst-to-reviewer
handoff, optional schema-only AI drafting, and local workflow receipts. Gated
data, non-tabular modalities, hosted services, and automated approval remain
outside this release.

Native headset support and AI tutoring are outside the 2.0 core. They may integrate later through adapters without moving statistical logic into the browser.
