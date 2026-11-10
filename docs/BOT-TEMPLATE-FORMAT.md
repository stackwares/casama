# Kasama bot template format

A shareable bot is one JSON file (`*.kasama-bot.json`). The app exports it from bot settings →
Share as template, and imports it from Bots → Import a bot or from a share link. The community
template repository accepts the same files.

```json
{
  "format": "kasama.bot",
  "version": 1,
  "name": "Invoicer",
  "description": "Chases unpaid invoices politely.",
  "persona_md": "You chase unpaid invoices politely...",
  "autonomy": "ask_risky",
  "avatar": "mascot:cool",
  "skills": [
    {
      "name": "dunning",
      "description": "Follow-up cadence for overdue invoices",
      "body_md": "1. Day 7: a friendly reminder...",
      "files": [{ "path": "templates/email.md", "content_base64": "SGVsbG8ge25hbWV9", "executable": false }]
    }
  ],
  "routines": [{ "name": "Weekly chase", "instructions_md": "Chase overdue invoices.", "schedule_cron": "0 9 * * 1" }],
  "connections": [{ "kind": "composio", "name": "Gmail" }],
  "memories": []
}
```

- `autonomy`: `ask_always`, `ask_risky` or `autonomous`.
- `avatar`: a built-in mascot (`mascot:<name>`) or null. Uploaded pictures are not exported.
- `skills`: the bot's own skills in the Agent Skills shape; files are base64 (1 MB a file, 5 MB and
  60 files a skill). Scripts only ever run on a bot's computer.
- `routines`: repeating schedules (5-field cron), run in the importer's timezone.
- `connections`: services to connect after importing. Names only: no credentials ever travel.
- `memories`: only present when the person exporting chose to include them.

Never in a template: model keys, secrets, OAuth tokens, the model choice (the importer picks a key
and model), chats or files from the bot's computer.
