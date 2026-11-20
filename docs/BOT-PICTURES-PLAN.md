# Bot pictures: your own picture for a bot, cropped the way you want it

Status: **not started**. Written 2026-11-20, waiting on Oliver's answers to §14 and his go-ahead.
No code yet.

Builds on D-202 (profile photos in Postgres, served by the API), D-201/D-085 (the design system and
`client/lib/ui`), D-405/D-324/D-410/D-452 (widgets, Live Activities, the watch, bot widgets), D-185
and D-419 (image generation and its safety check). It doesn't repeat them.

Line numbers and file names are from 2026-11-20. Re-find each hook before editing.

---

## 0. Summary

**Today** a bot's icon is its initials on a gradient or one of ten cloud mascots
(`avatar_url = "mascot:<name>"`). People can't use a picture of their own: a team's logo, a photo
of the real "Maria from accounts" the bot stands in for, a character they drew, a dog.

**Also today** a profile photo is cropped for you: `preparePhoto` takes the middle square and phones
shrink the picture to 512 px *before* anyone sees it. A face off-centre in a tall photo loses its
forehead, and nobody can fix it.

**This plan:**

1. **Any picture as a bot's picture.** From the camera, the photo library, a file, a drag onto the
   avatar, a paste, any picture already in a chat ("Use as Ada's picture"), and later one Casama
   draws for you.
2. **One cropper for every avatar in the app**, built for avatars rather than for photo editing: a
   fixed frame in the exact shape the picture will have (the bot squircle, the person circle), the
   picture moves and scales under it, and live previews show it at the sizes it will really appear,
   so you know a face still reads at 20 px in the sidebar before you commit. Profile photos move to
   it too.
3. **The picture shows everywhere a mascot shows today**: app, web app, Chrome extension, call
   screen, desktop companion, iOS/macOS/Android widgets, Live Activities and the Island, the watch
   and its complications, with the bot's colours taken from the picture so tinted surfaces still
   match it.

Phases (§12): 0 checks and a clickable prototype → 1 storage, upload, cropper, app → 2 every other
surface, more ways in, undo and recent pictures → 3 "Make one with AI" and bots that change their
own picture.

---

## 1. Principles

These decide every detail below.

1. **What you see in the cropper is exactly what you get.** Same shape, same corner radius, same
   colours behind it. No "it looked fine in the editor" surprise.
2. **Show it small before you commit.** Avatars live at 20–40 px. Most bad avatars are fine at
   300 px and mush at 24 px. The cropper shows the real small sizes, live.
3. **Moving the picture, not dragging handles.** For a fixed-shape avatar, the familiar pattern
   (iOS Contacts, WhatsApp, Telegram, Slack) is a still frame over a picture you pan and pinch.
   Corner handles belong to free-ratio crops, which an avatar never is.
4. **Never lose work, never block.** Upload in the background, show the new picture at once, undo
   for 10 seconds, and the last five pictures stay one tap away.
5. **The mascots stay the default and the heart of the brand.** A picture is a choice next to them,
   not instead of them; new bots still get a mascot.
6. **Native, fast, private.** All editing on the device in Flutter (no WebViews), metadata stripped
   on the server, nothing leaves the workspace unless someone shares it on purpose (§10).

---

## 2. Where people meet it (entry points)

| Where | What happens |
|---|---|
| **Bot profile** (`bot_profile_screen.dart`), the big avatar at the top | Gains the camera badge the profile photo already has. Tap → the picture sheet (§3) |
| **Bot profile → Icon** (`MascotPicker`, line ~270) | A new first tile, **Picture** (image-plus icon). With a picture set, it shows the picture, selected, with a small pencil: tap to re-crop the same original, long-press/right-click for Replace / Remove |
| **New bot** (`bots_screen.dart` ~875, the scrolling picker) | The same first tile. The live avatar beside the name field updates as you go |
| **Drag and drop** (desktop, web, iPad) | Drag a picture onto any editable bot avatar (profile hero, picker tile, create sheet). The avatar grows 6 % and shows a dashed ring in the accent with "Drop to use as Ada's picture". Drop → cropper |
| **Paste** | Cmd/Ctrl+V while the bot profile or the picker has focus, with a picture on the clipboard → cropper. A small "Paste picture" item appears in the picker's context menu when the clipboard holds one |
| **Any picture in a chat** | The message menu on an image (attached or generated) gets **Use as <bot>'s picture** (only for bots you can manage; a submenu when the chat has several bots) → cropper |
| **Ask the bot** (Phase 3) | "Use this as your picture", "draw yourself a new picture" → the bot does it through a tool, with Undo in the reply |
| **Profile photo** (`ProfilePhotoEditor`) | Same sheet and same cropper, round frame |

---

## 3. The picture sheet

`showChoiceSheet` (already used by the profile photo), titled "<Bot>'s picture", with the current
avatar large at the top of the sheet.

1. **Take a photo** (phones only; front camera for people, back camera for bots)
2. **Choose a photo** (photo library; on desktop and web, the system file picker filtered to
   images)
3. **Make one with AI** (Phase 3; shows its credit price on the row: "about 2 credits")
4. **Re-crop** (only with a picture; reopens the cropper on the kept original, §7)
5. **Recent** (Phase 2): a row of up to five earlier pictures of this bot, one tap to switch back
6. **Use a mascot instead** (closes the sheet and scrolls the picker into view)
7. **Remove picture** (red; goes back to the mascot it had before, or initials)

Desktop shows the same choices as a menu anchored to the avatar instead of a sheet, per the
adaptive-sheet rule.

---

## 4. The cropper

`client/lib/ui/avatar_cropper.dart`, one widget, two shapes:

```
showAvatarCropper(context, bytes, shape: AvatarShape.botSquircle | AvatarShape.circle,
                  name: 'Ada', status: ...) -> Future<CroppedAvatar?>
```

### 4.1 Layout

**Phones:** a full-screen route on black (like the system photo croppers; the picture's own colours
read best on black, and it matches the chat photo editor). **Tablets and desktop:** a 560 × 680
dialog on the app's dimmed backdrop. Same contents.

```
┌──────────────────────────────────────────┐
│  Cancel        Move and scale       Done  │  header (Done is the filled pill)
│                                          │
│   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│   ░░░░╭──────────────────────────╮░░░░   │  picture under a 55 % black scrim,
│   ░░░░│                          │░░░░   │  the frame cut out of it,
│   ░░░░│      (the picture)       │░░░░   │  1 px white hairline at 60 %
│   ░░░░│                          │░░░░   │
│   ░░░░╰──────────────────────────╯░░░░   │
│   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│                                          │
│   [56] [40] [24]   Ada   ● in a row       │  live previews (§4.4)
│                                          │
│   ⟲   ⇋     −  ━━━━━━●━━━━━━  +     Reset │  toolbar
│   Background: None · Ada's colour · White │  only for pictures with transparency (§4.5)
└──────────────────────────────────────────┘
```

- The frame is the **exact final shape**: a continuous-corner rounded square at radius
  `0.32 × size` for bots (the same math as `BotAvatar`), a circle for people. It takes 78 % of the
  shorter side of the editing area, so there's room to see what's being cut.
- Rule-of-thirds lines fade in (120 ms) while a finger or mouse is down and fade out after. No
  permanent grid noise.

### 4.2 Moving and scaling

- **Drag** to move, **pinch** (touch and trackpad) to scale around the fingers' midpoint,
  **scroll wheel** to scale around the cursor, **double-tap / double-click** toggles between "fill
  the frame" and 2× on the tapped point.
- **The picture always covers the frame.** Past an edge it rubber-bands (resistance grows as you
  pull) and springs back on release (a critically damped spring, ~280 ms). Scaling below "fill"
  springs back the same way. Exception in §4.5.
- **Zoom range:** from "fill" up to the point where the frame covers 256 source pixels. Past
  320 source pixels a quiet line appears under the previews: "Zoomed in close: the picture may look
  soft". No hard block.
- **Rotate 90°** (⟲) animates the turn (200 ms) and keeps the same point under the frame's centre.
  **Mirror** (⇋) for selfies. **Reset** returns to the starting framing; it's disabled until
  something changed.
- **Zoom slider** mirrors the gesture both ways, for mice, accessibility and people who don't
  pinch.
- **Haptics:** a light tick when the scale crosses "fill" and when it reaches the maximum, and a
  selection tick on rotate. None on desktop.

### 4.3 Where it starts

- Square pictures: fill, centred.
- **Portrait pictures** start a little high (the frame's centre at 40 % of the height), because
  faces and heads sit in the upper part of nearly every portrait photo. The single most common
  fix people make by hand, done for them.
- Landscape: fill, centred.
- Re-crop starts where the last crop ended (§7).
- Face-aware framing (Apple Vision, ML Kit) is a later option, §14 Q12.

### 4.4 Live previews

Under the frame, one row, always visible, updating every frame while you move (the same transform
drawn into small clipped boxes, so it costs nothing extra):

- **Bots:** the avatar at 56, 40 and 24 px, the last one in a mini sidebar row beside the bot's
  name with its status dot, on the app's light and dark surfaces (two tiny strips, stacked). It
  answers "does this still read in my sidebar?" before you commit.
- **People:** 56, 40 and 24 px circles and a mini chat header.
- Tapping a preview flips light/dark for a better look. They're `ExcludeSemantics`.

### 4.5 Pictures with transparency (logos, stickers, cut-out art)

Detected on load (any pixel with alpha < 250 in a downscaled scan). Then:

- The picture may scale **below** fill, so a wide logo can sit inside the frame with margin.
- A **Background** row appears: **None** (transparent: the bot looks like a mascot, no tile),
  **<Bot>'s colour** (the gradient it would have with initials, picked from its name), **White**,
  **Black**. Default: None when the picture already has margin, otherwise the bot's colour.
- The editing area shows a soft checkerboard only behind transparent parts, so "None" is visible.

### 4.6 Keyboard and accessibility

- **Keys:** arrows nudge 1 px (Shift: 10 px), `+`/`-` zoom, `R` rotate, `M` mirror, `0` reset,
  Return = Done, Esc = Cancel. Tooltips on every toolbar button name their key.
- **Screen readers:** the frame is one element, "Picture position", with custom actions Move
  up/down/left/right, Zoom in/out, Rotate and Reset, and a value that reads the zoom ("150 %").
  Every toolbar control is labelled. Focus starts on the frame; Done is reachable in two steps.
- **Reduced motion:** no springs (snap into bounds), no zoom animation on double-tap, no rotate
  animation.
- **Contrast:** the hairline and the scrim keep the frame visible on white and black pictures.
- Text scales to 200 % without the toolbar breaking (it wraps the zoom slider onto its own line).

### 4.7 Finishing

- **Done** closes the cropper at once. The avatar where you started shows the new picture
  immediately (from the rendered bytes in memory), with a thin progress ring around it while it
  uploads. On success: a soft haptic, a 1.0 → 1.06 → 1.0 pop (200 ms, none with reduced motion),
  and a snackbar "Picture updated" with **Undo** for 10 s.
- **Failure:** the old avatar comes back, and the snackbar says "Couldn't save the picture" with
  **Try again**, which re-sends the bytes still in memory. No re-cropping needed.
- **Cancel** with changes made asks nothing (nothing is lost: the original is still where it came
  from). Esc and the system back gesture behave the same.

### 4.8 Big and odd files

- The editor decodes at most 2,048 px on the long side (`instantiateImageCodec(targetWidth/Height)`),
  so a 48 MP photo opens fast and doesn't spike memory on a low-end Android phone. The previous
  `image_picker` limit of 512 px goes: the picker now asks for 2,048 px, so zooming has detail to
  work with.
- **HEIC, EXIF rotation, CMYK JPEG, 16-bit PNG**: Phase 0 checks each platform's decoder (§12).
  Anything a platform can't decode shows "This picture can't be opened here. Try a JPEG or PNG."
  inside the sheet, not a generic error.
- **GIFs and animated WebP**: the first frame, with a one-line note in the cropper ("Animated
  pictures stay still"). §14 Q8.
- **Files over 40 MB** are refused before decoding, with the size in the message.

### 4.9 Output

The cropper renders the framed square at **768 × 768 PNG** (alpha kept) on the device, with the
background from §4.5 baked in, and returns it with the crop parameters (§7). PNG because Flutter
encodes it natively; the server turns it into small WebP files (§6).

### 4.10 Why our own cropper and not `pro_image_editor`'s

The chat already uses `pro_image_editor` (crop, draw, text, filters) and it stays there. For avatars
it's the wrong tool: its crop editor offers a rectangle or an oval only (not our squircle), is built
around corner handles and free ratios, and can't host the live previews or the transparency
background. A focused cropper is about 500 lines on `InteractiveViewer`-style math and is easier to
test. §14 Q1.

---

## 5. Showing it

### 5.1 The value

`bots.avatar_url` keeps being the one field every pipeline already carries (glance, watch, Island,
canvas, notifications, packs, extension). A picture is stored as:

```
image:<uuid>:<rrggbb><rrggbb>
```

- `<uuid>` is the picture's id (§6); `<rrggbb><rrggbb>` are its two colours (§5.3).
- 55 characters: under glance's 64-character cap and notifications' 500, so no pipeline changes
  shape.
- Apps that don't know `image:` (older builds, today's widgets) fall back to initials: safe.
- One parser per language, with the same test vectors: Dart (`bot_avatar.dart`), Swift
  (`BotPalette`), Kotlin (`BotArt.kt`), TypeScript (`packages/domain`, used by the server and the
  extension).

Alternative: a separate `avatar_colors` field. Cleaner on paper, but it means changing every
payload and every native model. §14 Q4.

### 5.2 `BotAvatar`

- `image:` → the picture from `GET /v1/bot-images/<id>?size=128|512` (128 for anything drawn at
  ≤ 64 logical px on the device's pixel ratio, 512 above), through `SmoothNetworkImage` with the
  disk cache, clipped to the squircle.
- **No flash:** while it loads (first time only; ids are immutable and cached forever) the
  initials gradient in the picture's own colours shows, and the picture fades in over 150 ms.
- Large avatars (≥ 56 px) get the soft coloured shadow mascots and initials already get, in the
  picture's first colour.
- The status dot, `ringColor` and semantics are unchanged. 35 screens use `BotAvatar`, so they all
  get pictures with no per-screen work. Places that call `Mascot.fromAvatar` directly (colours,
  call screen, companion) are listed in Phase 2.

### 5.3 The bot's colour

Many surfaces tint with the bot's colour (`botColors`): chat accents, widgets, the call ring, the
watch. The server takes two colours from the picture (sharp's dominant colour plus the most
saturated distinct cluster; near-grey pictures fall back to the name palette), then nudges them to
pass 3:1 against both light and dark surfaces. `botColors(name, avatar)` reads them from the value.

### 5.4 Other surfaces (Phase 2)

| Surface | How |
|---|---|
| **Call screen** (`CallMascot`) | A bot with a picture shows it in its squircle at the call size, breathing while listening and scaling with the bot's loudness, with the pulsing ring in its colours, exactly the motion rules the mascot follows (55 % when muted, greyscale when failed, still with reduced motion) |
| **Desktop companion** | The picture in place of the mascot, same size and position, no animation |
| **iOS/macOS widgets, Live Activities, the Island** | Extensions can't fetch from the network reliably and Live Activity payloads are 4 KB. The app saves `bot-images/<id>@128.png` into the app group whenever glance data names a picture it doesn't have (and deletes ones no bot uses). `BotMarkView` reads the file; a missing file draws initials in the picture's colours. Tinted Home Screens desaturate it like the mascots (`widgetAccentedRenderingMode(.desaturated)`) |
| **Android widgets and the live-run notification** | Same idea: the app saves the 128 px file into its files directory; `BotArt.kt` loads it as a bitmap, clipped to the squircle |
| **Watch and complications** | The watch app fetches the 128 px picture from the API itself (it has its own network) into `URLCache`; complications read a copy in the watch's app group. "Wrist down" stays the outline-and-initial look |
| **Chrome extension** | `look.ts` learns `image:` and builds the URL from its API base. The old "any https URL" branch goes (§9) |
| **Web app** | Same Flutter code; images come from the API origin, already allowed by the CSP (Phase 0 check) |

Not in this plan: the bot's picture on push notifications (iOS communication notifications need a
Notification Service Extension we don't have; Android `largeIcon` is possible and listed as a later
item in §13).

---

## 6. Storage and API

Same reasoning as D-202: self-hosted stacks and production run no object storage, and a bot picture
is ~20–60 KB.

### 6.1 Table

```sql
create table public.bot_images (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  source text not null check (source in ('upload', 'chat', 'generated')),
  large bytea not null check (octet_length(large) between 1 and 524288),   -- 512 px WebP
  small bytea not null check (octet_length(small) between 1 and 65536),    -- 128 px WebP
  original bytea check (octet_length(original) <= 3145728),                -- for Re-crop, §7
  crop jsonb,                                                              -- {x, y, scale, rotation, mirror, background}
  colors text not null check (colors ~ '^[0-9a-f]{12}$'),
  created_at timestamptz not null default now()
);
-- RLS on, no user policies: API only (like profile_photos). allow_worker. pgTAP test.
```

- A trigger keeps the **five newest** per bot plus whichever one the bot is using, deleting older
  rows (that's the Recent row, §3). Deleting a bot or purging an account cascades.
- Size: 5 × (~60 KB + ~8 KB + ≤ 3 MB original) per bot at most. The original is kept only for the
  current picture and the one before it; older rows drop `original` (§14 Q9).

### 6.2 Endpoints

| Endpoint | Does |
|---|---|
| `PUT /v1/bots/{id}/image` `{png: base64, original?: base64, crop?: {...}}` | `can_manage_bot`. Body ≤ 5 MB. Checks magic bytes, decodes with sharp (refuses > 40 MP), re-encodes to WebP 512 and 128 (quality 86/82, alpha kept), **drops all metadata (EXIF, GPS, ICC beyond sRGB)**, takes the colours, inserts, sets `avatar_url`, returns the `Bot`. 20 a day per bot |
| `GET /v1/bot-images/{id}?size=128\|512` | No token, `Cache-Control: public, max-age=31536000, immutable`, `Content-Type: image/webp`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy: default-src 'none'`. The id is random and only handed to people who can see the bot (as with photos). 404 for unknown ids |
| `GET /v1/bots/{id}/images` | The Recent list: ids, colours, dates, `has_original` |
| `POST /v1/bots/{id}/image/{imageId}/use` | Switch back to a recent one (also how Undo works) |
| `GET /v1/bots/{id}/image/{imageId}/original` | For Re-crop; token required, `can_manage_bot` |
| `PATCH /v1/bots/{id}` `avatar_url` | Still how mascots and initials are chosen. Now validated: `null`, `mascot:<known name>`, or `image:<id of one of this bot's pictures>:<its colours>` (the server writes the colours, so a client can't fake them) |
| `POST /v1/bots/{id}/image/generate` (Phase 3) | §8 |

Contracts in `packages/contracts/src/bots.ts` and `routes/bots.ts`, then `pnpm gen` for the Dart
and TypeScript clients. `CreateBotRequest.avatar_url` stays `mascot:`/null; a picture is added right
after creation (the create sheet does both, invisibly to the person).

---

## 7. Re-crop

People often crop, look at it in the sidebar, and want "a bit less zoomed". Re-crop opens the
cropper on the **original** (the picture as picked, shrunk on the device to ≤ 2,048 px and ≤ 3 MB,
without its metadata) at the **last crop**, so a tweak takes two seconds. That's why §6.1 keeps `original` and `crop`. Without it, "edit" would re-crop an already
cropped 512 px picture and every tweak would lose quality.

---

## 8. Make one with AI (Phase 3)

A row in the sheet opens a small page:

- **Style chips**, each with a sample drawn in it: *Casama cloud* (our mascot style, any colour),
  *Soft 3D*, *Watercolour*, *Flat icon*, *Pixel*, *Line art*, *Photo*.
- An optional line: "Describe it" (placeholder from the bot: "A friendly owl with reading
  glasses"). Empty means Casama writes the prompt from the bot's name and instructions.
- **Make 2** (a pill with the credit price). Two candidates appear as large squircles with a soft
  shimmer while drawing (~6–10 s). Tap one → the cropper (usually just Done; they're drawn
  centred with margin). **Make 2 more** keeps the earlier ones on screen.
- Runs through the existing image path (D-185, `google/gemini-nano-banana-2.1` at 1K, ~$0.034
  each), the D-419 safety check first, charged as normal image credits, recorded in `usage_ledger`
  with `meta.purpose = "bot_picture"`. Candidates are saved with `source = 'generated'` but don't
  touch the bot until one is used; unused ones are pruned after a day.
- `docs/COSTS.md` gets the purpose row in the same change. No new vendor, no allowlist change.

**Bots change their own picture.** A `profile.set_picture` tool: from an image in the conversation,
or a new one through the same generator. Allowed only when the person speaking can manage the bot;
it's reversible, so it doesn't ask first, and the bot's reply carries an inline "Undo" chip. The
setup interview can offer it: "Want me to draw myself a picture?"

---

## 9. Safety, privacy and rules

- **Who can change it:** whoever can manage the bot (creator, or a workspace admin for team bots).
- **Who sees it:** people who can see the bot. Ids are random and never listed publicly.
- **Metadata:** stripped on the server (GPS in phone photos is the real risk). The original kept
  for Re-crop is re-encoded on the device without metadata before upload, and checked again on the
  server.
- **Arbitrary links go.** Today `avatar_url` accepts any URL and the extension loads https ones,
  which lets anyone who can edit a bot point every teammate's browser at a tracking pixel. After
  this, only `mascot:`, `image:` and null are accepted. Phase 0 counts existing https values
  (local, and a read-only query on production); a migration sets them to null.
- **Uploads aren't scanned** in v1: like chat attachments, they stay inside the workspace, and a
  workspace admin can remove one. Generated pictures go through D-419. §14 Q6.
- **Templates, packs, the gallery, the A2A agent card** stay mascot-only: a picture never leaves
  the workspace by being shared as a template. Sharing a bot with a picture as a template uses the
  mascot it had before, or initials, and the share sheet says so in one line. §14 Q5.
- **App Store / Play:** the camera and photo-library usage strings already exist (profile photos);
  the wording gets "and your bots' pictures". Privacy labels already declare user photos; checked
  in Phase 0. The macOS App Store build already has `user-selected` file access.
- **Privacy page and `docs-site/guide/privacy.md`** say where bot pictures live, that metadata is
  removed, and that they're deleted with the bot.

---

## 10. Analytics

Added to `packages/contracts/analytics/catalog.json` (no names, URLs or picture content):

| Event | Properties |
|---|---|
| `bot_picture_set` | `source`: camera, library, file, drop, paste, chat, recent, generated, bot_tool; `transparent`, `rotated`, `zoomed` (bools), `recrop` |
| `bot_picture_crop_cancelled` | `source` |
| `bot_picture_removed` | `to`: mascot, initials |
| `bot_picture_undone` | |
| `bot_picture_generated` (Phase 3) | `style`, `count` |
| `profile_photo_set` | `source`, `zoomed`, `rotated` |

The funnel worth watching: picture sheet opened → cropper opened → Done. A low Done rate means the
cropper is in the way.

---

## 11. Tests

- **Server** (`apps/server/test/bot-images.test.ts`): magic bytes and sizes, sharp re-encode drops
  EXIF/GPS (a fixture with GPS), alpha kept, colours stable on fixtures, 40 MP refusal, rate limit,
  `can_manage_bot`, cache and security headers, prune keeps five plus the one in use, `avatar_url`
  validation (foreign image id, fake colours, https refused), Undo/use, cascade on bot delete.
- **pgTAP:** the table, RLS on with no user policies, `allow_worker`, the prune trigger.
- **Domain/TS:** the `image:` parser and its shared vectors.
- **Flutter:** `avatar_cropper_test.dart` (bounds and rubber-band end states, zoom limits, rotate
  keeps the centre, mirror, keyboard, semantics actions, transparency detection and background,
  portrait start position, output 768 px with the right pixels in the corners), `bot_avatar_test`
  (`image:` parsing, small vs large variant, placeholder colours, unknown values fall back),
  picker and sheet tests, profile photo flow through the cropper.
- **Native:** Swift (`CasamaWidgetsTests`) and Kotlin parsers on the same vectors; the app-group
  file cache add/remove logic.
- **Real devices (Phase 2 exit):** iPhone, Android low-end, Mac, Windows, web: HEIC, a 48 MP photo,
  a transparent PNG logo, a GIF, VoiceOver/TalkBack through a full crop.

---

## 12. Phases

### Phase 0 — checks and a prototype (no production code)

1. Decode checks per platform (iOS, Android, macOS, Windows, Linux, web) for HEIC, EXIF orientation,
   CMYK JPEG, 16-bit PNG, animated GIF/WebP, through `instantiateImageCodec` with a target size.
   Record what fails and the fallback.
2. Memory and time to open a 48 MP JPEG on the low-end Android device.
3. Web: CSP allows the API origin for images; drag-and-drop and paste of images work.
4. Count `avatar_url` values that aren't `mascot:` or null (local, read-only on production).
5. **A clickable cropper prototype** in the widget preview (`flutter-add-widget-preview`) on a
   phone and a desktop window size, shown to Oliver before Phase 1 code goes further. Feel is the
   whole point; it gets tuned (frame size, spring, scrim) on a real phone.

**Done when:** each check has a written result here, and Oliver has tried the prototype.

### Phase 1 — pictures for bots in the app

Migration and pgTAP, contracts and `pnpm gen`, the endpoints (§6.2) with sharp, the `image:` value
and its parsers (Dart, TS), `AvatarCropper` with everything in §4, the picture sheet (camera,
library/file, re-crop, remove), `BotAvatar` showing pictures and their colours, bot profile hero
and picker tile, the create sheet, profile photos moved to the cropper (round), analytics events,
docs (`docs-site/guide/bots.md` "Give your bot a picture", privacy page, DECISIONS entry,
ARCHITECTURE, CHANGELOG).

**Done when:** a bot gets a picture from a phone and from a desktop, it shows in every Flutter
screen, profile photos crop by hand, all tests in §11 for these parts pass.

### Phase 2 — everywhere, and the nice ways in

Call screen and companion; iOS/macOS widgets, Live Activities and the Island; Android widgets and
the live-run notification; watch and complications; the extension; drag and drop, paste, "Use as
<bot>'s picture" in chat; Recent pictures and Undo; https `avatar_url` cleanup migration; template
sharing note.

**Done when:** the real-device list in §11 passes.

### Phase 3 — Make one with AI, and bots that set their own picture

§8, `docs/COSTS.md`, the tool and its guide text.

**Done when:** a picture can be made, cropped and used in under 30 seconds; a refused prompt says
why; costs land in `usage_ledger`.

Each phase is one commit series, tested with targeted runs while building and the full suites once
through `scripts/heavy.sh` at the end. App builds and deploys each need Oliver's yes.

---

## 13. Later (not in this plan)

- The bot's picture as the sender picture on notifications (Android `largeIcon` is easy; iOS needs
  a Notification Service Extension and communication-notification intents).
- Face-aware starting frame (Apple Vision on Apple platforms, ML Kit on Android).
- Workspace icons (`workspaces.avatar_url` exists, unused) through the same cropper.
- Background removal ("cut out the subject") on device.
- Pictures in shared templates and the gallery, with review.

---

## 14. Decisions for Oliver

Recommended answers first. Say "defaults" to take them all.

| # | Question | Recommendation |
|---|---|---|
| 1 | Build our own avatar cropper, or reuse `pro_image_editor`'s crop screen? | **Own** (§4.10): exact squircle, live small previews, transparency background |
| 2 | Bot pictures in the bot squircle, or round like people? | **Squircle**: bots and people stay easy to tell apart, and it matches every bot avatar today |
| 3 | Store in Postgres like profile photos? | **Yes** (§6). Revisit if object storage ever arrives |
| 4 | Carry the colours inside `avatar_url` (`image:<id>:<colours>`) or add a field? | **Inside** (§5.1): no payload or native model changes, older apps fall back safely |
| 5 | Can bots with pictures be shared as templates / packs / on the A2A card with the picture? | **No in v1**; they fall back to the earlier mascot or initials |
| 6 | Scan uploaded pictures with a model? | **No in v1** (workspace-private, like attachments); generated ones keep D-419 |
| 7 | AI pictures: how many per tap? | **2 per tap** (~$0.07), "Make 2 more" for more |
| 8 | Animated GIFs as avatars? | **No**, first frame |
| 9 | Keep originals for Re-crop (≤ 3 MB each, current + previous only)? | **Yes**; it's what makes "a bit less zoomed" lossless |
| 10 | Remove support for arbitrary https `avatar_url` values? | **Yes** (§9, tracking risk) |
| 11 | Move profile photos to the new cropper in Phase 1? | **Yes**: same work, fixes the forced centre crop |
| 12 | Face-aware first framing now? | **Later**; the portrait heuristic covers most cases |
| 13 | Should "Make one with AI" also offer the cloud mascot style in any colour, i.e. unlimited new mascots? | **Yes**, as the first style: it's on-brand and the most likely to look good small |
