set.seed(2026)
# Deterministic 80/20 split recorded in workflow-spec.json
model <- stats::glm(outcome ~ age + hours + education, data = train, family = stats::binomial())
predictions <- stats::predict(model, newdata = test)
# Inspect evidence/artifacts/model-evidence.json for linked holdout evidence.
