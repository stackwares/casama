# Master plan, November 2026

Status: **proposed** (2026-11-13). Nothing here is built. This is the one plan to execute from; it
orders the work of two documents and does not repeat their detail:

- `docs/PRODUCT-REVIEW-2026-11-13.md` (the review): what to fix, improve and add, with evidence.
  Items are cited as Fix 1–23, Improve (agent 1–9, app 1–7) and Add 1–15.
- `docs/LIBRARY-PLAN.md` (the Library plan): one place for everything bots make, in six phases,
  with wireframes in `docs/media/library-wireframes.html`.

When a stage lands, record its decisions in `docs/DECISIONS.md` (the highest number was D-266 on
2026-11-13; check first) and tick it here.

## Why this order

1. **Trust before features.** Production has 2 accounts and 5 runs. The first real users will hit
   the run failures and chat rough edges before they notice anything is missing.
2. **Server first inside each stage,** so the app work lands on something tested, and so a stage
   can start without a Flutter build.
3. **Work that touches the same code goes together,** so the chat screen, the Usage screen and the
   Slack adapter are each opened once.
4. **Library before the new kinds of output.** Finished documents, pages that take input, bigger
   sites and sound all need a shelf to land on; the review's Add 2 and Add 3 are the Library plan's
   Phase 6.

## Stages

Sizes: S is a day or two of agent work, M several days, L a week or more.

### Stage 0: confirm the two data-safety reports (S, read-only first)

- Fix 6: does the backup include the Vault key? Prove it with a restore onto a scratch machine.
- Fix 7: does the workflow engine keep message text outside encryption at rest and retention?
- Fix whichever is real. A change on the production server needs its own yes.
- *Done when:* a backup restores with working secrets on a clean machine, and a database dump of an
  encrypted workspace shows no message text in any schema.

### Stage 1: runs that survive (M, server only)

- Fix 1: waiting for a person doesn't count toward the run's time limit.
- Fix 2: thinking output resets the first-output timer.
- Fix 3: read why the model stopped; continue a cut-off reply; raise or drop the 4,096 cap.
- Fix 4: trim old tool results inside a run and recover from "context too long".
- Fix 5 and 8: retry after output has started, resume a failed run, sweep runs stuck in `running`,
  and don't repeat a tool that was in flight at a restart.
- Improve (agent) 6: Claude models get their thinking-effort setting.
- Improve (agent) 8: eval tasks for each fix above, and a stored live baseline so the nightly run
  can fail. A live eval run costs money and needs a yes.
- *Done when:* each fix has a test that failed before it; a run approved after an hour finishes; a
  60-step task completes on the default model.

### Stage 2: chat basics (M, app with small API changes)

*Built (D-283; Fix 9–13 before it). Checked by the Flutter suite, not yet on a phone; the tester build is still to ask for.*

- Fix 9: an error with Retry when a chat fails to load.
- Fix 10: load earlier messages; stop downloading the whole thread on every open.
- Fix 11–14: unsent messages survive a reload; Retry keeps attachments and skills; a just-sent
  message can be edited; drafts on the web.
- Fix 15–17: sharing a photo or file in; an in-app alert when an approval arrives; attachments go
  to the bot's own computer.
- Improve (app) 1–3: edit a routine and see its runs; rename and pin topics; search and add in
  Memory.
- Add 11 (the small ones): paste an image, regenerate, delete a message, find in this chat.
- *Done when:* the Flutter suite passes with a test for each; checked by hand on a phone and the
  web. Needs one tester build (ask first).

### Stage 3: the Library, part one (L)

*Built: Phase 1 (D-274), Phase 2 in the app (D-294). Not yet checked on a phone.*

- Library plan Phase 1 (the index and the API), then Phase 2 (the Library in the app).
- Shares the chat screen with Stage 2, so it follows it directly.
- *Done when:* the Library plan's checks for Phases 1 and 2 pass.

**Suggested launch line: after Stage 3.** Everything below can ship after launch.

### Stage 4: a more capable bot (M, server only)

- Improve (agent) 1: tool results can carry images, so the bot sees its screenshots.
- Improve (agent) 2: a `files.edit` tool.
- Improve (agent) 3: tool calls in parallel; sub-agents that don't block the parent.
- Improve (agent) 4–5: memory learns from the work in a run, retires contradicted facts, and the
  bot keeps a short record of its own tool work between messages.
- Add 10: a check before "done". Add 9: a research mode, which needs the parallel sub-agents.
- Improve (agent) 7: decide how far to widen the guard after untrusted content (changes D-213).
- *Done when:* eval success on the Stage 1 baseline rises and tokens per task don't.

### Stage 5: storage and cost you can see (L)

- Library plan Phase 3: the object store, real covers, files that outlive the computer, storage
  caps.
- Add 4 with it, since both change Usage, the paywall and `docs/COSTS.md`: a bot spending limit in
  the app, a price before a long run, no charge for failed runs, usage by person, low-credit
  alerts.
- Fix 6 follow-up: the object store is in the backup.
- The pricing question below is decided here.
- Turning on the screenshot service in production needs its own yes.
- *Done when:* Phase 3's check passes; a failed run shows $0; an owner can cap a bot from the app.

### Stage 6: where teams already are (L)

- Fix 18 first: webhook dedupe, long replies split, attachments, Feishu, inbound email.
- Add 1: a real Slack app (one-click install, @mention in channels, approvals, progress and files
  in the thread), then Microsoft Teams, then Discord.
- Add 14: assign a Linear or Jira ticket to a bot.
- Needs from Oliver: a Slack app listing, a Teams app registration, a Discord application.
- *Done when:* a person approves a risky step from a Slack thread without opening Casama.

### Stage 7: the Library, part two (M)

- Library plan Phase 4 (beside the chat, pins, collections) and Phase 5 (sharing every kind, media
  bytes out of Postgres).
- Add 11 (the rest): export a chat, a public read-only link to a chat, using Phase 5's sharing.

### Stage 8: making more, and knowing more (each item its own short plan)

- Library plan Phase 6: sites and games with real assets, the "+" in the Library, sound, duplicate.
- Add 2: finished documents (editable slides, docs, spreadsheets with a preview).
- Add 3: pages that take input (forms, stored data, webhooks). Changes D-119.
- Fix 19, then Add 5: a real PDF parser with scanned pages, then knowledge connectors in the app
  with continuous sync.
- Add 6: meeting notes through Fireflies, Granola or Circleback, with an "after a meeting" trigger.

### Alongside, when a stage touches the same code

- Self-hosting: Fix 20 (local models priced at zero, local memory search), Fix 21 (limits, log
  rotation, disk quota), Add 7 (guided local models).
- Small server fixes: Fix 22 (push tokens), Fix 23 (sign-in refresh lock).
- Operations: Improve (agent) 9 (alerts that reach someone, a worker health check).
- App polish: Improve (app) 4–7 (shortcuts, inbox paging, an app picker, accessibility).
- Add 8: more languages, starting with a language switch.
- Add 12, 13, 15: two accounts of one app, start by text, SOC 2 and a data processing agreement.

## Decisions for Oliver

Each has a default. Say nothing and the default holds.

| # | Question | Default |
|---|---|---|
| 1 | Where is the launch line? | After Stage 3 |
| 2 | The Library plan's 13 questions (§14 there): name, third tab, tab order, kept files, deleting a chat, caps, and the rest | Its defaults: Library, third tab, Chats / Library / Tasks, keep files, deleting a chat keeps what was made, 1 / 10 / 50 / 200 GB |
| 3 | Pricing against Rakazo (same $15 / $49 / $99, bigger computers, no markup) | Keep D-249 until Stage 5, then decide computer size and the 1.4 markup with real usage |
| 4 | Charge for failed runs? | No, from Stage 5 |
| 5 | Revisit what D-123 cut (driving the person's own browser, meeting bots)? | No; meeting notes come through connected apps in Stage 8 |
| 6 | Other AI subscriptions besides ChatGPT? | No |
| 7 | Widen the guard after untrusted content (D-213)? | Decide in Stage 4 with eval results |
| 8 | Pages that take input (changes D-119)? | Yes, in Stage 8 |

## Rules while building

The ones in `AGENTS.md` and the execution brief of `docs/ANALYTICS-PLAN.md`: ask before any Flutter
build and any production change, stage by path, format only new Dart files, migrations up only,
never reset the local database, privacy page and docs in the same commit as the code they describe,
every paid dependency in `docs/COSTS.md`.

Each stage: tests first for the fixes, a commit per item, the stage's check, then a short summary.
"Reported" items in the review are re-read in the code before they are fixed; one that turns out
wrong is struck from the review, not built.
