---
name: Miss Dee, a September annotated
description: A botanical correspondence book with chronological scenes, original recordings, and an unwritten fourth chapter.
colors:
  green: "#233f35"
  green-deep: "#182e26"
  wine: "#652f42"
  paper: "#f7f3e9"
  sheet: "#fffdf6"
  pink: "#ead7d6"
  ink: "#34382f"
  muted: "#626457"
  gold: "#dec797"
  line: "#d4d2c0"
typography:
  display:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "clamp(60px, 6.3vw, 88px)"
    fontWeight: 500
    lineHeight: 0.94
    letterSpacing: "-0.035em"
  headline:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "clamp(40px, 4.8vw, 62px)"
    fontWeight: 500
    lineHeight: 1.05
    letterSpacing: "-0.025em"
  chapter:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "clamp(42px, 5vw, 64px)"
    fontWeight: 500
    lineHeight: 1.05
    letterSpacing: "-0.025em"
  scene:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "40px"
    fontWeight: 500
    lineHeight: 1.05
    letterSpacing: "-0.025em"
  narrative:
    fontFamily: "Cormorant, Georgia, serif"
    fontSize: "23px"
    fontWeight: 500
    lineHeight: 1.55
  body:
    fontFamily: '"DM Sans", sans-serif'
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.7
  button:
    fontFamily: '"DM Sans", sans-serif'
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.5
rounded:
  small: "2px"
  control: "3px"
  cover: "2px 7px 7px 2px"
  circle: "50%"
spacing:
  compact: "12px"
  paragraph: "18px"
  gutter-mobile: "25px"
  gutter-tablet: "30px"
  gutter-desktop: "42px"
  scene-gap: "60px"
  paired-columns: "70px"
components:
  button-dark:
    backgroundColor: "{colors.green}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
    padding: "12px 22px"
    typography: "{typography.button}"
  button-dark-hover:
    backgroundColor: "{colors.wine}"
  button-text:
    backgroundColor: "transparent"
    textColor: "{colors.green}"
    padding: "10px 0"
    typography: "{typography.button}"
  book-cover:
    backgroundColor: "{colors.green}"
    textColor: "{colors.paper}"
    rounded: "{rounded.cover}"
    padding: "34px 30px 31px 43px"
  chapter-selected:
    backgroundColor: "{colors.green}"
    textColor: "{colors.paper}"
    rounded: "{rounded.small}"
    padding: "12px 18px"
  quiz:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "35px"
  question-card:
    backgroundColor: "{colors.pink}"
    textColor: "{colors.wine}"
    padding: "36px"
  letter:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.green}"
  photo-viewer:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.green}"
    rounded: "{rounded.control}"
    padding: "20px"
    width: "min(92vw, 800px)"
---

# Design System: Miss Dee, a September annotated

## Overview

**Creative North Star: "A botanical correspondence book"**

Forest-green binding, ivory pages, and the existing maroon lily illustration introduce a personal account of September. Dated prose explains why each photograph, film, or voice note belongs. The long story starts inside a closed book; optional games, possible plans, quiet notes, and the letter remain outside it.

This system applies to `/miss-dee/` and its compatibility routes. The surrounding Hugo blog keeps its own identity. Source authority is `static/date/date.css`, `static/date/date.js`, `layouts/date/single.html`, the `date-media` and `date-story-media` partials, and the two `dee_media` and `dee_story` data files. `PRODUCT.md` records the product constraints; `.impeccable/miss-dee-brief.md` records the approved replacement direction.

**Key Characteristics:**

- A native book disclosure keeps the long story closed until opened.
- Three chronological chapters contain 19 scenes, each with prose, lead media, and the rest of that exchange.
- Cormorant carries the story; DM Sans carries controls and annotations.
- Botanical imagery and restrained paper depth connect the cover, reader, and personal letter.
- Original recordings play on demand; games never gate the ending.

## Colors

Forest green leads the cover, navigation, headings, trivia, and finale. Deep green backs video frames. Maroon marks italic emphasis, quotations, dates, and the cover ribbon. Gold marks cover lettering, active chapter labels, and collected stamps.

Warm paper is the page background; the lighter sheet is the reader, quiz, letter, and photo viewer. Ink supplies prose, muted supplies supporting text, and line supplies fine dividers. Pink supports the question card and recording-error messages. The frontmatter preserves the stylesheet's ten shared color values.

**The reading contrast rule.** Keep narrative text in ink or green on paper or sheet. Use muted text for annotations and maroon for short emphasis.

## Typography

Self-hosted Cormorant Garamond uses the family name `Cormorant`, with regular and italic files at weight 500. DM Sans supplies interface and supporting text at weight 400. Both use `font-display: swap`; files live in `static/date/fonts/`.

The frontmatter records desktop roles. Chapter introductions use 24px serif text with a 1.45 line height. Scene prose uses the narrative role; quotations use italic 29px serif text with a 1.25 line height. Scene captions use 22px serif titles and 12px sans-serif descriptions. Dates, counts, and small annotations use 11px sans-serif text. General paragraphs cap at 70ch; chapter introductions cap at 49ch.

At 1000px, the opening title becomes 68px and scene prose becomes 21px. At 650px, the opening title becomes 48px, chapter titles 42px, scene titles 35px, and narrative prose 22px with a 1.5 line height. At 360px, the opening title becomes 40px and chapter titles 38px. Mobile prose retains room for extended reading.

**The prose first rule.** Give the narrative serif the reading space. Keep dates, controls, and media counts in the smaller sans-serif voice.

## Layout

The desktop invitation caps at 1200px with a 1:0.9 text-to-cover split, a 70px gap, and 66px 65px 84px padding. The reader caps at 1260px with 54px 56px 34px padding. Other sections cap at 1140px with 84px 42px padding.

At 1000px, reader margins become 22px, reader padding becomes 38px 30px 28px, and section padding becomes 68px 30px. At 650px, the invitation keeps the title and compact cover side by side; the dedication, opening action, and supporting note span both columns below them. Reader margins become 12px and padding becomes 30px 20px 25px. Other sections use 58px 25px padding. At 360px, section gutters reduce to 21px and reader horizontal padding to 15px.

The chapter selector stays in three equal columns and sticks to the top of the reader while scrolling. Desktop scenes pair prose and media in a 0.9:1.1 grid with a 60px gap; alternate scenes reverse their visual order. At 1000px the gap becomes 35px. At 650px every scene becomes one column, with prose before media and a 25px gap.

Each scene has one lead item. Remaining items sit in a labelled horizontal strip with a visible count, scroll snapping, and a keyboard-focusable region. Desktop photo strips use 155px items with 166px image height; mobile uses 140px items with 148px image height. Video and audio items are wider. Lead photographs use a 5:4 frame capped at 440px high; mobile uses a square frame capped at 360px. The surrounding page does not become a horizontal scroller.

The four keepsake anchors remain in one row. Outside the book, games and plan sections stack at 650px; the matching grid keeps four columns. The photo viewer becomes 95vw with 14px padding on mobile.

## Elevation & Depth

Fine borders separate the reader and dated scenes. Shadows belong to the book cover, paper reader, and modal photo viewer. The cover rests at a 3-degree angle, straightens when the book opens, and rises slightly on pointer hover. The lily print counter-rotates 3 degrees. The plan ticket tilts 2 degrees and the question card tilts minus 2 degrees. Exact shadow and motion values live in `.impeccable/design.json`.

Chapter changes use a 420ms directional reveal with a 12px horizontal offset and slight clipping. Letter opening uses a 500ms reveal. Reduced motion removes animations, transitions, and smooth scrolling; all content and state changes remain available.

## Shapes

Controls, quiz, and photo viewer use the small control radius. The book has a narrow binding edge and softer outer corners. Photographs and reading sheets otherwise remain rectangular. Circles belong to the letter seal and photo-expand cue. The maroon ribbon uses a notched end. Use the existing inline SVG icon partial for controls.

## Components

### Book and chapter navigation

The cover and invitation are one native `summary` in a `details` element without the `open` attribute. JavaScript shows one chapter at a time, marks its selector with `aria-current="page"`, and supplies Previous and Next controls with disabled endpoints. The chapter selector remains visible while reading. Turning a chapter moves focus to its heading and pauses recordings. Closing the book pauses recordings and the explicit close control returns focus to the cover.

Without JavaScript, opening the same disclosure reveals all three chapters in order. There is no separate gallery or category-filter mode. The story data places each of the 109 source items exactly once within its 19 scenes: 95 stills, nine films, and five voice notes. The dedication and matching game reuse a few images outside the story.

### Buttons and selection

Dark buttons use green with paper text and become maroon on pointer hover. Text buttons are underlined and turn maroon on hover. Standard buttons have a 48px minimum height. Shared focus treatment is a 3px `#91652d` outline with a 5px offset. Disabled buttons reduce opacity to 0.5. The selected chapter uses green with a gold chapter label; unselected chapters remain on sheet and gain a pale green hover fill.

### Scene media and photo viewer

Lead items include their full caption. Strip items carry compact titles and recording durations. `fit: contain` in the media data preserves screenshots, stickers, and approved crops where required. Native audio and video controls use `preload="none"`; video keeps original sound, caption tracks, and `playsinline`. Starting one recording pauses all others. A playback error offers a direct recording link. Voice notes have native Words & context disclosures.

Photo links open a native dialog with the scene title, image title, caption, meaningful alternative text, and position count. Previous, Next, and arrow keys move only through photographs in that scene. Endpoints disable. Opening the viewer pauses recordings. Escape, Close, or a click on the dialog background dismisses it. Modified clicks retain normal links; without JavaScript the links open the files directly. The image uses `object-fit: contain` in a 53dvh frame.

### Games, plans, and letter

The matching game shuffles four pairs, announces progress, and resets pending flips when restarted. Trivia uses native radio groups, feedback, and a replay action. The selected radio row gains a pale green fill and green border. Flexible plan choices update a local ticket; they are not bookings or transmitted responses. Four optional stamps become gold when collected.

The question card is pink with maroon serif text. Quiet notes and the letter use native disclosures. The letter remains reachable from the header and keepsake navigation, independent of games or chapter progress. It uses an ivory sheet, maroon circular seal, and 22px serif body text, reducing to 21px on mobile. The celebration compatibility route opens the letter by default.

Date-sensitive copy uses `America/New_York` and the September 27, 2026 meeting date. It reads "See you tomorrow" before the meeting, "See you today" on the day, and "To our next chapter" afterward. Interaction state belongs to the current visit and is neither stored nor sent.

### Image provenance and privacy

Use the existing generated lily illustration and real source media. The Ravi Kishan image is an existing YouTube thumbnail. Each shipping raster keeps its adjacent provenance JSON. Raw originals and private-message exports stay outside the public tree.

The actual shipping files enforce the requested crops. Items 872 and 873 use horse-only files, 968 and 880 use face-only files, and their thumbnail paths follow those replacements. The yellow-shirt person, item 879, and full-body animation, item 876, are removed. Their originals and the superseded uncropped files do not belong in the shipping tree. CSS framing is not a privacy control.

## Do's and Don'ts

- Do connect every story image and recording to its dated scene and surrounding prose.
- Do keep the book closed initially and retain the native disclosure fallback.
- Do preserve the original recordings, their sound, and playback controls.
- Do keep games, flexible plans, notes, and the personal letter available outside the book.
- Do use approved face and horse crops in both full-size files and thumbnails.
- Do maintain image provenance when replacing assets.
- Don't restore the random gallery, category filters, or removed private compositions.
- Don't autoplay recordings or allow competing players.
- Don't gate the story or letter on completing games.
- Don't turn uncertain dates, flexible plans, or chapter four into factual promises.
- Don't apply this identity to the unrelated Hugo blog.
