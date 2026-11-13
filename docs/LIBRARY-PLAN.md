# Library: one place for everything bots make, and the shell around it

Status: **proposed** (2026-11-13). Nothing here is built. The choices that are Oliver's are in §14,
each with a recommended default; the rest of the plan is written as if the defaults hold. When a
phase lands, record its decisions in `docs/DECISIONS.md` (the highest number was D-265 on
2026-11-13; check first).

Wireframes: `docs/media/library-wireframes.html` (the tab, one creation, the chat, and two desktop
layouts).

## 0. Summary

People will ask bots to make things: sites, games, pictures, videos, sound, documents. Today each
kind lands somewhere different, and most can only be found again by scrolling the chat they were
made in. This plan gives everything a bot makes one home, and shapes the shell around three
questions:

| Place | The question it answers |
|---|---|
| **Chats** | Who do I talk to? |
| **Library** (new) | What did they make? |
| **Tasks** | What are they working on? |

What changes:

1. **A third place, Library**, on every size: a tab on phones, a rail item on tablets, a sidebar
   row on desktop. It fills itself; nobody files anything by hand.
2. **A creation becomes a record.** One table indexes pages, generated pictures and videos, and
   files a bot hands over. Each has a title, a kind, a cover, the bot that made it and the chat it
   came from.
3. **Things outlive the computer.** A file a bot hands over is copied off the computer when the
   reply is saved, so it opens while the computer sleeps or after it is reset.
4. **Everything has a cover.** Screenshots for sites and games, a frame for videos, the first page
   for documents, a drawn cover when nothing else exists.
5. **The chat shows the same items.** Cards get covers, an update shows as "Updated", and each bot
   has a "Made here" view. On desktop the panel beside the chat gets a second tab for it.
6. **You change a thing by talking.** "Change it" on a creation opens the chat it came from with
   the creation attached, so the bot knows which one.
7. **Storage is counted and capped per plan**, and the bytes move out of Postgres before usage
   grows.

Not in this plan: a visual restyle (D-256 just did the chat look), any change to General and topics
(D-253), Tasks or Settings, and anything that needs a WebView.

## 1. What exists today

Checked in code on 2026-11-13. Line numbers are from that day; re-find each hook before editing.

### 1.1 The shell

- Two places on every size, Chats and Tasks (`client/lib/features/home/home_shell.dart:157-173`).
  D-176 set three (Chats, Inbox, Tasks); D-253 folded the Inbox into Chats.
- Phones: a floating pill with the two tabs and a round Connect apps button (`home_shell.dart:275-295`).
  The pill shows only on the tab roots `/`, `/bots`, `/tasks` (`home_shell.dart:153`).
- Tablets: a rail. Desktop: a sidebar with Needs you, Updates, the bots and group chats, then Tasks
  and the person (`home_shell.dart:524-765`).
- Desktop: the bot's computer is a resizable panel beside the chat (`home_shell.dart:388-401`), with
  Screen, Terminal, Files and Manage tabs (D-265).
- Search (D-235) covers messages, chats, memories, skills, routines, tickets and files on awake
  computers. It covers neither pages nor generated media (`packages/contracts/src/search.ts`).

### 1.2 Where each kind of output lives

| Kind | How a bot makes it | Where the bytes are | In the chat | Found again by |
|---|---|---|---|---|
| Web page: site, report, dashboard, single-file game | `pages.publish` (`packages/agent/src/pages.ts:84-223`) | `pages`: HTML up to 2 MB, data up to 1 MB, 20 versions (D-119) | A card with a globe and the title, no picture (`PageCard`, `client/lib/features/chat/media/attachment_view.dart:182`) | Updates, then the Pages filter; or the bot's profile. A plain list (`client/lib/features/pages/pages_screen.dart`) |
| Picture | `media.image.generate` (`packages/agent/src/tools/autonomy.ts:986-1035`) | `chat_media`, bytes in Postgres, up to 50 MB (D-205), plus a copy in the computer's `media/` | Shows under the reply | Scrolling the chat. There is no list route |
| Video | `media.video.generate` (`autonomy.ts:1037-1104`) | Same | A player under the reply; a poster from `GET /v1/media/:id/poster` | Scrolling the chat |
| Sound | No tool. Read aloud is the person's button, cached in `tts_cache` | n/a | n/a | n/a |
| Documents and other files: PDF, Word, slides, sheets, CSV, zip, code | `files.write` or the shell (LibreOffice, ffmpeg, pandoc) | The computer's disk only. No database row | The app turns links in the reply into cards (`client/lib/features/chat/widgets/shared_files.dart`, D-156); previews need the computer | The computer's Files tab, one folder at a time; search, on awake computers only |

### 1.3 The gaps

1. **No one place.** Four stores, three ways in, none of them a tab.
2. **Pictures and videos can't be browsed at all.** `chat_media` has no list route, no title and
   no owner column.
3. **Files die with the computer.** A document a bot made is only on its disk. Asleep, the preview
   has to wake it; reset, the file is gone and the chat card is dead.
4. **Nothing has a cover.** Pages have no thumbnail column or route.
5. **Opening a page takes three taps on a phone** (Updates, the Pages filter, the page), and the
   list caps at 200 with no paging
   (`apps/server/src/api/routes/pages.ts`).
6. **Deleting a chat deletes its media** (D-220). That was right when the chat was the only home.
7. **Sites and games are small.** One HTML file, no network, no forms, images as `data:` only
   (`packages/domain/src/pages.ts:9-20`). Enough for a small canvas game, not for one with real
   assets. The product review lists pages that take input (Add 3) and finished documents (Add 2).
8. **Storage is counted nowhere.** I found no cap or meter on `chat_media`; the only size limit in
   plan data is the computer's `disk_gb`. `docs/COSTS.md` lists file storage as "not metered".

## 2. Goals

- Anything a bot made is at most two taps from launch: the tab, then the item.
- It opens without waking a computer.
- It has a face you recognise in a grid.
- From any creation you can get back to the chat to change it, and from any chat to what was made
  there.
- Sharing uses one set of rules for every kind.
- The app stays native. Sites and games keep opening in the system browser (D-092).
- Storage cost is known per workspace and can't run away.

Not goals: a file manager for the computer (the Files tab stays), editing tools inside the Library,
a public showcase of other people's creations, hosting apps with a backend.

## 3. Principles

1. **A creation is a thing, not a path.** It has a name, a cover, a maker and a home chat.
2. **The Library fills itself.** Grouping comes free from kind, bot and topic. Collections made by
   hand come later and stay optional.
3. **One item per thing.** A new version updates the item; it never adds a twin.
4. **The chat is where you change it; the Library is where you find it.**
5. **Only what was handed over.** Generated media the person saw, published pages, files a reply
   links to, and things a bot saves on purpose. Browser screenshots, scratch files and the person's
   own uploads stay out.
6. **Kept by the server.** The computer is a workshop, not the shelf.
7. **Private until shared**, with the confirmation and audit pages already have.
8. **Every byte is counted** (the cost rule: no unmetered paid dependency).

## 4. Words

| Word | Meaning |
|---|---|
| **Library** | The place. In code the feature is `creations` (`/v1/creations`, `features/library/`), because "library" already means the skills library (D-104) and "gallery" is the public catalog (D-184) |
| **Creation** | One thing a bot made. The app rarely says the word; it says the kind |
| **Kind** | What drives the viewer and the filter: `page`, `image`, `video`, `audio`, `document`, `file` |
| **Label** | The bot's word for it, shown on the card: Site, Game, Report, Dashboard, Slides, Sheet. Free text, at most 24 characters; the app translates the ones it knows and falls back to the kind |
| **Cover** | The picture on the card |
| **Made here** | A bot's or a topic's creations, opened from its chat |
| **Collection** | A group the person makes (Phase 4) |

Filter chips group kinds for people: All, Sites & games (`page`), Images, Videos, Audio, Documents,
Files. A chip shows only once the workspace has something of that kind.

## 5. The experience

### 5.1 The shell

- **Phones:** the pill holds Chats, Library, Tasks. The round button stays Connect apps. The tab
  roots become `/`, `/bots`, `/library`, `/tasks`. Tapping Library again scrolls to the top
  (`TabReselect`).
- **Tablets:** the rail gets the third destination.
- **Desktop:** the sidebar's bottom group becomes Library, Tasks, the person. On wide windows a
  selected creation opens beside the grid, the way a settings page opens beside the settings list
  (`_settingsSplitWidth`).
- **Order:** Chats first because it is home. Library sits next to it because we expect people to
  open it more often than the ticket board.
- **A dot, not a count.** The Library tab shows a small dot when something was made since the last
  visit. Counts stay for things that wait on the person (Needs you).
- **Routes:** `/library`, `/library/:id`, and `/library?kind=&bot=&q=`. `/pages` and `/pages?bot=`
  redirect to `/library?kind=page`.

Other shapes considered:

| Shape | Why not |
|---|---|
| A Home tab with a prompt box and a feed (as Manus and Lovable do) | Casama is teammates you message; D-263 lands a new person in a chat. A fourth tab and a second way to start work would undo D-176 and D-253 |
| A Library row inside Chats, like Updates | Cheapest, but it buries the proof that the product works. People judge a maker tool by the shelf |

### 5.2 The Library screen

- **Header:** the title, search inside the Library, and later "+" (Phase 6).
- **Filters:** the kind chips; then Bot (any or one), Sort (Newest, Recently opened, Name) and, in
  workspaces with more than one person, Mine or Workspace. On phones the last three sit behind one
  filter button.
- **All:** a Pinned shelf when there is one, then everything newest first under day headings
  (Today, Yesterday, This week, Earlier). Tiles have one shape: a 4:3 cover, the title, the bot and
  a kind pill.
- **One kind:** the layout fits it. Images and videos as a tight three-column grid. Sites and games
  as two-column cards with a 16:10 cover. Audio, documents and files as rows.
- **Stacks:** a run that made several pictures shows as one tile with a count, which opens to the
  set. This keeps drafts from flooding the grid.
- **Loading:** a skeleton in the grid's shape, like every other screen. 60 a page, more on scroll,
  pull to refresh, and new creations arrive live.
- **Empty:** the mascot, "Nothing made yet", and three starters (a game, a logo, a one-page site).
  A starter opens the bot you talked to last with the prompt filled in and not sent, through the
  existing `/quick-ask?bot=&text=` route.
- **Offline:** the last list and covers from the caches that exist (`local_cache.dart`,
  `media_cache.dart`).
- **Select several** (Phase 4): long-press on phones, a checkbox on hover on desktop. Delete, add
  to a collection, save, share.

### 5.3 One creation

A full screen on phones, a pane beside the grid on wide windows.

- **Top:** the preview, the title (tap to rename), then "Made by Ada · 2 hours ago · version 3 ·
  private".
- **Actions:** one main action for the kind, Share, Change it, and a menu: Rename, Pin, Add to a
  collection, Save, Export PDF (pages), Who can see it, Delete.
- **Rows:** From "topic" in Ada's chat (opens the conversation at that message); Versions; Made
  alongside (the same run's other creations); Details (size, dimensions, length).

| Kind | Preview | Main action |
|---|---|---|
| Site, report, dashboard | A screenshot | Open, in the system browser through the single-use link as today |
| Game | A screenshot | Play (the same link) |
| Image | Native zoom and pan; swipe to the next | Save or Share |
| Video | The player the chat uses (`chat_video.dart`) | Save or Share |
| Audio | A player with a waveform; a mini player stays while you move around the app (Phase 4) | Play |
| Document | `PreviewBody`: PDF pages, Office as PDF, CSV as a table, code colored (`client/lib/features/chat/media/preview_body.dart`) | Open in another app |
| File | A type card | Save |

**Change it** opens the creation's home conversation with the composer focused and a chip above it
("About: Space Dodger"). The message carries the creation's id, and the agent gets its handle (the
page id, or the file's path and version) in context. If that conversation is gone, it opens the
bot's General.

### 5.4 In the chat

- **Cards get covers.** The page card shows its screenshot. Pictures and videos already show
  themselves. A long-press or right-click adds Pin and Show in Library.
- **Updates, not twins.** When a run changes an existing creation, the reply gets a compact card:
  the title and "Updated · version 2".
- **Made here.** A button in the chat header with a count. On phones it opens a sheet with that
  bot's creations (in a topic, that topic's first). The Pages row on the bot's profile becomes a
  Library tile next to Computer, Memory, Routines and Apps.
- **Desktop: the side panel has two tabs,** Computer and Made here. Clicking a creation card in the
  chat selects it in the panel with a native preview; a site shows its screenshot and Open. The
  panel remembers its tab per bot.
- **Tasks and projects.** A finished ticket's result card lists what was made for it, and a project
  page gets a "Made in this project" strip (Phase 4; runs already carry `project_id`).

### 5.5 Sharing

- Today only pages can be shared: private, workspace, or a public link that is hashed, revocable,
  can expire, asks first and is audited (D-119).
- The same three levels apply to every kind. A public picture, video or sound gets a small viewer
  page on the pages origin (`/s/<token>`), never on the API origin, with `noindex` and "Made with
  Casama".
- On phones Share first offers the file itself through the system share sheet (`share_plus` is
  already used); Copy public link is the second choice, behind the same confirmation as pages.
- Abuse rules are in §12.

### 5.6 Search, updates, notifications

- **Search:** a new kind, `creation`, matched on title, label and bot name. A Library scope chip.
  "Go to: Library" replaces the Pages place.
- **Updates:** "Ada published Weekly sales" stays and opens the creation. The Pages filter in
  Updates goes away.
- **Push:** when a routine or a long run finishes and made something, the notification names it
  and opens it. Quiet hours apply.

### 5.7 Teams

- You can see a creation if you can see the message that handed it over. Pages keep their own rule
  (the person it was made for and the bot's managers, D-119).
- Pin and "recently opened" are per person.
- Mine or Workspace appears only when the workspace has more than one person.

### 5.8 States that need a design

Loading, empty, a filter with nothing in it, offline, load failed with Try again, a creation whose
source is gone, deleted (with Undo), and storage full (§9).

## 6. Data

### 6.1 `creations`: the index

One row per thing. It points at the bytes; it does not copy what a table already holds.

| Column | Notes |
|---|---|
| `id`, `org_id`, `bot_id` | |
| `made_for` | The person. From the conversation's `created_by`, or the routine's owner |
| `conversation_id`, `message_id`, `run_id` | Where it came from. Ticket and project come through the run |
| `kind`, `label`, `title` | §4. The title is plain metadata, like a page title |
| `page_id` | For pages. Unique. Deleting the page deletes the creation |
| `media_id` | For `chat_media` rows. Unique |
| `blob_key`, `computer_id`, `origin_path` | For files handed over: where the kept copy is, and where it came from. Unique on bot, computer and path, so handing the same file over again makes a new version |
| `mime`, `size`, `width`, `height`, `duration_s` | |
| `cover_key`, `cover_w`, `cover_h` | Null until a cover exists |
| `version` | Pages mirror `pages.version` |
| `deleted_at` | Deleting is soft for 30 days |
| `created_at`, `updated_at` | |

- `creation_marks (user_id, creation_id, pinned_at, last_opened_at)` for per-person pins and the
  Recently opened sort.
- `creation_versions (creation_id, version, blob_key, size, created_at)` for files, last 5 kept by
  a trigger. Pages keep `page_versions`.
- `collections` and `collection_items` in Phase 4.
- **RLS:** select through `can_view_creation(id)`, which is `can_view_page` for pages and
  `can_access_conversation` otherwise. Update and delete for `made_for` and the bot's managers.
  `public.allow_worker` and a pgTAP test, as every new table.
- **Indexes:** `(org_id, created_at desc)`, `(org_id, kind, created_at desc)`,
  `(bot_id, created_at desc)`, `(conversation_id)`, `(run_id)`, and a trigram index on `title`.

### 6.2 How things get in

| Source | Hook | What happens |
|---|---|---|
| Pages | A trigger on `pages` (insert, version bump, delete), so the tool, the API and revert are all covered. `pages.publish` gets an optional `label` | Upserts the creation by `page_id` |
| Generated pictures and videos | `keepForChat` (`packages/agent/src/tools/autonomy.ts:969-984`) | Inserts the creation with the `chat_media` row. Title from a new optional `title` argument, else the first words of the prompt |
| Files a reply links to | `saveFinalMessage` (`packages/agent/src/run.ts:2585-2640`), where `linkedFilePaths` already finds them (`packages/agent/src/file-links.ts:41`) | While the computer is still awake, copies each file (up to 50 MB) to the blob store and upserts the creation by bot, computer and path. The server reads at most 5 links a reply and the app shows 8; make both 8 |
| Saved on purpose | New tools `library.save(path, title, label?)`, `library.list`, `library.get` | A bot files something it didn't link, finds its own earlier work, and gets the handle to change it. `files.from_chat` grows to bring a kept file back onto a computer that was reset |
| Sound | A new `media.audio.generate` tool (Phase 6) | Same path as pictures. A new paid dependency: it goes in `docs/COSTS.md` with a ledger kind before it ships |

**Backfill:** one SQL migration inserts a creation for every existing `pages` and `chat_media` row.
Files handed over before this are not backfilled: they are only links in message text, the text
may be sealed (D-136), and the files may be gone. Production had 2 accounts on 2026-11-13.

### 6.3 Message parts

- The `file` part with `media:<id>` and the `page` part stay exactly as they are and gain a
  `creation_id` field.
- Files handed over get a new part: `{type: "creation", creation_id, kind, title, name, mime_type,
  size, width?, height?, duration_s?, path, version}`. `path` is the computer path, so the app can
  match it to the link in the text and show one card.
- **Shipped apps:** the app's parser reads only `file` and `page` parts and skips the rest
  (`client/lib/core/backend.dart:83-94`), so an old build ignores the new part and keeps drawing
  cards from links. Confirm with the oldest build in use before shipping the server side.
- "Change it" sends an `about` part with the creation's id. The context builder turns it into one
  line for the model.

### 6.4 Deleting

- Deleting a creation hides it at once, shows Undo, and purges the bytes after 30 days. Deleted
  items count toward storage until purged.
- **Deleting a chat keeps what was made** (this changes D-220). The confirmation offers "Also
  delete 4 things made here", off by default.
- Workspace and account deletion remove creations and their bytes; add both to the purge job and
  its test.

## 7. Covers

Made by the worker when the creation is made or changed, stored at about 640 px wide, and served
from `GET /v1/creations/{id}/cover` with a long private cache.

| Kind | How | Exists today |
|---|---|---|
| Image | ffmpeg scales it down | ffmpeg is already on the server for video posters |
| Video | A frame from the middle, the current poster logic (`videoPoster`, `apps/server/src/api/routes/chat-media.ts:47`) | Yes, but it keeps posters in memory; store them |
| Page | A screenshot from the isolated Chromium that prints PDFs (the `pdf` service in `infra/compose/docker-compose.yml:370`, `PDF_RENDERER_URL`). Gotenberg 8 has screenshot routes; check the pinned version's docs. Taken 1.5 s after load so a game has drawn a frame | The service exists behind a compose profile. Turning it on in production needs Oliver's yes |
| Document | The first page, from the computer's thumbnail code while it is awake (D-226); Office files through the PDF preview (D-205) | Yes, per computer |
| Audio | 64 loudness peaks computed with ffmpeg; the app draws the waveform | No |
| File, and anything without a cover yet | The app draws one: a tint picked from the id, the kind's glyph, the title | No |

A bot can also pass `cover_path` to `pages.publish` (a screenshot it took in its own browser), which
covers servers that run without the PDF service.

## 8. API and contracts

- `GET /v1/creations?org_id=&kind=&bot_id=&conversation_id=&project_id=&scope=&pinned=&q=&cursor=&limit=`
- `GET /v1/creations/{id}` with versions and the same run's siblings
- `PATCH /v1/creations/{id}` (title, pinned; visibility in Phase 5), `DELETE`, `POST …/restore`
- `GET /v1/creations/{id}/content` with byte ranges (as `/v1/media/{id}` does, because AVPlayer
  needs them), `GET …/cover`
- Pages keep their routes; a page creation's detail calls view-link, revert and PDF through
  `page_id`.
- `GET /v1/search` gains the kind `creation`.
- A live event, `creation.changed`, delivered the way new messages and bot status reach the app
  today, so the grid updates without a refresh.
- All of it in the OpenAPI contracts (`packages/contracts/src/routes/`), unlike today's
  `/v1/media` routes, then regenerate `dart/casama_api`. The CLI and the MCP server get list and
  download after the app.
- Analytics, added to `packages/contracts/analytics/catalog.json`: `library_view` (filter),
  `creation_open` (kind, and source: library, chat, search or push), `creation_change_started`,
  `creation_shared` (level), `creation_pinned`, `creation_deleted`. A server milestone
  `first_creation`, and a daily rollup of creations by kind. Never titles.

## 9. Storage, limits and cost

**Where bytes go.** Postgres holds generated media today. That does not scale: the production
server has one 200 GB disk for everything (D-199), and the nightly dump kept for 14 days (D-197)
multiplies whatever sits in the database.

- New bytes (files handed over, covers) go to the object store from the start. The abstraction
  exists (`packages/sandbox/src/object-store.ts`: S3-compatible or filesystem; Cloud uses R2,
  D-062) but only the supervisor uses it. Wire it into the worker and the API. Keys:
  `creations/<org>/<creation>/<version>/<name>` and `covers/<creation>.jpg`.
- `chat_media` bytes move to the same store in Phase 5. Self-hosters keep the filesystem driver.

**Counting.** `organizations.storage_bytes` kept by triggers on the three sources (pages HTML and
data, media, kept files and their versions), shown in Usage.

**Caps** (proposed; R2 is $0.015 per GB-month with no egress fee, from `docs/COSTS.md`):

| Plan | Cap | Cost to us when full |
|---|---|---|
| Free | 1 GB | $0.02 a month |
| Plus $15 | 10 GB | $0.15 |
| Pro $49 | 50 GB | $0.75 |
| Max $99 | 200 GB | $3.00 |

- A warning at 80%. At 100% a bot can't make new media or pages and says why; the paywall opens
  with a new source, `storage_full`. Nothing is ever deleted for the person.
- For scale: a picture is 1 to 2 MB, a 10-second video 5 to 20 MB. Twenty pictures and five videos
  a day is 45 to 140 MB, or roughly 1.5 to 4 GB a month. A heavy maker fills Free within weeks and
  Plus within months.
- `docs/COSTS.md` changes in the same commit: the file storage row gets a meter and these caps.

## 10. App work

| Area | Change |
|---|---|
| `client/lib/core/router.dart` | `/library`, `/library/:id`, the `/pages` redirect |
| `client/lib/features/home/home_shell.dart` | Third destination, tab roots, the dot, the split pane, the side panel with two tabs |
| `client/lib/features/library/` (new) | `library_screen.dart`, `creation_tile.dart`, `creation_detail.dart`, `library_providers.dart`, `made_here.dart`, later `collections.dart` |
| `client/lib/features/chat/media/attachment_view.dart` | Covers on page cards, the Updated card, the `creation` part |
| `client/lib/features/chat/chat_screen.dart` | The Made here button, the About chip on the composer |
| `client/lib/features/bots/bot_profile_screen.dart` | The Library tile |
| `client/lib/features/search/search_view.dart` | The `creation` kind, the Library scope, the place |
| `client/lib/features/inbox/inbox_screen.dart` | Drop the Pages filter; page updates open the creation |
| `client/lib/features/pages/pages_screen.dart` | Its actions move into the detail; the screen goes |
| `client/lib/l10n/app_en.arb` | New strings (English only) |
| Tests | `navigation_test.dart` (three tabs), `pages_test.dart`, `search_test.dart`, `inbox_feed_test.dart`, `chat_media_test.dart`, `shared_files_test.dart`, and new `library_test.dart`, `creation_detail_test.dart` |

Reuse before building: `PreviewBody`, `AttachmentView`, `ChatPicture`, the video and audio widgets
in `client/lib/features/chat/media/`, `SmoothNetworkImage`, the skeleton pieces, `GroupedCard`,
`showAdaptiveSheet`.

## 11. Phases

Each phase ends at its check, then gets a commit. Sizes are relative: S is a day or two of agent
work, M several days, L a week or more.

**Phase 1: the index and the API** (M, server only)
- The `creations` and `creation_marks` tables, RLS, pgTAP.
- The pages trigger, the `keepForChat` hook, the backfill.
- List, get, patch, delete, content and cover routes; contracts; SDK.
- `organizations.storage_bytes` and its triggers (counting only).
- *Done when:* every page and every `chat_media` row has exactly one creation; a member of
  another workspace gets 404; the API and pgTAP suites pass.

**Phase 2: the Library in the app** (L)
- The third place on all three sizes; the screen with chips, the grid, skeleton, empty state.
- The detail, using the previews that exist; drawn covers for everything without a picture.
- Change it; Show in Library from a chat card; the `/pages` redirect; the search place and scope;
  the bot profile tile; the Pages filter and screen retired.
- *Done when:* from a cold start on a phone, one tap reaches the Library and a second opens any
  page, picture or video ever made; the Flutter suite passes with the new navigation tests.

**Phase 3: covers and files that last** (L)
- The object store in the worker and the API.
- Real covers for images, videos, pages and documents.
- Files handed over are kept; the `creation` part; `library.save`, `library.list`, `library.get`;
  file versions; stacks.
- Storage caps enforced, the Usage row, the paywall source, `docs/COSTS.md`.
- *Done when:* no tile is blank; a document opens with its computer asleep and after a reset; a
  workspace over its cap is told so in the chat and in Usage.

**Phase 4: beside the chat, and keeping things** (M)
- Made here on phones; the two-tab side panel on desktop; covers and Updated cards in the chat.
- Pin, collections, select several, Recently opened.
- What was made for a ticket and in a project.
- The audio mini player (useful once Phase 6 adds sound; a bot can already hand over an audio
  file it made with ffmpeg).

**Phase 5: sharing and moving the bytes** (M)
- Private, workspace and public for every kind; the public viewer page; reporting and takedown.
- `chat_media` bytes move to the object store; Postgres keeps the rows.
- *Done when:* a public picture opens signed out on the pages origin and stops the moment the link
  is revoked; the database dump no longer grows with media.

**Phase 6: making more** (each its own plan)
- "+" in the Library: pick a kind, write the ask, pick a bot.
- Sites and games with real assets: `pages.publish` takes a folder (an `index.html` plus files)
  served from the pages origin, with a size cap and a CSP that allows same-origin images, audio
  and scripts.
- Pages that take input (product review, Add 3) and finished documents (Add 2). Both land in the
  Library with no new shelf to build.
- `media.audio.generate`: speech, music, sound effects.
- Duplicate a creation and change the copy.

**Later, not planned:** a public showcase, custom domains for sites, comments on a creation, the
person's own uploads as a filter.

**Rules while building** are the ones in `AGENTS.md` and the execution brief of
`docs/ANALYTICS-PLAN.md`: ask before any Flutter build and any production change, stage by path,
format only new Dart files, migrations up only, privacy page and docs in the same commit as the
code they describe.

## 12. Risks

| Risk | What we do about it |
|---|---|
| **Public links get abused** (phishing pages, unlawful media). More kinds shared means more surface | Public stays off by default, asks first, is audited and revocable. Add a Report link on every public page, a takedown switch in the admin console, a rate limit on new public links per workspace, and `noindex` everywhere. Free workspaces could be held to workspace-only sharing (§14) |
| **Store rules on user-generated content.** Apple's guideline 1.2 applies once people can see content from strangers | They can't in this plan: the Library shows only your workspace. A public showcase would need reporting and blocking first, which is why it is "later" |
| **Untrusted HTML in the screenshot service** | It already runs isolated for PDFs, with a deny list for network and file URLs. Keep the same container, add a time limit and one render at a time |
| **Storage growth before the caps land** | Phase 1 counts from day one; Phase 3 enforces. Don't promote video making before Phase 3 |
| **Bytes in Postgres inflate backups** | Phase 3 stops adding to it; Phase 5 moves what is there |
| **A third change to the tab bar in a week** (D-176, D-253, this) | Additive: the two tabs people know don't move. Mention it in What's new |
| **Shipped apps meet a new message part** | Verified they skip unknown parts; still test the oldest build in use |
| **Media and kept files are not sealed** by the workspace key (D-136, D-205) | Unchanged by this plan, but there will be more of it. Say so on the privacy page in the same commit, or seal blobs as their own piece of work |
| **The Library fills with drafts** | Stacks per run; pins; only handed-over things get in |
| **Two sources of truth for pages** | `pages` stays the truth; the creation mirrors through the trigger and the API reads visibility from the page |

## 13. How we'll know it worked

- Share of people who open something they made more than 24 hours after it was made. Today that
  is close to zero, because there is no way back but scrolling.
- `creation_open` by source: the Library should overtake the chat within a few weeks for items
  older than a day.
- `creation_change_started` per person per week: the loop of make, look, change.
- Paywall views from `storage_full`, and what they convert to.
- No rise in "where did my file go" support questions once files are kept.

## 14. Decisions for Oliver

Each has a default. Say nothing and the default holds.

| # | Question | Default | The other choice |
|---|---|---|---|
| 1 | What is the place called? | **Library** | Creations (your word; longer on a tab), Made, Studio (sounds like a tool, not a shelf) |
| 2 | A third tab, or a row inside Chats? | **Third tab** | A row under Updates: less work, much less visible |
| 3 | Tab order | **Chats, Library, Tasks** | Chats, Tasks, Library: nothing moves for people who know the two tabs |
| 4 | Do sites and games stay in the system browser? | **Yes** (D-092, the no-WebView rule) | An in-app viewer would be the first WebView in the app |
| 5 | Keep a copy of every file a reply links to? | **Yes, up to 50 MB each, 8 a reply** | Only what the bot saves on purpose: less storage, but things go missing |
| 6 | Does deleting a chat keep what was made? | **Yes**; an option deletes them too (changes D-220) | Keep D-220: delete everything with the chat |
| 7 | Storage caps | **1 / 10 / 50 / 200 GB** | Any numbers; cost is $0.015 per GB-month |
| 8 | Full storage | **Bots stop making new media and pages; nothing is deleted** | Oldest unpinned items expire: kinder to the meter, unkind to people |
| 9 | Deleted items | **Kept 30 days, with Undo** | Gone at once |
| 10 | Public links on the Free plan | **Allowed, rate-limited** | Workspace-only on Free: less abuse, less word of mouth |
| 11 | The person's own uploads in the Library | **No** | A separate Uploads filter later |
| 12 | Turn on the PDF and screenshot service in production | **Yes, at Phase 3** (a production change; needs its own yes then) | Drawn covers and bot-supplied screenshots only |
| 13 | How far to build before the launch | **Phases 1 and 2** (the shelf, with what exists) | All of 1 to 3, so no tile is ever blank at launch |
