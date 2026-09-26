// All keepsake state belongs to this visit. Nothing is sent or stored.
const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
const stamps = new Set();
function collectStamp(name) {
  if (stamps.has(name)) return;
  stamps.add(name);
  const label = document.querySelector(`[data-stamp-label="${name}"]`);
  label.classList.add("collected");
  label.setAttribute("aria-label", `${label.textContent}, collected`);
  document.getElementById("stamp-note").textContent =
    stamps.size === 3
      ? "All three collected. Strong sticker-sheet energy, madam."
      : `${stamps.size} of 3 little stamps collected. The ending is always open.`;
}

const today = new Intl.DateTimeFormat("en-CA", {
  timeZone: "America/New_York",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
}).format(new Date());
const meetingDate = document.body.dataset.meetingDate;
if (today >= meetingDate) {
  document.querySelector("[data-relative-day]").textContent =
    today === meetingDate ? "Today" : "September 27";
  if (today > meetingDate)
    document.querySelector(".opening-line").innerHTML =
      "3.9 years in the making.<br>September 27. Our opening chapter.";
  document.querySelector("[data-see-you]").textContent =
    today === meetingDate ? "See you today" : "To our next chapter";
}

const quiz = document.getElementById("quiz");
const rounds = [...quiz.querySelectorAll("fieldset")];
const next = document.getElementById("quiz-next");
const feedback = document.getElementById("quiz-feedback");
const quizPosition = document.getElementById("quiz-position");
const complete = document.getElementById("quiz-complete");
let round = 0;
function showRound() {
  rounds.forEach((field, index) => (field.hidden = index !== round));
  quizPosition.textContent = `QUESTION ${round + 1} OF ${rounds.length}`;
  feedback.textContent = "Choose an answer. Your reputation is mostly safe.";
  next.disabled = !rounds[round].querySelector("input:checked");
  next.querySelector("span").textContent =
    round === rounds.length - 1 ? "Claim my sticker" : "Next question";
}
quiz.addEventListener("change", (event) => {
  if (!event.target.matches('input[type="radio"]')) return;
  const field = rounds[round];
  const correct = event.target.value === field.dataset.correct;
  feedback.textContent = `${correct ? "" : "A bold interpretation. "}${field.dataset.feedback}`;
  next.disabled = false;
});
next.addEventListener("click", () => {
  if (next.disabled) return;
  if (round === rounds.length - 1) {
    rounds[round].hidden = true;
    next.hidden = true;
    feedback.hidden = true;
    quizPosition.textContent = "THE CRITICS ARE DELIGHTED";
    complete.hidden = false;
    collectStamp("quiz");
    complete.querySelector("button").focus({ preventScroll: true });
    return;
  }
  round += 1;
  showRound();
  rounds[round].querySelector("input").focus({ preventScroll: true });
});
document.getElementById("quiz-replay").addEventListener("click", () => {
  round = 0;
  quiz.querySelectorAll("input").forEach((input) => (input.checked = false));
  complete.hidden = true;
  next.hidden = false;
  feedback.hidden = false;
  showRound();
  rounds[0].querySelector("input").focus({ preventScroll: true });
});
showRound();

const scenes = [...document.querySelectorAll(".scene-choice")];
scenes.forEach((button) => {
  button.disabled = false;
  button.addEventListener("click", () => {
    button.setAttribute(
      "aria-pressed",
      String(button.getAttribute("aria-pressed") !== "true"),
    );
    const selected = scenes.filter(
      (scene) => scene.getAttribute("aria-pressed") === "true",
    );
    document.getElementById("scene-summary").textContent = selected.length
      ? `A real hello, then ${new Intl.ListFormat("en", { style: "long", type: "conjunction" }).format(selected.map((scene) => scene.dataset.line))}. Or we improvise.`
      : "A real hello first. The rest, we figure out together.";
    if (selected.length) collectStamp("scene");
  });
});

const questions = [...document.querySelectorAll(".conversation-question")];
let question = 0;
function showQuestion() {
  questions.forEach((item, index) => (item.hidden = index !== question));
  document.getElementById("question-counter").textContent =
    `SAVE FOR OUR WALK · ${question + 1} / ${questions.length}`;
}
document.getElementById("question-deck").setAttribute("aria-live", "polite");
document.getElementById("draw-question").addEventListener("click", () => {
  question = (question + 1) % questions.length;
  showQuestion();
});
showQuestion();

document.querySelectorAll("[data-stamp]").forEach((note) =>
  note.addEventListener("toggle", () => {
    if (note.open) collectStamp(note.dataset.stamp);
  }),
);
const letter = document.getElementById("letter");
letter.addEventListener("toggle", () => {
  const action = letter.querySelector(".letter-action");
  action.textContent = letter.open ? "Keep this one" : "Open me";
  if (!letter.open || reducedMotion.matches) return;
  letter.querySelector(".letter-paper").animate(
    [
      { opacity: 0.6, transform: "translateY(-8px)" },
      { opacity: 1, transform: "translateY(0)" },
    ],
    { duration: 500, easing: "cubic-bezier(.16,1,.3,1)" },
  );
});
document.documentElement.classList.add("has-js");
