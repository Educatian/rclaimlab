/* Presentation only: stable workflow IDs, evidence and engine order are untouched. */
const RCLAIMLAB_PRESENTATION = (() => {
  "use strict";
  const {profiles, common, overrides} = RCLAIMLAB_ROLE_PRESENTATION;
  function profile(role) { return profiles[role] || {path: "Workflow path", goal: "Inspect R evidence and document your decisions.", output: "Evidence and workflow receipt"}; }
  function activity(role, item) {
    const type = typeof item.type === "string" ? item.type : "activity";
    const value = (overrides[role] || {})[type] || common[type] || [type.replaceAll("_", " "), "Activities", "Record a task note", "note", "Task note"];
    return {label:value[0], phase:value[1], action:value[2], target:value[3], note:value[4]};
  }
  return {profile, activity};
})();
