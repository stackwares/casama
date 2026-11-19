# Casama on the wrist: Apple Watch and Wear OS

Status: **approved and built as D-410 on 2026-11-19** (all §13 defaults taken). The native code is
type-checked and its model code tested, but it has not yet been built in Xcode or Gradle or run on
a watch or a simulator. Platform rules below were checked on 2026-11-18
against Apple's and Google's own pages, against the SDKs installed on this Mac (Xcode 27.2 with the
watchOS 27.2 SDK) and against the source of the Flutter tool we build with (3.50.0). What could not
be confirmed without a real watch is marked "to check on a watch". Sources are at the end. The
decision is D-410 in `docs/DECISIONS.md`; wire formats are in `docs/WATCH-PROTOCOL.md`.

Mockups: `docs/media/watch-mockups.html` (Apple Watch app, notifications, watch face and Smart
Stack; Wear OS app, tiles, watch face and notifications; the states both share).

Branch `watch`, worktree `.claude/worktrees/watch`.

## 0. Summary

A watch is good at three things: **knowing** (is a bot waiting on me, is it still working),
**deciding** (allow, deny, do it, stop) and **asking** (say one sentence, get one answer). This
plan builds those three, on both watches, and leaves everything else on the phone.

| Surface | Apple Watch | Wear OS | Its job |
|---|---|---|---|
| **The app** | SwiftUI | Compose for Wear OS | Now, Needs you, Ask, Working, Reply, Bots, Up next, Brief, Talk |
| **Notifications** | Our own layout, buttons that finish on the watch | Drawn by the watch app, same buttons | Most of what people will ever do |
| **Watch face** | Complications in all four shapes | Complications | The count, the next thing, a bot to ask |
| **One swipe away** | Smart Stack widgets; the iPhone's Live Activity | Tiles now, Wear Widgets later | A request with **Allow** in place; who's working; what runs next |
| **One press** | Controls, the Action button, Siri | Tile buttons, complication taps | Ask, talk, run a routine |

Eight findings shape the plan:

1. **Today a watch shows Casama's notifications and nothing works from it.** iPhone pushes are
   mirrored to the watch, but **Approve** and **Deny** are buttons that need our app to run, and
   there is no app on the watch. On Wear OS the same buttons run on the phone, behind its lock
   (§1).
2. **Flutter can't be the watch app.** It has no watchOS target at all. On Wear OS it runs, but
   tiles, complications and live surfaces are native only, and its crown-scrolling plugin is
   discontinued. So this is two small native apps. Flutter's tool does know how to build an iPhone
   app with a watch app inside it (§2.3).
3. **A watch has to reach the server by itself.** Apple and Google both say the phone link is a
   convenience, not the way data arrives, and we can't count on waking Flutter in the background
   to act for the watch. So the watch gets a key of its own, and the phone's only job is to sign
   it in (§8.2).
4. **Only plain HTTPS is dependable on Apple Watch.** WebSockets are blocked outside a call or an
   audio session, a request is cut off after two and a half minutes, there is no speech
   recognition framework and no Live Activities framework. Runs are followed with short streams of
   whole snapshots, dictation goes through the server or the system keyboard, and a live call
   comes last (§2.1).
5. **The server holds the rules; the watches only draw.** Two native apps must not each decide
   what a run is doing, what a risky request is, or how a reply reads as plain text. A small set
   of watch routes hands them finished words (§8.4).
6. **watchOS 26 and Wear OS 3 are the right floors.** Every watch that ran watchOS 11 runs 26, and
   Liquid Glass, controls, Smart Stack relevance and widget pushes all begin there. Wear OS 3
   covers every watch since 2021 (§2).
7. **The glance is shared with the widgets.** `GET /v1/glance` is being built on the `widgets`
   branch. The watch's home screen, complications and tiles read the same document, plus one new
   part: the runs that are live (§8.3).
8. **Nobody big is here yet.** ChatGPT, Claude, Gemini, Copilot and Perplexity have no Apple Watch
   app of their own; Meta shipped one on 9 November 2026. The small apps people pay for sell voice
   in, an answer out, and working without the phone. None of them has a bot that keeps working and
   asks you from your wrist.

It is built in eight phases (§12). Each is usable on its own.

## 1. What exists today

| Already there | Where | State on a watch |
|---|---|---|
| iPhone pushes | `packages/agent/src/notifications.ts` (`fcmMessage`), categories in `client/ios/Runner/AppDelegate.swift:28-47` | Mirrored when the iPhone is locked. `APPROVAL` has **Approve** and **Deny** as foreground buttons, which run on the device where they are tapped. With no watch app there is nothing to run them. To check on a watch what shows today |
| Android pushes | `PushNotifications.kt`, `SuggestionPush.kt` | Bridged to the watch. The buttons are `PendingIntent.getActivity` with `setAuthenticationRequired(true)`: they run on the phone and wait for it to be unlocked |
| A running bot, iPhone | `RunActivityWidget` in `CasamaWidgets.swift` | Shows in the Smart Stack by itself (iOS 18, watchOS 11) with the small Dynamic Island views. Our own watch layout isn't adopted (`CasamaWidgets.swift:200-202`: the extension still targets iOS 17). Tapping it offers to open the iPhone |
| A running bot, Android | `LiveRun.kt` | Doesn't reach the watch: ongoing notifications aren't bridged. On Wear OS 7 a Live Update may be, by the watch maker's choice |
| Siri and Shortcuts | `AskBotIntent`, `RunRoutineIntent` in `AppDelegate.swift` | Both open the iPhone app, so neither runs from the watch |
| Health data | `health` package (`features/devices/`) | What the watch records already reaches bots through the phone's Health sharing (D-328). Nothing to build |
| The glance and widget keys | `widgets` branch, not committed yet: `packages/contracts/src/glance.ts`, `apps/server/src/api/routes/glance.ts` | The summary a watch needs, and the pattern for a key that isn't a sign-in |
| A run's state in everyday words | `packages/agent/src/live-runs.ts` (`LiveRunPusher`, `liveStepWords`) | The server already turns a run's events into a phase, a step and a risk, for pushes |
| Dictation and read aloud | `POST /v1/voice/transcribe`, `GET /v1/messages/{id}/speech` | Plain HTTPS. A watch can use them as they are |
| Signing a second device in | `apps/server/src/api/routes/signin-codes.ts`, `client/lib/features/link/pairing.dart` | A QR code that ends in a full sign-in. A watch can't scan it and shouldn't hold a full sign-in |
| Bot marks drawn natively | `BotArt` in `CasamaWidgets.swift`, `BotArt.kt` | Reused for the watch as they are |

Gaps found while reading the code:

- **No watch target anywhere.** `Runner.xcodeproj` has Runner, CasamaWidgets and CasamaShare.
  `client/android/settings.gradle.kts` includes `:app` only. There is no WatchConnectivity and no
  Wearable Data Layer code.
- **`/v1` takes one kind of caller**: a Supabase sign-in token (`apps/server/src/api/app.ts`,
  lines 299 to 315).
- **The server doesn't know who may allow what.** "Never approve high risk from a button" is a
  rule in Dart (`approvalDecision` in `core/push.dart`) and in native code. Any signed-in caller
  can decide any approval.
- **A push token has no route.** The app writes `devices` through Supabase, and its `platform`
  check allows no watch.
- **Pushes leave through Firebase only**, and Firebase doesn't support watchOS officially. The
  server's one direct sender to Apple is for call rings (`ApnsVoipSender`), and production has no
  Apple key. The widgets plan needs the same key (its decision 4).
- **Reply pushes carry no category**, so nothing can attach a **Reply** button to them.
- **Native code holds no words.** The island's text arrives from Dart as a `labels` map. A watch
  that runs alone needs its words built in.
- **This Mac can't run either watch yet.** No watchOS simulator runtime and no Wear OS emulator
  image is installed.
- **The widgets plan lists "Apple Watch complications" under not shipping.** This plan takes that
  line over.

## 2. What the platforms allow

### 2.1 Apple Watch

- **Versions.** watchOS 27 shipped on 14 September 2026 and runs on Series 9 and later, SE 3, and
  Ultra 2 and later. Series 6, 7 and 8, SE 2 and the first Ultra stay on watchOS 26. Series 4, 5
  and the first SE stopped at watchOS 10. No watch stopped at 11. Xcode 27 can target watchOS 9
  to 27.
- **One target.** A watch app is a single SwiftUI target inside the iPhone app's project. Its
  bundle id must start with the iPhone app's (`ai.casama.app.watchkitapp`). It can be marked as
  running without the iPhone app; then people can install it alone from the watch's App Store, and
  it "can't rely on the Watch Connectivity framework as its main source of data".
- **Network.** Any app may use HTTPS through `URLSession`, including a streamed response. The
  watch sends it through the iPhone when the iPhone is near, else known Wi-Fi, else cellular.
  WebSockets and raw connections work only during a CallKit call or while streaming audio. A
  foreground request is cut after two and a half minutes. The app stays in front for two minutes
  after the wrist drops, by default.
- **Background.** At most about four refreshes an hour when a complication is on the active face,
  each with four seconds of processor time. No session type for long work fits a chat app.
- **Notifications.** The watch shows a notification when the iPhone is locked and the watch is on
  the wrist and unlocked. A button that opens the app runs **on the device where it was tapped**;
  a button that works in the background runs **on the device the push was sent to**. A watch app
  can give each category its own layout, and a reply button lets the person dictate. Double Tap
  presses the first button that isn't destructive.
- **Its own pushes.** A watch app gets its own push token. Apple: for an app that runs without the
  iPhone, "always send the notification to both iPhone and Apple Watch. The system ensures that
  the user only receives one notification at the best destination."
- **Live Activities.** The Live Activities framework isn't in the watchOS SDK, so a watch app
  can't start one. The iPhone's shows in the Smart Stack; `.supplementalActivityFamilies([.small])`
  (iOS 18) gives it a layout made for the watch, and with a watch app installed a tap opens that
  app (`WKSupportsLiveActivityLaunchAttributeTypes`, watchOS 11.1).
- **Complications and the Smart Stack.** WidgetKit shapes on a watch: circular, corner,
  rectangular and inline. All four can hold buttons (watchOS 11). From watchOS 26: widgets that
  show in the Smart Stack only when they matter (`RelevanceConfiguration`), controls in Control
  Center, the Smart Stack and on the Ultra's Action button, and refresh pushes from a server
  (`WidgetPushHandler`). Without a push, a complication the person looks at often gets 40 to 70
  refreshes a day. iPhone widgets don't appear on a watch; iPhone controls do.
- **Typing and talking.** The system offers dictation, Scribble and a keyboard (no keyboard on the
  SE). There is no way to open straight into dictation from SwiftUI. The Speech framework is not
  in the watchOS SDK, so the app can't transcribe by itself. It can record
  (`AVAudioRecorder`, `AVAudioEngine`, with echo cancelling) and speak (`AVSpeechSynthesizer`).
- **Calls.** CallKit and call pushes exist from watchOS 9. A live two-way call is the one case
  where a WebSocket is allowed.
- **Signing in.** Passkeys are unavailable on watchOS. Sign in with Apple and a web sign-in sheet
  exist. Apple names iCloud Keychain as a way to share a secret with the iPhone app, and warns
  that people can turn it off.
- **Who it is.** The watch can tell that it is on the wrist and unlocked
  (`deviceOwnerAuthenticationWithWristDetection`, watchOS 9).
- **The look.** Apps built for watchOS 10 or later get Liquid Glass on watchOS 26 automatically.
  Apple's guidance: interactions "that can last for less than a minute each", and "people
  frequently use a watchOS app's related experiences — like complications, notifications, and Siri
  interactions — more than they use the app itself."
- **Store.** Uploads must include 64-bit code. Screenshots are required, in one of six sizes.
  Review asks the same of a watch app as of any app.

### 2.2 Wear OS

- **Versions.** Wear OS 7 (Android 17, API 37) has been on Pixel Watch 2 to 5 since June 2026 and
  is reaching Samsung's newest watches. The first Pixel Watch stopped at Wear OS 5.1. Wear OS 3 is
  API 30. Google Play asks Wear apps to target API 35 or higher and to support 64-bit.
- **The toolkit.** Compose for Wear OS 1.7.1 with Material 3 Expressive: lists whose rows change
  size toward the edges (`TransformingLazyColumn`), a button that hugs the bottom edge
  (`EdgeButton`), colours taken from the watch face. The crown or bezel scrolls those lists with
  no extra code.
- **Always on.** From Wear OS 6, an app that targets API 36 stays on screen, dimmed, when the
  wrist drops. On older watches the system shows a blurred picture of it.
- **Tiles and Wear Widgets.** Tiles are one swipe from the watch face: one screen, no scrolling,
  one or two buttons, refreshed on a timer or when the app asks. Wear OS 7 introduced Wear Widgets
  as "the next step in the evolution of Tiles". Their libraries are still alpha, they need API 37,
  and on a Pixel Watch the tile is still what people see. Tiles stay supported.
- **Complications.** Short text, long text, a value in a range, small images. A complication may
  refresh every five minutes at most, or when the app asks.
- **Notifications.** A phone's notifications are bridged to the watch, except ongoing ones. A
  bridged button runs **on the phone**. A watch app can post its own instead and tell the system
  which of the phone's to stop bridging (bridge tags), and a dismissal id clears both at once.
  Google lists "missing `RemoteInput` for messaging apps replies" among the common reasons a Wear
  app is rejected.
- **Live surfaces.** Wear OS 7 shows Live Updates, for work that is "ongoing, user-initiated, and
  time-sensitive", not for chat messages or alerts. Older watches use the Ongoing Activity API: an
  icon on the watch face and a line in the app list.
- **Phone and watch.** The Wearable Data Layer carries small messages between a phone app and a
  watch app with the same package name and signing key, over Bluetooth or Google's cloud. Google
  lists "sending a session token from the phone to the watch during initial setup" as a proper
  use, and adds two rules: tell the person they are being signed in, and offer at least one other
  way to sign in.
- **Never a password on the watch.** Google's rule WO-P6.
- **Network.** HTTPS works, through the phone, Wi-Fi or cellular. Over Bluetooth it can be as slow
  as four kilobytes a second. Firebase pushes are supported on the watch itself and are "the
  recommended way to send notifications to a watch".
- **Voice.** Every watch has a microphone. The system offers a voice and keyboard input screen. A
  text-to-speech engine ships from Wear OS 4. Full-screen call notifications aren't supported.
- **Publishing.** A Wear app is its own bundle with the phone app's package name and signing key,
  its own version code, on its own Wear OS track in Play Console, with at least one round
  screenshot. It must declare whether it works without the phone. A rejected Wear bundle blocks
  listing updates for the phone app too.
- **Google's quality list** for a Wear app: black backgrounds, touch targets of 48 dp, swipe to
  close, a scroll bar, the person's font size honoured, everything inside a 192 dp circle, a tile
  that shows a preview and asks a signed-out person to sign in.

### 2.3 Flutter and the two build systems

- **Flutter has no watchOS target.** The watch app is Swift, in the same Xcode project.
- **The Flutter tool handles it.** In 3.50.0, `flutter_tools/lib/src/ios/mac.dart` looks for a
  target whose `Info.plist` names our iPhone app as its companion. When it finds one it leaves out
  the `-sdk` argument and the architecture settings, because "WatchKit dependencies cannot be
  build using the iOS SDK", and a simulator build then needs a device id (`-d`).
- **Known traps** from Flutter's issue tracker: the phase that embeds the watch app must sit
  before Flutter's own script phase, or Xcode reports a cycle; the watch target needs Flutter's
  three configurations (Debug, Profile, Release) and its platform set to watchOS in each, or
  archives fail. Flutter's own Apple Watch guide page no longer exists.
- **On Wear OS, Flutter would cost more than it saves.** Tiles, complications, Live Updates and
  the watch's notifications must be Kotlin whatever the app is written in. The plugin for crown
  scrolling is discontinued. The Material 3 Expressive pieces exist only in Compose.
- **A second module would join every phone build.** The Flutter tool runs Gradle tasks by bare
  name (`bundleRelease`), which Gradle runs in every module that has one. A Wear module inside
  `client/android/` would be built, and could fail, with every phone build.

## 3. Goals and what this is not

Goals:

- A person can **answer a bot from the wrist**: allow, deny, do it, stop, in one tap, with the
  phone in a pocket.
- A person can **ask a bot one thing by voice** and read or hear the answer, in under a minute.
- A glance at the watch face tells them **whether a bot is waiting, and whether one is working**.
- The watch **works without the phone** once it is signed in, on Wi-Fi or cellular.
- What the watch shows is **true, or says how old it is**.
- Nothing a stranger could read from a wrist, and nothing a stray touch could send.

This is not:

- The whole app, smaller. No settings, no bot setup, no computers, no Library browsing, no
  billing.
- A place to read long work. A reply shows its first screens, then **Open on iPhone**.
- A keyboard. Typing exists because the system provides it; the design assumes a voice or a tap.
- A health sensor for bots. The phone's Health sharing already carries what the watch records.
- A watch face.

## 4. Principles

1. **Two seconds to know, one tap to act.** A screen that needs reading twice is too full.
2. **The wrist decides small things; the phone decides big ones.** High risk is never allowed from
   a watch.
3. **The watch works alone.** The phone signs it in and then steps back.
4. **The server holds the rules.** A watch app never works out a risk, a step or a summary.
5. **True or dated.** Without a connection it drops the live colours and says "as of 9:12".
6. **Private when nobody is looking.** Wrist down, the person's words are hidden.
7. **Each watch's own language, one Casama.** Liquid Glass on one, Material 3 Expressive on the
   other; the same words, the same bot faces, and the same two colours that mean something.
8. **A tap on the wrist means something.** One haptic for "needs you", one for "done". No sound
   unless the person asked to hear a reply.
9. **Native and small.** No Flutter engine, no WebViews, no Firebase on the Apple Watch.
10. **Never a password on a watch.**

## 5. Words

| In the app and docs | Meaning | Not |
|---|---|---|
| **watch app** | Casama on an Apple Watch or a Wear OS watch | companion app, wearable |
| **Now** | The watch app's first screen | home, dashboard, glance |
| **Needs you**, **Needs your OK** | As in the app and the island (`pushNeedsYou`, `islandNeedsOk`) | pending |
| **Allow**, **Deny** | Answering a request, as the island says it (`islandAllow`, `islandDeny`) | approve, reject |
| **Review on iPhone** / **Review on phone** | A request the watch won't allow | escalate |
| **Open on iPhone** / **Open on phone** | Carry on where there is room | handoff |
| **Working**, **Finished**, **Stopped with a problem** | A run's state, as today | running, failed |
| **Up next**, **Run Now** | Routines in order, and starting one by hand (`runNow`) | schedule, trigger |
| **Do It**, **Not now** | Answering a suggestion (`doIt`) | accept, dismiss |
| **All clear** | Nothing needs the person (new, shared with the widgets) | empty |
| **quick replies** | The short answers offered under a reply | canned responses |
| **complication**, **tile**, **Smart Stack** | The systems' own names | widget (on a watch) |

Buttons use the app's capitals (**Do It**, **Run Now**). Notification buttons on the iPhone say
**Approve** today; they change to **Allow** so the phone and the watch say the same word.

## 6. The full set

### 6.1 The app's screens

The same screens on both watches. The mockups show each one.

#### A. Now

- One list, most urgent first: **Needs you** (the count and the first request), then each bot
  that is **working** (its step and a running clock), then what runs next.
- One big button: **Ask**. On Apple Watch it is the centre of the bottom bar, with **Bots** and
  **Up next** beside it, and Double Tap presses it. On Wear OS it is the edge button.
- Nothing waiting and nothing working: **All clear**, the bot's sleepy face, and "Brief at 7:00
  tomorrow".
- It opens from what the watch last saved, then refreshes. It never opens on a spinner.

#### B. Needs you

| What is waiting | The watch shows | Buttons |
|---|---|---|
| A **low risk** request | The bot, what it wants in everyday words, one or two lines of detail | **Allow** (one tap), **Deny** |
| A **medium risk** request | The same, plus what will be sent or changed (who an email goes to, its first line) | **Hold to allow**, **Deny** |
| A **high risk** request, or a payment | The same | **Review on iPhone**, **Deny** |
| A **suggestion** | The bot, its idea, one line of why | **Do It**, **Not now** |
| A takeover, a password request, a question from a connected app, a new skill | One line saying what it is | **Open on iPhone** |

- After **Allow**, **Deny** or **Do It**: a full-screen tick, a tap on the wrist, and the screen
  closes itself after a second.
- **Always Allow** is not on the watch. It changes how a bot behaves from then on, which is a
  phone decision.
- The server says whether this watch may allow this request (§8.4). The watch only obeys.
- A request someone already answered shows "Already answered" and leaves.

#### C. Ask

- Opens **already listening**, to the bot the person last asked. Stops by itself after a second
  and a half of silence, or on a tap. The bot's name at the top switches bots.
- Under the microphone: the person's own **starters** (D-338). A tap sends one.
- One scroll down: **Type instead**, which opens the system's keyboard, Scribble and dictation.
- What was heard shows for a moment with **Undo**, then goes. No "send" step.
- Each ask starts a new chat, as quick ask does on the phone. **Reply** continues the chat it
  answers.
- Without a connection the ask is kept and sent when the watch is back online, and the screen
  says so. A kept ask older than ten minutes asks before sending.

#### D. Working

- The bot's face in a ring, "Milo is working", the step in everyday words, a running clock, and
  **Stop**.
- When the bot needs an OK, this screen becomes the request (B), with a tap on the wrist.
- When it finishes, it becomes the reply (E), with a tap on the wrist.
- Wrist down: the app stays in front for two minutes, dimmed. After that the reply arrives as a
  notification.

#### E. Reply, and a bot's chat

- **Reply:** the bot's answer as plain text, large, up to about 1,200 characters. Below it:
  **Read aloud** (the same voice as the phone), **Reply** (the microphone), **Open on iPhone**.
- Longer answers end with "Continues on iPhone". A card, a page, a file or a picture shows as one
  line with its title ("Made a page: Q4 pricing") and **Open on iPhone**.
- **A bot's chat:** the last messages of its latest chat, the person's on the right, the bot's on
  the left. It is there to check what was said, not to scroll history.

#### F. Bots

- Up to eight bots, each with its own face and where it stands: **Working** with a clock,
  **Waiting for you**, or when it last replied.
- A tap opens the bot's chat. Its microphone asks that bot.

#### G. Up next

- Routines in the order they will run, across bots: the name, the time, the bot.
- **Run Now** on each. It shows "Started" with a tick; the run then appears on Now.
- Times count down by themselves.

#### H. Brief

- This morning's brief as plain text, with **Read aloud**. Before it arrives: "Brief at 7:00".
- Reached from the brief's notification, from Now's last row, and from its Smart Stack widget.

#### I. Talk (last phase)

- A live call with a bot: its face, a moving line while it speaks, captions, **Mute**, **End**,
  and the speaker or headphones.
- Until it is built, **Talk** on the watch starts the call on the phone.

#### J. Settings on the watch

- Who is signed in and which workspace, the bot **Ask** uses, **Hide details when my wrist is
  down** (on), **Read replies aloud** (off), **Sign out of this watch**.
- Everything else is set on the phone (§6.10).

### 6.2 Notifications

| Kind | The watch shows | Buttons | Where the button runs |
|---|---|---|---|
| **A bot needs your OK**, low or medium risk | The bot's face, "Needs your OK", what it wants | **Allow**, **Deny** | On the watch. Low risk: done, with a tick. Medium: opens the request with **Hold to allow** |
| The same, high risk | The same, marked high risk | Tap to open: **Review on iPhone**, **Deny** | On the watch |
| **A reply is ready** | The bot's name and the start of the reply | The person's **quick replies**, **Reply** (speak), tap to read it all | On the watch |
| **Couldn't finish** | The bot and why | Tap to open the chat | On the watch |
| **A suggestion** | "Ada suggests", the idea, one line of why | **Do It**, **Not now** | On the watch |
| **A routine's result**, **the brief** | The start of it | Tap to read, **Read aloud** | On the watch |
| A takeover, a password request, a missed call, account news | One line | **Open on iPhone** | The phone |

- **Allow** is the first button, so on a watch with Double Tap a pinch answers a low-risk request
  hands free. A medium-risk one opens instead.
- **Quick replies** are a short list (**Yes**, **No**, **Tell me more**, **Not now**) that the
  person can change on the phone. They are not written by a model: that would cost a model call
  for every reply.
- With **private notifications** on (self-hosted, through the relay) or **Hide reply text**, the
  push has no words. The watch app loads what happened from the server with its own key, as the
  phone app does.
- Quiet hours, the five notification switches and each bot's quiet setting apply as they do on
  the phone. There is no second set for the watch.

### 6.3 The watch face and one swipe away

**Apple Watch complications**

| Shape | Complication | Shows |
|---|---|---|
| Inline (the line on a face) | **Casama** | "2 need you", else the next routine, else "All clear" |
| Circular | **Needs you** | The count; a tick at zero |
| Circular | **Ask** (pick the bot) | The bot's face. A tap opens Ask, listening |
| Circular | **Credits** | The ring |
| Corner | **Needs you** | The count with a curved "need you" |
| Rectangular | **Needs you** | Who needs what; **Allow** in place for low risk |
| Rectangular | **Bot** (pick the bot) | Its name, where it stands, its step |
| Rectangular | **Up next** | The next routine and a countdown |

**Apple Watch Smart Stack.** The rectangular ones, set to come up by themselves when they matter
(watchOS 26): **Needs you** when the count is above zero, **Working** while a run of the person's
is live, **Up next** in the half hour before a routine, **Brief** in the hour after it arrives.

**Wear OS tiles**

| Tile | Shows | Button |
|---|---|---|
| **Needs you** | The count and the first request | **Allow** (low risk), else **Review** |
| **Ask** (pick the bot) | The bot's face and two starters | **Speak** |
| **Up next** | The next routine, its bot, the one after | **Run Now** |
| **Bot** (pick the bot) | Where it stands and its last line | **Ask** |

**Wear OS complications:** the count (short text), the first request (long text), credits (a value
in a range), and a bot's face that opens Ask (small image).

- On a watch face the system removes backgrounds and may tint everything one colour. Mascots keep
  their shape; numbers and names carry the meaning.
- A complication that can't refresh shows no claim about now.
- Signed out, every tile and complication says "Open Casama to sign in".

### 6.4 One press

| | Apple Watch | Wear OS |
|---|---|---|
| **Ask** | A control (Control Center, Smart Stack, the Ultra's Action button); "Ask Casama" to Siri | The Ask tile and complication |
| **Talk** | A control | The Bot tile (last phase) |
| **Run a routine** (pick it) | A control; "Run my morning brief in Casama" to Siri | The Up next tile |
| **What needs me?** | To Siri: it says the count and the first request | — |

- Asked through Siri, a short answer is spoken by Siri itself when the bot replies within about
  twenty seconds. Otherwise Siri says the bot is on it, and the reply arrives as a notification.
- Gemini on Wear OS can't call other apps yet. Google's way to do it (AppFunctions) is still
  experimental and by invitation.

### 6.5 Live runs

- **Apple Watch:** the iPhone's Live Activity, with a layout made for the watch (the bot's face,
  its state, the clock), in the Smart Stack. A tap opens the watch app at that run. A run started
  from the watch starts the iPhone's Live Activity by push (D-324 already built that), so it shows
  the same way. With no iPhone in reach, the **Working** Smart Stack widget and the app show it.
- **Wear OS:** the watch app posts its own. A Live Update on Wear OS 7; an Ongoing Activity on
  Wear OS 3 to 6: an icon on the watch face and a line in the app list. The phone's copy is told
  not to bridge.
- Both end as **Finished** and clear themselves. A run the person stopped leaves at once.

### 6.6 Voice

| Feature | How | Phase |
|---|---|---|
| **Dictation** | The watch records; the server transcribes (the phone's own way, so mixed languages work). The system's dictation is one scroll away, and takes over on a server with no voice service | 1 and 3 |
| **Read aloud** | The bot's voice from the server, played on the watch speaker or headphones. The watch's own voice when the server has none | 1 and 3 |
| **Voice mode** | Ask, hear the answer, ask again, without touching the watch | 6 |
| **A bot rings** (D-135) | The wrist rings; **Answer** starts the call, **Decline** tells the bot | 6 |
| **A live call** | Gemini Live from the watch itself | 6, after a trial |

### 6.7 Touch, crown and gestures

- **Double Tap** (Series 9, Ultra 2 and later): Ask on Now, Allow on a low-risk request, Stop
  never.
- **Hold to allow** takes most of a second and fills as it goes. With VoiceOver or TalkBack it
  becomes a tap followed by "Allow sending this email?".
- **The crown, the bezel:** scroll. Nothing else.
- **Wear OS:** swipe right closes any screen, as the system expects.
- **Destructive things are never the easy thing.** Deny is never the first button, Stop is never a
  gesture.
- **Haptics:** one for needs you (`notification`), one for done (`success`), one for a problem
  (`failure`), a click when a hold completes. On Wear OS the matching patterns.

### 6.8 States every screen has

| State | What it shows |
|---|---|
| Not signed in, phone app at hand | "Signing you in", then the person's name once. Nothing to tap |
| Not signed in, no phone app | A code and "Type it in Casama on your phone or computer" |
| Signed out from the phone | "Signed out. Open Casama on your phone to sign in again" |
| No connection | What was last saved, in grey, with "as of 9:12" |
| Wrist down | Counts and clocks; the person's words replaced by bars |
| Server too old | "Update your Casama server to use the watch" |
| Out of credits | "Out of credits" and **Open on iPhone**. Allow, Deny and Stop still work |
| First load | The layout in grey, never a spinner |
| Large text | A row is dropped rather than shrunk or cut |

### 6.9 The look

- **Background:** black on both, which is the plain background of a watch and what Google
  requires. Cards are dark grey.
- **Colour:** amber (`#F0A84A`) means needs you. Green (`#5FD49A`) means working. The brand orchid
  (`#F2B0EC` on dark, from `client/looks/schemes/casama.json`) is the one main button. Red is Stop
  and high risk. A bot's own colours stay on its own mark. Nothing else is coloured.
- **On Wear OS** the system may recolour buttons to match the watch face. Amber and green stay as
  they are, because they carry meaning.
- **Type:** the system's (SF Compact Rounded; Google Sans Flex or Roboto Flex). Nothing under 12
  points. Numbers keep a fixed width so clocks don't jump.
- **Faces:** the ten mascots from `client/assets/mascots/`, as still pictures at watch sizes, and
  the initials tile for bots without one, drawn exactly as `bot_avatar.dart` draws it.
- **Motion:** the working ring turns, a hold fills, a tick draws. Nothing else moves, and none of
  it with Reduce Motion on.
- **Sizes:** designed on the smallest first (40 mm, 162 by 197 points; a 192 dp circle), checked
  on the largest (49 mm; 227 dp).
- **Words:** the app's own, from `app_en.arb`, built into each watch app by a script so they can't
  drift.

### 6.10 The phone, discovery and docs

- **Settings → Watch** (new, in the Flutter app):
  - each watch signed in: its name, model, when it was last used, **Remove**;
  - **Sign in a watch with a code**;
  - **Allow from the watch**: Low and medium risk (default), Low risk only, Never;
  - **Show details on the watch** (follows the app lock, §10);
  - **Quick replies**: up to six;
  - how to add a complication and a tile, with pictures.
- **Signing in is automatic.** The first time the watch app opens with the phone app signed in,
  the phone signs it in and both say so: "Signed in as Oliver from your iPhone".
- **One quiet nudge:** after a person's first approval on a phone that has a watch paired, a line
  that Casama is on the watch. Shown once.
- **Open on iPhone** leaves a notification on the phone that opens the right place, and sets the
  system's Handoff. On Android it opens the phone app directly.
- **Docs:** new `docs-site/guide/apple-watch.md` and `docs-site/guide/wear-os.md`; lines in
  `lock-screen.md`, `privacy.md` and the notifications page; a self-hosting line on what needs
  Casama Cloud's relay.

## 7. What we're not shipping, and why

| Not shipping | Why |
|---|---|
| Flutter on either watch | No watchOS target; on Wear OS the parts that matter are native only (§2.3) |
| High-risk **Allow**, **Always Allow**, payments | The wrist decides small things. Deny stays, since saying no is safe |
| Typing a password, a key or a secret | Google forbids it and Apple's keyboard is no place for one. Those requests open on the phone |
| Taking over a bot's computer, the live view | A remote desktop doesn't fit 40 mm |
| The Library, tasks, projects, search | Browsing is phone work. The glance's counts are enough for now |
| Bot setup, routines editing, billing, workspace people | Settings are phone work |
| Replies written by a model for each message | A model call per reply, on every reply. A fixed list costs nothing |
| A watch face of our own | Apple doesn't allow them; Wear's need a separate format and add nothing |
| Wear Widgets in the first release | Alpha libraries, API 37 only. Tiles reach every watch today (decision 13) |
| Gemini or Siri AI calling Casama | Not open to other apps yet on Wear OS; Siri gets App Shortcuts |
| Heart rate, sleep and workouts from the watch app | The phone's Health sharing already carries them (D-328) |
| An analytics or crash SDK on the Apple Watch | The server counts what watch keys do (§15); Apple's own crash reports cover the rest |
| Square Wear OS screens | Not in Google's test list, and no current watch has one |
| A watch app for a second account | The watch follows the phone (decision 16) |

## 8. How it works

### 8.1 The shape

```
 Apple Watch app (SwiftUI)  ─┐                          ┌─ packages/agent/src/watch.ts
 its widgets and controls   ─┼─ HTTPS, "Watch <key>" ──►│  plain words, risk rules, snapshots
 Wear OS app (Compose)      ─┤                          │  apps/server/src/api/routes/watch.ts
 its tiles and complications─┘                          └─ the glance (shared with widgets)

 Phone app (Flutter) ── signs the watch in, lists and removes watches, never relays data
```

- The watch talks to the person's own server: Casama Cloud, or a self-hosted one at its address.
- The phone link (WatchConnectivity, the Data Layer) carries three things only: the watch's
  request to be signed in, the answer (which server, which workspace, the person's name), and
  "open this on the phone".
- No watch code talks to Supabase, Firebase Realtime or a model provider.

### 8.2 Watch keys and signing in

**The key.** Each watch makes its own key, 32 random bytes, and keeps it in its own keychain
(Apple: this device only, readable after first unlock, in a group its widgets share; Wear OS:
encrypted under an Android Keystore key). **Only the key's fingerprint ever leaves the watch.**
The server stores that fingerprint, as it stores a widget key's.

**Signing in from the phone** (the usual way):

1. The watch app opens with no key accepted yet. It sends the phone its fingerprint, name and
   model.
2. The phone app, signed in, registers the fingerprint: `POST /v1/watch-keys`.
3. The phone answers the watch: the server's address, the workspace, the person's name.
4. The watch calls the server with `Authorization: Watch <key>`. Both devices say "Signed in as
   Oliver".

If the phone app isn't running, the request waits and is answered the next time it opens; the
watch shows "Open Casama on your iPhone to finish". With the app lock on (D-375), the phone asks
before step 2.

**Signing in with a code** (no phone app at hand, and the second way Google requires):

1. The watch asks the server for a code and shows it: `KQ7 M2X`, good for ten minutes.
2. The person types it into Casama anywhere they are signed in (Settings → Watch), sees which
   watch is asking, and allows it.
3. The watch, which has been asking every few seconds, finds its key accepted.

This works with Casama Cloud. A self-hosted server signs a watch in through the phone, since the
watch has no way to learn its address.

**Signing out.** **Remove** on the phone, signing out of the phone app that paired it, or **Sign
out of this watch** deletes the key on the server. The watch's next call gets a 401; it wipes
what it saved and every complication and tile goes to "signed out".

### 8.3 The glance, plus live runs

The watch reads the glance the widgets plan defines (`needs`, `bots`, `next`, `brief`, `credits`,
`starters`, `flags`, a version for "not changed"). One part is added, for every reader:

| Part | Holds | At most |
|---|---|---|
| `runs` | Runs the person started by hand that are live: run, bot, phase, step in general words, step count, start time, approval and risk if one is waiting, link | 3 |

It is built by the code that builds live pushes today (`live-runs.ts`), so the watch, the Live
Activity and the Android notification can't disagree about a run.

### 8.4 What a watch may call

A watch key is refused everywhere except this list.

| The watch wants to | Route | Note |
|---|---|---|
| Read the glance | `GET /v1/glance` | Shared with widgets |
| Read a bot's latest chat | `GET /v1/watch/chats/{bot_id}` | New. Plain text, cut to fit, cards as one line |
| Ask or reply | `POST /v1/watch/ask` | New. Text, or the recording itself (the server transcribes and sends in one step). Makes the chat when there is none. Returns what it heard |
| Follow a run | `GET /v1/watch/runs/{id}` | New. One snapshot; or a stream of whole snapshots that the server ends after 110 seconds |
| Read a request | `GET /v1/watch/approvals/{id}` | New. Everyday words, up to three detail lines, and **whether this watch may allow it** |
| Answer a request | `POST /v1/approvals/{id}/decision` | As today, with the watch's limits enforced by the server |
| Answer a suggestion | `POST /v1/suggestions/{id}/accept`, `/dismiss` | As today |
| Run a routine | `POST /v1/routines/{id}/run` | As today |
| Stop a run | `POST /v1/runs/{id}/cancel` | As today |
| Transcribe, read aloud | `POST /v1/voice/transcribe`, `GET /v1/messages/{id}/speech` | As today |
| Describe itself | `PUT /v1/watch-keys/current` | New. Push token, app version. `DELETE` signs the watch out |
| Learn about the server | `GET /v1/config` | As today, plus `watch: true` |

For a watch key the server itself refuses: **Always Allow**; allowing above the level the person
set (medium by default); allowing any high-risk request or payment; anything in a workspace that
has turned watch approvals off. Deny is always accepted.

Every write carries an idempotency key (the API already honours them), so a retry on a bad
connection can't send twice.

### 8.5 Pushes

| | Phases 1 to 4 | Phase 5 |
|---|---|---|
| **Apple Watch alerts** | The iPhone's pushes, mirrored. The watch app supplies the layouts and runs the buttons. One server change: reply pushes gain a category | The watch's own token too, sent straight to Apple, so a watch away from its phone is reached |
| **Apple Watch complications** | Refresh on the system's schedule and whenever the app runs | Refresh pushes (watchOS 26), the same sender as the widgets plan |
| **Wear OS alerts** | Phase 3: bridged from the phone, read only. Phase 4: the watch app registers its own Firebase token and draws approvals, suggestions and replies itself | The same |
| **Wear OS tiles and complications** | Refresh on a timer and when the app runs | The same push wakes the app to refresh them |

- **No duplicates on Wear OS:** the phone tags what the watch draws, the watch app tells the
  system not to bridge those tags once it is signed in, and a shared dismissal id clears both.
- **Replies on Wear OS** need the phone to draw its own reply notifications (so it can tag them).
  Phones on an older app keep the system-drawn ones; for those people the watch shows the bridged
  copy instead of its own.
- **Self-hosted servers** send through Casama Cloud's relay, as today. The relay learns a watch's
  push token and nothing about what happened when private notifications are on.

### 8.6 Pieces

| Piece | Where | Size |
|---|---|---|
| Watch contract and routes | `packages/contracts/src/watch.ts`, `routes/watch.ts`, `apps/server/src/api/routes/watch.ts` | TypeScript, about 600 lines |
| Plain words, limits, snapshots | `packages/agent/src/watch.ts`; `runs` in `glance.ts` | TypeScript, about 450 lines |
| Keys and codes | `supabase/migrations/…_watch_keys.sql`, pgTAP tests | SQL, about 150 lines |
| The phone's part | `client/lib/features/watch/` (`watch_bridge.dart`, `watch_screen.dart`), `client/ios/Runner/WatchBridge.swift`, `client/android/.../WearBridge.kt` | Dart 450, Swift 180, Kotlin 220 |
| Apple Watch app | `client/ios/CasamaWatch/` | SwiftUI, about 3,200 lines |
| Apple Watch complications, Smart Stack, controls, Siri | `client/ios/CasamaWatchWidgets/` | SwiftUI, about 1,100 lines |
| Code both Apple targets share | `client/ios/Shared/` (`Glance.swift`, `BotMark.swift`, `WatchAPI.swift`) | Swift, about 500 lines |
| Wear OS app | `client/wear/` (its own Gradle project) | Kotlin, about 3,400 lines |
| Wear OS tiles, complications, notifications, live surface | `client/wear/` | Kotlin, about 1,300 lines |
| Apple pushes, watch pushes | `packages/agent/src/apns.ts` (from `ApnsVoipSender`), `notifications.ts`, the relay | TypeScript, about 350 lines |
| Words and fixtures | `scripts/gen-watch-strings.mjs`, `packages/contracts/fixtures/watch/*.json` | A script and sample answers |
| Packaging | `scripts/package-wear.sh`; a line in `scripts/package-ios.sh` | Shell |

### 8.7 Apple Watch notes

- **Targets.** `CasamaWatch` (a single-target watchOS app) and `CasamaWatchWidgets` (its WidgetKit
  extension), in `Runner.xcodeproj`. Bundle ids `ai.casama.app.watchkitapp` and
  `ai.casama.app.watchkitapp.widgets`. Both get Debug, Profile and Release, the platform set to
  watchOS in each, standard architectures, and their version from Flutter's build name and number
  as the other extensions do.
- **Runner** gains an "Embed Watch Content" phase before Flutter's script phase, and depends on
  `CasamaWatch`. The watch app's `Info.plist` sits in a folder named after the target, with
  `WKCompanionAppBundleIdentifier`, so Flutter's tool recognises it.
- **Deployment target watchOS 26.0** (decision 7). It runs without the iPhone app
  (`WKRunsIndependentlyOfCompanionApp`, decision 8).
- **No CocoaPods, no packages, no Firebase** in either watch target. They use only the system's
  frameworks.
- **Networking** is `URLSession` only. The run stream is a streamed HTTPS response the server
  ends before Apple's limit; the watch asks again and gets the whole state.
- **Speaking a request** records AAC with `AVAudioRecorder`. **Type instead** uses the system's
  text input.
- **Notifications.** A `WKNotificationScene` per category with our layout. `APPROVAL` and
  `SUGGESTION` keep the buttons the iPhone app registers; they are foreground buttons, so the
  watch app runs them. Quick replies are buttons inside the reply layout.
- **Complications** read the glance from the watch app's group container and fetch it themselves
  with the shared key when they refresh. On watchOS 27 the iPhone app also nudges them over
  WatchConnectivity when it is running.
- **The Live Activity's watch layout** lives in the iPhone's widget extension and needs that
  extension on iOS 18 (decision 15, the same as the widgets plan's decision 9).
- **Allowing** first checks the watch is on the wrist and unlocked. A watch with no passcode can
  read and deny, not allow.
- **Simulator builds need a device id** once the watch target exists. `flutter run` and the
  integration tests already pass one.

### 8.8 Wear OS notes

- **Its own Gradle project** at `client/wear/` (decision 14): the same Gradle, Android plugin and
  Kotlin versions as the phone, the same package name (`ai.casama.app`), signed with the same key
  (`client/android/key.properties`). Version name from `client/pubspec.yaml`; version code
  1,000,000,000 plus the build number, so it never collides with the phone's.
- **minSdk 30, targetSdk 36, compileSdk 37.** Target 36 gives the dimmed always-on screen for
  free. Target 37 would ask for a new permission to reach a server on the home network, so it
  waits.
- **Libraries, all stable:** Wear Compose 1.7.1, Tiles 1.6.2 with ProtoLayout 1.4.2
  (`Material3TileService`), complications 1.3.0, Ongoing Activity 1.1.0, the Data Layer 20.0.1,
  OkHttp. Firebase Messaging from Phase 4, set up at run time from `client/config/firebase.json`,
  as the phone app is.
- **Declared as working without the phone** (`com.google.android.wearable.standalone` true).
- **The clock and the status bar are the system's.** Wear Compose 1.8 hands them over; we draw
  neither.
- **Speaking a request** records with `MediaRecorder`. **Type instead** opens the system's voice
  and keyboard input.
- **Sound** plays on the speaker when there is one and no headphones are connected, as Google
  allows for anything that isn't media.
- **R8 and a baseline profile** from the first release.

### 8.9 The phone app's part

- `WatchBridge.swift` and `WearBridge.kt` are small: they receive the watch's request, hold it if
  Flutter isn't running, and pass the answer back. Channel `casama/watch`.
- Dart decides (`watch_bridge.dart`): is someone signed in, is the app lock asking first, which
  workspace. It registers the key and never sees the key itself.
- `PushNotifications.kt`, `SuggestionPush.kt` and `LiveRun.kt` add a bridge tag and a dismissal id
  to what they draw. From Phase 4 the phone also draws reply notifications itself.
- The iPhone app's `APPROVAL` buttons are renamed **Allow** and **Deny**; nothing else changes
  there.
- The Android phone app gains one library, `play-services-wearable`.

### 8.10 Server notes

- **`watch_keys`** (person, workspace, platform `watchos` or `wearos`, key fingerprint, name,
  model, versions, allow level, private, push token and kind, how it was paired, last used).
  Row-level security lets a person see and delete only their own; the worker gets
  `public.allow_worker`. At most ten a person per workspace.
- **`watch_key_requests`** for codes: the code's and the key's fingerprints, expiry, who claimed
  it. No one reads it but the API. Five requests an hour per address (an IPv6 /64 counts as one),
  five wrong codes an hour per person. Looking a code up doesn't use it up.
- **Auth:** a third branch beside `Bearer` in `app.ts`, shaped like the widgets branch's
  `widgetCaller`: check the route against the list, find the key, check the person is still in
  the workspace, count it. If the widgets branch has landed first, both become one resolver with
  two kinds of key.
- **Its own rate limit:** 60 requests a minute per watch key, separate from the person's 120, so
  a watch can't starve the phone and the reverse.
- **Two-step sign-in:** nothing on a watch key's list is an owner-or-admin action, so the second
  step never comes up.
- **The routes that work signed out** (asking for a code, checking it) go on the contracts list
  of such routes.
- **Run snapshots** listen to the same event bus as `LiveRunPusher` and add the reply's text.
- **Reply pushes** gain `category: "REPLY"`. Phones without a matching category ignore it.
- **`devices`** is untouched. A watch's token lives on its key.

## 9. Changes by area

| Area | Change |
|---|---|
| `packages/contracts`, `packages/agent`, `apps/server` | The watch contract, routes and words; `runs` in the glance; the key branch and its limits; the Apple sender; watch pushes; `category` on replies; `watch` in `/v1/config` |
| `packages/domain` | Which risks a watch may allow, in one place, used by the server |
| `supabase/migrations`, `supabase/tests` | `watch_keys`, `watch_key_requests`, policies, pgTAP |
| `dart/casama_api` | Regenerated client |
| `client/lib/features/watch/` (new) | The bridge and Settings → Watch |
| `client/lib/core/backend.dart`, `supabase_backend.dart`, `test/fake_backend.dart` | `watchKeys`, `registerWatchKey`, `claimWatchCode`, `updateWatchKey`, `removeWatchKey` |
| `client/lib/l10n/app_en.arb` | The watch's words (keys starting `watch`), and Settings → Watch |
| `client/ios` | Two new targets, `Shared/`, `WatchBridge.swift`, the embed phase, the renamed buttons; later the widget extension's iOS 18 and the Live Activity's watch layout |
| `client/android` | `WearBridge.kt`, bridge tags, reply notifications drawn natively, one library |
| `client/wear` (new) | The Wear OS project |
| `scripts/` | `gen-watch-strings.mjs`, `package-wear.sh`, the fixtures check |
| `packages/contracts/analytics/catalog.json`, `client/lib/core/telemetry.dart` | §15 |
| `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/COSTS.md`, `docs-site/`, `client/store/` | The decision, the file map, a cost line, two guide pages, the listings |

## 10. Security and privacy

- **A watch key is a short leash.** It can read a summary and a chat's recent text, ask, stop,
  run a routine, and answer requests up to a level. It can't change a setting, read a secret, see
  a file, open a computer, spend above medium risk, or make another key. Lost, it is removed from
  the phone in two taps.
- **The key never travels.** The watch makes it; the phone and the link between them carry only
  its fingerprint.
- **The server enforces the limits**, for the first time. Today "no high risk from a button" is
  the app's promise; for a watch key it is the server's refusal.
- **A watch off the wrist is locked** when it has a passcode. Allowing checks that it is on the
  wrist and unlocked; without a passcode the watch can't allow at all.
- **Medium risk takes a hold**, and shows what will be sent before it.
- **Wrist down**, the person's words are hidden; counts, bot names and clocks stay.
- **App lock on (D-375):** signing a watch in asks on the phone first, and the watch shows
  general words only until **Show details on the watch** is turned on. A workspace that requires
  the app lock can also turn watch approvals off.
- **Hide reply text** (D-325) hides replies in notifications and complications on the watch as it
  does on the phone.
- **Recordings** go to the server over HTTPS and are handled exactly as dictation from the phone
  is. Nothing is kept on the watch.
- **What the watch keeps:** the last glance and the last chat it showed, in its own storage,
  wiped at sign-out.
- **Pushes** to a phone carry what they carry today. A watch's own copy follows **Show details on
  the watch**: with it off, the bot's name and general words ("Needs your OK", "Replied"). With
  private notifications on, they carry nothing and the watch fetches the rest itself.
- **A code** is eight characters from an alphabet without look-alikes, good for ten minutes and
  one use, and the person sees which watch is asking before allowing it.
- **Signing in tells the person**, on both screens, as Google requires and as is right.

## 11. Cost

- Apple's and Google's push services are free at any volume. No new paid service.
- **Dictation and read aloud** use the server's existing voice service, charged as they are from
  the phone. A spoken ask is a few seconds of transcription. `docs/COSTS.md` gets a line saying
  watch dictation is the same charge as phone dictation.
- **The server** adds small indexed reads: the glance (answered "not changed" most of the time),
  a run snapshot stream while a watch screen is lit, a key lookup per call.
- **Stores:** no new fee. Both watches are on the accounts we already pay for.
- **No model call** is added anywhere: quick replies are a fixed list, and words are rules.

## 12. Phases

Every phase ends with its tests green (`flutter analyze`, `flutter test`, and for server work
`pnpm test` plus pgTAP, through `scripts/heavy.sh`), the watch apps' own unit tests, a decision
entry, docs and a commit on the `watch` branch. Builds and deploys are asked for one at a time, as
`AGENTS.md` requires.

| Phase | What | Done when | Needs from Oliver |
|---|---|---|---|
| **0. Ground** | Watch keys, codes, the key branch, the watch routes, `runs` in the glance. The phone's bridge and Settings → Watch. An empty watch app in each build system. The words script and the fixtures | Server tests cover every route, every refusal and both ways to sign in. An empty app on an Apple Watch simulator and on a Wear OS emulator signs in from the phone app and by code and shows the Needs-you count. `flutter run`, `flutter build ios`, `flutter build ipa`, `flutter build appbundle` and the Wear bundle all still build | The two simulator downloads; an iOS and an Android build; a production deploy |
| **1. Apple Watch: the app** | Screens A to H and J. Notification layouts and buttons. Dictation, read aloud. Open on iPhone. Wrist-down privacy. The offline queue | Simulator pictures of every screen and state at 40 mm and 49 mm, and at the largest text size. On a watch: allow from a notification with the iPhone locked; ask by voice and get the reply; run a routine; stop a run; all of it again with the iPhone switched off | An iOS build; an Apple Watch on watchOS 26 or later |
| **2. Apple Watch: the face and beyond** | Complications, Smart Stack widgets, controls, Siri, the Action button. The Live Activity's watch layout and opening the watch app from it | Pictures of each on its faces and in the Smart Stack. On a watch: add each one, press each button, pinch to allow | An iOS build; decision 15 |
| **3. Wear OS: the app** | The same screens in Compose. Sign-in both ways. Ambient. Bridged notifications as they are | Emulator pictures on the small and the large round screen, at the largest font. On a watch: the same checks as Phase 1 | The Wear OS form factor added in Play Console; a Wear build; a Wear OS watch |
| **4. Wear OS: tiles, face, notifications** | Four tiles, four complications. The watch's own notifications with buttons and spoken replies. The live surface. Bridge tags on the phone; the phone drawing replies | Allow from the watch with the phone locked. No notification twice. A run shows on the watch face and clears. Reply by voice from a notification | An Android and a Wear build; a deploy |
| **5. Fresh without the phone** | The watch's own push token on Apple; the Apple sender; refresh pushes for complications; background refresh on both; the relay's new bodies | With the phone off and the watch on Wi-Fi or cellular: a request reaches the wrist within a minute and **Allow** works; the count on the watch face is right within a minute | The Apple push key in production (also the widgets plan's decision 4); a deploy |
| **6. Voice** | Voice mode. A bot's ring on the wrist. A live call on the wrist, after a trial | The trial's numbers first: a five-minute call on Wi-Fi, on cellular and through the phone, with gaps, battery and heat written down. Then the call screen | Decision 12; builds; both watches |
| **7. Stores and launch** | Screenshots, listings, review notes and a test account. The two guide pages. The nudge. §15's numbers | Both stores approve the watch apps | Uploads, which only Oliver starts |

Phases 1 and 3 don't depend on each other, nor do 2 and 4. All need 0. Phase 5 shares its server
work with the widgets plan's Phase 3; whichever comes first builds the Apple sender.

**What Phase 0 must prove before anything else is written:** that adding the watch target doesn't
break or slow the iPhone builds every other session makes. If it does, the watch app comes out of
the `Runner` target: a script builds it by itself and adds it to the archive before export, so
everyday phone builds never touch it.

## 13. Decisions for Oliver

Each has a default this plan assumes. Say "defaults" to take them all.

| # | Decision | Default |
|---|---|---|
| 1 | Two native apps, SwiftUI and Compose. No Flutter on a watch | Yes. Flutter can't target watchOS, and on Wear OS it can't make tiles or complications |
| 2 | The line-up and its order: the app and notifications first on each watch, then the face, then pushes without the phone, then voice | Yes |
| 3 | The watch gets a key of its own and talks to the server itself. The phone only signs it in | Yes. Going through the phone fails whenever the phone app is asleep or away |
| 4 | Signing in from the phone is automatic and says so. With the app lock on, the phone asks first | Yes. The other choice is always asking |
| 5 | From the wrist: low risk one tap, medium risk a hold, high risk and payments never. Deny always | Yes. Other choices: low risk only; or medium with a plain tap |
| 6 | Double Tap allows a low-risk request from its notification | Yes |
| 7 | Oldest systems: watchOS 26 and Wear OS 3 | Yes. watchOS 26 runs on every watch from Series 6 on. People who never updated from watchOS 11 or 10 keep today's mirrored notifications |
| 8 | The Apple Watch app runs without the iPhone app installed | Yes. It can then be installed from the watch's own store, and signs in with a code |
| 9 | **Ask** starts a new chat each time, as quick ask does. **Reply** continues | Yes |
| 10 | The microphone uses Casama's own dictation, as the phone does; the system's is one scroll away | Yes. It is one tap, and it copes with mixed languages. It is charged as phone dictation is |
| 11 | Quick replies are a fixed list the person can edit. No replies written by a model | Yes |
| 12 | A live call on the wrist comes last, after a trial. Until then **Talk** starts the call on the phone | Yes. It needs CallKit, raw audio and a strong connection, and nobody has shown it works well |
| 13 | Wear OS gets Tiles now and Wear Widgets when their libraries are stable | Yes |
| 14 | The Wear OS app is its own Gradle project at `client/wear/` | Yes. Inside `client/android/` it would be built with every phone build |
| 15 | Raise the iPhone widget extension to iOS 18 for the Live Activity's watch layout | Yes. The widgets plan asks the same (its decision 9) |
| 16 | The watch shows the workspace the phone is on | Yes. Switching on the phone switches the watch |
| 17 | Wrist down, the person's words are hidden, with a switch on the watch | Yes |
| 18 | System fonts, black backgrounds, and colour only for needs you, working, the main button and Stop | Yes |

## 14. Risks

| Risk | What we do |
|---|---|
| The watch target breaks or slows iPhone builds for every session | Phase 0 runs every build command on the branch before any screen exists. The fallback is named in §12. The branch merges into `main` only when the phone builds are unchanged |
| A mirrored notification doesn't use our layout, or its button doesn't open the watch app | Apple's pages say both work; no real watch has shown us. It is Phase 1's first check on a watch. If it fails, the watch's own pushes move from Phase 5 to Phase 1 |
| A notification shows twice (Apple with two tokens, Wear OS with bridging) | Apple says it sorts this out for pushes sent together; ours take two roads. Checked on a watch in Phase 5, with one collapse id on both. On Wear OS, bridge tags and dismissal ids, checked in Phase 4 |
| Someone allows something by accident: a sleeve, water, a pocket | A hold for medium, nothing for high, the wrist check, the server's own limit. §15 watches for approvals followed by Stop within ten seconds |
| A watch is lost or sold | It locks off the wrist. **Remove** on the phone kills the key. The key was never able to do much |
| Two native apps drift apart | The server writes the words and the rules. Both apps decode the same sample answers in their tests. Both get their strings from one script |
| The connection through the phone is slow | Small answers (the glance is under 6 KB and usually "not changed"), what was saved shown first, writes that can be retried safely |
| Battery | Nothing polls. A stream runs only while its screen is lit. Everything else waits for a push |
| App Review or Play review says no | The watch app does real work alone. Sign-in needs no password. Google's quality list is in Phase 3's checks. A test account goes with the submission |
| A rejected Wear bundle blocks the phone app's listing updates | The Wear app goes to its internal track first and to review only when Phase 4 passes |
| Tiles are replaced sooner than expected | Tiles and Wear Widgets can ship side by side under one name; the tile's content is already data from the glance |
| A live call on a watch turns out poor | It is last, behind a trial with numbers, and **Talk** already works by starting the call on the phone |
| A self-hosted server can't be reached away from home | The watch shows what it saved and its age. With a Casama Link address it works anywhere |
| The widgets branch and this one both change the auth branch and the glance | One of them lands first; the other rebases onto it. This plan copies nothing from that branch |

## 15. How we'll know it worked

The server counts what watch keys do, so the Apple Watch needs no analytics SDK. Added to the
catalog, with no names, titles or text:

- `platform` gains `watchos` and `wearos`.
- `watch_paired`, with `method` (`phone`, `code`).
- `watch_action`, with `action` (`allow`, `deny`, `do_it`, `run`, `stop`, `ask`, `reply`,
  `read_aloud`) and `surface` (`app`, `notification`, `complication`, `smart_stack`, `tile`,
  `control`, `siri`).
- `watch_surfaces`, once a day per watch: how many complications and tiles are placed.

What we watch after release: the share of people with a watch who sign it in; the share of
requests answered from a watch; the time from a request being asked to being answered, with and
without a watch; asks a day per watch; approvals followed by Stop within ten seconds; and whether
people with a watch come back on more days than people without.

## 16. Left for Oliver

As of 2026-11-19 (D-410). Nothing below has been done yet:

- **Approve builds**, one at a time: an iOS build that includes the watch targets, and a Wear
  bundle (`scripts/package-wear.sh`).
- **Two downloads on this Mac:** the watchOS simulator runtime and a Wear OS emulator image.
- **Real watches.** An Apple Watch on watchOS 26 or later (a Series 9 or Ultra 2 or later shows
  Double Tap, and one with cellular checks use away from the phone). A Wear OS watch: a Pixel Watch
  2 or later, or a Galaxy Watch.
- **The Apple push key** (`.p8`), its key id and the team id, in production. The widgets plan and
  iPhone call rings need the same one.
- **App IDs and profiles** for `ai.casama.app.watchkitapp` and `ai.casama.app.watchkitapp.widgets`,
  with their app group and keychain group. Xcode registers them on the first signed build.
- **Play Console.** Add the Wear OS form factor (it wants one round screenshot) and opt in to
  review.
- **A production deploy** of the server, which includes migration `20270207100001`.
- **The store listings:** a watch screenshot set for each store, and one line in each description.
- **Store uploads**, only when asked.

Not built, so not on this list yet: a live call on the wrist, Wear Widgets, and refresh pushes from
the server to complications and tiles.

## Sources

- Apple, watchOS 27 compatibility: https://support.apple.com/en-us/108926
- Apple, "Creating independent watchOS apps":
  https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps
- Apple, "Setting up a watchOS project":
  https://developer.apple.com/documentation/watchos-apps/setting-up-a-watchos-project
- Apple, TN3157 "Updating your watchOS project for SwiftUI and WidgetKit":
  https://developer.apple.com/documentation/technotes/tn3157-updating-your-watchos-project-for-swiftui-and-widgetkit
- Apple, TN3135 "Low-level networking on watchOS":
  https://developer.apple.com/documentation/technotes/tn3135-low-level-networking-on-watchos
- Apple, "Keeping your watchOS app's content up to date":
  https://developer.apple.com/documentation/watchos-apps/keeping-your-watchos-app-s-content-up-to-date
- Apple, "Taking advantage of frontmost app state":
  https://developer.apple.com/documentation/watchkit/taking-advantage-of-frontmost-app-state
- Apple, "Taking advantage of notification forwarding":
  https://developer.apple.com/documentation/watchos-apps/taking-advantage-of-notification-forwarding
- Apple, "Enabling and receiving notifications":
  https://developer.apple.com/documentation/watchos-apps/enabling-and-receiving-notifications
- Apple, "Adding actions to notifications on watchOS":
  https://developer.apple.com/documentation/watchos-apps/adding-actions-to-notifications-on-watchos
- Apple, "Enabling Double Tap":
  https://developer.apple.com/documentation/watchos-apps/enabling-double-tap
- Apple, "Authenticating users on Apple Watch":
  https://developer.apple.com/documentation/watchos-apps/authenticating-users-on-apple-watch
- Apple, "Designing your app for the Always On state":
  https://developer.apple.com/documentation/watchos-apps/designing-your-app-for-the-always-on-state
- Apple, "Updating widgets with WidgetKit push notifications":
  https://developer.apple.com/documentation/widgetkit/updating-widgets-with-widgetkit-push-notifications
- Apple, "Widget suggestions in Smart Stacks":
  https://developer.apple.com/documentation/widgetkit/widget-suggestions-in-smart-stacks
- Apple, `WKSupportsLiveActivityLaunchAttributeTypes`:
  https://developer.apple.com/documentation/bundleresources/information-property-list/wksupportsliveactivitylaunchattributetypes
- Apple, Human Interface Guidelines, "Designing for watchOS" and "Live Activities":
  https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos,
  https://developer.apple.com/design/human-interface-guidelines/live-activities
- Apple, WWDC25 "What's new in watchOS 26": https://developer.apple.com/videos/play/wwdc2025/334/
- Apple, WWDC24 "Bring your Live Activity to Apple Watch":
  https://developer.apple.com/videos/play/wwdc2024/10068/
- Apple, WWDC21 "There and back again: Data transfer on Apple Watch":
  https://developer.apple.com/videos/play/wwdc2021/10003/
- Apple, watchOS 27 release notes:
  https://developer.apple.com/documentation/watchos-release-notes/watchos-27-release-notes
- Apple, screenshot specifications:
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Apple, upcoming requirements (64-bit watchOS apps):
  https://developer.apple.com/news/upcoming-requirements/
- Firebase, iOS SDK readme on watchOS support: https://github.com/firebase/firebase-ios-sdk
- Android Developers, Wear OS 7 changes:
  https://developer.android.com/training/wearables/versions/7/changes
- Android Developers, "What's new in Wear OS 7":
  https://developer.android.com/blog/posts/what-s-new-in-wear-os-7
- Android Developers, Wear app quality:
  https://developer.android.com/docs/quality-guidelines/wear-app-quality
- Android Developers, Compose for Wear OS and its releases:
  https://developer.android.com/training/wearables/compose,
  https://developer.android.com/jetpack/androidx/releases/wear-compose
- Android Developers, always-on apps: https://developer.android.com/training/wearables/always-on
- Android Developers, Tiles and Wear Widgets:
  https://developer.android.com/training/wearables/tiles/interactions,
  https://developer.android.com/training/wearables/widgets/migration
- Android Developers, complications:
  https://developer.android.com/training/wearables/complications/exposing-data
- Android Developers, bridging notifications:
  https://developer.android.com/training/wearables/notifications/bridger
- Android Developers, Live Updates on Wear OS and Ongoing Activity:
  https://developer.android.com/training/wearables/notifications/live-updates,
  https://developer.android.com/training/wearables/notifications/ongoing-activity
- Android Developers, the Wearable Data Layer:
  https://developer.android.com/training/wearables/data/overview
- Android Developers, authentication on wearables:
  https://developer.android.com/training/wearables/apps/auth-wear
- Android Developers, standalone apps and network access:
  https://developer.android.com/training/wearables/apps/standalone-apps,
  https://developer.android.com/training/wearables/data/network-access
- Android Developers, voice input and audio on Wear OS:
  https://developer.android.com/training/wearables/user-input/voice,
  https://developer.android.com/training/wearables/apps/audio
- Android Developers, packaging and distributing Wear apps:
  https://developer.android.com/training/wearables/packaging
- Google Play, target API level requirements:
  https://developer.android.com/google/play/requirements/target-sdk
- Google Play Console Help, Wear OS tracks:
  https://support.google.com/googleplay/android-developer/answer/13295490
- Gradle, running a task by name in every project:
  https://docs.gradle.org/current/userguide/command_line_interface.html
- Flutter, issues on watch companions:
  https://github.com/flutter/flutter/issues/135056, https://github.com/flutter/flutter/issues/186606
- pub.dev, `wearable_rotary` (discontinued): https://pub.dev/packages/wearable_rotary
- MacRumors, Meta's Apple Watch app (9 November 2026):
  https://www.macrumors.com/2026/11/09/meta-muse-apple-watch/
- The installed SDKs: the watchOS 27.2 SDK's framework list and interfaces (Xcode 27.2), read for
  which frameworks exist (no `Speech`, no `ActivityKit`) and from which version each API is
  available (`WidgetPushHandler`, `ControlWidget`, `RelevanceConfiguration`, `handGestureShortcut`,
  CallKit, `LAPolicy.deviceOwnerAuthenticationWithWristDetection`, passkeys unavailable).
- The installed Flutter tool: `packages/flutter_tools/lib/src/ios/mac.dart` and
  `xcode_project.dart` in Flutter 3.50.0, for how a watch companion is found and built.
- This repository: the files named in §1, and on the `widgets` branch
  `packages/contracts/src/glance.ts` and `apps/server/src/api/routes/glance.ts`.
