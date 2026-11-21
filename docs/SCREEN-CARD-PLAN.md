# The bot's screen in a floating card: plan

Status: **not started** (written 2026-11-21). Waiting on Oliver's answers in §11 and his go-ahead.
No code yet.

Line numbers are from 2026-11-21. Re-find each one before editing.

## 0. Summary

While a bot works on its computer's screen, a small card floats in the top right of its chat on a
phone and shows that screen, live. It appears on its own when there is something to watch, and
goes away on its own when there isn't. A tap opens the full live view that exists today.

Three choices shape the plan. Each is a decision in §11.

| | Choice | Why |
|---|---|---|
| What plays in the small card | Fast pictures (about one a second), not video. Video starts after the tap | Most bot computers have no video to play, and video would use about 1 GB of mobile data an hour for something the person didn't ask for (§7) |
| When it shows | Only for screen work (the bot's browser or desktop), never for terminal or file work | Terminal and file steps have nothing to look at; the "working" line already covers them |
| What it is for | A glance. Nothing is controlled from the card | At 140 points wide a desktop can't be read or tapped precisely; the full view is one tap away |

Most of the parts exist: the call screen already has this card (`CallLiveTile`), the chat already
knows when the bot is on its computer, and the full live view is built. The new work is the
rules for showing it, a lighter picture from the server, and the card's states.

## 1. What exists today

Checked in the code on 2026-11-21.

- **A monitor button with a live dot in the chat header**, on phones and tablets, only while the bot
  works on its computer (`chat_screen.dart:1359`, `_LiveDot`). It opens the Computer screen. The
  signal behind it is `_computerInUse` (`chat_screen.dart:2931`): the running reply has used a
  terminal, desktop, browser, file or checkpoint tool since the person's last message.
- **The same card, on a call** (D-327): `CallLiveTile` and `CallTileCorner`
  (`client/lib/features/voice/call_live_tile.dart`). 140 points wide, 16:10, in the top right,
  dragged to any corner. It plays screenshots once a second, turns amber when the bot needs the
  person, says "Done" briefly, has a close button, and opens the live view on a tap. It fetches
  nothing while the app is in the background.
- **The full live view** (`LiveViewScreen`, D-219): video over WebRTC through a relay, Take Control
  and Hand Back, and a fall back to screenshots when video can't get through.
- **Desktop** has the computer side panel beside the chat; **two panes** (folding phones, D-411)
  have a computer pane. Neither needs a card.
- **Outside the app**, the Live Activity, Dynamic Island and notch (D-324) show what a bot is
  doing, in words.

Three facts about the server limit the design:

1. **Video needs a desktop computer.** `POST /v1/computers/{id}/stream-session` answers 409
   `no_desktop` for any other (`live.ts:205`), and new computers are **headless** by default
   (`computers.profile` defaults to `headless`). A headless bot's "screen" is its browser page,
   captured by running `agent-browser screenshot` on the computer (`computers.ts:437`).
2. **A screenshot is a full-size PNG**, and nothing says whether it changed since the last one.
3. **Asking for a screenshot wakes the computer** and counts as activity: the route goes through
   `handle()`, which runs `ensureRunning` (`computers.ts:186`). A card that kept asking after the
   bot finished would keep the computer awake, against D-195.

## 2. Principles

1. **It earns its place each time.** The card covers part of the chat, so it shows only when
   there is a moving picture worth a glance, and never as an empty or frozen box.
2. **It never costs the person anything they didn't choose.** No video on mobile data, no waking
   a computer, no keeping one awake.
3. **One tap to the real thing, one tap to be rid of it.**
4. **It doesn't repeat the chat.** The working line says what the bot is doing in words; the card
   shows it. No step text on the card.
5. **Same access as the live view.** Whoever may open the live view may see the card. Nothing new
   is exposed.

## 3. The card

```
┌──────────────────────────────┐
│ ‹  (o) Ava            ▢• ☎ ✎ ⋯ │  header; the monitor button keeps its dot
│ General · Trip · Taxes         │  topic chips
│                  ┌───────────┐ │
│  Looking at      │● ░░░░░░ ✕ │ │  the card: 12 pt under the chips,
│  flights now.    │  ░░░░░░░  │ │  12 pt from the edge
│                  └───────────┘ │
│        Find me a flight to ▐   │
│  ▌ Browsing skyscanner.com…    │  the working line stays as it is
│ ┌────────────────────────────┐ │
│ │ Message                  ↑ │ │
│ └────────────────────────────┘ │
└──────────────────────────────┘
```

- **Size:** 38% of the screen's width, between 132 and 168 points on phones; 220 on tablets. The
  shape follows the picture (16:10 for a desktop, 16:9 for a browser page).
- **Look:** the app's card: 14-point corners, a hairline border, a soft shadow so it reads as
  floating. Same in light and dark, since the picture inside is the computer's own.
- **On it:** a small still dot in the top left (green while live), a close button in the top right,
  and a short label in the bottom left only when the state isn't plain watching (§5). In a group
  chat, the working bot's face sits in the bottom left instead.
- **Place:** top right by default. Bot text is on the left and the newest text is at the bottom,
  so the top right is the part of the thread a person reads least while the bot works.
- **It keeps clear of:** the header and topic chips, the composer, the "newest" button, and the
  minimised call bubble (when both sit on the same side, the card goes under the bubble).
- **Motion:** it grows out of the header's monitor button and folds back into it, so a person
  learns where the screen lives when the card is gone. When the reply ends, the card and the
  button's dot go together. With Reduce Motion on, it fades.
- **The first time ever**, one line shows under it for four seconds: "Ava's screen. Tap to watch,
  drag to move."

## 4. When it shows, and when it goes

It shows when **all** of these are true:

- The person is in that bot's chat, on a phone or tablet layout (not desktop, and not two panes
  with the computer pane open).
- The reply in progress is using the **screen**: a `browser.*` or `desktop.*` step, or a request
  for the person to take over. Terminal, file and checkpoint steps don't count.
- It is more than a single look: the second screen step of the reply has started, or one screen
  step has run for more than two seconds. A bot that reads one page and answers shows no card.
- The first picture has arrived. No picture (a sleeping computer, an empty browser tab, no
  access), no card.
- The person hasn't closed it for this reply, the setting is on (§6), and the live view isn't
  already open.

It goes when:

| What happened | What the card does |
|---|---|
| The reply finished | Says "Done" for three seconds, then folds away |
| The reply failed or was stopped | Folds away at once |
| The bot moved on to other work (no screen step for 20 seconds) | Folds away; comes straight back at the next screen step |
| No new picture for 8 seconds | Dims slightly. After 20 seconds it folds away |
| The person left the chat or the app | Stops asking for pictures at once |
| The person closed it | Gone for the rest of this reply; back with the next one |

Once shown it stays at least six seconds, so it never blinks on and off. A takeover request
shows the card at once, without waiting for the second step.

All the timings are starting values, tuned in Phase 0 on a real phone.

## 5. States

| State | When | Card |
|---|---|---|
| **Watching** | The bot is driving the screen | Picture, green dot, no label |
| **Needs you** | The bot asked the person to take over (a sign-in, a CAPTCHA) | Amber border, "Needs you" label, one light haptic, one pulse. A tap opens the live view on that request |
| **You have the screen** | The person (or a teammate) is in control | Picture paused and dimmed, "You have the screen" or "Mia has the screen" |
| **Done** | The reply finished | Last picture, "Done", three seconds |
| **Stale** | No new picture for 8 seconds | Dimmed, small spinner |

The takeover prompt in the chat stays as it is. The amber card is a second signal that still
shows when the person has scrolled up.

## 6. What you can do with it

- **Tap:** opens the full live view (`/computer/live`), where video and Take Control are. The
  card grows into it, and shrinks back on return.
- **Drag:** moves it. On release it snaps to the nearest corner, and the app remembers the corner
  on this device.
- **Close (✕):** hides it for this reply. The header's monitor button and its dot stay.
- **Long press:** Open full screen · Hide for now · Don't show automatically.
- **Setting:** "Show the bot's screen while it works", on by default, beside "Show bot steps"
  (`settings_screen.dart:332`). Kept on the device.
- **After closing it on three replies in a row**, one toast offers to turn it off, with where to
  turn it back on.

Nothing is typed or clicked through the card. Control stays in the full view, where the lease,
the privacy note and Hand Back already are.

**Screen readers:** the card is one button, "Ava's screen, live. Double tap to open." Pictures
are never announced. Only a change to Needs you is.

## 7. What it plays

| | Fast pictures (recommended) | Video in the card |
|---|---|---|
| Works on headless computers (the default) | Yes | No |
| Mobile data in an hour of watching | Tens of MB (to measure) | About 0.7–1.4 GB (the estimate in `docs/COSTS.md`) |
| Starts | With the next picture | After the streamer starts and WebRTC connects, a few seconds |
| Phone battery | An image decode a second | A video decoder running the whole time |
| Looks smooth | No: about one frame a second | Yes |

A bot acts every few seconds, and the card is 140 points wide, so one frame a second reads as
live. The call screen already made this choice (D-327: "screenshots small, video when enlarged").

Today's screenshot is too heavy to fetch every second on a phone, so Phase 1 adds a lighter one
(§8): a small JPEG, sent only when the screen changed, that never wakes the computer.

**On a slow connection** the card slows down by itself: it waits for each picture before asking
for the next, and never asks more often than twice the time the last one took.

**Later, if pictures aren't smooth enough (Phase 3):**

- *Headless computers:* `agent-browser` can stream its page over a WebSocket as small JPEG frames
  (its docs give about 9 KB a frame at 640×360). It listens on the computer's own `127.0.0.1`
  only, so computerd would relay it. This would also improve the Computer screen, which shows a
  headless bot's page every five seconds today.
- *Desktop computers:* view-only video in the card, on Wi-Fi.

## 8. How it's built

**Server (small):** `GET /v1/computers/{id}/screenshot` gains optional parts. Old apps send none
and see no change.

- `width` and `format=jpeg`: resized with `sharp`, which the server already has.
- `If-None-Match`: answers 304 when the screen is the same as last time.
- `wake=false`: a sleeping computer answers 409 and is neither woken nor counted as used.
- One capture a second per computer is shared by everyone watching it.

No migration, no new paid service, no computer image change in Phases 1 and 2.

**App:**

- `client/lib/ui/screen_tile.dart`: the tile and its corner snapping, moved out of
  `call_live_tile.dart` so the call and the chat use the same one.
- `client/lib/features/chat/widgets/screen_card.dart`: the rules in §4 and the states in §5,
  placed in the chat body's stack.
- `chat_controller.dart`: the chat state records when the reply's screen steps started and
  ended (tool entries carry no time today).
- The setting, the strings, and three analytics events in the catalog: `screen_card_shown`,
  `screen_card_opened`, `screen_card_hidden` (with how: close, menu or setting).

**Tests:** widget tests for every row of §4 with a fake clock, the states, corner snapping and
the call bubble; server tests for the new parts of the route (no wake, 304, resize); the call
screen's existing tile tests still pass on the shared tile.

## 9. Not in this plan

- **The system's own Picture in Picture** (the card outside the app). `flutter_webrtc` 1.6.3 has
  no Picture in Picture; it is an open pull request (#2163). On Android the whole app window
  shrinks, not one card, and Android asks for video only. Headless computers have no video at
  all. Outside the app, the Live Activity (D-324) is the surface.
- **The card on other screens** (following the person around the app, like the call bubble).
- **Desktop layout.** The side panel does this job.
- **The person's own Mac's screen** when a bot works there. D-216 left a live view of a personal
  computer for its own decision (its own approval and a "being watched" sign).
- **Control, sound or recording from the card.**

## 10. Phases

| Phase | What | Done when |
|---|---|---|
| **0. Measure and try** | Measure today's screenshot on a desktop and a headless computer: size, time, load on the computer at one a second, and whether it slows the bot's own browser. Build the card behind a debug flag (`?previewScreenCard=1`, as `?previewActing=1` does) with sample pictures | The numbers are in this plan, and Oliver has tried sizes and corners on his phone (needs his yes for a Flutter run) |
| **1. The card** | The lighter screenshot, the shared tile, the show and hide rules, tap, drag, close, the setting, analytics | A bot browsing in a chat on a phone shows the card by the rules in §4; the tests in §8 pass; the computer still sleeps on time after the reply |
| **2. States and polish** | Needs you, You have the screen, Done, Stale; the grow and fold motion; the first-time line; group chats; tablets; the call bubble; Reduce Motion and screen readers; the three-closes toast | Each state checked in light and dark on a phone and a tablet |
| **3. Smoother (optional)** | The headless page stream, or video in the card on Wi-Fi | Decided from the Phase 0 numbers and the analytics; its own short plan if it goes ahead |

Phases 1 and 2 need a server deploy and app builds to reach people. Each needs Oliver's yes.

## 11. Decisions for Oliver

| # | Question | Default |
|---|---|---|
| 1 | What plays in the small card? | Fast pictures. Video only after the tap |
| 2 | What counts as "necessary"? | Screen work only (browser and desktop steps, and takeover requests), from the second step |
| 3 | What does a tap do? | Opens the full live view. No middle size |
| 4 | On by default? | Yes, with the setting to turn it off |
| 5 | Where does it show? | Only in that bot's chat, on phones and tablets |
| 6 | Slower pictures on mobile data? | No new package: it slows down by itself on slow connections. The other choice adds `connectivity_plus` to halve the rate on mobile data |
| 7 | The person's own Mac's screen? | Not in this plan |
| 8 | Phase 3? | Decide after Phase 0 and the first weeks of analytics |

## 12. Risks

- **It annoys more than it helps.** It covers the person's own messages in the top right. The
  close button, the setting and the three-closes toast are the answer, and `screen_card_hidden`
  against `screen_card_opened` says whether the default should flip.
- **Pictures load the computer.** On a headless computer each picture is a command run beside the
  bot's own browser commands. Phase 0 measures it; the shared one-a-second capture caps it.
- **A shared team computer** shows whichever reply holds its screen (`computer_screen_leases`).
  The live view has the same property today; the card adds no new access, but it shows without
  being asked for. If Phase 0 finds a case where it shows another chat's work, the card waits for
  this reply's own screen step to finish before its first picture.
- **Places** (`docs/COMPUTER-PLACES-PLAN.md`, not started) lets a bot work on two computers in one
  chat. The card then follows the place of the latest screen step, and shows only for the bot's
  own computer.

## Sources

Checked 2026-11-21.

- agent-browser, Streaming: <https://agent-browser.dev/streaming> (WebSocket on 127.0.0.1, base64
  JPEG frames, quality and size settings, frame sizes). The pinned version is 0.43.0
  (`infra/images/computer/Dockerfile.headless:14`).
- flutter_webrtc changelog: <https://pub.dev/packages/flutter_webrtc/changelog> (nothing on
  Picture in Picture up to 1.6.3), and pull request #2163 in its issue list:
  <https://github.com/flutter-webrtc/flutter-webrtc/issues?q=picture+in+picture>.
- Android, Picture in Picture: <https://developer.android.com/develop/ui/views/picture-in-picture>
  ("only the top activity enters picture-in-picture"; meant for video).
- Apple's Picture in Picture page could not be read (it loads its text with scripts), so nothing
  here rests on it.
