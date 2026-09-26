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
await Promise.all([...document.images].filter(image => image.id !== "viewer-image").map(image => { image.loading = 'eager'; return image.decode(); }));
assert(document.documentElement.scrollWidth <= innerWidth, 'Horizontal overflow');
assert(document.title.includes('Miss Dee'), 'Wrong recipient');
assert(!/smash|ritu|ice cream/i.test(document.body.textContent), 'Obsolete copy');
const book = document.getElementById('story');
assert(!book.open, 'Long story must start closed');
assert(document.querySelectorAll('.book-page').length === 3, 'Missing chapters');
assert(document.querySelectorAll('.story-scene').length === 19, 'Missing story scenes');
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
  assert(document.getElementById('quiz-position').hidden, 'Question count remains after quiz completion');
  assert(document.querySelectorAll('.collected').length === 1, 'Quiz stamp duplicated');
  document.getElementById('quiz-replay').click();
  assert(next.disabled && !document.querySelector('.quiz input:checked'), 'Replay not reset');
  assert(!document.getElementById('quiz-position').hidden && document.getElementById('quiz-position').textContent.includes('QUESTION 1 OF 4'), 'Replay does not restore question progress');
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
for (const note of document.querySelectorAll('details:not(#story)')) {
 note.querySelector('summary').click();
 assert(note.open, 'Note does not expand');
 assert(document.documentElement.scrollWidth <= innerWidth, 'Open detail overflows');
 await tick();
 note.querySelector('summary').click();
}
assert(document.querySelectorAll('.collected').length === 3, 'Missing keepsake stamps');
assert(document.getElementById('stamp-note').textContent.includes('3 of 4'), 'Final stamp state missing');
assert(!localStorage.length && !sessionStorage.length, 'Unexpected persistent state');

const tiles = [...document.querySelectorAll('.pair-tile')];
const first = tiles[0], wrong = tiles.find(t => t.dataset.pair !== first.dataset.pair);
first.click(); wrong.click();
assert(first.classList.contains('is-flipped') && wrong.classList.contains('is-flipped'), 'Mismatch not shown');
document.getElementById('reset-pairs').click();
assert(tiles.every(t => !t.classList.contains('is-flipped')), 'Reset during mismatch failed');
for (const id of new Set(tiles.map(t => t.dataset.pair))) {
  const pair = tiles.filter(t => t.dataset.pair === id);
  pair[0].click(); pair[0].click();
  assert(!pair[0].disabled, 'Same tile incorrectly matched itself');
  pair[1].click();
  assert(pair.every(t => t.disabled && t.classList.contains('is-matched')), 'Pair did not match');
}
assert(document.querySelectorAll('.collected').length === 4, 'Photo-game stamp missing');
assert(document.getElementById('stamp-note').textContent.includes('All four'), 'Complete stamps message');
document.getElementById('reset-pairs').click();
assert(tiles.every(t => !t.disabled), 'Matched game replay failed');
const moments = [...document.querySelectorAll('[data-media-id]')];
assert(moments.length === 109 && new Set(moments.map(m=>m.dataset.mediaId)).size === 109, 'Story duplicates or loses media');
assert(!moments.some(m=>['879','876'].includes(m.dataset.mediaId)), 'Removed media still appears');
book.querySelector('summary').click();
await tick();
assert(book.open, 'Book does not open');
const chapterButtons = [...document.querySelectorAll('[data-book-chapter]')];
for (const [i, button] of chapterButtons.entries()) {
  button.click();
  assert(document.querySelectorAll('.book-page:not([hidden])').length === 1, 'Reader shows multiple chapters');
  assert(!document.getElementById(`story-chapter-${i}`).hidden, 'Wrong chapter shown');
  assert(button.getAttribute('aria-current') === 'page', 'Current chapter not announced');
  assert(document.documentElement.scrollWidth <= innerWidth, 'Story overflows horizontally');
}
assert(document.getElementById('next-chapter').disabled, 'Next enabled at final chapter');
document.getElementById('previous-chapter').click();
assert(chapterButtons[1].getAttribute('aria-current') === 'page', 'Previous chapter failed');
chapterButtons[0].click();
assert(document.getElementById('previous-chapter').disabled, 'Previous enabled at first chapter');
await new Promise(resolve => setTimeout(resolve, 2200));
document.getElementById('next-chapter').scrollIntoView({behavior: 'instant'});
document.getElementById('next-chapter').click();
await new Promise(resolve => setTimeout(resolve, 2200));
const chapterHeading = document.querySelector('.book-page:not([hidden]) h2').getBoundingClientRect();
const contentsBottom = document.querySelector('.book-contents').getBoundingClientRect().bottom;
assert(chapterHeading.top >= contentsBottom && chapterHeading.bottom < innerHeight, 'Chapter turn leaves heading offscreen or under sticky navigation');
chapterButtons[0].click();
const scene = document.querySelector('.story-scene');
const photo = scene.querySelector('[data-photo]');
photo.focus(); photo.click();
const viewer = document.getElementById('photo-viewer');
const image = document.getElementById('viewer-image');
assert(viewer.open, 'Full-size photo viewer did not open');
await image.decode();
const original = image.src;
assert(document.getElementById('viewer-previous').disabled, 'Previous photo enabled at boundary');
document.getElementById('viewer-next').click();
await image.decode();
assert(image.src !== original, 'Next photo did not change');
viewer.dispatchEvent(new KeyboardEvent('keydown', {key: 'ArrowLeft', bubbles: true}));
assert(image.src === original, 'Keyboard previous photo did not return');
while (!document.getElementById('viewer-next').disabled) document.getElementById('viewer-next').click();
const scenePhotos = scene.querySelectorAll('[data-photo]').length;
assert(document.getElementById('viewer-position').textContent === `${scenePhotos} of ${scenePhotos}`, 'Viewer left its story scene');
await image.decode();
document.querySelector('.viewer-close').click();
assert(!viewer.open && document.activeElement === photo, 'Viewer close or focus restoration failed');
document.getElementById('close-story').click();
assert(!book.open && document.activeElement === book.querySelector('summary'), 'Book close or focus return failed');
book.querySelector('summary').click();
assert(document.querySelectorAll('audio').length === 5 && document.querySelectorAll('video').length === 9, 'Missing recordings');
assert([...document.querySelectorAll('audio,video')].every(p => !p.autoplay && p.preload === 'none'), 'Unexpected autoplay or preload');
assert([...document.querySelectorAll('video')].every(v => v.querySelector('track[kind="captions"]')), 'Missing caption track');

const video = document.querySelector('video');
assert(!video.autoplay && video.preload === 'none', 'Video downloads or plays automatically');
return `PASS ${innerWidth}px: images, layout, quiz correct/wrong/replay, selections, question cycle, letter, stamps, book disclosure/chapters, story media, full-size viewer, photo pairs`;
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
agent-browser eval "if (getComputedStyle(document.querySelector('.book-cover')).animationName !== 'none') throw new Error('Reduced motion failed'); document.querySelector('#letter summary').click();" >/dev/null
printf '%s\n' 'PASS: compatibility redirects, direct letter, reduced-motion book.'
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
 doc.getElementById('story').querySelector('summary').click();
 if (!doc.getElementById('story').open || [...doc.querySelectorAll('.book-page')].some(p => p.hidden)) throw Error('No-JS story chapters unavailable');
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

agent-browser open "$base/miss-dee/" >/dev/null
agent-browser eval "if(performance.getEntriesByType('resource').some(r=>/\\.(mp4|m4a)(\\?|$)/.test(r.name))) throw Error('Recording downloaded before playback');" >/dev/null
agent-browser click '.book-invitation' >/dev/null
agent-browser eval --stdin <<'JS'
(async()=>{
 const recordings=[...document.querySelectorAll('audio,video')];
 for(const player of recordings){
  const page=player.closest('.book-page');
  document.querySelector(`[aria-controls="${page.id}"]`).click();
  player.muted=true;
  await player.play();
  if(!(player.duration>0 && player.readyState>=2)) throw Error('Undecodable recording');
  if(recordings.filter(p=>!p.paused).length!==1) throw Error('Overlapping playback');
 }
 recordings.forEach(p=>p.pause());
 for (const track of document.querySelectorAll('track')) {
  const response=await fetch(track.src);
  if(!response.ok || !(await response.text()).startsWith('WEBVTT')) throw Error('Missing captions');
 }
 return 'PASS: no recordings preloaded; 9 videos and 5 voice notes decode/play; one player at a time; caption files load';
})();
JS
