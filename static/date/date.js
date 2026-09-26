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
    stamps.size === document.querySelectorAll("[data-stamp-label]").length
      ? "All four collected. Your sticker privileges are extensive."
      : `${stamps.size} of 4 little stamps collected. The ending is always open.`;
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
  quizPosition.hidden = false;
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
    quizPosition.hidden = true;
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

// Native players share one playback owner: starting one pauses the others.
const players = [...document.querySelectorAll("video, audio")];
players.forEach((player) => {
  player.addEventListener("play", () => {
    players.forEach((other) => {
      if (other !== player) other.pause();
    });
  });
  player.addEventListener(
    "error",
    () => {
      let message = player.parentElement.querySelector(".media-error");
      if (!message) {
        message = document.createElement("p");
        message.className = "media-error";
        message.setAttribute("role", "status");
        const link = document.createElement("a");
        link.href = player.querySelector("source").src;
        link.textContent = "Open this recording directly";
        message.append("This recording could not load. ", link);
        player.after(message);
      }
    },
    true,
  );
});

const story = document.getElementById("story");
const pages = [...document.querySelectorAll(".book-page")];
const chapterButtons = [...document.querySelectorAll("[data-book-chapter]")];
const previousChapter = document.getElementById("previous-chapter");
const nextChapter = document.getElementById("next-chapter");
let chapter = 0;
function showChapter(index, moveToPage = false) {
  const direction = index < chapter ? -1 : 1;
  chapter = index;
  pages.forEach((page, i) => {
    page.hidden = i !== chapter;
  });
  chapterButtons.forEach((button, i) => {
    if (i === chapter) button.setAttribute("aria-current", "page");
    else button.removeAttribute("aria-current");
  });
  previousChapter.disabled = chapter === 0;
  nextChapter.disabled = chapter === pages.length - 1;
  document.getElementById("reader-position").textContent =
    `Chapter ${chapter + 1} of ${pages.length}`;
  players.forEach((player) => player.pause());
  if (moveToPage) {
    const heading = pages[chapter].querySelector("h2");
    heading.focus({ preventScroll: true });
    heading.scrollIntoView({
      behavior: reducedMotion.matches ? "instant" : "smooth",
      block: "start",
    });
    if (!reducedMotion.matches)
      pages[chapter].animate(
        [
          {
            opacity: 0.65,
            transform: `translateX(${direction * 12}px)`,
            clipPath: "inset(0 1% 0 0)",
          },
          {
            opacity: 1,
            transform: "translateX(0)",
            clipPath: "inset(0 0 0 0)",
          },
        ],
        { duration: 420, easing: "cubic-bezier(.16,1,.3,1)" },
      );
  }
}
chapterButtons.forEach((button) =>
  button.addEventListener("click", () =>
    showChapter(Number(button.dataset.bookChapter), true),
  ),
);
previousChapter.addEventListener("click", () => showChapter(chapter - 1, true));
nextChapter.addEventListener("click", () => showChapter(chapter + 1, true));
showChapter(0);
story.addEventListener("toggle", () => {
  document.getElementById("book-action").textContent = story.open
    ? "Close our story"
    : "Open our story";
  if (!story.open) {
    players.forEach((player) => player.pause());
    return;
  }
  document.getElementById("reader").scrollIntoView({
    behavior: reducedMotion.matches ? "instant" : "smooth",
    block: "start",
  });
});
document.getElementById("close-story").addEventListener("click", () => {
  story.open = false;
  story.querySelector("summary").focus({ preventScroll: true });
  story.scrollIntoView({
    behavior: reducedMotion.matches ? "instant" : "smooth",
  });
});

const viewer = document.getElementById("photo-viewer");
const viewerImage = document.getElementById("viewer-image");
let viewerPhotos = [];
let viewerIndex = 0;
const previousPhoto = document.getElementById("viewer-previous");
const nextPhoto = document.getElementById("viewer-next");
function showPhoto(index) {
  viewerIndex = index;
  const link = viewerPhotos[index];
  viewerImage.src = link.href;
  viewerImage.alt = link.querySelector("img").alt;
  document.getElementById("viewer-title").textContent = link.dataset.title;
  document.getElementById("viewer-caption").textContent = link.dataset.caption;
  document.getElementById("viewer-position").textContent =
    `${index + 1} of ${viewerPhotos.length}`;
  previousPhoto.disabled = index === 0;
  nextPhoto.disabled = index === viewerPhotos.length - 1;
}
document.querySelectorAll("[data-photo]").forEach((link) =>
  link.addEventListener("click", (event) => {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey)
      return;
    event.preventDefault();
    const scene = link.closest(".story-scene");
    viewerPhotos = [...scene.querySelectorAll("[data-photo]")];
    document.getElementById("viewer-context").textContent =
      scene.querySelector("h3").textContent;
    showPhoto(viewerPhotos.indexOf(link));
    players.forEach((player) => player.pause());
    viewer.showModal();
  }),
);
previousPhoto.addEventListener("click", () => showPhoto(viewerIndex - 1));
nextPhoto.addEventListener("click", () => showPhoto(viewerIndex + 1));
viewer.addEventListener("keydown", (event) => {
  if (event.key === "ArrowLeft" && !previousPhoto.disabled) {
    event.preventDefault();
    previousPhoto.click();
  } else if (event.key === "ArrowRight" && !nextPhoto.disabled) {
    event.preventDefault();
    nextPhoto.click();
  }
});
viewer.addEventListener("click", (event) => {
  if (event.target === viewer) viewer.close();
});

const pairTiles = [...document.querySelectorAll(".pair-tile")];
const matchStatus = document.getElementById("match-status");
let firstTile = null;
let pairTimer;
let matchedPairs = 0;
let pairLocked = false;
function turnTile(tile, open) {
  tile.classList.toggle("is-flipped", open);
  tile.setAttribute("aria-pressed", String(open));
  tile.querySelector("img").setAttribute("aria-hidden", String(!open));
  tile.setAttribute(
    "aria-label",
    open
      ? tile.querySelector("img").alt
      : `Photo ${tile.dataset.position}, face down`,
  );
}
function resetPairs() {
  clearTimeout(pairTimer);
  firstTile = null;
  pairLocked = false;
  matchedPairs = 0;
  for (let i = pairTiles.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [pairTiles[i], pairTiles[j]] = [pairTiles[j], pairTiles[i]];
  }
  pairTiles.forEach((tile, index) => {
    tile.parentElement.append(tile);
    tile.dataset.position = index + 1;
    tile.disabled = false;
    tile.classList.remove("is-matched");
    turnTile(tile, false);
  });
  matchStatus.textContent = "Turn over two photos. Find their twins.";
}
pairTiles.forEach((tile) =>
  tile.addEventListener("click", () => {
    if (pairLocked || tile === firstTile || tile.disabled) return;
    turnTile(tile, true);
    if (!firstTile) {
      firstTile = tile;
      return;
    }
    const previous = firstTile;
    firstTile = null;
    if (previous.dataset.pair === tile.dataset.pair) {
      [previous, tile].forEach((item) => {
        item.disabled = true;
        item.classList.add("is-matched");
        item.setAttribute(
          "aria-label",
          `${item.querySelector("img").alt}, matched`,
        );
      });
      matchedPairs += 1;
      matchStatus.textContent =
        matchedPairs === 4
          ? "All four. You really do remember the little things."
          : `${matchedPairs} of 4 pairs. Excellent attention to the evidence.`;
      if (matchedPairs === 4) collectStamp("match");
    } else {
      pairLocked = true;
      matchStatus.textContent =
        "A convincing theory. Two different photos, though.";
      pairTimer = setTimeout(
        () => {
          turnTile(previous, false);
          turnTile(tile, false);
          pairLocked = false;
        },
        reducedMotion.matches ? 1300 : 1000,
      );
    }
  }),
);
document.getElementById("reset-pairs").addEventListener("click", resetPairs);
resetPairs();
document.documentElement.classList.add("has-js");
