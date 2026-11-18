---
name: casama-bot-template
description: "Write or convert Casama bot templates (.casama-bot.json, format casama.bot v1) and workspace files (casama.json, routine .md files, SKILL.md per bot, git sync). Use when asked to export, import, share or hand-write a Casama bot, its routines or skills, or keep them in a GitHub repo."
---

# Bot templates and workspace files

Two file formats carry Casama configuration:

| Format | Holds | Use it to |
| --- | --- | --- |
| Bot template (`casama.bot` v1, `*.casama-bot.json`) | One bot: instructions, autonomy, mascot, skills, routines, connection names, optional memories | Share or copy a bot |
| Workspace files (`casama.files` v1 folder) | Every bot's routines and skills as Markdown | Edit in an editor, review in PRs, git sync |

Neither ever carries keys, secrets, OAuth tokens, the model choice, chats or computer files.

Full pages: https://docs.casama.ai/develop/bot-templates.md and
https://docs.casama.ai/develop/workspace-files.md

## Check the gallery first

Before writing a new bot, skill or routine, look for one that already exists at https://gallery.casama.ai: the
`gallery_search` tool of `npx -y @casama/mcp`, `casama gallery search "<words>"`, or the public
JSON files (`index.json`, `apps.json`, `bots.json`, `routines.json`, `plugins.json`, `sets.json`).
If one fits, point the person to its page (`https://gallery.casama.ai/i/<type>/<id>/`) or start
from it with `casama init --from-gallery bot/<id>`. Build a new one only when nothing fits, and
consider submitting it to the gallery afterwards.

## Bot template

```json
{
  "format": "casama.bot",
  "version": 1,
  "name": "Invoicer",
  "description": "Chases unpaid invoices politely.",
  "persona_md": "You chase unpaid invoices for a small design studio. Be polite and brief...",
  "autonomy": "ask_risky",
  "avatar": "mascot:cool",
  "skills": [{
    "name": "dunning",
    "description": "Follow-up cadence for overdue invoices. Use when an invoice is past due.",
    "body_md": "1. Day 7: a friendly reminder...",
    "files": [{ "path": "scripts/overdue.sh", "content_base64": "IyEvYmluL2Jhc2gK", "executable": true }]
  }],
  "routines": [{ "name": "Weekly chase", "instructions_md": "Check for overdue invoices...", "schedule_cron": "0 9 * * 1" }],
  "connections": [{ "kind": "composio", "name": "gmail" }, { "kind": "mcp", "name": "accounting" }],
  "memories": [{ "kind": "preference", "content": "Invoices go out from billing@example.com." }]
}
```

| Field | Rules |
| --- | --- |
| `format`, `version` | Always `"casama.bot"`, `1` |
| `name` | Required, 1-80 chars |
| `description` | Optional, max 300 |
| `persona_md` | Required (may be empty), max 20,000 |
| `autonomy` | Required: `ask_always`, `ask_risky` (default) or `autonomous` |
| `avatar` | `mascot:<cool\|focused\|giggly\|lovey\|shy\|sleepy\|starry\|thinker\|winky\|wow>` or `null`; anything else dropped |
| `skills` | Max 30. `name` `^[a-z0-9][a-z0-9_-]{0,62}$`, `description` 1-300, `body_md` max 50,000, `files` max 60 |
| skill `files[]` | `path` (letters, digits, `. _ - /`, no `..`), `content_base64` (max 1 MB decoded), `executable` (default false); 5 MB per skill |
| `routines` | Max 20. `name` 1-120, `instructions_md` 1-20,000, `schedule_cron` 5-field cron. No time zone (runs in the importer's), no `ends_at`/`max_runs` |
| `connections` | Max 30. `kind` (`mcp`, `openapi`, `composio`, `a2a`, ...; max 40) and `name` (max 120). Names only |
| `memories` | Max 200. `kind` `fact`/`episode`/`summary`/`preference`, `content` 1-8,000 |

Exports skip workspace-wide skills, disabled skills, check-ins and non-cron routines (webhook,
once, etc.).

### Export, import, share (API, Bearer user token)

```sh
curl -s "$API/v1/bots/$BOT/export" -H "$AUTH" > invoicer.casama-bot.json     # ?memories=true for managers
jq -n --slurpfile t invoicer.casama-bot.json --arg org "$ORG" --arg key "$CRED" --arg model "$MODEL" \
  '{org_id:$org, template:$t[0], credential_id:$key, model:$model, include_routines:true, include_memories:false}' |
  curl -s -X POST "$API/v1/bots/import" -H "$AUTH" -H "content-type: application/json" -d @-
```

- Import requires `org_id`, `template`, `credential_id`, `model`; returns 201
  `{bot_id, skills, routines, memories, connections_to_add}`. It always creates a **new** bot and
  connects nothing.
- Validation stops everything: `validation_failed`, `skill_too_large`, `skill_bad_path`,
  `invalid_cron`; also `forbidden`, `credential_not_found`, plan bot limit.
- On Casama Cloud (billing plus cloud models on) `credential_id`/`model` are still required but the
  bot uses the server's cloud model.
- Share link: `POST /v1/bots/{id}/share` `{include_memories, expires_in_days}` (1-365, default 30,
  `null` = never) → `{token, url, expires_at}`; read with `GET /v1/bot-shares/{token}`.
- Convert OpenClaw or Hermes Agent: `POST /v1/agent-imports` `{org_id, zip_base64}` (or a file list;
  max 50 MB, 3,000 files) → a template to review, then `POST /v1/bots/import`.

## Workspace files

```text
casama-files/
├── casama.json                    {"format":"casama.files","version":1,"bots":{"invoicer":{"id":"<uuid>","name":"Invoicer"}}}
├── invoicer/routines/weekly-chase.md
├── invoicer/skills/dunning/SKILL.md (+ files)
└── workspace/skills/house-style/SKILL.md     every bot has it
```

Folders match bots by `id` in `casama.json`, else by folder name vs bot name (lowercase, dashes).
`workspace/` is reserved.

### Routine file `<bot>/routines/<name>.md`

```markdown
---
id: 8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f
name: Weekly chase
schedule: 0 9 * * 1
timezone: America/Chicago
trigger: schedule
enabled: true
notify: true
ends_at: null
max_runs: null
---

Check for overdue invoices and follow the dunning skill.
```

- `name` required (max 120); body required (max 20,000). Omit `id` for a new routine.
- `trigger`: `schedule` (default), `once` (needs `run_at`, an ISO time), `webhook`, `github`,
  `calendar_event`, `message`, `device`. `schedule` is cron for `schedule`, `null` otherwise.
- `timezone` IANA, default `UTC`. `enabled`, `notify` default `true`.
- `ends_at` / `max_runs` (1-10,000): `null` removes, missing leaves as is; a changed `max_runs`
  counts from the import. Not for `once`. Can't enable past the end.
- Event triggers keep settings under `calendar`, `message` or `device` (one-line JSON or an indented
  map). A message routine needs a filter; arrive/leave need `place`.
- **A file can't create a `webhook`/`github` routine** or switch to one (they need a secret); create
  those via app or API, then files can edit them. Git sync can't create `device` routines.
- Kind changes allowed only between `schedule` and `once`.

### Skill file

Normal `SKILL.md` plus optional `id` and `enabled`. `name` must match the folder; description
first 300 chars kept, body max 50,000. Imported files are **not executable**, so call scripts via
their interpreter (`bash scripts/check.sh`). Plugin skills can't be changed this way (reported as
an error).

### Export, import, git sync (owners and admins)

```sh
casama files export ./casama-files --org acme
casama files import ./casama-files --dry-run      # + created, ~ updated, ! error; exit 1 on errors
casama files import ./casama-files
```

API: `POST /v1/orgs/{id}/files/export` → `{zip_base64, count, files}`;
`POST /v1/orgs/{id}/files/import` with `zip_base64` or `files: [{path, content_base64}]` (max
5,000) and `dry_run` → `{created, updated, deleted, unchanged, errors, dry_run}`.

Import matches routines by `id`, else bot + name; skills by bot + name. **Import never deletes.**
Bad files are listed in `errors`; the rest apply.

Git sync: workspace secret `GITHUB_TOKEN` allowed for `api.github.com`, then
`PUT /v1/orgs/{id}/git-sync` `{repo: "owner/name", branch: "main", path}`; first setup returns
`webhook_url` + `webhook_secret` once (push events, `application/json`). Sync runs within about a
minute of a Casama change, every 10 minutes from the repo, sooner with the webhook. Conflicts:
Casama keeps its version and opens a PR on `casama/sync-...`. **Git sync does delete** a routine or
skill whose file (with an `id`) is removed. `GET /v1/orgs/{id}/git-sync` shows `last_error`,
`open_pr_url`, `has_token`; `POST .../git-sync/run` syncs now.

## Checklist

- [ ] Template has `format`, `version`, `name`, `persona_md`, `autonomy`; within every limit
- [ ] No secrets, tokens or URLs with credentials anywhere (connections are names only)
- [ ] Cron strings are 5 fields; routine files name a `timezone`
- [ ] Skill folder names equal SKILL.md `name`; scripts invoked through `bash`/`python3`
- [ ] Ran `casama files import --dry-run` (or `dry_run: true`) before applying
