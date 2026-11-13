# Product review, 2026-11-13

What to fix, improve and add in Casama, and how it compares with competitors. Read-only: no code was
changed, nothing was built or deployed. Production was only read.

**How this was done**

- Two code reviewers read the Flutter client and the backend (nothing was run). I re-read the
  findings marked **checked** myself; the rest are the reviewers' and are marked **reported**.
- Three researchers read competitors' live pages on 2026-11-13. Reddit, G2 and openai.com could not
  be fetched, so user sentiment comes from GitHub issues, Trustpilot, Hacker News and review sites.
  Prices marked *third-party* were not on a page the vendor publishes.
- The app itself was not run (a build needs your yes), so the app findings come from code.
- Production has no usage to learn from yet: 2 accounts, 2 bots, 5 runs, all completed. Nothing
  below comes from real failures; it comes from reading code and from research.

## The short version

Casama's feature list is already wider than any single competitor's. The gap is not features; it is
that a run can still die for avoidable reasons, the chat screen has a few sharp edges, and three
things competitors now lead with are missing or thin: a proper Slack/Teams/Discord presence,
finished documents, and pages that take input.

Order I'd work in:

1. Make runs survive (Fix 1–5 below).
2. Confirm and close the two data-safety items (Fix 6–7).
3. Chat basics in the app (Fix 9–14).
4. Let the bot see, edit files in place and run tools in parallel (Improve 1–3).
5. Slack app, then Teams and Discord (Add 1).
6. Finished documents and pages that take input (Add 2–3).
7. Cost clarity: bot spending limit in the app, a price before long runs, no charge for failed ones
   (Add 4), and a look at computer size and markup against Rakazo (Pricing).

## Fix

### Runs and the agent

| # | What a person sees | Evidence | Status |
|---|---|---|---|
| 1 | Approve a request more than 30 minutes after the run started and the bot does that one action, then fails with "took longer than its time limit". The limit counts time spent waiting for the person; an approval can wait 24 hours. | `packages/agent/src/run.ts:1847`, `packages/domain/src/budget.ts:90`, `packages/domain/src/approvals.ts:54` | checked |
| 2 | A model that thinks for more than 60 seconds before writing is cut off, retried once, then the run fails. Only text and tool calls reset the timer; thinking output is dropped. | `packages/agent/src/gateway/fallback.ts:32,51-59`, `packages/agent/src/gateway/ai-sdk.ts:203-216` | checked |
| 3 | A long answer or a large file write is cut off mid-way and treated as finished. Casama Cloud caps output at 4,096 tokens and the run loop never reads why the model stopped. | `packages/domain/src/cloud-models.ts:39`, `packages/agent/src/gateway/types.ts:127-140` (nothing in `run.ts` reads it) | checked |
| 4 | Long tasks fill the model's context and fail. History is summarized before a run, but inside a run every tool result is resent, with no recovery from a "context too long" error. | `packages/agent/src/run.ts:773`, `packages/agent/src/context.ts:233-238` | checked in part |
| 5 | One provider hiccup after output has started fails the whole run, and there is no way to resume it, so the work is lost. Runs stuck in `running` are never swept (only `queued`). | `packages/agent/src/gateway/fallback.ts:36-41,85`, `apps/server/src/worker/workflows.ts:174,416-426` | reported |
| 6 | **Confirm first.** Backups hold the database dump and `.env` but not the volume with the Vault key, so secrets would not restore on a new machine. Production runs with backups on. | `infra/backup/backup.sh:73-79`, `infra/compose/docker-compose.yml:177` | reported, key location inferred |
| 7 | **Confirm first.** The workflow engine stores each step's output (history, replies, tool results) in plain text, outside encryption at rest, deletion and retention, and nothing cleans it up. That would break the "a database dump shows no message text" claim. | `apps/server/src/worker/workflows.ts:174`, `apps/server/src/worker/index.ts:547-558`; compare `packages/agent/src/events.ts:31-43` | reported |
| 8 | A worker restart runs the in-flight tool again; a deploy that changes the step order fails runs waiting on an approval. | `packages/agent/src/run.ts:1135`, `apps/server/src/worker/workflows.ts:111-115` | reported, inferred from the engine's behaviour |

### The app

| # | What a person sees | Evidence | Status |
|---|---|---|---|
| 9 | A chat that fails to load shows placeholder bubbles forever, with no error and no retry. It happens whenever nothing is cached, which on the web is always. | `client/lib/features/chat/chat_controller.dart:395-449`, `client/lib/features/chat/chat_screen.dart:428-436` | checked |
| 10 | Only the last 500 messages show, with no way to load earlier ones, and the whole thread downloads on every open. This matters more now that each bot has one long main conversation (D-253). | `client/lib/core/supabase_backend.dart:1299-1323` | checked |
| 11 | A message that failed to send ("Try Again") disappears when the chat reloads. | `client/lib/features/chat/chat_controller.dart:289-342,540-547` | reported |
| 12 | Retry after a failed run resends only the text: attachments, picked skills and card answers are dropped, and a files-only message can't be retried. | `client/lib/features/chat/chat_controller.dart:522,577-580`, `client/lib/features/chat/chat_screen.dart:1536-1570` | reported |
| 13 | A message you just sent can't be edited until you reopen the chat. | `client/lib/features/chat/chat_controller.dart:518,553-555` | reported |
| 14 | The web app keeps no drafts: switching bots clears what you typed. | `client/lib/core/local_cache.dart:84-86` | reported |
| 15 | Sharing a photo or file into Casama on Android delivers only its file name; the iPhone share extension passes text only. | `client/lib/core/mobile_extras.dart:52-56`, `client/lib/features/quick_ask/quick_ask_screen.dart:68-90` | reported |
| 16 | Windows and Linux get no push, and no platform shows an in-app alert when an approval arrives while the app is open. Only badges change. | `client/lib/core/push.dart:128-130` | reported |
| 17 | An attachment can upload to a computer the bot doesn't use: the app falls back to any computer in the workspace, the server never does. | `client/lib/features/chat/chat_screen.dart:58-69`, `packages/agent/src/computers.ts:131-141` | reported |

### Chat apps, knowledge and self-hosting

| # | What a person sees | Evidence | Status |
|---|---|---|---|
| 18 | Chat apps on real traffic: a redelivered webhook starts a second run; Feishu asks for an encrypt key but never decrypts; inbound email with no body in the webhook is dropped; long replies are cut and attachments ignored. | `apps/server/src/api/routes/channels.ts:30,249-254`, `packages/agent/src/channels/adapters.ts:106,137-142,217,334,371,381-410` | reported |
| 19 | Most uploaded PDFs index as empty. The parser is a regular expression over literal text strings; exported PDFs mostly use hex strings and font maps, and scanned PDFs aren't read at all. | `packages/agent/src/knowledge-parse.ts:161-202` | checked that it is a regex parser; impact inferred |
| 20 | Local models: a model name outside a short list is priced at $1/$3 per million tokens against the default $1-a-run budget, so a free local model can stop for "budget". Memory search needs an OpenAI key and fails silently without one. | `packages/agent/src/gateway/registry.ts:35-42,109`, `packages/agent/src/credentials.ts:280-298`, `packages/agent/src/memory.ts:43` | reported |
| 21 | A self-hosted server can fill itself: no default limit on computers, no log rotation, no per-computer disk quota. | `infra/compose/docker-compose.yml:97,405`, `packages/sandbox/src/docker/provider.ts:296-311` | reported |
| 22 | Push tokens are deleted on any 400 from the push service, so one bad payload can silently unsubscribe a phone. | `packages/agent/src/notifications.ts:125,144` | reported, effect inferred |
| 23 | Two runs refreshing the same sign-in at once can invalidate a rotating token. | `packages/agent/src/integrations.ts:759-777` | reported, effect inferred |

## Improve

### The agent

1. **The bot can't see.** `browser.screenshot` saves a file and returns its path; tool results are
   text only, so a vision model never gets the picture. `packages/agent/src/tools/computer.ts:342-364`,
   `packages/agent/src/gateway/types.ts:42`. Checked.
2. **No in-place file edits.** The file tools are read, write, list and search. Changing one line
   means rewriting the whole file, which is slow and runs into the output cap (Fix 3).
   `packages/agent/src/tools/computer.ts:102-170`. Checked.
3. **One thing at a time.** Tool calls run in sequence and a sub-agent blocks its parent.
   `packages/agent/src/run.ts:944`, `packages/agent/src/tools/autonomy.ts:817`. Reported.
4. **Memory is shallow.** Extraction sees only the person's message and the final reply, never the
   work in between. Nothing retires a fact that was later contradicted, and recall has no relevance
   floor. `packages/agent/src/run.ts:2674-2681` (checked), `packages/agent/src/memory.ts:23,76-89`
   (reported).
5. **The bot forgets its own work between messages.** History carries text only, capped at 16k
   tokens, then a 300-word summary; earlier tool results and images are not resent.
   `packages/agent/src/context.ts:10-11`. Reported.
6. **Claude models never get a thinking-effort setting.** An early return for prompt caching skips
   it. `packages/agent/src/gateway/ai-sdk.ts:72`. Checked.
7. **The prompt-injection guard is narrow.** After untrusted content only medium-risk tools that
   send something out ask first (D-213 chose this). Shell commands, GET requests, saving a memory and
   creating a routine stay open, and saved memories enter the system prompt unwrapped.
   `packages/domain/src/approvals.ts:49`, `packages/agent/src/context.ts:175-178,220`. Reported.
8. **Evals gate nothing.** 30 tasks with rule-based checks; only a 3-task live run was ever recorded,
   so the nightly run can't fail. No tasks for long-context work, recall, desktop, chat apps, voice
   or integrations. `packages/evals/baseline.json`, `packages/evals/src/run.ts:254-270`. Reported.
9. **Operations are blind.** Alert rules exist but nothing delivers them; the worker has no health
   check; no disk, database or backup alerts. `infra/monitoring/alerts.yml:2`,
   `infra/compose/docker-compose.yml:368`. Reported.

### The app

1. **Routines can't be edited.** You can run one, switch it on or off, change when it ends, or delete
   it, but not change its time or instructions, and there is no run history per routine.
   `client/lib/core/backend.dart:995-1016`. Checked. (`routines_screen.dart` has uncommitted edits,
   so this may be in progress.)
2. **Topics can't be renamed, searched or pinned.** The chat API has no update operation.
   `client/lib/features/chat/chat_screen.dart:2140-2230`. Reported.
3. **Memory has no search and no "add a memory".** `client/lib/features/memory/memory_screen.dart:23-85`. Reported.
4. **Keyboard shortcuts are Cmd/Ctrl+K and Enter only**; no Esc to stop a run, and Windows, Linux
   and web have no New chat or Settings shortcuts. `client/lib/features/home/home_shell.dart:221-226`. Reported.
5. **The inbox shows the newest 100 notifications**, with no paging and no per-item dismiss.
   `client/lib/core/supabase_backend.dart:1878-1884`. Reported.
6. **Watched apps need a typed Android package id** (`com.mybank.app`) instead of an app picker.
   `client/lib/features/devices/device_connections_screen.dart:470-473`. Reported.
7. **Accessibility:** text size stops at 1.3x on purpose (D-191), so larger accessibility sizes are
   ignored; five icon buttons have no label; right-to-left layouts aren't ready. Reported.

**Checked and fine:** no stubs or "coming soon" screens; every roadmap row has a screen; drafts on
phone and desktop, drag-and-drop, send-while-working, stop, upload retry, branches, offline cached
thread; live view fallbacks; reduced motion; no hard-coded strings; no skipped tests.

## Add

Ranked by how often competitors lead with it and how often their users ask for it.

| # | Feature | Who has it | Where Casama stands |
|---|---|---|---|
| 1 | **A real Slack app, then Microsoft Teams and Discord.** One-click install, @mention in any channel, approvals, progress and files in the thread. | Viktor, Lindy, Claude Tag, Gumloop, Devin; OpenClaw lists 33 channels, Hermes 28 | 8 channels. Slack needs a pasted bot token per bot, is text only, and approvals happen only in the app. No Teams or Discord code (checked). |
| 2 | **Finished documents:** editable slides, docs and spreadsheets as first-class outputs with a preview. | Manus (native .pptx), Claude, ChatGPT, Genspark | Bots have LibreOffice and a PDF preview of Office files (D-205). |
| 3 | **Pages that take input:** forms, stored data, webhooks, and small apps on a public link. | Manus, Zo, Poke, Lindy Apps, Viktor Spaces, Kortix | Pages are static: D-119 blocks forms and network calls. |
| 4 | **Cost clarity and controls.** A bot spending limit in the app, a price before a long run, no charge for failed runs, usage by person, per-person caps, low-credit alerts, auto top-up. | Lindy, Dust, Viktor, Gumloop, Claude Tag | The server enforces per-run and daily bot budgets, but no screen shows or sets them (checked). Usage is by bot, model, day and kind. |
| 5 | **Knowledge connectors in the app with continuous sync,** and an auto-built company wiki. | Dust (70+ connectors), Lindy Brain, Gumloop | The app adds files, websites and GitHub; other sources are API-only and refresh daily (D-125). Fix PDFs first (Fix 19). |
| 6 | **Meeting notes without a meeting bot:** connect Fireflies, Granola or Circleback, an "after a meeting" trigger, team meeting folders. | Lindy, Notion, Dust; Claude Meetings (12 Nov) | Meeting bots were cut on purpose (D-123). This route doesn't reverse that. |
| 7 | **Guided local models:** install and size a local model for the machine, plus local memory search. | Hermes v0.22, OpenClaw beta | Takes an OpenAI-style endpoint only; see Fix 20. |
| 8 | **More languages.** | Hermes Desktop (5+ packs), Rakazo (Polish, Turkish) | English only. Strings are ready; it needs ARB files and a language switch (the Settings row is read-only). |
| 9 | **A research mode:** many sources in parallel into one sourced table. | Manus Wide Research | Sub-agents exist but run one at a time (Improve 3). |
| 10 | **A check before "done":** a separate verifier or completion contract. | Kortix, Hermes | None. Answers "it always thinks it did a good job". |
| 11 | **Small chat features:** paste an image into the composer, regenerate a reply, rate it, delete a message, find in this chat, export a chat, a public read-only link to a chat (OpenClaw). | most chat apps | Missing (`client/lib/features/chat/widgets/composer.dart:134-157`, `message_actions.dart:137-143`). |
| 12 | **Two accounts of one app** (work and personal Gmail). | Manus | Not found in SPEC or DECISIONS; not checked in code. |
| 13 | **Start by text with no install:** sign up from a phone number; hosted iMessage. | Poke, Meta Muse | iMessage needs the person's Mac online. |
| 14 | **Assign a Linear or Jira ticket to a bot** and get the report on the ticket. | Devin | The ticket board is Casama's own. |
| 15 | **Team trust paperwork:** SOC 2 Type I, a data processing agreement, SCIM. | Lindy, Dust, Viktor, Kortix | SSO/SAML and audit export only. |

**Cut on purpose, now common elsewhere** (your call to revisit, not a recommendation):

- **Driving the person's own browser** (D-123). Claude in Chrome, Gemini and Manus ship it; cloud
  browsers stall on bot checks and logins. The desktop companion covers part of it.
- **Other AI subscriptions** (Claude, Gemini, Grok through their local CLIs). OpenMausBot, Kortix and
  goose do this; Casama allows ChatGPT only, on purpose.
- **Web panels beside chat** (MCP Apps, OpenClaw). Conflicts with the no-WebView rule.

## Pricing against competitors

**Rakazo is the closest twin** (Apache-2.0, 8.2k stars, shipping a release nearly every day; v0.11.0
on 12 Nov) and uses the same three prices. From its pricing page, read today:

| | Rakazo | Casama (D-249) |
|---|---|---|
| $15 | 25 computer hours, 4 vCPU / 8 GB | 30 hours, size 1, $5 credits |
| $49 | 100 hours, 8 vCPU / 16 GB | 100 hours, size 2, $15 credits, 3 seats |
| $99 | 200 hours, 16 vCPU / 32 GB | 300 hours, size 4, $30 credits, 10 seats |
| Model usage | "Charged at the provider's price, with no markup" | markup 1.4 |
| Trial | 7 days with 10 computer hours | Free plan; 7-day Pro trial |

Casama gives more hours and includes credits; Rakazo gives much bigger computers and no markup. Its
page shows no seat, bot or concurrent-computer limits. Worth deciding whether Casama's story is
"credits included" or whether the computer size and markup need another look.

Others, per month:

| Product | Plans | Main limit |
|---|---|---|
| Manus | Free; $20; $40; $200 | 4,000 / 8,000 / 40,000 credits, no rollover *(third-party)* |
| Poke | Free; $19; $199 | rate limits unpublished |
| ChatGPT | $8; $20; Pro $100–$500 | always-on agent from Pro only *(third-party)* |
| Claude | $20; $100; $200 | limits shared across all Claude products |
| Zo | $18; $64; $200 | $10 / $40 / $100 AI credits |
| Lindy | from $29.99 per user | 3,000 credits per user |
| Viktor | $50–$200 per team | shared credits, no seat fee |
| Dust | €30 and €150 per seat | 8,000 / 40,000 credits per seat |
| Gumloop | $37 | 20k credits, unlimited seats |

Team note: Viktor and Gumloop charge no seat fee; Casama Plus has one seat.

## Where Casama already wins

Use these in marketing; each answers a complaint users make about a competitor.

- **You can watch and take over.** Claude's always-on agent "can't yet show you its browser".
- **Memory you can read and edit, and a choice of model** (self-hosted). OpenAI's agent offers neither.
- **Spending you control:** own keys, ChatGPT plan sign-in, budgets. The top complaint about Manus,
  Lindy, Viktor, Notion and Perplexity is unpredictable credit burn and paying for failed work.
  (This is why Add 4 matters: the controls exist on the server but not in the app.)
- **Real phone apps with push.** Hermes has no phone app; OpenMausBot's Android has no push.
- **Security built in:** hidden secrets, an egress proxy and a sandbox are OpenClaw's top-voted
  open requests.
- **It can't be taken away.** Relay.app shut down in September; Zapier is folding its Agents product
  into another; open source, self-hosting and export answer that.
- **No region locks.** Several big-lab agents are blocked in the EEA, UK and Switzerland.

## The market in one paragraph

Since August the large labs have each shipped an always-on agent with its own cloud computer (the
researchers list Grok Bot, Meta Muse, Manus 2.0, OpenAI's dots, Claude Duet and Gemini's Task mode),
and Notion gave its agents a computer and browser on 19 Oct. The shape Casama sells is now the
default. The open-source leaders are far ahead on reach (OpenClaw 394k stars, Hermes 263k) and on
ecosystem size (tens of thousands of skills), and they install with one command or a signed
download, where Casama needs Docker and Supabase. Casama's room is the middle: as capable as the lab
products, but open, watchable and under the owner's control.

## Sources

Competitor pages read on 2026-11-13:

- Rakazo: https://rakazo.com/pricing, https://github.com/elie222/rakazo/releases, https://github.com/elie222/rakazo/issues
- OpenClaw: https://github.com/openclaw/openclaw, https://docs.openclaw.ai/channels, https://docs.openclaw.ai/install
- Hermes Agent: https://github.com/NousResearch/hermes-agent/releases, https://hermes-agent.nousresearch.com/docs/user-guide/messaging/
- OpenMausBot: https://github.com/milind-soni/OpenMausBot
- Kortix: https://github.com/kortix-ai/suna
- Manus: https://manus.im/blog/product, https://manus.im/blog/introducing-manus-2-0
- Poke: https://poke.com/pricing
- Claude: https://claude.com/pricing, https://claude.com/blog/claude-duet, https://support.claude.com/en/articles/12138966-release-notes, https://www.anthropic.com/news/introducing-claude-tag
- Zo: https://docs.zocomputer.com/billing
- Lindy: https://lindy.ai/changelog, https://www.lindy.ai/pricing
- Viktor: https://viktor.com/changelog, https://viktor.com/pricing
- Dust: https://dust.tt/home/pricing, https://docs.dust.tt/changelog
- Gumloop: https://www.gumloop.com/changelog, https://www.gumloop.com/pricing
- Notion: https://www.notion.com/releases
- Zapier: https://zapier.com/blog/zapier-agents-is-now-ai-by-zapier/
- Devin: https://devin.ai/pricing
- User complaints: https://www.trustpilot.com/review/lindy.ai, https://www.trustpilot.com/review/getviktor.com, https://news.ycombinator.com/item?id=48648039, https://kilo.ai/articles/openclaw-vs-hermes-what-reddit-says, https://www.eesel.ai/blog/openai-dots-review, https://preuve.ai/blog/manus-ai-review
