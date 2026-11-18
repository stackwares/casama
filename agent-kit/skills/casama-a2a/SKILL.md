---
name: casama-a2a
description: "Agent-to-agent (A2A 1.0) with Casama: publish a bot so outside agents can send it tasks (agent card, SendMessage, GetTask, CancelTask, ListTasks, ksk_ workspace keys), or connect an outside A2A agent as a tool for a bot. Use for A2A, agent cards, multi-agent or cross-server bot calls."
---

# Casama and A2A

Casama implements [A2A](https://a2a-protocol.org) **1.0** over the **JSON-RPC** binding, both
ways. Methods: `SendMessage`, `GetTask`, `CancelTask`, `ListTasks`. **Text parts only.** No
streaming and no push notifications yet (the card says `"streaming": false,
"pushNotifications": false`).

Full page: https://docs.casama.ai/develop/a2a.md

## Publish a bot (outside agents call Casama)

1. **Workspace switch** (owner/admin): **Agent-to-agent (A2A)** in workspace settings, or
   `PATCH /v1/orgs/{id}/settings` with `{"a2a_enabled": true}`. Turning it off unpublishes every
   bot.
2. **Publish the bot** (someone who manages it):

   ```sh
   curl -s -X PUT "$API/v1/bots/$BOT/a2a" -H "authorization: Bearer $TOKEN" \
     -H "content-type: application/json" -d '{"published": true}'
   ```

   → `{workspace_enabled, published, agent_card_url}`. Publishing while the workspace switch is off
   → 409 `a2a_off`. `GET /v1/bots/{id}/a2a` reads the status.
3. **Create a workspace API key** (owner/admin): **Connect AI apps** in workspace settings, or

   ```sh
   curl -s -X POST "$API/v1/orgs/$ORG/mcp-keys" -H "authorization: Bearer $TOKEN" \
     -H "content-type: application/json" -d '{"name": "Partner agent"}'
   ```

   `key` (`ksk_...`) is shown once. Revoke: `DELETE /v1/orgs/{id}/mcp-keys/{key_id}`.

A key **acts as the person who created it**, in that workspace only: the bot's usual approvals,
budgets and action rules apply, calls are audited, and only bots that person can use are
reachable. It stops working when that person leaves. Give each caller its own key.

### Agent card (public, no auth)

`GET <server>/a2a/{bot id}/.well-known/agent-card.json`. It has `name`, `description` (the first
500 chars of the bot's instructions, so write those lines for outside readers),
`supportedInterfaces: [{url: "<server>/a2a/{bot id}", protocolBinding: "JSONRPC",
protocolVersion: "1.0"}]`, one skill `chat`, and a Bearer `workspaceKey` security scheme. An
unpublished bot answers 404.

### Calls

JSON-RPC 2.0 `POST <server>/a2a/{bot id}`, `Authorization: Bearer ksk_...`. `A2A-Version` is
optional; if sent it must be `1` or `1.x`.

```sh
curl -s -X POST "$API/a2a/$BOT" -H "authorization: Bearer $CASAMA_KEY" \
  -H "content-type: application/json" -H "a2a-version: 1.0" -d '{
  "jsonrpc": "2.0", "id": 1, "method": "SendMessage",
  "params": { "message": { "role": "ROLE_USER", "messageId": "<uuid>",
    "parts": [{ "text": "Which invoices from October are still unpaid?" }] } } }'
```

- `role` must be `ROLE_USER` with at least one `text` part; text parts are joined, other parts
  ignored.
- **Blocks up to 55 s** for the bot to finish or need an approval, then returns the task as it is;
  poll `GetTask`. `params.configuration.returnImmediately: true` returns at once.
- Follow-ups: send the task's `contextId` (must be a UUID) in the next message to continue the
  conversation, or a `taskId` to continue that task's conversation.
- The task becomes a run in a conversation created by the key's person, visible in the app.
- Result: `result.task` with `id`, `contextId`, `status.state`, `status.message`, and on success
  an artifact named `answer`.

| Method | Params | Notes |
| --- | --- | --- |
| `GetTask` | `{id}` | Answer arrives as artifact `answer` and the final status message |
| `CancelTask` | `{id}` | Returns `TASK_STATE_CANCELED`; already finished → `-32002` |
| `ListTasks` | `{contextId?, pageSize?}` | Your key's tasks to this bot, newest first; `pageSize` 1-100 (default 50); `nextPageToken` is always `""` |

| Run status | Task state |
| --- | --- |
| queued | `TASK_STATE_SUBMITTED` |
| running, waiting for approval, waiting for takeover | `TASK_STATE_WORKING` |
| completed / failed / cancelled | `TASK_STATE_COMPLETED` / `TASK_STATE_FAILED` / `TASK_STATE_CANCELED` |

While waiting for approval the state stays `WORKING` with the message "Waiting for the bot's owner
to approve a step." **Approvals happen in Casama, not over A2A.**

### Errors

| Code | HTTP | Meaning |
| --- | --- | --- |
| `-32600` | 404 / 401 / 403 / 200 | No published bot / bad, revoked or other-workspace key / key's person can't use the bot / invalid JSON-RPC |
| `-32700` | 200 | Body isn't JSON |
| `-32601` | 200 | Unknown method |
| `-32602` | 200 | Bad params (no `ROLE_USER` or no text) |
| `-32001` | 200 | Task not found (or not yours) |
| `-32002` | 200 | Task already finished, can't cancel |
| `-32009` | 200 | Unsupported `A2A-Version` |
| `-32603` | 200 | Server failure |

## Call an outside agent from a bot

Any agent with an A2A 1.0 card and a JSON-RPC interface, including a bot on another Casama server.

- **App:** add a connection of kind **AI agent (A2A)** with the agent's address or card URL and an
  optional access token, then attach it to bots.
- **API** (owners/admins):

  ```sh
  curl -s -X POST "$API/v1/integrations" -H "authorization: Bearer $TOKEN" \
    -H "content-type: application/json" -d '{"org_id":"'"$ORG"'","kind":"a2a",
    "name":"travel_agent","config":{"url":"https://agents.example.com/travel"},
    "secret":"the-agent-access-token"}'
  curl -s -X POST "$API/v1/bots/$BOT/integrations" -H "authorization: Bearer $TOKEN" \
    -H "content-type: application/json" -d '{"integration_id":"<id>"}'
  ```

  `name`: lowercase letters, digits, `_`, starting with a letter, max 40. `config.url`: the agent's
  address (Casama appends `/.well-known/agent-card.json`) or the full card URL ending in `.json`.
  `secret` (optional) is sent as `Authorization: Bearer <secret>`, kept in the vault. Casama reads
  the card immediately to check it.

The bot gets one tool, `a2a.<name>.send`, with inputs `task` (required), `context_id`, `task_id`.
It polls every 1.5 s until done, input-required, or 10 minutes, and returns the answer plus
`context_id`. **Medium risk** by default (may need approval, e.g. after reading untrusted content).
Tool description from the card is capped at 1,024 chars.

**Two Casama servers:** on the other server publish the bot and create a key; on yours add an A2A
connection to `https://other.example.com/a2a/<bot id>` with that key. For two people who trust each
other, **linked bots** (invite/accept in the app) need no publishing or keys and use a per-link
token on the same `/a2a/{bot id}` address.

## Checklist

- [ ] Workspace `a2a_enabled`, bot `published`, card URL returns 200
- [ ] One `ksk_` key per caller, created by an account whose access fits the caller
- [ ] Callers send `ROLE_USER` text, keep `contextId` for follow-ups, poll `GetTask` after 55 s
- [ ] Someone watches approvals in Casama (A2A can't approve)
- [ ] First 500 chars of the bot's instructions read well as a public description
