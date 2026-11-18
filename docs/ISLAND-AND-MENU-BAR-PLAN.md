# The island and the menu bar app: the Mac notch, the iPhone Dynamic Island and Live Activities, and Android

Status: **approved, D-324** (2026-11-16). Oliver took every §13 default except decision 8 (pushes go
through Firebase) and decision 10 (only while the notch is on); see §13. Platform rules below were checked on 2026-11-16 against Apple's
and Google's own pages and against the SDKs installed on this Mac (Xcode 27.2, macOS 27.2 SDK,
iOS 27.2 SDK); sources are at the end.

## 0. Summary

Today a person only knows what a bot is doing while Casama's window is in front of them. This plan
puts that knowledge where they already look:

| Where | What it becomes |
|---|---|
| **Mac notch** | A Dynamic Island for the Mac: a running bot sits in the notch, opens on hover, and takes **Stop**, **Allow** and **Deny** without switching windows |
| **Mac menu bar** | Casama keeps running when its window closes. The icon opens a panel with the same list, plus quick ask |
| **iPhone** | A real Live Activity: Lock Screen, Dynamic Island, StandBy, Apple Watch, CarPlay, and the Mac's menu bar through the person's iPhone |
| **Android** | A live notification: a status bar chip and lock screen card on Android 16 and later, a custom RemoteViews layout before that, and a live home-screen widget |

All four read **one feed** built once in Dart: what runs, what needs the person, what just
finished. The server pushes that feed to phones while the app is closed.

Three findings shape the plan:

1. **macOS has no notch API.** ActivityKit ships in the macOS 27.2 SDK, but it is marked
   unavailable on macOS and code that uses it doesn't compile. The notch is drawn by us: a
   borderless panel above the menu bar, placed with public screen geometry. No private API and no
   new entitlement.
2. **The iPhone Live Activity we ship today stops being true about 30 seconds after the app
   leaves the screen.** It is only updated from Dart, and iOS suspends the app. The island is
   visible exactly when the app is not, so without pushes from the server it shows "Thinking…"
   until the person comes back. Pushes are the core of the iPhone work, not an extra.
3. **On Android the two things asked for exclude each other.** Android 16's Live Updates (the
   status bar chip, the nearest thing to a Dynamic Island) refuse any notification with a custom
   RemoteViews layout. The plan uses each where it works (§6 E, decision 7).

It is built in six phases (§12). Phase 1 (the Mac) and Phases 3 and 4 (iPhone with pushes) are
the two that matter most. Each phase is usable on its own.

## 1. What exists today

| Already built | Where | State |
|---|---|---|
| iOS Live Activity and Dynamic Island | D-067: `client/ios/CasamaWidgets/CasamaWidgets.swift`, `client/lib/core/mobile_extras.dart` (`LiveRunActivities`), the `live_activities` plugin | Works only while the app is open. See the gaps below |
| Run events for an open chat | `client/lib/features/chat/chat_controller.dart` (`started`, `step`, `ended` calls into `runActivitiesProvider`) | The only thing that feeds the Live Activity |
| Tray icon, status line, **Open Casama**, **Quick ask…** | `client/lib/features/companion/desktop_shell.dart` (`tray_manager`) | A plain menu. Shows only a bot using this computer |
| Global shortcut Cmd/Ctrl+Shift+K | Same file (`hotkey_manager`), D-152 | Opens the window at Quick ask with context chips |
| "A bot is using this computer" bar with **Stop** | D-066: `client/lib/features/companion/companion_overlay.dart` | Inside the window, and it forces the window to stay on top |
| Native Mac bridges, Open at Login, dock badge | `client/macos/Runner/MainFlutterWindow.swift` (`MacBridge`), `client/lib/core/mac_bridge.dart` | The pattern the notch bridge follows |
| Approvals, takeovers, inbox count | `approvalsProvider`, `takeoversProvider`, `inboxBadgeProvider` in `client/lib/core/providers.dart`; `/approvals/:id` screen | Everything the island needs to ask for an OK |
| Everyday words for a tool ("Searching the web") | `client/lib/ui/tool_words.dart`, `toolDoing` in `app_en.arb` | Reused for every step line |
| Pushes: FCM, Apple call pushes with a `.p8` key, the Cloud relay | `packages/agent/src/notifications.ts`, `phone-calls.ts` (`ApnsVoipSender`), `apps/server/src/link/push-relay.ts` | Live Activity updates use the FCM path (decision 8); call pushes keep their own, still unset, APNs key |
| Android pushes drawn natively from data messages | D-247: `client/android/.../SuggestionPush.kt` | The pattern for Android live updates when the app is dead |
| Android home-screen widget | `client/android/.../BotStatusWidget.kt`, `res/layout/bot_status_widget.xml` | Static: a name, a status word, today's cost |

Gaps found while reading the code:

- **The Live Activity freezes in the background** (finding 2 above), and it is never marked stale,
  so a run that ended while the phone was locked can sit on the Lock Screen for up to 8 hours.
- **Only runs started from an open chat on that device show at all.** A routine, a run started on
  another device, or a chat that was closed mid-run never appears.
- **Steps show raw tool names** (`shell.exec`), not the words the chat uses.
- **Approvals never reach it.** A run waiting for an OK still says it is working.
- **The Dynamic Island layout is a placeholder:** a sparkle icon, the first 12 characters of the
  step, no timer, no state, no actions, nothing for Apple Watch or CarPlay.
- **Closing the Mac window quits the app** (`applicationShouldTerminateAfterLastWindowClosed`
  returns true in `AppDelegate.swift`). So the menu bar icon, the shortcut and "Use this computer
  for bots" all die with the window.
- **Android has nothing.** `LiveRunActivities` returns early unless the platform is iOS.

## 2. What the platforms allow

### 2.1 Mac

- **No system island.** ActivityKit is in the macOS 27.2 SDK only as a stub: all 73 macOS
  availability marks in its interface read `@available(macOS, unavailable)`, and a test file using
  it fails to compile with "unavailable in macOS". A Mac app cannot start a Live Activity.
- **The notch is measurable with public API.** `NSScreen.safeAreaInsets.top` is above zero on a
  notched display, and `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` give the menu bar on each
  side of it. Measured on this MacBook Pro: screen 1728 × 1117 pt, notch 185 × 32 pt.
- **Drawing over it is ordinary AppKit:** a borderless, non-activating `NSPanel` above the menu
  bar's window level, on every Space and over full-screen apps. It works sandboxed and unsandboxed,
  so both the Developer ID build and the Mac App Store build can carry it.
- **iPhone Live Activities already reach the Mac.** From macOS 26, Live Activities from a person's
  iPhone appear in the Mac's menu bar once iPhone Mirroring has been set up; the iPhone must be on
  but need not be nearby. So the iPhone work in this plan shows up on the Mac for free, and a
  person with both may see one run twice (§14).

### 2.2 iPhone

- **Where a Live Activity appears:** Lock Screen (iPhone and iPad), Dynamic Island, StandBy,
  a paired Apple Watch's Smart Stack and CarPlay (both by opting in with
  `.supplementalActivityFamilies([.small])`), and the Mac's menu bar. iOS 27 also shows the Dynamic
  Island in landscape, and `isDynamicIslandLimitedInWidth` tells the compact view when it has less
  room.
- **Limits:** active for up to 8 hours, then up to 4 more on the Lock Screen. Static plus dynamic
  data at most 4 KB. The Lock Screen view is cut off above 160 pt. The widget extension has no
  network access, so a bot's photo can't be fetched there.
- **Starting:** the app must be in the foreground, or a push must start it (push-to-start, iOS
  17.2 and later, which must carry an alert). A started-by-push activity gets its own update token
  with `input-push-token` on iOS 18 and later.
- **Updating from a server:** an APNs request with `apns-push-type: liveactivity`, topic
  `<bundle id>.push-type.liveactivity`, a token (`.p8`) connection, and an `aps` body with
  `timestamp`, `event` (`update` or `end`), `content-state`, and optionally `stale-date`,
  `dismissal-date`, `relevance-score` and `alert`.
- **Budget:** priority 10 pushes count against an hourly budget and are throttled past it; priority
  5 pushes don't count. `NSSupportsLiveActivitiesFrequentUpdates` raises the budget, and a person
  can turn that off in Settings.
- **Buttons:** `Button(intent:)` with a `LiveActivityIntent` runs in the app's process without
  opening it. Buttons do nothing in CarPlay.
- **Also available, not needed here:** broadcast channels (one push to many phones, iOS 18),
  scheduled start, and the transient style that ends when the phone locks.
- **Firebase can carry these pushes** (`apns.live_activity_token` in the HTTP v1 API). We don't
  use it: production already sends through Firebase, which holds the Apple key, and the server has
  no APNs key of its own (decision 8).

### 2.3 Android

- **Live Updates (Android 16, API 36):** a promoted ongoing notification shown at the top of the
  shade, on the lock screen, and as a chip in the status bar. To qualify, a notification must use
  the standard style, `BigTextStyle`, `CallStyle`, `ProgressStyle` or `MetricStyle`; be ongoing;
  have a title; request promotion; and the app must declare `POST_PROMOTED_NOTIFICATIONS`. It must
  **not** set a custom content view ("no RemoteViews"), be a group summary, or be colorized.
  The chip shows an icon and, when it fits in 96 dp, a short text (`setShortCriticalText`; under
  7 characters always fits) or a timer. Whether a phone allows it is read at run time
  (`canPostPromotedNotifications`).
- **Google's guidance on use:** for ongoing, time-sensitive activities a person started, with a
  clear start and end. Not for chat messages, alerts, promotions or ambient information.
- **Custom layouts:** an app targeting Android 12 or later can't make a fully custom notification.
  It gets the system's frame with its own RemoteViews inside (`DecoratedCustomViewStyle`).
  Collapsed layouts may get as little as 48 dp of height and expanded ones 252 dp, and text must
  use the notification text styles so it stays readable on every skin.
- **Background updates:** a high-priority data-only FCM message wakes a receiver that redraws the
  notification, exactly as suggestion pushes do today. No foreground service is needed, since the
  phone isn't doing the work.

## 3. Goals and what this is not

Goals:

- A person can tell, without opening Casama, **which bot is working, on what, and for how long**.
- When a bot needs an OK, the request reaches them where they are, and on the Mac they can answer
  it in place.
- **Stop is always one step away**, most of all when a bot is using this very computer (D-066).
- What is shown is **true**: it updates while the app is closed and says so when it can't.
- One feed, one set of words, four surfaces. No surface has its own idea of what a run is doing.

This is not:

- A second chat. Replies are read in the app; the island says a reply is ready and opens it.
- A notification replacement. Pushes keep alerting; the island shows state and never makes a sound.
- A media, calendar or battery widget for the notch. It shows Casama's bots and nothing else.
- A tray rewrite for Windows and Linux. They keep today's tray (§7).

## 4. Principles

1. **One feed.** Every surface renders the same list from `client/lib/features/island/`. Native
   code draws; it never decides what a run is doing.
2. **True or marked stale.** Every update carries a stale date. A surface that can't be updated
   says "Open Casama for the latest" instead of showing an old step.
3. **Quiet.** No sounds, no bouncing. The notch opens by itself only when something needs the
   person and Casama isn't the app in front.
4. **Safe by default.** Nothing risky is approved by hover, by accident, or from a locked phone.
5. **Native, small, no WebViews.** SwiftUI on Apple platforms, RemoteViews on Android, fed by data.
6. **Costs nothing when idle.** No polling, no timers and no pushes unless a bot is working.
7. **Words from one place.** Steps use the chat's own tool words. The server keeps a short English
   list for pushes and the app overwrites it with the full words whenever it is open.

## 5. Words

| In the app and docs | Meaning | Not |
|---|---|---|
| **the notch** | The Mac surface, also on a display without one | island, pill |
| **menu bar panel** | What the Mac menu bar icon opens | popover, tray |
| **Live Activity** | The iPhone surface, Apple's own name | widget |
| **live notification** | The Android surface | Live Update, RemoteViews |
| **Needs your OK** | A run waiting for an approval | pending, awaiting approval |
| **Finished** / **Stopped with a problem** | How a run ended | completed, failed |

In code and in this plan the shared model is called **the island feed**.

## 6. The full feature set

### A. The feed (shared)

| Item | Shown as | Actions |
|---|---|---|
| A run that is working | Bot, step in everyday words, what it's about (a site, a file), time running, cost | Open, Stop |
| A run that needs an OK | Bot, the approval's summary, its risk | Allow, Deny (Mac); Review (phones) |
| A run asking the person to take over a screen | Bot and its reason | Open |
| A bot using this computer | Marked as "on this Mac", always listed first among working runs | Stop |
| A run that just ended | **Finished** or **Stopped with a problem**, for a short while | Open |

- **Order:** needs an OK, take over, working, ended. Within a group: this computer first, then newest.
- **Whose runs:** runs the person started, from any device. The Mac also shows runs nobody started
  by hand (a routine, a webhook), since it sits open all day. Phones don't (decision 6).
- **Sub-runs** (a helper a bot asked) are folded into their parent.
- **Stopped by the person:** leaves at once, with no "Finished" line.

### B. The Mac notch

1. **Resting.** Nothing is visible; the panel sits behind the notch.
2. **Working.** The notch widens. Left: the bot's mark and a slow pulse. Right: the step if it
   fits, else the running time. Several runs show a count.
3. **Open.** On hover or click it grows into a list, one row per item, with the row's actions.
   It closes when the pointer leaves, on Esc, or on a click elsewhere.
4. **Needs your OK.** The notch opens by itself with the request and **Allow** / **Deny**, but only
   when Casama isn't the app in front (the chat already shows the card when it is). Buttons act on
   click only. High-risk requests add **Open** to read the full details first.
5. **Peek.** A two-second look, then back to compact: a run finished, a run stopped with a
   problem, a bot started using this computer.
6. **Ask from the notch.** Hovering the resting notch opens a small home: a text field, the bot it
   goes to (the one talked to last, changeable), and the Needs you count. Enter starts a new chat
   and the run appears in the notch at once. Cmd+Shift+K keeps opening full Quick ask with its
   context chips (decision 12).
7. **Drop a file on the notch.** It opens as a drop target and hands the files to Quick ask, the
   same path Android's share uses.
8. **No notch** (an external display, a Mac mini, a closed lid): the same shape hangs from the top
   centre, and only while there is something to show.
9. **Which display:** the built-in one when it has a notch, otherwise the main display. It moves
   when displays change.
10. **Full screen and Spaces:** present on every Space and over full-screen apps.
11. **Bots' screenshots:** the panel is left out of screenshots a bot takes of this Mac.
12. **Accessibility:** every state has VoiceOver labels, Reduce Motion swaps the spring for a
    fade, and the open list is keyboard reachable.
13. **A live voice call** in the notch (level meter, mute, end) comes in Phase 6. *Built (§16.3).*

### C. The Mac menu bar

- **Casama keeps running when its window closes**, as Mac apps do. Cmd+Q quits. Clicking the Dock
  icon, the menu bar icon or the notch brings the window back.
- **A native menu bar item** replaces `tray_manager`'s on macOS: the icon, with a dot when
  something needs the person. Its width never changes, so it isn't pushed behind the notch.
- **The panel** shows the same list as the open notch, the ask field, and **Open Casama**,
  **Settings…** and **Quit Casama**.
- **Open at Login** starts in the menu bar without showing the window.
- **Hide the Dock icon** (menu bar only) is left as a later switch (§7).

### D. iPhone: Live Activities

One Live Activity per followed run, with a typed state instead of loose strings.

| Presentation | Content |
|---|---|
| **Dynamic Island, compact** | Leading: the bot's mark. Trailing: a state glyph and the running time, or a short glyph when width is limited (iOS 27) |
| **Dynamic Island, minimal** | The state glyph in a ring: working, needs you, done |
| **Dynamic Island, expanded** | Bot and running time on top, the step and what it's about in the middle, **Stop** and **Open** (or **Review**) at the bottom |
| **Lock Screen and banner** | Bot, step, detail, running time, steps so far; a highlighted **Needs your OK** variant; a **Finished** variant. Under 160 pt |
| **StandBy** | The Lock Screen view with larger type and an edge-to-edge tint |
| **Apple Watch and CarPlay** | The small family: bot, state, running time. No buttons in CarPlay |
| **Mac menu bar** | Comes free from the compact and Lock Screen views (macOS 26 and later) |

- **Timers tick by themselves** (`Text(timerInterval:)`), so the running time never needs a push.
- **Taps:** the activity opens the run's chat. **Review** opens the approval. **Stop** opens the
  app and stops the run. All three are deep links in the first release; acting without opening the
  app comes later (decision 5). *Built in Phase 6 (§16.1): Stop, Allow and Deny act in place.*
- **Starts** when the person starts a run on the phone, and for any run of theirs that is still
  going when they open the app.
- **Updates** come from the app while it is open and from the server otherwise (§6 F).
- **Ends** with the **Finished** state, which stays on the Lock Screen for 15 minutes (decision 9),
  or at once when the person stopped it.
- **Goes stale** two minutes after its last update: it dims and says "Open Casama for the latest".
- **Long runs:** iOS ends an activity after 8 hours. A run still going is shown again the next
  time the app opens.
- **The bot's mark** is its initial on its colour. A photo is saved into the App Group when the
  run starts from the app, since the widget can't download one.
- **Push-to-start** (showing a run on the phone that the phone never saw start) is Phase 6
  (decision 11). *Built in Phase 6 (§16.2).*

### E. Android: the live notification

One ongoing notification per followed run, on a silent **Bots at work** channel.

| Android | What the person sees |
|---|---|
| **16 and later**, promotion allowed, a run the person started | A **Live Update**: status bar chip ("Working", "Needs you", or the running time), a card on the lock screen and at the top of the shade. Standard style, as the platform requires |
| **8 to 15**, or promotion off, or a run nobody started by hand | A **custom RemoteViews** notification inside the system frame: collapsed (mark, bot, step, timer in 48 dp) and expanded (detail, steps so far) |

- **Buttons:** **Stop**, **Review** (when it needs an OK) and **Open**, as deep links like the
  suggestion buttons.
- **Lock screen:** the public version says only that a bot is working; the step shows once
  unlocked.
- **Ends** as **Finished**, tappable, and clears itself after 15 minutes.
- **Updates** come from the app while it lives, and from data-only FCM messages drawn by a native
  receiver when it doesn't.
- **The home-screen widget goes live:** the same RemoteViews show the running bot, its step and
  **Stop** while something runs, and today's status and cost otherwise.
- **No foreground service** and no new runtime permission beyond notifications.

### F. Updates from the server

- A device that follows a run registers a **live token** for it: the Live Activity's own push
  token on iPhone, the phone's push token on Android.
- The server watches that run's events and sends at most one **step** update every 5 seconds per
  run (Apple priority 5, which is free of the budget), and sends **needs your OK**, **back to
  work** and **ended** at once (priority 10).
- Every update carries the full state, a timestamp and a stale date, so a late or lost push never
  leaves a wrong picture.
- The Live Activity push never alerts. The approval's ordinary notification still does, so the
  phone buzzes once, not twice.
- **Self-hosted servers** linked to Casama Cloud send through the relay, as pushes and call rings
  do. With **private notifications** on, the relay gets the state ("working", "needs you") and no
  words.
- A server with no way to push leaves the app-driven behaviour, and the stale date keeps it honest.

### G. Settings and docs

- **Mac, Settings → App:** **Show bots in the notch** (on) and **Open the notch on hover** (on),
  next to **Open at Login**.
- **iPhone and Android:** the system's own switches (Live Activities; the **Bots at work**
  channel). Notifications settings gets one row that explains them and opens the right system page.
- **Docs:** a guide page per surface in `docs-site/guide/`, the companion page's "tray or menu bar
  icon" line, and the self-hosting page on what needs Casama Cloud's relay.

## 7. What we're not shipping, and why

| Not shipping | Why |
|---|---|
| Windows and Linux equivalents | No notch and no shared model for one. Their tray stays; a floating pill can follow once the Mac one has proved itself |
| A separate Swift helper app for the menu bar | It would need its own sign-in, its own live connection and its own updates, and "Use this computer for bots" lives in the main app anyway |
| A second Flutter engine inside the notch | Memory and shaped-window trouble for a very small view |
| Approving from a locked phone | A risky action shouldn't be approvable by whoever picks up the phone |
| Broadcast channels | Runs are personal; there is no audience to broadcast to |
| A Live Activity for every routine run on phones | Noise. Phones follow what their owner started (decision 6) |
| Hiding the Dock icon | A switch for later; closing the window already gets most of the way |
| A live iOS home-screen widget | iOS widgets refresh on a budgeted timeline, so it would lag. The Live Activity is the live surface |
| Reply text on the Lock Screen | Replies can be private. "Finished" opens the chat |

## 8. How it works

### 8.1 Pieces

| Piece | Where | Size |
|---|---|---|
| Island feed and run tracker | `client/lib/features/island/island_feed.dart` (new) | Dart, about 450 lines |
| Bridge: sends the feed to native, takes actions back | `client/lib/features/island/island_bridge.dart` (new), channel `casama/island` | Dart, about 250 lines |
| Mac notch, menu bar item and panel | `client/macos/Runner/Island.swift` (new, added to the Runner target) | SwiftUI and AppKit, about 700 lines |
| iPhone bridge to ActivityKit | `client/ios/Runner/AppDelegate.swift` | Swift, about 200 lines |
| Live Activity views and shared attributes | `client/ios/CasamaWidgets/`, one file shared with Runner | SwiftUI, about 400 lines |
| Android live notification, receiver and widget | `client/android/.../LiveRun.kt` (new), layouts, manifest | Kotlin, about 450 lines |
| Live tokens and the pusher | `supabase/migrations/`, `packages/agent/src/live-updates.ts` (new) | SQL and TypeScript, about 400 lines |

### 8.2 The run tracker

- An open chat keeps reporting its run's steps, as it does today.
- For every other run, the tracker **asks** rather than listens: while any bot's status is working
  or waiting, one small query every 3 seconds lists the workspace's unfinished top-level runs
  (`runs`, under row-level security). A run that has moved on gets its last 40 events read for the
  newest step.
- It asks because a second listener on a run's live topic (`run:<id>`) would knock the chat's own
  listener off that topic.
- When no bot is working the timer stops. Bot status already arrives live, and that restarts it.
- A run the server no longer lists has ended: one read of its status says finished, failed or
  stopped.

### 8.3 The channel

One method channel, `casama/island`, on macOS, iOS and Android.

- **Dart → native, `state`:** the items (id, phase, bot, step, detail, run id, approval id, risk,
  started at, cost, on this computer, link), the Mac's switches, the inbox count, the bots quick
  ask can go to, and the button labels (from `app_en.arb`, so native code holds no text).
- **Native → Dart, `action`:** open a link, stop a run, allow or deny an approval, ask (bot and
  text), drop (file paths), show the window.
- **Native → Dart, `token`:** a Live Activity's push token, which Dart registers for its run.

### 8.4 Mac

- `IslandPanel` is a borderless, non-activating `NSPanel` one level above the menu bar, joined to
  all Spaces and marked as a full-screen auxiliary. It becomes key only while the ask field is in
  use, so opening it never takes focus from the app in front.
- Its frame always matches the visible shape (compact, open, or the notch itself when resting), so
  nothing outside the shape swallows clicks meant for the menu bar.
- SwiftUI draws the shape in black so it merges with the notch, and animates between sizes with
  one spring.
- The menu bar item is an `NSStatusItem` with an `NSPopover` holding the same SwiftUI list.
- `MainFlutterWindow` hides instead of closing, so the Flutter engine, the live connection and the
  companion keep running. The Dock icon and both surfaces bring it back.
- `desktop_shell.dart` stops creating the tray on macOS and keeps the shortcut.

### 8.5 iPhone

- `live_activities` is replaced by a small bridge of our own (decision 1). The plugin keeps its
  data in the App Group, which a push can't write to; a push can only replace the content state.
- `RunActivityAttributes` (shared by the app and the widget extension) holds what never changes:
  run id, bot id, bot name, colour, started at. Its content state holds the rest: phase, step,
  detail, steps so far, approval id, risk, updated at. Times are plain seconds, since pushes are
  decoded with default JSON rules.
- The bridge starts, updates and ends activities from the feed, sets a stale date on every update,
  and forwards each activity's push token to Dart.
- Info.plist gains `NSSupportsLiveActivitiesFrequentUpdates`. The widget opts into the small family
  for Apple Watch and CarPlay.
- The router gains `/runs/:id/stop`, which stops the run and lands on its chat, like
  `/suggestions/:id/accept` does for suggestions.

### 8.6 Android

- `LiveRun.kt` builds the notification from the same state map, choosing the Live Update or the
  RemoteViews form (§6 E), and updates the home-screen widget.
- `LiveRunReceiver` listens for FCM data messages of kind `live`, as `SuggestionPushReceiver`
  does for suggestions, and redraws from the message alone when the app isn't running.
- The manifest gains `POST_PROMOTED_NOTIFICATIONS` and the receiver.

### 8.7 Server

- `run_live_tokens` (run, user, platform, token): row-level security lets a person write tokens
  only for themselves and only for runs they can see; the worker gets access with
  `public.allow_worker`. The app writes it directly, as it does `voip_tokens`, so no route and no
  contract change.
- `EventBus` gains observers. `LiveRunPusher` observes run events in both the API and the worker,
  looks up a run's tokens (cached briefly), throttles steps, and sends.
- iPhone: Live Activity updates go through the existing FCM sender with `apns.live_activity_token`
  and the `liveactivity` push type (decision 8). No APNs key on the server.
- Android: the existing data-only FCM path.
- The Cloud relay (`/link/v1/push`) accepts a `live` body for iPhones.
- Tokens are deleted when their run ends, when Apple or Firebase reports them gone, and by a
  sweep in the worker once they are 12 hours old.

## 9. Changes by area

| Area | Change |
|---|---|
| `client/lib/core/backend.dart`, `supabase_backend.dart`, `test/fake_backend.dart` | `activeRuns`, `runEventsAfter`, `registerLiveToken` |
| `client/lib/features/chat/chat_controller.dart` | Reports to the run tracker (bot id, tool arguments) instead of `runActivitiesProvider` |
| `client/lib/core/mobile_extras.dart` | `LiveRunActivities` removed; the home widget reads the feed |
| `client/lib/app.dart`, `core/router.dart`, `settings_screen.dart`, `l10n/app_en.arb` | Keeps the bridge alive; `/runs/:id/stop`; two Mac switches; the labels |
| `client/pubspec.yaml`, `THIRD_PARTY_NOTICES.md` | `live_activities` removed |
| `client/macos`, `client/ios`, `client/android` | §8.4 to §8.6 |
| `supabase/migrations`, `supabase/tests` | `run_live_tokens`, its policies and pgTAP tests |
| `packages/agent`, `apps/server` | Observers on `EventBus`, `LiveRunPusher`, the sender, the relay's `live` body, upkeep |
| `packages/contracts/analytics/catalog.json` | The features in §15 |
| `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/COSTS.md`, `docs-site/` | The decision, the file map, a zero-cost line, the guide pages |

## 10. Security and privacy

- **Approvals.** On the Mac, **Allow** needs a deliberate click on an unlocked computer, the same
  trust as the in-app banner. On phones the first release opens the app, behind the phone's lock.
- **Stop is never gated.** Stopping a bot is always safe, so it is the one action offered
  everywhere.
- **What leaves the server in a push:** the bot's name, a step in general words ("Searching the
  web"), a phase and times. Never tool arguments, file names, sites, message text or approval
  details. With private notifications on, not even the step.
- **The Lock Screen** shows the same general words. Android's public version shows only that a bot
  is working.
- **Tokens** are per run, written under row-level security, and useless once the run ends.
- **The notch panel** can't be made to act by another app: it accepts clicks only, takes no
  commands from outside, and its actions go through the signed-in app.
- **No new permissions on the Mac.** No accessibility, no screen recording, no input monitoring.
- **Bots' screenshots** leave the panel out, so a bot never reads its own approval prompt off the
  screen.

## 11. Cost

Apple's push service and Firebase messaging are free at any volume. The server adds one token
lookup per interesting run event (cached) and at most one small push every 5 seconds per followed
run. The Mac adds one small query every 3 seconds, only while a bot is working. `docs/COSTS.md`
gets a line saying so.

## 12. Phases

Every phase ends with its tests green (`flutter analyze`, `flutter test`, and for server work
`pnpm test` plus pgTAP), a decision entry, docs, and a commit. Builds and deploys are asked for one
at a time, as `AGENTS.md` requires.

| Phase | What | Done when | Needs from Oliver |
|---|---|---|---|
| **0. The feed** | Tracker, feed, bridge, backend queries, chat controller hook | Unit tests cover order, whose runs, ending, and stopping when idle. Nothing visible changes | Nothing |
| **1. Mac** | Stay alive, menu bar item and panel, the notch with working, open, needs your OK, peek, Stop | On this MacBook: start a run, switch apps, watch it in the notch, stop it, approve one, close the window and reopen it | A macOS build |
| **2. Mac extras** | Ask from the notch, file drop, no-notch shape, switches, left out of screenshots, accessibility | Same checks on an external display, with VoiceOver, and with Reduce Motion | A macOS build |
| **3. iPhone** | Our own bridge, typed state, every presentation, deep-link actions, stale handling, small family | In the simulator and on an iPhone with a Dynamic Island: every state in every presentation | An iOS build; a look on a real iPhone |
| **4. Server pushes** | Tokens, pusher, Apple sender, relay, FCM data path | A locked iPhone follows a run to **Finished**, through an approval, with the app closed | A production deploy; the Apple push key set on the server if call rings haven't needed it yet |
| **5. Android** | Live notification in both forms, receiver, live widget | Android 16: chip and lock screen card. Android 13: RemoteViews. Both update with the app swiped away | An Android build; a device or emulator on each version |
| **6. Later** | Acting without opening the app, push-to-start, a voice call in the notch, Windows and Linux | Each gets its own short plan | Decisions 5 and 11 |

Phases 1 and 3 don't depend on each other. Phase 4 needs 3. Phase 5 needs 4.

## 13. Decisions for Oliver

Each has a default this plan assumes. Say "defaults" to take them all.

| # | Decision | Default |
|---|---|---|
| 1 | Replace the `live_activities` plugin with our own small bridge | Yes. Pushes need a typed state the plugin can't give |
| 2 | Closing the Mac window keeps Casama running; Cmd+Q quits | Yes |
| 3 | A native menu bar item and panel replace the tray menu on macOS | Yes |
| 4 | The resting notch opens on hover (after a short pause) | Yes, with a switch to make it click only |
| 5 | Approvals: **Allow** and **Deny** in place on the Mac; **Review** opens the app on phones | Yes. In-place on phones comes later, behind Face ID |
| 6 | Whose runs: the Mac shows yours plus routines; phones show only yours | Yes |
| 7 | Android 16 and later use the Live Update chip with the standard layout; RemoteViews everywhere else | Yes. The other choice is RemoteViews everywhere and no chip |
| 8 | Live Activity pushes go through Firebase (`apns.live_activity_token` in the HTTP v1 API), not straight to Apple | **Firebase** (Oliver, 2026-11-16). Production has no `APNS_*` key; Firebase holds the Apple key. Phase 4 first checks it is a `.p8` auth key |
| 9 | **Finished** stays 8 seconds in the notch and 15 minutes on a phone's lock screen | Yes |
| 10 | With the notch on, the window no longer forces itself on top while a bot uses this Mac (D-066) | Yes, **only while Show bots in the notch is on** and the notch is on screen; otherwise D-066's on-top window stays |
| 11 | Push-to-start, so a run started on the Mac appears on the phone unasked | Not in the first release |
| 12 | Cmd+Shift+K keeps opening full Quick ask, not the notch's field | Yes |
| 13 | The setting's name: **Show bots in the notch** | Yes |

## 14. Risks

| Risk | What we do |
|---|---|
| The notch panel fights the menu bar or steals focus | A non-activating panel whose frame is only ever the visible shape; checked in Phase 1 on a real notch |
| Menu bar items get hidden behind a wider notch | The notch only widens while something runs, and our own menu bar item never changes width |
| One run shows twice on a Mac (our notch and the iPhone's mirrored activity) | Accepted. A person can turn off iPhone Live Activities on the Mac in System Settings; the docs say how |
| Another notch app is running | **Show bots in the notch** turns ours off; the menu bar panel has everything |
| Apple throttles pushes | Steps go at the free priority, at most one per 5 seconds; only state changes use the budget |
| A push is lost | Every push is the whole state with a stale date; the next one, or the stale state, corrects it |
| Android skins treat custom layouts differently | The decorated style, system text styles, a 48 dp collapsed layout, checks on two versions |
| Google or Apple reject the use | Only runs a person started are promoted on Android; both surfaces show progress of a task, never promotion |
| Hiding the window instead of closing it breaks a plugin that expects a close | `window_manager` already shows and hides this window; checked in Phase 1 |
| None of this can be proved without real devices | Each phase names its on-device check, and nothing is called done on a build alone |

## 15. How we'll know it worked

Added to the analytics catalog as features, counted once per person per day as today:

- `notch_opened`, `notch_action` (stop, allow, deny, ask), `menu_bar_panel`
- `live_activity_started` (iPhone), `live_notification_started` (Android)

What we watch after release: the share of approvals answered from the notch, the time from an
approval being asked to being answered on the Mac, and how many Live Activities end as stale
(that number should be near zero once Phase 4 is live).

## 16. Phase 6 plans

Phase 6 was four separate pieces, each planned briefly here before it was built.

### 16.1 Acting without opening the app (decision 5)

- **What:** Stop, Allow and Deny work from the Lock Screen and the notification shade without
  bringing Casama forward. Review stays a deep link.
- **iPhone:** two App Intents (`client/ios/CasamaWidgets/RunActionIntents.swift`, built into the
  app and the widget): `StopRunIntent` (`.alwaysAllowed`: Stop is never gated, §10) and
  `AnswerRequestIntent` (`.requiresAuthentication`: Face ID or the passcode first). As
  `LiveActivityIntent`s they run in the app's process, starting it in the background if need be;
  the app hands them to Dart over `casama/island` (`action`, with `unlocked: true` for answers).
  Dart gets 10 seconds to come up; if it can't act, the intent asks iOS to bring the app forward
  and the fallback link opens there.
- **Android:** the buttons open a translucent `LiveRunActionActivity` in its own task. Being an
  activity, Android asks to unlock first (Allow and Deny also set `setAuthenticationRequired`). If
  the app's engine is alive it hands the action to Dart and closes, so the app never shows;
  otherwise, or if Dart says no, it opens the deep link as before. Android shows three buttons at
  most, so a request answered here has Allow, Deny and Review, and the notification itself opens
  the chat.
- **Dart:** a phone answers only when native code says the phone was unlocked for it, only a
  request the feed shows as waiting, and **never a high-risk one** (those show Review alone, so the
  person reads the details first). A state without a risk (from an older server) shows Review alone
  too.

### 16.2 Push-to-start (decision 11)

- **What:** a run the person starts on another device (the Mac, the web app, another phone) shows
  on their phones a few seconds later, unasked. Settings → App → **Bots you start elsewhere**
  (phones, on by default) turns it off per phone.
- **Tokens:** `live_start_tokens` (user, platform, token, an iPhone's Firebase token) under
  row-level security. An iPhone registers ActivityKit's `pushToStartTokenUpdates` token (iOS 17.2+);
  an Android phone registers its Firebase token. A shared phone follows whoever signed in on it
  last: turning the setting off keeps the row with `enabled = false` (still the newest for that
  token) rather than deleting it, and signing out deletes it.
- **Server:** `LiveRunPusher` waits 6 seconds after a person's run starts (so the phone that started
  it has its own activity), then sends an `event: start` to every start token of that person whose
  phone doesn't already follow the run. iPhones get the APNs start payload (`attributes-type`,
  `attributes` with the labels, a silent `alert`); Android gets the usual data message, and its
  token is added to the run's live tokens so updates and the end follow. An iPhone watches
  `activityUpdates` for the activity the server started and registers its update token, and ends a
  duplicate if the app and the server both started one.

### 16.3 A voice call in the notch (§6 B 13)

- **What:** while a voice call runs on the Mac, the notch shows it like a run, first in the list:
  the bot's mark, a level meter, the call's length, and on hover **Mute** / **Unmute** and
  **Hang up**. Clicking the row brings the call window back.
- **How:** since D-327 a call belongs to `ActiveCall` (`active_call.dart`), not its screen, so
  `followActiveCall` (`island_call.dart`) reports the live call to `islandCallProvider` with
  controls that use the call's own `CallController`; the bridge sends `call` in the state (macOS
  only) and the level ten times a second as its own `level` message, only when it moved, so only
  the meter redraws. Mute and Hang up are the controller's, so the transcript is saved the same
  way; clicking the row sends `call_open`, which opens the call screen through
  `ActiveCall.act(open)`. On the Mac the notch and its panel replace D-327's tray call items; on
  Windows and Linux the tray menu shows the call above the feed.

### 16.4 Windows and Linux

- No notch: the tray menu carries the feed (`island_tray.dart`), with Stop, Allow, Deny and Open,
  and the tray's tooltip and title say what matters most. Built first in this phase.

## 19. Left for Oliver

What was built without a person at the screen, and what only a person can check or decide.
Filled in as each phase lands.

### Phase 1 (Mac)

Checked on this MacBook (M-series, notch 220 × 38 pt) by `client/integration_test/island_flow_test.dart`:
the menu bar item appears, a run shows in the notch and stays there with another app in front, the
panel sits above the menu bar on every Space and in full screen and never becomes key, App Nap is
held off while a bot works, hover opens and closes the list, Stop reaches the server and a stopped
run leaves at once, a request that needs an OK opens the notch by itself and sets the menu bar dot,
Allow reaches the server, Finished peeks then leaves, the menu bar panel opens and closes (twice),
closing the window keeps the app running and the Dock icon brings it back. What it draws was checked
from images rendered by the app itself.

Not checked, because a test can't move the real pointer or take a screenshot here:

- A real hover over the notch and real clicks on its buttons (the test calls the same handlers).
- How the notch looks on the real screen around the camera housing, and the menu bar icon and dot.
- Cmd+Q quitting (a test can't quit its own app).
- Mission Control, a full-screen app, and a second display (Phase 2 also covers external displays).

### Phase 2 (Mac extras)

Checked on this MacBook by the same integration test: the notch rests behind the camera housing and
is left out of screen captures (`sharingType` none), hover opens it, the ask field is read by
VoiceOver as "Ask a bot…" and typing asks for the keyboard, a question sent from the notch reaches
the bot (the message is in the database), its run shows in the notch and the window stays closed,
hover off means click to open, the notch switch hides and brings back the notch, the no-notch pill
is 156 × 24 pt and leaves the screen at rest, dropped files open Quick ask, and Open at Login is
detected.

Left for a person:

- An **external display** and a Mac without a notch: how the pill looks and where it sits.
- **VoiceOver** itself reading the rows and buttons, and **Reduce Motion** on (the test reads the
  accessibility tree; it can't listen).
- **Real keyboard focus**: a background app can't take key focus without a real click, so the test
  checks the panel asks for it; typing into the field after a real click, and focus going back to
  the app that had it, need a person.
- The bot picker's look beside the field, and dragging a real file from Finder.

### Phase 3 (iPhone)

Checked in the iPhone 18 Pro Simulator (iOS 27.2) by `client/integration_test/island_ios_test.dart`:
a run the person started gets an activity with its step and a two-minute stale date, turns into
Needs your OK with Review, ends as Finished and stays, and Stop (the deep link) stops the run and
ends its activity at once. Screenshots showed the compact and expanded Dynamic Island and the Lock
Screen (in Notification Center) for Needs your OK and Finished. iOS asked "Allow Live Activities
from Casama?" on the Lock Screen the first time.

Left for a person:

- **A real iPhone with a Dynamic Island**: every state in every presentation, StandBy, and the
  minimal presentation next to another app's activity.
- **The small family** (Apple Watch, CarPlay) isn't built: it needs the widget extension's target
  raised to iOS 18 (`supplementalActivityFamilies`). Decide whether to raise it.
- An iOS build (`flutter build ipa`), and a look at the Lock Screen when locked for real (the
  Simulator can't be locked from the device tools).

### Phase 4 (server pushes)

Built and tested locally only: the migration (applied by hand to the local database, safe to run
twice), pgTAP for its policies, the pusher with a recording sender, and the relay's `live` body. In
the Simulator, an activity's push token reached `run_live_tokens` (the integration test with
`ISLAND_PUSH_WAIT`), and the real pusher made the APNs payload Firebase would pass to Apple
(`packages/agent/scripts/live-push-local.ts`). The Simulator won't apply it: pushed with the
`.push-type.liveactivity` topic it answers "Bad address", and with the topic in the payload it
treats it as an ordinary notification with nothing to show. So a push changing an activity has only
been checked as far as the payload. The same run showed the stale date at work: with no update for
two minutes, the activity turned stale.

Left for Oliver:

- **Production deploy** (`scripts/deploy-prod.sh`): the migration and the worker's pusher.
- **Firebase holds Apple's `.p8` auth key** (Project settings → Cloud Messaging → Apple app
  configuration). Live Activity pushes need a token-based key; a certificate won't do.
- **The first real push**: Firebase's `apns.live_activity_token` request is built from Firebase's
  documentation and hasn't met the real service yet. Watch the worker's "live push" warnings on the
  first run followed from a phone.
- **A locked iPhone with the app closed** following a run to Finished through an approval (the
  phase's "done when"). On a development build, `ISLAND_PUSH_WAIT` in the iPhone integration test
  holds an activity open for this and checks it shows what the server pushed.
- Self-hosted: a linked server's live pushes through Casama Cloud need Casama Cloud deployed first.

### Phase 5 (Android)

Checked on the Pixel 10 Pro XL emulator (Android 17, Google Play image) by
`client/integration_test/island_android_test.dart`: a run the person started gets a notification
that Android promotes to a Live Update (status bar chip with the running time, then **Needs you**),
with Stop and Open, then Review and Open; Finished stops being ongoing with a 15-minute timeout;
Stop (the deep link) stops the run and the notification leaves at once; the RemoteViews form (forced
in a debug build, as on older Android or with Live Updates off); a server state drawn by the native
side, an older one ignored, and a stopped run's end removing it; the widget's data follows the run.
With `--dart-define-from-file=config/firebase.json` and `ISLAND_PUSH_WAIT`, the phone's Firebase
token reached `run_live_tokens`, and three real pushes sent through Firebase from this Mac
(`packages/agent/scripts/live-push-local.ts` with `LIVE_SEND=1`, the local service account) were
drawn by `LiveRunReceiver` while Casama was in the background; the last step, which arrived after
Needs your OK, was ignored as older. Screenshots showed the card at the top of the shade and both
chips.

Left for Oliver:

- **An Android build** and a look on a real phone, **with the app swiped away** (the test runner
  keeps the app alive, then uninstalls it, so a push waking a dead process wasn't watched; the
  receiver is the same one Firebase wakes for suggestion pushes).
- **Android 13 to 15 on a real device or emulator**: only Android 17 was run here; the RemoteViews
  form was checked by forcing it, not on an older system.
- **The lock screen itself** with a PIN set (the emulator has none): the public version should say
  only "A bot is working".
- **The home-screen widget's look** while a bot runs (its data was checked, not its pixels), and the
  Samsung skin (One UI draws Live Updates as its Now Bar).
- Production: Phase 4's deploy carries Android too; no new key is needed.

### Phase 6 (later pieces)

Built and checked here:

- **Windows and Linux:** the tray menu's rows and buttons come from the feed (unit tests on the
  entries, the tooltip and the title). Not run on a Windows or Linux machine.
- **The voice call in the notch:** `client/integration_test/island_flow_test.dart` puts a call in
  the real notch on this MacBook: compact with the level meter moving, the call row on hover,
  Mute from the notch (the row turns to Unmute with a slashed microphone), Hang up, and the notch
  back at rest. Screenshots looked right. The call screen's side (reporting the call, Mute and
  Hang up through its own handlers, the transcript saved) is a widget test with a fake call.
- **Acting without opening, Android:** the emulator test presses the notification's real **Stop**
  and **Deny** buttons (their PendingIntents, as a tap sends them): both reached the server while
  the app stayed where it was; a medium-risk request shows Allow, Deny and Review, with Allow and
  Deny asking to unlock; a high-risk one shows Review alone.
- **Acting without opening, iPhone:** the intents build into the app and the widget; Dart's side
  (unlocked only, never high risk) is unit tested.
- **Push-to-start:** the server's part runs against the local database (who gets a start, the
  phone that already follows it left out, a shared phone, the Android token joining the run, the
  APNs start payload); the app's part (registering, the switch, an iPhone's token from native code)
  is unit tested; the iOS code builds.

Left for Oliver:

- **A real iPhone (iOS 17.2 or later) with an app build**: push-to-start (start a chat on the Mac,
  watch the Lock Screen a few seconds later), its updates and end, and no second activity on the
  phone that started a run. The Simulator delivers no Live Activity pushes.
- **On the iPhone's Lock Screen:** Stop without unlocking; Allow and Deny asking for Face ID, then
  answering without opening Casama; a high-risk request showing only Review; and, with Casama swiped
  away, that a button still works (iOS starts the app in the background) or opens it.
- **On a real Android phone, locked:** Stop, Allow and Deny ask to unlock, then act without
  showing the app; with the app swiped away they open it instead. Push-to-start on Android: start a
  chat elsewhere and watch the notification appear.
- **The call in the notch during a real call** (the test used a stand-in for the call): the meter
  following real speech, and Mute/Hang up matching the call screen.
- **Windows and Linux:** a look at the tray menu on each (only the entries were tested).
- **Production:** a server deploy carries push-to-start (the `live_start_tokens` migration and the
  pusher); no new key is needed beyond Phase 4's.

## Sources

- Apple, "Displaying live data with Live Activities":
  https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- Apple, "Starting and updating Live Activities with ActivityKit push notifications":
  https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications
- Apple, WWDC26 "Live Activities essentials": https://developer.apple.com/videos/play/wwdc2026/223/
- Apple Support, "Manage iPhone notifications and Live Activities on Mac":
  https://support.apple.com/en-us/120684
- Android Developers, "Create live update notifications":
  https://developer.android.com/develop/ui/views/notifications/live-update
- Android Developers, "Create a custom notification layout":
  https://developer.android.com/develop/ui/views/notifications/custom-notification
- Android Developers, "Progress-centric notifications":
  https://developer.android.com/about/versions/16/features/progress-centric-notifications
- Firebase, "Get started with Live Activity":
  https://firebase.google.com/docs/cloud-messaging/customize-messages/live-activity
- The installed SDKs: `ActivityKit.framework` in the macOS 27.2 and iOS 27.2 SDKs (Xcode 27.2), and
  `NSScreen` geometry read on a 16-inch MacBook Pro.
