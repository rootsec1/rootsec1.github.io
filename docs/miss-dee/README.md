# Miss Dee invitation

The invitation is at `/miss-dee/`, with its celebration at `/miss-dee/yes/`. Hugo also redirects the alternate `/miss-dee/decision/` and `/miss-dee/decision/yes/` URLs. The dedicated `date` layout avoids nesting documents inside the blog template. No analytics, external fonts, runtime image requests, or new project dependencies are needed.

The No button glides to varied positions inside the viewport when the mouse approaches, on touch, and on keyboard activation. Its path stays clear of Yes, and scrolling or resizing returns it to the answer area. Reduced motion disables the glide. It never submits a rejection or covers Yes. The Yes link works without JavaScript. Confetti respects reduced motion and removes itself when its animation finishes. This static site does not send or store an RSVP.

## Personalization

The invitation uses light shared jokes about benches, leaf photos, AMC dreams, black T-shirts, and interview prep. The field-trip ticket lays out the rage room, ice cream, and bench plan without setting a date or claiming anything is booked. Three native expandable notes add playful answers and a sincere message. The supplied conversation export is not included in the repository.

## Images

- `static/date/bench.webp`: frame at 1 second from the supplied IMG_7200.MOV, with the full bench and park background retained. Converted to a 720 × 1280 WebP without the video's audio or metadata.
- `static/date/ravi-kishan.webp`: WebP version of the thumbnail for [1 Hour of Ravi Kishan singing koteshwaray](https://www.youtube.com/watch?v=AGwFkEbHIZA), retrieved from `https://i.ytimg.com/vi/AGwFkEbHIZA/hqdefault.jpg`.
- The hammer and broken plate are an inline SVG illustration.

## Checks

Built with Hugo extended 0.111.3, matching the Pages workflow. To repeat the browser check, build with `hugo --gc --minify --baseURL http://127.0.0.1:1313/`, serve `public/` at that address, then run `bash scripts/check-date.sh`.

The check covers 320, 390, 430, and 1280 pixel widths, image loading, horizontal overflow, No button positioning and activation, Yes navigation, and both alternate-path redirects. Mobile and desktop screenshots were reviewed. Both pages passed automated WCAG 2 A/AA checks with zero violations. Browser checks use Chromium viewport emulation, not a physical iPhone.

## Screenshots

[Mobile invitation](mobile.png) · [Desktop invitation](desktop.png) · [Mobile celebration](yes-mobile.png)
