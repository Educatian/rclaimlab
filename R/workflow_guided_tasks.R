# Pedagogy shared by local authoring and compiled workspaces, not demo-only copy.
guided_workflow_task <- function(type, question) {
  prompts <- c(
    frame = paste0("Before revealing evidence, predict a pattern and explain your reasoning. Question: ", question),
    inspect = "Explore the linked table and visualizations. Identify the variables, a pattern, and an observation that challenges your prediction.",
    transform = "Read the available R source. Explain what the selected variables and analysis commands do, and connect their output to the evidence table.",
    explain = "Compare the evidence with your prediction. Cite a selected observation, explain the pattern, and state a limitation.",
    revise = "Identify an unsupported inference in your explanation. Repair it using evidence and describe what changed.",
    challenge = "Apply the idea to a different dataset or context. Name the new variables, map their roles, and identify an assumption you must recheck before running R.",
    reproduce = "Use the recorded R source and provenance to rerun the analysis locally. Record checks or differences; viewing code alone is not reproduction.",
    handoff = "Reflect on what changed in your understanding. Share the evidence, revised explanation, transfer plan, and local receipt with unresolved questions."
  )
  criteria <- list(
    frame = c(prediction = "States a prediction before inspecting results", reasoning = "Explains the prediction"),
    inspect = c(observation = "Identifies a linked observation", pattern = "Describes a pattern and exception"),
    transform = c(code = "Explains an R command", evidence = "Connects the command output to evidence"),
    explain = c(evidence = "Cites evidence", comparison = "Compares the prediction with results", limitation = "States a limitation"),
    revise = c(repair = "Revises an unsupported inference", reason = "Explains the revision"),
    challenge = c(context = "Names a new context", mapping = "Maps variable roles", assumption = "Names an assumption to recheck"),
    reproduce = c(rerun = "Records actual rerun checks or remaining differences"),
    handoff = c(reflection = "Explains changed understanding", evidence = "Includes traceable evidence and unresolved questions")
  )
  list(prompt = unname(prompts[[type]]), criteria = criteria[[type]])
}
