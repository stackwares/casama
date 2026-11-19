# Templates, sharing and import

You can pass a bot along in two ways: share a copy as a template that anyone can import into their
own workspace, or give people in your workspace access to the bot itself. You can also bring a bot
over from another agent app.

| You want to | Use |
| --- | --- |
| Give someone a copy of a bot to set up as their own | [Share as template](#share-a-bot-as-a-template) |
| Let teammates chat with, edit or manage one of your bots | [Sharing](#share-a-bot-with-people) |
| Move an agent from OpenClaw or Hermes Agent | [Import an agent](#import-an-agent) |
| Move a bot from Grok Bot, Muse, ChatGPT Dots, Claude Duet, Hark or Instinct | [Paste a bot's setup](#paste-a-bot-s-setup) |
| Bring what ChatGPT or Claude knows about you | [Import memories](#import-memories-from-chatgpt-or-claude) |
| Share a page, picture, document or file a bot made | [Share what bots make](#share-what-bots-make) |
| Share a chat | [Share or export a chat](#share-or-export-a-chat) |

## Share a bot as a template

A template is a copy of a bot's setup: its instructions, skills, routines and the services it
uses. It never holds keys, secrets or sign-ins.

1. Open the bot's **Bot profile** → **Advanced** → **Share as Template**.
2. Optional: tick **Include Memories**. Leave it off unless you trust who you share with, since it
   carries what the bot has learned about you and your work.
3. Choose how to share it:
   - **Save as File** saves a `.casama-bot.json` file.
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
| Memories, only if you ticked **Include Memories** | |

Templates use the open `casama.bot` format, which is also what the community template repository
accepts. See [Bot templates](/develop/bot-templates) for the file format.

## Import a bot

1. Open the template:
   - **A file:** select **Add** (the **+** button) → **Import a bot**, then pick the file.
   - **A link:** open it. It works for anyone signed in to Casama, in any workspace.
2. Review **What Comes with It**: the instructions, skills, routines, the apps to
   **Connect after importing**, and how many memories it has.
3. Choose whether to **Schedule Its Routines** and **Keep its memories**.
4. On a self-hosted server, under **Model**, pick a **Model key** from your workspace and a
   **Model**. The key's default model is filled in. Casama Cloud picks the model for you and skips
   this step.
5. Select **Import a bot**.

The new bot belongs to you, and its routines run in your timezone. Casama can't sign in to apps for
you, so if the template uses any, you see which ones to connect in Integrations. Importing counts
toward your workspace's bot limit.

## Share a bot with people

By default, everyone in the workspace can chat with a bot. Make it private to choose exactly who
can see it, or add people who should be able to change it.

1. Open the bot's **Bot profile** → **Sharing**.
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
**Everyone Who Is …**.

From the CLI, `casama bot create --private` creates a bot that only you can see.

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

1. Select **Add** (the **+** button) → **Import an Agent**.
2. In the desktop app, choose **Pick Its Folder**. Anywhere, you can choose
   **Upload a ZIP of its folder** (a ZIP of the whole home folder or of only its workspace folder
   both work).
3. Review what was found. Edit the **Name**, read the persona, and untick any skill, routine or
   memory you don't want. Files that weren't imported are listed with the reason.
4. On a self-hosted server, pick a **Model key** and **Model**. Then select **Import an Agent**.

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
bot from outside Casama.

## Paste a bot's setup

Bring a bot over from Grok Bot, Meta Muse, ChatGPT Dots, Claude Duet or Cowork, Hark Pro, Instinct,
or any other app
whose bot can describe itself. Your old bot answers a prompt with its setup, and you paste the
answer into Casama. Nothing is read from the other app's servers.

1. Select **Add** (the **+** button) → **Import an Agent** → **Paste a Bot's Setup**.
2. Pick where your bot is now. **Copy** the prompt and send it to your old bot.
3. Paste its whole reply under **2. Paste its reply**, then select **Next**.
4. Review what was found, untick anything you don't want, and select **Import an Agent**.

The prompt asks for a fixed format:

```
NAME: Inbox Chief
ABOUT: Keeps my inbox under control
INSTRUCTIONS:
"""
You are Inbox Chief. Triage email every morning.
"""
SCHEDULE: weekdays 08:30 | Summarize unread email
EVENT: New email from my boss | Flag it and ping me
SKILL: weekly-report | Builds the Friday report
"""
1. Open the sent folder
2. Write a short report
"""
APP: Gmail
ASK_FIRST: Sending an email
MEMORY: Works at Stackwares
PREFERENCE: Likes short answers
```

What becomes what:

| In the reply | In Casama |
| --- | --- |
| `NAME`, `ABOUT` | The bot's name and description |
| `INSTRUCTIONS` | Its instructions |
| `ASK_FIRST` | A "Check with me before" list in its instructions; a rule like "anything" sets it to ask every time |
| `SCHEDULE` | Routines. Times can be `daily 09:00`, `weekdays 09:00`, `weekly mon 08:00`, `monthly 1 09:00`, `every 2 hours` or `every 30 minutes`, and run in your time zone |
| `EVENT` | Not made into routines. A note names the closest trigger: Meetings, Messages, GitHub or a webhook |
| `SKILL` | Skills, with the steps as the skill's instructions |
| `APP` | Shown as apps to connect after importing |
| `MEMORY`, `PREFERENCE` | Memories |

Along the way:

- **Keys are removed.** Lines that look like keys, tokens, passwords or card numbers are dropped before anything
  is read, with a note saying how many.
- **Markdown is fine.** Bold labels, headings such as `## Schedules`, bullet lists and code fences
  all work.
- **Any text works.** If the paste doesn't follow the format, for example text copied from a
  settings page, all of it becomes the bot's instructions, with a note.
- **What doesn't come over:** the other app's computer, files and sign-ins. Sign in to the bot's
  apps again in Integrations.
- **ChatGPT Dots** has no schedules, and you can't list its memories one by one, so a Dots import
  is mostly its instructions.
- **Hark Pro** has no memory in the EEA, the UK or Switzerland, so an import from there has no
  memories.
- **Instinct** works by text message, so its prompt is short and asks for plain lines with no
  formatting. If its answer comes as several texts, paste them all into the box together.

The same review and limits as a template apply.

## Import memories from ChatGPT or Claude

1. Open the bot's **Memory** screen and select the import button.
2. **Copy** the prompt into ChatGPT or Claude, then paste its answer under **Its answer** and
   select **Next**.
3. Untick anything that's wrong, then select **Save**.

See [Memory and knowledge](/guide/memory).

## Share what bots make

Pages, pictures, videos, sounds, documents and files a bot makes are kept in the
[Library](/guide/library), and each one can be shared on its own.

1. Open the item in the Library.
2. Under **Who Can See It**, choose **Only me**, **Workspace** or **Anyone with the link**.

**Anyone with the link** gives a public link that anyone can open without signing in. Making it
public again gives a new link, and the old one stops working. A workspace can make at most 20 new
public links a day, and every public item has a link for viewers to report it. See
[Library](/guide/library) for details.

To put a site on the web at an address of its own, or on your own domain, see
[Sites and domains](/guide/sites-and-domains).

## Share or export a chat

Through the [HTTP API](/develop/api), you can:

- **Export a chat** as Markdown or JSON (`GET /v1/conversations/{id}/export`). The export has only
  what you can see in it.
- **Share a read-only link** to a chat (`POST /v1/conversations/{id}/share` with `public: true`).
  The link shows the chat as its starter saw it, with attachments listed by name only. Sharing
  again gives a new link; `public: false` turns it off. Only the person who started the chat or the
  bot's managers can share it, and a chat that holds personal data from a device can't be made
  public.

The app doesn't have buttons for these yet.

## Limits

- A template holds at most 30 skills, 20 routines, 200 memories and 20,000 characters of
  instructions. Agent imports over these limits are trimmed, with a note.
- Agent uploads can be up to 50 MB and 3,000 files.
- Template share links can't be revoked from the app; they expire after 30 days.
- The app shares a bot with individual members only. Role-wide access needs the API
  (`PUT /v1/bots/{id}/access`).
- Newer OpenClaw versions keep scheduled jobs in a database, which isn't read, so those jobs don't
  come over.
- Other files are kept for one day after an agent import. If the new bot has no computer yet, they
  can't be copied; give it a computer and import again.

## Related

- [Packs](/guide/packs): share several bots with their skills and routines in one link
- [Bot templates](/develop/bot-templates)
- [Bots and models](/guide/bots)
- [Memory and knowledge](/guide/memory)
- [Workspaces and teams](/guide/workspaces)
