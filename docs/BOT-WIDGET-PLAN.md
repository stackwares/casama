# Bot widgets: a bot puts what it likes on a person's widgets

Status: **in progress** (D-452). Approved 2026-11-20 with §13's defaults. Phases 1–3 written on
`feat/bot-widgets`, not built; Phase 0 and Phases 4–6 not started.

Platform rules below were checked on 2026-11-20 against Apple's and Google's own pages and against
the SDKs installed on this Mac (Xcode 27.2; iOS 27.2, macOS 27.2 and watchOS 27.2 SDKs). Sources
are at the end. This plan builds on D-405 (`docs/WIDGETS-PLAN.md`), D-324
(`docs/ISLAND-AND-MENU-BAR-PLAN.md`) and D-410 (`docs/WATCH-PLAN.md`) and does not repeat them.

## Execution brief (read this first)

**Nothing starts until Oliver approves this plan.** After that: build the phases of §15 in order,
each to its "Done when" check, then a commit. Phases 2 and 3 don't depend on each other.

- Every Flutter, Xcode or Gradle build is asked for, one at a time (`AGENTS.md`, "Flutter").
- Nothing in production without a yes for that deploy.
- §13's defaults are taken unless Oliver changes one. If a default turns out unworkable, pick the
  closest option, write down why in the decision entry, and keep going.
- New migrations: check every branch and worktree for the version number first.

## 0. Summary

A person says "show a Bible verse on my Lock Screen every morning", or "count down to my trip", or
"keep my reading streak on my home screen". Today a bot can't: Casama's nine widgets (D-405) each
show a fixed thing, the glance. This plan adds **one widget a bot fills in**, called **Canvas**, and
the tools a bot uses to fill it, so it works from a chat and from a routine.

| Part | What |
|---|---|
| Tools | `widget.set`, `widget.clear`, `widget.list` (§8) |
| What a bot can show, first version | Five templates: text, countdown, number, list, picture. A background (colour, gradient, picture or a built-in painting), a type style, an icon (§6) |
| Kept changing, cheaply | A **rotation**: the bot writes a list once and the canvas cycles through it with no further model runs. Or up to 14 dated entries in one call. Or a routine that writes on the day (§6.4) |
| Where | iPhone and iPad Home Screen, StandBy and Lock Screen; Mac desktop; Android home screen and lock screen page (§10) |
| Who may write | A bot the person allowed, once, with a preview card. Only for the person its run acts for (§11, §12) |
| Later phases | Live Activity, Dynamic Island and Android live notification for timers; a free layout; watches (§15) |

Six findings shape the plan:

1. **Most of the road exists.** D-405 built the widget key, the widget-side fetch, the refresh push
   (`GlancePusher`) and the three native widget sets. A bot's content is one more thing fetched the
   same way.
2. **The iPhone Lock Screen is small and one colour.** A rectangular widget is about 160×72 points:
   a title and two short lines. No background, no colour pictures. The bot must send a short form of
   its text, or the server cuts one (§6.3).
3. **Planned content is exact; unplanned content is "soon".** WidgetKit switches timeline entries
   on the minute with the phone offline. A change the server pushes arrives when Apple delivers it:
   "budgeted" and "opportunistic", no number published (§2.1). So the tool takes a schedule.
4. **A Live Activity is for something that ends.** Apple: "tasks and events that have a defined
   beginning and end", at most eight hours. Google bars "ambient information" about a person's
   interests in a Live Update. A daily verse belongs on the widget; a pasta timer belongs on the
   island (§2.2).
5. **Nobody can place a widget for the person on an iPhone or a Mac.** They add Canvas once by
   hand. Android can offer **Add to Home screen**. The tool's answer tells the bot whether a Canvas
   widget is placed, so it never claims something is showing when it isn't (§8.4).
6. **"Custom UI" is safe as data, never as code.** A widget draws a view tree from data, so a small
   layout schema is possible on every platform. Templates come first because they can be tuned for
   every size; the free layout is its own phase (§6.6).

## 1. What exists today

| Already built | Where | Use here |
|---|---|---|
| The glance, its route and contract | `packages/agent/src/glance.ts`, `apps/server/src/api/routes/glance.ts`, `packages/contracts/src/glance.ts` | The model for the new route: one transaction as the person, a content version, `If-None-Match` |
| Widget keys | `public.widget_keys` (`supabase/migrations/20270205100001_widget_keys.sql`), `widgetCaller` and `WIDGET_ROUTES` in `routes/glance.ts` | The Canvas widget reads with the same key; two routes join the allowlist. 120 requests an hour per key stays |
| Refresh pushes | `GlancePusher.changed(userId, {urgent})` in `packages/agent/src/glance-push.ts`; `ApnsWidgetSender`; Firebase `{kind:"glance"}`; the Cloud relay's `widget` body | Called when a canvas changes. The push still carries nothing but "changed" |
| iPhone widgets | `client/ios/CasamaWidgets/`: `Widgets.swift` (kinds), `GlanceFetch.swift` (fetch with the key, pictures through ImageIO, 3 MB cap), `GlanceTimeline.swift`, `GlanceIntents.swift` (pickers), `WidgetPush.swift` | A new kind, provider, picker and views beside them |
| Mac widgets | `client/macos/CasamaWidgetsMac/MacWidgets.swift`, sharing the iPhone's views | Canvas joins the bundle |
| Android widgets | `client/android/.../Widgets.kt`, `MoreWidgets.kt` (rows built with `RemoteViews.addView`, covers as bitmaps), `GlanceRefresh.kt` (WorkManager every 30 minutes, `GlancePushReceiver`), `WidgetConfigActivity.kt` | A new provider, layouts and picker |
| The app's side | `client/lib/features/widgets/`: `glance_sync.dart` (the carrier), `widgets_screen.dart` (Settings → Widgets, `WidgetPinner`), `widget_key_store.dart` | A canvas carrier and a section in the screen |
| Live Activities and push-to-start | `RunActivityAttributes.swift`, `IslandActivities.swift`, `LiveRunPusher` (`packages/agent/src/live-runs.ts`, through Firebase), `live_start_tokens`, Android `LiveRun.kt` | Phase 4 adds a second activity type the same way |
| Watch complications and tiles | `client/ios/CasamaWatchWidgets/Complications.swift` (ten complications), `client/wear/.../complications/`, `tiles/`; `WATCH_ROUTES` in `routes/watch.ts` | Phase 6 |
| A grant a person gives a bot once | `public.device_grants (user_id, bot_id, kind)`; `needGrant` and `askOnce` in `packages/agent/src/device-data.ts`; `PUT /v1/device-grants` (D-328) | The same shape for "may show things on my widgets" |
| Who a run acts for | `actingUserId` on `ToolContext`: the sender of a chat, the maker of a routine; null for linked-bot runs (`packages/agent/src/acting.ts`) | A canvas belongs to that person |
| Fetching a link safely | `safeFetch` (`packages/agent/src/safe-fetch.ts`): private addresses and rebinding blocked | Picture downloads go through it, with their own type and size checks |
| Picture work | `sharp` 0.34.5 in `packages/agent` (`file-ops.ts`) | Shrinking and re-encoding |
| A place for files | `ObjectStore` (`packages/sandbox/src/object-store.ts`), wired as `deps.objects` | Canvas pictures |
| Cards in chat and what a tap does | `ui.shown` with the catalog (`packages/domain/src/a2ui.ts`, `UI_COMPONENTS`); `client/lib/features/chat/local_actions.dart` (`app:` events) | The preview card and its buttons |
| Tools grouped by name | `toolGroup(name)` in `packages/agent/src/lazy-tools.ts` | `widget.*` is its own group, so its text isn't sent with every model call |

What is still unproven, from `docs/PLANS.md` and the decisions themselves:

- **D-405's widgets have not been run on a device.** Their look, the keychain group, the widget
  push on a real phone, and the Lock Screen hiding marked text are all listed as not verified.
- **The Apple push key** (`APNS_KEY_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID`) was not in production when
  D-405 was written. Without it Apple devices refresh on their own schedule only.
- **Push-to-start and Live Activity pushes** have never reached a real iPhone (D-324 §19).

This plan stands on those. Phase 0 checks them before anything new is built on top.

## 2. What the platforms allow

D-405's plan §2 holds the general widget rules. Only what matters for a bot's own content is here.

### 2.1 iPhone, iPad and Mac widgets

| Surface | Verdict | The limit |
|---|---|---|
| Home Screen small, medium, large; extra large on iPad and Mac; StandBy | Works | Full colour, pictures, system fonts in four designs. In tinted and clear Home Screens the system drops the background and takes colour out of pictures |
| Lock Screen rectangular | Works with limits | About 160×72 points (153 to 172 wide by phone). One colour. A title and two lines |
| Lock Screen inline (above the clock) | Works with limits | One line, about 25 characters, one symbol |
| Lock Screen circular | Works with limits | A number, a ring or a symbol, 72 points across |
| Mac desktop and Notification Center | Works | No Lock Screen sizes exist on the Mac |

- **No code, no web content, no video, no animation, no scrolling, no typing.** A widget is a view
  drawn from data when its timeline is built.
- **Refresh.** 40 to 70 timeline reloads a day for a widget the person looks at. Entries "at
  least about 5 minutes apart". Entries for known future moments switch by themselves, on time,
  offline. A timer or a relative date ticks by itself.
- **Refresh from the server** (version 26 and later; the SDK also has it on watchOS 26): a push
  with only `content-changed`, which "the system budgets" and "delivers opportunistically". It is
  "an additional update mechanism" that "doesn't replace timeline updates".
- **Pictures.** Apple publishes no size limit. A widget extension has little memory and refuses
  pictures much bigger than the widget, so the widget shrinks what it fetched, as it does for
  Library covers today.
- **App Review.** 2.5.16: widgets "should be related to the content and functionality of your
  app". 2.5.18: no display advertising in widgets.
- **The wallpaper** can't be changed by an app on iPhone. A widget's background is as far as it
  goes.

### 2.2 Live Activities and the Dynamic Island

| Question | Answer |
|---|---|
| Can a bot start one remotely? | Yes. Push-to-start, iOS 17.2 and later, already built for runs. The push must include an alert, so a remote start is never silent |
| Can it be planned ahead? | Only by the app while it runs (`request(… start:)`, iOS 26) |
| How long? | Eight hours active. Then up to four more on the Lock Screen: "a maximum of 12 hours" |
| How often can it change? | Priority 10 pushes have "a certain budget … per hour" with no number given; priority 5 doesn't count. The person can turn frequent updates off |
| How much data? | Static and changing data together "can't exceed … 4 KB" |
| Pictures? | "A Live Activity can't access the network". Pictures must already be on the phone and no bigger than the space they're drawn in |
| What is it for? | "Tasks and events that have a defined beginning and end." "Don't use a Live Activity to display ads or promotions." App Review 4.5.3: no unsolicited messages through Live Activities |
| The Mac? | ActivityKit is marked unavailable on macOS in the SDK. An iPhone's activities show in the Mac's menu bar. Casama's own notch (D-324) is ours to draw in |

**Verdict: works with limits, and fits only timed things.** A timer, a countdown to a moment
today, the progress of a job. A verse, a quote or a streak is standing content and goes on the
widget. A Live Activity would also be gone within twelve hours.

### 2.3 Android

| Surface | Verdict | The limit |
|---|---|---|
| Home screen widget (RemoteViews) | Works | Only these views: `LinearLayout`, `FrameLayout`, `RelativeLayout`, `GridLayout`, `TextView`, `ImageView`, `ProgressBar`, `Chronometer`, `TextClock`, buttons. "Descendants of these classes are not supported" |
| Sizes and colours | Works | A layout per size and the phone's colours on Android 12 and later, as D-405's widgets do |
| Freshness | Works | A Firebase data message wakes native code, which redraws with the app closed. This is the freshest surface |
| Lock screen | Works with limits | Phones on Android 16 QPR2 and later (Pixels first). Widgets sit on a page reached by swiping from the right of the lock screen, after the person turns it on in Settings. Every widget is eligible unless it opts out; opening anything from it asks for an unlock. Not on the lock screen's face. Other makers may differ; only Pixels were confirmed |
| Live Update (status bar chip) | Works with limits | "Ongoing, user-initiated, and time-sensitive." Not for "ads, promotions, chat messages, alerts, upcoming calendar events". "Don't show ambient information." A promoted notification may have no custom view, so it is a title, text, a progress bar and a timer |
| Add from the app | Works | `requestPinAppWidget`, where the launcher supports it (`WidgetPinner` already asks) |

- **Pictures** cross to the launcher's process as bitmaps, so they are decoded at the widget's size
  and kept small. Google's pages give no number; the widgets already do this for covers.
- **A countdown** under a day is a `Chronometer` counting down, which ticks by itself. Days are
  text, redrawn at midnight.
- **Planned entries** are switched by a one-off WorkManager job, which Android may run some minutes
  late. Exact alarms need a permission this isn't worth asking for.

### 2.4 Watches (optional, last)

| Surface | Verdict | The limit |
|---|---|---|
| Apple Watch complications and Smart Stack | Works with limits | The same WidgetKit sizes plus the corner. Tiny. D-410 built no server refresh for watch complications; watchOS 26 has the widget push |
| Wear OS complication | Works with limits | Short text, long text or a ranged value. Updates "not more often than every 5 minutes on average" |
| Wear OS tile | Works with limits | A full-screen card. Google is replacing Tiles with Wear Widgets (Wear OS 7, libraries still alpha), so a tile built now may be rebuilt later |

## 3. Goals and what this is not

Goals:

- A person asks a bot once, in their own words, and something useful or beautiful sits on their
  Home Screen or Lock Screen from then on, kept current by the bot.
- It works unattended: a routine can refresh it every morning with nobody tapping anything.
- What a bot writes always fits the place it lands, and the bot is told what was cut.
- The person decides which bots may write, what shows on a locked phone, and can clear it in one tap.
- One document, one set of rules, three platforms. The server does the deciding (what fits, which
  text colour); native code only draws.

This is not:

- A way to run a bot's code or show a web page. Never (`AGENTS.md`: no WebViews).
- A second notification channel. A canvas changes quietly. Nothing buzzes except a remotely
  started Live Activity, which Apple requires to alert.
- A team noticeboard. A canvas belongs to one person.
- A wallpaper changer.
- A replacement for D-405's nine widgets. Those show Casama's state; this shows what a bot chose.

## 4. Principles

1. **Data, never code.** A canvas is a small checked document. A widget can't do anything a bot
   wrote; it can only draw it.
2. **The person opens the door once per bot.** After that the bot keeps its canvas current without
   asking, or routines would be useless.
3. **It always fits.** Every entry carries a plain short form, so the Lock Screen, a watch and an
   older app can always draw something true.
4. **We choose the text colour.** A bot picks the background; the server picks light or dark text
   for contrast. A bot can't make an unreadable widget.
5. **A tap goes to Casama.** Never to a link the bot chose.
6. **Planned beats pushed.** For anything with a known time, the bot hands over the entries ahead
   and the widget switches by itself.
7. **Say where it shows.** The tool's answer names the surfaces the content is on, or says none
   yet. The bot repeats that, not a guess.
8. **Nothing private by accident.** A bot marks private content; the person has the last word per
   canvas; the app lock rule from D-405 applies on top.

## 5. Words

| In the app and docs | Meaning | Not |
|---|---|---|
| **Canvas** | The widget a bot fills in, and what one bot keeps on it for one person | board (that is Tasks), card (that is chat), pin (that is a bot on the home screen) |
| **entry** | One thing a canvas shows, with the time it shows from | slide, frame |
| **rotation** | A list of entries a canvas cycles through on a rhythm, written once | source, playlist, deck, feed |
| **Show on my widgets** | The button that lets a bot write, the first time | approve, grant |
| **Hide on a locked phone** | The per-canvas switch | privacy mode |
| **From your bots** | The section of Settings → Widgets that lists canvases | bot content |
| **live** | Shown as a Live Activity or live notification (Phase 4) | pinned, sticky |

In code the document is a `canvas`, in `widget_canvases`. The tools keep Oliver's name, `widget.*`.

## 6. What a bot can show

### 6.1 Templates (first version)

| Template | For | Fields |
|---|---|---|
| `text` | A verse, a quote, a note, a status line | `title`, `text`, `footer`, `icon` |
| `countdown` | Days to a trip, minutes to leaving | `title`, `target` (a time), `footer`, `icon`. Counts up after the target when `count: "up"` |
| `number` | A streak, a score, steps toward a goal | `title`, `value`, `of` (the goal, optional: draws a ring or bar), `unit`, `footer` |
| `list` | Today's three priorities, a shopping list | `title`, up to 5 `items` (`text`, `done`) |
| `picture` | A photo or painting, with or without a caption | `picture`, `text` (the caption), `footer` |

Every entry may also carry `short` (80 characters, for the Lock Screen rectangle and watches) and
`tiny` (24 characters, for the line above the clock). When a bot leaves them out the server makes
them: text cut at a word, the footer kept ("Be still, and know that I am God. · Ps 46:10").

### 6.2 The look

| Choice | Options | Who decides |
|---|---|---|
| Background | `auto` (white, or the app's dark grey: D-380), one colour, a two-colour gradient, a picture, or a built-in painting by name | The bot |
| Text colour | Light or dark | The server, for contrast. A picture gets a soft shade behind the text |
| Type style | `plain`, `serif`, `rounded`, `mono` (the system's own font designs; Android maps `rounded` to its default) | The bot |
| Alignment | `start` or `center` | The bot |
| Icon | One emoji, or a name from the app's icon set | The bot |
| Accent (rings, bars) | The bot's own colour unless one is given | The bot |

The system's rules win where they apply: the Lock Screen is one colour, a tinted Home Screen drops
the background, and text size follows the person's setting.

**Pictures** come from an https link, a creation in the Library, or a file on the bot's computer.
The server fetches the link through `safeFetch`, accepts only JPEG, PNG, WebP or HEIC up to 10 MB,
drops metadata, shrinks to fit 1200×1200 and re-encodes as JPEG under 400 KB. It also records
whether the picture is light or dark, so every platform picks the same text colour. Widgets fetch
the picture from our server with the widget key. A widget never loads a link a bot gave.

**Built-in paintings** (decision 7): eight painted backgrounds with room for text, named so a bot
can ask for `sunrise` or `night sky` without making or finding a picture.

### 6.3 What each place draws

| Template | Home small | Home medium, Android 4×2 | Home large | Lock rectangle | Line above the clock | Lock circle |
|---|---|---|---|---|---|---|
| `text` | Title, up to 6 lines, footer | The same, wider | Larger type, up to 12 lines | Title and two lines of `short` | Icon and `tiny` | The icon |
| `countdown` | The time left, large; title | Adds the footer and the date | Adds `text` | Time left and title | "Trip in 12 days" | Days, or hours and minutes |
| `number` | The value in a ring | Ring, title, footer | Adds `text` | Value, unit, a bar | Value and unit | The ring |
| `list` | 3 rows | 4 rows | Title and 5 rows | 2 rows | The first row | How many are left |
| `picture` | The picture, caption over it | The same | The same | The caption | `tiny` | The icon |

Android's lock screen page draws the home screen layouts. The Mac draws the Home Screen column.
Home Screen sizes carry the bot's mark, small, in a corner, so the person can tell whose it is.

### 6.4 Entries and time

A model run costs credits; a widget switching entries costs nothing. So there are three ways to
keep a canvas changing, cheapest first, and the tool's description tells the bot to pick the
cheapest one that fits:

| Way | Model runs | For |
|---|---|---|
| **A rotation.** The bot writes a list once; the canvas cycles through it | One, ever, or one more whenever the list is refreshed | Things that don't go out of date: verses, quotes, words to learn, photos, affirmations |
| **A schedule.** Up to 14 dated entries in one write | One a fortnight for something daily | Things written for particular days: this week's plan, a reading for each date |
| **A write on the day,** from a routine | One per change | Things only knowable that day: a headline, the weather, what's on the calendar |

**Rotations**

- The bot gives the list and a rhythm: every day or week at a time ("06:00", in the person's time
  zone, from `profiles.timezone`), or every 1 to 23 hours. In order or shuffled. At the end it
  starts again, or stops on the last one.
- Up to 400 items, enough for a year of days. Given in the call, up to 60 at a time with `append`
  for more, or as a file: a list on the bot's computer or a creation in the Library (JSON, CSV, or
  plain text with one item per line). A file lets the bot build a long list with a script instead
  of writing every item out through the model.
- Every item is an entry like any other: the same templates, short forms and limits. The look can
  be set once for the whole list (one painting, a new verse each day) or per item.
- **Nothing runs each day.** Which item shows is worked out from the clock: the start time, the
  rhythm and the order give the item for any moment. The server hands a widget the next 14 as dated
  entries, so widgets treat a rotation exactly like a schedule and switch on the minute, offline,
  for up to 14 switches ahead. Their ordinary refreshes pull the window forward. No push, no
  routine, no write.
- A shuffle is the same on every device: it is made from the canvas's id and the lap number, not
  from chance.
- `widget.list` tells the bot where a rotation stands and how many items are left before it loops
  or stops, so a monthly routine can top it up if the person wants fresh ones.

**Schedules and single writes**

- Without a rotation a canvas holds 1 to 14 entries. The first shows now; each later one has a
  time it shows from.
- Entries must be at least 5 minutes apart.
- When the last entry's time has passed, the last entry stays until the bot writes again.

**Both**

- `until` clears the canvas by itself at a time. A countdown's default is a day after its target.

Not in this plan: a canvas fed straight from a link (a feed or an API) with no bot in between. It
would put words nobody chose on a Lock Screen, and the server would have to poll. A routine that
reads the feed and writes a fortnight's schedule does the same job for one run a fortnight.

### 6.5 States

| State | What the widget shows |
|---|---|
| No canvas yet | "Ask a bot to put something here", with one example |
| Waiting for the person's yes | Nothing new; the chat has the preview card |
| Private key (app lock on, D-405) | The canvas's name and bot, no content, until **Show details in widgets** is on |
| **Hide on a locked phone** on | The title only while locked |
| The bot was deleted or its switch turned off | Back to "no canvas yet" |
| Out of date and can't refresh | The content, and "as of 9:41" when a countdown or a dated entry would otherwise be wrong |
| Signed out | The same as D-405's widgets |

### 6.6 The free layout (Phase 5, its own short plan)

A sixth template, `layout`: a flat list of components in A2UI's shape, so bots don't learn a second
vocabulary. `Column`, `Row`, `Text`, `Image`, `Icon`, `Divider`, plus three that only widgets have:
`Gauge`, `Timer` and `Spacer`. No inputs, tabs, lists that scroll, media players or buttons with a
bot's own events. At most 24 components, four levels deep, Home Screen sizes only. The Lock Screen
and watches always draw the entry's `short` and `tiny`, which stay required. Checked by
`checkComponents` (`packages/domain/src/a2ui.ts`) with a widget profile. Drawn by a small recursive
view in SwiftUI, by `RemoteViews.addView` with one layout file per component on Android, and by the
app's own catalog in Flutter.

## 7. Data model

One migration (version chosen after checking every branch and worktree).

**`public.widget_canvases`**

| Column | Holds |
|---|---|
| `id`, `org_id`, `user_id`, `bot_id` | The canvas, its workspace, the person it is for, the bot that writes it. Cascades from each |
| `name` | A short name the bot gives ("Daily verse"), 40 characters, unique per person and bot. Default "Main" |
| `content` | The checked document: entries and look, or a rotation's items, rhythm, order and start time. Its words are sealed where the workspace seals text (D-238) and opened in code when read. A rotation moving on changes nothing here |
| `version` | Goes up on every write. The route's `ETag` and the picture cache use it |
| `status` | `waiting` (written before the person said yes), `shown`, `paused` (the person paused it) |
| `hide_when_locked` | Set from the bot's `private` on the first write; the person can change it |
| `live` | Phase 4: whether it is also a Live Activity, and until when |
| `until` | When it clears by itself |
| `set_at`, `set_by_run` | When, and which run, for the link back to the chat |
| `writes_hour`, `writes_day` and their window starts | The write limits of §12.3 |

- Row-level security: a person reads and deletes their own, and changes only `status` (to pause or
  resume) and `hide_when_locked`. Bots write through the worker (`public.allow_worker`).
- The trigger that deletes a person's widget and watch keys when they leave a workspace (D-410's
  audit) also deletes their canvases.
- Account deletion and the data export include canvases and their pictures.

**The grant.** `device_grants` gains the kind `widgets`: "this bot may show things on my devices".
It is per person and per bot, which is what's needed, and `PUT /v1/device-grants` and its settings
already exist. Action rules don't fit: they belong to a workspace, so one teammate's "always allow"
would let a bot write on another's Lock Screen.

**`widget_keys`** gains `canvas_seen`: which Canvas sizes this device last asked for, and when. It
is how the server knows whether a Canvas widget is placed (§8.4).

**Pictures** live in the object store at `canvases/<org>/<canvas>/<hash>.jpg`. A write removes the
pictures the new content no longer names. Built-in paintings are served from the server's own
files under fixed names.

**The contract** (`packages/contracts/src/canvas.ts`): `Canvas` (id, name, bot's id, name and mark,
version, when set, `hide_when_locked`, entries), `CanvasEntry` (§6.1's fields, `short`, `tiny`,
`at`, the look, the picture's hash and tone) and `CanvasList` (up to 12). Sample canvases in
`packages/contracts/fixtures/canvases.json` are read by the server's, the app's, the Swift and the
Kotlin tests, so four renderers are checked against the same inputs.

## 8. The bot's tools

In `packages/agent/src/tools/widgets.ts`. Named `widget.*`, so they form their own group in the
lazy tool index and cost nothing in calls that don't need them.

### 8.1 `widget.set`

Low risk. It changes nothing outside Casama and costs nothing, so it never goes through the
approval flow; the grant of §11.1 is its gate.

| Argument | Meaning |
|---|---|
| `name` | Which canvas. A new name makes a new one. Left out: "Main" |
| `template` and its fields | §6.1 |
| `short`, `tiny` | Optional short forms |
| `background`, `font`, `align`, `icon`, `accent` | §6.2 |
| `schedule` | Up to 13 more entries, each with `at` and its own fields |
| `rotate` | Makes it a rotation: `every` (`day`, `week`, or 1 to 23 hours), `at` (a time of day), `order` (`in_order` or `shuffle`), `then` (`loop` or `stop`) |
| `items`, `items_file`, `append` | The rotation's list: up to 60 items in the call, or a file on the bot's computer or a Library creation; `append` adds to the list already there |
| `until` | When to clear it |
| `private` | True when it shouldn't be read on a locked phone |
| `live` | Phase 4: also show it on the Dynamic Island and as a live notification. Only a countdown or number that ends within 8 hours |

The description tells the bot, in a few lines: what fits where, that a schedule is better than a
write at the moment, never to put secrets, codes or another person's details on a widget, never an
advertisement, and to say where it is showing only from the tool's answer.

### 8.2 `widget.clear`

`name`, or everything this bot shows this person. Low risk.

### 8.3 `widget.list`

Read-only. This bot's canvases for this person: what each shows now, what comes next, where it is
placed, and what is left of today's writes. It is how a bot answers "what's on my widget?".

### 8.4 What `widget.set` answers

| Case | The answer the bot reads |
|---|---|
| Allowed, a Canvas widget placed | "Showing on Oliver's iPhone Lock Screen and Mac. The Lock Screen shows: 'Be still, and know… · Ps 46:10'." |
| Allowed, no Canvas widget anywhere | "Saved. Oliver hasn't added the Canvas widget yet. A card in the chat shows how; say so." |
| Not allowed yet | "Oliver has a preview with a **Show on my widgets** button. It will show once they tap it. End your turn." |
| Cut to fit | Names what was cut and where |
| Over a limit | The limit and what to do instead ("use `schedule` to plan changes ahead") |
| No person (`actingUserId` is null) | "This run isn't working for one person, so it has no widgets to write to." |

### 8.5 The preview card

Every `widget.set` from a chat puts a card in that chat: the canvas drawn as the widget will draw
it, by a new catalog component, `WidgetPreview` (older apps skip a card they don't know, as with
Casama's other cards). Its buttons depend on the case:

- **Show on my widgets** and **Not now**, the first time for this bot (`app:widget_allow`).
- **Add to Home screen** on Android when no Canvas widget is placed (`app:widget_add`), and the
  steps for iPhone, iPad and Mac, where an app can't add a widget.
- None when it's already showing.

A write from a routine posts no card unless the bot isn't allowed yet. Then the card lands in the
bot's chat and waits there.

## 9. Server

### 9.1 Pieces

| Piece | Where |
|---|---|
| Rules: limits, checking a document, cutting `short` and `tiny`, contrast | `packages/domain/src/canvas.ts` |
| The store: set, clear, list, allow, the write limits | `packages/agent/src/canvas.ts` |
| Pictures: fetch, check, shrink, tone, store, clean up | `packages/agent/src/canvas-pictures.ts` |
| Tools | `packages/agent/src/tools/widgets.ts` |
| Routes | `apps/server/src/api/routes/canvas.ts` |
| The catalog component | `packages/domain/src/a2ui.ts` (`WidgetPreview`), `packages/agent/src/tools/ui-catalog.ts` |

### 9.2 Routes

| Route | Who | Does |
|---|---|---|
| `GET /v1/canvases?org_id=` | Session, `Widget <key>`, later `Watch <key>` | The person's shown canvases, up to 12, each with at most 14 entries: a rotation is dealt here as its next 14, dated. `ETag` (the version, and for a rotation the item it starts at) and `If-None-Match`. A `sizes` parameter says which sizes the caller draws, saved to `canvas_seen`. A private key gets names and bots only |
| `GET /v1/canvases/:id/pictures/:hash` | Session, `Widget <key>` | The JPEG. Private, cached for good: the hash is in the address |
| `PATCH /v1/canvases/:id` | Session | Pause or resume; **Hide on a locked phone** |
| `DELETE /v1/canvases/:id` | Session | Clear it |
| `PUT /v1/device-grants` (exists) | Session | With kind `widgets`: allowing a bot also shows what it left waiting; turning it off clears what it was showing |

`WIDGET_ROUTES` gains the two `GET`s. A widget key still can't write anything.

The canvases stay out of the glance. The glance is about 6 KB and is fetched by every widget; a
person's canvases could be several times that. The glance gains one small number,
`canvases_version`, so a caller that just read the glance knows whether to ask for canvases.

### 9.3 Pushes

- A shown canvas that changes calls `GlancePusher.changed(userId, {urgent: true})`. Apple devices
  get the same empty widget push and Android the same data message, with `kind: "canvas"` so it
  fetches canvases only. Linked self-hosted servers go through the Cloud relay's `widget` body
  unchanged.
- The write limits of §12.3 are also the push limits: no more pushes than writes.
- Nothing is pushed at an entry's time. iPhones and Macs switch by their own timeline; Android by
  its own job (§10.2).

## 10. Clients

### 10.1 iPhone, iPad and Mac

| Piece | Where | Notes |
|---|---|---|
| Decoding and the store | `client/ios/CasamaWidgets/Canvas.swift` | The App Group key `canvases`, beside `glance` |
| Fetch | `CanvasFetch` in the same file, using `GlanceFetch`'s session and key | Pictures saved in the App Group, shrunk with ImageIO to the largest size this device draws |
| The picker | `CanvasIntents.swift`: `WidgetCanvasEntity`, `ChooseCanvasIntent` | **Automatic** (whatever an allowed bot set last) or one named canvas |
| The timeline | `CanvasTimeline.swift`: `CanvasProvider` | An entry per dated entry ahead; one per midnight for a countdown in days; timers tick by themselves |
| Views | `WidgetViews/CanvasViews.swift` | Five templates across small, medium, large, extra large, the three Lock Screen sizes; full colour, tinted, clear and the Lock Screen's look |
| The widget | `Widgets.swift`: kind `CanvasWidget` | Refreshed by push where the system has it, through `GlanceBundle.refreshable` |
| The Mac | `client/macos/CasamaWidgetsMac/MacWidgets.swift` | The same views, Home Screen sizes |

- `privacySensitive()` on the content when **Hide on a locked phone** is on. Whether iOS hides it
  is one of Phase 0's checks; if it doesn't, the Lock Screen sizes draw the title only.
- A tap opens `casama://app/canvases/<id>`, which the router sends to the bot's chat at the
  message that set it.
- Asks not to be shown in CarPlay, as Brief and Tasks do.
- No buttons in the first version.

### 10.2 Android

| Piece | Where | Notes |
|---|---|---|
| The store | `CanvasStore.kt`, beside `GlanceStore.kt` | |
| The widget | `CanvasWidget : CasamaWidget()` in a new `CanvasWidget.kt`; `res/xml/canvas_widget_info.xml` | Resizable from 2×1 to 5×4; `home_screen|keyguard`; can be placed without choosing and changed later |
| Layouts | `res/layout/widget_canvas_*.xml`, one per template and a compact one for small sizes | A size map on Android 12 and later |
| Type styles | A `TypefaceSpan` on the text (`serif`, `monospace`, default) | Spans cross to the launcher; no layout per font |
| Backgrounds | A colour as a tint on the rounded background; a gradient or picture as one bitmap in an `ImageView` | One bitmap shared by every size, decoded at the widget's largest size; the colour is drawn when a picture won't fit |
| Countdown | `Chronometer` counting down under a day; text for days | |
| Fetch and time | `GlanceRefresh.kt`: a `canvas` push fetches canvases; a one-off job for the next entry's time; the 30-minute job covers both | |
| The picker | `WidgetConfigActivity.kt` | Automatic or a named canvas |
| Add from the app | `WidgetPinner` | With the canvas already chosen |
| Locked | The `keyguard` host draws the title only when **Hide on a locked phone** is on | As D-405's widgets draw private there |

### 10.3 The app (Flutter)

| Piece | Where |
|---|---|
| The model | `client/lib/features/widgets/canvas.dart` |
| The carrier: fetch when the app opens, comes forward or a chat shows a preview; write the shared store; ask widgets to redraw | `client/lib/features/widgets/canvas_sync.dart`; on the Mac through `casama/mac` → `glance`, as today |
| Drawing a canvas in Flutter, for the preview card and Settings | `client/lib/features/widgets/canvas_view.dart` |
| The card | `WidgetPreview` in the app's A2UI catalog; `app:widget_allow` and `app:widget_add` in `client/lib/features/chat/local_actions.dart` |
| Settings | **From your bots** in `widgets_screen.dart` (§11.2) |
| The route `/canvases/:id` | `client/lib/core/router.dart` |
| Backend | `backend.dart`, `supabase_backend.dart`, `test/fake_backend.dart`: `canvases`, `updateCanvas`, `clearCanvas` |
| Words | `client/lib/l10n/app_en.arb`; the widgets' own words go through `glance_words` as D-405's do |

Web, Windows and Linux have no widgets. The preview card still draws there, and the tool's answer
says which devices are showing the canvas.

### 10.4 Live: the Dynamic Island, the Lock Screen banner and Android's live notification (Phase 4)

- **A second activity type,** `BotActivityAttributes`, beside `RunActivityAttributes`: the canvas,
  the bot's name and mark, a link, the words; and a state of one template (`countdown`, `number` or
  `text`), a title, a line of text, a target time, a value and goal, an icon and one of eight fixed
  tints. No pictures: an activity can't fetch them.
- **Started** by the app when it is in front, else by push-to-start. Push-to-start tokens are per
  activity type, so `live_start_tokens` gains a kind. Sent through Firebase, as D-324 decided.
- **Ends** at the target or `until`, and leaves the Lock Screen 15 minutes later.
- **Android:** an ongoing notification on its own quiet channel, drawn by a sibling of
  `LiveRun.kt`. On Android 16 and later a countdown or progress asks to be a Live Update (standard
  style, no custom view); otherwise our own layout.
- **Rules the tool enforces:** only `countdown` and `number`; ends within 8 hours; the run was
  started by the person in a chat or is a routine they made; at most two at a time per person. A
  remote start alerts, because Apple requires it, with the canvas's title as its words.
- **The Mac notch** shows the same row through the island feed.

### 10.5 Watches (Phase 6)

- **Apple Watch:** `WatchCanvasWidget` in `Complications.swift` (rectangle, circle, inline,
  corner), fetched with the watch key; `WATCH_ROUTES` gains `GET /v1/canvases`. The widget push
  for watchOS 26, which D-410 left unbuilt, comes with it.
- **Wear OS:** a complication service (short text, long text, ranged value) and a tile, refreshed
  from the watch's own Firebase message, no more than every 5 minutes. Whether to build the tile
  or wait for Wear Widgets is decided then.

## 11. What the person controls

### 11.1 The first time

1. A bot calls `widget.set` for someone who hasn't allowed it. The canvas is saved as `waiting`.
2. The chat shows the preview with **Show on my widgets** and **Not now**.
3. **Show on my widgets** gives the bot the grant and shows the canvas. From then on that bot
   writes without asking.
4. **Not now** deletes the waiting canvas. The bot may ask again another day; it gets no grant.

### 11.2 Settings → Widgets → From your bots

- Each canvas: its preview, its bot, when it was set, where it is showing, **Hide on a locked
  phone**, **Pause**, **Clear**.
- Each bot that may write: one switch, **May show things on your widgets**. Off clears what it was
  showing.
- Canvas joins the list of widgets above it, with **Add to Home screen** on Android and the steps
  on Apple devices.

### 11.3 Which widget shows what

The person chooses, in each placed widget's own settings: **Automatic** or one named canvas. A bot
chooses only which canvas it writes. It can't move itself onto a widget the person pointed
elsewhere.

## 12. Privacy, safety and limits

### 12.1 Privacy

- **A locked phone.** Anyone who picks the phone up can read a Lock Screen widget. Content shows
  there by default, because the person asked for it there (decision 9). A bot sets `private` for
  anything personal; the person's **Hide on a locked phone** switch decides in the end.
- **App lock on (D-375, D-405).** The widget key is private: canvases show their name and bot only,
  until **Show details in widgets** is on. A workspace that requires the app lock keeps it so.
- **Pushes are still empty.** Apple, Google and the Cloud relay learn that something changed, not
  what.
- **At rest,** a canvas's words are sealed as the workspace's other text is.
- **Teams.** A canvas is for the person a run acts for. A run that acts for nobody (a linked bot's)
  can't write one. A bot shared by a team keeps a separate canvas per person.

### 12.2 Safety

- **A bot that read something hostile** (a web page, an email) could be talked into writing its
  words onto a widget. What limits the harm: only a bot the person allowed can write; a canvas is
  text and pictures with no links; a tap opens Casama; Home Screen sizes name the bot; **Clear** is
  one tap. Asking for approval on every write after untrusted content would break "show me today's
  headline", so it doesn't.
- **Pictures** are fetched by the server through `safeFetch`, decoded and re-encoded, so a widget
  never opens a file or an address a bot chose.
- **No advertising.** The tool's description forbids it and App Review 2.5.18 requires it. A
  gallery bot gets the same one-time question as any other.
- **Live** follows §10.4's rules, which are Apple's and Google's.

### 12.3 Limits

Held in `packages/domain/src/canvas.ts` and enforced in the store, so every path meets them.

| Limit | Value |
|---|---|
| Canvases per bot, per person | 3 |
| Canvases per person, per workspace | 12 |
| Entries per canvas | 14, at least 5 minutes apart |
| A rotation | 400 items; 60 per call; a rhythm of one hour or longer; 30 different pictures |
| Writes per canvas | 6 an hour, 30 a day |
| Writes per person, all canvases | 60 a day |
| Text | `title` 60, `text` 280, `footer` 40, `short` 80, `tiny` 24, a list row 60 |
| Pictures | 10 MB in; 1200×1200 and 400 KB kept; one per entry |
| Live at once, per person | 2 |

## 13. Decisions for Oliver

Each has a default this plan assumes. Say "defaults" to take them all.

| # | Decision | Default |
|---|---|---|
| 1 | The widget's name | **Canvas**. Others considered: "From your bot", "Bot's pick" |
| 2 | The tools | `widget.set`, `widget.clear`, `widget.list` |
| 3 | When a bot must ask | **Once per bot, with a preview and Show on my widgets.** After that it writes without asking, from chats and routines. The other choices: ask every time (routines stop working) or never (any bot can take a widget over) |
| 4 | How many canvases | **Up to 3 named canvases per bot**, and the person points each widget at one or at Automatic. The other choice is one per bot, where a countdown replaces the verse |
| 5 | What a bot can show first | **The five templates.** The free layout is Phase 5 with its own short plan |
| 6 | How much of the look a bot controls | **Background, type style, alignment, icon, accent. We choose the text colour.** The other choice is full control, and unreadable widgets |
| 7 | Built-in paintings | **Yes, eight**, made with the image model `AGENTS.md` names, in Phase 1. The standing yes for pictures covers web pages only, so this is asked here |
| 8 | Where pictures come from | **A link, a Library creation or a file on the bot's computer**, always fetched, shrunk and kept by our server |
| 9 | A locked phone | **Shows by default; the bot marks private content; the person can hide any canvas.** The other choice is hidden by default, which defeats "a verse on my Lock Screen" until a switch is found |
| 10 | What a tap does | **Opens the bot's chat at the message that set it.** No links or buttons from the bot in the first version |
| 11 | The limits of §12.3 | As listed |
| 12 | Live Activities and the island | **Phase 4, only a countdown or a number that ends within 8 hours.** Never standing content, on Apple's and Google's rules |
| 13 | Teams | **A canvas is one person's.** A canvas a whole team sees is not in this plan |
| 14 | Android's lock screen | **The lock screen widgets page only.** No standing notification to reach the lock screen's face, and no wallpaper change |
| 15 | Plans | **Every plan, Free included.** It costs nothing to serve; a routine that refreshes it spends credits as any routine does |
| 16 | Watches | **Last phase.** Wear OS tile or Wear Widgets decided then |
| 17 | The grant | **A `widgets` kind in `device_grants`**, shown with the bot's other device access. The other choice is a table of its own |
| 18 | Phase 0 | **Check D-405 and D-324 on real devices first** (§15). It needs an iOS and an Android build and the Apple push key in production |
| 19 | Rotations (§6.4): a list written once that the canvas cycles through with no further model runs | **Yes, in Phase 1.** Up to 400 items, hourly at the fastest, in order or shuffled, looping by default. A canvas fed straight from a link with no bot in between stays out |

## 14. Tests

| Where | What |
|---|---|
| `packages/domain/test/canvas.test.ts` | Every limit; each template's required fields; cutting `short` and `tiny` at a word with the footer kept; contrast for colours, gradients and picture tones; entries too close or out of order. Rotations: the item for any moment, in order and shuffled; the same shuffle for the same canvas and lap; looping and stopping; a daily rhythm across a clock change and in another time zone; the next 14 dealt as dated entries |
| `packages/agent/test/canvas.test.ts` | Set, replace, clear, list; a rotation from the call, from a file and with `append`; a rotation moving on writes nothing and pushes nothing; waiting until allowed, then shown; **Not now** deletes; hourly and daily write limits; a run with no person is refused; one person's canvas is never another's on a shared bot; turning the grant off clears |
| `packages/agent/test/canvas-pictures.test.ts` | A private address is refused; a wrong type and an oversize file are refused; the output is a JPEG within size; metadata is gone; unused pictures are removed on the next write |
| `packages/agent/test/tools-widgets.test.ts` | Each answer of §8.4; the preview card and its buttons per case; no card from a routine that is allowed |
| `apps/server/test/canvas.test.ts` | Each route with a session and with a widget key; a widget key can't write; `ETag` answers 304; a private key gets no content; another person's canvas is 404; `canvas_seen` is saved; `GlancePusher.changed` is called on a shown write and not on a waiting one |
| `supabase/tests/widget_canvases_rls.test.sql` | A person reads and deletes only their own, changes only the two columns, inserts nothing; the worker writes; leaving a workspace deletes |
| `client/test/canvas_test.dart`, `canvas_settings_test.dart` | The model against the shared samples; the carrier writes the store and redraws; the preview card's buttons; the settings rows and switches |
| Swift and Kotlin | Type-checked as D-405 was; decoding and timeline building tested against the shared samples, in scripts like `scripts/test-watch-swift.sh` and `scripts/test-wear-kotlin.sh` |
| On devices | Each phase's "Done when" (§15) |

While building, only the files that changed. The full set once at the end, through
`scripts/heavy.sh`.

## 15. Phases

| Phase | What | Done when | Needs from Oliver |
|---|---|---|---|
| **0. The ground** | On a real iPhone and a real Android phone: a D-405 widget draws; it fetches with its key with Casama closed; a server push reloads it; marked text hides on a locked iPhone. Fix what fails | All four seen on both phones, and written into D-405's entry | An iOS build and an Android build; the Apple push key in production; a deploy if D-405's server side isn't live |
| **1. Server, tools and the app** | The contract and shared samples, the rules, the migration, the store, rotations, pictures, the built-in paintings, the three tools, the routes, the grant, the push hook; in the app the model, the carrier, the preview card, **Show on my widgets**, **From your bots**, the words, analytics | Tests of §14 for the server and the app green. On the local stack: a chat sets a canvas, the card previews it, the button shows it, `GET /v1/canvases` returns it with a widget key, and a routine replaces it unattended | A yes for the paintings (decision 7) |
| **2. iPhone, iPad and Mac** | The Canvas widget, picker, timeline and views; the Mac target | Simulator pictures of five templates in every size, light, dark, tinted, clear and on the Lock Screen. On an iPhone: add it to the Home Screen and the Lock Screen, ask a bot for a verse, see it; plan seven entries and see the next one switch at its minute with the phone offline; lock the phone with **Hide on a locked phone** on | An iOS build and a Mac build; a real iPhone |
| **3. Android** | The Canvas widget, layouts, picker, **Add to Home screen**, the planned-entry job | The emulator on Android 17 and Android 11: every template and size, light and dark. On a phone with Casama swiped away: a bot's change shows within a minute; the lock screen page draws it and hides it when asked | An Android build; a real phone, a Pixel for the lock screen page |
| **4. Live** | `BotActivityAttributes`, its views, push-to-start for it; Android's live notification and Live Update; the tool's `live`; the Mac notch row | On an iPhone: "time 9 minutes for the pasta" shows on the island and the Lock Screen and ends itself; the same with Casama closed, started by push. On Android 16 or later: the chip counts down | Builds; real phones (the Simulator delivers no Live Activity pushes) |
| **5. The free layout** | §6.6, after a short plan of its own | That plan's checks | Its decisions |
| **6. Watches** | §10.5 | A canvas on an Apple Watch face and a Wear OS face, refreshed with the phone away | Watch builds; real watches |

Every phase ends with its tests green, a decision entry, the docs of §18 and a commit. Phase 1
needs no device and can start while Phase 0 waits for builds.

## 16. Risks

| Risk | What we do |
|---|---|
| D-405's ground doesn't hold on a real device | Phase 0 finds out before anything is built on it |
| Apple delays or drops widget pushes | A schedule switches without one; a pushed change still arrives on the widget's own refresh; old content says its age when that matters |
| A bot writes too much, or something ugly | Templates; the server cuts and tells the bot what it cut; we choose the text colour; the person sees a preview in the chat |
| Hostile text ends up on a Lock Screen | §12.2 |
| A person is surprised by private content on a locked phone | The bot is told to mark it; the switch is on the canvas's row in Settings; the app lock hides everything |
| App Review reads Canvas as a place for ads or spam | Content comes only from a bot the person allowed, in their own account; the tool forbids ads; Live is kept to timed things the person asked for |
| Four renderers drift apart (SwiftUI, RemoteViews, Flutter, later the watches) | The server decides fit and colour; one set of sample canvases feeds every renderer's tests |
| Android launchers draw or limit widgets differently | The system's corner radius and colours, one shared bitmap kept small, the colour as a fallback; checks on a Pixel and a Samsung |
| Android runs a planned switch late | Accepted for the first version. If it matters, the server sends Android a refresh at entry times |
| A bot forgets its canvas and it goes stale | `until`; a countdown clears a day after its target; **Clear** in Settings |
| Pictures pile up in storage | 400 KB each, at most 14 per canvas, removed when replaced and with the canvas |
| The free layout looks bad in small sizes | Home Screen sizes only; the short forms stay required; its own plan and device checks |

## 17. Cost

Nothing new is paid for. Apple's push service and Firebase are free. The server adds one small
indexed read per Canvas refresh, answered "not changed" most of the time, and a few hundred
kilobytes of stored pictures per canvas. `docs/COSTS.md` gets a zero-cost line. A bot that makes a
picture for a background uses the image tool that already exists, with its own cost and approval.
A routine that refreshes a canvas spends credits as any routine does. That is the one cost a
person feels, and §6.4 is built around it: a rotation spends one run for a year of daily changes,
a schedule one a fortnight, and only content that can't be known ahead needs a run a day.

## 18. How we'll know it worked, and docs

Added to `packages/contracts/analytics/catalog.json`. No names, titles or text.

- `canvas_set` (server): `template`, `has_picture`, how many entries, `trigger` (chat or routine),
  whether it was the bot's first.
- `canvas_allowed` (app): **Show on my widgets** or **Not now**.
- `widgets_placed` gains the Canvas count and whether one is on the Lock Screen.
- `feature_used` gains `canvas_set`.

What we watch: the share of active people with a canvas; how many of them placed the widget (the
gap is the "add it by hand" step); the share of canvases kept current by a routine; whether people
with a canvas come back on more days.

Docs in the same commits as the code: a section in `docs-site/guide/widgets.md` and
`lock-screen.md`; the tools in the bots' reference; a line in the privacy page about the Lock
Screen; `docs/ARCHITECTURE.md`'s file map; the decision entry.

## 19. Left for Oliver

- §13's answers, or "defaults".
- A yes to build, then builds and deploys one at a time as each phase asks.
- The Apple push key in production, if it isn't there yet.
- Real devices: an iPhone on iOS 26 or later, an Android phone (a Pixel for the lock screen page),
  and for Phase 6 the watches.

## Sources

- The installed SDKs (Xcode 27.2): `WidgetKit` and `ActivityKit` in the iOS 27.2, macOS 27.2 and
  watchOS 27.2 SDKs, read for which sizes, push handlers and activity calls exist where
  (`WidgetPushHandler` on iOS, macOS and watchOS 26; `request(… start:)` on iOS 26; ActivityKit
  unavailable on macOS).
- Apple, "Starting and updating Live Activities with ActivityKit push notifications":
  https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications
- Apple, "Displaying live data with Live Activities":
  https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- Apple, Human Interface Guidelines, "Live Activities" and "Widgets":
  https://developer.apple.com/design/human-interface-guidelines/live-activities,
  https://developer.apple.com/design/human-interface-guidelines/widgets
- Apple, "Updating widgets with WidgetKit push notifications":
  https://developer.apple.com/documentation/widgetkit/updating-widgets-with-widgetkit-push-notifications
- Apple, "Keeping a widget up to date":
  https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- Apple, App Review Guidelines (2.5.16, 2.5.18, 4.5.3):
  https://developer.apple.com/app-store/review/guidelines/
- Apple, WWDC26 "Live Activities essentials": https://developer.apple.com/videos/play/wwdc2026/223/
- Android Developers Blog, "Widgets on lock screen: FAQ":
  https://android-developers.googleblog.com/2025/03/widgets-on-lock-screen-faq.html
- Android Authority, lock screen widgets on Pixel phones in Android 16 QPR2:
  https://www.androidauthority.com/android-16-qpr2-lock-screen-widgets-pixel-phones-how-use-3621781/
- Android Developers, "Create a Live Update notification":
  https://developer.android.com/develop/ui/views/notifications/live-update
- Android Developers, `RemoteViews`: https://developer.android.com/reference/android/widget/RemoteViews
- Android Developers, "Expose data to complications":
  https://developer.android.com/training/wearables/tiles/exposing-data-complications
- Android Developers, "Wear Widgets": https://developer.android.com/training/wearables/widgets
- This repository: the files named in §1, `docs/WIDGETS-PLAN.md`, `docs/ISLAND-AND-MENU-BAR-PLAN.md`,
  `docs/WATCH-PLAN.md`.
