# Your own model provider on Casama Cloud, and a switch to turn Casama's models off: plan

Status: **live** (written 2026-11-21; Phases 0–4 built and deployed to production 2026-11-21, D-465: server `5cf766117eef`, web app build 70, docs, and `own_providers: true` enabled; store builds and Phase 5 wait on store release / OpenAI's hosted-use approval).

Oliver asked (2026-11-21) whether Casama's models can be switched off remotely so people use their
own ChatGPT plan or API keys ("just in case we go bankrupt"), and then whether people on Casama
Cloud should be free to choose their own provider at any time, so a paying workspace that brings
its own model only pays for the bot computers, "like Rakazo does now but more flexible".

Line numbers are from 2026-11-21. Re-find each one before editing.

## 0. Summary

Two things, built in this order because the second is useless without the first.

1. **Choice.** A Casama Cloud workspace can add its own model key or connect a ChatGPT plan, and
   pick it for the whole workspace or for one bot. Casama's models stay the default and need no
   setup. Model use on your own provider costs no credits.
2. **The switch.** The instance owner can turn Casama's models off from the admin console, for
   every plan or for chosen plans, with no deploy and no app release. A workspace that has its own
   provider keeps working without doing anything. One that hasn't sees a card that connects one.

| | Today | After |
|---|---|---|
| Model key on Casama Cloud | Casama's only; the app hides chat keys, and a run replaces any other choice | Casama's, your own key, or your ChatGPT plan |
| Who chooses | Nobody; Casama assigns the models (D-188) | The workspace, with a per-bot override |
| Model on your own key | Not possible | Any model the key offers |
| Credits needed to start a run | Always, whatever key (D-246) | Only when the run uses Casama's key |
| Turning Casama's models off | Not possible without stopping everyone | A switch in Admin, per plan |
| ChatGPT plan on Cloud | Off until OpenAI approves hosted use (D-091) | On once approved; API keys don't wait for it |

**What it does not cover.** The switch stops Casama's model bills, which are the cost that grows
with use. It does not keep Casama Cloud alive if the server itself is turned off: computers, chats
and files live there. Surviving that is self-hosting plus moving a workspace off Cloud, which is a
separate plan (§12).

## 1. What exists today

Checked in the code on 2026-11-21.

**Every Cloud run is forced onto Casama's key.**

- `packages/agent/src/run.ts:589-594` (and `:5408-5411`): with billing on, the bot's saved
  `model_policy` is thrown away and replaced by `cloudRunPolicy(assigned)`: Casama's OpenRouter
  key, Casama's chat model, Casama's background model (D-188).
- `apps/server/src/api/routes/bots.ts:349-357`: a new bot is stored with the same policy, whatever
  the request asked for. `bot-template.ts:199-206` does the same.
- The key is the server's `CLOUD_MODEL_UPSTREAM_KEY`, credential id
  `00000000-0000-4000-8000-0000000000c1`, not a row anyone can edit (D-186).

**The app hides the choice.**

- `client/lib/features/settings/model_keys_screen.dart:369-406`: on Cloud the screen is "Service
  keys", lists only the providers in `keyProviders.cloud` (`google_maps`, `mapbox`, `treg`,
  `packages/domain/src/key-providers.ts:38`) and the add form offers only those, with no ChatGPT
  button.
- `client/lib/features/bots/model_picker.dart:39-46`: `casamaModelFixed` is true whenever billing is
  on, so the model field shows Casama's model and doesn't open.
- The server does **not** refuse a chat key on Cloud: `createCredential`
  (`bots.ts:1539`) accepts any provider. Only the app and the run-time replacement stand in the way.

**ChatGPT plans are off on Cloud.** `chatGptSignInEnabled` (`routes/chatgpt.ts:38-42`) is off when
billing is on, because OpenAI's "Sign in with ChatGPT" needs its approval for hosted use (D-091;
the interest form is an open item in `docs/NEEDS-FROM-OLIVER.md`). A plan is personal: it runs
only for the person who connected it. Connecting needs the desktop app or the CLI
(`canConnectChatGpt`), phones and the web point there.

**Own keys already cost nothing.** A run on a workspace's own key is logged with `cost_usd = 0`
(`source = chatgpt_plan` for a plan) and isn't billable (docs/COSTS.md, "How the money works").
The reply-usage sheet already has "on your keys" lines (`reply_usage.dart:115-126`).

**But every run needs credits.** `spend` in `run.ts:2786-2812`: on a credit-gated plan (all four)
a run is refused with no credits, whatever key it uses, because tools inside the run bill Casama
(D-246). The daily cap `cloud_daily_usd` is checked the same way for every run.

**Other features already prefer an own key.** Images, video, read-aloud and dictation use the
workspace's own OpenRouter key when it has one, else Casama's (`worker/index.ts:529-535, 573-576`,
`worker/voice.ts:162-166`); memory search uses an own OpenAI key, else Casama's
(`worker/index.ts:350-365`). These already check credits themselves when they run on Casama's key
(`needCredits`, `hasCredits`).

**Remote settings exist; none does this.**

- `instance_settings` rows edited in Admin, reloaded by every process within a minute
  (`startRemoteSettings`, D-373): `cloud_models`, `model_catalog`, `app_config`.
- `app_config.flags` reaches every installed app within 30 minutes (D-241). Used for `intro_video`
  and `bot_email` only.
- `cloud_daily_usd` per plan (Admin → Pricing). Setting it to 0 would stop every run, own keys
  included (`budget.ts:39,58`), and tells people to upgrade. It can't serve as the switch.

**Rakazo.** From `docs/PRODUCT-REVIEW-2026-11-13.md`: its plans sell computer hours and charge
model use "at the provider's price, with no markup". How its own-key setting works wasn't checked
for this plan; the design below follows Oliver's description, not a reading of Rakazo's product.

## 2. Principles

1. **Casama's models stay the default.** A new person never has to find a key to get a first reply.
2. **A person's own provider is never replaced silently.** No quiet move back to Casama's key, which
   would spend credits they chose not to spend.
3. **The switch is enforced on the server.** An app flag alone would leave the API open.
4. **Switching off must not break people who already brought their own.** They shouldn't notice.
5. **Shipped apps must survive the switch.** In an emergency there is no time for a store release.
6. **What Casama still pays for stays paid for.** Computers, web search, app calls and paid data keep
   their own limits and credit checks.

## 3. The model

### 3.1 Where a run's model comes from

Three levels, first match wins:

1. **The bot's own choice.** Bot profile → Brain: "Workspace default", "Casama", or one of the
   workspace's keys with a model.
2. **The workspace default.** Settings → Models: "Casama" or one of the workspace's keys with a
   model.
3. **Casama's models**, if the plan may use them (§3.3).

If none of them gives a usable model, the run is refused with `own_provider_required` (§3.4).

**Automatic pick.** When Casama's models are off for the workspace and nobody chose a default, the
run uses the workspace's first usable chat key with that provider's default model from the model
catalog (D-373). This is what lets a shipped app keep working: adding a key is enough.

**Background work** (summaries, memory, briefs, check-in scans) follows the same source as chat,
on the provider's small model (`smallModelFor`), or a "cheap" model the person picked.

**A ChatGPT plan** keeps its rule: it runs only for its owner. A teammate's run, or a routine made
by someone else, moves to the next level down, as today (`chatgpt_plan_not_yours`).

### 3.2 When your own provider fails

A bad key, an empty balance or a plan limit stops the run with the provider's error, naming whose
key failed. It does not fall back to Casama's models unless the person turned on **"If my provider
fails, use Casama's models"** for that key. That is today's `fallback_on_limit` setting, extended
from ChatGPT plans to every key. Off by default.

### 3.3 The owner's switch

One `instance_settings` row, key `model_access`:

```json
{
  "own_providers": true,
  "casama_models": { "default": "on", "plans": { "free": "off" } },
  "note": "Casama's models are paused. Connect your own to keep going."
}
```

- `own_providers`: whether Cloud workspaces may use their own keys and plans at all. Ships `false`,
  turned on after the checks in Phase 1.
- `casama_models.default` and `.plans.<code>`: `on` or `off`. A plan without an entry follows the
  default. This covers three uses with one setting: everything on (today), Free on your own
  provider only (a cost lever), and everything off (the emergency).
- `note`: optional text shown on the blocked card, for saying why.

**What "off" covers:** everything that spends Casama's model keys (the shared OpenRouter key and
the server's Google key): chat, background work, images, video, read-aloud, dictation, live calls,
memory search, bot and workspace pictures, and the model relay that self-hosted servers reach
through Casama Link (`billing/link.ts`). Each of these already prefers the workspace's own key
(§1), so with an own OpenRouter key most keep working.

**What "off" doesn't cover:** computers, web search, app calls, paid data, phone numbers, email.
They aren't model bills and keep their own limits.

**Runs in flight** finish. New runs are checked at admission.

**Self-hosted servers** ignore the setting. They have no shared key unless their owner set one.

### 3.4 When a run is refused

Code `own_provider_required`, status 402, with a message that works as plain text in an old app:
"Casama's models aren't available on this plan right now. Add your own model key in Settings to
keep chatting." The response says which ways out apply: `connect` (always), `upgrade` (when a paid
plan still has Casama's models).

**Routines and check-ins** must not fail every few hours and push each failure. A scheduled run
refused with this code is skipped, the routine is marked "Waiting for a model", and the person
gets one notification. It resumes by itself when a model is available.

## 4. Money

- **Model use on your own provider costs no credits and has no markup.** Unchanged from self-hosted.
- **Credits are no longer needed to start a run on your own provider.** The check moves from the
  run to the things that cost Casama: a run on Casama's key (as today), and each paid tool call
  inside any run. Out of credits on your own key: chat works; web search, app calls, paid data,
  images on Casama's key and phone calls say they need credits.
- **The daily cap** (`cloud_daily_usd`) moves the same way: it stops spend on Casama's keys, never a
  run on your own.
- **Computer hours** are unchanged: a plan limit, not credits (D-442).
- **Plans stay as they are in v1.** A workspace on its own provider pays the same plan and uses its
  included credits on search, apps, data and calls instead of models. Whether to add a cheaper
  "computers only" plan is question 3 in §13; it means new products in three stores.
- **Free with your own key** costs Casama at most Free's computer hours (5) and Free's credits ($1)
  a month, the same ceiling as today.
- **If Casama's models are turned off for a paying plan,** people keep what else the plan gives.
  Whether they are owed anything for the model credits is question 4.

`docs/COSTS.md` changes in the same commit as the code: "How the money works" and the plan table
note. No new paid dependency.

## 5. Other features on your own provider

| Feature | Runs on, in order | With Casama's models off and no key of that kind |
|---|---|---|
| Chat, background work | bot's choice, workspace default, Casama | Refused with the connect card |
| Images, video, read-aloud, voice messages | own OpenRouter key, Casama | "Add an OpenRouter key to use this" |
| Dictation | own OpenRouter key, Casama | The phone's own dictation (already the fallback) |
| Live calls | own Google AI key, Casama | "Add a Google AI key to use calls" |
| Memory search | own OpenAI key, Casama | Works by keyword only, to confirm in Phase 0 |
| Web search | Casama's search keys (not model keys) | Unchanged |

A ChatGPT plan covers chat only. The Models screen says which features each connected key covers
and which are still on Casama or unavailable, so nobody finds out mid-call.

## 6. Data and API

- **`instance_settings.model_access`** (§3.3). `packages/domain/src/model-access.ts`: the check, the
  loaded copy, and `casamaModelsAllowed(planCode)`. Loaded by `startRemoteSettings` with the other
  owner settings; lenient on load, strict on save.
- **Admin routes:** `GET/PUT /v1/admin/model-access`, behind the admin console lock, each change
  written to the audit log.
- **Workspace default:** a `model_default` JSON column on `organizations`
  (`{ source: "casama" | "own", credential_id?, model?, cheap_model? }`), set through
  `PATCH /v1/workspaces/{id}` by owners and admins. One migration; check its version against every
  branch and worktree first.
- **Bot choice:** `model_policy.source`: `workspace` (the default when missing), `casama` or `own`.
  Existing Cloud bots have Casama's key saved and no `source`, so they follow the workspace.
- **Resolution:** one function, `resolveModelPolicy`, used by both places in `run.ts` that call
  `cloudRunPolicy` today, by bot create and update, by the bot template route and by check-ins.
  On Casama's key the model stays whatever Casama assigns (D-188 still holds there).
- **One gate for every other caller of Casama's keys:** voice, media, pictures, live calls, the watch
  route, telephony, memory search, the Link relay. Phase 0 lists them all; each asks
  `casamaModelsAllowed` before using a server key.
- **Config to the app:** `/v1/config` gains `own_providers`; the billing summary (per workspace)
  gains `casama_models: "on" | "off"`. `key_providers.cloud` gains the chat providers when
  `own_providers` is on, which is what makes the add-key form in shipped apps show them (D-374).
- **Credit and cap checks** move as in §4: `spend` in `run.ts` skips them when the whole chain is on
  own keys; `needCredits` covers the paid tools. Phase 0 confirms every paid tool has its own check
  (media, speech and data do; web search and app calls are to be checked).
- **Keys** stay where they are: Vault, written by the API, read only by the worker (D-015).

## 7. The app

- **Settings → Models** (today "Service keys" on Cloud). Top: "Who runs your bots", two choices:
  Casama (included, uses credits) or one of your keys. Below: your keys, with Add. The add form
  offers the chat providers and "Continue with ChatGPT" where the server allows it. Under each key,
  what it covers (§5).
- **Bot profile → Brain:** Workspace default, Casama, or a key with the model picker. The picker
  opens for own keys and stays fixed on Casama's (`casamaModelFixed` becomes "this choice is on
  Casama's key", not "billing is on").
- **Blocked card** in chat for `own_provider_required`: the owner's note, then Add a key, Connect
  ChatGPT (desktop), and See plans when upgrading helps. Same card on the empty chat and when
  creating a bot.
- **Setup:** unchanged while Casama's models are on. When they're off for the plan, setup shows the
  "connect a model" step that self-hosted setup already has.
- **Usage:** the existing "on your keys" lines; the credits meter explains that models on your own
  provider don't use credits.
- **Privacy note** on the Models screen and the privacy page: on your own provider, that provider's
  terms apply to what your bots send it. Casama's no-training setting only applies on Casama's key.
- **Shipped apps** (no update): they show the server's message as text, can add a chat key once the
  server widens `key_providers.cloud`, and the automatic pick (§3.1) takes it from there. They can't
  choose a model or connect ChatGPT. `min_versions` is there if that isn't enough.
- All native Flutter; no new packages.

## 8. Safety

- **`openai_compatible` on Cloud** takes a base URL. It must go through the worker's safe fetch (no
  private addresses). Phase 0 confirms it; if it doesn't, Cloud doesn't offer that provider.
- **Weak models.** D-188 fixed the models because a model that can't call tools breaks a bot. On
  their own key the person owns that risk: the picker lists recommended models first and warns on
  ones the catalog marks as lacking tools.
- **Whose key failed.** Errors from an own key name the key and never suggest topping up credits.
- **Team workspaces.** Only owners and admins add keys or set the default (as today). A ChatGPT plan
  stays personal.
- **Abuse.** Own keys remove Casama's model cost, not its checks: suspension, egress controls and
  plan limits apply the same.
- **Analytics:** `own_provider_added`, `model_source_changed`, `own_provider_required_shown` and its
  outcome, added to the catalog; no key material, no model text.

## 9. ChatGPT plans on Cloud

Needs OpenAI's approval for hosted use first. Until then API keys carry both halves of this plan.
After approval: `CHATGPT_SIGN_IN=on` on the server, a live check with a real plan, and the phone
and web sign-in question (today desktop and CLI only) decided then.

## 10. Tests

- Domain: `model-access.test.ts` (plans, defaults, bad rows), `resolve-model-policy.test.ts` (every
  level, the automatic pick, ChatGPT owner rule).
- Server: a Cloud bot on an own key runs at cost 0 with no credits; the same bot's paid tool is
  refused without credits; Casama off for Free refuses a Free run and passes a Pro one; a workspace
  with a key keeps running when the switch flips; a routine is skipped once, not failed repeatedly;
  the Link relay is refused; old-app shape of the error.
- Billing: existing suites stay green; the daily cap no longer stops an own-key run.
- Flutter: Models screen in each state, the bot picker, the blocked card.
- A live check on local dev with a real key before any deploy.

## 11. Phases

| Phase | What | Done when |
|---|---|---|
| 0 | Checks, no user-visible change: list every caller of Casama's model keys; confirm per-tool credit checks, safe fetch for custom URLs, memory search without a key, what a shipped app shows | The list is in this file and each "to confirm" above has an answer |
| 1 | Server: `model_access`, `resolveModelPolicy`, workspace default, bot source, credit and cap checks moved. `own_providers` off | Server tests green; nothing changes for anyone |
| 2 | App: Models screen, bot picker, usage wording, privacy note | A Cloud workspace on local dev runs a bot on its own key |
| 3 | The switch: admin card, `own_provider_required`, blocked card, routines wait, every other caller gated | Flipping it locally stops Casama's key everywhere and own-key workspaces don't notice |
| 4 | Docs: docs-site (keys, pricing), casama.ai pricing FAQ, privacy page, COSTS.md, decisions | Pages match the build |
| 5 | ChatGPT plans on Cloud | After OpenAI approves |

Phases 1 and 3 on the server, plus widening `key_providers.cloud`, are the smallest set that gives
a working emergency switch for the apps already installed. Deploys and app builds each need
Oliver's yes, in the usual order.

### Phase 0 findings (2026-11-21)

1. **Every caller of Casama's model keys (`CLOUD_MODEL_UPSTREAM_KEY` / `00000000-0000-4000-8000-0000000000c1` and `GOOGLE_AI_API_KEY`):**
   - **Agent runs (chat, routines, check-ins, subagents, delegation, projects, watchers):** `packages/agent/src/run.ts` (`runAgent` and `backgroundComplete`, which also powers starters `refreshStartersWorkflow`, call summaries `summarizeCallWorkflow`, and media safety `mediaSafetyFor`).
   - **Start verdict for check-in suggestions:** `apps/server/src/api/routes/checkins.ts` (`startVerdict` in `packages/agent/src/run.ts`).
   - **Bot creation, update, template import, and welcome:** `apps/server/src/api/routes/bots.ts` (`createBot`, `updateBot`, `handleWelcomeAction`, `startWelcome` -> `ensureBotModel`), `apps/server/src/api/routes/bot-template.ts` (`importBot`), and `packages/agent/src/tools/bots.ts` (`registerBotTools`).
   - **Credentials listing & model picker for platform key:** `apps/server/src/api/routes/bots.ts` (`listCredentials` and `listCredentialModels`).
   - **Embeddings (memory & knowledge search):** `apps/server/src/worker/index.ts` (`embedderFor`: workspace's `openai` or `openai_compatible` key first, else `platformOpenRouterKey`).
   - **Media generation (images, video, bot pictures, workspace pictures):** `apps/server/src/worker/index.ts` (`mediaFor`: workspace's `openrouter` key first, else `platformOpenRouterKey`; called by `media.image.generate`, `media.video.generate`, `drawBotPictures`, and `drawWorkspacePictures`).
   - **Spoken audio (`media.audio.generate`):** `apps/server/src/worker/index.ts` (`speechFor`: workspace's `openrouter` key first, else `platformOpenRouterKey`).
   - **Voice dictation & read-aloud (`/v1/voice/transcribe`, `/v1/messages/{id}/speech`):** `apps/server/src/worker/voice.ts` (`voiceTranscribe`, `voiceSpeak`: workspace's `openrouter` key first, else `platformOpenRouterKey`).
   - **Live calls & outbound phone calls (`/v1/voice/session`, `/telephony/stream/:id`):** `apps/server/src/worker/voice.ts` (`voiceSession`), `apps/server/src/api/routes/voice.ts`, `apps/server/src/api/routes/telephony.ts`, and `apps/server/src/billing/calls.ts` (`billsCalls`: workspace's `google` key first, else `GOOGLE_AI_API_KEY`).
   - **Watch route & `/v1/config` (`server_voice`):** `apps/server/src/api/routes/watch.ts` (`voiceFor`) and `apps/server/src/api/routes/system.ts` (`serverVoice`).
   - **Casama Link model relay (`/link/v1/models/chat/completions`, `/link/v1/whoami`):** `apps/server/src/billing/link.ts`.
   - **Decision models (`packages/agent/src/decide.ts`):** When `billable` and acting (`mode === "on"`), gated on `casamaModelsAllowed`.
2. **Per-tool credit checks:**
   - Confirmed `needCredits` / `hasCredits` already gate images, video, bot pictures, workspace pictures (`autonomy.ts`), spoken audio (`autonomy.ts`), paid data (`data.ts`), dictation & read-aloud (`worker/voice.ts`), and live/phone calls (`routes/voice.ts`, `routes/telephony.ts`).
   - `web.search` on the server's chain is not billed to credits (`billable: false`, D-400).
   - Managed Composio app calls (`kind: "app_calls"` in `packages/agent/src/run.ts`) recorded billable ledger rows without checking `needCredits` first; Phase 1 adds `await needCredits(db, ctx.orgId, cloudCharge(COMPOSIO_CALL_USD))` before `adapter.callTool` when `billApps` is true.
3. **`openai_compatible` and safe fetch:**
   - `AiSdkGateway`, `listCredentialModels`, `testCredential`, and `openAiEmbedder` now use `safeFetch` whenever `billing` is enabled (and `createCredential` checks `assertSafeUrl(body.base_url)` on Cloud), so `openai_compatible` can be safely offered on Cloud without private-address SSRF.
4. **Memory search without an embedding key:**
   - Confirmed in `packages/agent/src/memory.ts`: when `embedderFor` returns `null`, `public.search_memories(botId, query, null, limit)` runs Postgres full-text keyword search (`tsv @@ websearch_to_tsquery`) plus pinned memories, and `MemoryService.write` stores `embedding = null` with normalized text deduplication.
5. **What a shipped app shows:**
   - Confirmed in `client/lib/features/settings/model_keys_screen.dart` and `error_details.dart`: widening `key_providers.cloud` in `GET /v1/config` makes shipped apps show all chat providers in the add-key form, and `own_provider_required` renders its plain-text fallback message in the chat notice bubble; once the user adds a chat key, the server's automatic pick runs their bots on that key's default model.

## 12. Not in this plan

- **Leaving Casama Cloud:** exporting a workspace and bringing it up on a self-hosted server. This
  is the real answer to "what if Casama Cloud shuts down" and deserves its own plan.
- **A "computers only" plan and its store products** (question 3).
- **Own keys for web search and app connections on Cloud.**
- **One Casama key per workspace** (D-186 left it for later).

## 13. Questions for Oliver

| # | Question | Recommended |
|---|---|---|
| 1 | Who may bring their own provider on Cloud: every plan, or paid plans only? | Every plan. Free's cost to Casama stays capped by its hours and credits |
| 2 | Per-bot choice as well as the workspace default? | Yes. It is how "more flexible than Rakazo" shows |
| 3 | A cheaper "computers only" plan now? | Not in v1. Same plans, credits go further. Decide after seeing how many switch |
| 4 | If Casama's models are turned off for a paying plan, what do those people get? | Keep the plan; the owner's note explains. Refunds case by case |
| 5 | Fall back to Casama's models when an own provider fails? | Only when the person turned it on for that key |
| 6 | Should the switch also be able to turn off only chat, leaving images and voice on Casama's keys? | No. One switch for all of Casama's model keys |
| 7 | Offer custom model URLs (`openai_compatible`) on Cloud? | Yes if Phase 0 confirms safe fetch |
| 8 | Send the OpenAI hosted-use interest form now? | Yes; it gates Phase 5 only |
| 9 | Build order: all phases, or the emergency set (1 and 3) first? | 1, 2, 3 in order; the app work is small next to the server's |
