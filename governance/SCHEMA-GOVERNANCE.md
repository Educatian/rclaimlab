# Evidence schema governance

1. Open an RFC describing the learner, author, or interoperability problem.
2. Include before/after fixtures, migration impact, accessibility impact, and deterministic-hash impact.
3. Obtain statistical-method review when the meaning of evidence changes.
4. Obtain accessibility review when fallback semantics or interaction identity changes.
5. Obtain both core-maintainer approvals for a public API or schema change.
6. Merge only after old and new fixtures, five reference lessons, browser checks, and package checks pass.
7. Record the decision in NEWS and publish a schema changelog.

Patch releases may clarify documentation but cannot change required fields or semantics. Minor releases may add optional fields. Required-field or meaning changes require a major schema version.
