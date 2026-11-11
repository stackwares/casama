# Routines and skills as files

Every routine and skill in a workspace can live as a Markdown file. Export them to a folder, edit
them in any editor, review changes in pull requests, and import them back. Or connect a GitHub
repository and let Kasama keep both sides in sync.

Exporting, importing and git sync are for workspace owners and admins, because the files cover
every bot in the workspace.

## The folder layout

```text
kasama-files/
├── kasama.json                     which folder is which bot
├── invoicer/                       one folder per bot
│   ├── routines/
│   │   └── weekly-chase.md         one file per routine
│   └── skills/
│       └── dunning/
│           ├── SKILL.md            one folder per skill
│           └── templates/
│               └── reminder.md     files the skill uses
└── workspace/
    └── skills/
        └── house-style/
            └── SKILL.md            a skill every bot in the workspace has
```

Bot folders are named after the bot (lowercase, with dashes). `workspace/` is reserved for skills
the whole workspace shares.

### kasama.json

The index that ties folders to bots:

```json
{
  "format": "kasama.files",
  "version": 1,
  "bots": {
    "invoicer": { "id": "5d0c1e6a-8b7f-4e8a-a1d2-3c4b5a6f7e80", "name": "Invoicer" }
  }
}
```

On import, a folder matches a bot by the `id` in `kasama.json`. Without a match there (or without
`kasama.json` at all), Kasama matches the folder name against the bot names. Renaming a bot in the
app doesn't break the link, as long as `kasama.json` keeps its id.

### Routine files

`<bot>/routines/<name>.md`: front matter between `---` lines, then the instructions.

```markdown
---
id: 8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f
name: Weekly chase
schedule: 0 9 * * 1
timezone: America/Chicago
trigger: schedule
enabled: true
notify: true
---

Check for overdue invoices and follow the dunning skill. Send me a short summary of who you
contacted.
```

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | no | The routine's id. Kasama writes it on export; leave it out for a new routine. |
| `name` | yes | Up to 120 characters |
| `schedule` | for `schedule` triggers | A 5-field cron expression; `null` for other triggers |
| `timezone` | no | An IANA time zone, such as `America/Chicago`. Defaults to `UTC`. |
| `trigger` | no | `schedule` (default), `webhook` or `github` |
| `enabled` | no | `true` (default) or `false` |
| `notify` | no | Whether to notify you when it runs: `true` (default) or `false` |

The body after the front matter is the instructions: required, up to 20,000 characters.

::: warning Webhook and GitHub triggers
A file can't create a webhook or GitHub routine, or switch a routine to one, because those need a
secret that only the app shows. Create them in the app or the API (see
[Webhooks](/develop/webhooks)); after that, their files can update the name, instructions and
other fields like any routine.
:::

### Skill files

`<bot>/skills/<name>/SKILL.md` for one bot's skill, or `workspace/skills/<name>/SKILL.md` for a
skill every bot in the workspace has. It's a normal [Agent Skills](https://agentskills.io)
`SKILL.md`, plus Kasama's `id` and `enabled`:

```markdown
---
name: dunning
description: Follow-up cadence for overdue invoices. Use when an invoice is past due.
id: 0f9e8d7c-6b5a-4c3d-2e1f-0a9b8c7d6e5f
enabled: true
---

1. Day 7: a friendly reminder, using templates/reminder.md.
2. Day 14: a firmer note with the invoice attached.
3. Day 30: tell me before sending anything else.
```

| Field | Required | Meaning |
| --- | --- | --- |
| `name` | yes | Lowercase letters, digits, `-` and `_`, up to 63 characters. Must match the folder's name. |
| `description` | yes | When to use the skill. Kasama keeps the first 300 characters. |
| `id` | no | Written on export |
| `enabled` | no | `true` (default) or `false` |

The body is the skill's instructions (up to 50,000 characters). Every other file in the skill's
folder goes with it, so the bot finds it on its computer. Files imported this way aren't marked
executable, so start scripts with their interpreter (`bash scripts/check.sh`,
`python3 tool.py`). See [Skills](/guide/skills).

### What's left out

Export skips skills installed by [plugins](/develop/plugins) (change the plugin instead) and
check-in routines, which Kasama manages for you. Archived bots aren't exported.

## Export

**In the app:** Workspace settings → **Routines and skills as files** → **Export as files** saves a
ZIP.

**With the CLI:**

```sh
kasama files export ./kasama-files --org acme
```

**With the API:** `POST /v1/orgs/{id}/files/export` returns the same files both as one ZIP and
one by one, base64-encoded:

```sh
curl -s -X POST "https://kasama.example.com/v1/orgs/$ORG/files/export" \
  -H "authorization: Bearer $TOKEN" | jq -r .zip_base64 | base64 --decode > kasama-files.zip
```

```json
{
  "zip_base64": "UEsDBBQ...",
  "count": 4,
  "files": [{ "path": "kasama.json", "content_base64": "ewogICJmb3JtYXQi..." }]
}
```

## Import

**In the app:** Workspace settings → **Routines and skills as files** → **Import files**, pick a
ZIP, review the preview (new, changed and unchanged), then **Apply**.

**With the CLI:**

```sh
kasama files import ./kasama-files --dry-run
kasama files import ./kasama-files
```

The CLI skips files and folders whose names start with `.`, such as `.git`.

**With the API:** `POST /v1/orgs/{id}/files/import` takes either a ZIP or a list of files:

```sh
jq -n --arg zip "$(base64 < kasama-files.zip | tr -d '\n')" '{zip_base64: $zip, dry_run: true}' |
curl -s -X POST "https://kasama.example.com/v1/orgs/$ORG/files/import" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d @-
```

| Field | Meaning |
| --- | --- |
| `zip_base64` | A ZIP of the folder, base64-encoded. A ZIP whose files all sit in one top folder with `kasama.json` inside works too. |
| `files` | Instead of a ZIP: `[{ "path": "invoicer/routines/weekly-chase.md", "content_base64": "..." }]` |
| `dry_run` | `true` to see what would change without changing anything |

```json
{
  "created": ["invoicer/routines/month-end.md"],
  "updated": ["invoicer/skills/dunning/SKILL.md"],
  "deleted": [],
  "unchanged": 2,
  "errors": ["invoicer/routines/bad.md: \"0 9 * *\" isn't a valid cron schedule"],
  "dry_run": true
}
```

### How import decides

- **Matching.** A routine matches by its `id`, else by bot and name. A skill matches by bot and
  name.
- **Changes.** A changed file updates its routine or skill; a new file creates one. Changing a
  schedule or time zone moves the next run.
- **Nothing is deleted.** Removing a file and importing leaves the routine or skill in place.
  Delete it in the app. (Git sync is different; see below.)
- **Bad files are skipped.** Every file is checked: front matter, cron, time zone, names, and that
  a skill's folder matches its name. Problems are listed in `errors`, and the other files still
  apply. The CLI exits with code 1 when there are errors.
- **Plugin skills stay as they are.** A file for a skill that came from a plugin is reported as an
  error.

## Git sync

Git sync keeps a workspace's routines and skills in a GitHub repository, both ways. Edit a routine
in the app and Kasama commits the change; push a change to the repository and Kasama applies it.

### Set it up

1. **Add a GitHub token.** In workspace secrets, add a secret named `GITHUB_TOKEN`, allowed for the
   host `api.github.com`, with a token that can push to the repository and open pull requests.
2. **Connect the repository.** In Workspace settings → **Routines and skills as files** → **Git
   sync**, enter the repository (`owner/name`), the branch (default `main`) and, optionally, a
   folder inside the repository. Or use the API:

   ```sh
   curl -s -X PUT "https://kasama.example.com/v1/orgs/$ORG/git-sync" \
     -H "authorization: Bearer $TOKEN" \
     -H "content-type: application/json" \
     -d '{"repo": "acme/kasama-config", "branch": "main", "path": "bots"}'
   ```

3. **Add the webhook.** The first setup returns a `webhook_url` and a `webhook_secret`, shown only
   this once. In the repository's **Settings → Webhooks**, add a webhook for push events with that
   payload URL and secret, and the content type `application/json`. See
   [Git sync webhook](/develop/webhooks#git-sync-webhook).

The webhook is optional but makes changes from the repository arrive within a minute instead of
within 10 minutes.

### How sync works

Each sync compares three versions of every file: what was synced last time, what Kasama has now,
and what the branch has now.

| Changed in | Result |
| --- | --- |
| Kasama only | Kasama commits the change to the branch |
| The repository only | Kasama checks the file and applies it. A bad file is reported and retried once it's fixed. |
| Both | Kasama keeps its version and opens a pull request with it on a `kasama/sync-...` branch. Merging it makes both sides agree. |

- **When.** Changes in Kasama sync within about a minute. Kasama also checks the repository every
  10 minutes, and a push webhook makes it check on the next minute. **Sync now** in the app (or
  `POST /v1/orgs/{id}/git-sync/run`) does the same.
- **Deletions.** Unlike import, git sync deletes a routine or skill when you remove its file from
  the repository (only files that carry an `id`).
- **Moving.** Changing the repository, branch or folder starts over, as if syncing for the first
  time.

`GET /v1/orgs/{id}/git-sync` shows the state: `last_synced_at`, `last_commit`, `last_error` (bad
files and other problems) and `open_pr_url` when a pull request is waiting for you. `has_token`
tells you whether the `GITHUB_TOKEN` secret is in place. `DELETE /v1/orgs/{id}/git-sync` stops
syncing and leaves the repository as it is.

## Limits

| What | Limit |
| --- | --- |
| Routine name | 120 characters |
| Routine instructions | 20,000 characters |
| Skill name | 63 characters |
| Skill description | 300 characters kept |
| Skill body | 50,000 characters kept |
| Files in an API import's `files` list | 5,000 |
| Who | Workspace owners and admins |

## Related

- [Routines](/guide/routines)
- [Skills](/guide/skills)
- [Webhooks](/develop/webhooks)
- [Bot template format](/develop/bot-templates): one bot as a shareable file
- [CLI](/develop/cli#routines-and-skills-as-files-files)
