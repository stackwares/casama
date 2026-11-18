# Making credits last: plan

Status: **built on 2026-11-17 as D-354 (step 1) and D-355 (steps 2 to 8), not deployed. Step 9
is not built: it turned out to be false on Casama Cloud (section 9).** Oliver took every default
in section 7 and asked for all of it in one go. What was built differs from this plan in a few
places, listed in section 9; the rest of the page is the plan as written.
Steps 7 to 9 were added on 2026-11-17 from the self-hosting question (a separate session; Oliver
asked for both lists to be one plan).

## 0. Summary

People's credits run out fast. We measured why on production (2026-11-13 to 17: 218 runs, 5
workspaces, $4.73 charged) and confirmed each cause with test calls.

| Share of spend | What | Main cause |
|---|---|---|
| 45% | Chat messages | About 10 model calls a message, each re-sending about 25,000 tokens, on providers 2 to 8 times dearer than we assumed |
| 22% | Voice calls | Every turn is billed the whole call so far, including 3,700 tokens of tool definitions |
| 21% | Check-ins (scans and briefs) | 15 of 39 scans ended with nothing to show; no scan is ever skipped |
| 8% | Images | Priced per image; not in this plan |
| 4% | Other routines, computer time | |

The steps, in the order I'd build them (biggest saving first; 7 to 9 are a decision and two
options):

| Step | What | Expected saving | Size |
|---|---|---|---|
| 1 | Cheapest provider first on our key | About half of model spend (measured by replay) | **Built** |
| 5 | Check-ins: no wasted scans, fetch first, skip unchanged | A scan from about $0.024 to under $0.008 | Medium |
| 6 | Voice: smaller tool set, earlier trimming | Estimate: about half per minute; needs one measured call | Small |
| 3 | A fixed budget for a task's own steps | About 16% of input tokens | Small |
| 2 | Keep the prompt cache: tool loading, and history between messages | Estimate: 5 to 10% of chat spend, more in long chats | Medium |
| 4 | Smaller always-sent tools | About 2,000 tokens off every call | Small |
| 7 | Keep DeepSeek V4.1 Flash; no model of our own | Avoids $600 to $800 a month | Decided, nothing to build |
| 8 | A faster provider for live chat only (optional, off) | None: about 3 times the chat model cost for about 2.4 times the speed | Small |
| 9 | Point heavy users to their own AI | Their runs cost us nothing | Small, needs an app change |

Only step 1's saving is measured. The others are estimates from the same production data, and
each phase ends by measuring again (section 6).

Steps 1 to 8 are on the server and need no app build. Step 9 changes the app. Two small
migrations (steps 2 and 5).

## 1. What we measured

- **Input is the cost.** 37.8M input tokens against 0.57M output; input was 84% of model spend.
  87% of input was the previous step's context sent again.
- **Run length.** A chat message took 9.8 model calls on average. Messages with 26 or more calls
  were 12 runs and 36% of chat spend; most stopped at the 40-step limit.
- **Refusals.** 29 of 218 runs were refused at the daily limit (`cloud_daily_cap`): 21 chat
  messages, 5 scans, 3 calls. That is what a person sees when credits "burn".
- **Check-ins.** 39 scans: 24 finished ($0.011 each), 10 hit the 8-step limit after spending $0.015
  each and reported nothing, 5 stopped at the daily limit. 163 app reads at $0.0028 each. With a
  scan every 12 hours and a daily brief, a Free workspace spends about $0.065 a day on check-ins,
  about $1.95 a month, against $1 of monthly credits and a $0.25 daily limit shared with chat.
  Four of the six bots with check-ins are on Free.
- **Voice.** 745 seconds of calls cost $1.07, $0.086 a minute. A 155-second call was billed
  83,000 text and 27,000 audio input tokens, for about 3,900 tokens of actual speech.
- **Follow-ups.** 52% of follow-up messages arrive within 2 minutes of the last one, 65% within 5.

Not a cause: memory (at most 8 notes a message; saving new ones is 1.5% of spend), rules (approval
rules, never in the prompt), knowledge (read on demand), skills (3 enabled per workspace on
average), chat history (already capped at 16,000 tokens, D-253).

## 2. What exists today

| Area | Where | What it does |
|---|---|---|
| Provider routing | `packages/agent/src/gateway/openrouter.ts` | D-354: `provider.sort = "price"` on the shared key; `CLOUD_MODEL_PROVIDER_SORT`, `CLOUD_MODEL_PROVIDERS` |
| Prompt | `packages/agent/src/context.ts:201` (`buildContext`) | Rules, persona, computer text, skills, date and time, person, project, memories, summary; then history and the message |
| Tool loading | `packages/agent/src/lazy-tools.ts`, `run.ts:1350` | Over 30 tools: 15 core tools (4,922 tokens) and an index; `tools.load` adds groups to the tool list mid-run |
| Trimming a run | `context.ts:352` (`trimTurn`) | Cuts old tool results at 75% of the model's window: about 786,000 tokens on a 1M model, so never |
| Check-ins | `packages/agent/src/checkins.ts`, `apps/server/src/worker/routines.ts:153` | Scan every N hours, brief daily, event scans; 8 steps; every allowed tool sent on every step; memory saved after every scan |
| Voice session | `apps/server/src/worker/voice.ts:284`, `packages/agent/src/voice.ts:389` | Instructions, persona (up to 20,000 characters), up to 8,000 characters of earlier turns, 18 tools (about 14,900 characters); trimming at 32,000 tokens down to 16,000 |
| Limits | `packages/domain/src/cloud-models.ts:51`, `checkins.ts:513` | $0.25 a day on Free, $10 on paid plans; a bot's check-in limit is checked only before a run starts |

## 3. What the platforms allow

Checked with live calls on the Casama OpenRouter key unless a source is named.

- **OpenRouter spreads calls unless told otherwise.** Our default model has 50 providers, $0.036
  to $0.60 per 1M input tokens. `sort: "price"` tries the cheapest first and turns the spread off.
  `order` names providers to try first.
- **Each provider has its own cache.** A call that lands on a new provider pays full price.
- **Providers keep a prompt cached for at least 12 minutes.** All six we tried, the cheapest
  included (section 3.1). So the cache can hold from one message to the next, not only inside a
  run: 78% of follow-up messages arrive within 10 minutes.
- **The tool list comes first in the prompt.** Adding one tool gave 0 cached tokens: the whole
  context is billed again. Changing the end of the system text kept only the tools cached. Adding
  a message at the end kept everything.
- **OpenRouter keeps a conversation on one provider once a cache is in use**, and a `session_id`
  starts that earlier (OpenRouter's prompt caching guide). Not yet tried by us.
- **Gemini Live bills every turn for the whole session so far**, and has no prompt cache
  (developer forum reports and a Google staff reply; our own numbers match). Whether trimming the
  session lowers the bill is not documented, so step 6 measures it. Firebase's own example trims
  at 10,000 tokens down to 2,000.

### 3.1 Cache lifetime by provider

One prompt of 8,000 tokens per provider and interval, sent once and sent again after the wait.
"Hit" means the second call was billed as cached (7,680 to 8,022 of 8,023 tokens).

| Provider | 1.5 min | 3 min | 6 min | 12 min |
|---|---|---|---|---|
| Wafer (the cheapest; where `sort: price` sends us) | hit | hit | hit | hit |
| DeepInfra (fp8) | hit | hit | hit | hit |
| Morph (fp8) | hit | hit | hit | hit |
| Sail Research | hit | hit | hit | hit |
| PrimeIntellect | hit | hit | hit | hit |
| Ionstream (flex) | hit | hit | hit | hit |

Wafer was tried at more intervals: hits at 10, 30, 60 and 90 seconds and at 5 and 10 minutes, and
one miss at 2 minutes. So a cached prompt is usually there, not always; one miss in eleven tries.
No provider outlasted another in this test, so cache lifetime doesn't change which is cheapest.

## 4. The changes

### Step 5. Check-ins

1. **A scan that runs out of steps still reports.** Today it fails with nothing
   (`max_steps_exceeded`); chats get one last turn without tools (`run.ts:1017`). Scans get the
   same, and the scan instructions say how many steps there are.
2. **Fetch first, think once.** For Gmail, Outlook and Google Calendar the worker reads the
   usual things itself before any model call (the newest 10 messages without bodies, the next two
   days of calendar) and puts them in the task. The model judges in one or two calls, not 6.6.
   Other connected apps keep today's tool loop.
3. **Skip a scan when nothing changed.** The worker hashes what it fetched (ids and changed
   times) and keeps it in a new column, `bot_checkins.scan_digest`. Same hash and no event note:
   the scan ends without a model call, at the price of the reads. Watchers already work this way
   (D-116).
4. **No memory pass after a quiet scan.** Today one runs after every scan, also after
   `NOTHING_NEW` (`run.ts:3509`).
5. **Check the limit during a scan**, not only before it (`checkinCapReached` joins `checkRun`).
6. **Leave room for the person.** Check-ins stop at a share of the day's limit, so a scan can't
   use up what the person's own messages need. Default 40% (decision 3).
7. **Check-ins use the background model on Casama Cloud.** `run.ts:522` replaces the whole model
   policy and drops the swap made at `run.ts:2121`. Same model today, so no saving yet; the Admin
   setting then does what it says.
8. **Free plan defaults** (decision 2).

Done when: 50 production scans average under $0.008 with app reads, none ends with nothing, and
a quiet workspace's scheduled scans make no model call.

### Step 6. Voice calls

1. **A smaller tool set on calls.** Four tools are two thirds of the tool text:
   `routines.create`, `routines.update`, `watchers.create`, `device.read`. Calls keep short
   versions of the first and last (set a reminder; read the calendar) and send the rest through
   `start_task`, which already runs bigger jobs in the chat. Target: under 1,200 tokens of tools.
2. **Less carried in.** Persona cut to its first 1,500 characters on a call; earlier turns from
   8,000 characters to 2,400.
3. **Trim sooner.** `contextWindowCompression` from 32,000 → 16,000 tokens to 8,000 → 3,000
   (decision 4), as a server setting instead of a literal (`packages/agent/src/voice.ts:440`).
4. **Measure with one scripted three-minute call before and after**, and compare our count with
   Google's bill. This also settles whether our per-response counts add up correctly.

Done when: the same scripted call costs at most half of today's, and `docs/COSTS.md` carries the
measured rate.

### Step 3. A fixed budget for a task's own steps

`trimTurn` gets a fixed budget, as history did in D-253: once a run's own steps pass 48,000
tokens, the oldest tool results are cut to their first lines until 24,000 remain. The newest four
results stay whole, as today. The share-of-window rule stays for small models. One trim re-bills
the kept context once (about $0.001), so the two-to-one gap keeps trims rare.

In production 301 of 1,527 model calls carried more than 45,000 input tokens, and the tokens above
that line were 16% of all input.

Done when: no step in a 40-step test task sends more than about 60,000 tokens, and the eval
success rate doesn't drop.

### Step 2. Keep the prompt cache

1. **A conversation remembers its tool groups.** New column `conversations.tool_groups`. A run
   starts with the groups this conversation loaded before (the six most recent, sorted), so it
   needs no `tools.load` call and its tool list matches the last message's.
2. **Send a `session_id`** (a hash of the conversation id) on the shared key, so OpenRouter keeps
   the conversation on one provider when the cheapest one is busy.
3. **Experiment, behind a setting:** `tools.load` returns the definitions as text and the bot
   calls them through one fixed `tools.call` tool, so the tool list never changes. Only if 1
   leaves more than one run in ten loading tools mid-run, and only if evals hold (decision 6).
4. **Keep history cached between messages.** Today the system text holds the time to the minute,
   the recalled memories and the turn's hints, so it changes with every message and everything
   after it (the whole history) is billed fresh. They move to a marked block in front of the
   newest message, after the history; the system text then stays the same for a whole
   conversation. On this week's traffic that is about 1.5% of model spend, because most chats
   were short. In a long chat it is up to 16,000 tokens a message read at $0.01 instead of $0.036
   per 1M, which is up to about 40% of what a one-step message there costs.

Done when: a second message in a conversation makes no `tools.load` call; cached tokens are at
least 80% of input on steps after the first; and a follow-up within 10 minutes is billed its
history as cached.

### Step 4. Smaller always-sent tools

- `ui.show` is 2,270 of the 4,922 core tokens: its description lists every component. Keep it in
  core with the common components (text, rows, buttons, choices, tables) in about 700 tokens; the
  rest (maps, drafts, events) come from a `ui.catalog` read the bot calls when it needs them
  (decision 5).
- `connections.offer`, `secrets.request` and `setup.apply`: 1,119 tokens together, to about 500.

Done when: the core tools are under 3,000 tokens and the `ui.show` eval tasks still pass.

### Step 7. Keep DeepSeek V4.1 Flash; no model of our own

Decided 2026-11-17: Casama Cloud stays on per-token open models. Nothing to build.

- **The production server can't run one.** 6 cores without AVX2, no graphics card, 12 GB of
  memory with 9 GB kept for people's computers. Our calls carry about 25,000 input tokens.
- **A rented GPU costs 60 to 160 times the bill it replaces.** A 48 GB card that holds a 27B
  model and our prompts is $600 to $800 a month. Model spend is about $10 a month today, about $5
  after step 1. Break-even is roughly 2,500 to 5,500 runs a day; we have about 44.
- **It would be a weaker model.** DeepSeek V4.1 Flash is open-weight (MIT) and far larger than
  anything one GPU holds; Qwen3.8-27B is much weaker at long tool-using runs.
- **It wouldn't touch voice (22% of spend) or images (8%).**
- **Training our own waits.** Fine-tuning a small model needs thousands of example runs from
  people who agreed to it (we have 218 runs in all), and the result needs the GPU above.

Look again when traffic holds above about 3,000 runs a day, or when a customer needs their data
kept on our servers. Then start with a scale-to-zero serverless GPU running Qwen3.8-27B (Apache
2.0) on its own machine, not the VPS.

### Step 8. A faster provider for live chat only (optional, off by default)

The cheapest provider answers at about 70 tokens a second, first word in 0.9 s. With
`sort: throughput` the same model came from Crusoe at 171 tokens a second, and that call cost 2.7
times more (one sample each, a 300-word answer). Replaying production chat traffic at Crusoe's
prices gives about 3 times the cost ($2.33 against $0.79).

- A new setting, `CLOUD_MODEL_CHAT_SORT` (unset by default), applies only to the model steps of
  runs a person is waiting on: chat, mentions and chat apps.
- Check-ins, routines, summaries, memory, the reply check, the support assistant and the Link
  proxy stay on the cheapest provider.
- In-between steps are short and already quick on the cheapest route (median 1.0 s in our test).
  Speed shows mainly on long final answers, so measure a real chat before turning it on.

Done when: with the setting on, chat steps go to the fast provider and every other call still
goes to the cheapest; with it unset, nothing changes.

### Step 9. Point heavy users to their own AI

Three ways to run bots cost us nothing: a ChatGPT plan, the person's own model key, and a local
model through Ollama (D-330). Onboarding already offers them first (docs/COSTS.md). When someone
reaches their daily limit or runs out of credits, the limit message and the paywall get one more
line and button: use your own AI instead. A product decision (decision 11); low priority.

Done when: the limit message and the paywall offer it, and choosing it opens the model set-up.

## 5. Not in this plan

- **Another default model.** GLM-5.3 Flash answered faster and far cheaper in one speed sample
  (118 tokens a second, $0.000034 against $0.000234), and the cloud model changes in Admin
  without a deploy (D-188). Its tool use is untested, so it needs an eval run before anything.

- **Thinking level.** After step 1, output is about a third of model cost and about a quarter of
  output is thinking (`DEFAULT_REASONING_EFFORT=medium`). Lower thinking on in-between steps could
  save 5 to 9%, but it trades quality. Worth an eval run later (decision 7).
- **People's own OpenRouter keys.** Unchanged; their account's routing wins (decision 8).
- **Images** ($0.054 each) and **app reads** ($0.0028 each): priced per use; D-350 already moves
  Zoho off the per-call price.
- **Showing people where credits went.** D-353 (usage by source) is being built separately.

## 6. Phases

Each phase is one commit and one deploy (with Oliver's yes), and ends with the same production
queries used for section 1.

| Phase | Contains | Done when |
|---|---|---|
| 0 | Deploy step 1 (D-354) | A day of production calls: at least 90% on the cheapest provider, model cost per call about half |
| 1 | Step 5, items 1, 4, 5, 6, 7 | No scan ends with nothing; check-ins never pass their share of the day |
| 2 | Step 5, items 2, 3, 8 | Scans under $0.008; quiet scheduled scans make no model call |
| 3 | Step 6 | The scripted call costs at most half |
| 4 | Steps 3 and 4 | No step over about 60,000 tokens; core tools under 3,000 |
| 5 | Step 2, items 1, 2 and 4; then the decision on item 3 | Second messages make no `tools.load` call; a follow-up's history is billed as cached |
| 6 | Step 8, only if decision 10 is yes | Chat steps on the fast provider, everything else on the cheapest |
| 7 | Step 9, only if decision 11 is yes; needs an app build | The limit message and the paywall offer it |

## 7. Decisions for Oliver

Defaults in bold. Say "defaults" to take them all.

| # | Decision | Options |
|---|---|---|
| 1 | Deploy step 1 now? | **Yes** (dry run first, as always) / wait |
| 2 | Check-ins on Free | **One scan a day and the daily brief** / as today (two scans and a brief) / brief only |
| 3 | Check-ins' share of the day's limit | **40%** / 25% / no share |
| 4 | Voice trimming | **8,000 → 3,000 tokens** / 16,000 → 6,000 / leave at 32,000 → 16,000 |
| 5 | `ui.show` | **Short version in core, the rest on request** / move it out of core / leave |
| 6 | The `tools.call` experiment | **Only if step 2 item 1 isn't enough** / build it now / never |
| 7 | Thinking level on in-between steps | **Leave at medium for now** / run evals at low |
| 8 | Cheapest-first for people's own OpenRouter keys | **No** / a switch per key |
| 9 | Provider order on our key | **Decided 2026-11-17: cheapest first** (Wafer through OpenRouter; fastest in our test). The other option was fuller-precision providers first (`deepinfra/fp8`: same cost on replay, about twice as slow) |
| 10 | A faster provider for live chat (step 8) | **Off; build the setting later if chat feels slow** / build the setting now, off / on |
| 11 | Offer "use your own AI" at the limit (step 9) | **Yes, one line and a button in the limit message and paywall** / paywall only / no |

## 8. Risks

- **The cheapest provider runs a 4-bit copy of the model.** Our 12-task check found no
  difference, but it is a small sample. `CLOUD_MODEL_PROVIDERS` changes the order without a deploy
  of code, and `CLOUD_MODEL_PROVIDER_SORT=off` undoes it.
- **One provider carries most calls.** If it fails, OpenRouter moves to the next cheapest; that
  step pays full price once.
- **Trimming loses detail.** A bot late in a long task sees only the first lines of early
  results. Large outputs are already saved to a file on its computer, and the note tells it to run
  the step again.
- **Fetch-first covers three apps.** Other apps keep the slower loop, so their scans save less.
- **A voice call forgets sooner.** With trimming at 8,000 tokens, a long call drops its earliest
  turns after a few minutes. Transcripts are still saved to the chat.
- **Fewer scans on Free means later suggestions.** Event scans stay off on Free as today.
- **Memories next to the person's message.** Notes a bot saved are facts, not orders (D-269).
  Moving them from the system text to a block in front of the newest message must not make the
  model treat them as the person's instructions: the block keeps that wording, and the injection
  eval has to pass before step 2 item 4 ships.
- **The speed numbers are one sample each.** Step 8 measures a real chat before anyone turns it
  on, and people pay the higher price from their credits.
- **"Use your own AI" next to a paywall.** Check the App Store and Google Play rules before it
  ships there; on the web and desktop there is no such question.

## Sources

- OpenRouter: provider routing (openrouter.ai/docs/features/provider-routing), prompt caching
  (openrouter.ai/docs/guides/best-practices/prompt-caching), the model's provider list
  (openrouter.ai/api/v1/models/deepseek/deepseek-v4.1-flash-1017/endpoints), read 2026-11-17.
- Google: Live API best practices (ai.google.dev/gemini-api/docs/live-api/best-practices),
  Firebase "Manage sessions for the Live API" (firebase.google.com/docs/ai-logic/live-api/sessions),
  and developer forum threads on per-turn billing (discuss.ai.google.dev, threads 173248 and
  181691). The forum threads are reports, not documentation.
- Our own numbers: production `usage_ledger` and `runs`, 2026-11-13 to 17, read-only; test calls
  on the Casama OpenRouter key, 2026-11-17.
- Steps 7 and 8: the self-hosting session's hardware check, GPU rental prices
  (thundercompute.com/blog/nvidia-rtx-5090-pricing, gpuperhour.com) and speed samples, 2026-11-17.

## 9. What was built, and where it differs

Built as planned unless listed here. The decision log has the details (D-354, D-355).

| Step | Difference from the plan |
|---|---|
| 2 | Memories stay in the system text (sorted, so the same notes make the same text). Only the date and time, the project and the turn's hints moved next to the newest message. In 36 live calls each way the default model never obeyed an order planted in a note, but the system placement is the one that has held across the models people bring, and the saving was small. |
| 2 | The `session_id` is per run, not per conversation, so a conversation can't stay pinned to a dearer stand-in provider. |
| 2 | The `tools.call` experiment is not built (decision 6). |
| 5 | Fetch-first reads Gmail, Google Calendar and the board. Outlook is not included: there was no account to check its tool's arguments against. |
| 5 | Check-ins do not move to the cloud's background model: the shared key allows only the chat model, both are the same model today, and widening that rule is a billing decision of its own. |
| 5 | Free's floor went from 12 to 24 hours, which needed two extra fixes: a once-a-day scan runs six hours after the brief (midnight is inside quiet hours, where scheduled scans are skipped), and saving the check-in sheet with an old value below the new floor raises it instead of refusing. The app's picker gains 24 hours. |
| 4 | Core tools are 2,972 tokens (the target was under 3,000). The three smaller tools came to 719 tokens, not about 500: their schemas alone are about 470. To get there, no tool's schema carries the `$schema` line any more. A table card now takes one `ui.catalog` lookup first. |
| 6 | The two trim settings count the conversation only; an estimate of the instructions and tools is added before they go to Gemini, which counts that fixed part too. Measured with six text turns: 62% fewer prompt tokens. A ten-turn spoken call (D-357): $0.055 a minute before, $0.038 after, at Google's prices; what's left is mostly the call's own audio so far. Gemini's prompt total is larger than the per-kind counts we charge from; each call now records both, so one day's invoice can show which Google bills (at most 7% of a call's cost). |
| 9 | **Not built.** On Casama Cloud every run uses Casama's key and model (D-188) and the limits apply whatever the key, so "use your own AI" would be false there. The texts that already said "add your own model key" on Cloud are corrected. Own AI on Cloud needs a decision and its own plan. |

Still to do after the deploy: measure each step on production with the queries behind section 1,
and compare one day's invoice from Google with the two prompt counts recorded on each call
(D-357).
