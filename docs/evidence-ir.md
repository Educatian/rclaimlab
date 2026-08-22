# Evidence Intermediate Representation 2

`rclaimlab-evidence-2` is the stable boundary between R analysis and educational rendering. The browser never estimates PCA, regression, classification, or clustering models. It consumes the compiler artifact and records learner actions against stable identifiers.

## Required identity model

- `observation_id` identifies an analytical case across table, 2D, 3D, explanation, transfer, and receipt artifacts.
- `dimension_id` identifies a score, variable, residual, probability, interval, class, cluster, or distance.
- `evidence_id` identifies exactly one observation-dimension value and links it to provenance.
- `task_id` and named criteria connect the R-authored lesson sequence to browser validation and learning receipts.

## Required provenance

Each artifact records the analysis engine and complete generated source, retained-row decision, deterministic seed, R version, package versions, and artifact hash. Adapters may include method-specific metadata such as PCA loadings and variance, regression coefficients and intervals, GLM event and threshold, or k-means centers and distances. Browser receipts preserve both the compiled evidence hash and the browser-run hash.

## Question and pedagogy contract

The authoring layer records the analytical question, intent, unit of analysis, outcome, identifier, grouping, time, and decision context. Method-specific diagnostics, cautions, misconceptions, prompts, and criteria are serialized with the lesson. Renderers display that contract; they do not maintain a second set of statistical or assessment rules.

## Extension contract

An adapter implements `as_rclaimlab_evidence.<class>()`, calls the internal evidence builder, and never reimplements model estimation. It must produce finite numeric evidence, stable unique labels, valid links, and deterministic JSON for the same input and environment.

Schema changes require two maintainer approvals and a fixture migration. See `governance/SCHEMA-GOVERNANCE.md`.
