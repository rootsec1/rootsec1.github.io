#!/usr/bin/env bash
# Build Hugo with --baseURL http://127.0.0.1:1313/ and serve public/ before running.
# Requires agent-browser.
set -euo pipefail
export AGENT_BROWSER_SESSION=miss-dee-check
base=${1:-http://127.0.0.1:1313}
trap 'agent-browser close >/dev/null' EXIT
for width in 320 390 430 1280; do
  agent-browser set viewport "$width" 844 >/dev/null
  agent-browser open "$base/miss-dee/" >/dev/null
  agent-browser eval --stdin <<'JS'
(async () => {
const assert = (value, message) => { if (!value) throw new Error(message); };
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
assert(document.documentElement.scrollWidth <= innerWidth, 'Horizontal overflow');
assert(document.title.includes('Miss Dee'), 'Wrong recipient');
assert(!/smash/i.test(document.body.textContent), 'Old wording remains');
await Promise.all([...document.images].map(image => { image.loading = 'eager'; return image.decode(); }));
assert([...document.images].every(image => image.naturalWidth > 0), 'Broken image');
const no = document.getElementById('noButton');
const yes = document.getElementById('yesButton');
const positions = new Set();
for (let i = 0; i < 5; i++) {
  const start = no.getBoundingClientRect();
  if (i % 2) {
    document.dispatchEvent(new PointerEvent('pointermove', {pointerType: 'mouse', clientX: start.left - 10, clientY: start.top + 20}));
  } else {
    no.dispatchEvent(new PointerEvent('pointerdown', {pointerType: 'touch', cancelable: true}));
  }
  await wait(90);
  const middle = no.getBoundingClientRect();
  assert(Math.hypot(middle.x - start.x, middle.y - start.y) > 1, 'Button did not animate');
  for (let frame = 0; frame < 10; frame++) {
    const n = no.getBoundingClientRect(), y = yes.getBoundingClientRect();
    assert(n.left >= 0 && n.right <= innerWidth && n.top >= 0 && n.bottom <= innerHeight, 'No button escaped the viewport');
    assert(n.right <= y.left || n.left >= y.right || n.top >= y.bottom || n.bottom <= y.top, `No button crosses Yes: ${JSON.stringify({width:innerWidth, i, start:start.toJSON(), no:n.toJSON(), yes:y.toJSON()})}`);
    await wait(45);
  }
  const end = no.getBoundingClientRect();
  assert(Math.hypot(end.x - middle.x, end.y - middle.y) > 1, 'Button snapped instead of gliding');
  positions.add(`${Math.round(end.x)},${Math.round(end.y)}`);
}
assert(positions.size >= 4, 'Not enough varied destinations');
window.dispatchEvent(new Event('resize'));
assert(!no.classList.contains('is-dodging'), 'Resize did not reset position');
no.click();
await wait(550);
assert(no.classList.contains('is-dodging'), 'Keyboard activation does not dodge');
assert(location.pathname === '/miss-dee/', 'No navigated');
window.dispatchEvent(new Event('scroll'));
assert(!no.classList.contains('is-dodging'), 'Scroll did not reset position');
for (const note of document.querySelectorAll('details')) {
  note.querySelector('summary').click();
  assert(note.open, 'Personal note did not expand');
  assert(document.documentElement.scrollWidth <= innerWidth, 'Expanded note overflows');
  note.querySelector('summary').click();
  assert(!note.open, 'Personal note did not close');
}
yes.click();
})();
JS
  agent-browser wait --url '**/miss-dee/yes/' >/dev/null
  agent-browser eval "if (!document.body.classList.contains('celebration') || !document.querySelector('h1').textContent.includes('Miss Dee')) throw new Error('Missing celebration');" >/dev/null
done
agent-browser open "$base/miss-dee/decision/" >/dev/null
agent-browser wait --url '**/miss-dee/' >/dev/null
agent-browser eval "if (!document.getElementById('yesButton')) throw new Error('Alternate invitation failed');" >/dev/null
agent-browser open "$base/miss-dee/decision/yes/" >/dev/null
agent-browser wait --url '**/miss-dee/yes/' >/dev/null
agent-browser eval "if (!document.body.classList.contains('celebration')) throw new Error('Alternate celebration failed');" >/dev/null
echo 'PASS: mobile/desktop layout, images, touch/mouse/keyboard activation, Yes navigation, and alternate-path redirects.'
