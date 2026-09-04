(() => {
  "use strict";
  const contract = RCLAIMLAB_WORKFLOW;
  const workflow = contract.workflow;
  const evidence = contract.evidence;
  const quest = contract.code_quest || {};
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
    taskNotes: stored.taskNotes && typeof stored.taskNotes === "object" ? stored.taskNotes : {},
    predictionRevealed: stored.predictionRevealed === true,
    challenge: stored.challenge || "",
    handoffTo: stored.handoffTo || null,
    focusMode: stored.focusMode !== false,
    railCollapsed: stored.railCollapsed === true,
    guideCollapsed: stored.guideCollapsed !== false,
    questCode: stored.questCode || quest.code || "",
    questHistory: Array.isArray(stored.questHistory) ? stored.questHistory : [],
    questRun: stored.questRun || null,
    questCodeHash: stored.questCodeHash || (quest.receipt && quest.receipt.code_hash) || "",
    questInterpretation: stored.questInterpretation || "",
    questPinned: stored.questPinned || null,
    events: Array.isArray(stored.events) ? stored.events : [],
    eventSequence: Number.isFinite(Number(stored.eventSequence)) ? Number(stored.eventSequence) : (Array.isArray(stored.events) ? stored.events.length : 0)
  };
  const pageSize = 25;
  let page = 0;
  let view = "table";
  let angle = -.55;
  let dragging = false;
  let dragX = 0;
  let projected = [];
  let canvasIndex = 0;
  const $ = id => document.getElementById(id);
  const text = (id, value) => { const node = $(id); if (node) node.textContent = value == null || value === "" ? "Not declared" : String(value); };
  const save = () => localStorage.setItem(stateKey, JSON.stringify(state));
  const logEvent = (type, payload = {}) => {
    state.eventSequence += 1;
    state.events.push({
      event_id: `${workflow.id}-${String(state.eventSequence).padStart(4, "0")}`,
      type,
      occurred_at: new Date().toISOString(),
      activity_id: state.active || null,
      evidence_id: state.selected || (state.questPinned && state.questPinned.target) || null,
      ...payload
    });
    if (state.events.length > 500) state.events = state.events.slice(-500);
    save();
  };
  const formatValue = value => {
    if (value == null) return "";
    const numeric = Number(value);
    return Number.isFinite(numeric) && String(value).trim() !== "" ? numeric.toLocaleString(undefined, { maximumFractionDigits: 4 }) : String(value);
  };
  const escapeHtml = value => String(value == null ? "" : value).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));
  const escapeRegex = value => String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const icon = name => `<span class="rci rci-${name}" aria-hidden="true"></span>`;
  const activityIcon = type => ({ frame: "bullseye", inspect: "eye", clean: "filter", transform: "code-branch", describe: "chart-column", compare: "chart-line", split: "code-branch", baseline: "bullseye", fit: "chart-line", diagnose: "clipboard-check", evaluate: "clipboard-check", slice: "people-group", explain: "comment-dots", challenge: "shuffle", revise: "rotate", communicate: "quote-right", reproduce: "rotate", handoff: "share-nodes", approve: "circle-check", verify_source: "database" }[type] || "file-lines");

  text("role-badge", workflow.role_label);
  text("workflow-title", workflow.title);
  text("workflow-question", workflow.question);
  text("rail-title", workflow.role_label);
  const rolePresentation = RCLAIMLAB_PRESENTATION.profile(workflow.role);
  text("role-path", `${workflow.role_label} · ${rolePresentation.path}`);
  text("role-purpose", rolePresentation.goal);
  text("role-output", `Your output: ${rolePresentation.output}. Analysis runs in local R.`);
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
  text("quest-title", quest.title);
  text("quest-prompt", quest.prompt);
  text("quest-code-hash", String(state.questCodeHash || "").slice(0, 10));
  const questRVersion = String((quest.receipt && quest.receipt.r_version) || contract.execution.r_version || "Recorded");
  text("quest-r-version", (questRVersion.match(/R version\s+([^\s]+)/) || [null, questRVersion])[1]);
  text("quest-seed", (quest.receipt && quest.receipt.seed) || contract.execution.seed || 2026);
  text("quest-rows", quest.receipt && quest.receipt.rows);
  if ($("quest-code")) $("quest-code").value = state.questCode;
  if ($("quest-interpretation")) $("quest-interpretation").value = state.questInterpretation;

  const metricEntries = Array.isArray(evidence.metrics) ? evidence.metrics : [];
  ["one", "two", "three"].forEach((slot, index) => {
    const metric = metricEntries[index] || { label: index === 0 ? "Evidence rows" : index === 1 ? "Analysis" : "Seed", value: index === 0 ? evidence.total_rows : index === 1 ? evidence.engine : (contract.execution.seed || 2026) };
    text(`metric-${slot}-label`, metric.label);
    text(`metric-${slot}-value`, formatValue(metric.value));
  });

  function renderActivities() {
    const list = $("activity-list");
    list.innerHTML = "";
    let group = null;
    let previousGroup = null;
    activities.forEach((activity, index) => {
      const presentation = RCLAIMLAB_PRESENTATION.activity(workflow.role, activity);
      const groupName = presentation.phase;
      if (groupName !== previousGroup) {
        group = document.createElement("section");
        group.className = "activity-group";
        const label = document.createElement("div");
        label.className = "activity-group-label";
        label.textContent = groupName;
        group.appendChild(label);
        list.appendChild(group);
        previousGroup = groupName;
      }
      const button = document.createElement("button");
      button.type = "button";
      button.className = `activity-button${activity.id === state.active ? " active" : ""}${state.complete[activity.id] ? " complete" : ""}`;
      if (activity.id === state.active) button.setAttribute("aria-current", "step");
      button.setAttribute("aria-label", `${index + 1}. ${presentation.label}${state.complete[activity.id] ? ", complete" : ""}`);
      button.innerHTML = `<span class="activity-index">${icon(state.complete[activity.id] ? "check" : activityIcon(activity.type))}</span><span class="activity-name">${escapeHtml(presentation.label)}</span><span class="activity-state">${state.complete[activity.id] ? "Done" : ""}</span>`;
      button.addEventListener("click", () => openActivity(activity));
      group.appendChild(button);
    });
    text("rail-progress", `${Object.values(state.complete).filter(Boolean).length} of ${activities.length} activities complete`);
  }

  function openActivity(activity) {
    state.active = activity.id;
    state.screen = "focus";
    logEvent("activity_opened", {activity_type: activity.type});
    renderActivities(); renderActive(); renderScreen();
    $("active-title").focus({preventScroll: true});
  }

  function renderActive() {
    const activity = activities.find(item => item.id === state.active) || activities[0];
    if (!activity) return;
    const presentation = RCLAIMLAB_PRESENTATION.activity(workflow.role, activity);
    const index = activities.indexOf(activity);
    text("active-type", presentation.phase);
    text("active-title", presentation.label);
    text("activity-position", `Step ${index + 1} of ${activities.length} · ${presentation.label}`);
    text("activity-action", presentation.target === "code" ? "View available R source" : presentation.action);
    $("activity-action-help").hidden = presentation.target !== "code";
    text("activity-action-help", "Opens bundled R source. Some examples contain excerpts; full analysis reruns require local R.");
    text("task-note-label", presentation.note);
    $("task-note").value = state.taskNotes[activity.id] || "";
    text("task-note-status", "Local draft · included in your downloaded receipt");
    const next = activities[index + 1];
    text("next-activity", next ? `Next: ${RCLAIMLAB_PRESENTATION.activity(workflow.role, next).label}` : "Review outputs and receipt");
    const predictFirst = workflow.role === "guided_learning" && activity.type === "frame" && !state.predictionRevealed;
    document.body.classList.toggle("prediction-first", predictFirst);
    $("reveal-evidence").hidden = !predictFirst;
    text("active-prompt", activity.prompt);
    const criteria = $("active-criteria");
    criteria.innerHTML = "";
    const criteriaItems = Array.isArray(activity.criteria)
      ? activity.criteria
      : activity.criteria && typeof activity.criteria === "object"
        ? Object.values(activity.criteria)
        : activity.criteria
          ? [activity.criteria]
          : [];
    criteriaItems.forEach(value => { const li = document.createElement("li"); li.textContent = value; criteria.appendChild(li); });
    const complete = $("complete-activity");
    const evidenceReady = Boolean(state.selected || state.questPinned);
    const canComplete = !activity.evidence_required || evidenceReady || Boolean(state.complete[activity.id]);
    complete.classList.toggle("complete", Boolean(state.complete[activity.id]));
    complete.disabled = !canComplete;
    complete.setAttribute("aria-disabled", String(!canComplete));
    complete.textContent = state.complete[activity.id] ? "Completed" : canComplete ? "Mark complete" : "Select evidence first";
    $("claim-input").value = state.claims[activity.id] || "";
    $("boundary-input").value = state.boundaries[activity.id] || (workflow.role === "guided_learning" || workflow.role === "data_analyst" ? "These observations do not establish a causal or population-level conclusion." : "This is predictive evidence, not a causal conclusion.");
    renderClaimQuality();
  }

  function renderScreen() {
    document.querySelectorAll("[data-workspace-screen]").forEach(section => {
      const active = section.dataset.workspaceScreen === state.screen;
      section.hidden = !active;
      section.classList.toggle("active", active);
    });
    document.querySelectorAll(".workspace-nav-button").forEach(button => {
      const active = button.dataset.screen === state.screen;
      button.classList.toggle("active", active);
      if (active) button.setAttribute("aria-current", "page"); else button.removeAttribute("aria-current");
    });
    document.body.classList.toggle("focus-hidden", !state.focusMode);
    document.body.classList.toggle("rail-collapsed", state.railCollapsed);
    document.body.classList.toggle("guide-collapsed", state.guideCollapsed);
    document.body.classList.toggle("quest-mode", state.screen === "quest");
    $("focus-mode").checked = state.focusMode;
    $("toggle-rail").setAttribute("aria-expanded", String(!state.railCollapsed));
    $("toggle-rail").setAttribute("aria-label", state.railCollapsed ? "Expand workflow rail" : "Collapse workflow rail");
    $("toggle-rail").textContent = state.railCollapsed ? "Expand" : "Collapse";
    $("toggle-quest-guide").setAttribute("aria-expanded", String(!state.guideCollapsed));
    if (state.screen === "quest") renderQuest();
    if (state.screen === "trace") renderTrace();
    if (state.screen === "claim") renderClaimEvidence();
    if (state.screen === "handoff") { renderDeliverables(); renderHandoffTruth(); }
    window.scrollTo({ top: 0, behavior: "auto" });
  }

  document.querySelectorAll("[data-screen]").forEach(button => button.addEventListener("click", () => { state.screen = button.dataset.screen; save(); renderScreen(); }));
  $("task-note").addEventListener("input", () => {
    state.taskNotes[state.active] = $("task-note").value.slice(0, 6000);
    try { save(); text("task-note-status", "Saved locally · included in your downloaded receipt"); }
    catch (_) { text("task-note-status", "Browser storage unavailable. Download your receipt before leaving."); }
  });
  $("reveal-evidence").addEventListener("click", () => {
    state.predictionRevealed = true; save(); renderActive();
    $("evidence-heading").scrollIntoView({block:"center"});
  });
  $("next-activity").addEventListener("click", () => {
    const next = activities[activities.findIndex(item => item.id === state.active) + 1];
    if (next) openActivity(next);
    else { state.screen = "handoff"; save(); renderScreen(); }
  });
  $("activity-action").addEventListener("click", () => {
    const activity = activities.find(item => item.id === state.active) || activities[0];
    if (!activity) return;
    const target = RCLAIMLAB_PRESENTATION.activity(workflow.role, activity).target;
    if (target === "code") { $("view-r-code").click(); return; }
    state.screen = ["trace", "quest", "claim", "handoff"].includes(target) ? target : "focus";
    save(); renderScreen();
    if (target === "note") $("task-note").focus();
    if (target === "claim") $("claim-input").focus();
    if (target === "table") {
      document.querySelector('[data-view="table"]').click();
      const first = $("evidence-table-body").querySelector("tr");
      if (first) first.focus();
    }
    if (target === "metrics") document.querySelector(".metric-strip").scrollIntoView({block:"center"});
  });
  $("toggle-rail").addEventListener("click", () => { state.railCollapsed = !state.railCollapsed; save(); renderScreen(); });
  $("toggle-quest-guide").addEventListener("click", () => { state.guideCollapsed = !state.guideCollapsed; save(); renderScreen(); });
  $("focus-mode").addEventListener("change", event => { state.focusMode = event.target.checked; save(); renderScreen(); });
  $("complete-activity").addEventListener("click", () => {
    const activity = activities.find(item => item.id === state.active) || activities[0];
    if (activity && activity.evidence_required && !state.selected && !state.questPinned && !state.complete[activity.id]) return;
    state.complete[state.active] = !state.complete[state.active];
    logEvent(state.complete[state.active] ? "activity_completed" : "activity_reopened", { activity_type: activity.type });
    renderActivities(); renderActive();
  });

  const columns = rows.length ? Object.keys(rows[0]) : [];
  const learnerColumns = columns.filter(column => !["observation_id", "label"].includes(column));
  function recordLabel(row) {
    const label = String((row && row.label) || "");
    if (label && !/^(src|obs)-/i.test(label)) return label;
    const index = rows.indexOf(row);
    return `Record ${index >= 0 ? index + 1 : ""}`.trim();
  }
  function renderTable() {
    const head = $("evidence-table-head");
    head.innerHTML = `<tr><th scope="col">Record</th>${learnerColumns.map(column => `<th scope="col">${escapeHtml(column.replaceAll("_", " "))}</th>`).join("")}</tr>`;
    const body = $("evidence-table-body");
    body.innerHTML = "";
    const start = page * pageSize;
    rows.slice(start, start + pageSize).forEach(row => {
      const tr = document.createElement("tr");
      const id = String(row.observation_id || row.label || "");
      tr.tabIndex = 0;
      tr.setAttribute("aria-selected", String(id === state.selected));
      tr.dataset.observationId = id;
      tr.classList.toggle("selected", id === state.selected);
      tr.innerHTML = `<th scope="row">${escapeHtml(recordLabel(row))}</th>${learnerColumns.map(column => `<td>${escapeHtml(formatValue(row[column]))}</td>`).join("")}`;
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
  function selectRow(row, restoreFocus = false, recordEvent = true) {
    state.selected = String(row.observation_id || row.label || "");
    if (recordEvent) logEvent("evidence_selected", { artifact_id: evidence.primary_artifact, artifact_hash: evidence.artifact_hash, representation: view }); else save();
    text("selected-label", recordLabel(row));
    text("selected-id", `Linked ${evidence.primary_artifact} · ${String(evidence.artifact_hash).slice(0, 12)}`);
    renderTable();
    renderActive();
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
  $("evidence-canvas").addEventListener("keydown", event => { if (!rows.length) return; if (event.key === "ArrowRight" || event.key === "ArrowDown") { event.preventDefault(); canvasIndex = (canvasIndex + 1) % rows.length; selectRow(rows[canvasIndex]); } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") { event.preventDefault(); canvasIndex = (canvasIndex - 1 + rows.length) % rows.length; selectRow(rows[canvasIndex]); } else if (event.key === "Enter" || event.key === " ") { event.preventDefault(); selectRow(rows[canvasIndex]); } });
  document.querySelectorAll(".view-tab").forEach(button => button.addEventListener("click", () => { view = button.dataset.view; logEvent("representation_changed", { representation: view }); document.querySelectorAll(".view-tab").forEach(item => { const active = item === button; item.classList.toggle("active", active); item.setAttribute("aria-pressed", String(active)); }); $("table-panel").hidden = view !== "table"; $("canvas-panel").hidden = view === "table"; if (view !== "table") drawCanvas(); }));

  const questCandidates = Array.isArray(quest.candidates) ? quest.candidates : [];
  const questMetric = quest.mode === "classification_slice" ? "error_rate" : "value";
  function questCandidate(value) { return questCandidates.find(item => String(item.label || item.id) === String(value) || String(item.id) === String(value)); }
  function questValueFromCode(code) {
    const variable = escapeRegex(quest.editable_variable || "target_group");
    const match = String(code).match(new RegExp(`${variable}\\s*<-\\s*["']([^"']+)["']`));
    return match ? match[1] : null;
  }
  function questInterpretationChecks() {
    const value = state.questInterpretation.trim();
    const targetNamed = !quest.interpretation || quest.interpretation.require_group === false || value.toLowerCase().includes(String(quest.target || "").toLowerCase());
    const terms = (quest.interpretation && quest.interpretation.boundary_terms) || [];
    const boundary = terms.some(term => value.toLowerCase().includes(String(term).toLowerCase()));
    const lengthOk = value.length >= Number((quest.interpretation && quest.interpretation.minimum_characters) || 30);
    return { result: targetNamed && lengthOk, boundary: boundary && lengthOk };
  }
  function questRunIsTarget() { return Boolean(state.questRun && state.questRun.valid && String(state.questRun.target) === String(quest.target)); }
  function questDisplayValue(candidate) {
    const value = Number(candidate && candidate[questMetric]);
    return Number.isFinite(value) ? (questMetric === "error_rate" ? `${(value * 100).toFixed(1)}%` : formatValue(value)) : "—";
  }
  function renderQuest() {
    const run = state.questRun;
    const checks = questInterpretationChecks();
    const correct = questRunIsTarget();
    const canPin = correct && checks.result && checks.boundary;
    const maxValue = Math.max(...questCandidates.map(item => Number(item[questMetric]) || 0), 1e-9);
    const bars = $("quest-bars");
    bars.innerHTML = questCandidates.map(candidate => {
      const value = Number(candidate[questMetric]) || 0;
      const revealed = Boolean(run && run.valid);
      const classes = ["quest-bar", revealed ? "revealed" : "", String(candidate.label || candidate.id) === String(quest.target) ? "target" : ""].filter(Boolean).join(" ");
      return `<div class="${classes}"><span class="quest-bar-track"><span class="quest-bar-fill" style="height:${Math.max(4, value / maxValue * 100)}%"></span></span><span class="quest-bar-value">${revealed ? escapeHtml(questDisplayValue(candidate)) : "?"}</span><span class="quest-bar-label">${escapeHtml(candidate.label || candidate.id)}</span></div>`;
    }).join("");
    bars.setAttribute("aria-label", run && run.valid ? `R-computed comparison. ${quest.target} is the target result.` : "Evidence is hidden until valid R code is run.");
    $("quest-table-body").innerHTML = questCandidates.map(candidate => {
      const label = String(candidate.label || candidate.id);
      const current = run && String(run.target) === label;
      const target = label === String(quest.target);
      const status = run && run.valid ? (target ? "Largest eligible result" : "Compared") : "Locked until run";
      return `<tr class="${current ? "current " : ""}${target && run && run.valid ? "target" : ""}"><th scope="row">${escapeHtml(label)}</th><td>${escapeHtml(candidate.n == null ? "—" : candidate.n)}</td><td>${run && run.valid ? escapeHtml(questDisplayValue(candidate)) : "Hidden"}</td><td>${escapeHtml(status)}</td></tr>`;
    }).join("");
    const loopState = state.questPinned ? 6 : canPin ? 4 : run && run.valid ? 3 : state.questCode !== quest.code ? 2 : 1;
    const loopIcons = ["eye", "code", "play", "comment-dots", "thumbtack"];
    $("quest-loop").innerHTML = (quest.loop || []).map((label, index) => `<li class="${index + 1 < loopState ? "complete" : index + 1 === loopState ? "active" : ""}"><span class="quest-loop-icon rci rci-${index + 1 < loopState ? "check" : loopIcons[index] || "circle-check"}" aria-hidden="true"></span><span>${escapeHtml(label)}</span></li>`).join("");
    $("quest-code-state").classList.toggle("verified", correct);
    $("quest-verified").classList.toggle("verified", correct);
    text("quest-code-state", run ? (run.valid ? "R run recorded" : "Check code") : "Not run");
    text("quest-verified", correct ? "Clue verified by R" : run && run.valid ? "Valid run · compare" : "Awaiting R run");
    if (!run) text("quest-output", "Edit the quoted target in the R code, then run it.");
    else if (!run.valid) text("quest-output", run.message);
    else if (correct) text("quest-output", `R returned ${run.target}: ${questDisplayValue(run.candidate)}. This is the largest eligible result.`);
    else text("quest-output", `R returned ${run.target}: ${questDisplayValue(run.candidate)}. Compare it with the other eligible candidates.`);
    $("quest-output").classList.toggle("verified", correct);
    $("quest-rubric-result").classList.toggle("pass", checks.result);
    $("quest-rubric-boundary").classList.toggle("pass", checks.boundary);
    $("quest-rubric-run").classList.toggle("pass", correct);
    $("quest-pin").disabled = !canPin || Boolean(state.questPinned);
    const questPinLabel = $("quest-pin").querySelector("[data-button-label]");
    if (questPinLabel) questPinLabel.textContent = state.questPinned ? "Clue pinned" : "Pin this clue";
    $("quest-continue").disabled = !state.questPinned;
    $("quest-undo").disabled = !state.questHistory.length;
    text("quest-code-hash", String(state.questCodeHash || "").slice(0, 10));
    text("quest-pin-status", state.questPinned ? "Clue pinned with its R code hash, evidence hash, interpretation, and boundary." : canPin ? "Interpretation is ready. Pin the clue to continue." : "A clue can be pinned only after a verified run and bounded interpretation.");
    const suppressed = Object.entries(quest.suppressed || {});
    text("quest-suppressed", suppressed.length ? `${suppressed.map(([id, item]) => `${id.replace(/^.*=/, "")}: n=${item.n}, hidden because it is below the minimum slice size of ${quest.minimum_n}`).join(" · ")}.` : "All displayed candidates satisfy the minimum evidence rule.");
  }
  async function hashQuestCode(code) {
    if (window.crypto && window.crypto.subtle) {
      const bytes = new TextEncoder().encode(code);
      const digest = await window.crypto.subtle.digest("SHA-256", bytes);
      return Array.from(new Uint8Array(digest)).map(value => value.toString(16).padStart(2, "0")).join("");
    }
    let hash = 2166136261;
    for (const character of code) { hash ^= character.charCodeAt(0); hash = Math.imul(hash, 16777619); }
    return `fnv1a-${(hash >>> 0).toString(16).padStart(8, "0")}`;
  }
  async function runQuest() {
    const code = $("quest-code").value;
    const requested = questValueFromCode(code);
    if (state.questRun && state.questRun.code !== code) state.questHistory.push(state.questRun.code);
    else if (!state.questRun && code !== quest.code) state.questHistory.push(quest.code);
    const candidate = requested == null ? null : questCandidate(requested);
    state.questCode = code;
    state.questCodeHash = await hashQuestCode(code);
    state.questRun = candidate ? { valid: true, target: String(candidate.label || candidate.id), candidate, code, run_at: new Date().toISOString() } : { valid: false, target: requested, code, run_at: new Date().toISOString(), message: `R contract blocked the run. Set ${quest.editable_variable} to one allowed quoted value.` };
    state.questPinned = null;
    logEvent("code_quest_run", { code_hash: state.questCodeHash, target: requested, valid: Boolean(candidate) }); renderQuest();
  }
  $("quest-code").addEventListener("input", event => { state.questCode = event.target.value; if (!state.questRun || state.questRun.code !== state.questCode) { state.questRun = null; state.questPinned = null; } save(); renderQuest(); });
  $("quest-code").addEventListener("keydown", event => { if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) { event.preventDefault(); runQuest(); } });
  $("quest-run").addEventListener("click", runQuest);
  $("quest-undo").addEventListener("click", () => { const prior = state.questHistory.pop(); if (prior != null) { state.questCode = prior; state.questRun = null; state.questPinned = null; $("quest-code").value = prior; save(); renderQuest(); } });
  $("quest-interpretation").addEventListener("input", event => { state.questInterpretation = event.target.value; state.questPinned = null; save(); renderQuest(); });
  $("quest-pin").addEventListener("click", () => {
    if (!questRunIsTarget()) return;
    const checks = questInterpretationChecks();
    if (!checks.result || !checks.boundary) return;
    const candidate = questCandidate(state.questRun.target);
    state.questPinned = { target: state.questRun.target, metric: questMetric, value: candidate[questMetric], interpretation: state.questInterpretation.trim(), artifact_id: quest.receipt.artifact_id, artifact_hash: quest.receipt.artifact_hash, code_hash: state.questCodeHash, seed: quest.receipt.seed, r_version: quest.receipt.r_version, pinned_at: new Date().toISOString() };
    logEvent("code_quest_pinned", { target: state.questPinned.target, metric: questMetric, code_hash: state.questCodeHash, artifact_hash: state.questPinned.artifact_hash }); renderQuest(); renderTrace(); renderClaimEvidence(); renderActive();
  });

  function renderTrace() {
    const row = selectedRow();
    const questClue = state.questPinned;
    document.querySelectorAll(".trace-record-id").forEach(node => { node.textContent = state.selected || (questClue && questClue.target) || "No selection"; });
    text("trace-value", row ? primaryValue(row) : questClue ? `${questClue.target} · ${questMetric}: ${formatValue(questClue.value)}` : "Select evidence");
    text("trace-mark", row ? `${view === "table" ? "table row" : view === "plot2d" ? "2D point" : "3D point"}` : questClue ? "Pinned Code Quest clue" : "Not selected");
    text("trace-claim", state.claims[state.active] ? "Draft linked" : "Not drafted");
    text("detail-record", state.selected || (questClue && questClue.target) || "None");
    text("detail-value", row ? primaryValue(row) : questClue ? `${questMetric}: ${formatValue(questClue.value)}` : "None");
  }
  const traceStageMessages = {
    source: "Original source-row pointer and dataset fingerprint.",
    prepared: "Observation retained after approved missing-value and row rules.",
    evidence: "R-computed artifact linked by record ID and artifact hash.",
    mark: "The same evidence selection represented as a table row, 2D point, or 3D point.",
    claim: "Learner or reviewer statement linked to selected evidence and a limitation."
  };
  document.querySelectorAll("[data-trace-stage]").forEach(button => button.addEventListener("click", () => {
    document.querySelectorAll("[data-trace-stage]").forEach(item => { const active = item === button; item.classList.toggle("active", active); item.setAttribute("aria-pressed", String(active)); });
    logEvent("provenance_stage_inspected", { stage: button.dataset.traceStage });
    text("trace-stage-status", traceStageMessages[button.dataset.traceStage]);
  }));
  function renderClaimEvidence() {
    const chips = $("claim-evidence-chips");
    if (!chips) return;
    const row = selectedRow();
    chips.innerHTML = row ? `<span class="evidence-chip">${icon("chart-line")}${escapeHtml(primaryValue(row))}</span><span class="evidence-chip">${icon("link")}${escapeHtml(String(evidence.artifact_hash).slice(0, 12))} · traceable</span>` : state.questPinned ? `<span class="evidence-chip">${icon("thumbtack")}${escapeHtml(state.questPinned.target)} · ${escapeHtml(questMetric)} ${escapeHtml(formatValue(state.questPinned.value))}</span><span class="evidence-chip">${icon("circle-check")}${escapeHtml(String(state.questPinned.artifact_hash).slice(0, 12))} · R verified</span>` : `<span class="evidence-chip">${icon("bullseye")}Select evidence or pin a Code Quest clue</span>`;
    renderClaimQuality();
  }
  function renderClaimQuality() {
    const claim = $("claim-input") ? $("claim-input").value.trim() : "";
    const boundary = $("boundary-input") ? $("boundary-input").value.trim() : "";
    const evidenceReady = Boolean(state.selected || state.questPinned);
    const comparisonReady = /better|worse|higher|lower|compare|than|difference/i.test(claim);
    const boundaryReady = boundary.length >= 20;
    $("rubric-evidence").classList.toggle("pass", evidenceReady);
    $("rubric-comparison").classList.toggle("pass", comparisonReady);
    $("rubric-boundary").classList.toggle("pass", boundaryReady);
    $("save-claim").disabled = !(evidenceReady && claim.length >= 12 && comparisonReady && boundaryReady);
    $("save-claim").setAttribute("aria-disabled", String($("save-claim").disabled));
    const activitiesReady = activities.every(activity => Boolean(state.complete[activity.id]));
    const savedReady = Boolean(state.claims[state.active] && state.boundaries[state.active] && evidenceReady && activitiesReady);
    $("ask-review").disabled = !savedReady;
    $("ask-review").setAttribute("aria-disabled", String(!savedReady));
  }
  $("claim-input").addEventListener("input", renderClaimQuality);
  $("boundary-input").addEventListener("input", renderClaimQuality);
  $("save-claim").addEventListener("click", () => {
    state.claims[state.active] = $("claim-input").value.trim();
    state.boundaries[state.active] = $("boundary-input").value.trim();
    logEvent("claim_saved", { claim_characters: state.claims[state.active].length, boundary_characters: state.boundaries[state.active].length }); renderClaimQuality(); renderTrace(); renderHandoffTruth();
    text("claim-status", state.claims[state.active] ? "Claim saved locally and linked to this activity." : "Add a claim before accepting it.");
  });
  document.querySelectorAll("[data-challenge]").forEach(button => button.addEventListener("click", () => { document.querySelectorAll("[data-challenge]").forEach(item => item.classList.toggle("active", item === button)); state.challenge = button.dataset.challenge; logEvent("claim_challenged", { challenge: state.challenge }); text("challenge-feedback", state.challenge); }));
  const nextRole = workflow.role === "data_analyst" ? "data_scientist" : workflow.role === "data_scientist" ? "model_reviewer" : workflow.role === "model_reviewer" ? "complete" : "instructor_review";
  const nextRoleLabel = nextRole === "data_scientist" ? "Data Scientist" : nextRole === "model_reviewer" ? "Model Reviewer" : nextRole === "instructor_review" ? "Instructor Review" : "Complete workflow";
  $("continue-reviewer").querySelector("strong").textContent = nextRole === "complete" ? "Complete reviewed workflow" : `Continue with ${nextRoleLabel}`;
  $("continue-reviewer").querySelector("span:last-child").textContent = nextRole === "complete" ? "Close the review while preserving evidence and receipt" : "Pass linked artifacts without copying raw data";
  $("ask-review").addEventListener("click", () => {
    state.handoffTo = nextRole;
    state.screen = "handoff";
    logEvent("handoff_prepared", { next_role: nextRole });
    renderScreen();
    renderHandoffTruth();
    text("handoff-action-status", `${nextRoleLabel} handoff is prepared locally with linked artifacts.`);
  });
  $("continue-reviewer").addEventListener("click", () => { state.handoffTo = nextRole; logEvent("handoff_confirmed", { next_role: nextRole }); $("continue-reviewer").querySelector("strong").textContent = `${nextRoleLabel} prepared`; text("handoff-action-status", `${nextRoleLabel} handoff is prepared locally with linked artifacts.`); });

  function renderDeliverables() {
    const deliverables = $("deliverable-list");
    if (deliverables.childElementCount) return;
    Object.entries(workflow.deliverables || {}).forEach(([name, description]) => { const item = document.createElement("div"); item.className = "deliverable"; item.innerHTML = `${icon(name.includes("script") ? "code" : name.includes("report") ? "file-lines" : name.includes("evidence") ? "link" : "folder-open")}<span><strong>${escapeHtml(name.replaceAll("_", " "))}</strong><span>${escapeHtml(description)}</span></span>`; deliverables.appendChild(item); });
  }
  function renderHandoffTruth() {
    const verification = contract.verification || {};
    const analysisVerified = verification.analysis_verified === true;
    const sourceVersionRecorded = verification.source_version_recorded === true;
    const licenseDeclared = verification.license_declared === true;
    const publicationReady = verification.publication_ready === true;
    const evidenceLinked = Boolean(state.selected || state.questPinned);
    const activitiesReady = activities.every(activity => Boolean(state.complete[activity.id]));
    const claimReviewed = evidenceLinked && Object.values(state.claims).some(value => String(value || "").trim().length > 0);
    const limitationRecorded = Object.values(state.boundaries).some(value => String(value || "").trim().length >= 20);
    const handoffReady = analysisVerified && sourceVersionRecorded && evidenceLinked && activitiesReady && claimReviewed && limitationRecorded;
    const setCompletion = (id, complete, title, pendingTitle, completeCopy, pendingCopy) => {
      const node = $(id); if (!node) return;
      node.classList.toggle("complete", complete); node.classList.toggle("pending", !complete);
      node.querySelector("strong").textContent = complete ? title : pendingTitle;
      node.querySelector(":scope > span:last-child").textContent = complete ? completeCopy : pendingCopy;
      const stateIcon = node.querySelector(".completion-state-icon");
      if (stateIcon) stateIcon.className = `completion-state-icon rci rci-${complete ? "circle-check" : "clock"}`;
    };
    setCompletion("completion-data", sourceVersionRecorded, "Data approved", "Source record incomplete", "Source and roles recorded", "Record a source revision or content hash");
    setCompletion("completion-analysis", analysisVerified, "Analysis reproduced", "Analysis not verified", "Seed and artifact hashes recorded", "Artifact verification did not pass");
    setCompletion("completion-activities", activitiesReady, "Activities complete", "Activities pending", "Every role activity is complete", "Complete every role activity before handoff");
    setCompletion("completion-claim", claimReviewed, "Claim reviewed", "Claim review pending", "Evidence-linked claim saved", "Save an evidence-linked claim");
    setCompletion("completion-limit", limitationRecorded, "Limitations recorded", "Limitations pending", "Interpretation remains bounded", "Record an interpretation boundary");
    text("handoff-title", handoffReady ? "Your workflow is ready to hand off" : "Finish the review to prepare handoff");
    text("receipt-status-title", handoffReady ? "Receipt-ready" : "Receipt in progress");
    text("handoff-verification-text", analysisVerified ? "Analysis verified locally" : "Analysis verification incomplete");
    text("source-license", licenseDeclared ? contract.source.license : "Not declared — publication blocked");
    text("publication-status", publicationReady ? "Eligible" : licenseDeclared ? "Blocked — pin source revision" : "Blocked — add source license");
    text("artifact-verification-status", analysisVerified ? "Verified" : "Not verified");
    text("event-trail-status", `${state.events.length} local event${state.events.length === 1 ? "" : "s"}`);
    $("continue-reviewer").disabled = !handoffReady;
    $("continue-reviewer").setAttribute("aria-disabled", String(!handoffReady));
  }
  function downloadBlob(name, value, type) { const blob = new Blob([value], { type }), link = document.createElement("a"); link.href = URL.createObjectURL(blob); link.download = name; link.click(); setTimeout(() => URL.revokeObjectURL(link.href), 1000); }
  function downloadJson(name, value) { downloadBlob(name, JSON.stringify(value, null, 2), "application/json"); }
  $("export-table").addEventListener("click", () => { const csv = [columns.join(","), ...rows.map(row => columns.map(column => `"${String(row[column] == null ? "" : row[column]).replaceAll('"', '""')}"`).join(","))].join("\n"); logEvent("evidence_exported", { artifact_id: evidence.primary_artifact, row_count: rows.length }); downloadBlob(`${workflow.id}-evidence.csv`, csv, "text/csv"); text("export-status", `Evidence table exported with ${rows.length} linked rows.`); });
  [$("view-r-code"), $("open-matching-code")].forEach(button => button.addEventListener("click", () => { window.open("../analysis/workflow.R", "_blank"); text(button.id === "view-r-code" ? "export-status" : "trace-stage-status", "Requested the generated R analysis script in a new tab."); }));
  $("download-workflow-receipt").addEventListener("click", () => {
    logEvent("receipt_downloaded", { event_count: state.events.length + 1 });
    text("event-trail-status", `${state.events.length} local event${state.events.length === 1 ? "" : "s"}`);
    const receipt = { receipt_version: "1.0", schema_version: "rclaimlab-workflow-receipt-1", generated_at: new Date().toISOString(), workflow_id: workflow.id, role: workflow.role, attempt_number: 1, activity_state: state.complete, approvals: { question: true, variable_roles: true, method: true, missing_values: true, publication: false }, analysis: { question: workflow.question, method: evidence.engine }, evidence_selections: { selected_source_record_id: state.selected, artifact_hash: evidence.artifact_hash, code_quest_clue: state.questPinned }, claims: state.claims, decisions: { code_quest: state.questRun ? { target: state.questRun.target, valid: state.questRun.valid, interpretation: state.questInterpretation } : null }, limitations: Object.values(state.boundaries).filter(Boolean), unresolved_issues: state.challenge ? [state.challenge] : [], source: { provider: contract.source.provider, id: contract.source.id, revision: contract.source.revision, fingerprint: contract.source.fingerprint || null }, evidence: { bundle_hash: evidence.bundle_hash, artifacts: [{ artifact_id: evidence.primary_artifact, artifact_hash: evidence.artifact_hash }] }, learning_events: state.events, handoff: { from: workflow.role, to: state.handoffTo }, approval: "pending", reproducibility: { seed: contract.execution.seed || 2026, r_version: contract.execution.r_version || "compiled in R", source_code_hash: contract.execution.source_code_hash || null, code_quest_hash: state.questCodeHash || null }, privacy: { storage: "local", telemetry: false, raw_data_embedded: false } };
    receipt.decisions.task_notes = state.taskNotes;
    downloadJson(`${workflow.id}-workflow-receipt.json`, receipt);
    text("handoff-action-status", "Workflow receipt downloaded with evidence IDs, hashes, decisions, and limitations.");
  });

  document.querySelectorAll(".view-tab").forEach(button => button.setAttribute("aria-pressed", String(button.dataset.view === view)));
  renderActivities(); renderActive(); renderTable(); renderDeliverables(); renderQuest(); renderScreen();
  if (state.selected) { const row = selectedRow(); if (row) selectRow(row, false, false); }
})();
