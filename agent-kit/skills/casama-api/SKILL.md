---
name: casama-api
description: "Call Casama from code: sign in, create a conversation, send a message, stream or poll run events (SSE), decide approvals, cancel runs, handle problem+json errors, paging, idempotency, and inbound webhooks with HMAC signatures. Use for Casama HTTP API, REST, OpenAPI, SDK, CLI, curl or webhook work."
---

# Casama HTTP API

Everything the apps do goes through one HTTP API under `/v1`. Routes are Zod schemas in
`packages/contracts`; the OpenAPI 3.1 document is generated from them, so trust the document.

- Base URL: Casama Cloud `https://api.casama.ai`, or a self-hosted server's address.
- OpenAPI: https://docs.casama.ai/api/openapi.json (or `<server>/openapi.json`; reference UI at
  `<server>/docs`). With the docs MCP server, `get_api_operation("POST /v1/routines")` returns
  one operation's parameters and schemas.
- Full pages: https://docs.casama.ai/develop/api.md and https://docs.casama.ai/develop/webhooks.md

## Authentication

`/v1` takes a **Supabase access token** (JWT, `aud=authenticated`, `role=authenticated`) as
`Authorization: Bearer <token>`. Casama has no sign-in endpoint of its own; sign in at the Auth
server named in `GET /v1/config` (no auth):

```sh
API=https://api.casama.ai
CONFIG=$(curl -s "$API/v1/config")
SUPABASE_URL=$(echo "$CONFIG" | jq -r .supabase_url)
ANON_KEY=$(echo "$CONFIG" | jq -r .supabase_anon_key)
TOKEN=$(curl -s "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" -H "content-type: application/json" \
  -d '{"email":"ana@example.com","password":"..."}' | jq -r .access_token)
AUTH="authorization: Bearer $TOKEN"
```

The response has `access_token`, `refresh_token`, `expires_in`. Refresh before expiry with
`grant_type=refresh_token` and `{"refresh_token": "..."}`. For scripts, use a dedicated account.

- **Workspace API keys (`ksk_...`) do NOT work on `/v1`.** They are for the hosted MCP endpoint
  (`<server>/mcp`) and A2A (`/a2a/{bot id}`) only.
- Admin actions in a workspace that requires two-step sign-in answer 403 `mfa_required` until the
  session is `aal2`.
- No token needed: `GET /v1/config`, `GET /v1/app-config`, `GET /v1/signup/challenge`,
  `GET /v1/join/preview`, `GET /v1/referral/preview`, `POST /v1/auth/pairing-codes/redeem`,
  `/healthz`, `/readyz`, and `/hooks/*` (signature-checked).

## Core flow: chat with a bot

```sh
ORG=$(curl -s "$API/v1/orgs" -H "$AUTH" | jq -r '.items[0].id')
curl -s "$API/v1/bots?org_id=$ORG" -H "$AUTH" | jq -r '.items[] | "\(.id) \(.name)"'

CONV=$(curl -s -X POST "$API/v1/conversations" -H "$AUTH" -H "content-type: application/json" \
  -d "{\"bot_id\":\"$BOT\",\"title\":\"From a script\"}" | jq -r .id)          # 201

RUN=$(curl -s -X POST "$API/v1/conversations/$CONV/messages" -H "$AUTH" \
  -H "content-type: application/json" -H "idempotency-key: $(uuidgen)" \
  -d '{"text":"Summarize the open issues"}' | jq -r .run_id)                    # 202
```

`sendMessage` returns `message_id`, `run_id`, `conversation_id` (and `joined: true` when the bot
was already running in that chat; then `run_id` is that run). Message `text` max 100,000 chars,
max 10 attachments.

Then `GET /v1/runs/{id}` (status, `tokens_in`, `tokens_out`, `cost_usd`, `error`) and
`GET /v1/conversations/{id}/thread` (messages, oldest first, each with its `reactions`).

Reactions (D-331): `PUT /v1/conversations/{id}/messages/{message_id}/reaction` with
`{"emoji": "👍"}` sets yours (one per person per message; another emoji replaces it), `DELETE` on
the same path takes it back, `GET …/reactions` lists who reacted. Exactly one emoji or 400
`invalid_emoji`. A reaction doesn't start a run; the bot sees it next turn, and 👎 counts as a
correction for skill learning.

## Run events

Envelope: `{v: 1, run_id, seq, ts, bot_id, type, payload}`. `seq` is 1, 2, 3... per run, no gaps.

**Poll:** `GET /v1/runs/{id}/events?after_seq=0&limit=500` → `{items, run_status}`. `limit` 1-1000
(default 500). Page by passing the last `seq` as `after_seq`. `run_status`: `queued`, `running`,
`waiting_approval`, `waiting_takeover`, `completed`, `failed`, `cancelled`.

**Stream (SSE):** same URL with `Accept: text/event-stream`. Sends stored events after
`after_seq`, then live ones. Each `event: run_event` has `id: <seq>`; `event: ping` every 15 s.
The server closes after the terminal event. Reconnect with `Last-Event-ID: <last seq>` (or
`?after_seq=`) to get exactly what you missed.

| Type | Payload |
| --- | --- |
| `run.started` | `trigger`, `model`, `computer_id` |
| `message.delta` | `message_id`, `text` (append) |
| `message.completed` | `message_id`, `content` |
| `tool.started` / `tool.output` | `call_id`, `tool`, `args_redacted` / `call_id`, `chunk` |
| `tool.completed` / `tool.failed` | `call_id`, `result_preview`, `artifact_path`, `duration_ms` / `call_id`, `error_code`, `message` |
| `approval.requested` | `approval_id`, `tool`, `args_redacted`, `risk`, `expires_at` |
| `approval.resolved` | `approval_id`, `decision` (`approved`/`denied`/`expired`), `decided_by` |
| `usage` | `tokens_in`, `tokens_out`, `cost_usd` (running totals) |
| `notice` | `code`, `message` |
| `run.completed` / `run.failed` / `run.cancelled` | `final_message_id` / `error_code`, `message` / `cancelled_by` (terminal) |

Others exist (`secret.*`, `takeover.*`, `computer.state`, `checkpoint.created`, `subrun.*`,
`memory.written`, `skill.loaded`, `model.fallback`, `ui.shown`, ...). **Ignore unknown types.**

## Approvals and cancel

```sh
curl -s -X POST "$API/v1/approvals/$APPROVAL/decision" -H "$AUTH" \
  -H "content-type: application/json" -d '{"decision":"approved","always_allow":false}'
curl -s "$API/v1/approvals?org_id=$ORG&status=pending" -H "$AUTH"
curl -s -X POST "$API/v1/runs/$RUN/cancel" -H "$AUTH"    # 202; 409 run_finished if already ended
```

`decision` is `approved` or `denied`; `always_allow: true` stops asking for that tool on that bot.
Denying fails only that step. Cancel stops the run and its helper runs within about 2 s.

## Errors (RFC 9457, `application/problem+json`)

`{type, title, status, code, detail, instance, errors?}`. **Match on `code`.** `errors` lists
`{path, message}` for `validation_failed`. Common codes: 400 `validation_failed`; 401
`unauthorized`, `invalid_token`; 402 `plan_limit`, `workspace_limit`, `paid_plan_required`,
`out_of_credits` (billing on only); 403 `forbidden`, `mfa_required`, `email_unverified`,
`workspace_suspended`; 404 `not_found`, `bot_not_found`, `conversation_not_found`...; 409
`run_finished`; 422 `idempotency_key_reused`; 429 `rate_limited` (honor `Retry-After`); 503
`computer_unavailable`, `capacity_full` (retry). Every response has `x-request-id`; send your own
to correlate.

## Rate limits, idempotency, paging

- 120 requests/minute per user (or IP without a token) by default (`RATE_LIMIT_PER_MINUTE`).
- `Idempotency-Key` on `POST`/`PUT`/`PATCH`/`DELETE`: max 255 chars, kept 24 h per user; replays
  return the stored response with `idempotent-replayed: true`; different method/path → 422.
- Most lists return everything as `{items: [...]}`. Paged: run events (`after_seq`, `limit`),
  `GET /v1/creations` (`cursor` ← `next_cursor` until `null`, `limit` 1-100), conversation
  thread (`limit` up to 500, `before=<message id>`).

## Inbound webhooks (start a routine from another service)

Create a routine with `"trigger": "webhook"` (or `"github"` plus optional `events`, max 20):

```sh
curl -s -X POST "$API/v1/routines" -H "$AUTH" -H "content-type: application/json" \
  -d '{"bot_id":"'"$BOT"'","name":"Triage orders","instructions":"Check stock...","trigger":"webhook"}'
```

The 201 response includes `webhook_url` (`/hooks/custom/<routine id>`, or `/hooks/github/<id>`)
and `webhook_secret`, **shown only once**. Optional `ends_at` / `max_runs` (1-10,000).

Signature: `sha256=` + hex HMAC-SHA256 of the **raw body** keyed with the secret, in
`X-Casama-Signature` (GitHub sends `X-Hub-Signature-256`). Optional `X-Casama-Event` names the
event.

```js
import { createHmac } from "node:crypto";
const body = JSON.stringify({ order_id: 1042 });
const sig = `sha256=${createHmac("sha256", secret).update(body).digest("hex")}`;
await fetch(url, { method: "POST", body,
  headers: { "content-type": "application/json", "x-casama-signature": sig, "x-casama-event": "order.created" } });
```

Gotchas: Casama answers **202 `{"accepted": true}` before checking**, even for a bad signature or
unknown routine; verify by watching for a run in the bot's chat. Sign the exact bytes you send. No
deduplication: every valid delivery is a run. 413 over 1 MB; the bot sees the first 50,000 chars,
marked untrusted. `/hooks/*` share the 120/min per-IP limit.

## SDKs and CLI

- **Dart / Flutter:** `casama_sdk` (`CasamaClient.connect(url)`, `signIn`, per-area clients such
  as `casama.chat.sendMessage`, `watchRun(client, runId)` with catch-up, ordering and reconnect,
  `problemOf(e)` for problem codes). https://docs.casama.ai/develop/sdk.md
- **CLI:** `casama` (`brew install stackwares/tap/casama`). `casama login`, `casama --json chat
  <bot> "..."` prints run events as JSON Lines; `casama runs watch <run id>`. Defaults to
  `https://api.casama.ai`; override with `--api` or `CASAMA_API_URL`.
  https://docs.casama.ai/develop/cli.md
- **TypeScript:** `npm i @casama/client`. `createCasamaClient({ apiUrl, token | getToken })` gives
  typed `GET`/`POST`/… calls for every route, plus `ask(botId, text)` (sends, waits, returns the
  reply), `watchRun(runId)` (SSE with poll fallback), `decideApproval`, `cancelRun` and
  `CasamaError` from problem+json. https://docs.casama.ai/develop/typescript.md

## Checklist

- [ ] Bearer user token from Supabase Auth, refreshed before `expires_in`; no `ksk_` keys on `/v1`
- [ ] `Idempotency-Key` on every retried write
- [ ] Event consumer tracks `seq`, resumes with `Last-Event-ID`, ignores unknown types and `ping`
- [ ] Handles `approval.requested` (or tells a person) so runs don't wait forever
- [ ] Errors switch on `code`; 429/503 retried with `Retry-After` / backoff
- [ ] Webhook signer HMACs the exact raw bytes; secret stored safely (shown once)
