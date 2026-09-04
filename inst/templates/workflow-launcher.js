(() => {
  'use strict';
  let selected = 'guided';
  const inputs = Array.from(document.querySelectorAll('input[name="role"]'));
  function select(key) {
    if (!Object.hasOwn(RCLAIMLAB_LAUNCHER, key)) key = 'guided';
    selected = key;
    const view = RCLAIMLAB_LAUNCHER[key];
    inputs.forEach(input => { input.checked = input.value === view.role; });
    document.getElementById('purpose_detail').innerHTML = view.html;
  }
  inputs.forEach(input => input.addEventListener('change', () => {
    const key = Object.keys(RCLAIMLAB_LAUNCHER).find(k => RCLAIMLAB_LAUNCHER[k].role === input.value);
    select(key);
    history.replaceState(null, '', '#' + key);
  }));
  window.addEventListener('hashchange', () => select(location.hash.slice(1)));
  document.getElementById('launch_example').addEventListener('click', () => { location.href = './modes/' + selected + '/app/'; });
  document.getElementById('wizard_next_1').addEventListener('click', () => {
    const panel = document.getElementById('own-data'); panel.hidden = false; panel.focus();
  });
  select(location.hash.slice(1));
})();
