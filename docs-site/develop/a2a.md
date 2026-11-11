# Agent-to-agent (A2A)

[A2A](https://a2a-protocol.org) is an open protocol for AI agents to hand each other tasks. Kasama
speaks it both ways:

- **Publish a bot** so outside agents (another company's assistant, your own agent framework, a
  script) can give it tasks.
- **Call outside agents** from a bot, as a tool it uses like any other.

Kasama implements A2A version 1.0 over its JSON-RPC binding: agent cards at
`/.well-known/agent-card.json`, the methods `SendMessage`, `GetTask`, `CancelTask` and `ListTasks`,
and text messages. Streaming and push notifications aren't offered yet; the agent card says so.

## Publish a bot

Publishing is off until you turn it on, in two steps:

1. **Turn on A2A for the workspace.** An owner or admin turns on **Agent-to-agent (A2A)** in
   workspace settings, or sets `a2a_enabled` with `PATCH /v1/orgs/{id}/settings`. Turning it off
   later unpublishes every bot.
2. **Publish the bot.** Someone who manages the bot turns on **Publish as an A2A agent** in its
   settings, or calls the API:

   ```sh
   curl -s -X PUT "https://kasama.example.com/v1/bots/$BOT/a2a" \
     -H "authorization: Bearer $TOKEN" \
     -H "content-type: application/json" \
     -d '{"published": true}'
   ```

   ```json
   {
     "workspace_enabled": true,
     "published": true,
     "agent_card_url": "https://kasama.example.com/a2a/5d0c1e6a-8b7f-4e8a-a1d2-3c4b5a6f7e80/.well-known/agent-card.json"
   }
   ```

   Publishing while the workspace switch is off answers 409 `a2a_off`. `GET /v1/bots/{id}/a2a` reads
   the same status. Publishing and unpublishing are recorded in the audit log.

### Create a workspace API key

Callers authenticate with a **workspace API key**, the same `ksk_...` keys the
[hosted MCP endpoint](/guide/mcp) uses. An owner or admin creates one in workspace settings under
**Connect AI apps**, or with the API:

```sh
curl -s -X POST "https://kasama.example.com/v1/orgs/$ORG/mcp-keys" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{"name": "Partner agent"}'
```

The response's `key` is shown only once. Revoke a key with
`DELETE /v1/orgs/{id}/mcp-keys/{key_id}`.

A key **acts as the person who created it**, in that workspace only. So a task sent with it runs
like a message from that person: with the bot's usual approvals, budgets and action rules, recorded
in the audit log, and only on bots that person can use. A key stops working when its person
leaves the workspace.

::: tip
Create keys from an account whose access fits what the caller should reach, and give each caller
its own key so you can revoke one without breaking the others.
:::

### The agent card

A published bot's card is public (it holds nothing secret), so any A2A client can discover it:

```sh
curl -s "https://kasama.example.com/a2a/$BOT/.well-known/agent-card.json"
```

```json
{
  "name": "Invoicer",
  "description": "You chase unpaid invoices for a small design studio. Be polite and brief...",
  "version": "1.0.0",
  "supportedInterfaces": [
    {
      "url": "https://kasama.example.com/a2a/5d0c1e6a-8b7f-4e8a-a1d2-3c4b5a6f7e80",
      "protocolBinding": "JSONRPC",
      "protocolVersion": "1.0"
    }
  ],
  "capabilities": { "streaming": false, "pushNotifications": false },
  "defaultInputModes": ["text/plain"],
  "defaultOutputModes": ["text/plain"],
  "skills": [
    {
      "id": "chat",
      "name": "Ask the bot",
      "description": "Give Invoicer a task in plain language; it works with its own tools and returns the result.",
      "tags": ["assistant"]
    }
  ],
  "securitySchemes": {
    "workspaceKey": {
      "httpAuthSecurityScheme": { "scheme": "Bearer", "bearerFormat": "Kasama workspace API key" }
    }
  },
  "securityRequirements": [{ "workspaceKey": [] }]
}
```

The description is the start of the bot's instructions (up to 500 characters), so write the first
lines of its instructions with outside readers in mind. A bot that isn't published answers 404.

## Send a bot a task

Every call is a JSON-RPC 2.0 `POST` to `/a2a/{bot id}` with the key as a bearer token. The
`A2A-Version` header is optional; if you send it, it must be `1` or `1.x`.

### SendMessage

```sh
curl -s -X POST "https://kasama.example.com/a2a/$BOT" \
  -H "authorization: Bearer $KASAMA_KEY" \
  -H "content-type: application/json" \
  -H "a2a-version: 1.0" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "SendMessage",
    "params": {
      "message": {
        "role": "ROLE_USER",
        "messageId": "3e9b6c1a-0f2d-4a8b-9c7e-5d4f3a2b1c0d",
        "parts": [{ "text": "Which invoices from October are still unpaid?" }]
      }
    }
  }'
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "task": {
      "id": "b7a1c2d3-e4f5-4a6b-8c7d-9e0f1a2b3c4d",
      "contextId": "f0e1d2c3-b4a5-4968-8776-655443322110",
      "status": {
        "state": "TASK_STATE_COMPLETED",
        "timestamp": "2026-11-11T21:04:05.000Z",
        "message": {
          "role": "ROLE_AGENT",
          "parts": [{ "text": "Three are unpaid: #1031, #1036 and #1040..." }],
          "messageId": "...",
          "contextId": "f0e1d2c3-b4a5-4968-8776-655443322110",
          "taskId": "b7a1c2d3-e4f5-4a6b-8c7d-9e0f1a2b3c4d"
        }
      },
      "artifacts": [
        {
          "artifactId": "b7a1c2d3-e4f5-4a6b-8c7d-9e0f1a2b3c4d-answer",
          "name": "answer",
          "parts": [{ "text": "Three are unpaid: #1031, #1036 and #1040..." }]
        }
      ]
    }
  }
}
```

- The message needs `role: "ROLE_USER"` and at least one part with `text`. Text parts are joined;
  other kinds of parts are ignored.
- The task becomes a run in a conversation with the bot, created by the key's person, so it shows
  up in the app like any other chat.
- **Blocking by default.** The call waits up to 55 seconds for the bot to finish or to need an
  approval. If it's still working, you get the task in its current state; poll `GetTask`. Pass
  `"configuration": {"returnImmediately": true}` in `params` to get the task back at once.
- **Follow-ups.** Send the `contextId` from a task (it must be a UUID) in your next message to
  continue the same conversation, so the bot remembers what you discussed. Or send a `taskId` to
  continue that task's conversation.

### GetTask

```sh
curl -s -X POST "https://kasama.example.com/a2a/$BOT" \
  -H "authorization: Bearer $KASAMA_KEY" -H "content-type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "GetTask",
       "params": {"id": "b7a1c2d3-e4f5-4a6b-8c7d-9e0f1a2b3c4d"}}'
```

The result is the task. The answer arrives as an artifact named `answer` and as the final status
message, once the state is `TASK_STATE_COMPLETED`.

| Kasama run status | Task state |
| --- | --- |
| Queued | `TASK_STATE_SUBMITTED` |
| Running, waiting for approval, waiting for a person to take over | `TASK_STATE_WORKING` |
| Completed | `TASK_STATE_COMPLETED` |
| Failed | `TASK_STATE_FAILED` |
| Cancelled | `TASK_STATE_CANCELED` |

While the bot waits for its owner to approve a step, the state stays `TASK_STATE_WORKING` with the
status message "Waiting for the bot's owner to approve a step." Approvals happen in Kasama, not over
A2A.

### CancelTask

```sh
curl -s -X POST "https://kasama.example.com/a2a/$BOT" \
  -H "authorization: Bearer $KASAMA_KEY" -H "content-type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 3, "method": "CancelTask",
       "params": {"id": "b7a1c2d3-e4f5-4a6b-8c7d-9e0f1a2b3c4d"}}'
```

Cancels the run and returns the task as `TASK_STATE_CANCELED`. A task that already finished
answers the error `-32002`.

### ListTasks

```sh
curl -s -X POST "https://kasama.example.com/a2a/$BOT" \
  -H "authorization: Bearer $KASAMA_KEY" -H "content-type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 4, "method": "ListTasks",
       "params": {"contextId": "f0e1d2c3-b4a5-4968-8776-655443322110", "pageSize": 20}}'
```

Returns `{"tasks": [...], "nextPageToken": ""}`: the tasks your key's person sent to this bot,
newest first, optionally only those in one `contextId`. `pageSize` is 1 to 100 (default 50).
There are no further pages.

### Errors

Errors come back as JSON-RPC errors:

| Code | HTTP status | Meaning |
| --- | --- | --- |
| `-32600` | 404 | No published bot with that id |
| `-32600` | 401 | Missing, revoked or wrong key, or a key from another workspace |
| `-32600` | 403 | The key's person can't use this bot |
| `-32600` | 200 | Not a valid JSON-RPC request |
| `-32700` | 200 | The body isn't JSON |
| `-32601` | 200 | Unknown method |
| `-32602` | 200 | Bad parameters, such as a message without `ROLE_USER` or text |
| `-32001` | 200 | Task not found (or not yours) |
| `-32002` | 200 | The task already finished and can't be cancelled |
| `-32009` | 200 | Unsupported `A2A-Version` |
| `-32603` | 200 | Something failed on the server |

## Call outside agents from a bot

Any agent that publishes an A2A 1.0 agent card with a JSON-RPC interface can become a tool for
your bots, including bots on another Kasama server.

**In the app:** add a connection of the kind **AI agent (A2A)**, enter the agent's address or the
URL of its agent card, and its access token if it needs one. Then attach the connection to the bots
that should use it.

**With the API:** create an integration with `kind: "a2a"`, then attach it to a bot:

```sh
curl -s -X POST "https://kasama.example.com/v1/integrations" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{
    "org_id": "'"$ORG"'",
    "kind": "a2a",
    "name": "travel_agent",
    "config": { "url": "https://agents.example.com/travel" },
    "secret": "the-agent-access-token"
  }'

curl -s -X POST "https://kasama.example.com/v1/bots/$BOT/integrations" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{"integration_id": "<id from the first response>"}'
```

| Field | Meaning |
| --- | --- |
| `name` | Lowercase letters, digits and `_`, starting with a letter, up to 40 characters |
| `config.url` | The agent's address (Kasama adds `/.well-known/agent-card.json`) or the full URL of its agent card (ending in `.json`) |
| `secret` | Optional. Sent as `Authorization: Bearer <secret>`. Stored in the vault, never returned. |

Only owners and admins add integrations. Kasama reads the agent card right away to check the
connection.

### What the bot gets

One tool, `a2a.<name>.send`, described from the agent card's description and skills, with these
inputs:

| Input | Meaning |
| --- | --- |
| `task` | What to do, with everything the agent needs (required) |
| `context_id` | Continue an earlier conversation with this agent |
| `task_id` | Answer a task that asked for more input |

The tool sends the task, then checks on it every 1.5 seconds until it finishes, needs input, or 10
minutes pass. It returns the agent's answer (its artifacts, or its last status message) and the
`context_id` for follow-ups, and says when the agent needs more input, failed or declined.

The tool is **medium risk**, so with the default autonomy the bot may ask before using it, for
example after it has read untrusted content. You can change its risk like any connection's tool.
See [Autonomy and approvals](/guide/autonomy).

### Connect two Kasama servers

To let a bot on one server use a bot on another:

1. On the other server, publish the bot and create a workspace API key.
2. On yours, add an A2A connection with the published bot's address
   (`https://other.example.com/a2a/<bot id>`) and the key as its access token.

## Limits

| What | Limit |
| --- | --- |
| `SendMessage` wait | 55 seconds, then poll `GetTask` |
| `ListTasks` page size | 100 (default 50) |
| Card description | 500 characters |
| Outside agent tool wait | 10 minutes |
| Tool description from a card | 1,024 characters |
| Message parts | Text only, in and out |

## Related

- [Hosted MCP](/guide/mcp): the other way to use bots from outside, with the same keys
- [Connections](/guide/connections): add and attach connections
- [Autonomy and approvals](/guide/autonomy)
- [Bots working together](/guide/bots-together)
- [HTTP API](/develop/api)
