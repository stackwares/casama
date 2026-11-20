# Meeting bot: a bot that joins Zoom, Google Meet and Microsoft Teams calls

Status: **not started** (written 2026-11-21). Waiting on Oliver's answers in §14. No code yet.
The part that gets the bot into a call (Recall.ai, or our own) is left open on purpose (Oliver,
2026-11-21: "with recall and without, let us decide in the future"). Everything else in this plan
is the same for both, and §7 sets the two side by side. Platform rules, prices and vendor docs were
read on 2026-11-20 and 2026-11-21 (sources at the end). This reopens D-123 and replaces D-287's
"meeting bots stay cut". The decision gets its number when this is approved (the highest on local
main was D-453 on 2026-11-21; check origin/main too, the two have collided before).

## 0. Summary

Today Casama says "Casama doesn't send a bot into your calls" and works from other apps' notes
(D-287). Competing assistants join the call. This plan lets a Casama bot join a call as a named
participant, take notes, answer in the meeting chat and, later, speak.

There is no official door for this any more (§2): Google is closing its live-media API, Zoom's SDK
needs a token from someone already in the call, and Teams' official route is a Windows-only build
on Azure. So every product, Recall.ai included, sends a browser into the call as a guest that a
host lets in. The open question is whose browser:

| | A. Recall.ai (rented) | B. Our own (a meeting container on our computer servers) |
|---|---|---|
| Cost per meeting hour | $0.50; +$0.10 when the bot can speak; +$0.15 only if the call's own captions are off | About $0.013 of server time (1 vCPU, 2 GB at our Docker rate) |
| Build time to notes (Phase 1) | 4–5 days, all three platforms | 7–9 days for Meet; 3–4 more per extra platform |
| Upkeep | Theirs | Ours: join pages change and bot screening tightens |
| Platforms | Zoom, Meet, Teams, Webex, GoTo, Slack huddles | Meet first, then Teams. Zoom is the hard one (§2) |
| Self-hosters | Need their own Recall key | Works with no outside account |
| Biggest unknown | How fast the bot's first spoken word comes | Whether call sound can get out of our locked-down computer network (§6.7) |

Both unknowns are answered by Phase 0 before anything is built on them.

| Phase | What people get | Build time |
|---|---|---|
| 0. Proofs | Nothing yet: both engines tried on real calls, §7's table filled with measured numbers | 2–3 days |
| 1. Notes | Send a bot to a call with a link, or by a calendar rule. It joins, says who it is, takes notes, and files a summary with decisions and action items | A: 4–5 days. B: 7–9 days (Meet) |
| 2. Takes part in chat | Ask the bot something in the call's chat, or by name out loud, and it answers in the chat. Live transcript in the app | 2–3 days |
| 3. Speaks | Call the bot by name and it answers out loud | 3–4 days |
| 4. Reach | The other engine, phone dial-in, a signed-in bot account, invite by email, notes with no bot | Each its own short plan |

Build times are estimates in agent working days with tests. Live checks on real calls come on top
and need Oliver's accounts (§17).

**What is the same whichever engine is chosen** (about two thirds of the work): the `meetings`
tables, how a bot is sent and stopped, the notice it gives, how it follows the call, the chat
answers, the speaking session, the notes and the card, billing, limits, switches and docs. The
engine sits behind one interface (§6.3), so picking later, switching, or running both costs one
adapter.

**A correction to what I said in chat.** I said the bot's own computer already had most of what
our own engine needs. Reading the code changed that in two ways. Computers have no direct way out
to the internet, only web traffic through the egress proxy, and call sound normally travels another
way (§6.7). And a call in the bot's own computer would use up the workspace's one running computer
and put an outside web page next to the bot's files. So engine B is a separate short-lived
container on the same servers, and its network path is the first thing Phase 0 tests.

## 1. What exists today

| Where | What | Use here |
|---|---|---|
| `packages/agent/src/calendar-triggers.ts` | Calendar routines: connected calendars checked every 5 minutes, 36 hours ahead. Already pulls each event's call link (`CalEvent.link`: `hangoutLink`, `conferenceData`, `onlineMeeting.joinUrl`, or a Meet, Zoom, Teams, Webex or Whereby address in the location or description). Filters `title_match`, `outside_guests`, `has_video_link`; `anchor: "end"` (D-287) | The "join my meetings" rule |
| `packages/agent/src/voice.ts` (`createGeminiLiveSession`), `apps/server/src/worker/voice.ts` (`voiceSession`, with a `phone` mode) | Mints a locked, single-use Gemini Live session: 16 kHz sound in, 24 kHz out | A `meeting` mode for speaking |
| `apps/server/src/api/live-relay.ts` | The server relay every paid call goes through: counts usage, enforces call limits (D-333, D-426) | Speaking sessions go through it too |
| `apps/server/src/api/routes/telephony.ts` (`bridge`, `geminiBridge`), `resamplePcm16` and friends in `voice.ts` | The phone bridge between Twilio and Gemini Live | The pattern for a server-side sound bridge. It is Twilio-shaped, so the code is copied, not shared |
| `live_calls`, `live_call_turns`, `apps/server/src/billing/live-calls.ts` (`endSilentCalls`, `settleCall`) | A call record with a heartbeat; the worker ends abandoned calls and bills their real length | The same pattern for meetings |
| `apps/server/src/services/call-recap.ts` (`CallPart`, `recapText`) | The call card with a text line that older apps read (D-429) | The meeting card |
| `packages/sandbox/src/docker/provider.ts`, `apps/supervisor`, `infra/egress-proxy`, `infra/turn`, `dart/computerd`, Neko live view | Bot computers on Docker: Chromium, a real screen, live view, a proxy that is the only way out | Engine B's container |
| `apps/extension/src/lib/captions.ts` | Reads Google Meet's captions into a transcript, with a consent step and a notice for the others (D-323, behind `chrome_meeting_captions`) | Caption reading for engine B; the "no bot" route |
| `gallery/routines/meeting-notes`, `gallery/skills/meeting-notes` | The notes format and the `shared/meetings/` folder | The notes the bot writes |
| `packages/agent/src/telephony.ts` (`voice.call`, D-141) | Phones a number through the workspace's Twilio account | Phone dial-in (Phase 4). It can't press keypad digits yet |
| Bot addresses on `casama.app` (D-449, on origin/main) | Each bot has an email address | Invite the bot to an event (Phase 4). Invites aren't parsed yet |

**What is missing:**

- **No sound on a computer.** Neither image has a sound server, and computerd starts Neko with
  `NEKO_CAPTURE_MICROPHONE_ENABLED=false`.
- **No way out for call sound.** Each computer sits on a Docker network made with `Internal: true`.
  The egress proxy is the only way out and it carries web traffic only (HTTP and `CONNECT`, so TCP).
  The TURN relay only passes live view.
- **Small computers, few at once.** The compose default is 1 vCPU and 2 GB, and plans allow one to
  three running computers.
- **Nothing meeting-shaped on the server:** no tables, no usage kind, no tools, no content part.
- **Public text that says the opposite** (changes in step, §8): `docs-site/faq.md:341`,
  `docs-site/guide/meetings.md:3` and `:81`, `site/content/use-cases/ai-meeting-assistant.md:6`,
  `:7`, `:24` and `:81–87`, `site/content/use-cases/ai-executive-assistant.md:61`,
  `docs-site/public/llms.txt:66`, and the generated copies under `docs-site/public/`.

## 2. What the platforms allow

| | Google Meet | Microsoft Teams | Zoom |
|---|---|---|---|
| Official way for an outside bot to hear and speak | None. The Meet Media API never left preview and its endpoints are turned off on 2027-01-15. The REST API only covers after the call | Graph bots with "application-hosted media": C# only, on Windows Server in Azure, a public address per machine, still labelled developer preview | Meeting SDK: since 2026-03-02 a bot joining a call outside its own account needs a token from a user who is already in that call. RTMS delivers a call's sound and documents no way to send any in; the host must authorize it, and it runs on paid credits |
| A browser guest | Knocks and a host admits. Since March 2026 some knocks land in a second queue whose default answer is deny. If the host unticks "Anyone with the meeting link can ask to join", anonymous users and bots are refused automatically | Detected bots are held in the lobby whatever the lobby setting (`ExternalBotAccessMode`, default `RequireApprovalWhenDetected`); an admin can pick `BlockDetectedBots`. Microsoft says detection misses some bots and can mislabel people | Guests wait in the waiting room. The web client "identifies and intercepts automated or suspicious participants" and runs CAPTCHA v3; neither can be turned off |
| What helps | A signed-in Google account invited on the Calendar event joins without knocking under "Trusted" access (so a bot needs its own account for this, Phase 4) | A self-identification programme for bot makers exists (preview, full for now) | Nothing for a guest. Sign-in-only calls refuse them |
| Phone dial-in | US and Canada numbers on every Workspace edition | The organizer needs Audio Conferencing (in E5, an add-on elsewhere) | The host must be on a paid licence |

What follows from this:

- **The bot is always a guest someone lets in.** It works best when the person who sent it is in the
  call, or is the host. The app says so when a bot is sent.
- **No route works everywhere.** Some organizations block bots outright, so the fallbacks in §6.8
  matter, and a failed join must say why in plain words.
- **Zoom is the hardest for our own engine.** Its web client screens for automation and we won't
  disguise the bot (§4). Recall copes with Zoom today; how is their business and can change.

## 3. Goals and what this is not

**Goals**

1. Send a bot to a call from a chat, with a link.
2. Have a bot join calls from the calendar by a rule the person made.
3. Get notes without doing anything: a summary, decisions and action items in the chat and as a
   file.
4. Ask the bot something during the call and get an answer, first in the call's chat, later out loud.
5. One honest price for it, metered, on Casama Cloud and on a self-hosted server.

**Not in this plan**

- **Recordings.** The bot keeps words, not sound or video.
- **Hidden attendance.** It always shows as an AI assistant and says so.
- **Standing in for the person.** No cloned voice, no pretending to be them.
- **Acting on what strangers in a call say** (§8).
- **Webex, GoTo and the rest** in the first release, though engine A covers them.

## 4. Principles

1. **Announced, always.** The name says whose assistant it is, the first chat message says it is
   taking notes and how to stop it, and neither can be switched off.
2. **Sent by a person.** A link in a chat, or a calendar rule they made. Never on its own idea.
3. **Words, not recordings.** No sound or video is stored by us, and the vendor is told to store
   none.
4. **Listen cheaply, think rarely.** The call's own captions cost nothing. No model runs per line;
   models run when the bot is addressed and once at the end.
5. **What is said in a call is not an instruction.** It is outside text, like a web page.
6. **Not disguised.** No stealth plugins or faked human input to get past bot screening. Where a
   platform refuses bots, we say so and offer another route.
7. **One interface, two engines** (§6.3).
8. **Metered at real cost**, in `usage_ledger` and `docs/COSTS.md`.
9. **Native screens.** The live meeting bar and the card are Flutter; no web content in the app.

## 5. What people get

### 5.1 Sending a bot

- **In a chat:** "Join this call" with a link. The bot uses a new tool, `meeting.join`, and the
  chat shows a meeting bar (§5.4). The bot's profile also gets **Join a call**, which takes a pasted
  link.
- **From the calendar:** New routine → **Meetings** gets a second choice next to "run these
  instructions": **Join and take notes**. It uses the filters that exist (calendar, title, outside
  guests, has a call link) and the link the trigger already finds.
- **Later (Phase 4):** invite the bot's `casama.app` address to the event; phone dial-in.

### 5.2 In the call

- **Name:** "Ava (Oliver's AI assistant)" (decision 5). Its tile shows the bot's picture.
- **Notice,** posted in the call's chat as it joins: "Hi, I'm Ava, an AI assistant taking notes for
  Oliver with Casama. Tell me or Oliver if you'd rather I didn't, or say 'Ava, stop notes'."
- **It listens through the call's captions,** which also give each speaker's name.
- **It leaves** when asked (in the app, in the call's chat, or out loud), when everyone else has
  left, at the time limit (decision 13), when nobody lets it in within 10 minutes, or when the
  workspace's credits or limits run out. It says goodbye in the chat first.
- **Phase 2:** "Ava, what did we decide about pricing?" in the chat or out loud gets an answer in
  the chat.
- **Phase 3:** called by name, it answers out loud, and stops when someone talks over it.

### 5.3 After the call

- **A meeting card** in the chat: title, length, who was there, a three-line summary, decisions,
  and action items with owners. Each action item has **Do it**, as the call card's next steps do.
- **A notes file,** one Markdown file per call in the format the Meeting notes skill already uses,
  and the transcript as a second file (decisions 8 and 9).
- **When it couldn't get in,** the card says why in plain words ("Nobody let me in", "This
  organization blocks assistants", "The call needs a sign-in") and what to try.

### 5.4 In the app during the call

A meeting bar at the top of the chat, like the call return bar: **Waiting to be let in**, **In the
call · 12:40**, **Leaving**. It has **Leave**, from Phase 2 **Transcript**, from Phase 3 **Mute**,
and on engine B **Watch** (live view of the bot's browser in the call).

### 5.5 Switches

- A server flag, `meeting_bot`, off until rollout (§13).
- A workspace switch for admins, and a per-bot switch, **Can join calls**.
- Who may send a bot (decision 4).
- **Use workspace knowledge when answering in calls,** off by default (§8).

## 6. How it works

### 6.1 The shape

```
chat tool · calendar rule · API
          │
     meetings row ──► MeetingService (worker) ──► MeetingEngine ──► A: Recall.ai
          ▲               │  states, timers                    └──► B: meeting container
          │               ▼
     meeting card     meeting_lines ──► follows the call ──► chat answer · voice session · notes run
```

### 6.2 Data

- **`meetings`:** workspace, bot, conversation, who sent it, source (`chat`, `calendar`, `api`), the
  routine and calendar event (so one event gets one bot), address, platform, title, engine and its
  reference, state, mode (`notes`, `chat`, `voice`), times, end reason, seconds, participants, usage,
  the card's message id, the notes path, and `last_seen_at` for the heartbeat.
- **`meeting_lines`:** meeting, sequence, time, speaker, text, source (`captions`, `speech`, `chat`).
  The text is sealed with the workspace's data key like message content (D-238).
- **Usage kind `meeting_seconds`.** The kinds live in the `usage_ledger_kind_check` constraint, so
  this is a migration, plus the places that treat kinds specially: the billable-default trigger, the
  analytics rollup map, the daily-spend sums and the app's usage row.
- **States:** `scheduled → joining → waiting → in_call → ended | failed`, with one set of end
  reasons that both engines map onto: `not_admitted`, `removed`, `blocked`, `sign_in_required`,
  `link_invalid`, `call_over`, `asked_to_leave`, `everyone_left`, `limit`, `engine_error`.
- **Row-level security:** the conversation's members read a meeting and its lines; only the server
  writes them. pgTAP covers it.

### 6.3 The engine interface

```ts
interface MeetingEngine {
  kind: "recall" | "own";
  join(req: JoinRequest): Promise<{ ref: string }>; // address, name, picture, notice, when, mode
  leave(ref: string): Promise<void>;
  sendChat(ref: string, text: string): Promise<void>;
  startVoice(ref: string, bridge: VoiceBridge): Promise<void>; // Phase 3
  stopVoice(ref: string): Promise<void>;
}
// Whatever the transport, events reach MeetingService.onEvent as one of:
// state · participant · line · chat · audio (only while a voice session is open) · usage
```

`MEETING_ENGINE` picks the engine for a server. A fake engine drives the tests, as the Twilio fake
does for phone calls.

### 6.4 Following the call

- Lines are saved as they arrive. **No model call per line.**
- **Being addressed** is found in code: the bot's name at the start of a line or after a comma, with
  the misspellings captions make, or its name in the call's chat. One wake per question.
- **On a wake,** one model call gets the last ten minutes of lines, the meeting's title and people,
  and the question, and answers in the chat (Phase 2) or opens a voice session (Phase 3).
- **At the end,** a normal bot run in the conversation gets the transcript as a file and writes the
  notes and the card. An hour of talk is about 13,000 tokens, so it fits without summarizing as we
  go.

### 6.5 Speaking (Phase 3)

- **A voice session opens only when the bot is addressed** and closes 20 seconds after its answer if
  nobody follows up. Held open for a whole call it would cost $2.30–3.60 an hour at the rates we
  measured (D-357), would hit Google's ten-minute connections, and would try to answer everything it
  hears.
- It is `voiceSession` in a new `meeting` mode: the bot's persona, the meeting's title and people,
  and the recent lines. Its only functions are `leave_meeting` and `stay_quiet` (§8).
- **Sound:** both engines hand us the call's sound at 16 kHz, which is what Gemini Live takes, and
  both can play its 24 kHz reply. Gemini's `interrupted` stops playback when someone talks over it.
- It goes through the live relay, so limits and usage work as on any call.
- **The delay before the first word** is the caption lag plus opening the session. The target is
  under three seconds; Phase 0 measures it. If it is too slow, or Gemini Live copes badly with a room
  of voices, the fallback is a written answer read out with Gemini's read-aloud voice.

### 6.6 Engine A: Recall.ai

- **Setup:** `RECALL_API_KEY`, `RECALL_REGION` and `RECALL_WEBHOOK_SECRET`, all in Vaultwarden.
  Regions are separate accounts (US East, US West, Frankfurt, Tokyo), and Recall says meeting data
  never leaves its region.
- **Join:** `POST /api/v1/bot/` with the address, the name, `join_at`, the notice as
  `chat.on_bot_join`, the picture as `automatic_video_output`, `automatic_leave` set to our limits,
  video recording off and `retention: null` (keep nothing).
- **Timing:** a bot created more than ten minutes ahead is guaranteed on time, so calendar joins are
  created early. A join from a pasted link draws from a small warm pool and can answer `507`; we
  retry every 30 seconds, up to ten times, and the bar says "Joining in a moment".
- **Transcript:** `meeting_captions`, free, on Zoom, Meet and Teams (not personal Teams accounts).
  Lines and participant events come to our API over a websocket (`realtime_endpoints`,
  `transcript.data`). If the host has captions off, Recall's own speech-to-text is $0.15 an hour
  (decision 11).
- **States:** Recall's status webhooks, signed, at `/hooks/recall`. Their sub-codes map onto our end
  reasons (`google_meet_bot_blocked`, `zoom_bot_blocked` → `blocked`; `meeting_requires_sign_in` →
  `sign_in_required`; `timeout_exceeded_waiting_room` → `not_admitted`).
- **Chat:** `send_chat_message`. Meet allows 500 characters a message, so long answers are split.
- **Speaking:** the bot shows a small page we host as its camera (`output_media`). That page hears
  the call and plays the reply, and it talks to our live relay with a one-time secret, as the app
  does. It needs Recall's larger bot (`web_4_core`, +$0.10 an hour) chosen at join, so a call in
  voice mode pays that for its whole length.
- **What Recall sees:** the whole call passes through their bot. They become a subprocessor, which
  changes the privacy policy (§8).
- **Self-hosters** put their own Recall key in the server's settings (decision 12).
- **Not confirmed yet:** the page-as-camera details (I read the agent guide, not the reference
  page), whether keeping nothing affects the live transcript, and their compliance papers. Phase 0
  covers the first two.

### 6.7 Engine B: our own

- **A meeting container per call.** A new image, `computer-meeting`, built on the desktop image (the
  same Chromium, screen, Neko and computerd) plus a sound server and a small runner, `meetingd`
  (TypeScript on Playwright). The supervisor starts it through `DockerProvider` with a new profile,
  `meeting`: no home volume, a fixed size, removed when the call ends. It isn't one of the
  workspace's computers and is metered as meeting time.
- **Sound:** a virtual speaker the browser plays into, which we record (the whole call, mixed), and
  a virtual microphone we play the bot's voice into, unmuted in the call only while it speaks. Vexa's
  bot uses this layout and plays 24 kHz sound, which is what Gemini Live gives us.
- **Joining:** one Playwright flow per platform: open the link, set the name, camera and microphone
  off, ask to join, wait to be let in, notice being removed or the call ending, turn captions on.
  Vexa's bot (Apache-2.0, which fits our AGPL licence) is the reference for the steps. We port ideas
  with credit and don't depend on it: its bot is mid-rewrite and the project has about 530 open
  issues.
- **Transcript:** the call's captions read from the page. The Meet logic exists in the extension;
  Teams and Zoom need their own. When captions are off, speech-to-text on the mixed sound is a later
  addition.
- **Chat:** typed into the call's chat box.
- **The network, which is the main unknown.** Call sound normally travels as UDP straight to the
  platform, and a computer can't send that. In order of preference:
  1. Make the browser carry the call over the web port through the egress proxy. All three platforms
     have a fallback for networks that block UDP; I'm stating that from memory, and whether it holds
     through our proxy, with usable quality, is Phase 0's first test. Nothing about isolation changes.
  2. A relay for meeting containers only, limited to the platforms' published media addresses. That
     changes the isolation model and needs a security review before any code.
- **gVisor:** production computers run under it. Chromium already does; the sound server is ordinary
  user-space software. Decoding other people's video in software is the cost, so the bot asks for
  the smallest layout and turns incoming video off where the call allows.
- **Size:** 1 vCPU and 2 GB to start (what Vexa's Helm chart gives a bot); Phase 0 measures a real
  call.
- **Identity:** an anonymous guest in the first release. A signed-in bot account, signed in once
  through live view and stored as a sealed credential, comes in Phase 4. Vexa's notes on this are
  blunt: one call at a time per account, a dedicated account, a steady address.
- **Capacity:** meeting containers count against the host's memory budget
  (`COMPUTER_HOST_MEMORY_GB`). The production server has about 9 GB free for computers, so about four
  calls at once with nothing else running (§10).

### 6.8 Fallbacks either engine can use (Phase 4)

- **Phone dial-in.** Calendar events often carry a number and a PIN. The phone bridge joins with
  them once it can press keypad digits. Sound only, no captions and no names, so it needs
  speech-to-text or an open voice session throughout, on top of about $1.10 an hour in Twilio fees
  on the workspace's own account. For when it is asked for, not a default.
- **Notes with no bot.** The Chrome extension's caption notes exist for Meet (behind
  `chrome_meeting_captions`). Recording a call's sound in the desktop app is its own plan.

## 7. The engine decision

| | A. Recall.ai | B. Our own |
|---|---|---|
| Per meeting hour | $0.50–0.75 | About $0.013, plus the server it sits on |
| At 100 / 1,000 / 10,000 hours a month | $50 / $500 / $5,000 and up, before any volume deal | Nothing extra / about one dedicated server (€159) / about six (§10) |
| Build to notes | 4–5 days, three platforms | 7–9 days for Meet, 3–4 per platform after |
| Upkeep | None for joining | A fix whenever a join page or bot screening changes; expect it monthly somewhere |
| Zoom | Works today | Likely blocked for a plain guest; dial-in or A instead |
| Speaking | A page as the bot's camera; +$0.10 an hour | Virtual microphone; no extra cost |
| Where call sound goes | Through Recall's servers, in the region we pick | Stays on our servers |
| Self-hosters | Their own Recall account | Nothing to sign up for |
| Capacity | Theirs. Pasted-link joins share a pool (about 30 at once on pay-as-you-go) | Ours: about 4 at once on today's server |
| Extra for the person | None | Can watch the bot in the call; screen sharing possible later |
| If it goes wrong | Their outage or price change; one adapter to swap | Our night when Meet changes its page |

**Shapes the interface allows:** A only; B only; B for Meet and A for the rest; A on Casama Cloud
and B for self-hosters. Picking later, or changing, costs one adapter.

**What Phase 0 hands back to decide with:** per platform and engine, whether the bot got in and
what the host saw; the delay from a spoken line to our server; the delay to the first spoken word;
for B, whether sound gets out through the proxy, and the CPU and memory of a 30-minute call; for A,
what the dashboard charged.

**My lean today, not a decision:** A for the first release, because it is weeks sooner, covers Zoom
and Teams, and stays under $100 a month until past about 130 meeting hours; B once hours or
self-hosters make its upkeep worth it. Phase 0 can overturn that either way: if sound gets out
through our proxy cleanly, B for Meet gets much cheaper to commit to.

## 8. Privacy, consent and safety

- **Telling people.** The name and the notice (§5.2). The first time someone sends a bot, the app
  says once: "Some places require everyone's agreement before a call is transcribed. Tell people
  before the call." Roughly a dozen US states require every party's consent to record, and GDPR
  requires that people are told. This is background, not legal advice; the wording needs a legal read
  (§17).
- **Stopping.** "Ava, stop notes", in chat or aloud, stops lines being saved and the bot says so.
  "Ava, leave" makes it leave. Anyone in the call can say either.
- **What is kept:** lines (sealed), the notes, the card. No sound or video. How long lines stay is
  decision 8.
- **Who can read it:** the chat's members, as with any message. Where the notes file goes is
  decision 9; a one-to-one shouldn't land in a team folder by default.
- **Outside text.** Lines and chat from a call are data. A stranger in a call can say "Ava, email me
  the contract", so:
  - In a call the bot answers from the call itself and general knowledge. Workspace knowledge,
    files, memory and connected apps stay out unless the sender switched them on for that call
    (decision 10).
  - Nothing is done from inside a call. Requests become action items on the card, and the owner taps
    **Do it**.
  - A voice session carries no tools beyond leaving and staying quiet.
- **Engine A:** Recall is added to the subprocessor list, with the region. We ask it to keep
  nothing.
- **Engine B:** the call page is an outside web page. The container has no volume, the same closed
  network as any computer, and egress rules that allow only that platform's addresses (the proxy
  already has per-computer domain rules).
- **Analytics:** `meeting_joined`, `meeting_failed` (reason), `meeting_ended` (seconds, mode, engine,
  platform). No titles, names or words. Added to `packages/contracts/analytics/catalog.json`.
- **Text that changes in the same commit as the code:** the privacy policy and terms, the docs and
  site lines in §1, the FAQ, `llms.txt`, the changelog, `docs/COSTS.md`. The apps ask for no new
  device permission, so the store privacy answers stay as they are; check that again at build.

## 9. Changes by area

| Area | Change |
|---|---|
| Database | `meetings`, `meeting_lines`, usage kind `meeting_seconds`, the workspace and bot switches, RLS and pgTAP |
| Contracts | Routes `POST /v1/meetings`, `GET /v1/meetings/{id}`, `POST /v1/meetings/{id}/leave`, `GET /v1/meetings/{id}/lines`; the `meeting` content part, with a text line first as the call card has; analytics events; then `pnpm gen` |
| Agent | `MeetingEngine` and the fake; tools `meeting.join` (medium risk, send), `meeting.leave`, `meeting.status`; the wake check; the `meeting` voice mode; "Join and take notes" as a calendar routine action |
| Server | `MeetingService` and its minute tick in the worker (start scheduled joins, end silent ones, bill); the notes run and card; engine A's webhook and websocket endpoints and the camera page; engine B's websocket for `meetingd` |
| Sandbox, supervisor, images (B) | The `meeting` profile in `DockerProvider`, the `computer-meeting` image, `meetingd`, the host memory budget, the publish workflow |
| App | The meeting bar, the meeting card, **Join a call**, the routine choice, the switches, the usage row. New Dart files import `material_ui` and are the only ones formatted |
| Docs and site | `docs-site/guide/meetings.md` rewritten, the FAQ, the use-case pages, `llms.txt`, the API reference, the changelog |
| Costs | `docs/COSTS.md`: Recall.ai as a vendor (A) or the meeting container rate and server plan (B), and `meeting_seconds` |

## 10. Cost and pricing

**Per meeting hour**

| | A. Recall.ai | B. Our own |
|---|---|---|
| Notes, from the call's captions | $0.50 | About $0.013 (1 vCPU × $0.003 + 2 GB × $0.005) |
| Voice switched on for the call | $0.60 | The same $0.013 |
| The host has captions off | +$0.15 for their speech-to-text | Our own speech-to-text; not priced yet |
| The notes run at the end | About 15,000 tokens in and 1,500 out per hour of talk, at the bot's model's price. Cents | The same |
| Each answer in chat | About 4,000 tokens in | The same |
| Each minute a voice session is open | $0.038–0.06 (measured, D-357) | The same |

Recall's first five hours are free, it bills by the second, and its startup programme halves the
rate for the first 10,000 hours.

**Servers for engine B.** Calls bunch up in working hours. Taking the peak as three times the
working-hours average: 1,000 hours a month is about 17 calls at once, which is one Hetzner
AX102-class server (€159 a month, already in `docs/COSTS.md` as the next step); 10,000 hours is
about 170 at once, roughly six of them. These are estimates until Phase 0 measures a call. Below
about four calls at once, today's server carries it.

**What we charge** (decision 7). The simple start: `meeting_seconds` in `usage_ledger` at what it
costs us, billable on Casama Cloud with the usual markup, drawn from credits. An hour on engine A is
then about $0.70 of credits before any model use. Including meeting hours in plans, as computer
hours are, can come once we know what people use.

## 11. Phases

### Phase 0: proofs (2–3 days)

- **A:** a script that sends a Recall bot to a test call on each platform. Record: was it let in and
  what did the host see; do caption lines arrive, and how late; does a chat message post; with the
  camera page and Gemini Live, how long from the end of a question to the first spoken word; what the
  dashboard charged. Recall reaches the local stack through the `api-dev` tunnel.
- **B:** on local Docker, the desktop image plus a sound server, on a network with no way out but
  the egress proxy. Join a Meet call as a guest. Record: does the call's sound arrive and leave over
  the web port; are captions readable; does a clip played into the virtual microphone reach the
  others; CPU and memory over 30 minutes. Then a guest join on Teams and on Zoom, to see what stops
  it. The gVisor check needs a Linux machine with `runsc` (§17).
- **Done when:** §7's table has measured numbers and each engine has a yes or no per platform.

### Phase 1: notes (A: 4–5 days. B: 7–9 days for Meet)

- The tables, routes, `MeetingService`, the engine interface and its fake, the chosen adapter.
- `meeting.join` from a chat, **Join a call**, and "Join and take notes" on calendar routines.
- The notice, the leave rules, the limits, billing, the switches.
- The notes run, the meeting card with its text line, the failure reasons in plain words.
- The docs and site text, `docs/COSTS.md`, the decision entry.
- **Done when:** a bot sent by link and one sent by a calendar rule each join a real call, announce
  themselves, and file notes and a card; a refused join shows its reason; the hour appears in usage
  at the right cost.

### Phase 2: takes part in chat (2–3 days)

- The wake check, the chat answer, splitting long answers, "stop notes" and "leave".
- **Transcript** in the meeting bar.
- **Done when:** a question to the bot by name, typed or spoken, gets an answer in the call's chat
  within ten seconds, and a line that only mentions the name in passing doesn't.

### Phase 3: speaks (3–4 days)

- The `meeting` voice mode through the live relay; the engine's sound in and out; being talked over;
  **Mute**.
- **Done when:** on a real call the bot answers out loud inside the target delay, stops when
  interrupted, and the voice minutes are billed.

### Phase 4: reach (each its own short plan)

The other engine's adapter; phone dial-in; a signed-in bot account; inviting the bot's address;
more platforms on engine A; a notes-only desktop capture; screen sharing on engine B.

## 12. Checks

- **Unit:** the state machine and end-reason mapping, the wake check against recorded caption
  streams (names misheard, names in passing), webhook signatures, the join timing rules.
- **Server:** the routes and worker tick against the fake engine; billing and limits; the notes run.
- **pgTAP:** who can read a meeting and its lines.
- **App:** the card (new and old content), the bar's states, the routine choice.
- **Engine B:** the join flows against saved copies of each platform's join page, so a changed page
  fails a test before it fails a call. A weekly scheduled run that joins a real test call.
- **Live, with Oliver's accounts:** one call per platform per phase, with a second account as host:
  let in, refused, removed, captions off, the host ending the call.

## 13. Rollout

1. `meeting_bot` flag off; the admin workspace first.
2. Casama Cloud owners who ask, then everyone, one platform at a time as each passes its live
   check.
3. Older app builds read the card's text line and never see the bar; nothing breaks for them.
4. Public wording changes only when Phase 1 is live (decision 14).

## 14. Decisions for Oliver

| # | Question | Recommended | Other choice |
|---|---|---|---|
| 1 | Which engine? | **Decide after Phase 0**, with measured numbers, as you asked | A now; B now; or both (B for Meet, A for the rest) |
| 2 | What to build first | **Phase 0, then notes and chat (1–2).** Voice once notes have run on real calls | Everything through Phase 3 in one go |
| 3 | Platforms first | **On A, all three. On B, Meet, then Teams, then Zoom** | Meet only until it has users |
| 4 | Who may send a bot | **Any member, to a call they are invited to** | Owners and admins only |
| 5 | The name people see | **"Ava (Oliver's AI assistant)"** | "Ava · Casama" |
| 6 | The calendar rule's default | **Only calls the person organizes**; other calls are opt-in per rule | Every event with a call link |
| 7 | How it is charged | **From credits, at cost with the usual markup** | Meeting hours included in plans, like computer hours |
| 8 | Keeping the transcript | **Saved as a file beside the notes**, the person's to delete; raw lines removed after 30 days | Notes only; lines removed when the notes are written |
| 9 | Where notes go | **The chat and the bot's own folder;** "Share with the team" is one tap | Always `shared/meetings/`, as the routine does today |
| 10 | Workspace knowledge in a call | **Off; on per call** | On whenever no outside guests are in the event |
| 11 | Captions off (engine A) | **Pay the $0.15 an hour speech-to-text automatically** | Tell the person and take no notes |
| 12 | Self-hosters on engine A | **Their own Recall key in server settings** | Nothing until engine B exists |
| 13 | Time limit for one call | **2 hours, up to 4 if the sender extends it** | The length of the calendar event plus 15 minutes |
| 14 | What we say in public | **"Joins your calls and takes notes" once Phase 1 is live on Meet and one more** | Announce at the first platform |

## 15. Risks

- **Platforms keep closing the door.** Each of the three tightened bot access in 2026. A bot that
  works at launch may be held or refused later. The interface, the plain failure reasons and the
  fallbacks are the answer; no engine removes the risk.
- **Not let in.** The commonest failure will be nobody clicking Admit. The bar and the card must
  make that obvious, and the app says up front that it works best when the sender is in the call.
- **Engine B's network.** If call sound can't leave through the proxy, B needs a new network path
  and a security review, or it isn't worth building. Phase 0 answers this first.
- **Engine B's upkeep.** Vexa's own project shows the load: a rewrite in progress and hundreds of
  open issues. The saved-page tests and the weekly real call are there to catch breaks early.
- **Engine A's dependency.** Price changes, an outage, or a platform cutting Recall off. One adapter
  to swap, but a swap takes weeks.
- **Capacity.** Today's server carries about four calls. A burst of calendar joins at the top of the
  hour needs a queue and an honest "No room right now", and B at any scale needs the second server.
- **Captions.** Free, but off in some organizations, uneven across languages, and they mishear
  names, including the bot's.
- **Speaking in a room.** Gemini Live was built for one voice at a time. Cross-talk may confuse it;
  the read-aloud fallback covers that.
- **Consent.** A bot that transcribes without people knowing is a legal and trust problem. The
  notice can't be switched off for that reason.
- **Injection.** Someone in a call, or text on a shared screen, will try to steer the bot. §8 keeps
  tools and private knowledge out of reach by default.
- **Self-hosters on engine A** get a feature that needs a paid outside account.

## 16. How we'll know it worked

- Joins that end in notes, out of joins tried, by platform and by reason for failure.
- Calls per active workspace per week, and how many came from a calendar rule.
- Questions answered in a call, and how often **Do it** is tapped on a meeting card.
- Cost per meeting hour against what was charged.
- Whether "Does a bot join my meetings?" stops being a reason people give for choosing someone else.

## 17. Left for Oliver

- A Recall.ai account for the Phase 0 trial (five free hours); its key goes in Vaultwarden. Search
  the vault first.
- Test accounts that can host calls: a Google Workspace user, a Microsoft 365 tenant with Teams, and
  a paid Zoom licence.
- A Linux machine with gVisor for engine B's check. Running it on the production server is a
  production change and needs your yes; a throwaway cloud machine is the alternative.
- A legal read of the notice and the consent reminder.
- If engine B is chosen: the go-ahead for the larger server when calls outgrow today's.

## Sources

Read on 2026-11-20 and 2026-11-21.

- Google Meet API release notes (the Media API's end on 2027-01-15):
  <https://developers.google.com/workspace/meet/release-notes>
- Google Workspace Updates, the safeguarded guest admit flow (2026-03-24):
  <https://workspaceupdates.googleblog.com/2026/02/safeguarded-guest-admit-flow-in-google-meet.html>
- Google Meet help, controlling meeting access (bots and "Ask to join"):
  <https://support.google.com/a/users/answer/11989526>
- Google Meet help, dialling in: <https://support.google.com/meet/answer/9683440>
- Microsoft Learn, `Set-CsTeamsMeetingPolicy` (`ExternalBotAccessMode`):
  <https://learn.microsoft.com/en-us/powershell/module/microsoftteams/set-csteamsmeetingpolicy>
- Microsoft Learn, managing external bots:
  <https://learn.microsoft.com/en-us/microsoftteams/manage-external-bots>
- Microsoft Learn, the bot identification programme:
  <https://learn.microsoft.com/en-us/microsoftteams/teams-bot-identification>
- Microsoft Learn, application-hosted media bots:
  <https://learn.microsoft.com/en-us/microsoftteams/platform/bots/calls-and-meetings/requirements-considerations-application-hosted-media-bots>
- Zoom developer blog, the move to OBF tokens:
  <https://developers.zoom.us/blog/transition-to-obf-token-meetingsdk-apps/>
- Zoom support, automated participants on the web client:
  <https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0088381>
- Zoom developer docs, RTMS: <https://developers.zoom.us/docs/rtms/meetings/getting-started/>
- Recall.ai pricing: <https://www.recall.ai/pricing>
- Recall.ai docs: creating bots, captions, real-time sound, chat, status events, regions:
  <https://docs.recall.ai/llms.txt>
- Vexa (Apache-2.0), its bot and its notes on signed-in bots:
  <https://github.com/Vexa-ai/vexa>, <https://docs.vexa.ai/authenticated-bots.md>
- Attendee's licence (Elastic License 2.0, so not usable for Casama Cloud):
  <https://github.com/attendee-labs/attendee/blob/main/LICENSE>
- joinly (MIT): <https://github.com/joinly-ai/joinly>

Not confirmed from a first-party page, and marked as such above: that Google's second knock queue
targets bots (Google's post doesn't say so); the rollout date of Teams' block option; whether a free
Zoom account gets dial-in numbers; Recall's compliance papers.
