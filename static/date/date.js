const noButton = document.getElementById("noButton");
if (noButton) {
  let attempts = 0;
  let lastDodge = -Infinity;
  const messages = [
    "Oops. It got shy.",
    "Nope has left the conversation.",
    "Even the button wants us to go.",
    "Still running. Very little stamina, though.",
  ];
  const dodge = (event) => {
    event.preventDefault();
    if (performance.now() - lastDodge < 180) return;
    const start = noButton.getBoundingClientRect();
    const yes = document.getElementById("yesButton").getBoundingClientRect();
    const padding = 16;
    const width = document.documentElement.clientWidth;
    const height = window.visualViewport?.height ?? innerHeight;
    let target;
    for (let i = 0; i < 100; i += 1) {
      const x =
        padding +
        Math.random() * Math.max(0, width - start.width - padding * 2);
      const y =
        padding +
        Math.random() * Math.max(0, height - start.height - padding * 2);
      // Keep the entire glide, not just its destination, clear of Yes.
      const clearOfYes =
        Math.max(start.right, x + start.width) <= yes.left - 8 ||
        Math.min(start.left, x) >= yes.right + 8 ||
        Math.max(start.bottom, y + start.height) <= yes.top - 8 ||
        Math.min(start.top, y) >= yes.bottom + 8;
      if (clearOfYes && Math.hypot(x - start.left, y - start.top) > 100) {
        target = { x, y };
        break;
      }
    }
    if (!target) return;
    lastDodge = performance.now();
    if (!noButton.classList.contains("is-dodging")) {
      noButton.style.width = `${start.width}px`;
      noButton.style.height = `${start.height}px`;
      noButton.style.transform = `translate3d(${start.left}px, ${start.top}px, 0)`;
      noButton.classList.add("is-dodging");
      // Establish the initial position before starting the CSS transition.
      noButton.getBoundingClientRect();
    }
    noButton.style.transform = `translate3d(${target.x}px, ${target.y}px, 0)`;
    document.getElementById("no-note").textContent =
      messages[attempts++ % messages.length];
  };
  document.addEventListener("pointermove", (event) => {
    if (event.pointerType !== "mouse") return;
    const rect = noButton.getBoundingClientRect();
    if (
      event.clientX > rect.left - 35 &&
      event.clientX < rect.right + 35 &&
      event.clientY > rect.top - 35 &&
      event.clientY < rect.bottom + 35
    )
      dodge(event);
  });
  noButton.addEventListener("pointerdown", dodge);
  noButton.addEventListener("click", (event) => {
    event.preventDefault();
    if (event.detail === 0) dodge(event);
  });
  const reset = () => {
    noButton.classList.remove("is-dodging");
    noButton.removeAttribute("style");
    lastDodge = -Infinity;
  };
  window.addEventListener("resize", reset);
  window.addEventListener("scroll", reset, { passive: true });
  window.visualViewport?.addEventListener("resize", reset);
}
if (
  document.body.classList.contains("celebration") &&
  !matchMedia("(prefers-reduced-motion: reduce)").matches
) {
  for (let i = 0; i < 26; i += 1) {
    const piece = document.createElement("span");
    piece.className = "confetti";
    piece.setAttribute("aria-hidden", "true");
    piece.style.left = `${Math.random() * 100}%`;
    piece.style.background = ["#cf4835", "#b393be", "#e9dc8e"][i % 3];
    piece.style.animationDelay = `${Math.random() * 0.6}s`;
    document.body.append(piece);
    piece.addEventListener("animationend", () => piece.remove(), {
      once: true,
    });
  }
}
