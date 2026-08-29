(() => {
  "use strict";
  const contract = RCLAIMLAB_WORKFLOW;
  const workflow = contract.workflow;
  const evidence = contract.evidence;
  const rows = Array.isArray(evidence.rows) ? evidence.rows : [];
  const activities = Array.isArray(workflow.activities) ? workflow.activities : [];
  const stateKey = `rclaimlab:workflow:${workflow.id}:${evidence.bundle_hash}`;
  const stored = (() => { try { return JSON.parse(localStorage.getItem(stateKey)) || {}; } catch (_) { return {}; } })();
  const state = {
    screen: stored.screen || "focus",
    active: stored.active || (activities[0] && activities[0].id),
    complete: stored.complete || {},
    selected: stored.selected || null,
    claims: stored.claims || {},
    boundaries: stored.boundaries || {},
    challenge: stored.challenge || "",
    handoffTo: stored.handoffTo || null,
    focusMode: stored.focusMode !== false
  };
  const pageSize = 25;
  let page = 0;
  let view = "table";
  let angle = -.55;
  let dragging = false;
  let dragX = 0;
  let projected = [];
  const $ = id => document.getElementById(id);
  const text = (id, value) => { const node = $(id); if (node) node.textContent = value == null || value === "" ? "Not declared" : String(value); };
  const save = () => localStorage.setItem(stateKey, JSON.stringify(state));
  const formatValue = value => {
    if (value == null) return "";
    const numeric = Number(value);
    return Number.isFinite(numeric) && String(value).trim() !== "" ? numeric.toLocaleString(undefined, { maximumFractionDigits: 4 }) : String(value);
  };
  const escapeHtml = value => String(value == null ? "" : value).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));

  text("role-badge", workflow.role_label);
  text("workflow-title", workflow.title);
  text("workflow-question", workflow.question);
  text("rail-title", workflow.role_label);
  text("source-provider", `${contract.source.provider} dataset`);
  text("source-id", contract.source.id);
  text("source-revision", contract.source.revision);
  text("source-license", contract.source.license);
  text("analysis-engine", evidence.engine);
  text("bundle-hash", evidence.bundle_hash);
  text("detail-artifact", evidence.artifact_hash);
  text("artifact-hash-short", String(evidence.artifact_hash || "").slice(0, 12));
  text("sample-note", `${evidence.sampled_rows} shown · ${evidence.total_rows} total`);
  text("repro-seed", contract.execution.seed || 2026);
  text("repro-environment", contract.execution.r_version || "Recorded by R");

  const metricEntries = Array.isArray(evidence.metrics) ? evidence.metrics : [];
  ["one", "two", "three"].forEach((slot, index) => {
    const metric = metricEntries[index] || { label: index === 0 ? "Evidence rows" : index === 1 ? "Analysis" : "Seed", value: index === 0 ? evidence.total_rows : index === 1 ? evidence.engine : (contract.execution.seed || 2026) };
    text(`metric-${slot}-label`, metric.label);
    text(`metric-${slot}-value`, formatValue(metric.value));
  });

  function groupFor(type) {
    if (["frame", "inspect", "clean", "transform", "describe", "compare", "verify_source"].includes(type)) return "Prepare";
    if (["split", "baseline", "fit", "diagnose"].includes(type)) return "Model";
    if (["evaluate", "slice", "explain", "challenge", "revise", "reproduce"].includes(type)) return "Evaluate";
    return "Communicate";
  }

  function renderActivities() {
    const list = $("activity-list");
    list.innerHTML = "";
    const groups = ["Prepare", "Model", "Evaluate", "Communicate"];
    groups.forEach(groupName => {
      const items = activities.map((activity, index) => ({ activity, index })).filter(item => groupFor(item.activity.type) === groupName);
      if (!items.length) return;
      const group = document.createElement("section");
      group.className = "activity-group";
      const label = document.createElement("div");
      label.className = "activity-group-label";
      label.textContent = groupName;
      group.appendChild(label);
      items.forEach(({ activity, index }) => {
        const button = document.createElement("button");
        button.type = "button";
        button.className = `activity-button${activity.id === state.active ? " active" : ""}${state.complete[activity.id] ? " complete" : ""}`;
        button.innerHTML = `<span class="activity-index">${String(index + 1).padStart(2, "0")}</span><span class="activity-name">${escapeHtml(activity.type.replaceAll("_", " "))}</span><span class="activity-state">${state.complete[activity.id] ? "Done" : ""}</span>`;
        button.addEventListener("click", () => { state.active = activity.id; state.screen = "focus"; save(); renderActivities(); renderActive(); renderScreen(); });
        group.appendChild(button);
      });
      list.appendChild(group);
    });
    text("rail-progress", `${Object.values(state.complete).filter(Boolean).length} of ${activities.length} activities complete`);
  }

  function renderActive() {
    const activity = activities.find(item => item.id === state.active) || activities[0];
    if (!activity) return;
    text("active-type", activity.type.replaceAll("_", " "));
    text("active-title", activity.output_type === "approval" ? "Human review decision" : activity.type.replaceAll("_", " "));
    text("active-prompt", activity.prompt);
    const criteria = $("active-criteria");
    criteria.innerHTML = "";
    Object.entries(activity.criteria || {}).forEach(([, value]) => { const li = document.createElement("li"); li.textContent = value; criteria.appendChild(li); });
    const complete = $("complete-activity");
    complete.classList.toggle("complete", Boolean(state.complete[activity.id]));
    complete.textContent = state.complete[activity.id] ? "Completed" : "Mark complete";
    $("claim-input").value = state.claims[activity.id] || "";
    $("boundary-input").value = state.boundaries[activity.id] || "This is predictive evidence, not a causal conclusion.";
    renderClaimQuality();
  }

  function renderScreen() {
    document.querySelectorAll("[data-workspace-screen]").forEach(section => {
      const active = section.dataset.workspaceScreen === state.screen;
      section.hidden = !active;
      section.classList.toggle("active", active);
    });
    document.querySelectorAll(".workspace-nav-button").forEach(button => button.classList.toggle("active", button.dataset.screen === state.screen));
    document.body.classList.toggle("focus-hidden", !state.focusMode);
    $("focus-mode").checked = state.focusMode;
    if (state.screen === "trace") renderTrace();
    if (state.screen === "claim") renderClaimEvidence();
    if (state.screen === "handoff") renderDeliverables();
    window.scrollTo({ top: 0, behavior: "auto" });
  }

  document.querySelectorAll("[data-screen]").forEach(button => button.addEventListener("click", () => { state.screen = button.dataset.screen; save(); renderScreen(); }));
  $("focus-mode").addEventListener("change", event => { state.focusMode = event.target.checked; save(); renderScreen(); });
  $("complete-activity").addEventListener("click", () => { state.complete[state.active] = !state.complete[state.active]; save(); renderActivities(); renderActive(); });

  const columns = rows.length ? Object.keys(rows[0]) : [];
  function renderTable() {
    const head = $("evidence-table-head");
    head.innerHTML = `<tr>${columns.map(column => `<th scope="col">${escapeHtml(column)}</th>`).join("")}</tr>`;
    const body = $("evidence-table-body");
    body.innerHTML = "";
    const start = page * pageSize;
    rows.slice(start, start + pageSize).forEach(row => {
      const tr = document.createElement("tr");
      const id = String(row.observation_id || row.label || "");
      tr.tabIndex = 0;
      tr.dataset.observationId = id;
      tr.classList.toggle("selected", id === state.selected);
      tr.innerHTML = columns.map(column => `<td>${escapeHtml(formatValue(row[column]))}</td>`).join("");
      tr.addEventListener("click", () => selectRow(row));
      tr.addEventListener("keydown", event => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); selectRow(row, true); } });
      body.appendChild(tr);
    });
    const pages = Math.max(1, Math.ceil(rows.length / pageSize));
    text("page-status", `Page ${page + 1} of ${pages} · ${evidence.total_rows} total rows`);
    $("previous-page").disabled = page === 0;
    $("next-page").disabled = page >= pages - 1;
  }
  $("previous-page").addEventListener("click", () => { if (page > 0) { page--; renderTable(); } });
  $("next-page").addEventListener("click", () => { if ((page + 1) * pageSize < rows.length) { page++; renderTable(); } });

  function primaryValue(row) {
    const preferred = ["predicted_probability", "fitted", "residual", "observed", "value", "label"];
    const key = preferred.find(name => Object.prototype.hasOwnProperty.call(row || {}, name)) || columns.find(name => !["observation_id", "label"].includes(name));
    return key ? `${key}: ${formatValue(row[key])}` : "Evidence selected";
  }
  function selectedRow() { return rows.find(item => String(item.observation_id || item.label || "") === state.selected); }
  function selectRow(row, restoreFocus = false) {
    state.selected = String(row.observation_id || row.label || "");
    save();
    text("selected-label", row.label || state.selected);
    text("selected-id", `${state.selected} · ${String(evidence.artifact_hash).slice(0, 12)}`);
    renderTable();
    if (restoreFocus) { const selected = $("evidence-table-body").querySelector("tr.selected"); if (selected) selected.focus(); }
    drawCanvas();
    renderTrace();
    renderClaimEvidence();
  }

  const numericColumns = columns.filter(column => !["observation_id", "label"].includes(column) && rows.some(row => Number.isFinite(Number(row[column]))));
  const axes = numericColumns.slice(0, 3);
  function normalized(column, value) { const values = rows.map(row => Number(row[column])).filter(Number.isFinite), min = Math.min(...values), max = Math.max(...values); return max === min ? .5 : (Number(value) - min) / (max - min); }
  function drawCanvas() {
    const canvas = $("evidence-canvas"), context = canvas.getContext("2d"), width = canvas.width, height = canvas.height;
    context.clearRect(0, 0, width, height);
    context.strokeStyle = "#dbe2ed";
    for (let i = 1; i < 10; i++) { context.beginPath(); context.moveTo(i * width / 10, 30); context.lineTo(i * width / 10, height - 30); context.stroke(); }
    projected = [];
    rows.forEach(row => {
      const x = normalized(axes[0], row[axes[0]]) - .5, y = axes[1] ? normalized(axes[1], row[axes[1]]) - .5 : 0, z = axes[2] ? normalized(axes[2], row[axes[2]]) - .5 : 0;
      let px, py, depth = 0;
      if (view === "scene3d") { const rx = x * Math.cos(angle) - z * Math.sin(angle); depth = x * Math.sin(angle) + z * Math.cos(angle); px = width / 2 + rx * width * .72; py = height / 2 - y * height * .72 + depth * height * .18; }
      else { px = 50 + (x + .5) * (width - 100); py = height - 50 - (y + .5) * (height - 100); }
      const selected = String(row.observation_id || row.label) === state.selected;
      projected.push({ x: px, y: py, row });
      context.beginPath(); context.arc(px, py, selected ? 7 : 4, 0, Math.PI * 2); context.fillStyle = selected ? "#13804b" : `rgba(23,87,215,${view === "scene3d" ? .45 + Math.max(0, depth) * .7 : .65})`; context.fill();
    });
    context.fillStyle = "#5c6880"; context.font = "12px system-ui"; context.fillText(axes[0] || "record", 50, height - 15);
    text("canvas-help", view === "scene3d" ? "Drag horizontally to rotate; select a point to cite it." : "Select a point to connect it with its evidence row.");
  }
  $("evidence-canvas").addEventListener("pointerdown", event => { dragging = true; dragX = event.clientX; event.currentTarget.setPointerCapture(event.pointerId); });
  $("evidence-canvas").addEventListener("pointermove", event => { if (dragging && view === "scene3d") { angle += (event.clientX - dragX) * .01; dragX = event.clientX; drawCanvas(); } });
  $("evidence-canvas").addEventListener("pointerup", event => { if (!dragging) return; dragging = false; const rect = event.currentTarget.getBoundingClientRect(), x = (event.clientX - rect.left) * event.currentTarget.width / rect.width, y = (event.clientY - rect.top) * event.currentTarget.height / rect.height, nearest = projected.map(point => ({ point, d: (point.x - x) ** 2 + (point.y - y) ** 2 })).sort((a, b) => a.d - b.d)[0]; if (nearest && nearest.d < 400) selectRow(nearest.point.row); });
  document.querySelectorAll(".view-tab").forEach(button => button.addEventListener("click", () => { view = button.dataset.view; document.querySelectorAll(".view-tab").forEach(item => item.classList.toggle("active", item === button)); $("table-panel").hidden = view !== "table"; $("canvas-panel").hidden = view === "table"; if (view !== "table") drawCanvas(); }));

  function renderTrace() {
    const row = selectedRow();
    document.querySelectorAll(".trace-record-id").forEach(node => { node.textContent = state.selected || "No selection"; });
    text("trace-value", row ? primaryValue(row) : "Select evidence");
    text("trace-mark", row ? `${view === "table" ? "table row" : view === "plot2d" ? "2D point" : "3D point"}` : "Not selected");
    text("trace-claim", state.claims[state.active] ? "Draft linked" : "Not drafted");
    text("detail-record", state.selected || "None");
    text("detail-value", row ? primaryValue(row) : "None");
  }
  function renderClaimEvidence() {
    const chips = $("claim-evidence-chips");
    if (!chips) return;
    const row = selectedRow();
    chips.innerHTML = row ? `<span class="evidence-chip">${escapeHtml(primaryValue(row))}</span><span class="evidence-chip">${escapeHtml(String(evidence.artifact_hash).slice(0, 12))} · traceable</span>` : `<span class="evidence-chip">Select evidence in Table, 2D, or 3D</span>`;
    renderClaimQuality();
  }
  function renderClaimQuality() {
    const claim = $("claim-input") ? $("claim-input").value.trim() : "";
    const boundary = $("boundary-input") ? $("boundary-input").value.trim() : "";
    $("rubric-evidence").classList.toggle("pass", Boolean(state.selected));
    $("rubric-comparison").classList.toggle("pass", /better|worse|higher|lower|compare|than|difference/i.test(claim));
    $("rubric-boundary").classList.toggle("pass", boundary.length >= 20);
  }
  $("claim-input").addEventListener("input", renderClaimQuality);
  $("boundary-input").addEventListener("input", renderClaimQuality);
  $("save-claim").addEventListener("click", () => {
    state.claims[state.active] = $("claim-input").value.trim();
    state.boundaries[state.active] = $("boundary-input").value.trim();
    save(); renderClaimQuality(); renderTrace();
    text("claim-status", state.claims[state.active] ? "Claim saved locally and linked to this activity." : "Add a claim before accepting it.");
  });
  document.querySelectorAll("[data-challenge]").forEach(button => button.addEventListener("click", () => { document.querySelectorAll("[data-challenge]").forEach(item => item.classList.toggle("active", item === button)); state.challenge = button.dataset.challenge; save(); text("challenge-feedback", state.challenge); }));
  $("ask-review").addEventListener("click", () => { state.handoffTo = "model_reviewer"; save(); text("claim-status", "Review handoff prepared locally. Open Handoff when ready."); });
  $("continue-reviewer").addEventListener("click", () => { state.handoffTo = "model_reviewer"; save(); text("continue-reviewer", "Model Reviewer handoff prepared"); });

  function renderDeliverables() {
    const deliverables = $("deliverable-list");
    if (deliverables.childElementCount) return;
    Object.entries(workflow.deliverables || {}).forEach(([name, description]) => { const item = document.createElement("div"); item.className = "deliverable"; item.innerHTML = `<strong>${escapeHtml(name.replaceAll("_", " "))}</strong><span>${escapeHtml(description)}</span>`; deliverables.appendChild(item); });
  }
  function downloadBlob(name, value, type) { const blob = new Blob([value], { type }), link = document.createElement("a"); link.href = URL.createObjectURL(blob); link.download = name; link.click(); setTimeout(() => URL.revokeObjectURL(link.href), 1000); }
  function downloadJson(name, value) { downloadBlob(name, JSON.stringify(value, null, 2), "application/json"); }
  $("export-table").addEventListener("click", () => { const csv = [columns.join(","), ...rows.map(row => columns.map(column => `"${String(row[column] == null ? "" : row[column]).replaceAll('"', '""')}"`).join(","))].join("\n"); downloadBlob(`${workflow.id}-evidence.csv`, csv, "text/csv"); });
  [$("view-r-code"), $("open-matching-code")].forEach(button => button.addEventListener("click", () => window.open("../analysis/workflow.R", "_blank")));
  $("download-workflow-receipt").addEventListener("click", () => {
    const receipt = { receipt_version: "1.0", schema_version: "rclaimlab-workflow-receipt-1", generated_at: new Date().toISOString(), workflow_id: workflow.id, role: workflow.role, attempt_number: 1, activity_state: state.complete, approvals: { question: true, variable_roles: true, method: true, missing_values: true, publication: false }, analysis: { question: workflow.question, method: evidence.engine }, evidence_selections: { selected_source_record_id: state.selected, artifact_hash: evidence.artifact_hash }, claims: state.claims, decisions: {}, limitations: Object.values(state.boundaries).filter(Boolean), unresolved_issues: state.challenge ? [state.challenge] : [], source: { provider: contract.source.provider, id: contract.source.id, revision: contract.source.revision, fingerprint: contract.source.fingerprint || null }, evidence: { bundle_hash: evidence.bundle_hash, artifacts: [{ artifact_id: evidence.primary_artifact, artifact_hash: evidence.artifact_hash }] }, handoff: { from: workflow.role, to: state.handoffTo }, approval: "pending", reproducibility: { seed: contract.execution.seed || 2026, r_version: contract.execution.r_version || "compiled in R", source_code_hash: contract.execution.source_code_hash || null }, privacy: { storage: "local", telemetry: false, raw_data_embedded: false } };
    downloadJson(`${workflow.id}-workflow-receipt.json`, receipt);
  });

  renderActivities(); renderActive(); renderTable(); renderDeliverables(); renderScreen();
  if (state.selected) { const row = selectedRow(); if (row) selectRow(row); }
})();
