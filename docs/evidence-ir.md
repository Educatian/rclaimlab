# Evidence Intermediate Representation 2

`rlearnxr-evidence-2` is the stable boundary between R analysis and educational rendering. The browser never estimates PCA, regression, classification, or clustering models. It consumes the compiler artifact and records learner actions against stable identifiers.

## Required identity model

- `observation_id` identifies an analytical case across table, 2D, 3D, explanation, transfer, and receipt artifacts.
- `dimension_id` identifies a score, variable, residual, probability, interval, class, cluster, or distance.
- `evidence_id` identifies exactly one observation-dimension value and links it to provenance.

## Required provenance

Each artifact records the analysis engine and call, deterministic seed, R version, package versions, and artifact hash. Adapters may include method-specific metadata such as PCA loadings, regression coefficients, GLM threshold, or k-means centers.

## Extension contract

An adapter implements `as_rlearnxr_evidence.<class>()`, calls the internal evidence builder, and never reimplements model estimation. It must produce finite numeric evidence, stable unique labels, valid links, and deterministic JSON for the same input and environment.

Schema changes require two maintainer approvals and a fixture migration. See `governance/SCHEMA-GOVERNANCE.md`.
