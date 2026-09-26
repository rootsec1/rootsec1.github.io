# Miss Dee's little collection

`/miss-dee/` is a living scrapbook for the first NYC meeting on September 27, 2026. The user asked for substantially more of the supplied media after both the first premiere and the 46-item album felt sparse. The latter also hid everything after the first eight camera-roll entries. The revision puts real people and recordings first, while retaining the flexible plan, games, and ungated letter.

The collection contains **96 photos and still images, nine videos with their original audio, one animated reaction sticker, and five voice notes**. Three narrated films lead, five recordings have a listening section, and the remaining 103 items form a browsable camera roll. The original bench appears as a playable film with its park background. Ravi Kishan still has his supporting appearance. Source context shapes each caption; the site does not reproduce the message export.

## Structure and behavior

- `data/dee_media.yaml` owns the media catalogue, captions, dimensions, durations, and voice-note context. `data/miss_dee.yaml` owns trivia and plan/question content. `layouts/partials/date-media.html` is the shared renderer for photos, videos and audio.
- Native videos and audio use `preload="none"` and never autoplay. Starting a recording pauses the others. Separate duration labels remain visible before native players load their metadata. Captions accompany the videos; multilingual voice notes have context/meaning summaries rather than unreliable word-for-word automatic transcripts.
- Photos have responsive WebP thumbnails and larger versions. Native links open the larger image without JavaScript; JavaScript adds a native dialog with Escape/close behavior, focus restoration, Previous/Next buttons and arrow-key navigation within the selected subject. Screenshots and cut-out stickers fit inside their frames without cropping.
- The camera roll shows all 103 entries immediately, with subject filters and a film filter displaying their counts. There is no pagination. The script-free page also shows the entire catalogue. Filtering pauses any video being hidden.
- The photo-pair game uses four real pictures and supports mismatch, match and replay states. Its optional stamp joins the existing quiz, scene and notes stamps. No state is sent or persisted, and games never lock the letter.
- The navigation stays available while scrolling. Reduced motion disables the entry, flip and state animations. All reading material, native media controls, and the letter work without JavaScript.
- New York date handling changes “tomorrow” to “today” on September 27 and to keepsake wording afterward. Without JavaScript, the original pre-meeting wording remains.

`/miss-dee/yes/` opens the letter. Both `/miss-dee/decision/` compatibility redirects remain. The standalone date layout leaves the blog unchanged. The page is marked `noindex`, but the URL is public, not authenticated. There are no analytics, external runtime assets, or new runtime dependencies.

## Source selection and preparation

The September source inventory contains 168 still images, four animated HEIC sequences, 12 videos and 11 available audio messages, plus other export payloads. Images were checked through contact sheets, videos through sampled frames and local speech transcription, and audio against local transcription and surrounding messages. The four HEIC sequences required FFmpeg extraction for inspection; they repeat the same running-away sticker, now represented once as attachment 876. Raw PDFs, archive contents, extracted chat, and transcripts stay outside the repository.

The selected pictures include both people, homemade reaction stickers, horses, flowers, scenery, everyday food, clothing, art, the pastel-colour debate, translation attempts, music and watch-along updates. This expansion restores 64 still images and one animated sticker omitted by the previous selection. Clips preserve their original sound. The selection leaves out financial/work/contact screenshots, private relationship disclosures, a spoken phone number, unrelated third-party recordings, sexual jokes, and the explicitly unsent clip. Short, ambiguous multilingual automatic transcripts are not published as exact dialogue.

Media filenames retain source attachment IDs for provenance:

- Still images: 96, indexed by source attachment ID in `data/dee_media.yaml`. The five subjects contain 16 faces/reactions, 20 outdoor moments, 24 food updates, 26 daily updates and 17 watchlist entries, including the seven camera-roll video files.
- Videos: 736, 738, 740, 800, 801, 804, 807, 834, 987. H.264/AAC MP4, up to 640px on the long edge, fast-start metadata. Original audio retained. English captions are edited for readability; quiet scenic clips have descriptive cues.
- Animated sticker: 876, converted from the original silent HEIC sequence to H.264 MP4 for browser playback. This is the tenth video file; its label and caption identify it as a silent animation.
- Voice notes: 757, 809, 814, 824, 906. AAC in M4A containers.
- Original location/private metadata is removed. Adjacent WebP JSON sidecars record source provenance. The whole media directory is about 20 MB, but recordings load only when played and photographs load progressively.
- `ravi-kishan.webp` remains the existing [Koteshwara video thumbnail](https://www.youtube.com/watch?v=AGwFkEbHIZA). `lilies.webp` remains the generated botanical illustration. Self-hosted Cormorant Garamond and DM Sans retain their OFL licenses.

## Verification

Use Hugo extended 0.111.3, matching the Pages workflow:

```sh
hugo --gc --minify --baseURL http://127.0.0.1:1313/
python3 -m http.server 1313 --directory public
# In another terminal:
bash scripts/check-date.sh
```

The browser check covers widths 320, 390, 430 and 1280; image decoding/overflow; quiz correct and incorrect answers/replay; plan and question controls; stamps; matching, mismatches and reset; all subject/film filter counts, whole-album visibility, photo Previous/Next and keyboard navigation; full-size photo viewing; no-JS reading; alternate routes; reduced motion; and New York date rollover. It also verifies no recording is fetched initially, then activates the page and plays all ten video files and five voice notes to check decoding and exclusive playback, and fetches every caption file. The browser closes on exit; stop the server after testing.

The final mobile axe-core WCAG 2 A/AA and 2.1 AA scan reported zero violations. These checks use Chromium emulation, not a physical iPhone.

[Mobile opening](mobile.png) · [Desktop opening](desktop.png) · [Voice notes](voices-mobile.png) · [Camera roll on mobile](album-mobile.png) · [Camera roll on desktop](album-desktop.png) · [Photo viewer](photo-viewer-mobile.png) · [Letter](yes-mobile.png)
