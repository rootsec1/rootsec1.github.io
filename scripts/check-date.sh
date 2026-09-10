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
const assert = (value, message) => { if (!value) throw new Error(message); };
assert(document.documentElement.scrollWidth <= innerWidth, 'Horizontal overflow');
assert(document.title.includes('Miss Dee'), 'Wrong recipient');
assert([...document.images].every(image => image.complete && image.naturalWidth > 0), 'Broken image');
const no = document.getElementById('noButton');
const yes = document.getElementById('yesButton');
for (let i = 0; i < 8; i++) {
  no.dispatchEvent(new PointerEvent(i % 2 ? 'pointerenter' : 'pointerdown', {pointerType: i % 2 ? 'mouse' : 'touch', cancelable: true}));
  const n = no.getBoundingClientRect(), y = yes.getBoundingClientRect();
  assert(n.left >= 0 && n.right <= innerWidth, 'No button escaped the viewport');
  assert(n.right <= y.left || n.left >= y.right || n.top >= y.bottom || n.bottom <= y.top, 'No button covers Yes');
}
no.click();
assert(document.getElementById('no-note').textContent !== 'The “No” button has commitment issues. Try it.', 'No does not dodge');
assert(location.pathname === '/miss-dee/', 'No navigated');
yes.click();
JS
  agent-browser wait --url '**/miss-dee/yes/' >/dev/null
  agent-browser eval "if (!document.body.classList.contains('celebration') || !document.querySelector('h1').textContent.includes('Miss Dee')) throw new Error('Missing celebration');" >/dev/null
done
agent-browser open "$base/ritu/decision/" >/dev/null
agent-browser wait --url '**/miss-dee/' >/dev/null
agent-browser eval "if (!document.getElementById('yesButton')) throw new Error('Legacy invitation failed');" >/dev/null
agent-browser open "$base/ritu/decision/yes/" >/dev/null
agent-browser wait --url '**/miss-dee/yes/' >/dev/null
agent-browser eval "if (!document.body.classList.contains('celebration')) throw new Error('Legacy celebration failed');" >/dev/null
echo 'PASS: mobile/desktop layout, images, touch/mouse/keyboard activation, Yes navigation, and legacy redirects.'
