# Live calls that keep going: minimised calls, switching bots, the live view on a call, and the background

Status: **approved, D-327** (2026-11-16). Oliver: "Execute the plan until all phases complete", with
every §11 default.

## Progress

All four phases are built and on `main` (merged 2026-11-16 in 1673516c, pushed 2026-11-17), and the
island (D-324) is merged with the call wired into the Mac notch. Not deployed to production. Native
code is written but not compiled: Flutter builds wait for Oliver's yes. What still needs a build or a device is in
"Left for Oliver" at the end.

- **Phase 1, calls belong to the app: built.** `ActiveCall` and `CallController`
  (`client/lib/features/voice/active_call.dart`), the bubble, the sidebar card and the chat's return
  bar (`call_bubble.dart`), the call screen as a view, one call at a time with the sheet,
  keep-awake (`core/screen_awake.dart` plus a small iOS and Android channel), the wake word paused
  during calls, turns saved as they happen, the heartbeat, `live_calls` and the worker sweep
  (`apps/server/src/billing/live-calls.ts`), context carry-over.
- **Phase 2, the bot's work on the call: built.** `CallController` follows each `start_task` run
  (and tools still running after 12 s) through its run events: the "Working on it" card and the
  job strip stay while it runs, the call doesn't hang up for quiet, and the bot hears a note when
  the job finishes, fails or needs the person, said after a pause. The live-view tile
  (`call_live_tile.dart`, screenshots only) shows while a job works on the computer; tapping it
  swaps to the live view and the bubble swaps back. `stop_task` (server, `routes/voice.ts`) and
  `show_screen` (answered by the app); the recap card at the end of a call (`call_recap.dart`,
  posted by `postCallRecap` in `billing/live-calls.ts`).
- **Phase 3, the background: built (native parts not compiled).** `CallSystem`
  (`client/lib/features/voice/call_system.dart`): an outgoing CallKit call on iPhone through
  flutter_callkit_incoming (the mic and player wait for CallKit's audio session), a microphone
  foreground service with a CallStyle notification on Android (`CallService.kt`,
  `casama/call_service`). Their Mute, End Call, hold and tap drive the call. `CallInterruptions`
  (audio_session): another call, Siri or an alarm puts the call on hold (`VoiceCall.setOnHold`)
  and the bot waits; when the audio comes back the session and route are restored. Unplugged
  headphones switch to the speaker. "On hold" and "Reconnecting" show on the bubble's timer and the
  notification. The web tab's title counts the call.
- **Phase 4, island surfaces: built for what exists on main (native parts not compiled).**
  `CallGlance` (`client/lib/features/voice/call_glance.dart`): what surfaces outside the window
  show (the bot, when it went live, mute, hold, reconnecting, the job and whether it needs you),
  changing only when that changes. iPhone: the call's Live Activity on the lock screen and Dynamic
  Island (`RunActivityWidget` draws `kind: call`), with Mute and End Call buttons that reach the
  call over `casama/call_glance`. Mac: the menu bar (`desktop_shell.dart`) starts with the call's
  line, Mute or Unmute, End Call and Show Call, and its title counts the call. Mac: since the island
  merge (D-324, 2026-11-17) the call shows in the notch and its panel with Mute and End, and the
  tray's call items stay only on Windows and Linux (see "After island merge").

All four phases are built, merged and pushed. Not deployed; no app build has run.

### Calls made while building (Oliver said to decide and note them)

- **Wide screens:** the sidebar card shows wherever the desktop sidebar is (`LayoutSize.desktop`).
  The tablet layout has a narrow rail with no room for a card, so tablets and narrow windows get the
  bubble, like phones. The bubble also shows on a wide window outside the shell (no sidebar on
  screen): the card registers itself, and the bubble steps aside only while a card is mounted.
- **Entry points:** every way into a call still opens `/bots/:botId/call`. The call screen asks
  `ActiveCall` for the call, so deep links, the wake word and rings all get "one call at a time"
  without each needing its own check. Asking about another bot's call happens on that screen.
- **Answering a ring during a call** ends the current call first in `PhoneCalls.answer`. On
  phones the person chose by answering on CallKit or Android's calling screen; on desktop the
  banner's button reads **End and Answer**. No separate in-call ring banner on phones.
- **Turn ids** are `t<index>` within a call; the server keys them by `(live_call_id, turn_id)` in
  a small `live_call_turns` table. The final `/v1/voice/transcript` post carries only the turns not
  yet saved (with their ids), so retried or late posts never double a message.
- **Length billed by the sweep** is up to the last heartbeat (not up to the sweep), with the token
  counts that heartbeat carried; on Casama Cloud the listening-rate floor still applies.
- **A session that started but never connected** now ends its record right away (0 seconds), so
  its Cloud hold is returned instead of kept.
- **Which jobs are followed:** `start_task` runs and tools that answer `running`. The server still
  answers `start_task` with `completed` (older apps unchanged); the app knows it by name.
- **The bot's notes** wait for 1.5 s with nobody speaking (any speech starts the wait again), and
  several notes go together. A job stopped with `stop_task` isn't reported again when its run
  says it was cancelled; one stopped from the chat is.
- **A job's approval** shows Allow and Not now on its own card on the call; the card goes back to
  "Working on it" after the answer (the job carries on or stops by itself).
- **The tile** shows while a followed job has used a computer tool (shell, desktop, computer,
  checkpoint, browser, files: the chat's own test) or woken the computer, after `show_screen`, and
  for 3 s after the job ends ("Done"). It has a close button; a later job on the computer brings it
  back. Its computer is the one the job's events name, else the bot's own (`computerForBot`).
- **The swap** replaces the call screen with the live view in the navigation stack (and back from
  the bubble), so going back from either returns to where the call started, not through a pile of
  pages. `GoRouter.swapTo` in `core/nav.dart`.
- **Wide screens** (900 px and wider) put the screen beside the call, at the left; narrower ones
  get the small corner tile, draggable to any corner.
- **`show_screen`** opens the tile when the call screen is open and the tile hidden; otherwise the
  full live view (pushed over whatever is open when the call is minimised). Old apps get a plain
  answer from the server instead. Calls get `show_screen` only on servers with computers.
- **`stop_task`** stops every job from the call still going, newest first, through the person's
  own session (`request_run_cancel`). A tool result needs a run id, so "nothing to stop" and
  `show_screen` answer with an all-zero id.
- **The recap** is a message in the call's chat with a text part (for older apps and the model's
  history) and a `call` part the app shows as a card instead of the text. It's posted once, by
  whichever ends the call (hang-up or the sweep), for any call that connected or started a job.
  The next call's "Earlier in this conversation" leaves it out.
- **One call system per call**, made by `callSystemProvider` (tests use a fake). Desktop and web
  have none (the Mac's notch and menu bar are Phase 4).
- **An answered ring isn't reported to CallKit again:** CallKit already has it (D-135), so the
  call uses its id for mute, connected and end. This also ends the CallKit call when the live call
  ends, which nothing did before.
- **CallKit's audio session:** the call starts the voice connection only after CallKit says the
  session is active, or after 3 seconds, so a slow CallKit never blocks a call. `record` and
  SoLoud keep configuring the session as before; whether they get along with CallKit is the
  device check (risk table).
- **Hold:** CallKit calls say they support holding, so iOS can offer Hold and Accept for a phone
  call; hold and audio interruptions both put the call on hold. While held, the mic sends nothing,
  the bot's speech is dropped (not played later), its job notes wait, and the idle check waits.
  The bot is told when the hold starts and ends.
- **China:** CallKit is skipped when the device's region is CN (the locale's country), and the
  call runs on background audio alone.
- **Android's first call:** the mic permission is asked as the call connects, after the service
  would start, and Android refuses a mic service without it. The service then starts once the call
  is live, while the app is still in front. Android also asks for audio focus during a call
  (voice-communication usage), so it hears when another app takes the audio. Neither the service
  nor audio focus holds up the call: the voice connection starts alongside them (only CallKit's
  audio session is waited for).
- **Android, an answered ring:** flutter_callkit_incoming keeps its own ongoing-call notification
  after Answer, and nothing ended it. The call's service now ends that one as it starts, so there's
  one notification and it goes with the call.
- **The notification** has its own channel ("Calls", silent). It goes when the call ends, when the
  app is swiped away, and when Flutter's engine goes away (the call lives there). Its words come
  from the app's strings.
- **Network changes** use the existing resume path: a dropped socket resumes with Gemini's handle
  and shows "Reconnecting". No separate network watcher.
- **Phase 4 without the island:** D-324's notch and its menu bar panel are on
  `t3/island-phase-0-feed`, not on main, and its plan puts calls in its Phase 6. So the call side
  is behind its own small pieces (`CallGlance`, `CallGlanceSurface`, `ActiveCall.act`), wired to
  what main has: the Live Activity plugin and the `tray_manager` menu bar. The island takes the
  same glance after its merge.
- **The call's Live Activity alongside CallKit:** CallKit's own call UI already has mute and end,
  but not what the bot is doing; the activity adds the job line, so it shows for every call (also
  in region CN, where it's the only lock screen view). Whether the two together look crowded in
  the Dynamic Island is a device check.
- **One activity per call,** by the call's id. A call shows "Connecting…" under the bot's id
  first, then switches to its server record's id once it has one (one end, one create). It's
  removed if the app is killed (the call ends with the app) and takes no push updates.
- **Live Activity buttons** need iOS 17 (the widget's target already is). They're App Intents
  that run in the widget's process, so they tell the app through a Darwin notification
  (`ai.casama.app.call.<action>`), and `AppDelegate.swift` passes it to Flutter. Tapping the
  activity opens the call screen (`casama://app/bots/<id>/call`).
- **Menu bar:** the call's items go above the usual ones, and the menu is rebuilt when the call
  changes (tray_manager has no item removal); the title ticks once a second ("● Ava 3:12") and
  goes back to the computer-use status after. Its words come from the app's strings ("Show Call"
  is new); the menu's older items stay as they were.
- **Context carry-over** goes into the locked instructions before the greeting, oldest first,
  each turn cut at 600 characters, newest kept within about 2,000 tokens (4 characters a token).

## 0. Summary

Live calls (D-165, D-177, D-234) are stable while the call screen is open. Everything else ends or
breaks the call:

| When the person… | Today | After this plan |
|---|---|---|
| Leaves the call screen (Back, a tab, a link) | The call hangs up, and no transcript is saved | The call shrinks to a bubble (phones) or a sidebar card (wide screens) and carries on |
| Calls a second bot | A second call screen opens; the first call dies when its screen goes | One call at a time: "End call with Ava and call Max?" |
| Watches the bot work on its computer | One "Started" card, then nothing until the chat shows the result | A live-view tile on the call, tap to swap; the bot says when the job is done or needs them |
| Puts the app in the background on iPhone | Probably keeps going, with no controls outside the app and no recovery after an interruption | A CallKit call: green pill, lock screen controls, headset buttons, resumes after interruptions |
| Puts the app in the background on Android | The mic gets silence, so the bot can't hear; the idle check hangs up after 2 minutes | A microphone foreground service with a call notification: mute, end, timer |
| Swipes the app away, or it crashes | Transcript lost; on Cloud the 2-minute hold stays as the charge | Turns saved as they happen; the server ends the call and bills its real length |

The core change: **a call belongs to the app, not to a screen.** The call screen becomes one view
of it, next to the bubble, the sidebar card, the notifications and the notch.

## 1. What exists today

| Piece | Where | Note |
|---|---|---|
| Call screen and the call's whole life | `client/lib/features/voice/call_screen.dart` | Connects in `initState`, hangs up in `dispose` (line 219), saves the transcript only in `_hangUp` |
| Gemini Live client | `client/lib/core/gemini_live.dart` | Mic through `record` (voice-communication source), playback through `flutter_soloud`, resumes on `goAway` |
| Audio routes | `client/lib/core/call_audio.dart` | Speaker, earpiece, headsets via `audio_session`; no interruption handling |
| Tool cards, approvals in the call | `call_activity.dart`, `call_screen.dart` `_decide` | `VoiceCall.tellModel` is used only after an approval |
| Session, tools, transcript, billing | `apps/server/src/api/routes/voice.ts` | `start_task` returns at once; other tools wait up to 12 s; the 2-minute Cloud hold settles only when the app posts the transcript |
| Incoming phone-style calls | `client/lib/features/voice/phone_calls.dart` | `flutter_callkit_incoming` already drives CallKit and Android's calling screen for rings (D-141) |
| Live view | `client/lib/features/computer/live_view_screen.dart` | Has an `embedded` mode, pauses video in the background, falls back to one screenshot a second |
| Background audio | `client/ios/Runner/Info.plist` | `audio`, `voip` background modes are on |
| Android services | `client/android/app/src/main/AndroidManifest.xml` | `FOREGROUND_SERVICE` is declared, but no microphone service exists |
| Island feed, notch, Live Activities, Android live notification | D-324, `docs/ISLAND-AND-MENU-BAR-PLAN.md` | Being built on `t3/island-phase-0-feed`; lists "a voice call in the notch" as Phase 6 |

Other gaps found while reading:

- Nothing keeps the screen awake during a call.
- A new call starts with only a greeting; it doesn't know the conversation's last turns.
- The idle check (2 minutes of quiet) ignores background jobs started on the call.
- It isn't clear whether the wake word keeps listening during a call.

## 2. One call for the whole app

A new `ActiveCall` controller (`client/lib/features/voice/active_call.dart`), held by a Riverpod
provider that stays alive for the app's life. It owns everything `_CallScreenState` owns today:

- the session, the `VoiceCall`, mute, the audio route, captions;
- tool runs and approvals, the idle check;
- the transcript and the started-at time;
- the call's bot and conversation.

`CallScreen` becomes a view that reads `ActiveCall` and sends it commands. `dispose` no longer
hangs up. `ActiveCall.end()` is the only way a call ends: the red button, the bubble, the
notification, CallKit, the idle limit, a failed connection that can't resume, or the server.

`ActiveCall.start(botId, conversationId?, callId?)`:

- no call: starts one and opens the call screen;
- a call with this bot: opens the call screen;
- a call with another bot: asks first (§5).

Every call entry point goes through it: the bot's call button, `/bots/:botId/call` deep links, the
wake word, answering a ring.

## 3. Minimised calls

### Phones (compact width)

- Back, a tab, or opening a link from the call minimises it. A **minimise** button sits in the
  call screen's header too.
- A **bubble** floats above every screen: the bot's call mascot (still pose when Reduce Motion is
  on), a thin ring that pulses with the bot's voice, the timer underneath.
  - Drag it anywhere; it snaps to the nearest side edge and stays clear of the safe areas, the
    keyboard and the bottom bar.
  - Tap: back to the call screen.
  - Long press: a small menu with **Mute** and **End call**.
  - Muted: a mic-off badge. Needs the person (an approval): an amber dot and a light haptic.
  - It remembers which side it sat on.
- It lives in one overlay in `app.dart` above the router, so it survives navigation.
- Screen readers: one button, "Call with Ava, 3 minutes, tap to return", with Mute and End as
  custom actions.

### Wide screens (Mac, web, tablets)

- A **call card** docked at the bottom of the sidebar: mascot, name, timer, mute, end. Click
  opens the call. It never covers content.
- On the Mac the notch also shows the call (§9), once the island ships.
- Decision 1 asks whether wide screens float a bubble instead.

### In the chat while minimised

The chat of the call's conversation shows a thin bar at the top: "On a call with Ava, tap to
return". Typing there still sends an ordinary chat message (later, §10).

## 4. Saving as you go, and the server ending calls

Both fix lost transcripts and the stuck Cloud hold, for every way a call can end.

- **Turns as they happen.** `ActiveCall` posts each finished turn (person or bot) to
  `POST /v1/voice/transcript/turns`. It's idempotent by a client turn id, and failed posts retry
  from a small queue. Hanging up sends only usage and seconds; the existing transcript route
  keeps working for older apps.
- **A call record on the server.** `voice_calls` (or a new `live_calls` table, decision 6) gets
  a row per call: started, last heard from, provider, conversation, ended, billed.
  - The app sends a heartbeat every 30 s while the call is live, with Gemini's usage so far.
  - A worker sweep ends calls with no heartbeat for 2 minutes. It bills the clock time (capped by
    the token's life, as today) and settles the hold.
  - The transcript route marks the call ended, so the sweep skips it.
- This closes D-177's known gap: what a call costs no longer depends on the app reporting it at
  hang-up.

## 5. One call at a time

- Calling a second bot during a call shows a sheet: **"End call with Ava and call Max?"**, with
  **End and call** and **Cancel**. End and call saves the first call (§4), then starts the second.
- Calling the same bot opens the call screen.
- A ring from a bot (D-141) during a call shows a banner with **End and answer** and **Decline**.
  It never switches on its own.
- A phone-number call (Twilio) to someone else isn't an in-app call; this rule doesn't apply.
- **Context carries over.** `POST /v1/voice/session` adds the conversation's last turns (about 20,
  trimmed to a token budget, voice and text) to the session's locked instructions as "Earlier in
  this conversation". Ending one call and coming back later picks up where it left off. This also
  helps every call started from a chat.
- No hold and no two calls at once: two live sessions sharing one mic and speaker is where the
  stability would go (decision 2).

## 6. The live view on a call

### The bot says what's happening

- When `start_task` starts a run, `ActiveCall` follows it through the run events the chat already
  gets (Realtime plus catch-up, D-041).
- When the run finishes, fails, or waits for approval or a takeover, `ActiveCall` calls
  `tellModel` with a short note ("The task finished: …" with the first lines of the reply). The
  bot says it out loud: "Done, it's booked."
- Tools that come back `running` after 12 s are followed the same way.
- The tool card for the job stays while it runs (a "Working" card with the seconds counter),
  instead of folding after 5 s.

### The idle check

A call doesn't hang up for quiet while a job started on it runs or waits for the person. The
2-minute rule starts again when the job ends.

### The tile

- While a job runs on the bot's computer, the call screen shows a **live-view tile**.
  - Phones: a small 16:10 tile in a corner, draggable, snapping to corners.
  - Wide screens: the desktop beside the call, mascot and captions in a column.
- **Tap the tile to swap:** the desktop goes full screen (the live view screen, with takeover),
  and the call shrinks to the bubble. Tapping the bubble swaps back.
- The tile shows the one-a-second screenshots that exist today. WebRTC video starts only when it
  is enlarged, so a call doesn't pay for video nobody is looking at. In the background, nothing
  streams.
- A takeover request ("I need you to sign in") turns the tile amber, and the bot says it.
- The tile hides when the job ends, after a short "Done" state.

### By voice

- **"Stop that"**: a new call tool `stop_task` cancels the job started on this call (the bot's
  approvals still apply).
- **"Show me"**: a call tool `show_screen` opens the tile when it's hidden, or the full live view.

## 7. The app in the background

The call carries on like a normal phone call, with controls outside the app.

### Android

- A **microphone foreground service** (`foregroundServiceType="microphone"`, with
  `FOREGROUND_SERVICE_MICROPHONE`) starts when the call goes live, before the app can leave the
  screen. Android 14 and later require the type, and Android lets a service start using the mic
  only while the app is in front. So it starts with the call, not on backgrounding.
- An **ongoing call notification** in `CallStyle`: the bot's avatar, its name, the timer, **Mute**
  and **End call**. Tapping it opens the call screen. On Android 16 it shows the status bar call
  chip.
- This is the same notification channel D-324's Android work builds. The call takes priority over
  run updates while it lasts.
- Built with a small Kotlin service in `client/android` (no new plugin): a foreground service
  that holds the notification, and a method channel for state and buttons.

### iPhone

- **Report the call to CallKit** as an outgoing call when it starts (`flutter_callkit_incoming`
  already has `startCall`, `setCallConnected`, `endCall`). That gives the green pill, the lock
  screen call UI, headset and AirPods buttons, and lets iOS treat the call as a call. Mute in
  CallKit mutes the call; end ends it.
  - CallKit owns the audio session once it is active. The mic and SoLoud start after CallKit
    activates the session. The one-device check is CallKit with `record` and `flutter_soloud`
    (decision 4).
  - CallKit is unavailable in mainland China; there the call keeps background audio only, without
    the system call UI.
- The **Live Activity** (D-324) shows the call: mascot, timer, what the bot is doing, mute and
  end as App Intents.

### Both

- **Interruptions:** a cellular call, FaceTime, Siri or an alarm takes the audio. `ActiveCall`
  mutes the mic, pauses playback, and tells the bot ("They got another call; wait quietly").
  When the interruption ends, it restores the audio session and the route and picks up again.
  If the connection dropped meanwhile, it resumes with the session handle as on `goAway`.
- **Headphones unplugged:** switch to the speaker as the system does, without stopping.
- **Network changes:** Wi-Fi to cellular resumes with the handle, the same path as `goAway`. A
  short "Reconnecting" state shows on the bubble and the notification.
- **Screen stays awake** while the call screen is open and in front, never in the background.
- **Swiped away:** the call ends. Turns are already saved (§4), and the server bills it (§4).
- **The wake word** stops listening during a call and starts again after it.

### Web

- A hidden browser tab keeps its audio and WebSocket. The tab title shows "On a call · 3:12". No
  more than that is needed.

## 8. The call screen, small changes

- A **minimise** button in the header (phones), and Back minimises.
- A **job strip** under the name while a job runs: "Working on: book the flight · 0:42", tap for
  the live view.
- **After hang-up:** the chat shows a recap card: length, what was started on the call, links to
  the runs.

## 9. The Mac notch and menu bar

D-324 lists "a voice call in the notch" as its Phase 6. This plan brings it forward, using the
island's notch and menu bar once they exist:

- Closed notch: the mascot on the left, a live level meter on the right, the timer.
- Open notch: name, mute, end, and the job the bot is on.
- Menu bar panel: the same, at the top of the list.
- Closing the window during a call keeps the call (D-324 already keeps Casama running).

## 10. Later (each gets its own short plan)

- **Type into the call:** with a call minimised, the chat's composer sends text, links and photos
  into the call (Gemini Live `clientContent`), not into a separate run.
- **Show the bot something:** camera or screen into the call (Gemini Live takes video, at a
  higher cost; needs pricing first).
- **Move a call to another device:** continue the same conversation on another device with the
  context carry-over from §5. A true handover of the live session isn't possible with single-use
  tokens.
- **Group calls:** a second bot joins the same call.
- **Floating outside the app:** Android picture-in-picture, a small always-on-top Mac window, a
  document picture-in-picture window on web.

## 11. Decisions (each with a default)

| # | Question | Default |
|---|---|---|
| 1 | Wide screens: sidebar card or a floating bubble like phones? | **Sidebar card** (never covers content); notch on the Mac |
| 2 | A second call: end and switch, or put the first on hold? | **End and switch**, with the "End and call" sheet; no hold |
| 3 | How much earlier conversation does a new call get? | **Last 20 turns**, trimmed to about 2,000 tokens |
| 4 | iPhone: CallKit for every call? | **Yes**, except where CallKit isn't allowed (mainland China) |
| 5 | Live-view tile: screenshots small, video only when enlarged? | **Yes** |
| 6 | Server call record: extend `voice_calls` or a new table? | **New `live_calls` table** (`voice_calls` is phone-number calls) |
| 7 | Idle limit while a job runs | **Paused** until the job ends |
| 8 | The bot speaks up when a job finishes, even mid-sentence from the person? | **Waits for a pause**, then speaks |

## 12. Phases

Each phase is usable alone and ends with a real-device check. Flutter builds and production
deploys still need Oliver's yes each time.

| Phase | What | Device check |
|---|---|---|
| **1. Calls belong to the app** | `ActiveCall`; Back minimises; the bubble and the sidebar card; the call screen as a view; one call at a time with the sheet; keep-awake; wake word paused during calls; turns saved as they happen; heartbeat, `live_calls` and the server sweep; context carry-over | A call keeps going across tabs and chats on a phone and the Mac; killing the app keeps the transcript and bills the real length |
| **2. The bot's work on the call** | Following `start_task` and `running` tools; the bot speaks up; idle paused during jobs; the live-view tile with swap; job strip; `stop_task`, `show_screen`; recap card | Ask for a web task on a call: watch it in the tile, swap, hear "done" |
| **3. The background** | Android microphone service and call notification; iPhone CallKit for outgoing calls; interruptions, network changes, unplugged headphones | Lock the phone mid-call on both platforms and keep talking; take a real phone call mid-call and come back |
| **4. Island surfaces** | The call in the iPhone Live Activity and the Mac notch and menu bar, on D-324's feed | A call on the lock screen and the Mac notch with mute and end working |
| **5. Later** | §10 | Each its own plan |

Phase 4 depends on the island track (`t3/island-phase-0-feed`) reaching its Live Activity and notch
phases; Phases 1 to 3 don't.

## 13. Tests

- Widget: the call survives leaving the screen; the bubble's tap, drag, snap, long press; the
  "End and call" sheet; one call at a time; the idle check paused during a job; the tile swap.
- `ActiveCall` unit tests with the existing fake socket (`gemini_live_test.dart`): turns posted
  once each with retries; interruptions mute and resume; a dropped connection resumes with the
  handle; ending from every source cleans up.
- API: turn posts are idempotent; the heartbeat; the sweep ends silent calls and settles the hold
  once; context carry-over is in the locked instructions; `stop_task` respects ownership.
- pgTAP for `live_calls` RLS (with `allow_worker`).
- Native code is checked on devices (each phase's check): no automated test covers CallKit or the
  Android service.

## 14. Risks

| Risk | Answer |
|---|---|
| CallKit and `record`/SoLoud fighting over the audio session on iPhone | Start the mic and player only after CallKit's `didActivate`; tested first in Phase 3 |
| Android OEMs killing foreground services | `CallStyle` plus the microphone type is the most protected kind; the server sweep bills correctly if it dies anyway |
| A bubble over every screen getting in the way | Snaps to edges, avoids keyboards and bars, hides during full-screen video and the live view |
| The bot interrupting the person to report a job | It waits for a pause (decision 8) |
| Longer instructions from context carry-over cost more per call | A token budget (decision 3); measured in Phase 1 |
| Tiles streaming video nobody watches | Screenshots until enlarged; nothing in the background |

## Left for Oliver

Each item needs a build (Oliver's yes first) or a real device. Nothing here was compiled or run.

### Phase 1

- **Screen stays on during a call (iOS, Android).** `casama/screen_awake` in
  `client/ios/Runner/AppDelegate.swift` (`isIdleTimerDisabled`) and
  `client/android/.../MainActivity.kt` (`FLAG_KEEP_SCREEN_ON`). Build: `flutter build ios` and
  `flutter build apk --debug`. Check: start a call, leave the phone untouched past its auto-lock
  time; the screen stays on. Minimise the call; the screen locks as usual.
- **Device check from §12:** a call keeps going across tabs and chats on a phone and on the Mac
  (bubble on the phone, sidebar card on the Mac); swipe the app away mid-call and, about 2 minutes
  later, the call's turns are in the chat and Usage shows its real length.

### Phase 2

- **Device check from §12:** on a phone, ask the bot on a call for a web task ("find a flight to
  Cebu on Friday"). The "Working on it" card and the strip under the name stay while it runs; the
  tile shows the browser; tap it for the full live view and the call shrinks to the bubble; tap the
  bubble to come back; when it's done the bot says so without cutting you off. Say "stop that"
  during a second task and check it stops. Hang up: the chat ends with the recap card, and its rows
  open the runs. Repeat on the Mac (the screen beside the call). No native code in this phase.
- **Production deploy** for the server half (`stop_task`, `show_screen`, the recap, the new call
  instructions). Older apps keep working: they never send `show_screen` without being told it
  can't show, and the recap's text shows for them.

### Phase 3

None of this was compiled. Each needs a build (ask first) and a real device.

- **Android microphone service and call notification.** `CallService.kt`, `CallBridge` and the
  `casama/call_service` channel in `MainActivity.kt`; `FOREGROUND_SERVICE_MICROPHONE` and the
  service in `AndroidManifest.xml`; `androidx.core:core-ktx:1.13.1` in `build.gradle.kts` (for
  `NotificationCompat.CallStyle`). Build: `flutter build apk --debug`. Check on Android 14 or later:
  start a call, lock the phone, keep talking for two minutes; the notification shows the bot, the
  timer, **Mute** and **End Call**; both buttons work; tapping it opens the call screen; on Android
  16 the status bar shows the call chip. Swipe the app away: the notification goes. First call on a
  fresh install (mic permission asked during the call): the notification still appears once the
  call is live. Answer a ring from a bot (D-135): one call notification, not two.
- **iPhone outgoing CallKit call.** `CallKitCallSystem` (no new Swift: flutter_callkit_incoming's
  `startCall`, `setCallConnected`, `muteCall`, `endCall`). Build: `flutter build ios`. Check: start
  a call; the green pill and the lock screen call UI show; lock the phone and keep talking; mute
  from the lock screen mutes the call and the app agrees; AirPods' press mutes or ends as iOS
  decides; end from the lock screen ends the call and saves it. Watch for audio: the mic and the
  bot's voice both work after CallKit starts (the `record`/SoLoud/CallKit audio session risk). An
  answered ring (D-135) ends its CallKit call when you hang up.
- **Interruptions.** Both platforms: take a real phone call mid-call (Hold and Accept on iPhone),
  then come back: the bot waited and carries on, the audio route is the one you had. Trigger Siri
  and an alarm the same way. Unplug wired headphones mid-call: the call moves to the speaker.
- **Network change.** Walk out of Wi-Fi mid-call: "Reconnecting" shows on the bubble and the
  notification, and the call resumes.
- **Mainland China (region CN):** the call runs without the CallKit UI and keeps going with the
  screen locked (background audio).
- **Web:** start a call on app.casama.ai and switch tabs; the tab's title reads "On a call · 3:12"
  and the call keeps going; it returns to "Casama" after hanging up.

### Phase 4

None of this was compiled (the widget file and the AppDelegate bridge were only type-checked on
their own). Each needs a build (ask first) and a device.

- **iPhone Live Activity for calls.** `RunActivityWidget`'s call branch, `CallActivityView`,
  `callIsland` and `CallActionIntent` in `client/ios/CasamaWidgets/CasamaWidgets.swift`;
  `CallGlanceBridge` and the `casama/call_glance` channel in `client/ios/Runner/AppDelegate.swift`.
  Build: `flutter build ios`. Check on an iPhone with a Dynamic Island, iOS 17 or later: start a
  call; the lock screen shows the bot, the timer counting, "On a call"; ask for a task and the line
  becomes "Working on: …"; **Mute** on the lock screen mutes the call (the app and CallKit agree,
  the button turns to Unmute); **End Call** ends and saves it, and the activity goes. Long-press
  the Dynamic Island for the expanded view with the same buttons. Tap the activity: the call
  screen opens. Kill the app mid-call: the activity goes. Check that a bot's run activity
  still looks as before. Judge whether CallKit's pill plus the activity is too much in
  the Dynamic Island; if so, show the activity only while a job runs.
- **Mac notch during a call** (replaces the menu bar items on the Mac since the island merge):
  `island_call.dart`, `island_bridge.dart`, `Island.swift`. Check: closed and open notch show the
  call, Mute and End work, a click on the call row opens the call screen.
  Build: `flutter build macos`.
- **Windows and Linux tray during a call.** `desktop_shell.dart` (Dart only, through tray_manager).
  Build: `flutter build windows` or `flutter build linux`. Check: start a call; the tray menu starts
  with "Ava · On a call", **Mute**, **End Call**, **Show Call**; each works.
- **Device check from §12:** a call on the lock screen and in the Mac's notch, with mute and end
  working from both.

### After island merge (D-324): done 2026-11-17

The original steps, kept for reference (the merge did it differently, see the note below):

- Add `'call': ref.watch(callGlanceProvider)?.toJson(l10n)` to `islandStateProvider` in
  `client/lib/features/island/island_bridge.dart`, and in `IslandBridge._action` pass `mute`,
  `unmute`, `end_call` and `open_call` to `ref.read(activeCallProvider).act(...)`.
- In `client/macos/Runner/Island.swift`: closed notch with the mascot, a level or the timer
  (counting from `since`); open notch and the panel's top row with the bot, `status`, Mute or
  Unmute and End Call (§9). Labels from the app's strings, sent with the island's labels.
- Drop the call items from `desktop_shell.dart` once the island's own status item replaces the
  tray, so the Mac shows the call once.
- On iPhone, if the island moves the run activity into its own feed, keep the call's branch in the
  widget (or move it to the island's widget) and keep `LiveActivityCallGlance` as the one writer
  for calls.
- Device check: a call in the Mac notch, closed and open, with mute and end working.

Done in the merge (2026-11-17), with the island's own wiring instead of the steps above:
`followActiveCall` (`island_call.dart`) reports the live call to `islandCallProvider`, whose
controls call the `CallController`'s mute and end; a click on the call row sends `call_open`, which
runs `ActiveCall.act(open)`. The Mac doesn't start the tray, so the call shows once (notch and
panel); Windows and Linux keep the call items above the island feed in the tray. The iPhone widget
keeps the call branch as `CallActivityWidget`, still written only by `LiveActivityCallGlance`. The
device check is still open.
