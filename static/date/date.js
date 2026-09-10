const noButton = document.getElementById("noButton");
if (noButton) {
  let attempts = 0;
  const messages = [
    "Oops. It got shy.",
    "Nope has left the conversation.",
    "Even the button wants us to go.",
    "Still running. Very little stamina, though.",
  ];
  const dodge = (event) => {
    event.preventDefault();
    attempts += 1;
    noButton.classList.toggle("is-dodging", attempts % 2 === 1);
    document.getElementById("no-note").textContent =
      messages[(attempts - 1) % messages.length];
  };
  noButton.addEventListener("pointerenter", (event) => {
    if (event.pointerType === "mouse") dodge(event);
  });
  noButton.addEventListener("pointerdown", dodge);
  // Keyboard and assistive-technology activation keeps the same playful behavior.
  noButton.addEventListener("click", (event) => {
    event.preventDefault();
    if (event.detail === 0) dodge(event);
  });
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
