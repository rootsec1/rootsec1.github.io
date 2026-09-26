---
name: Miss Dee's living scrapbook
description: A personal photo, film, and voice-note collection for /miss-dee/ and its compatibility pages.
colors:
  wine: "#4c2333"
  wine-deep: "#351824"
  paper: "#f7f3eb"
  pink: "#efccd0"
  ink: "#392b2c"
  muted: "#705b5c"
  green: "#233f35"
  gold: "#e7c789"
  line: "#d9c9c2"
typography:
  display:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "clamp(65px, 7.2vw, 96px)"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "clamp(42px, 5.1vw, 66px)"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "-0.025em"
  title:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "32px"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "-0.025em"
  body:
    fontFamily: '"DM Sans", sans-serif'
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.65
  button:
    fontFamily: '"DM Sans", sans-serif'
    fontSize: "14px"
    fontWeight: 400
rounded:
  paper: "3px"
  quiz: "4px"
  seal: "50%"
spacing:
  compact: "12px"
  gutter-mobile: "24px"
  gutter-tablet: "28px"
  gutter-desktop: "40px"
  paired-columns: "70px"
components:
  button-dark:
    backgroundColor: "{colors.wine}"
    textColor: "{colors.paper}"
    rounded: "{rounded.paper}"
    padding: "13px 22px"
    typography: "{typography.button}"
  quiz:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.quiz}"
    padding: "34px"
  question-card:
    backgroundColor: "{colors.pink}"
    textColor: "{colors.wine}"
    rounded: "{rounded.paper}"
    padding: "32px 36px"
  album-filter-selected:
    backgroundColor: "{colors.wine}"
    textColor: "{colors.paper}"
    rounded: "{rounded.paper}"
    padding: "10px 16px"
---

# Design System: Miss Dee's living scrapbook

## Overview

**Creative North Star: "Miss Dee's living scrapbook"**

This system applies to `/miss-dee/` and its compatibility pages. The Hugo blog retains its own identity. The current implementation lives in `static/date/date.css`, `static/date/date.js`, `layouts/date/single.html`, and `layouts/partials/date-media.html`. `data/dee_media.yaml` owns the media collection.

An ivory and rose scrapbook brings both people, their photographs, narrated films, and voice notes into the foreground. Maroon frames the collection; forest green separates the listening room and trivia. The user authorized this direction after rejecting the sparse premiere. AMC remains a shared joke within the album.

- Real portraits overlap as photographic prints beside the opening greeting.
- Three featured films and five voice notes lead into 103 camera-roll items, comprising 96 still images, six more films, and one silent animated sticker. The collection contains 111 assets in total.
- Photo pairs, trivia, scene choices, and stamps are optional. The personal letter remains available throughout.

## Colors

Wine supplies headings, the album spine, finale, selected filters, and dark buttons. Wine-deep backs video frames. Pink supports correspondence and stamps; green contains listening and trivia. Gold marks earned stamps and the star sticker. Paper carries reading areas, ink carries body text, muted carries supporting copy, and line separates rows. The frontmatter records the shared CSS colors; component-specific tints remain in the stylesheet.

## Typography

Self-hosted Cormorant Garamond uses the CSS family name `Cormorant`, with regular and italic files at weight 500. DM Sans supplies body text at weight 400. Both use `font-display: swap`; files live in `static/date/fonts/`.

The frontmatter records the active desktop greeting and base heading hierarchy. The greeting becomes 68px at 900px, 62px with a 0.9 line height at 600px, and 53px below 360px. Film titles use 31px; voice titles use 28px. Camera-roll titles use 27px, then 24px on mobile. Body text is 16px globally and 15px on mobile; supporting copy usually uses 11 to 14px. Paragraphs default to a 70ch maximum. Italic serif text carries captions, asides, and signoffs.

Lead the greeting and scene ticket with their title. Place contextual metadata beneath it.

## Layout

The opening caps at 1320px, with a 1:1.2 text-to-collage split, 50px gap, and 64px 50px 72px padding. Main sections cap at 1180px with 94px 40px padding. At 800px, sections reduce to 72px 28px; at 600px, to 62px 24px. Below 360px, side gutters reduce to 20px.

The three featured films occupy equal columns on desktop and stack at 600px. The listening room uses a 0.85:1.15 split and a 90px gap, reducing to 45px at 900px and stacking at 600px. Its decorative sticker photograph hides on mobile. The archive has three columns, then two at 900px; mobile videos span both columns. Photo pairs stay in a four-column grid.

On mobile the greeting precedes a compact portrait collage, followed by the media counts and films. Five chapter anchors stay in one row and stick to the top while scrolling. The full-size photo dialog uses `min(90vw, 800px)` width, expanding to 94vw on mobile. The letter wraps its summary controls on small screens.

## Elevation & Depth

Reading areas use flat backgrounds and fine rules. Portrait prints have a soft shadow and individual tilts of minus 7, 8, and 5 degrees. The scene ticket tilts 2 degrees and the question card minus 2 degrees. The photo dialog has a deeper shadow and dark backdrop. Matching pairs gain a green outline. Shadow values live in the sidecar.

## Shapes

Paper controls and pair tiles use a 3px radius; quiz, featured video frames, and the photo dialog use 4px. Photo prints remain square. Circular radio indicators, photo-expand controls, seals, and ticket cutouts have specific roles. Dashed borders describe ticket perforations and stamps. Reuse geometric inline SVG controls from `layouts/partials/date-icon.html`.

## Components

Dark buttons have a 52px minimum height, wine background, and paper text. Hover raises them 2px and lightens the wine; pressing scales them to 0.97. Disabled quiz progression uses muted colors. The mobile opening button is 45px high. Text links, filters, audio-context summaries, and dialog close controls provide at least 44px targets. Focus outlines use 3px gold with a 5px offset.

Native audio and video controls load recordings on demand with `preload="none"`. The nine original films preserve their sound; the animated reaction sticker is silent. Videos use `playsinline`, have caption tracks, and never autoplay. Starting one player pauses all others. Playback errors offer a direct recording link. Voice notes include native disclosures for words and context.

The camera roll uses photo links and inline video. All 103 items appear by default, without pagination or a reveal-more control. Filters use `aria-pressed` and show their counts: Everything 103, Faces & reactions 16, Outside together-ish 20, Lunch correspondence 24, Little daily updates 26, Our watchlist 17, and Little films 7. The live count updates with filtering, and hidden videos pause. Screenshots and stickers use `object-fit: contain` to keep their full contents visible.

Photo links open a native full-size dialog with a title, caption, meaningful alternative text, and a position count. Previous and Next buttons and the left and right arrow keys move through photos within the active filter; controls disable at the first and last photo. Opening the dialog pauses media. Escape, the close button, and the backdrop dismiss it and restore focus to the photo link that opened it. Modified clicks retain normal link behavior.

The photo-pair game shuffles four pairs of real photographs. Turning a tile updates its accessible label and pressed state. Matching tiles remain visible and become disabled; mismatches turn back after a short reading delay. Reset clears pending work and reshuffles. Live status describes progress. Trivia uses native radios and fieldsets; scene choices update a local ticket summary. None of these interactions gates the letter or sends choices elsewhere.

Without JavaScript, the full archive and native players remain available, photos link directly to their full-size files, and pairs show their photographs with an explanatory fallback. Native disclosures keep the letter and supporting notes usable. Quiz answers have a reading fallback and scene ideas remain visible.

Portraits arrive over 1.1 seconds; photos enlarge slightly on hover, pairs turn over 400ms, and the letter reveals over 500ms. Reduced motion disables animation, transitions, and smooth scrolling, and skips the scripted letter reveal. Static paper tilts remain. Date-sensitive copy uses the New York date and the chosen "See you tomorrow" wording before the meeting.

Keep actual photographs and recordings connected to their captions. The lily is a generated botanical illustration; the Ravi Kishan image is an existing YouTube thumbnail. Each shipping raster has an adjacent `<filename>.json` with its source or generation description in `prompt` and a `createdAt` value. Preserve those distinctions. Raw originals and private-message exports stay outside the repository.

## Do's and Don'ts

- Do preserve the substantial media collection, original sound, native controls, and mobile reading order.
- Do keep interactions optional and the letter accessible without game completion.
- Do maintain source provenance when replacing media.
- Don't apply this identity to the unrelated Hugo blog.
- Don't autoplay recordings or allow competing players.
- Don't turn flexible scene ideas into bookings or promised outcomes.
