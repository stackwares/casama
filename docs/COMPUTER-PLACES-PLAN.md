# A bot's own computer and yours, at the same time: plan

Status: **not started** (written 2026-11-21). Waiting on Oliver's answers in §12 and his go-ahead.
No code yet.

Line numbers are from 2026-11-21. Re-find each one before editing.

## 0. Summary

Today a bot has one computer at a time. Allowing a bot on your Mac **moves** it there: its Linux
computer and files are out of reach until you move it back, and nothing in the chat lets you see
or change that.

This plan changes the model to **lending**. A bot always keeps its own computer (its home), and
your computer is a second place it may also work in. The bot picks the place per action, you can
pin it, and the chat always shows where each thing happened.

| | Today | After |
|---|---|---|
| Allowing a bot on your Mac | Moves the bot to the Mac | Adds the Mac as a second place |
| The bot's Linux computer | Out of reach while on the Mac | Always there |
| Who chooses the place | You, in Bot profile → Computer | The bot per action; you can pin it |
| Mac closed or offline | The bot has no computer | The bot carries on with its own |
| Routines and check-ins | Fail when the Mac is off | Run on the bot's computer |
| Side panel | Shows the one current computer | Switches between the places |
| A tool row in chat | Doesn't say where | Says "on Oliver's MacBook Pro" |

## 1. What exists today

Checked in the code on 2026-11-21.

- **One computer per bot.** `ComputerService.forBot` (`packages/agent/src/computers.ts:166`) picks
  `bots.default_computer_id`, else the bot's private computer, else the team computer.
- **Allowing moves the bot, and the app does it.** The switch under **Bots Allowed**
  (`client/lib/features/companion/companion_screen.dart:191`) saves the allow list, then calls
  `setBotComputer(bot, device.computerId)`, a direct write to `bots.default_computer_id`
  (`client/lib/core/supabase_backend.dart:6226`). Turning it off writes `null`.
- **A run takes one computer** on its first computer tool call (`getComputer`,
  `packages/agent/src/run.ts:3503`) and keeps it. The same `forBot` lookup decides the system
  prompt's computer paragraph (`run.ts:801-830`, `localComputerText` in `context.ts:173`), whether
  desktop tools are offered, and whether high-risk actions must ask (`run.ts:4718`).
- **Owner only.** A personal computer works only in runs that act for its owner (`run.ts:3509`,
  D-131), and the tunnel checks the bot is in the allow list on every call
  (`apps/server/src/api/routes/local.ts:997`).
- **Offline has no fallback.** The bot is told the Mac is offline (`personalOfflineMessage`, D-447)
  and has nothing else to work on.
- **The choice is buried.** Bot profile → Computer (`bot_profile_screen.dart:488`) lists Automatic
  and every usable computer. The chat's side panel (`ComputerPanel`,
  `client/lib/features/computer/computer_screen.dart:329`) shows whichever `computerForBot` returns
  (`chat_screen.dart:81`).
- **Two tools already choose a place per call.** We follow them rather than invent a third way:
  - `coding.delegate` takes `where: my_computer | bot_computer | cloud`
    (`packages/agent/src/tools/coding.ts:137`) and finds the person's computer by the allow list
    (`localDevice`, `coding.ts:452`), whatever the bot's own computer is.
  - `browser.*` takes `where: mine | computer` for the person's Chrome (D-323,
    `packages/agent/src/tools/browser.ts:279`), with a per-run default and a clear offline error.
- **Everything else follows the bot's one computer:** files sent in chat, file links
  (`file-links.ts:95`), things the bot makes (`creations.ts:193`), plugin tools (`plugins.ts:154`),
  skills, restore points, the home folder limit, desktop context (D-152) and permission cards
  (D-376).

### Problems this causes

1. Allowing a Mac takes the bot's own computer away, and the screen that does it doesn't say so
   clearly.
2. A closed laptop breaks the bot: chat tools, routines, check-ins and chat-app messages.
3. The bot can't do the safe thing (try it in the sandbox) and the local thing (your files) in one
   task.
4. Files a bot made on Linux are stranded while it's on the Mac, and the other way round.
5. In a shared workspace, a bot moved to one person's Mac has **no** computer in everyone else's
   chats ("someone else's personal computer").
6. No way to see or change the place from the chat.

## 2. Principles

- **Home never moves.** A bot's home is a cloud computer (private or team). Files sent in chat,
  things it makes, plugins, skills and restore points stay there. That keeps every feature in the
  last bullet of §1 unchanged.
- **Your computer is lent, not assigned.** The allow list alone decides whether a bot may use it.
  All of today's limits stay: shared folders, per-capability switches, owner-only runs, the
  on-screen bar with Stop.
- **Safe by default.** An action goes to the bot's own computer unless the bot says otherwise or
  you pinned the chat to yours.
- **Always visible.** Every action row and every approval names the place.
- **Old apps keep working.** An older app still writes `default_computer_id` when you allow a bot;
  the database quietly keeps the bot's home where it was.
- **No WebViews, no new paid service.** `docs/COSTS.md` needs no change (see §10 for the effect on
  computer hours).

## 3. The model

**Places.** For a run, the places are:

1. the bot's own computer (always, as `forBot` picks it, limited to cloud computers), and
2. each computer of the **person the run acts for** that is switched on for bots and has this bot
   in **Bots Allowed**.

Teammates' computers are never places in your runs, as today.

**Preference ("Works on").** Each person sets it per bot (open question 2):

| Choice | What happens |
|---|---|
| **Automatic** (default) | The bot picks per action. With no word from the bot, its own computer. |
| **Only the bot's computer** | Your computer isn't offered in this bot's runs for you. |
| **Only my computer** | Every action goes to your computer. Offline means the offline notice, as today. |

**Which of your computers.** With two paired computers that both allow the bot, the one last
active is used, and the side-panel switcher changes it (open question 5).

**What the bot is told.** The system prompt's computer paragraph lists the places: the bot's own
computer (as now), then "the person's own Mac, `Oliver's MacBook Pro`, online" with what they
allowed and the shared folders (today's `localComputerText`), plus when to use which: their local
files, apps and sign-ins on theirs, everything else on its own, and never move their files to its
own computer unless asked.

## 4. Tools

### 4.1 One `where` option

`shell.exec`, `files.read/write/edit/list/search` and `desktop.*` get an optional
`where: "bot_computer" | "my_computer"`, the names `coding.delegate` already uses. Left out, the
chat's preference decides (Automatic means `bot_computer`).

- `my_computer` when it's offline, off, or the bot isn't allowed gives a clear error that names the
  computer and says the bot's own computer is still available. Nothing is marked broken.
- A capability that's off (for example **Run commands**) gives today's message naming the switch.
- **A guard against the wrong place:** a path under one of the person's shared folders with no
  `where` is refused with "That folder is on Oliver's MacBook Pro: pass where: my_computer". A
  `~/workspace` path sent to `my_computer` is refused the other way round.
- `checkpoint.*` and `computer.restart` stay on the bot's own computer.
- Desktop tools are offered when either place has a desktop: a headless bot can now use your Mac's
  apps without becoming a desktop computer.

### 4.2 Browser

`browser.*` keeps `mine` (your Chrome, D-323) and `computer` (the bot's own), and their per-run
stickiness, since page refs only mean something in one browser. The separate browser on your own
computer (the **Use a browser** capability) becomes a third value, `my_computer`, never picked by
default (open question 6).

### 4.3 Coding agents

`coding.delegate` already works this way. Only its wording and offline text are aligned with the
new shared helper.

### 4.4 Moving files between places

A new `files.copy` with `from` and `to` places (open question 7): one file or folder, 50 MB at
most, read through one tunnel and written through the other. Copying **from** your computer **to**
the bot's is medium risk, so it asks under **Ask before acting**. Without this tool the bot would
pipe files through shell output, which is worse.

### 4.5 In the run

- `getComputer()` becomes `getComputer(place)`, keeping one handle per place for the run. The
  owner check, the activity sent to the on-screen bar, team folders and the home folder limit move
  inside it unchanged.
- One screen holder per computer (D-413), not per run.
- The "high-risk actions on your own computer ask" rule (`run.ts:4718`) reads the **call's** place,
  not the bot's computer. Approval text names the place: "Run a command on Oliver's MacBook Pro".
- `tool.started` and `tool.finished` events carry `place: {computer_id, kind, name}`. Events are
  JSON, so no migration, and older apps ignore the field.
- Cancelling a run kills commands on both places (the `signal` from D-320 already reaches each
  handle).

## 5. Data and API

**Migration** (one file; check every branch and worktree for a version clash first):

- `bots.default_computer_id` may no longer point at a personal computer. A `before insert or
  update` trigger sets it to `null` when it does. That is what keeps older apps working: their
  allow switch and their Computer picker write straight to the table.
- Existing bots that sit on a personal computer today: set to `null` (back to Automatic home) and
  give the computer's owner the preference from open question 3.
- New table `bot_place_prefs (org_id, bot_id, user_id, mode, device_id, updated_at)`, primary key
  `(bot_id, user_id)`, `mode in ('auto', 'bot_computer', 'my_computer')`. RLS: a member reads and
  writes only their own rows for bots they can use. `public.allow_worker`, and a pgTAP file.

**API** (then `pnpm gen`):

- `GET /v1/bots/{id}/places`: the places for me (name, kind, platform, online, capabilities) and
  my preference. The side panel and the bot profile read it.
- `PUT /v1/bots/{id}/places/preference`: `{mode, device_id?}`.
- `PATCH /v1/bots/{id}` and the bots trigger refuse or clear a personal computer as the home.

**Code that reads "is this bot on a personal computer"** and must switch to the allow list:
`desktop-context.ts:61`, `permission-cards.ts:107`, the plugin and creations lookups
(`plugins.ts:58,157`, `creations.ts:193`, already home-only once the trigger exists),
`routes/projects.ts:51`, `routes/computers.ts:824`, and the unpair clean-up (`local.ts:658`).

## 6. The app

All native Flutter, with the existing component catalog.

- **Use this computer for bots → Bots Allowed.** The switch only saves the allow list; it no longer
  moves the bot. The help text changes to say the bot keeps its own computer and may also work
  here.
- **Side panel.** When the bot has more than one place for me, the panel header becomes a picker:
  the bot's computer and each of my computers, with an online dot. It changes what the panel shows
  (files, screen, status) and nothing else. One place: no picker, as today. Same header on phones,
  where the panel is its own screen.
- **Works on.** The same menu ends with **Works on: Automatic / Only the bot's computer / Only my
  computer**, with one line of help each. Also reachable from the bot profile.
- **Action rows.** A tool row that ran on my computer gets a small tag with its name; rows on the
  bot's computer stay as they are, so the chat doesn't fill with tags. Approval cards say the place
  in their title.
- **Bot profile → Computer** lists only the bot's possible homes (Automatic, its private computer,
  the team computer). A second row, **Your computer**, shows whether this bot may use it and opens
  the Works on choice.
- **Notices.** "Your computer is offline" (D-447) stays for **Only my computer**. In Automatic the
  bot just says it in its reply; no notice.
- **Computers list.** A personal computer's card says which bots may use it instead of "used by".
- **Strings** in `client/lib/l10n/*.arb`; new Dart files import `material_ui`; `dart format` only
  on new files.

## 7. Routines and other background runs

- **Routines** get a **Where** choice, like the one for your browser: **The bot's computer**
  (default) or **My computer when it's on**. A routine set to yours waits briefly, then says the
  computer was off, as the browser option does (open question 4).
- **Check-ins, watchers and chat-app messages** (Telegram, iMessage, email) use the bot's computer
  only. iMessage keeps its own path to the Mac, unchanged.
- **Local tools (MCP) and plugin tools placed on your computer** (D-096, D-344) are connections,
  not computer tools. They already work whatever the bot's computer is and don't change.

## 8. Safety

- Nothing new is reachable: a bot allowed on your Mac could already do all of this after being
  moved there. What changes is that one run can now touch both places.
- **Text from the web must not steer your computer.** The prompt rule in §3 plus the existing
  untrusted-content wrapping apply. High-risk actions on your computer still ask (D-066, D-394).
- **Copying from your computer to the bot's** is the one new path for your files to leave your
  machine through a tool, so it asks (§4.4). The bot's shell on your Mac could always reach the
  internet; that is unchanged and stays behind the **Run commands** switch.
- Every action on your computer still shows in the on-screen bar with Stop, and now in the chat
  row too.
- The tunnel's per-call checks (bot in the allow list, run acts for the owner) don't change.

## 9. Tests

- **Agent and server** (`apps/server/test/local.test.ts` and a new `places.test.ts`, with the real
  computerd in companion mode that `plugin-companion.test.ts` uses): both places in one run;
  default is the bot's computer; each preference; offline falls back in Automatic and notices in
  Only my computer; a teammate's run never sees my computer; the path guard both ways; approvals
  read the call's place; `files.copy` both directions and its size limit; cancel stops both; a
  routine with each Where value.
- **pgTAP:** the trigger (a personal computer as home becomes `null`), the data move, RLS on
  `bot_place_prefs`.
- **Flutter:** the allow switch no longer calls `setBotComputer`; the picker appears only with two
  places; Works on saves; the tag on rows; the bot profile rows.
- **Live, on Oliver's Mac** (needs a Flutter build: ask first): one task that reads a file in a
  shared folder, processes it on the bot's computer and writes the result back; close the app
  mid-task; an older app build allowing a bot.
- Full suites once at the end through `scripts/heavy.sh`.

## 10. Effects to know about

- **Computer hours.** A bot that lived on a Mac used no cloud hours. In Automatic it now starts its
  own computer when it needs one, which uses hours (Free has 5 a month). The computer still starts
  only on first use. When hours are used up, the bot is told to use the person's computer if one is
  online, and **Only my computer** avoids hours altogether. The docs and the Works on help say so.
- **Self-hosted servers without cloud computers** (no provider set): the personal computer is the
  only place, so runs behave as **Only my computer**.
- **Older apps** show the bot's own computer in the side panel and no tags. Nothing breaks.
- **Prompt size** grows by one short paragraph only when a second place exists.

## 11. Phases

Each phase ends at its check, with its own tests, then a commit.

| Phase | What | Done when |
|---|---|---|
| 1 | Migration, trigger, `bot_place_prefs`, the places resolver, the two API routes, `pnpm gen`, readers in §5 switched to the allow list | Old and new apps can allow a bot and its home stays; pgTAP and API tests pass |
| 2 | `where` on shell, files and desktop tools; per-place handles; path guard; approvals and events by place; prompt paragraph; browser's third value | One run uses both places in the server tests; offline falls back |
| 3 | `files.copy`; routines' Where; background runs keep to the bot's computer | Copy and routine tests pass |
| 4 | App: allow switch, side-panel picker, Works on, row tags, approval titles, bot profile, computers list, strings | Flutter tests pass |
| 5 | Docs (`guide/companion.md`, `guide/computers.md`, `guide/coding-agents.md`, `guide/routines.md`, FAQ), `CHANGELOG.md`, `docs-site/develop/architecture.md`, the decision entry, live check on the Mac | The live task in §9 works end to end |

Shipping order after that, each with its own yes: server, web app, Android with Wear OS, iOS, Mac
(both builds). The server can ship first: Phases 1 to 3 are safe with older apps.

## 12. Questions for Oliver

Each has a default that is used if you just say "go".

| # | Question | Default |
|---|---|---|
| 1 | When the bot doesn't say where, which place? | Its own computer |
| 2 | Is **Works on** set per bot (for each person) or per chat topic? | Per bot, for each person |
| 3 | Bots that sit on someone's computer today: after the change, **Automatic** or **Only my computer**? | **Only my computer**, so nothing changes for them until they choose, with a one-time note in the chat explaining Automatic |
| 4 | Routines: the bot's computer by default, with a per-routine choice for yours? | Yes |
| 5 | Two of your own computers allow the same bot: which one? | The one last active; the side-panel picker changes it |
| 6 | Keep the separate browser on your computer as a third browser choice, or hide it now that your Chrome works (D-323)? | Keep it, never as the default |
| 7 | Include `files.copy` between places in this version? | Yes, 50 MB at most, asking before a copy off your computer |
| 8 | Name in the app for the bot's own computer in the picker | "{bot}'s computer" (or "Team computer"), as the computers list already says |
