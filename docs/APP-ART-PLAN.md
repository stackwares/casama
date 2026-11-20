# Painted pictures across the app: plan

Status: **built** (2026-11-20, D-440). Live on the web app (build 51), the server (project cover
column, gallery covers) and gallery.casama.ai. Store builds and the Android startup check pending.

Asked by Oliver after the starter set picker's painted covers ("what other parts of our app can be
as beautiful as that?"), then "go and do all of this", plus a painted splash and welcome background.

## What carries pictures now

| Where | Picture | Files |
|---|---|---|
| Shared widgets | `PaintedArt`, `PaintedCover`, `PaintedHero`, `PaintedSectionHeader`, `paintedChipAvatar` | `client/lib/ui/painted_cover.dart` |
| Starter set picker | Unchanged look, now on the shared widget; also reads a set's gallery `cover` | `welcome/gallery_picks_step.dart` |
| Gallery cards and item page | Set covers (bundled or gallery `cover.webp`), a 16:9 cover at the top of an item's page | `gallery/gallery_cards.dart`, `settings/gallery_screen.dart` |
| Packs shelf | Set covers | `packs/packs_shelf.dart` |
| Library, empty | 6 painted starter tiles with the label on a dark foot | `library/library_starters.dart` |
| New bot, persona gallery | Painted category cards (work, research, build, create, life); a banner on the preview | `bots/template_picker.dart` |
| Skill catalog | Painted category headers and chip avatars (7 categories) | `skills/skill_catalog_screen.dart` |
| Waitlist, invite code, invite gate | A painted hero per step (ticket, gift, envelope, hourglass) via `FormSheet.art` | `auth/*`, `ui/form_sheet.dart` |
| What's new | Hot air balloon hero | `whats_new/whats_new.dart` |
| Invite friends, invite link | Paper plane gift, open present | `referrals/invite_friends.dart` |
| Tasks, empty | Clipboard and target pictures on the two ways in | `board/board_screen.dart` |
| Computers, empty (was missing) | Desk computer, with a "New computer" button | `computer/computers_screen.dart` |
| Use this computer, intro | Waking computer | `companion/companion_screen.dart` |
| Paywall plans | Star (Plus), gem (Pro), crown (Max) | `billing/paywall.dart` |
| Projects | Pick one of 8 painted covers; shown in the list, tiles and project header | `projects/*`, new `projects.cover` column |
| Splash, sign-in and welcome | One painted "coming home" scene, day and night, wide and tall; sign-in is the first screen signed-out people see after the splash, so it carries the scene too | `ui/splash_scene.dart`, `main.dart`, `auth/sign_in_screen.dart`, `welcome/welcome_screen.dart` |
| Web loading page | The same scene, lighter, as a CSS background | `web/index.html`, `web/boot.js` |

Left as they were on purpose: mascot empty states, sign-in, consent, name and notification steps, calls,
celebrations (the mascots already carry them); chat starters (written per person); app logos; routine
idea chips (one icon per routine says more than a shared category picture).

## Art

- `visuals/round-10/` holds the briefs (`BRIEF.md` for objects, `SCENE-BRIEF.md` for the scene),
  `prompts.json` and `install.sh`. Raw PNGs in `raw/` are gitignored. Made with gpt-6-luna, one image per
  task; night scenes used the day painting as the reference.
- `install.sh` writes 512 px WebP covers to `client/assets/art/` (5–12 KB each), the scene at 1600 px to
  `client/assets/scene/` (54–88 KB each) and a 1536 px web copy to `client/web/splash/` (26–36 KB).
- A missing or failing picture always falls back to a drawn gradient tile, so no screen breaks.

## Gallery covers

Gallery sets, bots, routines, skills and plugins may carry `cover.webp` (WebP, square, 256–1024 px, at most
80 KB). It stays out of the item's files and hash. The server makes it an absolute URL on the item's own
catalog (`cover`), so new art ships from gallery.casama.ai without an app build. The 8 starter sets have
theirs.

## Motion (asked by Oliver, same day; no new pictures)

| What | Motion | Where |
|---|---|---|
| Splash and welcome scene | Very slow zoom 1.00 → 1.05 over 16 s, back and forth, ease in-out; one cached layer under a transform | `ui/splash_scene.dart` |
| Web loading page | The same zoom in CSS; boot.js sets its delay from `performance.now()` and Flutter starts from the same page clock (`ui/page_clock.dart`), so the hand-off doesn't jump | `web/index.html`, `web/boot.js` |
| Starter set preview, persona preview | The new cover fades in from 1.04 to 1 (350 ms, ease out) inside the panel's existing cross-fade | `CoverSettleIn` in `ui/painted_cover.dart` |
| Waitlist, invite code, what's new sheet heroes | Soft float: 4 px up and down, a hair of tilt, 4 s loop | `PaintedHero(float: true)` via `FormSheet.art` |
| Library starters (optional extra) | One-time staggered entrance | `library/library_starters.dart` |

Rules: every duration goes through `AppMotion.of`, and looping motion checks `ambientMotionOn` (off under
Reduce Motion, where the scene sits at 1.0 and heroes hold still). Tickers pause on their own when a screen
isn't ticking (TickerMode). Controllers are disposed. Nothing moves in scrolling lists (skill headers,
gallery shelves, paywall cards) or on the Computers and Use this computer empty states. Tests switch looping
motion off globally (`ambientMotionEnabled` in `test/flutter_test_config.dart`); `painted_cover_test.dart`
turns it on to check it.

Sharpness: the raw paintings are 1536 × 1024, so a real 2400 px export isn't possible without new art or an
upscaler. The web copy now uses the full 1536 px (26–36 KB); the app's wide cut is 1600 px (54–88 KB). If it
looks soft zoomed on a large desktop, the next step is an upscaler pass on the same painting.

## Splash and welcome performance rules

- WebP, decoded at screen size (`ResizeImage` from the screen size, pixel ratio and the 1.05 zoom), any
  veil baked in, no blur filter, no parallax; the only motion is the slow zoom above.
- `SplashScene.precache` starts decoding at the first splash frame; the plain background shows until the
  picture is ready, then it fades in. Startup never waits for it.
- The decoded picture is evicted one frame after the last `SplashScene` closes (after the welcome screen,
  or after the splash for someone already set up).
- Web: the loading page fetches its copy at low priority after the first paint and only then sets it as
  the background; Flutter's splash and welcome reuse that cached file.
- Native launch screens stay plain (Android 12+ allows only an icon on one colour; iOS caches its launch
  storyboard).
- **Still to do:** measure web startup and first frame (D-336 headless Chrome method) and one low-end
  Android, before and after. More than ~100 ms slower: shrink or drop it there. Needs Oliver's yes for the
  builds.
