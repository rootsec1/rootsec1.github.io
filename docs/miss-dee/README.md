# Miss Dee invitation

The invitation is at `/miss-dee/`, with its celebration at `/miss-dee/yes/`. Hugo redirects the previous `/ritu/decision/` and `/ritu/decision/yes/` URLs. The dedicated `date` layout avoids nesting documents inside the blog template. No analytics, external fonts, runtime image requests, or new project dependencies are needed.

The No button alternates between two positions inside its answer area for mouse hover, touch, and keyboard activation. It never submits a rejection or covers Yes. The Yes link works without JavaScript. Confetti respects reduced motion and removes itself when its animation finishes. This static site does not send or store an RSVP.

## Images

- `static/date/bench.webp`: frame at 1 second from the supplied IMG_7200.MOV, with the full bench and park background retained. Converted to a 720 × 1280 WebP without the video's audio or metadata.
- `static/date/ravi-kishan.webp`: WebP version of the thumbnail for [1 Hour of Ravi Kishan singing koteshwaray](https://www.youtube.com/watch?v=AGwFkEbHIZA), retrieved from `https://i.ytimg.com/vi/AGwFkEbHIZA/hqdefault.jpg`.
- The hammer and broken plate are an inline SVG illustration.

## Checks

Built with Hugo extended 0.111.3, matching the Pages workflow. To repeat the browser check, build with `hugo --gc --minify --baseURL http://127.0.0.1:1313/`, serve `public/` at that address, then run `bash scripts/check-date.sh`.

The check covers 320, 390, 430, and 1280 pixel widths, image loading, horizontal overflow, No button positioning and activation, Yes navigation, and both legacy redirects. Mobile and desktop screenshots were reviewed. Both pages passed automated WCAG 2 A/AA checks with zero violations. Browser checks use Chromium viewport emulation, not a physical iPhone.

## Screenshots

[Mobile invitation](mobile.png) · [Desktop invitation](desktop.png) · [Mobile celebration](yes-mobile.png)
