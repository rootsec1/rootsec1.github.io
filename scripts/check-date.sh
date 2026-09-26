#!/usr/bin/env bash
# Serve a Hugo build at the base URL first. Requires agent-browser.
set -euo pipefail
export AGENT_BROWSER_SESSION=miss-dee-check
base=${1:-http://127.0.0.1:1313}
trap 'agent-browser close >/dev/null' EXIT
for width in 320 390 430 1280; do
  agent-browser set viewport "$width" 844 >/dev/null
  agent-browser open "$base/miss-dee/" >/dev/null
  agent-browser eval --stdin <<'JS'
(async () => {
const assert = (condition, message) => { if (!condition) throw new Error(message); };
const tick = () => new Promise(resolve => setTimeout(resolve, 50));
await document.fonts.ready;
await Promise.all([...document.images].map(image => { image.loading = 'eager'; return image.decode(); }));
assert(document.documentElement.scrollWidth <= innerWidth, 'Horizontal overflow');
assert(document.title.includes('Miss Dee'), 'Wrong recipient');
assert(!/smash|ritu|ice cream/i.test(document.body.textContent), 'Obsolete copy');
const letter = document.getElementById('letter');
letter.querySelector('summary').click();
assert(letter.open, 'Letter gated by games');
letter.querySelector('summary').click();
const next = document.getElementById('quiz-next');
assert(next.disabled, 'Quiz advances without an answer');
for (let run = 0; run < 2; run++) {
  for (let index = 0; index < 4; index++) {
    const question = document.querySelector('.quiz-question:not([hidden])');
    assert(question, 'Missing quiz question');
    const value = run === 0 ? question.dataset.correct : (Number(question.dataset.correct) + 1) % 3;
    question.querySelector(`input[value="${value}"]`).click();
    assert(!next.disabled, 'Answer did not enable Next');
    assert(document.getElementById('quiz-feedback').textContent.includes(question.dataset.feedback), 'No answer explanation');
    next.click();
  }
  assert(!document.getElementById('quiz-complete').hidden, 'Quiz not completed');
  assert(document.querySelectorAll('.collected').length === 1, 'Quiz stamp duplicated');
  document.getElementById('quiz-replay').click();
  assert(next.disabled && !document.querySelector('.quiz input:checked'), 'Replay not reset');
}
const scenes = [...document.querySelectorAll('.scene-choice')];
for (const scene of scenes) scene.click();
assert(scenes.every(scene => scene.getAttribute('aria-pressed') === 'true'), 'Scene selection failed');
assert(scenes.every(scene => document.getElementById('scene-summary').textContent.includes(scene.dataset.line)), 'Ticket omits selected scene');
assert(document.documentElement.scrollWidth <= innerWidth, 'Selected ticket overflows');
for (const scene of scenes) scene.click();
assert(document.getElementById('scene-summary').textContent.startsWith('A real hello first.'), 'Empty selection not restored');
const seen = new Set();
for (let index = 0; index < 6; index++) {
 seen.add(document.querySelector('.conversation-question:not([hidden])').textContent);
 document.getElementById('draw-question').click();
}
assert(seen.size === 6, 'Question deck does not cycle');
for (const note of document.querySelectorAll('details')) {
 note.querySelector('summary').click();
 assert(note.open, 'Note does not expand');
 assert(document.documentElement.scrollWidth <= innerWidth, 'Open detail overflows');
 await tick();
 note.querySelector('summary').click();
}
assert(document.querySelectorAll('.collected').length === 3, 'Missing keepsake stamps');
assert(document.getElementById('stamp-note').textContent.includes('All three'), 'Final stamp state missing');
assert(!localStorage.length && !sessionStorage.length, 'Unexpected persistent state');
const video = document.querySelector('video');
assert(!video.autoplay && video.preload === 'none', 'Video downloads or plays automatically');
return `PASS ${innerWidth}px: images, layout, quiz correct/wrong/replay, selections, question cycle, letter, stamps`;
})();
JS
done
agent-browser open "$base/miss-dee/decision/" >/dev/null
agent-browser wait --url '**/miss-dee/' >/dev/null
agent-browser open "$base/miss-dee/decision/yes/" >/dev/null
agent-browser wait --url '**/miss-dee/yes/' >/dev/null
agent-browser eval "if (!document.getElementById('letter').open) throw new Error('Legacy reveal failed');" >/dev/null
agent-browser set media reduced-motion >/dev/null
agent-browser open "$base/miss-dee/" >/dev/null
agent-browser eval "if (getComputedStyle(document.querySelector('.premiere-poster')).animationName !== 'none') throw new Error('Reduced motion failed'); document.querySelector('#letter summary').click();" >/dev/null
printf '%s\n' 'PASS: compatibility redirects, direct letter, reduced-motion poster.'
agent-browser eval --stdin <<'JS'
(async () => {
 const html = await (await fetch('/miss-dee/')).text();
 const iframe = document.createElement('iframe');
 iframe.style.cssText = 'width:390px;height:844px';
 document.body.append(iframe);
 const load = source => new Promise(resolve => { iframe.onload = resolve; iframe.srcdoc = source; });
 await load(html.replace(/<script[^>]*>[\s\S]*?<\/script>/g, ''));
 let doc = iframe.contentDocument;
 if (doc.documentElement.classList.contains('has-js')) throw Error('Fallback incorrectly enhanced');
 if ([...doc.querySelectorAll('.quiz-question')].some(q => q.hidden)) throw Error('Fallback hides questions');
 doc.querySelector('#letter summary').click();
 if (!doc.querySelector('#letter').open) throw Error('No-JS letter failed');
 for (const [date, expected] of [['2026-09-27T03:59:00Z','See you tomorrow'], ['2026-09-27T04:01:00Z','See you today'], ['2026-09-28T04:01:00Z','To our next chapter']]) {
   const mock = `<script>const OriginalDate = Date; window.Date = class extends OriginalDate { constructor(...args) { super(...(args.length ? args : ['${date}'])); } };<\/script>`;
   await load(html.replace('<head>', '<head>' + mock));
   if (iframe.contentDocument.querySelector('[data-see-you]').textContent !== expected) throw Error('New York date rollover failed: ' + date);
 }
 iframe.remove();
 return 'PASS: no-JS reading and letter; New York midnight date rollover';
})();
JS
