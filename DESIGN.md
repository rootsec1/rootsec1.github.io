---
name: Miss Dee's midnight cinema
description: A personal dream-cinema premiere, scoped to /miss-dee/ and its compatibility pages.
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
    fontSize: "clamp(68px, 7.6vw, 96px)"
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
  button-light:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.wine}"
    rounded: "{rounded.paper}"
    padding: "13px 22px"
    typography: "{typography.button}"
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
---

# Design System: Miss Dee's midnight cinema

## Overview

**Creative North Star: "Miss Dee's midnight cinema"**

This system applies only to the standalone `/miss-dee/` keepsake and pages that use its date layout. It does not change the Hugo blog's identity. The source of truth is `static/date/date.css`, with behavior in `static/date/date.js` and markup in `layouts/date/single.html`.

The approved AMC dream-cinema world uses maroon framing, ivory playbill pages, actual camera-roll photographs, and paper tickets. AMC refers to the shared dream joke. It does not imply cinema affiliation or a booking. Literary headings and restrained paper tilts support the playful, personal copy.

**Key Characteristics:**

- Large serif greetings and headings, paired with compact sans-serif prose.
- Actual photographs in a premiere poster and horizontal memory reel.
- Optional quiz, scene choices, and keepsake stamps; the letter is always available.

## Colors

Primary wine supplies the opening, finale, text accents, and dark buttons. Wine-deep separates the credits strip. Secondary pink marks correspondence and italic emphasis; green contains the trivia section. Tertiary gold marks earned stamps and the star sticker. Neutral paper carries reading areas, ink carries body text, muted carries supporting copy, and line separates rows. The frontmatter records the CSS custom properties without inventing a palette scale.

## Typography

Self-hosted Cormorant Garamond uses the CSS family name `Cormorant`, with regular and italic files at weight 500. DM Sans supplies the body at weight 400. Both use `font-display: swap`. Files live in `static/date/fonts/`.

The frontmatter records the base heading hierarchy. The mobile greeting is 66px with a 0.91 line height, falling to 56px below 360px. The mobile section baseline is 46px, with deliberate per-section overrides. Finale headings are 72px on desktop, 52px on mobile, and 45px below 360px. Memory titles are 28px on desktop and 29px on mobile. Body text is 16px globally and 15px on mobile; most supporting paragraphs use 12 to 14px. Paragraphs default to a 70ch maximum. Italic serif text carries personal asides and signoffs.

**The Heading First Rule.** Lead the opening and scene ticket with their title; place date, location, and ticket metadata beneath it. Small uppercase cinema labels are contextual metadata, not a reusable eyebrow-heading pattern.

## Layout

Desktop sections cap at 1180px with 94px vertical and 40px horizontal padding. Paired content commonly uses two columns with a 70px gap. The opening uses a 1.1:1 split; scene choices use 1.25:1. At 800px and below, sections reduce to 72px by 28px and paired gaps to 32px. At 600px and below, paired content stacks and sections use 62px by 24px. Below 360px, side gutters reduce to 20px. Above 1500px, opening gutters align with the main container.

Mobile preserves the greeting and opening action before the poster. The reel remains horizontally scrollable, with scroll snapping and a glimpse of the next memory: items use a 78% basis and 230px minimum width on mobile. The four chapter links remain in one row. The letter wraps its summary controls on small screens. The finale's inner reading width caps at 750px.

## Elevation & Depth

Most reading areas are flat and separated by background color or fine rules. The photographic poster, memory prints, and question card use soft shadows, recorded in the sidecar. The poster tilts 3 degrees, the scene ticket 2 degrees, and the question card minus 2 degrees. Earned stamps rotate slightly. Ticket notches and the inset letter seal give paper objects their shape; there are no floating dashboard panels.

## Shapes

Paper controls, correspondence, and tickets use the small paper radius; the quiz uses its slightly larger radius. Photographic print frames remain square. Circular radio indicators, seals, and ticket cutouts are reserved for their physical roles. Dashed borders describe ticket perforations and stamps. Reuse the geometric inline SVG icons in `layouts/partials/date-icon.html` for controls; decorative lettering on the seal is text.

## Components

Buttons use the frontmatter variants, a 52px minimum height, and generous inline spacing. Hover-capable devices raise them 2px; the light button turns pink and the dark button changes to a lighter wine. Pressed buttons scale to 0.97. Disabled quiz progression uses muted colors until an answer is selected. Text buttons and header links keep a 44px minimum height; mobile opening buttons use 49px.

Quiz answers use native radios and fieldsets. Selected answers gain a pink fill, wine border, filled radio, and SVG check. Scene choices use `aria-pressed` buttons, with a tinted row and checked circular indicator. Their live ticket summary updates without submitting or saving choices. Quiz feedback, the question deck, and stamp counts use polite announcements. Quiz progression moves focus to the next answer or replay button.

Chapter navigation uses native anchors. Details elements hold the supporting scenes, director's notes, and letter; their summaries remain keyboard operable without JavaScript. A skip link and gold focus outlines support navigation. Images have meaningful alternative text. The silent bench clip uses native controls and does not autoplay. Without JavaScript, personal content and the letter remain available, quiz answers have a reading fallback, and scene ideas remain visible.

The poster settles over 1.1 seconds. Buttons and choices use short state transitions; the letter reveals over 500ms. Reduced motion disables CSS transitions, animation, and smooth scrolling, and skips the scripted letter animation. Static paper tilts remain. Optional stamps never unlock the ending. Date-sensitive wording uses the New York date, with the chosen "See you tomorrow" reveal before the meeting.

**The Real Frames Rule.** Use the selected scenic photographs as photographs; preserve their relationship to the personal story. The lakeside poster comes from the supplied bench video. Memory images are `bench.webp`, `flower-detour.webp`, `sunset.webp`, and `cow.webp`; the lily image is a generated botanical illustration. The Ravi Kishan image is an existing YouTube thumbnail. Each shipping raster has an adjacent `<filename>.json` with `prompt` describing its source or generation and `createdAt`. Keep that distinction and provenance when replacing assets. Originals and private-message exports stay outside the repository.

## Do's and Don'ts

- Do scope these tokens and patterns to the Miss Dee keepsake.
- Do preserve the actual photographs, native controls, mobile reading order, and optional interactions.
- Do keep the letter accessible regardless of quiz answers or collected stamps.
- Don't apply this identity to the unrelated Hugo blog.
- Don't turn flexible scene ideas into bookings or promised outcomes.
- Don't replace control SVGs with text glyphs or make decorative metadata the leading heading treatment.
