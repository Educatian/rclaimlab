const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync('inst/templates/workflow-presentation.js', 'utf8');
const registry = JSON.parse(fs.readFileSync('inst/templates/workflow-presentation.json', 'utf8'));
const ui = vm.runInNewContext(source + '\nRCLAIMLAB_PRESENTATION', {RCLAIMLAB_ROLE_PRESENTATION: registry});
const sequences = {
  guided_learning: ['frame','inspect','transform','explain','revise','challenge','reproduce','handoff'],
  data_analyst: ['frame','inspect','clean','describe','compare','explain','communicate','handoff'],
  data_scientist: ['frame','inspect','clean','split','baseline','fit','diagnose','evaluate','slice','communicate','handoff'],
  model_reviewer: ['inspect','reproduce','diagnose','challenge','slice','revise','approve']
};
for (const [role, types] of Object.entries(sequences)) {
  const phases = [];
  const labels = [];
  for (const type of types) {
    const item = Object.freeze({id:'stable-' + type, type, prompt:'Author-owned prompt'});
    const result = ui.activity(role, item);
    assert.ok(['note','trace','code','table','metrics','quest','claim','handoff'].includes(result.target));
    assert.ok(result.label && result.phase && result.action && result.note);
    assert.equal(item.id, 'stable-' + type);
    assert.equal(item.prompt, 'Author-owned prompt');
    if (phases.at(-1) !== result.phase) phases.push(result.phase);
    labels.push(result.label);
  }
  assert.equal(new Set(phases).size, phases.length, role + ': phase must not recur');
  assert.equal(new Set(labels).size, labels.length);
  assert.ok(ui.profile(role).goal);
  console.log('PASS', role, labels.join(' -> '));
}
assert.equal(ui.activity('guided_learning',{type:'challenge'}).label,'Transfer');
assert.equal(ui.activity('model_reviewer',{type:'challenge'}).label,'Challenge claims');
assert.equal(ui.activity('extension_role',{type:'custom_activity'}).label,'custom activity');
assert.equal(ui.activity('guided_learning',{}).target,'note');
new vm.Script(fs.readFileSync('inst/templates/workflow.js','utf8'));
console.log('PASS presentation fallbacks and runtime syntax');
