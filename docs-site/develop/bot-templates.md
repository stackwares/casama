# Bot template format

A bot template is one JSON file that describes a bot people can import: its instructions, skills,
routines and the services it works with. It never carries keys, secrets or chats, so it's safe to
share in public. Files use the extension `.casama-bot.json`, and the format is called
`casama.bot`, version 1.

## Where templates come from

- **Export from the app.** In a bot's settings, **Share as template** saves the file or copies a
  share link. You choose whether to include the bot's memories.
- **Export from the API.** `GET /v1/bots/{id}/export` returns the template for any bot you can see.
  Add `?memories=true` to include memories; that only takes effect for people who manage the bot.
- **Write one by hand.** It's plain JSON; the full example below is a good start.

```sh
curl -s "https://casama.example.com/v1/bots/$BOT/export" \
  -H "authorization: Bearer $TOKEN" > invoicer.casama-bot.json
```

## A full example

```json
{
  "format": "casama.bot",
  "version": 1,
  "name": "Invoicer",
  "description": "Chases unpaid invoices politely.",
  "persona_md": "You chase unpaid invoices for a small design studio. Be polite and brief...",
  "autonomy": "ask_risky",
  "avatar": "mascot:cool",
  "skills": [
    {
      "name": "dunning",
      "description": "Follow-up cadence for overdue invoices. Use when an invoice is past due.",
      "body_md": "1. Day 7: a friendly reminder.\n2. Day 14: a firmer note with the invoice attached.\n3. Day 30: tell me before sending anything else.",
      "files": [
        {
          "path": "templates/reminder.md",
          "content_base64": "SGkge25hbWV9LCBqdXN0IGEgcmVtaW5kZXIuLi4=",
          "executable": false
        },
        {
          "path": "scripts/overdue.sh",
          "content_base64": "IyEvYmluL2Jhc2gKZWNobyAiY2hlY2tpbmcuLi4iCg==",
          "executable": true
        }
      ]
    }
  ],
  "routines": [
    {
      "name": "Weekly chase",
      "instructions_md": "Check for overdue invoices and follow the dunning skill.",
      "schedule_cron": "0 9 * * 1"
    }
  ],
  "connections": [
    { "kind": "composio", "name": "gmail" },
    { "kind": "mcp", "name": "accounting" }
  ],
  "memories": [
    { "kind": "preference", "content": "Invoices go out from billing@example.com." }
  ]
}
```

## Fields

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `format` | string | yes | Always `"casama.bot"` |
| `version` | integer | yes | Always `1` |
| `name` | string | yes | 1 to 80 characters |
| `description` | string | no | Up to 300 characters. A one-line summary for people browsing templates. |
| `persona_md` | string | yes | The bot's instructions, in Markdown. Up to 20,000 characters (can be empty). |
| `autonomy` | string | yes | `ask_always`, `ask_risky` or `autonomous` |
| `avatar` | string or null | no | A built-in mascot, `mascot:<name>`, or `null` |
| `skills` | array | no | Up to 30. See [Skills](#skills). |
| `routines` | array | no | Up to 20. See [Routines](#routines). |
| `connections` | array | no | Up to 30. See [Connections](#connections). |
| `memories` | array | no | Up to 200. See [Memories](#memories). |

The optional lists can be left out; a missing list means none.

### `autonomy`

How much the bot may do without asking. See [Autonomy and approvals](/guide/autonomy).

| Value | Meaning |
| --- | --- |
| `ask_always` | Asks before any action with side effects |
| `ask_risky` | The default. Asks before high-risk actions, paid data lookups and payments, and before a medium-risk action that sends data out after reading outside content |
| `autonomous` | Asks only before high-risk actions on personal computers |

### `avatar`

One of the built-in mascots: `mascot:cool`, `mascot:focused`, `mascot:giggly`, `mascot:lovey`,
`mascot:shy`, `mascot:sleepy`, `mascot:starry`, `mascot:thinker`, `mascot:winky` or `mascot:wow`.
Anything that doesn't start with `mascot:` is dropped on import, and uploaded pictures are never
exported.

### Skills

The bot's own skills, in the open [Agent Skills](https://agentskills.io) shape. See
[Skills](/guide/skills).

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `name` | string | yes | Lowercase letters, digits, `-` and `_`, starting with a letter or digit; up to 63 characters |
| `description` | string | yes | 1 to 300 characters. The bot reads it when choosing a skill, so say when to use it. |
| `body_md` | string | yes | The skill's instructions, up to 50,000 characters |
| `files` | array | no | Files the skill uses, up to 60 |

Each file:

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `path` | string | yes | A relative path of letters, digits, `.`, `_`, `-` and `/`, with no `..` |
| `content_base64` | string | yes | The file's bytes, base64-encoded. Up to 1 MB per file once decoded. |
| `executable` | boolean | no | Keep the executable bit (default `false`) |

A skill's files can total up to 5 MB. Scripts in a skill only ever run on the bot's own sandboxed
computer, never on the Casama server.

### Routines

Repeating schedules. See [Routines](/guide/routines).

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `name` | string | yes | 1 to 120 characters |
| `instructions_md` | string | yes | What to do each time, 1 to 20,000 characters |
| `schedule_cron` | string | yes | A standard 5-field cron expression, such as `0 9 * * 1` (Mondays at 9:00) |

There's no time zone in the file: routines run in the importing person's time zone.

### Connections

Services the bot works with, so the person importing knows what to connect. Names only: no
credentials, tokens or addresses ever travel.

| Field | Type | Rules |
| --- | --- | --- |
| `kind` | string | The connection type, such as `mcp`, `openapi`, `composio` or `a2a`. Up to 40 characters. |
| `name` | string | The connection's name in the exporting workspace. Up to 120 characters. |

### Memories

Only present when the person exporting chose to include them.

| Field | Type | Rules |
| --- | --- | --- |
| `kind` | string | `fact`, `episode`, `summary` or `preference` |
| `content` | string | 1 to 8,000 characters |

An export includes up to 200 memories, pinned and most important first.

## Never in a template

Casama never writes these into a template, and import doesn't read them:

- model keys, secrets, OAuth tokens or any other credential
- the model choice (the person importing picks a key and model)
- chats and conversation history
- files from the bot's computer
- uploaded avatar pictures
- skills shared by the whole workspace, turned-off skills, and routines that aren't on a
  repeating schedule (webhook, one-time and other triggers)

## Import a template

In the app, open **Bots → Import a bot** and pick the file, or open a share link
(`https://<your app>/import/<token>`). Casama previews the instructions, skills, routines,
connections and memory count, and you choose a model key and model, and whether to bring the
routines and memories.

From the API, `POST /v1/bots/import`:

```sh
jq -n --slurpfile t invoicer.casama-bot.json \
  --arg org "$ORG" --arg key "$CREDENTIAL" --arg model "$MODEL" \
  '{org_id: $org, template: $t[0], credential_id: $key, model: $model,
    include_routines: true, include_memories: false}' |
curl -s -X POST "https://casama.example.com/v1/bots/import" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d @-
```

| Field | Required | Meaning |
| --- | --- | --- |
| `org_id` | yes | The workspace to create the bot in |
| `template` | yes | The template file's contents |
| `credential_id` | yes | A model key from that workspace |
| `model` | yes | The model id the bot uses on that key |
| `include_routines` | no | Create the routines (default `true`) |
| `include_memories` | no | Add the memories (default `true`) |

```json
{
  "bot_id": "2a7d4c1e-9b8f-4e6a-8c5d-3f2e1a0b9c8d",
  "skills": 1,
  "routines": 1,
  "memories": 0,
  "connections_to_add": [
    { "kind": "composio", "name": "gmail" },
    { "kind": "mcp", "name": "accounting" }
  ]
}
```

What import does:

- **Checks first.** The file must match the schema above (`validation_failed` lists what's wrong),
  every skill's files are checked against the limits, and every routine's cron schedule is
  validated. A problem stops the import with nothing created (`skill_too_large`, `skill_bad_path`
  or `invalid_cron`).
- **Creates a new bot** owned by you, with the template's name, instructions, autonomy and mascot,
  and the key and model you picked. It counts toward your plan's bot limit when billing is on.
- **Adds the skills** with their files and executable bits.
- **Adds the routines** (if `include_routines`) in your profile's time zone, or UTC if you haven't
  set one.
- **Adds the memories** (if `include_memories`).
- **Doesn't connect anything.** `connections_to_add` lists the services to connect yourself; see
  [Connections](/guide/connections).

Importing always creates a new bot; it never changes an existing one.

## Share links

`POST /v1/bots/{id}/share` (for people who manage the bot) saves a snapshot of the template and
returns a link:

```sh
curl -s -X POST "https://casama.example.com/v1/bots/$BOT/share" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{"include_memories": false, "expires_in_days": 30}'
```

```json
{
  "token": "q3V9...",
  "url": "https://app.casama.example.com/import/q3V9...",
  "expires_at": "2026-12-11T15:00:00.000Z"
}
```

`expires_in_days` is 1 to 365 (default 30), or `null` for a link that doesn't expire. Anyone signed
in to the same Casama server, in any workspace, can open the link to preview and import the
snapshot; `GET /v1/bot-shares/{token}` returns it. The snapshot doesn't change when you edit the
bot later: share again for a fresh one.

## Limits

| What | Limit |
| --- | --- |
| Name | 80 characters |
| Description | 300 characters |
| Instructions (`persona_md`) | 20,000 characters |
| Skills | 30 per template |
| Skill body | 50,000 characters |
| Files per skill | 60 |
| File size | 1 MB each, 5 MB per skill |
| Routines | 20 per template |
| Connections | 30 per template |
| Memories | 200 per template, 8,000 characters each |
| Share link expiry | 1 to 365 days, or never |

## Related

- [Bots](/guide/bots)
- [Skills](/guide/skills)
- [Routines](/guide/routines)
- [Sharing](/guide/sharing)
- [Routines and skills as files](/develop/workspace-files): a workspace's routines and skills as
  Markdown files
