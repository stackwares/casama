# Decision models: plan

Status: **not started** (written 2026-11-20). Waiting on the decisions in §12 and Oliver's go-ahead.
No code yet. Phase 0 needs three models added to the OpenRouter guardrail, which is a change to the
production key and needs its own yes.

Oliver asked on 2026-11-20 how a decision model such as Jev or OpenAI's Decisions API could lower
our costs, improve anything, or just be useful, then said "go and write the full plan now".

## 0. Summary

A decision model does not write. You give it some text and a list of questions, each with a fixed
set of answers (yes or no, pick one of these, a score on a scale), and it returns how likely each
answer is. It answers in well under a second and charges only for what it reads.

**This is not a cost project.** Measured on production (§2), the one clear saving (skipping quiet
check-in scans) is about 1% of what we spend, and the other calls in this plan cost about that
much, so it roughly breaks even. What it buys is quality and speed: checks we skip today because a
model call is too slow or too dear to run every time, and thresholds we can tune from real outcomes
instead of fixed rules.

The uses, in the order I would build them:

| # | Use | What changes for people | Effect | Where |
|---|---|---|---|---|
| U1 | Scan gate | Nothing visible; quiet check-ins stop costing credits | Saves about 1% of spend; lets scans run more often for the same money | §6.1 |
| U2 | Reply check on every run | Fewer replies that claim work the bot didn't do | Quality. Today only runs with 4 or more tool steps are checked | §6.2 |
| U3 | Push scoring | Fewer pushes people dismiss | Quality. 73% of answered suggestions were dismissed (§2.4) | §6.3 |
| U4 | Tool-call gate | A bot acting on instructions hidden in a mail or page gets stopped and asks | Safety. Only ever adds an ask | §6.4 |
| U5 | Long-run check (experiment) | Runs that are stuck in a loop wrap up sooner | The only place real money sits: 20% of runs are 66% of chat spend | §6.5 |
| U6 | Effort picker (experiment) | Faster replies to simple messages | Unknown until we record reasoning tokens (Phase 0) | §6.6 |
| U7 | Watcher gate | Nothing visible | Nothing today: no one has made a watcher in production | §6.7 |

How it gets built: one small function, `decide()`, with settings that can be changed live. Every
use starts in **shadow mode**: the server asks the decision model, writes down its answer next to
what really happened, and acts on nothing. Shadow results on our own traffic pick the model, set
each threshold, and decide whether a use is turned on at all. No user content is exported for
this; the labels come from what the product already records.

**What I told you earlier that the numbers changed:**

1. I ranked watchers first. There are no watchers in production (0 rows), so that saves nothing
   today.
2. I said we would need Jev through OpenRouter or OpenAI as a new vendor. OpenRouter carries 36
   decision models from 17 makers, OpenAI's included, on one route. Some cost a quarter of Jev's
   price. No new vendor is needed.
3. I said we pay $0.022 per million input tokens. Since D-355 we pay **$0.0126**. Jev's $0.042 is
   3.3 times that. Output is the dear part for us ($0.60 per million, 42% of token spend), and
   decision models don't charge for output.

## 1. What is on offer (checked 2026-11-20)

### 1.1 How a call looks

Through OpenRouter, with our existing key. Shape as documented on 2026-11-20; the route is marked
alpha and may change, so Phase 0 confirms it with a live call.

```
POST https://openrouter.ai/api/alpha/decisions
Authorization: Bearer <OpenRouter key>

{ "model": "typesafe/jev-1.14",
  "state": "<the text to judge>",
  "questions": {
    "worth_telling": { "type": "noul", "instructions": "Does any item need the person's attention today?" },
    "kind": { "type": "choice", "criteria": { "person": "written by a real person", "notice": "an automatic notice", "other": "anything else" } }
  },
  "provider": { "data_collection": "deny" } }
```

```
{ "model": "typesafe/jev-1.14", "provider": "TypeSafe",
  "answers": {
    "worth_telling": { "type": "noul", "noul": 0.07 },
    "kind": { "type": "choice", "choice": "notice", "confidence": 0.75, "probabilities": { "person": 0.1, "notice": 0.8, "other": 0.1 } } },
  "usage": { "input_tokens": 476, "output_tokens": 70, "cost": 0.000019992 } }
```

- **Question types:** `noul` (yes or no, returned as the chance of yes from 0 to 1), `choice` (one
  of up to 255 named options, with a probability for each), `score` (a place on a scale of up to 10
  levels), and `box` (find something in an image; Jev 1.14 only, an early feature).
- **Several questions per call.** They share the one input, are answered in parallel, and the input
  is billed once. Asking four questions costs the same as asking one.
- **A second route,** `POST https://openrouter.ai/api/v1/systemone`, takes the same body and matches
  TypeSafe's own API. Its docs name only Jev. The alpha route serves every decision model.
- **OpenAI's own API** (`POST https://api.openai.com/v1/decisions`, model `gpt-6-luna`) has the same
  three ideas under other names (`predicate`, `choice`, `score`). We don't need it: the same model
  is on OpenRouter as `openai/gpt-6-luna-decisions`.

### 1.2 Models and prices

From OpenRouter's public model list on 2026-11-20. It lists 36 models whose output is "decisions"
(44 entries with aliases and free variants), from 17 makers. None charge for output.

| Model | OpenRouter id | Input, per 1M tokens | Context |
|---|---|---|---|
| Jev 1.14 (TypeSafe) | `typesafe/jev-1.14` | $0.042 | 262k |
| GPT-6 Luna Decisions (OpenAI) | `openai/gpt-6-luna-decisions` | $0.10 | 1.05M |
| Gemini Decision 1 (Google) | `google/gemini-decision-1` | $0.10 | 262k |
| Decider Flash v1.2 (Perplexity) | `perplexity/pplx-decider-flash-v1.2` | $0.01 | 262k |
| d1.2 (Liquid) | `liquid/d1.2` | $0.02 | 65k |
| Clef Flash (Cloudflare) | `cloudflare/clef-flash` | $0.019 | 24k |
| Joey 1 (Baseten) | `baseten/joey-1` | $0.01 | 16k |
| *For comparison: our chat and background model (DeepSeek V4.1 Flash), as paid since D-355* | | *$0.0126 in, $0.60 out* | |

I know how Jev performs from outside tests (§1.4). I know nothing about the quality of the cheaper
ones. Shadow mode (§7) compares them on our own traffic.

### 1.3 Speed and limits

- **Speed:** TypeSafe says 70 to 500 ms. OpenRouter's examples came back in under 600 ms. One
  outside test measured a median of about 350 ms from the UK to US servers. OpenAI's guide says
  about ten times faster than its text API; press coverage quoted 150 ms. Our server is in the US;
  Phase 0 measures from it.
- **Input size:** Jev accepts 262k tokens, but above about 32,000 bytes of text TypeSafe switches
  to a long-context mode it calls "slower and less accurate". Every use in this plan caps its input
  at 24,000 bytes.
- **Not repeatable to the last digit.** The same call twice moved a probability by up to 0.08 in
  OpenRouter's own example. Thresholds must sit far apart.
- **Errors:** 400 for a question type the model doesn't take, 402 when the key's limit is spent,
  429 when rate-limited. The usual OpenRouter set.

### 1.4 How good it is, and where it is weak

- **About as good as a small model asked to judge, not better.** In Red Hat's test (as reported by
  DataCamp): spotting prompt injection, Jev 86.4% against 89.3% for a mid-size open model used as a
  judge; content safety, Jev 86.2% against 85.5%. An academic test found it cost about $0.30 across
  19 benchmarks where model judges cost about $19.
- **Its probabilities mean something on average, not case by case.** Keeping only the half of its
  answers furthest from 50% raised accuracy from 79% to 93% in that same test. That is the pattern
  this plan uses everywhere: act only on confident answers, and do what we do today on the rest.
- **Stated weak spots:** numbers, dates and arithmetic; double negatives; long input with little
  relevant in it; a lean toward the first option listed; text written to fool it. It cannot explain
  an answer.
- **It must pick from your list.** Both vendors say to add an "other" option, or a separate yes/no
  question, when the list may not cover the input.
- **Vendor's own advice on thresholds:** start at 0.7 for yes and 0.3 for no, send the middle to a
  person, and set the real values from 100 to 200 labelled examples of your own.

### 1.5 Data

TypeSafe states that Jev is not trained on customer requests or responses. Zero retention is by
request for enterprise customers, not automatic. Our OpenRouter guardrail "Casama privacy" already
refuses any endpoint that trains on prompts; whether it treats these endpoints as acceptable is a
Phase 0 check (§11), not an assumption.

## 2. What production shows

Read-only totals from the production database, 2026-11-18 00:00 UTC to 2026-11-20 (about 2.4 days,
all after D-355): 203 runs, 19 people, 28 bots, $1.44 charged, about $1.20 paid to vendors. The
sample is small; every share below can move.

### 2.1 Where the money goes

| What | Runs | Model calls per run | Paid to vendors | Per run | Share of model spend |
|---|---|---|---|---|---|
| Chat messages | 83 | 12.0 | $0.708 | $0.0085 | 68% |
| Routine tasks | 30 | 10.7 | $0.244 | $0.0081 | 24% |
| Check-in scans | 35 | 3.4 | $0.058 | $0.0017 | 6% |
| Check-in briefs | 32 | 3.1 | $0.022 | $0.0007 | 2% |

- **Tokens:** 47.7M input tokens at $0.0126 per million ($0.60), and 0.72M output tokens at $0.60
  per million ($0.44). Output is now 42% of token spend.
- **Everything else** (voice, app calls, search, computers) came to $0.16.
- **Housekeeping calls are small.** Calls with under 6,000 input tokens (memory, reply check, skill
  learning, summaries, and short chat steps together) were 299 calls and $0.016 of input. Replacing
  them cannot save much.

### 2.2 Long runs are the cost

Chat and task runs, by how many model calls they took:

| Model calls | Runs | Paid to vendors | Share |
|---|---|---|---|
| 1 to 2 | 17 | $0.010 | 1% |
| 3 to 4 | 31 | $0.044 | 5% |
| 5 to 9 | 26 | $0.085 | 9% |
| 10 to 19 | 18 | $0.181 | 19% |
| 20 or more | 23 | $0.632 | 66% |

Of the 23 longest runs, 19 completed, 3 failed and 1 was cancelled. The four that didn't complete
cost $0.11, which is 9% of everything we paid in the window. None of the 23 used a computer.

### 2.3 Scans

- 44 scans. 9 were skipped for free because nothing had changed since the last one (the digest
  skip from D-355).
- 35 ran the model. **24 of those found nothing** and 11 made 19 suggestions, 18 of them pushed.
- The 24 that found nothing were $0.034 of the $0.081 charged for scans: 42%.
- Over the last 14 days: 77 scans, 13 skipped, 36 ran and found nothing, 28 made suggestions.

### 2.4 Suggestions and pushes (last 14 days)

- 63 suggestions, 55 pushed. Of the 41 the person answered, **11 were accepted and 30 dismissed
  (73% dismissed)**. 22 are still waiting.
- On days a person got any, they got 4.2 suggestion pushes on average and up to 10.

### 2.5 Approvals and watchers

- **Approvals** (last 14 days): 34 asked, 33 approved, 1 expired, none refused.
- **Watchers:** none exist in production.

## 3. Where Casama decides things today

| Decision | How it is made today | Where |
|---|---|---|
| Should this scan run the model at all | Skipped only if the read items are identical to last time | `packages/agent/src/run.ts:1263` |
| Did the scan find anything | The scan run itself answers `NOTHING_NEW` or adds suggestions | `packages/agent/src/checkins.ts:119` |
| How urgent is a suggestion | The scan run picks low, normal or urgent | `packages/agent/src/checkins.ts:464` |
| May this push interrupt now | Rules: Focus, driving, in a meeting, 5 a day per bot | `packages/agent/src/attention.ts:11` |
| Does the reply claim more than was done | One background model call, only when the run took 4 or more tool steps | `packages/agent/src/run.ts:1418`, `:2828` |
| Is anything worth remembering | One background model call after every run | `packages/agent/src/run.ts:4070` |
| Did the person correct the bot | A regex on the first words ("no", "actually", "that's wrong") | `packages/agent/src/skill-learning.ts:23` |
| Does this tool call need an approval | Fixed risk class of the tool plus the bot's autonomy setting | `packages/agent/src/run.ts:4455` |
| Did a watched thing change in the way asked | A full bot run that answers `NO_MATCH` or tells the person | `packages/agent/src/watchers.ts:165` |
| Is this image or video request allowed | A regex, then one background model call with four possible answers | `packages/agent/src/media-safety.ts:90` |
| How hard should the model think | Fixed: medium by default for chat on the shared key, low for check-ins | `apps/server/src/env.ts:506`, `packages/agent/src/run.ts:634` |

There is no model picker and no pre-check of a message today: a bot has one model, and the model
chooses its own tools.

## 4. Principles

1. **No decision means today's behaviour.** When the decision model is off, slow, down, refuses, or
   answers in the middle band, the code does exactly what it does now. Nothing depends on it.
2. **Shadow first, always.** A use is turned on only after shadow results on our own traffic meet
   the bar written for it in §6. If it misses the bar, it stays off and the plan says so.
3. **Act only on confident answers.** Thresholds sit far apart (start at 0.1 and 0.9) and come from
   our data, never from a guess that was tuned on a handful of cases.
4. **On safety it can only add caution.** It may add an approval ask or a second look. It never
   removes an approval, never unblocks a media request, and is never the only check.
5. **Dates, numbers, limits and quotas stay in code.** They are its stated weak spots.
6. **One function, settings changed live.** Model, mode and thresholds per use live in instance
   settings, editable by the owner without a deploy, like cloud models.
7. **Log the decision, never the content.** The log holds question names, probabilities, what the
   code did and what happened after. No message text.
8. **Pin the model version.** Thresholds belong to one model version. A new version goes through
   shadow before it replaces the old one.

## 5. Architecture

### 5.1 `decide()`

New file `packages/agent/src/decide.ts`.

```ts
type Question =
  | { type: "yesno"; ask: string }
  | { type: "choice"; ask?: string; options: Record<string, string> }  // name -> what it means
  | { type: "score"; ask?: string; levels: string[] };                 // 2 to 10 ordered levels

type Answer =
  | { type: "yesno"; p: number }                                  // chance of yes, 0 to 1
  | { type: "choice"; choice: string; p: Record<string, number> }
  | { type: "score"; score: number }
  | { type: "none" };                                             // off, failed, timed out or refused

decide(deps, { use, orgId, botId, runId, state, questions }): Promise<Record<string, Answer>>
```

- `use` names the caller (`scan_gate`, `reply_check`, `push_score`, `tool_gate`, `long_run`,
  `effort`). Settings and the log are keyed by it.
- `state` is cut to 24,000 bytes before it is sent.
- A 1.5 second time limit. A timeout, an error or a refusal returns `none` for every question.
- In shadow mode the caller still calls `decide()`, and then ignores the answers.

### 5.2 The backend

New file `packages/agent/src/gateway/decisions.ts`: a plain `fetch` to the OpenRouter route chosen
in Phase 0, mapping `yesno` to `noul`. One file, so a change to the alpha route or a move to
another vendor touches nothing else. Tests use recorded responses, as the gateway's `replay.ts`
does for chat.

No generic fallback to a chat model. Each use already has a behaviour for "no answer": what it
does today.

### 5.3 Model setting, allowlist and lock

- `CloudModelAssignment` gains `decision: string` (empty means off) in
  `packages/domain/src/cloud-model-assignment.ts`. Default empty until Phase 2 names a model.
- The decision path allows exactly that model on Casama's key, plus the shadow models while a
  shadow run is on; `cloudModelIds()` stays as it is for chat.
- The model goes on the OpenRouter guardrail "Casama privacy" **first** (D-364), or every call
  fails with "Model blocked by guardrail".
- `scripts/check-model-updates.mts` learns the new field so the weekly check covers it.
- **Self-hosted servers:** off by default. An owner with an OpenRouter key can set a decision
  model in the same setting. No other provider in the first version.

### 5.4 Settings

`instance_settings` key `decisions`, read with the same 10 second cache as
`apps/server/src/services/cloud-models.ts`:

```json
{ "shadow_models": ["typesafe/jev-1.14", "openai/gpt-6-luna-decisions", "perplexity/pplx-decider-flash-v1.2"],
  "uses": { "scan_gate": { "mode": "shadow", "skip_below": 0.1 },
            "reply_check": { "mode": "shadow", "flag_above": 0.9 } } }
```

`mode` is `off`, `shadow` or `on`. The admin API reads and writes it (owner only). The app's
Admin → Cloud models screen gets a "Decisions" row in a later app build; nothing in Phases 0 to 2
waits for an app build.

### 5.5 Decision log

New table `decision_log`, insert-only, no member access (service role and the owner's admin API
only).

| Column | Holds |
|---|---|
| `org_id`, `bot_id`, `run_id` | Whose decision it was |
| `use`, `model`, `shadow` | Which use, which model, whether it was acted on |
| `answers` | Question name to probability or choice. No text |
| `action` | What the code did: `skipped`, `ran`, `flagged`, `asked`, `none` |
| `outcome` | Filled in later with what really happened (the label), per use |
| `input_tokens`, `cost_usd`, `latency_ms` | For the cost and speed tables |

Rows older than 90 days are deleted by a worker cleanup job, like the existing purge jobs in
`apps/server/src/worker/workflows.ts`. They go with the workspace when it is deleted. Before adding
the migration, check every branch and worktree for a version collision.

### 5.6 Money

- Each call writes a `usage_ledger` row: kind `tokens_in`, the decision model's id, and
  `meta.purpose` of `decide:<use>`, with the cost OpenRouter returns in `usage.cost`.
- Shadow calls are never charged to a person (`billable = false`): they get nothing from them.
- A use that is on is charged like other background calls (§12, decision 3).
- `docs/COSTS.md` gains the decision model under "Usage costs" and the scan gate under "Lowering
  costs", in the same commit as the code.

## 6. The uses

Each one lists what happens today, what changes, the questions asked, the bar it must pass in
shadow, and how it fails safe. Question wording is a first draft; Phase 2 fixes it from results.

### 6.1 U1: scan gate

- **Today:** a scan reads the person's mail, calendar and boards before the model runs. If those
  reads are identical to last time the run is skipped for free. If anything differs, the model runs
  (about $0.0017). 24 of 35 such runs found nothing.
- **With the gate:** when the reads differ, ask the decision model about them first. If it is
  confident there is nothing worth telling, end the scan the way an unchanged one ends (same code
  path at `run.ts:1273`). Otherwise run the model as now.
- **Questions** on the read items plus the scan note:
  - `needs_attention`: does any item need the person's attention or action within a day?
  - `from_person`: was at least one new item written by a real person to this person, not a
    newsletter, receipt, notification or advert?
  - `time_bound`: does any item change a meeting, set a deadline, or concern a payment or security?
- **Skip only when** all three are at or under the skip threshold (start 0.1).
- **Never skipped:** scans someone asked for (setup, a new app, an app event), bots whose apps the
  pre-read doesn't fully cover, and people sharing device data. These are the same exceptions the
  digest skip has today. Also never more than 3 gate skips in a row for one bot.
- **Safety net:** the daily brief still reads everything. Phase 1 confirms the brief's reads cover
  what a skipped scan saw before this is turned on.
- **Label in shadow:** did that scan make a suggestion; stronger, was a suggestion from it accepted.
- **Bar to turn on:** on at least 150 shadow scans, of which at least 40 made a suggestion: the
  gate would have skipped no more than 2% of the scans that made a suggestion, none of the scans
  whose suggestion was accepted, and at least half of the scans that found nothing.
- **Saving:** scans that found nothing cost about $0.024 in the window. Skipping three quarters of
  them saves $0.018; the gate's own calls cost $0.006 at Jev's price (about 4,000 tokens each, to
  be measured) or $0.0014 at the cheapest. Net $0.012 to $0.017, which is 1.0 to 1.4% of spend.
- **What it opens up:** with quiet scans nearly free, the plan floors on scan frequency could come
  down. That is a pricing decision, not part of this plan.

### 6.2 U2: reply check on every run, and two better gates

- **Today:** the background model checks a reply against the run's steps only when the run took 4
  or more tool steps. Whether the person corrected the bot is a regex. Memory extraction runs after
  every run.
- **With one decision call** on the digest the checker already builds (the request, each step's
  result cut to 240 characters, the reply), asked for every chat run with at least one tool step:
  - `overclaims`: does the reply say something was done, sent, saved or found that no step shows,
    or report a failed step as a success?
  - `unfinished`: does the reply say the request is finished when an obvious part was not tried?
  - `corrects_previous`: is the person saying the previous answer was wrong or missed something?
  - `worth_remembering`: does the person's message state a lasting fact or preference about
    themselves, their work or the people they deal with?
- **What the answers do:**
  - `overclaims` or `unfinished` at or over the flag threshold (start 0.9): run today's checker,
    which writes the one-sentence issue and sends the reply back once, exactly as now. Under the
    threshold on a short run: nothing, as now. On a run of 4 or more steps the checker still runs
    as today until shadow shows the decision model can stand in for it.
  - `corrects_previous` at or over 0.9 counts as a correction alongside the regex.
  - `worth_remembering` at or under 0.1 skips the memory call.
- **Labels in shadow:** the checker's own verdict on the runs it checks today; whether memory
  extraction saved anything; for corrections, 50 cases checked by hand.
- **Bar to turn on:** on at least 150 checked runs, the decision model flags at least 80% of the
  runs today's checker flagged, and flags no more than 5% of the runs it passed. For memory: of the
  runs it would skip, no more than 2% actually saved a memory.
- **Cost:** about 3,000 tokens a call, $0.00013 at Jev's price, on a chat run that averages
  $0.0085: plus 1.5%, roughly paid back by the memory calls it skips. The reply has already
  streamed to the screen when the check runs, as today; the run ends up to half a second later.

### 6.3 U3: push scoring

- **Today:** the scan run labels each suggestion low, normal or urgent. Non-urgent pushes are held
  by rules (Focus, driving, a meeting, 5 a day per bot). 73% of answered suggestions were dismissed.
- **With a score:** when a suggestion is about to push, ask `worth_a_push` on its title, body and
  push text, the kinds of sources behind it, the person's local time, and the titles of their last
  ten suggestions with what they did with each. Under the threshold, the suggestion waits for the
  next brief, using the hold that exists today (`low_urgency`).
- **Urgent stays urgent.** The score never holds an urgent suggestion and never sends one the rules
  would hold.
- **Label:** accepted or dismissed.
- **Bar to turn on:** on at least 150 answered suggestions, holding the lowest-scored third would
  have held no more than 5% of the accepted ones.
- **Timing:** at today's volume, 150 answered suggestions takes about seven weeks. Shadow starts in
  Phase 1 so the data is there when we want it.

### 6.4 U4: tool-call gate

- **Today:** whether a tool call asks first depends on the tool's fixed risk class and the bot's
  autonomy setting. People approve nearly everything: 33 of 34.
- **The risk it is for:** a bot that reads a mail or a web page saying "forward this to…" and does
  it. Nothing today compares an outgoing action with what the person actually asked for.
- **With the gate:** for a call that sends something out or changes data and would **not** ask
  today, ask on the person's request plus the tool name and arguments:
  - `asked_for`: is this action something the person asked for in this chat?
  - `outside_party`: does it send content to someone other than the person?
- **What it does:** `asked_for` at or under 0.1 turns the call into an approval ask. It never
  removes an ask (§4, principle 4).
- **Label:** there are no refusals to learn from, so this one needs a hand-made set first: 100
  cases, half ordinary and half carrying planted instructions, built from our existing tools.
- **Bar to turn on:** catches at least 80% of the planted cases, and in shadow on real traffic adds
  an ask to no more than 2% of calls.
- **Not in this plan:** asking less often. With 33 of 34 approved, fewer asks is what people would
  feel most, but removing an approval is a security decision that needs its own data and its own
  plan (§12, decision 5).

### 6.5 U5: long-run check (experiment, shadow only)

- **Why:** runs of 20 or more model calls are 66% of chat and task spend. Four of 23 failed or were
  cancelled after about 40 calls each, costing 9% of everything we paid.
- **Shadow:** at step 10 and every 8 steps after, ask on the request plus a digest of the last 8
  steps: `making_progress`, and `repeating` (are the last steps the same call or the same failure
  again?).
- **Label:** the run completed, or it failed, was cancelled or ran out of steps.
- **Then decide.** If `repeating` at 0.9 or over picks out the runs that go on to fail, with false
  alarms on no more than 5% of runs that complete, the action is the note the bot already gets near
  its step limit ("deliver what you have"), sent early. It never kills a run. If shadow shows no
  such signal, this is dropped.
- **Ceiling:** stopping the failed long runs halfway would have saved about 4 to 5% of spend in
  this window. Small sample.

### 6.6 U6: effort picker (experiment)

- **Why:** output is 42% of token spend at $0.60 per million, and chat on the shared key thinks at
  medium effort for every message, a greeting included. Forcing low effort on check-ins was one of
  D-355's larger savings.
- **Unknown:** how much of chat's output is thinking. The ledger doesn't record it. Phase 0 adds
  the count OpenRouter already returns to the ledger's `meta`.
- **If thinking turns out to be a large share:** at the start of a run, ask on the person's message
  and the two turns before it (under 2,000 tokens) one `choice`: `quick` (a greeting, thanks, a
  short factual question, a one-step request), `normal`, `hard`. `quick` at 0.9 or over runs that
  message at low effort. It only ever lowers effort.
- **Measured by** output tokens per run, time to first words, and 👍/👎 reactions against the
  runs left at medium.
- **Not OpenRouter's Jev Router.** It picks a model and effort per request, but it chooses among
  many models and our key allows one, and it only runs in the global region.

### 6.7 U7: watcher gate

One yes/no on the watcher's condition and the change, before `fire()` starts a full run. About 20
lines once U1 exists. No one has made a watcher in production, so it waits until someone does.

### 6.8 Later, each its own small decision

- Which bot answers in a group chat, where today only `@everyone` is detected by a regex.
- Filing a message into the right topic.
- Sorting incoming bot email (from a person, an advert, needs a reply), which today is sender rules
  only. Belongs with `docs/BOT-EMAIL-PLAN.md`.
- Calendar triggers that match by meaning instead of a word in the title.
- Casama Help: turning away off-topic questions before the model writes anything.

### 6.9 Not doing

- **Replacing the image and video safety check.** It is safety-critical, the decision model is no
  more accurate than what we have, and it is weak against text written to fool it.
- **Anything that writes:** memories, summaries, starters, call recaps.
- **Voice.** Nothing here touches the 22% that was voice.
- **Removing approvals.** See §6.4.

## 7. Shadow mode: how we find out

1. **What runs.** For each use in `shadow`, the server calls every model in `shadow_models` with
   the same input, in parallel, off the main path, and writes one log row per model. The run goes
   on exactly as it would have.
2. **Labels come from the product.** A scan made a suggestion or didn't. The checker flagged the
   reply or didn't. The person accepted or dismissed. The run completed or failed. The worker fills
   `outcome` when it is known.
3. **No content leaves its normal path.** The input goes where the same content already goes for
   the bot's model call: to OpenRouter under the same guardrail. Nothing is exported for analysis;
   the log has no text.
4. **Reading the results.** One query per use gives, for each model and each threshold from 0.05 to
   0.95: how many it would have acted on, and how many of those were wrong. The admin API returns
   the same table.
5. **How long.** About 15 model-run scans and 20 checked runs a day today, so 150 of each takes
   about 10 days. Suggestions take about seven weeks.
6. **What shadow costs.** Three models on every scan, every chat run with a tool step and every
   long-run check: about $0.06 a day at today's volume, under $2 a month.

Before shadow goes to production, the same code runs on the local stack against Oliver's own
account, to catch wiring mistakes, not to set thresholds.

## 8. Cost

| | Today's volume | At 1,000 people active a day (about 125 times today) |
|---|---|---|
| What we pay vendors now | $0.50 a day | about $62 a day |
| Shadow, three models, U1 + U2 + U3 + U5 | about $0.06 a day | not run at that scale: one model by then |
| U1 and U2 on, one model at Jev's price | about $0.01 a day | about $1.10 a day |
| What U1 saves, before its own calls | about $0.0075 a day | about $0.95 a day |

So with U1 and U2 on, the decision model costs about 2% of spend and gives back about 1.5%: roughly
even. The case for it is §6.2 to §6.4, not this table. If U5 or U6 show a signal, they are where a
real saving could come from.

A cheaper model changes little here: the calls are small. Choose on accuracy first.

## 9. Privacy and documents

- **What the decision model receives:** the same content a bot's own model call already receives,
  through the same OpenRouter account and guardrail.
- **`site/privacy.html` names each model maker and what it receives** (lines 177 to 181, and the
  table at 236). The maker of whichever model is chosen is added there before any use is turned on
  for people, with what it receives and why. Shadow calls count: the line goes in before Phase 1
  ships. That is a website deploy and needs its own yes.
- **The decision log** holds no content and is deleted with the workspace.
- **Same commit as the code:** `docs/COSTS.md`, a `docs/DECISIONS.md` entry (the highest was D-451
  on 2026-11-20; check again before writing), the docs site's cloud models and self-hosting pages,
  and this plan's row in `docs/PLANS.md`.

## 10. Testing

- **`decide()`:** each question type parsed from recorded responses; a timeout, a 402, a 429, a
  refusal and a malformed body each return `none`; input cut at 24,000 bytes.
- **Each use:** with `none` the behaviour is byte-for-byte today's (existing tests keep passing
  with the decision model off, which is the default); in shadow nothing changes but the log; when
  on, the threshold decides, including the exceptions in §6.1.
- **Settings:** a change is picked up within the cache time; a member cannot read or write them.
- **Decision log (pgTAP):** members cannot select from it; rows go when the workspace goes.
- **Ledger:** shadow rows are not billable; `meta.purpose` is set.
- **Live, on the local stack:** one real call per model with the Casama key once the guardrail
  allows it.
- Targeted test files while building; the full suites once at the end through `scripts/heavy.sh`.

## 11. Rollout

### Phase 0: can we call it, and what does chat's thinking cost (half a day)

Needs Oliver's yes to add three models to the OpenRouter guardrail (§12, decisions 1 and 2).

1. Add the three shadow models to "Casama privacy".
2. With the Casama key, one call per model on the alpha route, and Jev on the SystemOne route.
   Write down for each: did it answer, is `usage.cost` there and in dollars, and 10 timings from
   the Mac and 10 from the production server.
3. Call a decision model that is **not** on the list: the guardrail must refuse it. If the
   guardrail doesn't apply to this route, stop and report; the key would be worth more than
   intended.
4. Confirm the key's daily cap and `data_collection: deny` apply on this route.
5. Record reasoning tokens in the ledger's `meta` for chat steps (a small server change; goes out
   with the next server deploy).

**Done when** this plan has a table of those results and names the route.

### Phase 1: `decide()`, the log, and shadow for U1, U2, U3 and U5 (2 to 3 days)

Everything in §5, the four shadow call sites, the admin API for settings and results, the privacy
page line, and tests. Ships with all modes `off`; the owner switches them to `shadow` after the
deploy.

**Done when** the suites pass, a server deploy has Oliver's yes, and the log is filling in
production with outcomes attached.

### Phase 2: read the results, turn on what passes (half a day, about 10 days after Phase 1)

Pick the model. Set thresholds from the tables. Fix question wording where a question, not a
threshold, is the problem, and give changed questions more shadow time. Turn on U1 and U2 if they
meet their bars. Cut the guardrail back to the one chosen model. Write the results into this plan.

**Done when** each of U1 and U2 is on with its numbers recorded, or off with the reason recorded.

### Phase 3: push scoring and the tool-call gate (2 days, when the data is there)

U3 when 150 suggestions have been answered. U4 after its hand-made test set, then shadow, then on.

### Phase 4: the experiments

U5 and U6 each get a go or a drop from their shadow results. U7 when watchers are in use. The
"later" list in §6.8 as separate small decisions.

## 12. Decisions for Oliver

My default is in bold. If you say "go" with no changes, these are what gets built.

| # | Decision | Default |
|---|---|---|
| 1 | Do Phase 0 and Phase 1 (shadow only, nothing changes for people)? | **Yes** |
| 2 | Which models to compare in shadow | **Jev 1.14, OpenAI GPT-6 Luna Decisions, Perplexity Decider Flash v1.2.** Three on the guardrail during shadow, one after. A stolen key could call them, but they are cheap and cannot write, so they are worth little to a thief |
| 3 | Who pays for decision calls | **Casama during shadow. Once a use is on, the person, like other background calls.** They are a small fraction of a cent, and the scan gate saves the person more than it costs |
| 4 | How many real finds the scan gate may miss | **No more than 2% of scans that made a suggestion, and none whose suggestion was accepted** |
| 5 | Tool-call gate direction | **Only adds an approval ask. Asking less often is a separate plan** |
| 6 | Push scoring and the 5-a-day rule | **Keep the rule; the score works under it.** Revisit once the score is proven |
| 7 | Self-hosted servers | **Off by default; an owner with an OpenRouter key can turn it on** |
| 8 | Model versions | **Pinned (`typesafe/jev-1.14`, not the "latest" alias)** |

## 13. Risks and open questions

- **The OpenRouter route is alpha.** Its shape can change. It lives in one adapter file, and Phase
  0 also tries the SystemOne route.
- **The guardrail may not cover this route.** Checked in Phase 0, step 3, before anything else.
- **The scan gate's label is the scan model's own judgment.** A gate that agrees with it perfectly
  is only as good as it. The accepted-suggestion label and the brief as a safety net cover part of
  that.
- **Small numbers.** Everything in §2 is 2.4 days and 19 people. Thresholds set on 150 cases will
  need another look as volume grows; the log makes that one query.
- **Text written to fool it.** A mail can be worded to look unimportant or to look like the
  person's request. The scan gate loses little to that (a sender gains nothing by being skipped);
  the tool-call gate is why principle 4 exists.
- **A young vendor.** TypeSafe launched Jev in September 2026. With 36 models on one route and one
  adapter file, changing model is a setting plus a shadow run.
- **Option order and wording move scores.** Questions are fixed strings in code, changed only with
  a shadow run behind them.
- **Open:** whether the daily brief's reads fully cover what a skipped scan saw (§6.1); how many
  tokens a scan's reads really are; whether `usage.cost` on this route is dollars or credits (the
  docs disagree with themselves).

## Appendix: sources and queries

**Vendor documents read on 2026-11-20:** TypeSafe's docs (quickstart, models, API, confidence,
legal); OpenAI's Decisions guide, reference and pricing; OpenRouter's Decisions API reference, Jev
guide, Jev Router guide and four cookbooks (classification, gating tool calls, verified cascade,
permission prompts); OpenRouter's public model list (`/api/v1/models?output_modalities=all`).
Secondary: DataCamp's overview (which reports the Red Hat and arXiv results), Zapier's Jev article,
Vercel's AI Gateway model page.

**Not verified:** the outside accuracy tests were read as reported by DataCamp, not from their own
papers. OpenAI's announcement page would not load. Per-model support for question types on
OpenRouter was not read; Phase 0 tests it.

**Production queries** (read-only, totals only, on `casama-db-1`): runs joined to routines by
trigger and kind; `usage_ledger` grouped by run for model calls and vendor cost; scans joined to
`suggestions` by `run_id`; `suggestions` by status; `approvals` by status; `watchers` by kind.
