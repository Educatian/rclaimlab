# Optional LLM visualization adapter

R-LearnXR keeps the R and WebR core usable without a model provider. The AI Visual Brief tab has a deterministic demo mode and can call an OpenAI-compatible server endpoint when `window.RLearnXR_LLM_ENDPOINT` is configured by the host application.

## Request

The browser sends JSON like:

```json
{
  "prompt": "Standardize the three axes and keep points with positive x.",
  "data_schema": {
    "required": ["label", "x", "y", "z"],
    "runtime": "WebR 0.6.0",
    "seed": 2026
  },
  "response_format": "rlearnxr_visualization_brief"
}
```

## Response

The endpoint must return a JSON object containing reproducible R code:

```json
{
  "title": "3D view focused on positive x values",
  "explanation": "The standardized x axis keeps observations where x > 0.",
  "axes": "x, y, z",
  "r_code": "set.seed(2026)\n...\nscene <- subset(scene, x > 0)"
}
```

The adapter rejects responses that do not include `set.seed()` and code that creates `scene`. It also rejects oversized code and common filesystem, shell, network, package-install, data-import, dynamic-evaluation, and function-construction tokens. Browser credentials are omitted from the request, and the browser sends only the learner prompt plus the public scene schema, never the learner's raw data or an API key. This is a lightweight browser guardrail, not a security boundary: the learner still reviews the code and WebR validates the returned `scene` data frame. Put authentication and provider-specific prompts in a server-side proxy, and record the model name, model version, prompt hash, and generated-code hash in the host application's provenance log.

## Grant-safe design

The optional adapter must not be required for a lesson to work and is outside the funded grant MVP. A lesson remains reproducible when the model is unavailable because the R code, seed, runtime, returned rows, artifact hash, and Quarto export are the authoritative evidence. Do not describe model-generated code as independently verified or safe to run without review.
