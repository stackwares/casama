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
  "api_version": "0.1.0",
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
| `sign_in_codes` | Whether this server makes scan-to-sign-in codes (see below) |
| `signups_open` | `false` when new accounts can't be made here, so a client should offer only sign-in |
| `signups_by_invitation` | Whether new accounts are only for email addresses someone on this server invited. Also `true` while Casama Cloud's sign-up gate is on |
| `signup_gate` | Only while Casama Cloud's gate is on: `{ "mode": "invite_only", "waitlist_url": "…" }`. Absent otherwise |

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

A few endpoints need no bearer token:

- `GET /v1/config`, `GET /v1/app-config` (the owner's
  [remote app settings](/self-hosting/operations#remote-app-settings)) and `GET /v1/signup/challenge`
- `GET /v1/join/preview` and `GET /v1/referral/preview`, which show what an invite opens before
  you join
- the [waitlist routes](#the-waitlist-casama-cloud)
- `POST /v1/auth/pairing-codes/redeem`, which trades a scanned sign-in code for a one-time sign-in
  token
- `/healthz` and `/readyz`
- the inbound [webhooks](/develop/webhooks) under `/hooks/`, which check a signature instead

Two WebSocket endpoints carry their own tokens instead of a bearer token: a computer's live view
(`GET /v1/computers/{id}/stream`, with the token from `POST /v1/computers/{id}/stream-session`) and
the desktop app's computer connection (`GET /v1/local-computer/connect`).

### Sign in another device with a code

When `sign_in_codes` is `true` in `/v1/config`, a signed-in client can make a one-time code with
`POST /v1/auth/pairing-codes` and show it as a QR code. The other device posts the scanned code to
`POST /v1/auth/pairing-codes/redeem` and gets a one-time sign-in token back. The apps use this to
sign a phone in to a server reached through [Casama Link](/guide/casama-link).

## The waitlist (Casama Cloud)

Casama Cloud can take new accounts by invitation only. The routes below exist only there. A server
without the waitlist, such as a self-hosted one, answers every one of them with 404
`waitlist_off`. While the gate is on, `GET /v1/config` carries `signup_gate` and
`signups_by_invitation: true`.

Signed out. The first two need a solved sign-up puzzle (see `GET /v1/signup/challenge`):

| Route | What it does | Errors |
| --- | --- | --- |
| `POST /v1/waitlist` | Adds an email address to the waitlist. Sends no email. Answers the same for every address | 400 `bad_email`, 400 `disposable_email`, 403 `proof_required`, 404 `waitlist_off`, 429 `too_many_attempts` |
| `POST /v1/waitlist/redeem` | Claims an invite code for an email address, which can then sign up with any sign-in method. Takes `email`, or an Apple or Google ID token instead (below) | 400 `bad_email`, 400 `disposable_email`, 400 `bad_id_token`, 400 `provider_off`, 403 `proof_required`, 404 `invite_not_found`, 404 `waitlist_off`, 429 `too_many_attempts`, 503 when Apple's or Google's keys can't be fetched |
| `GET /v1/invites/preview?code=` | Says what an invite code is and whether it has an invite left | 404, 429 |
| `POST /v1/waitlist/leave` | Takes an address off the waitlist, with the token from its "You're in" email | 400, 404, 429 |

A code is a member's 6-character code, a campaign code, the one-time code from a "You're in" email
(`XXXX-XXXX`, good for one more address), or an invite link. `kind` in the answer is `personal`,
`campaign` or `one_time`.

**With an ID token.** For Sign in with Apple and Google's own sign-in sheet, send the ID token
instead of `email`, and the address inside it is let in. That is how an Apple "Hide My Email"
address gets an invite. Then sign in with the same token.

```json
{
  "code": "SHOWHN-DEC8",
  "id_token": "<the ID token>",
  "provider": "apple",
  "token_nonce": "<the raw nonce the token was requested with>",
  "proof": { "challenge": "…", "nonce": "…" },
  "source": "app_ios"
}
```

The server checks the token's signature against Apple's or Google's published keys, its issuer,
its expiry and its audience (one of the client ids Auth accepts: `APPLE_SIGNIN_APP_ID` and
`APPLE_SIGNIN_SERVICES_ID` for Apple, `GOOGLE_AUTH_CLIENT_ID` for Google). When the token carries
a `nonce` claim, send the raw nonce as `token_nonce`: the claim must be its SHA-256 in hex, as Auth
checks it. A Google address must be verified.

**At sign-up.** A sign-up can carry the code in its user metadata, and the sign-up hook claims it for
the sign-up's address on the spot, the same way. With supabase-js or supabase_flutter that is
`options.data.invite_code` (`data: { "invite_code": "SHOWHN-DEC8" }`). A used-up code puts the
address on the waitlist and the sign-up is refused with the usual sentence. An email sign-up still
needs its `signup_proof`, and the proof is checked before the code is used.

Instance owners only:

| Route | What it does | Errors |
| --- | --- | --- |
| `GET /v1/admin/waitlist` | Numbers, the gate, the daily batch's last day (`stats.last_batch`) and a page of entries | 401, 403, 404 |
| `POST /v1/admin/waitlist/admit` | Lets in chosen entries, or the next N. They are let in as their "You're in" emails go out, never more than the day's number | 400, 401, 403, 404 |
| `POST /v1/admin/waitlist/entries` | Lets addresses in by hand | 400, 401, 403, 404 |
| `DELETE /v1/admin/waitlist/entries/{id}` | Removes an entry. A removed address can no longer sign up | 401, 403, 404 |
| `GET /v1/admin/signup-gate` | Reads the sign-up gate | 401, 403, 404 |
| `PUT /v1/admin/signup-gate` | Turns the gate on or off and sets its opening time and numbers. Fields left out keep their value. Takes effect within 15 seconds | 400, 401, 403, 404 |

**The daily batch.** With `daily_admit` above 0, once a day from `batch_hour_utc` (UTC, default 15)
the worker chooses up to `daily_admit` people from the waitlist, never more than the day's
"You're in" emails (`daily_emails_max`) have room for. It skips the day and sends the instance
owners a notification when the day before was busy: computers used 7/9 of the memory set aside
for them (`COMPUTER_HOST_MEMORY_GB`) at their peak, or model spend on Casama's key passed 60% of
`OPENROUTER_DAILY_CAP_USD` (default 50). Owners can still let people in by hand.
| `GET /v1/admin/invite-campaigns` | Lists campaign invite codes | 401, 403, 404 |
| `POST /v1/admin/invite-campaigns` | Makes a campaign code with a total | 400 `bad_code`, 401, 403, 404, 409 when the code exists |
| `PATCH /v1/admin/invite-campaigns/{code}` | Changes a code's total, dates or name, or turns it off | 400, 401, 403, 404 |

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
| 402 | `out_of_credits` | The workspace is out of credits, so a computer won't start (only when billing is on) |
| 403 | `forbidden` | You're signed in but not allowed to do this |
| 403 | `mfa_required` | The workspace requires two-step sign-in for this |
| 403 | `email_unverified` | Confirm your email address before starting a computer |
| 403 | `workspace_suspended` | The instance owner suspended this workspace |
| 403 | `computer_forbidden` | A personal computer's files are only for its owner and the bots they allowed |
| 404 | `not_found` | No such route |
| 404 | `bot_not_found`, `org_not_found`, `conversation_not_found`, ... | The thing doesn't exist or you can't see it |
| 409 | `run_finished` | You tried to cancel a run that already ended |
| 409 | `device_offline` | A personal computer's desktop app isn't connected |
| 409 | `chat_private` | A chat that holds personal device data can't be shared publicly |
| 422 | `idempotency_key_reused` | The `Idempotency-Key` was used for a different request |
| 429 | `rate_limited` | Too many requests; see `Retry-After` |
| 429 | `too_many_links` | The workspace made its daily number of public Library links |
| 500 | `internal_error` | A server bug. Retry later; the server logged it. |
| 503 | `computer_unavailable` | The bot's computer couldn't be reached (stopping, waking or restarting). Retry shortly. |
| 503 | `capacity_full` | The server has no room to start another computer right now. Retry in a few minutes. |

Every response carries an `x-request-id` header. Send your own `x-request-id` to tie a request to
your logs, and include it when you report a problem.

## Rate limits

Requests to `/v1/*` and `/hooks/*` are limited per minute, per signed-in user (or per client IP
address without a token). The default is 120 requests a minute; self-hosters change it with
`RATE_LIMIT_PER_MINUTE`.

Over the limit, the API answers 429 with the code `rate_limited` and a `Retry-After` header in
seconds. Wait that long, then retry.

The window is a fixed minute kept in the API process's memory, so a server that runs several API
processes counts each one separately. The [Casama Link](/guide/casama-link) paths under `/link/`,
which self-hosted servers call, get ten times the limit.

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
- Keys are up to 255 characters; a longer one answers 400 `validation_failed`. Requests without a token, and `GET` requests, ignore the header.

## Lists and pagination

Most list endpoints return everything you can see in one response, wrapped in an object:

```json
{ "items": [ { "id": "..." } ] }
```

A few lists are paged, each in the way that suits it:

| List | How to page |
| --- | --- |
| Run events (`GET /v1/runs/{id}/events`) | By sequence number: `after_seq` and `limit` (see [below](#read-events-after-the-fact)) |
| The Library (`GET /v1/creations`) | By cursor: pass the response's `next_cursor` back as `cursor` until it's `null` |
| A chat's messages (`GET /v1/conversations/{id}/thread`) | Without `limit`, the whole branch. With `limit` (up to 500), the newest messages; add `before=<message id>` for the page before it |

The [API reference](/api/) lists each endpoint's parameters.

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
`device.access_requested`, `device.data_used`, `local_mcp.sign_in_needed` (a server on the
person's computer needs them to sign in), `mcp.question` and `mcp.question_resolved` (a connected
MCP server asked the person something; answer with `POST /v1/mcp-questions/{id}/answer`), and
`ui.shown` (an interactive card in the chat).
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
Admin bot approvals (tools named `admin.*`) take a normal signed-in session of an instance owner
and can't be always allowed ([the admin bot](/guide/workspaces#the-admin-bot)); `GET` and `PUT
/v1/admin/admin-bot` read and set which bot that is.
`GET /v1/approvals?org_id=...&status=pending` lists what's waiting. See [Autonomy and approvals](/guide/autonomy) for how risk decides what asks.

### Cancel a run

```sh
curl -s -X POST "$API/v1/runs/$RUN/cancel" -H "authorization: Bearer $TOKEN"
```

The API answers 202 with the run, and the worker stops it (and any helper runs it started) within
about two seconds. The run then ends with a `run.cancelled` event. Cancelling a run that already
ended answers 409 `run_finished`.

## The Library

Everything bots make that you can open again (pages, pictures, videos, sounds, documents and kept
files) is a **creation**, listed in the Library. List a workspace's creations, newest first:

```sh
curl -s "$API/v1/creations?org_id=$ORG&kind=document&limit=20" -H "authorization: Bearer $TOKEN" |
  jq '{next_cursor, items: [.items[] | {id, kind, title, bot_name}]}'
```

Filter with `kind` (`page`, `image`, `video`, `audio`, `document` or `file`), `bot_id`,
`conversation_id`, `project_id`, `pinned=true` or a search term in `q`. `sort=opened` lists what
you opened most recently. `limit` is 1 to 100 (default 40).

Read one with `GET /v1/creations/{id}`. Its bytes come from `GET /v1/creations/{id}/content`
(pictures, videos and sound; it honours one byte range), its card picture from `/cover` when
`has_cover` is true, and a document's PDF from `/preview` when `has_preview` is true.

Change who can see it with `PATCH`:

```sh
curl -s -X PATCH "$API/v1/creations/$CREATION" -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{"visibility": "public"}' | jq -r .public_url
```

`visibility` is `private`, `workspace` (every member) or `public` (anyone with the link). The
public link is in `public_url` only in this one response; making it public again gives a new link
and the old one stops working. The same `PATCH` renames it (`title`), pins it (`pinned`) or files
it under a project (`project_id`). `DELETE` hides it at once, and `POST /v1/creations/{id}/restore`
brings it back within 30 days.

A public link opens a read-only viewer on the server's pages address, with no scripts. Pictures,
videos, sound and PDFs show in the page; any other file downloads instead.

## Export or share a chat

Download a chat as Markdown (the default) or JSON. It holds only what you can see:

```sh
curl -s "$API/v1/conversations/$CONVERSATION/export?format=json" \
  -H "authorization: Bearer $TOKEN" -o chat.json
```

Make a public, read-only link to it:

```sh
curl -s -X POST "$API/v1/conversations/$CONVERSATION/share" -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" -d '{"public": true}'
```

```json
{ "url": "https://pages.casama.example.com/t/..." }
```

Only the person who started the chat, or someone who manages its bot, can share it. Sharing again
gives a new link; `{"public": false}` turns the link off and returns `{"url": null}`. A chat that
holds personal data from a device answers 409 `chat_private`.

## Reactions

React to a message with one emoji, the way the app does. One reaction per person per message:
another emoji replaces yours.

```sh
curl -s -X PUT "$API/v1/conversations/$CONVERSATION/messages/$MESSAGE/reaction" \
  -H "authorization: Bearer $TOKEN" -H "content-type: application/json" -d '{"emoji": "👍"}'
```

```json
{ "message_id": "…", "reactions": [{ "emoji": "👍", "count": 2, "mine": true, "users": ["…"], "bots": [] }] }
```

`DELETE` on the same path takes yours back. `GET …/messages/$MESSAGE/reactions` lists every
reaction with the person's or bot's name and picture. Each message in
`GET /v1/conversations/{id}/thread` carries its `reactions`, grouped by emoji, most first; `users`
holds the first 20 people.

A reaction never starts a run; the bot sees it the next time it works in the chat. Errors: 400
`invalid_emoji` when the text isn't exactly one emoji, 400 `not_reactable` for tool steps and other
messages people don't read, 404 `message_not_found`, and 429 `rate_limited` past 60 changes a
minute. Apps watching a chat get a `message_reaction` broadcast on its Realtime topic.

## Find your way around

The [API reference](/api/) groups endpoints by tag. The main groups:

| Area | Paths |
| --- | --- |
| Workspaces, members, invites, settings | `/v1/orgs`, `/v1/orgs/{id}/...`, `/v1/join`, `/v1/me` |
| Bots and their memory | `/v1/bots`, `/v1/bots/{id}/...` |
| Chats and runs | `/v1/conversations`, `/v1/runs`, `/v1/approvals`, `/v1/search` |
| Routines, tickets, watchers | `/v1/routines`, `/v1/tasks`, `/v1/watchers` |
| Computers | `/v1/computers`, `/v1/local-devices` |
| The Library and pages | `/v1/creations`, `/v1/pages`, `/v1/projects` |
| Connections and model keys | `/v1/integrations`, `/v1/apps`, `/v1/credentials` |
| Skills and plugins | `/v1/skills`, `/v1/plugins` |
| Usage and billing | `/v1/usage`, `/v1/orgs/{id}/billing` |
| Casama Link | `/v1/orgs/{id}/link/...`, `/v1/admin/remote-access` |
| Instance owner | `/v1/admin/...` |

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
| Library items per page | 100 (default 40) |
| Chat messages per page | 500 |
| New public Library links | 20 per workspace a day |
| Bots in a group chat | 10 |

## Related

- [API reference](/api/): every endpoint and schema
- [Dart SDK](/develop/sdk): a typed client with sign-in and `watchRun`
- [CLI](/develop/cli): the same API from your terminal
- [Webhooks](/develop/webhooks): start routines from other services
- [Agent-to-agent (A2A)](/develop/a2a): call bots with workspace API keys
- [Hosted MCP](/guide/mcp): use bots from AI apps
