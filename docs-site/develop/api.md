# HTTP API

Everything the Casama apps do goes through one HTTP API, and you can call it too: from a shell
script, a backend service or your own app. This page covers what every request has in common
(authentication, errors, rate limits, idempotency) and how to follow a bot's work live. For every
endpoint and schema, see the [API reference](/api/).

The routes are defined once, as Zod schemas in `packages/contracts`, and the OpenAPI document is
generated from them. So the reference, the Dart client and the server can't drift apart.

## Base URL and versioning

Use your server's API address, for example `https://casama.example.com`. Every route lives under
`/v1`:

```sh
curl https://casama.example.com/v1/config
```

| Path | What it is |
| --- | --- |
| `/v1/...` | The API |
| `/openapi.json` | The OpenAPI 3.1 document for this server |
| `/docs` | An interactive reference rendered from that document |
| `/healthz` | `{"status":"ok"}` while the process is up |
| `/readyz` | 200 when the database and other dependencies answer, 503 when they don't |

The `/v1` prefix changes only for breaking changes. Within `/v1`, new fields, endpoints and event
types can appear at any time, so ignore fields you don't know. The server's version is in
`api_version` from `GET /v1/config` and in `info.version` of `/openapi.json`.

## Public configuration

`GET /v1/config` needs no sign-in. It tells a client everything it needs besides the API address:

```sh
curl -s https://casama.example.com/v1/config
```

```json
{
  "product_name": "Casama",
  "api_version": "0.8.0",
  "supabase_url": "https://auth.casama.example.com",
  "supabase_anon_key": "eyJhbGciOi...",
  "billing_enabled": false,
  "default_models": { "openrouter": "...", "openai": "..." },
  "default_reasoning_effort": "medium"
}
```

| Field | Meaning |
| --- | --- |
| `supabase_url`, `supabase_anon_key` | Where and how to sign in (see below) |
| `billing_enabled` | Whether plans and paywalls apply on this server |
| `default_models` | The default model id for each model provider |
| `default_reasoning_effort` | `none`, `low`, `medium`, `high`, `xhigh` or `max` |
| `signup_proofs` | Proofs a new account must carry, if any: `app_check`, `pow` |
| `chatgpt_sign_in` | Whether people can connect a ChatGPT plan here |
| `wallpapers_enabled` | Whether wallpaper photo search is available |
| `trace_url_template` | Where a run's trace opens, with `{trace_id}` in it, or `null` |
| `server_voice` | Voice features the server's own keys cover: `live`, `read_aloud`, `dictation` |
| `google_client_ids` | Google client ids Auth accepts, for Google's own sign-in sheet in the apps |

The fields after `default_reasoning_effort` are optional and may be missing on some servers.

## Authentication

The API accepts a **Supabase access token** (a JWT) as a bearer token:

```http
Authorization: Bearer eyJhbGciOi...
```

You get one by signing in to the Supabase Auth server named in `/v1/config`. Casama doesn't run
its own sign-in endpoint; it verifies the token's signature and requires
`aud=authenticated` and `role=authenticated`.

### Sign in with email and password

```sh
API=https://casama.example.com
CONFIG=$(curl -s "$API/v1/config")
SUPABASE_URL=$(echo "$CONFIG" | jq -r .supabase_url)
ANON_KEY=$(echo "$CONFIG" | jq -r .supabase_anon_key)

curl -s "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "content-type: application/json" \
  -d '{"email": "ana@example.com", "password": "correct-horse-battery"}'
```

The response holds `access_token`, `refresh_token` and `expires_in` (seconds). Send the access token
to Casama. Before it expires, trade the refresh token for a new pair:

```sh
curl -s "$SUPABASE_URL/auth/v1/token?grant_type=refresh_token" \
  -H "apikey: $ANON_KEY" \
  -H "content-type: application/json" \
  -d '{"refresh_token": "..."}'
```

These are standard Supabase Auth endpoints, so any Supabase client library works too. The
[Dart SDK](/develop/sdk) and the [CLI](/develop/cli) handle sign-in and refresh for you, including
magic-link codes and two-step sign-in.

::: tip Two-step sign-in
A workspace can require two-step sign-in for its owners and admins. A token from a password-only
sign-in still works for everything else, but admin actions in that workspace answer 403 with the
code `mfa_required` until you verify a second factor (an `aal2` session).
:::

### What about workspace API keys?

Workspace API keys (`ksk_...`, created by admins in workspace settings) don't work on `/v1`. They're
for the [hosted MCP endpoint](/guide/mcp) and for [agent-to-agent](/develop/a2a) calls. For
scripts that call the REST API, sign in as a person (a dedicated account works well) and refresh
the token as shown above.

### Endpoints without a token

A few endpoints need no bearer token: `GET /v1/config`, `GET /v1/app-config` (the owner's
[remote app settings](/self-hosting/operations#remote-app-settings)), `GET /v1/signup/challenge`, `/healthz`,
`/readyz`, and the inbound [webhooks](/develop/webhooks) under `/hooks/`, which check a signature
instead.

## Errors

Errors use [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) problem details, with the content
type `application/problem+json` and a stable `code` you can match on:

```json
{
  "type": "https://casama.ai/problems/validation_failed",
  "title": "Bad Request",
  "status": 400,
  "code": "validation_failed",
  "detail": "Request validation failed",
  "instance": "/v1/conversations",
  "errors": [{ "path": "bot_id", "message": "Invalid UUID" }]
}
```

| Field | Meaning |
| --- | --- |
| `code` | Stable, machine-readable. Match on this, not on `title` or `detail`. |
| `status` | The HTTP status, repeated |
| `title` | The status's standard name |
| `detail` | A sentence for people. It can change. |
| `instance` | The request path |
| `errors` | For `validation_failed`: one entry per bad field, with its dotted `path` |

Common codes:

| Status | Code | When |
| --- | --- | --- |
| 400 | `validation_failed` | The body, query or path didn't match the schema |
| 401 | `unauthorized` | No bearer token on a route that needs one |
| 401 | `invalid_token` | The token is malformed, expired or not a user token |
| 402 | `plan_limit`, `workspace_limit`, `paid_plan_required` | A plan limit was reached (only when billing is on) |
| 403 | `forbidden` | You're signed in but not allowed to do this |
| 403 | `mfa_required` | The workspace requires two-step sign-in for this |
| 404 | `not_found` | No such route |
| 404 | `bot_not_found`, `org_not_found`, `conversation_not_found`, ... | The thing doesn't exist or you can't see it |
| 409 | `run_finished` | You tried to cancel a run that already ended |
| 409 | `device_offline` | A personal computer's desktop app isn't connected |
| 422 | `idempotency_key_reused` | The `Idempotency-Key` was used for a different request |
| 429 | `rate_limited` | Too many requests; see `Retry-After` |
| 500 | `internal_error` | A server bug. Retry later; the server logged it. |
| 503 | `computer_unavailable` | The bot's computer couldn't be reached (stopping, waking or restarting). Retry shortly. |

Every response carries an `x-request-id` header. Send your own `x-request-id` to tie a request to
your logs, and include it when you report a problem.

## Rate limits

Requests to `/v1/*` and `/hooks/*` are limited per minute, per signed-in user (or per client IP
address without a token). The default is 120 requests a minute; self-hosters change it with
`RATE_LIMIT_PER_MINUTE`.

Over the limit, the API answers 429 with the code `rate_limited` and a `Retry-After` header in
seconds. Wait that long, then retry.

The window is a fixed minute kept in the API process's memory, so a server that runs several API
processes counts each one separately.

## Idempotency keys

Network errors happen. To retry a `POST`, `PUT`, `PATCH` or `DELETE` without doing it twice, send
an `Idempotency-Key` header with a value you generate once per action (a UUID works well):

```sh
curl -s -X POST "$API/v1/conversations/$CONVERSATION/messages" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -H "idempotency-key: 6f1c2b7e-4c1a-4f0e-9a43-2b8d0f7c9e11" \
  -d '{"text": "Draft the weekly update"}'
```

- The first response that isn't a server error (status below 500) is stored, and a retry with the
  same key gets the same status and body back, with the header `idempotent-replayed: true`.
- Keys belong to the signed-in user and are kept for 24 hours.
- Reusing a key for a different method or path answers 422 `idempotency_key_reused`.
- Keys are up to 255 characters. Requests without a token, and `GET` requests, ignore the header.

## Lists and pagination

Most list endpoints return everything you can see in one response, wrapped in an object:

```json
{ "items": [ { "id": "..." } ] }
```

Run events are the exception: they're paged by sequence number (see below). A few other endpoints
take a `limit` query parameter; the [API reference](/api/) lists each endpoint's parameters.

## Runs and live events

When you send a message, the bot starts a **run**: one piece of work, from reading your message to
its final answer. Every step of a run is an **event**, stored in order. You can read them after the
fact, or stream them while the run works.

### The event envelope

```json
{
  "v": 1,
  "run_id": "0b9e7c52-1f0a-4a4e-9d2c-6f3f1b0d8a11",
  "seq": 7,
  "ts": "2026-11-11T21:04:05.123Z",
  "bot_id": "5d0c1e6a-8b7f-4e8a-a1d2-3c4b5a6f7e80",
  "type": "message.delta",
  "payload": { "message_id": "c1f9...", "text": "Here's the draft" }
}
```

| Field | Meaning |
| --- | --- |
| `v` | Protocol version, currently `1` |
| `run_id`, `bot_id` | Which run, which bot |
| `seq` | 1, 2, 3, ... per run, with no gaps |
| `ts` | When it happened |
| `type` | The event type |
| `payload` | Depends on `type` |

Ignore event types you don't know: new ones are added without a version change.

### Event types

The ones most clients care about:

| Type | Payload | Meaning |
| --- | --- | --- |
| `run.started` | `trigger`, `model`, `computer_id` | The run began |
| `message.delta` | `message_id`, `text` | A piece of the bot's reply; append `text` |
| `message.completed` | `message_id`, `content` | The reply is complete; `content` is the full list of parts |
| `tool.started` | `call_id`, `tool`, `args_redacted` | The bot started using a tool |
| `tool.output` | `call_id`, `chunk` | Output from a running tool, such as a shell command |
| `tool.completed` | `call_id`, `result_preview`, `artifact_path`, `duration_ms` | The tool finished |
| `tool.failed` | `call_id`, `error_code`, `message` | The tool failed; the run usually goes on |
| `approval.requested` | `approval_id`, `tool`, `args_redacted`, `risk`, `expires_at` | The bot is waiting for someone to approve a step |
| `approval.resolved` | `approval_id`, `decision`, `decided_by` | `approved`, `denied` or `expired` |
| `usage` | `tokens_in`, `tokens_out`, `cost_usd` | Running totals for the run |
| `notice` | `code`, `message` | Something the person should know about the run |
| `run.completed` | `final_message_id` | Finished. The last event. |
| `run.failed` | `error_code`, `message` | Failed. The last event. |
| `run.cancelled` | `cancelled_by` | Cancelled. The last event. |

Others you may see: `secret.requested` and `secret.resolved` (the bot asked for a secret),
`takeover.requested` and `takeover.resolved` (the bot asked a person to take over its computer),
`lease.changed`, `computer.state`, `checkpoint.created`, `subrun.started` and `subrun.completed`
(work handed to a helper), `memory.written`, `skill.loaded`, `model.fallback`,
`device.access_requested`, `device.data_used`, and `ui.shown` (an interactive card in the chat).
The [API reference](/api/) has every payload as a schema (`RunEvent`).

### Read events after the fact

```sh
curl -s "$API/v1/runs/$RUN/events?after_seq=0&limit=500" \
  -H "authorization: Bearer $TOKEN"
```

```json
{ "items": [ { "v": 1, "seq": 1, "type": "run.started", "...": "..." } ], "run_status": "running" }
```

`after_seq` (default 0) returns events with a higher `seq`. `limit` is 1 to 1000 (default 500). To
page, call again with `after_seq` set to the last `seq` you got. `run_status` is the run's status
right now: `queued`, `running`, `waiting_approval`, `waiting_takeover`, `completed`, `failed` or
`cancelled`.

### Stream events live (SSE)

Send `Accept: text/event-stream` to the same endpoint to get a
[server-sent event](https://html.spec.whatwg.org/multipage/server-sent-events.html) stream:

```sh
curl -sN "$API/v1/runs/$RUN/events" \
  -H "authorization: Bearer $TOKEN" \
  -H "accept: text/event-stream"
```

```text
event: run_event
data: {"v":1,"run_id":"0b9e...","seq":1,"ts":"...","bot_id":"5d0c...","type":"run.started","payload":{...}}
id: 1

event: run_event
data: {"v":1,"run_id":"0b9e...","seq":2,"ts":"...","bot_id":"5d0c...","type":"message.delta","payload":{...}}
id: 2

event: ping
data: {}
```

- The stream first sends every stored event after `after_seq`, then live events as they happen.
- Each `run_event` has the event's `seq` as its SSE `id`.
- While nothing happens, a `ping` event arrives every 15 seconds. Ignore it.
- The server closes the stream after `run.completed`, `run.failed` or `run.cancelled`. If the run
  had already ended, you get the stored events and then the stream closes.

**Reconnecting.** If the connection drops, reconnect with the `Last-Event-ID` header set to the
last `seq` you processed (or `?after_seq=`). You get exactly the events you missed. Events are
stored before they're sent, so nothing is lost and nothing is sent twice if you track `seq`.
The Dart SDK's `watchRun` does this for you, with backoff.

::: details Apps: Supabase Realtime
The Casama app gets live events through Supabase Realtime instead (private topic `run:<run id>`)
and fills any gaps from `GET /v1/runs/{id}/events?after_seq=`. SSE is the simpler choice for
scripts and servers.
:::

### Approvals

When a run waits on an `approval.requested` event, a person with access approves or denies it:

```sh
curl -s -X POST "$API/v1/approvals/$APPROVAL/decision" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{"decision": "approved"}'
```

`decision` is `approved` or `denied`; add `"always_allow": true` to stop asking about this tool for
this bot. Denying fails only that step, and the bot carries on.
`GET /v1/approvals?org_id=...&status=pending` lists what's waiting. See [Autonomy and approvals](/guide/autonomy) for how risk decides what asks.

### Cancel a run

```sh
curl -s -X POST "$API/v1/runs/$RUN/cancel" -H "authorization: Bearer $TOKEN"
```

The API answers 202 with the run, and the worker stops it (and any helper runs it started) within
about two seconds. The run then ends with a `run.cancelled` event. Cancelling a run that already
ended answers 409 `run_finished`.

## Walkthrough: chat with a bot from the shell

This puts it all together with `curl` and `jq`. You need an account on the server and a bot you can
use.

**1. Sign in.**

```sh
API=https://casama.example.com
CONFIG=$(curl -s "$API/v1/config")
SUPABASE_URL=$(echo "$CONFIG" | jq -r .supabase_url)
ANON_KEY=$(echo "$CONFIG" | jq -r .supabase_anon_key)

TOKEN=$(curl -s "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" -H "content-type: application/json" \
  -d '{"email": "ana@example.com", "password": "correct-horse-battery"}' | jq -r .access_token)
AUTH="authorization: Bearer $TOKEN"
```

**2. Find your workspace and bot.**

```sh
ORG=$(curl -s "$API/v1/orgs" -H "$AUTH" | jq -r '.items[0].id')
curl -s "$API/v1/bots?org_id=$ORG" -H "$AUTH" | jq -r '.items[] | "\(.id)  \(.name)"'
BOT=5d0c1e6a-8b7f-4e8a-a1d2-3c4b5a6f7e80   # pick one from the list
```

**3. Start a conversation.**

```sh
CONVERSATION=$(curl -s -X POST "$API/v1/conversations" -H "$AUTH" \
  -H "content-type: application/json" \
  -d "{\"bot_id\": \"$BOT\", \"title\": \"From the shell\"}" | jq -r .id)
```

**4. Send a message.** The API answers 202 with the run it started.

```sh
RUN=$(curl -s -X POST "$API/v1/conversations/$CONVERSATION/messages" -H "$AUTH" \
  -H "content-type: application/json" \
  -H "idempotency-key: $(uuidgen)" \
  -d '{"text": "What can you do for me? Answer in three bullets."}' | jq -r .run_id)
```

The response also has `message_id` and `conversation_id`. If the bot was already working in this
conversation, `joined` is `true` and `run_id` is that run: it reads your message before its next
step.

**5. Stream the run** and print the reply as it arrives:

```sh
curl -sN "$API/v1/runs/$RUN/events" -H "$AUTH" -H "accept: text/event-stream" |
  while IFS= read -r line; do
    case "$line" in
      data:*)
        json=${line#data: }
        case $(echo "$json" | jq -r '.type // empty') in
          message.delta) printf '%s' "$(echo "$json" | jq -r .payload.text)" ;;
          tool.started)  echo; echo "[tool] $(echo "$json" | jq -r .payload.tool)" ;;
          run.failed)    echo; echo "failed: $(echo "$json" | jq -r .payload.message)" ;;
          run.completed) echo ;;
        esac ;;
    esac
  done
```

**6. Check the result.** `GET /v1/runs/{id}` returns the run's status, tokens, cost and any error;
`GET /v1/conversations/{id}/thread` returns the conversation's messages, oldest first.

```sh
curl -s "$API/v1/runs/$RUN" -H "$AUTH" | jq '{status, tokens_in, tokens_out, cost_usd, error}'
```

## Limits

| What | Limit |
| --- | --- |
| Requests | 120 a minute per user or IP address by default (`RATE_LIMIT_PER_MINUTE`) |
| `Idempotency-Key` | 255 characters; kept 24 hours |
| Message `text` | 100,000 characters |
| Attachments per message | 10 |
| Run events per page | 1,000 (default 500) |
| Bots in a group chat | 10 |

## Related

- [API reference](/api/): every endpoint and schema
- [Dart SDK](/develop/sdk): a typed client with sign-in and `watchRun`
- [CLI](/develop/cli): the same API from your terminal
- [Webhooks](/develop/webhooks): start routines from other services
- [Agent-to-agent (A2A)](/develop/a2a): call bots with workspace API keys
- [Hosted MCP](/guide/mcp): use bots from AI apps
