# Templates, sharing and import

You can pass a bot along in two ways: share a copy as a template that anyone can import into their
own workspace, or give people in your workspace access to the bot itself. You can also bring a bot
over from another agent app.

| You want to | Use |
| --- | --- |
| Give someone a copy of a bot to set up as their own | [Share as template](#share-a-bot-as-a-template) |
| Let teammates chat with, edit or manage one of your bots | [Sharing](#share-a-bot-with-people) |
| Move an agent from OpenClaw or Hermes Agent | [Import an agent](#import-an-agent) |
| Bring what ChatGPT or Claude knows about you | [Import memories](#import-memories-from-chatgpt-or-claude) |

## Share a bot as a template

A template is a copy of a bot's setup: its instructions, skills, routines and the services it
uses. It never holds keys, secrets or sign-ins.

1. Open the bot's **Bot settings** → **Share as template**.
2. Optional: tick **Include memories**. Leave it off unless you trust who you share with, since it
   carries what the bot has learned about you and your work.
3. Choose how to share it:
   - **Save as file** saves a `.kasama-bot.json` file.
   - **Copy link** creates a link and copies it. Links work for 30 days.

Anyone who can see the bot can save it as a file. Creating a link, and including memories, is for
people who manage the bot. Every share is recorded in the audit log.

What a template carries:

| Included | Never included |
| --- | --- |
| Name, description and instructions | Model keys and the model choice |
| Autonomy level | Secrets and passwords |
| Its built-in mascot | Sign-ins to apps (OAuth tokens) |
| The bot's own skills, with their files | Workspace skills |
| Its repeating routines | One-time routines |
| The apps and services it uses, by name only | |
| Memories, only if you ticked **Include memories** | |

Templates use the open `kasama.bot` format, which is also what the community template repository
accepts. See [Bot templates](/develop/bot-templates) for the file format.

## Import a bot

1. Open the template:
   - **A file:** select **Add** (the **+** button) → **Import a bot**, then pick the file.
   - **A link:** open it. It works for anyone signed in to Kasama, in any workspace.
2. Review **What comes with it**: the instructions, skills, routines, the apps to
   **Connect after importing**, and how many memories it has.
3. Choose whether to **Schedule its routines** and **Keep its memories**.
4. Under **Model**, pick a **Model key** from your workspace and a **Model**. The key's default
   model is filled in.
5. Select **Import a bot**.

The new bot belongs to you, and its routines run in your timezone. Kasama can't sign in to apps for
you, so if the template uses any, you see which ones to connect in Integrations. Importing counts
toward your workspace's bot limit.

## Share a bot with people

By default, everyone in the workspace can chat with a bot. Make it private to choose exactly who
can see it, or add people who should be able to change it.

1. Open the bot's **Bot settings** → **Sharing**.
2. Turn on **Private** to hide the bot from everyone except you and the people you list.
3. Under **People**, add workspace members. Each starts with **Can chat**.
4. Change each person's access, or remove them with **×**.
5. Select **Save**.

| Access | What they can do |
| --- | --- |
| **Can chat** | See the bot and chat with it. |
| **Can edit** | Also change its settings, memory, knowledge and other things a bot's managers can change. |
| **Can manage** | Also change who has access. |

The bot's creator and workspace admins can always change sharing. Only workspace members can be
listed, and every change is recorded in the audit log. Access can also be given to a whole role
(for example everyone who is an admin or higher) through the API; such entries show as
**Everyone who is …**.

From the CLI, `kasama bot create --private` creates a bot that only you can see.

### A bot working for someone uses only their things

When several people use one bot, it acts for whoever started the work, and uses only what that
person may use:

- Local tools (MCP servers) on someone's own computer are offered only in their runs.
- A bot whose computer is someone's personal computer won't use it in other people's runs.
- Personal password managers and ChatGPT plans work the same way.

Knowledge belongs to the bot or the workspace, so everyone who can chat with the bot shares it.

## Import an agent

Bring an agent over from OpenClaw or Hermes Agent: its persona, skills,
schedules and memories. You review everything before the bot is created, and keys and settings
files are never read.

1. Select **Add** (the **+** button) → **Import an agent**.
2. In the desktop app, choose **Pick its folder**. Anywhere, you can choose
   **Upload a ZIP of its folder** (a ZIP of the whole home folder or of only its workspace folder
   both work).
3. Review what was found. Edit the **Name**, read the persona, and untick any skill, routine or
   memory you don't want. Files that weren't imported are listed with the reason.
4. Pick a **Model key** and **Model**, then select **Import an agent**.

What becomes what:

| From | OpenClaw | Hermes Agent |
| --- | --- | --- |
| Persona | `SOUL.md` and `AGENTS.md`; `IDENTITY.md` gives the name | `SOUL.md`, plus `AGENTS.md` or `.hermes.md` |
| Facts | `MEMORY.md` | `memories/MEMORY.md` |
| Preferences | `USER.md` | `memories/USER.md` |
| Episodes | The newest 60 daily notes in `memory/` | |
| Skills | `skills/<name>/SKILL.md` | `skills/<category>/<name>/SKILL.md` |
| Routines | Scheduled jobs in `cron/jobs.json` | Scheduled jobs in `cron/jobs.json` |

Along the way:

- **Never read:** `.env`, `auth.json`, `credentials/`, `openclaw.json`, `config.yaml`, databases,
  sessions, logs and run history.
- **Not made into routines, with a note:** paused, one-off, finished and unreadable jobs. Jobs run
  in your timezone.
- **Fixed up:** invalid skill names are renamed, so `Weekly Report` becomes `weekly-report`.
- **Other files** (such as `HEARTBEAT.md` or notes) can be copied to `~/imported/openclaw/` or
  `~/imported/hermes/` on the new bot's computer. Tick **Copy … other files** to do that.

The import goes through the same review and limits as a template, so there's one way to create a
bot from outside Kasama.

## Import memories from ChatGPT or Claude

1. Open the bot's **Memory** screen and select the import button.
2. **Copy** the prompt into ChatGPT or Claude, then paste its answer under **Its answer** and
   select **Next**.
3. Untick anything that's wrong, then select **Save**.

See [Memory and knowledge](/guide/memory).

## Limits

- A template holds at most 30 skills, 20 routines, 200 memories and 20,000 characters of
  instructions. Agent imports over these limits are trimmed, with a note.
- Agent uploads can be up to 50 MB and 3,000 files.
- Share links can't be revoked from the app; they expire after 30 days.
- The app shares a bot with individual members only. Role-wide access needs the API
  (`PUT /v1/bots/{id}/access`).
- Newer OpenClaw versions keep scheduled jobs in a database, which isn't read, so those jobs don't
  come over.
- Other files are kept for one day after an agent import. If the new bot has no computer yet, they
  can't be copied; give it a computer and import again.

## Related

- [Bot templates](/develop/bot-templates)
- [Bots and models](/guide/bots)
- [Memory and knowledge](/guide/memory)
- [Workspaces and teams](/guide/workspaces)
