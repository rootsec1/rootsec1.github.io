# Miss Dee's September book

`/miss-dee/` is a keepsake for the first NYC meeting on September 27, 2026. A forest-green book opens into three chapters and 19 dated scenes. Each scene places its prose beside the pictures, films and recordings from that exchange. On phones the prose comes first, followed by the related media. The long story starts closed; games, the flexible NYC plan, quiet notes and letter remain available outside it.

The book contains **109 source attachments: 95 still images, nine videos with their original audio, and five voice notes**. Every selected attachment belongs to exactly one scene. The original bench films and Ravi Kishan's supporting appearance remain.

## Content and behavior

- `data/dee_media.yaml` owns the flat media catalogue, dimensions, captions, durations and voice-note context. `data/dee_story.yaml` assigns those IDs to dated scenes and supplies the narrative. `data/miss_dee.yaml` owns trivia, plans and questions.
- `layouts/partials/date-media.html` renders photos, videos and audio. `date-story-media.html` adds their scene captions. A lead image or recording accompanies each scene; longer exchanges use a labelled horizontal strip for the rest.
- Native video and audio controls never autoplay and use `preload="none"`. Starting one recording pauses the others. Chapter changes and closing the book pause playback. Video captions and separate duration labels accompany the recordings. Voice notes have contextual summaries rather than unreliable verbatim automatic transcripts.
- Photos use responsive WebP files. Their viewer navigates only within the current scene, supports arrow keys and Escape, and restores focus. Without JavaScript, photo links open their image directly.
- JavaScript shows one chapter at a time, with persistent contents and Previous/Next controls. Turning a chapter brings its heading into view. Without JavaScript, the native disclosure opens all chapters for continuous reading.
- Matching photos, the lore quiz, plan choices and question deck retain their optional stamps. Nothing gates the letter. No state is stored or sent. Reduced motion disables the authored transitions.
- New York date handling changes tomorrow to today on September 27 and to keepsake wording afterward. The script-free page keeps its original pre-meeting wording.

`/miss-dee/yes/` opens the letter. The decision compatibility routes still redirect. The date layout leaves the blog unchanged. The page is marked `noindex`, uses self-hosted assets, and adds no runtime dependencies.

## Source selection and privacy crops

The supplied September inventory contains 168 still images, four animated HEIC sequences, 12 videos and 11 available audio messages. Selection used contact sheets, sampled video frames, local transcription and the surrounding messages. The dated story also matches source images to their positions in the message PDF. Raw exports, extracted messages and local matching results stay outside this repository.

The book keeps shared jokes, everyday updates, nature, horses, clothes, flowers, music and the watch-along sequence. It excludes financial/work/contact screenshots, private relationship disclosures, spoken contact information, unrelated third-party recordings, sexual jokes and the explicitly unsent clip.

The latest privacy changes remove attachment 879, the yellow-shirted stranger, and the full-body reaction animation 876. Attachments 872 and 873 now use horse-focused crops; 880 and 968 use face crops. The cropped files have new `-horse` or `-face` names, and their former wider files are removed from the current tree. Both thumbnails and full-size viewers use the crops. This does not rewrite earlier Git history.

Videos 736, 738, 740, 800, 801, 804, 807, 834 and 987 use H.264/AAC MP4 with fast-start metadata and original sound. Voice notes 757, 809, 814, 824 and 906 use AAC in M4A containers. Image metadata is stripped; adjacent JSON files record source provenance and crop details. Recordings load only when played and images load progressively.

`ravi-kishan.webp` is the existing [Koteshwara video thumbnail](https://www.youtube.com/watch?v=AGwFkEbHIZA). `lilies.webp` is the existing generated botanical illustration. Self-hosted Cormorant Garamond and DM Sans retain their OFL licenses.

## Run and verify

Use Hugo extended 0.111.3, matching the Pages workflow:

```sh
hugo server --bind 127.0.0.1 --port 1313 --baseURL http://localhost:8080/ --appendPort=false --liveReloadPort 8080 --disableFastRender
```

From your laptop, forward the development server:

```sh
ssh -N -L 8080:127.0.0.1:1313 rootsec1@devbox.abhishekmurthy.com
```

Visit `http://localhost:8080/miss-dee/`. Stop the server and tunnel when finished testing.

For browser checks, build and serve with a matching base URL:

```sh
hugo --gc --minify --baseURL http://127.0.0.1:1314/
python3 -m http.server 1314 --bind 127.0.0.1 --directory public
# In another terminal:
bash scripts/check-date.sh http://127.0.0.1:1314
```

The check covers widths 320, 390, 430 and 1280, image decoding, overflow, all games and controls, the closed book, chapter navigation, 109 unique media assignments, scene-scoped photo navigation, script-free reading, compatibility routes, reduced motion and New York date rollover. It checks that recordings do not load initially, plays all nine videos and five voice notes, verifies exclusive playback, and fetches every caption file. The browser closes on exit; stop the test server afterward.

Mobile and desktop axe-core WCAG 2 A/AA and 2.1 AA scans reported zero violations. These checks use Chromium emulation, not a physical iPhone.

[Mobile opening](mobile.png) · [Desktop opening](desktop.png) · [Open book](book-mobile.png) · [Mobile story](story-mobile.png) · [Desktop story](story-desktop.png) · [Voice notes](voices-mobile.png) · [Cropped photo viewer](photo-viewer-mobile.png) · [Letter](yes-mobile.png)
