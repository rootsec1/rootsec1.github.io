# Miss Dee: opening night

`/miss-dee/` is a personal premiere keepsake for the first NYC meeting on September 27, 2026. AMC refers to their dream-cinema joke. The former Yes/No invitation is replaced by optional games and a native expandable letter. `/miss-dee/yes/` opens the same keepsake with the letter expanded; the `/miss-dee/decision/` aliases still redirect.

The standalone Hugo `date` layout leaves the blog unchanged. Repeated memories, trivia, scene ideas, and conversation questions live in `data/miss_dee.yaml`. CSS, JavaScript, images, and fonts are self-hosted. There are no new runtime dependencies, analytics, external image requests, or RSVP submissions. The page is marked `noindex`; it remains a public URL, not an authenticated private page.

## Experience

A bench-photo film poster leads into memories, Ravi Kishan's supporting appearance, a four-question lore quiz, a flexible NYC scene picker, maroon lilies, a question deck, three director's notes, and the letter. Optional stamps reward exploring without gating content. Wrong trivia answers explain the reference and still let the reader continue. Scene choices can be toggled freely and remain in memory only. No plans are booked or sent; the rage room is optional.

The date is fixed in the template. JavaScript uses America/New_York to change “tomorrow” to “today” on September 27, and to keepsake wording afterward. Without JavaScript, all reading material and the letter remain available; scene buttons are disabled and all questions are readable. Without JavaScript, relative date wording remains the original pre-meeting copy.

The poster settles on entry, choices respond on selection, and the letter opens gently. Reduced motion disables these animations. Images below the opening are lazy-loaded; the short silent bench video has native controls, no autoplay, and `preload="none"`.

## Media provenance

The supplied PDF, archive, extracted messages, audio, and transcripts are not included. The implementation uses selected scenic media and light shared references; it omits personal disclosures and exact travel logistics. Archive image/video inventories and source context were reviewed before selecting these assets.

- `bench.webp`: existing frame at 1 second from the supplied IMG_7200.MOV, retaining the original park background.
- `ravi-kishan.webp`: existing WebP of the thumbnail for [Ravi Kishan singing Koteshwara](https://www.youtube.com/watch?v=AGwFkEbHIZA).
- `flower-detour.webp`, `sunset.webp`, `cow.webp`: selected photos from the supplied September archive (attachments 983, 806, and 991), resized with original private metadata removed.
- `lake-bench.webp`, `lake-bench.mp4`: still and silent, compressed 5.3-second video from attachment 987. The video has no audio track or original location metadata.
- `lilies.webp`: AI-generated botanical illustration of maroon lilies with pink/ivory edges and a rose ribbon, converted to WebP. It is a digital illustration, not a claim that flowers have been purchased.
- Image provenance is recorded in adjacent `.webp.json` sidecars because the design tool uses sidecars for WebP.
- Cormorant Garamond and DM Sans are self-hosted WOFF2 files sourced from Google Fonts, with their OFL licenses in `static/date/fonts/`.

## Verification

Build with Hugo extended 0.111.3, matching the Pages workflow:

```sh
hugo --gc --minify --baseURL http://127.0.0.1:1313/
python3 -m http.server 1313 --directory public
# In another terminal:
bash scripts/check-date.sh
```

The browser check uses `agent-browser` and covers 320, 390, 430, and 1280px widths; images and horizontal overflow; correct and incorrect trivia, replay, scene selection/deselection, six-question cycling, stamps, letter access before games, expanded details, legacy redirects, reduced motion, the script-free reading fallback, and New York midnight date changes. It closes its own browser. Stop the server after testing.

The September 26 build also passed an axe-core WCAG 2 A/AA and 2.1 AA scan with zero violations. Testing uses Chromium emulation, not a physical iPhone.

[Mobile opening](mobile.png) · [Desktop opening](desktop.png) · [Mobile letter](yes-mobile.png)
