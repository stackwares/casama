# After a call: the call card: plan

Status: **built** (2026-11-19, D-428). Oliver left every §10 choice to the defaults ("you decide all for me").

Oliver, 2026-11-19: "after a call we only see a chat bubble with the duration of the call. What
could we improve here? … make it the best it can be."

Builds on D-327 (calls that survive the app, the recap card in §8 of `docs/CALLS-PLAN.md`) and
D-423 (the bot hangs up). Take the next free D-number when the first phase lands (D-423 was the
newest on 2026-11-19; check `docs/DECISIONS.md` and the other branches first).

## 0. Summary

Today a call ends in a card that says **"Call ended · 3:12"**, plus a list of jobs only when
`start_task` ran. The call's turns are saved as ordinary chat bubbles above it, with nothing to
show they came from a call. And the last thing said before hanging up is often lost (§1.2).

The goal: **the card becomes the call.** One card in the chat holds the whole call: what it was
about, what was decided, what the bot did, what's left to do (one tap each), the transcript
behind a fold, and a way to call back. You can glance at it a week later and know what happened
without replaying a single bubble.

```
┌─────────────────────────────────────────────┐
│ (phone)  Voice call · 4:12           2:41 PM │
│                                             │
│ Planned Friday's Cebu trip: flights on the  │  summary, 1 to 3 sentences
│ 7 AM PAL, dinner at Abaca for four.         │
│                                             │
│ NEXT STEPS                                  │
│ ○ Text Ana the hotel address       [Do it]  │  tap: starts a chat run
│ ○ Remind you Thursday at 6 PM      [Do it]  │
│                                             │
│ DONE ON THE CALL                            │
│ ✓ Looked up flights to Cebu                 │  quick tools (web, memory, routines…)
│ ✓ Remembered: you like aisle seats          │
│ ⟳ Booking dinner at Abaca        Open  ›    │  start_task jobs (exists today)
│                                             │
│ ▸ Transcript · 18 turns                     │  the call's bubbles, folded in here
│                                             │
│ [ (phone) Call back ]   [ Copy ]   [ ⋯ ]    │
└─────────────────────────────────────────────┘
```

Five phases (§9): fix the lost words first, then fold the transcript in, then the summary and
next steps, then a card that is live while the call is on, then polish.

## 1. What exists today

### 1.1 The pieces

| Piece | Where | What it does |
|---|---|---|
| Turns saved as they happen | `client/lib/features/voice/active_call.dart` (`_onTranscript`, `TurnSaver`) → `POST /v1/voice/transcript/turns` → `saveTurns` in `apps/server/src/api/routes/voice.ts` | Each finished turn becomes a `messages` row, text part `{type:"text", text, voice:true}`, and gets a row in `live_call_turns` (id → message) |
| Turn splitting | `client/lib/core/gemini_live.dart` `GeminiLiveEvents.handle` | Gemini's input and output transcription goes into two buffers; a turn is saved at the bot's first audio (the person's words) and at `turnComplete` / `interrupted` (both) |
| The recap | `postCallRecap` in `apps/server/src/billing/live-calls.ts` | Posted once by whatever ends the call (hang-up or the worker sweep): a text part "Call ended · 3:12 / Started on the call: …" for older apps, and a `call` part `{live_call_id, seconds, tasks[]}` |
| The card | `client/lib/features/voice/call_recap.dart` `CallRecapCard`, parsed by `MessageCall.fromContent` in `client/lib/core/backend.dart` | Phone icon + "Call ended · 3:12", then the `start_task` jobs with their status and a link to each run |
| Quick tools on a call | `voiceTool` in `voice.ts` | `memory.write`, `web.search`, `routines.create`, `tasks.create`, `device.read`… each becomes a `runs` row with `trigger='voice'` and `voice_call = {name, arguments, result}`. **None of them show anywhere after the call** |
| Live updates in a chat | `Backend.watchConversation` (`ConversationActivity.message`) | Already tells an open chat that one message changed; the summary arriving can use it |
| Background model calls | `backgroundComplete` in `packages/agent/src/run.ts` | One call on the bot's background (small) model, billed in `usage_ledger` with `meta.purpose`, counted toward the daily budget (starters D-338, media safety D-419) |

### 1.2 Bug: the last words of a call are lost

`GeminiLiveCall.hangUp()` closes the socket without saving what is still in the two buffers. A
turn is only saved at the bot's first audio or at `turnComplete`, so anything said in the middle
of a turn at hang-up is dropped:

- the person says "great, thanks, bye" and taps the red button → their words are lost;
- the bot is mid-sentence when the person hangs up → the bot's partial reply is lost;
- the call drops for good (`CallState.failed`) → the same.

Production data (2026-11-17 to 19) fits this: calls of 20, 34 and 40 seconds each saved only
the bot's greeting (`t0`). A reconnect keeps the same buffers (`_ev` lives on the call object),
so only the end of a call loses words.

### 1.3 What feels wrong

1. **Duration is the least interesting fact about a call.** It's the only thing the card shows.
2. **The transcript is noise in the timeline.** A 2-minute call adds 30 short bubbles. Scrolling
   back past a call is tiring, and nothing marks where it started or ended.
3. **What the bot did is invisible.** It searched, remembered something and made a reminder; the
   card says nothing unless a `start_task` job ran.
4. **No way forward.** No "call back", no "keep going in chat", nothing to act on.
5. **The conversation list says "Call ended · 3:12"** as the chat's last line.
6. **Failed or missed calls leave nothing,** or just the bot's greeting with no explanation.

## 2. Principles

1. **One call, one card.** Everything a call made lives in its card. The timeline shows a call as
   one item, the way a messaging app shows a photo album.
2. **Outcome first, process last.** Summary → next steps → what was done → transcript. Duration
   moves to the header, small.
3. **Nothing waits on the summary.** The card is complete and useful the moment the call ends.
   The summary fades in when it's ready (usually 1 to 3 s) and is skipped when it can't be made.
4. **Every row does something.** A job opens its run, a next step starts on a tap, a remembered
   fact opens Memory, the transcript opens.
5. **The words stay the person's.** The transcript is kept exactly as it was spoken. The summary
   is clearly the bot's take and never replaces it.
6. **Cheap and safe.** One small background-model call per call worth summarizing, on the bot's
   own model and key. No new vendor and no recordings.
7. **Older apps keep working.** Old apps see the same bubbles and a better recap text.

## 3. The card in detail

### 3.1 Header

`(phone) Voice call · 4:12` on the left, the end time on the right (tabular figures). It's a
"Phone call" when the bot rang the person (D-135). Long press or `⋯` gives Copy summary, Copy
transcript, Share, and Delete call (deletes the card and its turns together, with an undo
snackbar, the same as deleting a message).

**End states replace the duration where they matter:**

| How it ended | Header | Extra |
|---|---|---|
| Normal hang-up (either side, D-423) | Voice call · 4:12 | none |
| Dropped and couldn't resume | Call dropped · 0:42 | "Call back" is the main button |
| Silence timeout | Voice call · 2:10 · ended after a quiet minute | none |
| Never connected (person started it) | Call didn't connect | the error in one line + Try again |
| Bot rang, nobody answered (D-135) | Missed call from Nova | the ring's reason ("about your 3 PM") + Call back |

Today never-connected and missed calls post nothing. They get a slim one-line card instead (no
summary, no fold).

### 3.2 Summary

- 1 to 3 plain sentences, past tense, in the conversation's language, written by the bot about the
  call ("Planned Friday's Cebu trip: …"). No "In this call, you and I discussed…".
- While it's being written: two shimmer lines (no shimmer under reduce-motion, just "Writing a
  summary…" in muted text). After 15 s with nothing, the shimmer goes away quietly.
- **Skipped** for calls under 30 seconds or under 3 turns with words in them. The card is then just
  the header, what was done, and the transcript. A 10-second "hi, never mind" call doesn't need a
  summary.
- Tap the summary: it expands if it was clamped (3 lines max collapsed).
- Small "Summary by Nova" label only on the expanded view, so it's clear who wrote it.

### 3.3 Next steps

- 0 to 3 items from the same model call: things the person or the bot said would happen next and
  that the bot can do. Each has a short label ("Text Ana the hotel address") and the full task in
  the person's words for the run.
- **[Do it]** starts an ordinary chat run with that task, using D-306's machinery: per row, used
  up only once the run starts, re-enabled if starting fails. The row then turns into a job row
  ("⟳ Texting Ana… Open ›") and moves to "Done on the call" (the card updates through
  `watchConversation`).
- A swipe or `×` dismisses a step. Dismissed and done states are saved on the message, so every
  device agrees.
- Only steps the bot could do get a button. Steps for the person ("You'll book the hotel") show
  without a button. That's still useful, and it tells the person nobody else is on it.
- **Never done automatically.** Only a tap starts one.

### 3.4 Done on the call

One list, oldest first:

- `start_task` jobs (today's rows, unchanged: status icon, task, Open ›).
- Quick tool calls from `runs` where `trigger='voice'` during the call, each turned into one
  human line from its name and arguments, with no model needed:

| Tool | Line | Tap |
|---|---|---|
| `memory.write` | ✓ Remembered: you like aisle seats | opens the bot's Memory at that entry |
| `web.search` / `web.fetch` | ✓ Looked up "flights to Cebu" | opens the run |
| `routines.create` | ✓ Set up: every weekday at 8 AM, the news | opens the routine |
| `tasks.create` | ✓ Added a task: renew passport | opens the task |
| `notify.user` | (hidden: it's a push) | none |
| `device.read` | ✓ Checked your calendar | opens the run |
| `memory.search`, `knowledge.search`, `routines.list`, `tasks.list`, `usage.report` | hidden: lookups that changed nothing | none |

  Failed tools show "✕ Couldn't set up the reminder · Try again" (Try again starts it as a chat run).
- More than 4 rows: show 3 + "2 more" that expands.

### 3.5 Transcript

- The call's voice bubbles **leave the main timeline** and live in the card, folded:
  "▸ Transcript · 18 turns".
- Tap: expands inline below, in a compact layout: small speaker name ("You" / "Nova") and text,
  no bubbles, tighter line height, timestamps in the margin every minute. A call over 40 turns
  opens a full-height sheet with search and Copy instead, so the chat doesn't jump a whole screen.
- Words that were cut off at hang-up end in "…" (§1.2 fix).
- Each turn still supports the message menu (copy, read aloud, react, report), because each one is
  still its own message under the hood.
- Search across chats still finds words said on calls, and a hit opens the card with the fold
  open and the turn highlighted.

### 3.6 Actions row

- **Call back** (primary on dropped / missed, secondary otherwise): starts a call to the same bot
  in the same conversation, so the new call hears the last turns (D-327's call context).
- **Copy**: the summary + next steps + transcript as plain text, ready to paste into a note.
- **⋯**: Share (system share sheet with the same text), Delete call.

### 3.7 While the call is on

Today the bubbles land in the chat one by one while the call goes on. Instead, the card appears at
the start of the call (Phase 3) as a live card: "(pulsing dot) On a call with Nova · 1:23 ·
Return to call" with the transcript fold filling in and job rows appearing as they start. At the
end it becomes the recap card in place, with no new message and no jump. On another device it
shows "On a call on your iPhone" without a Return button.

### 3.8 Elsewhere

- **Conversation list preview:** "(phone) Planned Friday's Cebu trip…" once the summary is in, and
  "(phone) Voice call · 4:12" until then (not "Call ended").
- **Notifications:** none by default; the person was just on the call. If the app is in the
  background when a `start_task` job from the call finishes, the existing reply-ready push
  (D-325) covers it.
- **The bot's next chat run** sees the summary as the recap's text part, so "what did we decide
  on the call?" works even after the turns have been trimmed from context.
- **Wide screens:** same card, max width 520 (up from 420) because it holds more.
- **Watch (D-410), widgets (D-405):** out of scope; they read the text part.

### 3.9 Accessibility and feel

- The card is one semantics node that reads "Voice call, 4 minutes 12 seconds, 2:41 PM. Planned
  Friday's Cebu trip…  2 next steps. 3 things done. Transcript, 18 turns, collapsed." with custom
  actions for Call back and each Do it.
- Dynamic type: rows wrap, buttons drop below their text past 1.3× scale.
- Motion: the summary cross-fades in (200 ms), the fold animates its height (250 ms,
  `Curves.easeOutCubic`). Both are instant under reduce-motion.
- Haptics: a light tick on Do it, as the suggestion rows do.
- Dark mode: the card keeps `surfaceContainerLow` and `outlineVariant`; no tinted background
  (plain backgrounds rule).

## 4. Data model

No new table for the card. The `call` part on the recap message grows; old apps ignore the new
fields.

```jsonc
{ "type": "call",
  "live_call_id": "…",
  "seconds": 252,
  "kind": "app" | "phone",                       // phone = the bot rang (D-135)
  "ended": "hung_up" | "bot_hung_up" | "dropped" | "silent" | "failed" | "missed",
  "started_at": "…", "ended_at": "…",
  "state": "live" | "ended",                     // Phase 3
  "turns": 18,                                   // count, for the fold label
  "tasks": [ … ],                                // as today
  "actions": [ { "run_id", "tool", "label", "status", "target": {"kind":"memory"|"routine"|"task"|"run", "id"} } ],
  "summary": { "status": "pending" | "ready" | "skipped" | "failed",
               "text": "…", "model": "…" },
  "next_steps": [ { "id", "label", "task", "doable": true, "state": "open" | "started" | "dismissed", "run_id": null } ]
}
```

- **Turns are tied to their call** by a new `call` field on their text part:
  `{type:"text", text, voice:true, call:"<live_call_id>", cut?: true}`. The app hides messages
  whose `call` matches a card in the same chat and shows them in that card. Calls from before this
  change have no field and stay as bubbles above their card (no backfill; see §10 Q5).
- **Quick tools are tied to their call** by passing `live_call_id` into `voiceTool` runs (the
  request already carries it) and storing it in `runs.voice_call.live_call_id`; no migration.
- **State changes** (next step started or dismissed, summary arriving) update the recap message's
  content through the API (sealed with `contentKeys` like all content) and send
  `ConversationActivity.message(id)` so open chats refetch that one message.
- The text part (for older apps and the model) becomes:
  `Voice call · 4:12\nPlanned Friday's Cebu trip: …\nNext: Text Ana the hotel address; …\nStarted on the call: …`

## 5. The summary call

- **When:** right after `postCallRecap`, as a worker job (never in the hang-up request), for calls
  that pass the §3.2 threshold. The card is posted with `summary.status = "pending"`.
- **Model:** the bot's **background** model through `backgroundComplete`, the same path as
  starters and media safety: the bot's own key, local model, or Casama's key with markup,
  `meta.purpose = "call_summary"`. **No new model**, so nothing to add to the OpenRouter
  allowlist, unless §10 Q2 picks a dedicated one.
- **Input:** the call's turns (speaker + text), the names of what was done (§3.4), the bot's
  name, the person's first name, today's date and time zone. Long calls send the last ~6,000
  tokens of turns plus the first 500 (the opening usually says why the call happened).
- **Output:** strict JSON `{summary, next_steps:[{label, task, doable}]}`, max 400 output
  tokens; anything that doesn't parse marks `failed` and the card simply has no summary.
- **Prompt rules:** past tense, 1 to 3 sentences, facts only from the transcript, no guesses at
  dates the person didn't say, next steps only for things said out loud, ≤ 3, and `doable` only
  if the bot has a tool for it.
- **Budget and credits:** counts toward the bot's daily budget. On a credit-gated plan with no
  credits it's skipped (`skipped`), never blocking the card.
- **Cost:** about 1,500 tokens of speech a minute. A 4-minute call is ~7,000 in / 250 out: **about
  $0.001** on DeepSeek V4.1 Flash, about $0.004 on a mid-size model, free on a local model. Goes into
  `docs/COSTS.md` next to the starters row in the same commit.
- **Settings:** a per-bot switch, "Summarize calls" (on by default), in the bot's Voice settings.
  Off: no model call, no summary, no next steps; everything else stays.

## 6. Fixing lost words (Phase 0)

1. `GeminiLiveEvents.flushPending({bool cut})` saves whatever is in `_user` and `_bot` as turns,
   marking a bot turn `cut` when it ended mid-reply.
2. `GeminiLiveCall.hangUp()` and the failed path call it **before** closing, so
   `ActiveCall.end()`'s `_onTranscript()` picks the turns up and they go with the hang-up post.
3. The worker sweep (app gone) can't recover words the app never sent; that stays as is.
4. Tests: fakes for "hang up mid-user-turn", "hang up mid-bot-turn", "connection fails
   mid-turn" in `client/test/` (gemini_live / active_call tests), each asserting the turn reaches
   `saveVoiceTranscript`.

This ships alone, first, since it's a bug fix.

## 7. Analytics

Add to `packages/contracts/analytics/catalog.json`:
`call_recap_summary_shown {ms_to_ready}`, `call_recap_summary_skipped {reason}`,
`call_transcript_opened {turns}`, `call_next_step_started`, `call_next_step_dismissed`,
`call_back_tapped {from: "dropped"|"missed"|"normal"}`, `call_recap_copied`. No transcript or
summary text in any event.

## 8. Testing

- **Server (vitest):** recap content shape per end state; summary job: threshold skip, JSON
  parse failure, credit skip, budget, ledger row with `purpose = "call_summary"`; quick-tool lines
  for each tool; the next-step start endpoint (used once, re-enabled on failure); a delete removes
  the card and its turns.
- **pgTAP:** only if a migration turns out to be needed (none planned).
- **Flutter:** `call_recap_test.dart` golden-style widget tests for each end state, pending →
  ready summary, fold open/closed, 40+ turns opens the sheet, Do it → job row, reduce-motion,
  text scale 2.0; chat timeline hides grouped turns and keeps ungrouped (old) ones;
  `gemini_live_test.dart` for §6.
- **Live check:** a real call on the local stack (web app through the T3 browser, then a phone
  build with Oliver's yes): talk 1 minute, ask it to remember something and set a reminder,
  hang up mid-sentence; check the card, the summary, the last words, Do it, Call back.

## 9. Phases

| Phase | What | Done when |
|---|---|---|
| **0. Lost words** | §6 | Hanging up mid-sentence keeps the words; tests green |
| **1. One card per call** | `call` field on turns, turns fold into the card, compact transcript + sheet, new header with end states, quick-tool rows, Call back / Copy / ⋯, missed and failed cards, list preview text | A call shows as one card with everything it did; older chats unchanged |
| **2. Summary and next steps** | §5 worker job, pending/ready UI, next steps with Do it / dismiss, Summarize calls switch, COSTS.md, analytics | Summary in ~3 s after a real call; Do it runs; ledger row correct |
| **3. Live card** | card posted at call start with `state: live`, fills in during the call, becomes the recap in place; other-device state | No jump at hang-up; the call shows live on a second device |
| **4. Polish** | search hit opens the fold at the turn, share sheet, a11y pass, docs-site page on calls, CHANGELOG | Checklist in §3.9 passes on iOS, Android, web |

Each phase: targeted tests while working, the full suites once through `scripts/heavy.sh` at
the end, commit by path, push after Oliver's go. **No deploy and no app builds without a yes.**

## 10. Questions for Oliver

| # | Question | My default |
|---|---|---|
| 1 | Fold the call's bubbles into the card (cleaner), or keep them in the timeline and only add the summary on top? | **Fold them in** |
| 2 | Summary on the bot's background model (cheap, already allowlisted, quality varies by bot), or one fixed model for every summary (consistent, one allowlist entry)? | **Bot's background model** |
| 3 | "Summarize calls" on by default? | **On** |
| 4 | Do the live card (Phase 3) now or later? It changes when the recap message is created. | **Now, after 2** |
| 5 | Old calls: leave their bubbles as they are, or backfill the `call` field from `live_call_turns` so they fold too (one migration, sealed content has to be rewritten)? | **Leave them** |
| 6 | Missed-call card when the bot rings and nobody answers? | **Yes** |

## 11. Risks

- **A wrong summary is worse than none.** Mitigated by strict prompt rules, the transcript always
  one tap away, "Summary by Nova" labelling, and never acting on a step without a tap.
- **Hiding bubbles hides context for older apps' users?** No: older apps don't read the `call`
  field and keep showing the bubbles.
- **Gemini's transcription quality** sets the ceiling for the transcript and summary. Names and
  numbers can be misheard; the summary prompt says to keep the words as heard.
- **Cost creep** on very long calls: input is capped (§5); calls past 30 minutes use the capped
  window.
