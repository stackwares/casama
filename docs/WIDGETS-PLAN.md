# Widgets: the home screen, the Lock Screen and controls on iPhone, Android and the Mac

Status: **approved and built, D-405** (2026-11-18). Oliver asked for all of it and left every
decision to the build; §13's defaults were taken except decision 10 (see §13). Platform rules below were checked on 2026-11-18
against Apple's and Google's own pages and against the SDKs installed on this Mac (Xcode 27.2,
iOS 27.2 SDK, macOS 27.2 SDK); sources are at the end. The decision gets its number when this is
approved.

Mockups: `docs/media/widgets-mockups.html` (iPhone Home Screen, Lock Screen and controls, Android,
Mac).

## 0. Summary

Casama has one widget today. It shows the first bot's name, a status word and today's cost, and it
only knows what the app last told it. This plan replaces it with a set of widgets that each answer
one question a person has when they glance at their phone:

| Widget | The question it answers | Where |
|---|---|---|
| **Needs you** | Is a bot waiting on me? | Home screen, Lock Screen |
| **Bot** | What is this bot doing? | Home screen, Lock Screen |
| **Ask** | Let me ask or talk, now | Home screen, controls |
| **Routines** | What runs next, and can I run it now? | Home screen, Lock Screen, controls |
| **Today** | Everything on one large widget | Home screen |
| **Brief** | What did my bot tell me this morning? | Home screen |
| **Library** | What did my bots make lately? | Home screen |
| **Tasks** | Where does the board stand? | Home screen |
| **Credits** | How much have I used? | Home screen, Lock Screen |

The first four, the Lock Screen set and three controls are the release that matters. Today and
Brief follow. Library, Tasks, Credits and the Mac come last.

Five findings shape the plan:

1. **A widget can't be told anything by our server today.** The app writes four strings while it
   is open; nothing updates them once it closes. The sign-in is kept where a widget can't read it
   and no native code talks to the server (§1).
2. **Apple now lets a server ask a widget to refresh** (iOS 26 and macOS 26), but the push carries
   no content and Firebase can't send it. So a widget has to fetch its own data, with a key of its
   own, and the server has to send that push to Apple directly (§2.1, §8.3).
3. **The Lock Screen is for knowing, not doing.** Apple leaves widget buttons dead on a locked
   phone until the person unlocks it. Lock Screen widgets show state; controls and the unlocked
   Home Screen act (§2.1).
4. **Android can be live where iPhone can't.** A data push already wakes our native code and
   redraws the widget with the app closed (`LiveRun.kt`), and the library for modern widgets
   (Glance 1.2) is already in the build (§2.2).
5. **The Mac has no widget target at all**, its widget plugin doesn't exist, and a Mac widget
   can't act in place the way an iPhone one can. iPhone widgets already show on a Mac for free
   (§2.3). The Mac is worth doing, last, as a view-only set.

It is built in seven phases (§12). Each is usable on its own.

## 1. What exists today

| Already built | Where | State |
|---|---|---|
| iPhone widget **Bot status** | `client/ios/CasamaWidgets/CasamaWidgets.swift` (`BotStatusWidget`) | Small and medium. Re-reads four strings every 15 minutes. One link: quick ask |
| Android widget | `client/android/.../BotStatusWidget.kt`, `res/layout/bot_status_widget.xml` | One 3×2 size. Shows the running bot, its step and **Stop** while a run is followed (D-324) |
| The data both read | `client/lib/core/mobile_extras.dart` (`homeWidgetSyncProvider`), `home_widget` 0.10.0 | `bot_name`, `bot_avatar`, `bot_status`, `bot_cost`, for `bots.first` only |
| A bot's mark drawn natively | `BotArt`/`BotMarkView` (Swift), `BotArt.kt` (Kotlin) | Mascot or initials, matching `bot_avatar.dart`. Reused as is |
| Acting without opening the app | `client/ios/CasamaWidgets/RunActionIntents.swift`, `IslandActivities.swift`; Android `LiveRunActionActivity` | **Stop**, **Allow**, **Deny** from a Live Activity or notification, handed to Dart. Not yet run on a real iPhone (D-324 §19) |
| Siri and Shortcuts | `AskBotIntent`, `RunRoutineIntent` in each `AppDelegate.swift` (D-111); Android `quick_actions` | Both open the app |
| Routes that act on open | `core/router.dart`: `/quick-ask?bot=&text=`, `/bots/:id/call`, `/run-routine/:ref`, `/suggestions/:id/accept`, `/approvals/:id`, `/runs/:id/stop` | Every widget tap already has somewhere to go |
| Briefs, suggestions, approvals in one call | `GET /v1/for-you` (`apps/server/src/api/routes/checkins.ts`) | The nearest thing to a summary. No routines, bots, tasks or credits in it |
| A sender that talks to Apple directly | `ApnsVoipSender` in `packages/agent/src/phone-calls.ts`, `APNS_KEY_P8` and friends in `env.ts` | Built for call rings. Production has no key set |

Gaps found while reading the code:

- **One bot, picked for you.** The widget shows `bots.first`. There is no way to choose.
- **It goes out of date the moment the app closes.** On iPhone the 15-minute refresh re-reads the
  same strings. "Working…" can sit there for hours.
- **Nothing that needs the person reaches it.** No approvals, no suggestions, no routines, no
  brief.
- **No Lock Screen widgets and no controls** on iPhone. Nothing on the Mac.
- **A widget can't sign in.** The session lives in the app's own preferences, or in the keychain
  with no shared group while the app lock is on (`features/app_lock/session_store.dart`). The iOS
  extensions have no keychain group, and there is no HTTP code in any Swift or Kotlin file.
- **The Android widget looks like 2012.** A system dialog frame for a background, stock buttons,
  no dark mode, no preview in the picker, no resizing rules.
- **The app lock doesn't touch it** (D-375). With the lock on, the widget still shows what it has.
- **The guide gives it one sentence** (`docs-site/guide/lock-screen.md`).

## 2. What the platforms allow

### 2.1 iPhone and iPad

- **Sizes.** Small, medium and large on the Home Screen; extra large on iPad; **extra large
  portrait is new in iOS 27** (in the SDK as `systemExtraLargePortrait`, iOS 27.0 and macOS 27.0).
  The Lock Screen has circular, rectangular and inline (the line above the clock).
- **A small widget travels.** The system reuses it in StandBy, in CarPlay (iOS 26) and on a Mac
  desktop, with the background removed in the first two.
- **Looks it must survive.** Full colour, tinted, clear (iOS 26) and the Lock Screen's vibrant
  look. Apple: "Use full-color images judiciously", and for vibrant "use opaque grayscale values".
- **Buttons** (iOS 17) run an App Intent without opening the app, in every Home Screen size and in
  the circular and rectangular Lock Screen sizes. Apple: "On a locked device, buttons and toggles
  are inactive and the system doesn't perform actions unless a person authenticates and unlocks
  their device."
- **Where a button's code runs.** In the widget's own process by default, which has no sign-in.
  It runs inside the app for a few kinds of intent, `LiveActivityIntent` among them. That is how
  **Stop** on our Live Activity reaches Dart today.
- **Refreshing.** A widget the person looks at often gets "from 40 to 70 refreshes" a day, so
  every 15 to 60 minutes. Refreshes are free while the app is in front and after a button press.
- **Refreshing from a server** (iOS 26, macOS 26): the widget registers a push token
  (`WidgetPushHandler`); the server sends `apns-push-type: widgets` to the topic
  `<bundle id>.push-type.widgets` with only `"content-changed": true`. The system then reloads the
  widget's timeline. Apple "budgets WidgetKit push notifications and delivers them
  opportunistically". Firebase has no way to send these, because the token isn't a Firebase token.
- **A widget may use the network** while it builds its timeline, with little time to do it.
- **Time is free.** A timeline can hold entries for known future moments, and timers and relative
  dates tick by themselves. A routine's next run needs no refresh to stay right.
- **Controls** (iOS 18): buttons in Control Center, in the Lock Screen's two corners and on the
  Action button. A control can open the app at a place or run an intent, and can ask for the
  phone to be unlocked first.
- **Choosing what a widget shows**: an `AppIntentConfiguration`, edited where the widget sits.
- **Apple's design rules that matter here:** "Create a layout that provides essential information
  at a glance"; "Replicating an app icon offers little additional value"; "It's more important to
  create one widget in the size that best represents the content than providing the widget in all
  sizes"; text at 11 points or larger; 16-point margins.

### 2.2 Android

- **The timer is slow.** `updatePeriodMillis` "doesn't support values of less than 30 minutes".
- **A push is fast.** A data-only Firebase message wakes a native receiver that can redraw a
  widget with the app closed. `LiveRunReceiver` does exactly that for a running bot today.
- **Glance** is Google's current way to build widgets (stable 1.2.0). `home_widget` 0.10.0 already
  brings `androidx.glance:glance-appwidget:1.2.0` into our build. It gives sizes that adapt,
  scrolling lists, the phone's own colours, and a preview made from the person's real data.
- **Since Android 12:** the phone's theme colours, layouts per size, a widget that can be
  reconfigured or placed without configuring.
- **Adding from inside the app:** `requestPinAppWidget` (Android 8 and later), where the launcher
  supports it.
- **Google's quality bar** for a top-tier widget: resizable, follows the device's colours, light
  and dark, a preview with the person's content, a description, the system's corner radius,
  loading and error states drawn on the widget.
- **Lock screen widgets came back to phones** with Android 16's December 2025 update on Pixels,
  and reach more phones with Android 17. A widget opts in with the `keyguard` category. Google's
  developer pages don't describe the phone behaviour yet, so this needs a look on a device before
  we promise it.
- **Quick Settings tiles** are Android's controls. Google: for things people "access often or need
  fast access to", not for launching an app, and at most two per app.

### 2.3 Mac

- **Sizes:** small to extra large, plus extra large portrait in macOS 27. **No Lock Screen sizes**
  (they are marked unavailable on macOS in the SDK). Widgets sit on the desktop and in
  Notification Center.
- **iPhone widgets already appear on the Mac** (iPhone on iOS 17 or later, same Apple Account,
  nearby or on the same Wi-Fi). So everything in §6 shows up on a Mac with no Mac work.
- **A native Mac widget needs things we don't have:** a widget extension target (the Mac project
  has only `Runner`), an app group (no Mac entitlements file has one), and a sandboxed extension
  inside an app whose direct-download build is not sandboxed. `home_widget` supports iOS and
  Android only.
- **A Mac widget can't run its buttons inside the app.** `LiveActivityIntent` is unavailable on
  macOS. Mac widgets open Casama at the right place instead.
- Server-sent refresh and controls exist on macOS 26 and later.

## 3. Goals and what this is not

Goals:

- A person can tell **whether a bot is waiting on them** without opening Casama, and clear the
  simple cases in one tap.
- **Asking, talking and running a routine are one press away** from the Home Screen, the Lock
  Screen corner and the Action button.
- What a widget shows is **true, or says how old it is**.
- A person's words stay private where a stranger could read them.
- One set of data, one set of words, every platform.

This is not:

- A chat. You can't type in a widget on any of these systems. Ask opens quick ask with the
  keyboard up.
- A live progress view on iPhone. That is the Live Activity (D-324). A widget may lag by minutes.
- A second inbox. It shows the top few things and opens the app for the rest.
- An Apple Watch app. There is no watch target; Live Activities already reach the Watch.

## 4. Principles

1. **One question per widget.** If a widget needs a title to explain itself, it is two widgets.
2. **Never an icon with a border.** Every widget shows something that changes, including Ask
   (§6.1 C).
3. **The bot's own face.** Its mascot or initials, drawn as the app draws them. Never a stand-in.
4. **Two colours mean something, everywhere.** Orange is "needs you". Green is "working". Nothing
   else uses them.
5. **True or dated.** A widget that can't be refreshed drops any claim about now and shows "as of
   9:41".
6. **Private by placement.** On a Lock Screen, counts and general words only. Behind the app
   lock, the same on the Home Screen.
7. **Empty is still useful.** "All clear" plus what comes next beats a blank tile.
8. **Acting goes through the app.** A widget never holds anything that could approve, spend or
   send.
9. **Native and small.** SwiftUI and Glance, fed by data. No WebViews, no Flutter engine inside a
   widget.

## 5. Words

| In the app and docs | Meaning | Not |
|---|---|---|
| **widget** | A tile on the Home Screen, desktop or Lock Screen | complication, app widget |
| **control** | A button in Control Center, a Lock Screen corner or the Action button | toggle, tile |
| **Needs you** | Approvals, takeovers and suggestions waiting on the person | pending, inbox |
| **Up next** | Routines in the order they will run | schedule, queue |
| **Run now** | Start a routine by hand | trigger, execute |
| **All clear** | Nothing needs the person | empty, no items |
| **Show details in widgets** | The switch that lets widgets show a person's words | privacy mode |

In code and in this plan the shared data is called **the glance**.

## 6. The full set

### 6.1 Home screen widgets

Sizes are Apple's (S, M, L, XL). Android uses the matching grid sizes (§6.4).

#### A. Needs you (S, M)

- **Counts** exactly what the Chats tab's **Needs you** row counts, so the two numbers never
  disagree. Its rows are approvals, takeovers and suggestions.
- **Order:** a blocked bot first (approvals, takeovers), newest first; then suggestions, urgent
  first.
- **S:** the number, the first item's bot and one line. One item: a tap opens it. Several: a tap
  opens the Needs you list.
- **M:** two rows, each with the bot, one line and its button: **Allow** and **Deny** on a
  low-risk approval, **Review** on any other approval, **Open** on a takeover, **Do it** on a
  suggestion. Tapping a row opens it.
- **Nothing waiting:** "All clear", the bot's face, and the next thing due ("Brief at 7:00").

#### B. Bot (S, M), with a bot to pick

- **S:** the bot's mark, name and where it stands: **Working** with its step in everyday words,
  **Waiting for you**, **Idle** with when it last replied, or **Turned off**. A tap opens its chat.
- **M:** adds its last message (two lines) and **Ask** and **Talk**.
- **iPhone:** "Working" is shown only while the data is under ten minutes old; after that it says
  when the bot was last busy. **Android:** live, with the timer and **Stop**, as today.
- It takes over from **Bot status** under the same identifier, so widgets people already placed
  become this one. Today's cost moves to Credits.

#### C. Ask (S, M), with a bot to pick

- **S:** the bot's face, **Ask**, and a microphone. A tap opens quick ask with the keyboard up;
  the microphone starts a voice call (`/bots/:id/call`).
- **M:** an ask field (a tap opens quick ask), the microphone, and **two things to try**: the
  person's own starters (D-338), changing through the day. Tapping one opens quick ask with it
  typed in, not sent.
- The starters are what keeps this from being a launcher.

#### D. Routines (S, M), automatic or chosen

- **Automatic** (default): the next runs in time order, across bots. **Chosen:** up to four
  routines the person picks, for the ones they start by hand.
- **S:** the next one: time, name, bot, **Run now**.
- **M:** three rows: time, name, bot and how often, **Run now** on each.
- The list moves on by itself when a run time passes. **Run now** shows "Started", and the run
  then appears as a Live Activity or live notification.
- **None yet:** "No routines yet", opening the bot's routines.

#### E. Today (L; XL on iPad and Mac; XL portrait on iOS 27)

- **L:** the date and a credits ring; **Needs you** (two rows with their buttons); **Up next**
  (two rows); the last thing a bot finished; an ask field.
- **XL:** adds the start of the brief and a strip of recent creations.
- One large widget instead of a large version of each small one.

#### F. Brief (M, L)

- The latest morning brief (D-312) as plain text, with its bot and time. A tap opens the chat at
  the brief.
- Before today's arrives: "Brief at 7:00". A quiet day shows what the bot wrote.

#### G. Library (S, M, L)

- The latest creations by their covers: one, three or six. A tap opens the creation.
- Covers are small pictures the widget fetches with its own key (§8.3), so this needs Phase 3.

#### H. Tasks (M, L)

- The board's counts (To do, In progress, In review, Blocked) and the top rows, **In review**
  first because those wait on a person. A tap opens `/tasks`.

#### I. Credits (S)

- A ring for the share of this period's credits used, what is left, and today's spend. On the
  Free plan, when the daily cap resets. On a self-hosted server with billing off: today's and
  this month's spend.

### 6.2 Lock Screen widgets (iPhone and iPad)

| Shape | Widget | Shows |
|---|---|---|
| Line above the clock | **Casama** | The most important one line: "2 need you", else the next routine or brief time, else "All clear" |
| Circular | **Needs you** | The number; a tick at zero |
| Circular | **Credits** | The ring |
| Circular | **Bot** | The bot's initial in a ring that shows its state. Opens its chat |
| Rectangular | **Needs you** | Who needs what. The request itself is hidden until the phone is unlocked |
| Rectangular | **Up next** | The next routine, its bot, and a countdown |
| Rectangular | **Bot** | Name, state, step in general words |

- One Casama cloud outline is the glyph on all of them; mascots don't survive the Lock Screen's
  single-colour look.
- No buttons here. Apple keeps them dead while locked, and a dead button is worse than none.

### 6.3 Controls (iPhone, iOS 18 and later)

| Control | Does | Locked phone |
|---|---|---|
| **Ask Casama** | Opens quick ask | Opens after unlock |
| **Talk to a bot** (pick the bot) | Starts a voice call with it | Opens after unlock |
| **Run a routine** (pick the routine) | Runs it without opening Casama | Asks to unlock first (decision 6) |

Each can go in Control Center, a Lock Screen corner, or on the Action button.

### 6.4 Android

- **The same nine**, built with Glance: Ask as a **4×1 bar** (resizable from 2×1 to 5×1) and 2×2;
  Needs you 2×2 and 4×2; Bot 2×2 and 4×2; Routines 2×2 and 4×2; Today 4×3 and taller, scrolling;
  Brief 4×2 and 4×3; Library, Tasks and Credits later.
- **Colours** follow the phone (Material You), light and dark. A bot's own colours stay its own.
- **The picker shows the person's own bot** in each preview (Android 15 and later).
- **Add from the app:** Settings → Widgets has **Add to Home screen** on each.
- **Choosing** a bot or routines: a small native picker when the widget is placed, and again from
  a long press.
- **Live:** Bot and Today show the running bot, its step and **Stop**, from the pushes D-324
  already sends.
- **Later, after a look on a device:** Needs you, Routines and Bot on the lock screen; one Quick
  Settings tile (**Ask Casama**); a bot pinned to the home screen as its own icon.

### 6.5 Mac

- **Until the native ones exist:** the iPhone widgets, on the desktop, through the person's
  iPhone.
- **Native** (Phase 5): Needs you, Bot, Routines (S, M), Today (L, XL), Brief (M, L), drawn by the
  same SwiftUI views as the iPhone's.
- **View only.** A click opens Casama where the thing is. Allow, Deny, Stop and asking in place
  stay with the notch and the menu bar panel (D-324), which already do them better.

### 6.6 States every widget has

| State | What it shows |
|---|---|
| Signed out | The Casama mascot and "Open Casama to sign in" |
| No bots yet | "Meet your first bot", opening the app |
| Private (§10) | Numbers, bot names and general words. No requests, messages, routine names or brief text |
| Out of date | Nothing claimed about now, and "as of 9:41" |
| Server too old | The Bot widget works as today; the others say "Update your Casama server to use this widget" |
| First load | The layout with greyed placeholders, never a spinner |

### 6.7 The look

- **Background:** white, or the app's dark grey (the Plain theme, D-380). No tint. The system's
  own material in tinted and clear Home Screens and in StandBy.
- **Type:** the system's font, rounded on Apple devices as the Live Activity already is. Nothing
  under 11 points. Numbers keep a fixed width so they don't jump.
- **Colour:** the bot's colours on its own mark; orange for needs you; green for working; the
  brand purple on the one main button. Everything else is text grey.
- **Buttons:** capsules, one main button per row at most, and never more than two rows of them.
- **Tinted and clear:** numbers and buttons take the person's tint; mascots lose their colour
  rather than fight it.
- **Motion:** numbers roll when they change. Nothing else moves.
- **Accessibility:** every state has a spoken label that says the whole thing ("Needs you, 2.
  Milo wants to search flight prices"). Large text drops a row instead of shrinking.
- **Words:** the app's own, from `app_en.arb`, so "Needs you", "Allow" and "Do it" read the same
  everywhere.

### 6.8 Settings, discovery and docs

- **Settings → Widgets** (new): each widget with a picture and how to add it; on Android the
  **Add to Home screen** buttons; the **Show details in widgets** switch.
- **One quiet nudge:** after a person's first approval or first routine, a line in the app that
  the matching widget exists. Shown once.
- **Gallery text:** each widget's description starts with a verb, as Apple asks ("See which bots
  are waiting on you").
- **Docs:** a new `docs-site/guide/widgets.md`; lines in `lock-screen.md`, `privacy.md` and
  `routines.md`.

## 7. What we're not shipping, and why

| Not shipping | Why |
|---|---|
| A text field in a widget | No system allows one. Ask opens quick ask |
| Live steps on an iPhone widget | Budgeted refreshes lag. The Live Activity is the live surface (D-324) |
| Allow from a Lock Screen widget | Apple disables it while locked; the Live Activity already offers it behind Face ID |
| Allow for medium or high risk in a Home Screen widget | A stray thumb on the Home Screen shouldn't send an email (decision 5) |
| Apple Watch complications | Needs a watch app. Live Activities already reach the Watch |
| Mac widgets that act in place | The Mac can't run a widget's button inside the app; the notch does this job |
| Windows and Linux widgets | No shared model; the tray carries the feed (D-324) |
| A widget per computer, per project, per chat app | Small audiences. Revisit when asked |
| Custom fonts and themes in widgets | Widgets sit among system UI and must follow its text size and tint |
| A second way to sign in for widgets | The widget key reads one summary and nothing else (§8.3) |

## 8. How it works

### 8.1 The glance

One small document, the same on every platform, under about 6 KB:

| Part | Holds | At most |
|---|---|---|
| `needs` | The count; for each top item: kind, bot, one line, risk, ids, link | 4 |
| `bots` | Id, name, mark, status, step in general words, last message and when, link | 8 |
| `next` | Routine id, name, bot, next run time, how often, link | 6 |
| `brief` | Bot, plain text, time, link; or when the next one is due | 1 |
| `lately` | What bots last finished: bot, title, time, link | 3 |
| `recent` | Creations: id, kind, title, whether it has a cover, link | 6 |
| `tasks` | A count per status and the top rows | 3 |
| `credits` | Share used, left, today's spend, when it resets, or that billing is off | |
| `starters` | Emoji and text, for the default bot | 4 |
| `flags` | Private, hide reply text | |

It also carries when it was made. It never carries tool arguments, approval details beyond the
one-line summary, full messages, or anything a secret could be in.

### 8.2 The server builds it

- `GET /v1/glance?org_id=` returns the glance for the signed-in person, built in
  `packages/agent/src/glance.ts` from the queries behind `/v1/for-you`, the inbox badge, routines,
  creations, tasks and billing. Sealed text is opened in code, as `/v1/for-you` does.
- It answers "not changed" to a caller that already has the current one, so a refresh that finds
  nothing new costs one cheap request.
- **Why the server and not the app:** in Phase 3 the widgets fetch it themselves, so it has to
  exist on the server. Building it there from the start means one builder and one set of tests,
  and the app never has a second opinion about what a widget shows.

### 8.3 How it reaches a widget

1. **The app carries it** (Phase 0). While Casama is open it fetches the glance on start, on
   coming back to front, and when bots, the inbox, approvals or routines change (at most once in
   15 seconds), and writes it where widgets read: the App Group on iPhone, `home_widget`'s store
   on Android, the Mac's app group. It writes the words (from `app_en.arb`) beside it, so native
   code holds no text, as the island does. Then it asks the widgets to redraw.
2. **Time does the rest for free.** Each widget's timeline holds an entry for every known moment
   ahead: each routine's run time, the brief's hour, the point where the data counts as old.
3. **The widget fetches it itself** (Phase 3). The app asks the server for a **widget key** and
   stores it where only the app and its widgets can read. The key can read the glance and creation
   covers. It can do nothing else. Each widget refresh then fetches the glance, with or without
   the app.
4. **The server says when** (Phase 3). When something a widget shows changes, the server sends a
   refresh request with no content in it: to Apple for iPhones and Macs on version 26 or later,
   and a normal-priority data message for Android. Needs-you changes go at once; everything else
   is gathered into at most one every five minutes per person.

An iPhone still on iOS 18 gets steps 1 to 3: right whenever the app is used, and within the hour
otherwise.

### 8.4 Acting goes through the app

| Action | iPhone | Android | Mac |
|---|---|---|---|
| Ask, Talk, open anything | A link | A link | A link |
| **Run now** | An intent that runs inside the app, as Stop does today, and hands to Dart. Falls back to opening `/run-routine/…` | The action activity D-324 built: silent if the app is alive, else opens the same link | Opens the link |
| **Do it** | Same, falling back to `/suggestions/:id/accept` | Same | Opens the link |
| **Allow**, **Deny** (low risk only) | `AnswerRequestIntent`, as built. Dart still refuses a request that isn't waiting or isn't low risk here | The action activity | Opens the approval |
| **Stop** | `StopRunIntent`, as built | As built | The notch |

Dart acts as the signed-in person, with every check the app already makes. With the app lock on,
every acting button opens the app instead, and the lock screen asks first.

### 8.5 Pieces

| Piece | Where | Size |
|---|---|---|
| Glance contract, builder, routes | `packages/contracts/src/glance.ts`, `packages/agent/src/glance.ts`, `apps/server/src/api/routes/glance.ts` | TypeScript, about 500 lines |
| The app's carrier | `client/lib/features/widgets/glance_sync.dart` (replaces `homeWidgetSyncProvider`) | Dart, about 250 lines |
| iPhone widgets, Lock Screen, controls | `client/ios/CasamaWidgets/` split into `Glance.swift`, `BotMark.swift`, `Widgets/*.swift`, `Controls.swift`, `LiveActivities.swift` | SwiftUI, about 1,400 lines |
| iPhone intents and pickers | `RunActionIntents.swift` (two new intents), `GlanceEntities.swift` | Swift, about 200 lines |
| Android widgets | `client/android/.../widgets/*.kt` (Glance), `GlanceStore.kt`, a picker activity, `res/xml` | Kotlin, about 1,300 lines |
| Widget key and self-refresh | A `widget_keys` table; a fetcher in Swift and in Kotlin (`WorkManager`) | SQL, Swift and Kotlin, about 450 lines |
| Refresh pushes | `packages/agent/src/glance-push.ts`; `ApnsVoipSender` generalised; the relay's `widget` body | TypeScript, about 350 lines |
| Mac widgets | A `CasamaWidgetsMac` target sharing the SwiftUI files; `MacBridge` writes the glance; the two packaging scripts sign the extension | Swift and shell, about 300 lines of our own |
| Settings → Widgets | `client/lib/features/widgets/widgets_screen.dart` | Dart, about 250 lines |

### 8.6 iPhone notes

- **Raise the widget extension from iOS 17 to iOS 18** (decision 9). Controls then need no second
  code path, and the Live Activity can finally opt into the Apple Watch and CarPlay size D-324
  left open. Every iPhone that runs iOS 17 runs iOS 18; a few 2017 and 2018 iPads don't.
- The server-refresh handler is compiled in for iOS 26 and later only.
- The bot and routine pickers read the glance in the App Group. Today's Shortcuts list sits in the
  app's own preferences, which the extension can't read.
- The widget key goes in a keychain group shared by the app and the extension, readable after the
  first unlock so a refresh works on a locked phone. Both targets gain the entitlement; the
  extension gains push.

### 8.7 Android notes

- Glance needs the Compose compiler turned on in `app/build.gradle.kts`. The library is already
  there. This is the first Compose code in the Android project, so it gets one early build
  (Phase 2 starts by asking for it).
- `BotStatusWidget` keeps its class name, so placed widgets carry over.
- A `glance` data message wakes a receiver that queues a fetch; a 30-minute periodic job covers a
  server that can't push. Both stop when the last widget is removed.
- The lock screen category is added only after it has been seen working on a Pixel.

### 8.8 Mac notes

- The extension is sandboxed and shares data through a Team-ID-named app group, which works for
  the direct download and the App Store build alike.
- `package-macos.sh` and `package-macos-appstore.sh` sign the extension, with its own
  entitlements, before the app. The App Store build needs a provisioning profile for it.
- A Sparkle update replaces the app under a running widget; whether the old widget process
  refreshes by itself is checked in the phase.

### 8.9 Server notes

- `widget_keys` (user, workspace, platform, key hash, push token, label, last used): row-level
  security lets a person see and delete only their own; the worker gets `public.allow_worker`. A
  key is shown once, stored hashed, limited to 120 requests an hour, deleted at sign-out.
- The glance routes take the session or `Authorization: Widget <key>`, as
  `/v1/local-computer/connect` takes `Device <token>`. Because the key isn't a Supabase token, the
  routes go on the contracts list of routes that work signed out.
- `GlancePusher` watches the same event bus as `LiveRunPusher`, plus inbox rows, approval
  decisions, suggestion answers and routine changes.
- Apple pushes need `APNS_KEY_P8`, `APNS_KEY_ID` and `APNS_TEAM_ID` in production (decision 4).
  The same key makes iPhone call rings work (D-135).
- Self-hosted servers send through Casama Cloud's relay (`/link/v1/push`, a new `widget` body
  with tokens and nothing else). The widget fetches from the person's own server.

## 9. Changes by area

| Area | Change |
|---|---|
| `packages/contracts`, `packages/agent`, `apps/server` | The glance contract, builder and routes; widget keys; `GlancePusher`; the Apple sender; the relay body |
| `supabase/migrations`, `supabase/tests` | `widget_keys`, its policies and pgTAP tests |
| `dart/casama_api` | Regenerated client |
| `client/lib/core/mobile_extras.dart`, `backend.dart`, `supabase_backend.dart`, `test/fake_backend.dart` | `homeWidgetSyncProvider` gives way to the carrier; `glance`, `createWidgetKey`, `deleteWidgetKey` |
| `client/lib/features/widgets/` (new) | The carrier and Settings → Widgets |
| `client/lib/features/island/island_bridge.dart` | Handles `run_routine` and `accept` beside `stop`, `allow`, `deny` |
| `client/lib/features/app_lock/` | **Show details in widgets**; the private flag |
| `client/lib/l10n/app_en.arb` | The widgets' words and spoken labels |
| `client/ios` | §8.6: files, targets' entitlements, the extension's deployment target |
| `client/android` | §8.7: Glance widgets, provider XML, manifest receivers, the Compose compiler |
| `client/macos`, `scripts/package-macos*.sh` | §8.8 |
| `packages/contracts/analytics/catalog.json`, `client/lib/core/analytics.dart` | §15 |
| `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/COSTS.md`, `docs-site/` | The decision, the file map, a zero-cost line, the guide page |

## 10. Security and privacy

- **The widget key reads; it never acts.** It opens the glance and creation covers. It can't
  approve, run, send, read a chat or mint another key. Stolen, it leaks a summary until the person
  signs out.
- **Refresh pushes are empty.** No name, no step, no count leaves the server in them, so Apple,
  Google and the Cloud relay learn only that something changed. Private notifications need no
  special case.
- **Lock Screen:** numbers and general words show. Anything written by or about the person (a
  request, a routine's name, a brief) is marked private, which iOS hides until the phone is
  unlocked. Android's lock screen versions leave those lines out.
- **App lock on (D-375):** widgets are private everywhere and acting buttons open the app, until
  the person turns on **Show details in widgets**. A workspace that requires the app lock keeps it
  off.
- **Hide reply text** (D-325) also hides a bot's last message in the Bot widget.
- **Allow in a widget:** low risk only, and Dart re-checks that the request is still waiting.
- **Run a routine from a locked phone:** asks to unlock first.
- **CarPlay:** Brief and Tasks ask not to be shown there.
- **Sign-out** deletes the key on the server, wipes the stored glance and redraws every widget
  signed out.

## 11. Cost

Apple's push service and Firebase are free at any volume. The server adds one small indexed read
per refresh, answered "not changed" most of the time: at most about 70 a day for each widget a
person looks at, plus one per change. The Library widget adds a small picture per new creation.
`docs/COSTS.md` gets a line saying so.

## 12. Phases

Every phase ends with its tests green (`flutter analyze`, `flutter test`, and for server work
`pnpm test` plus pgTAP, through `scripts/heavy.sh`), a decision entry, docs, and a commit. Builds
and deploys are asked for one at a time, as `AGENTS.md` requires.

| Phase | What | Done when | Needs from Oliver |
|---|---|---|---|
| **0. The glance** | Contract, builder, `GET /v1/glance`, the app's carrier, an older server's fallback | Tests cover every part, the private flag, the limits, and a server without the route. The existing widget still works | A production deploy |
| **1. iPhone** | Needs you, Bot, Ask, Routines; the Lock Screen set; the three controls; pickers; **Run now**, **Do it**, **Allow**, **Deny** in place; every look | Simulator pictures of every widget in every size, light, dark, tinted, clear and on the Lock Screen. On an iPhone: add each one, press each button, lock the phone | An iOS build; a real iPhone |
| **2. Android** | The same four in Glance, the Ask bar, previews, **Add to Home screen**, pickers, in-place actions, the live overlay | Emulator on Android 17 and on Android 11 (the last without the phone's colours): every size, light and dark. A real phone with the app swiped away | An Android build; a real phone |
| **3. Fresh while closed** | Widget keys, self-refresh on both, `GlancePusher`, the Apple sender, the relay | With Casama closed: an approval raised elsewhere shows on a locked iPhone's widget and on Android within a minute; answering it on the Mac clears both | The Apple push key in production; a deploy; both phones |
| **4. Today and Brief** | Today (L, XL, XL portrait), Brief, on iPhone and Android | Same checks as Phases 1 and 2 | Builds |
| **5. Mac** | The extension target, the shared views, the app group, both packaging scripts | Widgets on this MacBook's desktop from a signed direct-download build and from an App Store build; a Sparkle update leaves them working | A macOS build of each kind; an App Store profile for the extension |
| **6. More** | Library, Tasks, Credits; Android lock screen, Quick Settings tile, pinned bots | Each gets its own short plan | Decision 16 |

Phase 1 and Phase 2 don't depend on each other. Phase 3 needs both. Settings → Widgets lands with
whichever of 1 and 2 comes first.

## 13. Decisions for Oliver

Each has a default this plan assumes. Say "defaults" to take them all.

| # | Decision | Default |
|---|---|---|
| 1 | The line-up and its order: Needs you, Bot, Ask, Routines first; Today and Brief next; Library, Tasks, Credits last | Yes |
| 2 | The server builds the glance; the app and the widgets only read it | Yes. The other choice is building it in Dart, and again on the server in Phase 3 |
| 3 | Widgets refresh themselves with a read-only widget key | Yes. Without it they are only as fresh as the last time the app was open |
| 4 | The server sends refresh pushes straight to Apple, which needs the Apple push key (`.p8`) in production | Yes. Firebase can't send them. The same key turns on iPhone call rings |
| 5 | In a Home Screen widget, **Allow** and **Deny** work in place for low-risk requests only; medium and high show **Review** | Yes. The other choice is low and medium, as the Live Activity does behind Face ID |
| 6 | **Run a routine** from a locked phone asks to unlock first | Yes |
| 7 | With the app lock on, widgets show numbers and general words only, until **Show details in widgets** is turned on | Yes |
| 8 | On the Lock Screen, a person's own words stay hidden until unlock | Yes |
| 9 | Raise the iPhone widget extension to iOS 18 | Yes. People still on iOS 17 lose widgets and Live Activities until they update |
| 10 | Android widgets are built with Glance and follow the phone's colours | **RemoteViews with the phone's colours** (changed in the build): Glance needs the Compose compiler in a Flutter Gradle build that couldn't be built here, and RemoteViews is what `LiveRun.kt` and the existing widget already use. Android 12+ sizes and dynamic colours work the same |
| 11 | Widgets use the system's fonts, not Google Sans | Yes |
| 12 | **Bot status** becomes **Bot** in place; today's cost moves to Credits | Yes |
| 13 | Mac widgets are view only and come in Phase 5 | Yes |
| 14 | One Casama outline for every Lock Screen widget; no single-colour mascots yet | Yes |
| 15 | The widget names in §0 | Yes |
| 16 | Android's lock screen, the Quick Settings tile and pinned bots wait for a look on a device | Yes |

## 14. Risks

| Risk | What we do |
|---|---|
| The in-place buttons rest on a pattern no real iPhone has run yet (D-324 §19) | Phase 1's first device check is **Stop** on the existing Live Activity. Every button has a link to fall back to |
| Apple throttles or drops refresh pushes | They are a hint, never the only path: the widget also fetches on its own schedule, and the data carries its age |
| A widget shows a count that is no longer true | Answering anywhere sends a refresh at once; old data loses its claim about now (§6.6) |
| Glance brings Compose into a Flutter app's Gradle build | One early build before any widget is written. RemoteViews remains the fallback (decision 10) |
| Android skins draw widgets differently | The system's corner radius and colours, Glance's own size handling, checks on a Pixel and a Samsung |
| Two targets and two builds on the Mac have to agree on signing and an app group | Phase 5 starts with an empty widget shipped through both scripts before any view is ported |
| Lock Screen privacy depends on iOS hiding marked text | Checked on a locked iPhone in Phase 1; if it doesn't hold, those lines are left out as on Android |
| Nine widgets is a lot to keep right | Four ship first. Each later one must earn its place in §15's numbers |
| App Review reads Ask as a launcher | It shows the person's own starters, which change; the controls are the plain launchers, where Apple expects them |
| Self-hosted servers behind a home network can't be reached by the widget | The widget keeps the app-carried data and shows its age |

## 15. How we'll know it worked

Added to the analytics catalog. No names, titles or text, as the catalog requires.

- `widgets_placed`, once a day per device: how many, and whether any is on the Lock Screen.
- `feature_used` gains `widget_opened` (Casama opened from a widget) and `widget_action`.
- `widget_action` on its own event with `action`: `run`, `do_it`, `allow`, `deny`, `stop`, `ask`,
  `talk`.

What we watch after release: the share of active people with a widget placed; the share of
approvals answered from a widget or control; the time from an approval being asked to being
answered; routine runs started from a widget; and whether people with a widget placed come back on
more days than people without.

## 16. Left for Oliver

Filled in as each phase lands. Known now:

- **The Apple push key** (`.p8`), its key id and the team id, for production (Phase 3). If the one
  uploaded to Firebase is still at hand, it can serve both.
- **Real devices:** an iPhone on iOS 26 or later, an Android phone, and for the lock screen work a
  Pixel.
- **Builds and deploys**, asked for one at a time.
- **The App Store listing:** a widgets screenshot is worth a slot (`docs/STORE-SCREENSHOTS-PLAN.md`).

## 17. The store layout (what the app writes, what widgets read)

| Key | Holds |
|---|---|
| `glance` | The glance as JSON (`packages/contracts/src/glance.ts`), already made private by whoever wrote it when `flags.private` is set |
| `glance_words` | A JSON map of the widgets' words from `app_en.arb` (`widgetNeedsYou` → `needs_you`, …). Placeholders are `{bot}`, `{time}`, `{n}`, `{amount}`, `{title}`. Native code keeps an English copy for when it's missing |
| `glance_server` | The API base URL the widget fetches from in Phase 3 |
| `glance_signed_in` | `"1"` or absent |

Where: iPhone, the App Group `group.ai.casama.app` (`UserDefaults(suiteName:)`); Android,
`home_widget`'s `HomeWidgetPreferences`; Mac, the app group `V8V5US964Z.ai.casama.app` (written by
`MacBridge` over `casama/mac` → `glance`). The widget key is never in these: iPhone and Mac keep it
in the keychain group `$(AppIdentifierPrefix)ai.casama.app.widgets` (service `ai.casama.widgets`,
account `key`), Android in the app-private preferences file `casama_widget_key`.

Words (`glance_words` keys): `needs_you`, `all_clear`, `allow`, `deny`, `review`, `open`, `do_it`,
`run_now`, `started`, `stop`, `ask`, `ask_bot`, `talk`, `try`, `up_next`, `no_routines`, `working`,
`waiting`, `idle`, `off`, `replied_at`, `brief`, `brief_at`, `no_brief`, `today`, `credits`,
`credits_left`, `spent_today`, `used_pct`, `resets_at`, `finished`, `library`, `no_creations`,
`tasks`, `todo`, `in_progress`, `in_review`, `blocked`, `sign_in`, `no_bots`, `as_of`,
`update_server`, `needs_ok_from`, `suggests`, `take_over`, `next_brief`, `nothing_next`.

Actions native code hands to Dart over `casama/island` → `action`, beside `stop`, `allow`, `deny`:
`run_routine` (`routine_id`, `bot_id`) and `accept` (`suggestion_id`, `bot_id`). Each has a link to
fall back to: `/run-routine/<routine>:<bot>` and `/suggestions/<id>/accept?bot=<bot>`. Taps that
only open go to `casama://app<link>`; Ask opens `/quick-ask?bot=<id>`, Talk `/bots/<id>/call`, a
starter `/quick-ask?bot=<id>&text=<text>`.

## Sources

- Apple, "Keeping a widget up to date":
  https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- Apple, "Updating widgets with WidgetKit push notifications":
  https://developer.apple.com/documentation/widgetkit/updating-widgets-with-widgetkit-push-notifications
- Apple, "Adding interactivity to widgets and Live Activities":
  https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
- Apple, "Creating accessory widgets and watch complications":
  https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications
- Apple, "Making network requests in a widget extension":
  https://developer.apple.com/documentation/widgetkit/making-network-requests-in-a-widget-extension
- Apple, "Preparing widgets for additional contexts and appearances":
  https://developer.apple.com/documentation/widgetkit/preparing-widgets-for-additional-contexts-and-appearances
- Apple, "Making a configurable widget":
  https://developer.apple.com/documentation/widgetkit/making-a-configurable-widget
- Apple, "Creating controls to perform actions across the system":
  https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system
- Apple, "Configuring app groups":
  https://developer.apple.com/documentation/xcode/configuring-app-groups
- Apple, Human Interface Guidelines, "Widgets" and "Controls":
  https://developer.apple.com/design/human-interface-guidelines/widgets,
  https://developer.apple.com/design/human-interface-guidelines/controls
- Apple, WWDC26 "WidgetKit foundations": https://developer.apple.com/videos/play/wwdc2026/277/
- Apple, Mac User Guide, "Add and customize widgets":
  https://support.apple.com/guide/mac-help/add-and-customize-widgets-mchl52be5da5/mac
- Apple Developer Forums, widgets missing when the extension isn't sandboxed:
  https://developer.apple.com/forums/thread/685166, https://developer.apple.com/forums/thread/751422
- Android Developers, "App widgets overview" and "Create an advanced widget":
  https://developer.android.com/develop/ui/views/appwidgets/overview,
  https://developer.android.com/develop/ui/views/appwidgets/advanced
- Android Developers, "Widget discoverability":
  https://developer.android.com/develop/ui/views/appwidgets/discoverability
- Android Developers, "Jetpack Glance" and its release notes:
  https://developer.android.com/develop/ui/compose/glance,
  https://developer.android.com/jetpack/androidx/releases/glance
- Android Developers, "Widget quality":
  https://developer.android.com/docs/quality-guidelines/widget-quality
- Android Developers, "Create custom Quick Settings tiles":
  https://developer.android.com/develop/ui/views/quicksettings-tiles
- Android Developers, `AppWidgetProviderInfo` (the `keyguard` category):
  https://developer.android.com/reference/android/appwidget/AppWidgetProviderInfo
- 9to5Google, lock screen widgets on phones in Android 16 QPR2:
  https://9to5google.com/2025/08/20/android-qpr2-lock-screen-widgets/
- Home Assistant, sending widget pushes to Apple directly because Firebase can't:
  https://github.com/home-assistant/mobile-apps-fcm-push/pull/337
- The installed SDKs: `WidgetKit.framework` and `AppIntents.framework` in the iOS 27.2 and macOS
  27.2 SDKs (Xcode 27.2), read for which sizes, push handlers, controls and intents exist where.
- This repository: `home_widget` 0.10.0's `android/build.gradle` (Glance 1.2.0), and the files
  named in §1.
