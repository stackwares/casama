# Skills

A skill is a set of instructions a bot loads when a task calls for it, like your house style for
reports or the steps for cleaning up a spreadsheet. Skills keep a bot's standing instructions short:
the bot always knows which skills it has, and reads the full text only when it needs one.

## How skills work

Every run, a bot sees the name and one-line description of each enabled skill it can use. When a
task matches a description, the bot loads that skill's full instructions. The chat shows this as
**Loaded skill …**. Any files that come with the skill are copied to `~/skills/<name>/` on the
bot's computer, so its scripts can run there.

A skill belongs either to the whole workspace, so every bot can use it, or to one bot.

You can also make sure a bot uses a skill: type `/` in the message field and pick it. See
[Chatting with a bot](/guide/chat).

## The skill format

Casama uses the open Agent Skills layout, so skills written for other apps that read it work here
too. A skill is a folder with a `SKILL.md` file and, optionally, other files:

```text
weekly-report/
├── SKILL.md
├── template.md
└── scripts/
    └── build.py
```

`SKILL.md` starts with front matter, then the instructions in Markdown:

```markdown
---
name: weekly-report
description: Turn the week's notes into a one-page report for the team.
---

# Steps

1. Read the notes in ~/workspace/notes from the last 7 days.
2. Fill in template.md: wins, problems, next week.
3. Keep it under one page.
```

| Field or rule | Requirement |
| --- | --- |
| `name` | Lowercase letters, digits, `-` and `_`, starting with a letter or digit, up to 63 characters. |
| `description` | One line. Bots read it to decide when the skill applies, so say when to use it. |
| Extra files | Up to 60 files, 1 MB each and 5 MB in total. |
| Scripts | Run only on a bot's computer, never on the server. |

## Create a skill

1. Go to **Settings** → **Skills** and select **New skill**.
2. Fill in **Name (lowercase, dashes)**, **One-line description** and **Instructions (Markdown)**.
3. Select **Save**.

Skills made here belong to the whole workspace. Use the switch next to a skill to turn it off for
every bot without deleting it. To change or remove a skill, select it, then **Save** or
**Delete skill**.

You can also teach a bot a skill by doing the task once while it watches. See
[Teach by showing](/guide/teach).

## Install from the catalog

Casama ships a catalog of ready-made skills in seven categories: Work (meeting notes, meeting
prep, weekly report, email drafts, inbox triage, decision memos, a daily digest, feature specs,
PDF, Word and PowerPoint), Writing (proofreading, tone rewrites, social posts, article outlines),
Research (research briefs, comparisons, fact checks, document summaries, a second pass over claims,
competitive briefs), Data (CSV cleanup with a cleaning script, spreadsheet formulas, charts, Excel,
an HTML dashboard), Money (budget reviews, invoice checks), Build (code review, bug reports, SQL,
web app checks, systematic debugging) and Life (trips, meals, gifts, workouts, teaching a topic).

The catalog comes from the [open gallery](https://gallery.casama.ai/#skill), so new and improved
skills arrive without an app update, and anyone can propose one by pull request. When the gallery
can't be reached, the copy that ships with Casama is shown.

1. Go to **Settings** → **Skills** and select **Skill catalog**. The catalog opens as its own page.
2. Search, or filter by category. Select a skill to read its full instructions.
3. Select **Install**, then choose **The whole workspace** or one bot. With no bots yet, it installs
   for the whole workspace straight away. Installed skills show a check.

Workspace owners and admins can install for the whole workspace. People who manage a bot can
install for that bot.

## Import from GitHub

1. Go to **Settings** → **Skills** and select **Import from GitHub**.
2. Paste a link to a folder that contains a `SKILL.md`, then select **Preview**.
3. Review `SKILL.md` and every file in the folder. Binary files are marked as such.
4. Under **Install for**, choose **The whole workspace** or one bot, then select **Install**.

Casama installs exactly the commit you previewed, so a change pushed after your review never
sneaks in. The skill is labeled with its repository.

Private repositories need a workspace secret named `GITHUB_TOKEN` that is allowed for
`api.github.com`. See [Apps and connections](/guide/connections).

### Update a GitHub skill

1. In **Settings** → **Skills**, select **Check for updates** on the skill.
2. If there's a newer commit, review the line-by-line changes to `SKILL.md` and the files
   **Added**, **Changed** and **Removed**.
3. Select **Update**. Otherwise you see **Already up to date.**

## Skills bots write

A bot can save a skill for itself, for example after you walk it through a task, and improve the
skills it saved. Skills a bot saves belong to that bot and show **Saved by a bot**.

- A bot can change only its own skills. Workspace skills are for admins to change.
- Saving or changing a skill is a medium-risk action. When it needs your approval (see
  [Autonomy and approvals](/guide/autonomy)), the approval card shows the whole `SKILL.md` for a
  new skill, or a line-by-line diff for a change.

## Skill ideas from a bot's own work

Bots also learn from how their runs go and suggest skills for you to approve.

- **A new skill.** When a bot succeeds at a task using at least two tools and no skill, and it has
  done similar tasks successfully at least twice before, it writes up a skill from up to four of
  those runs: a name, a description, the steps and the tools it used. It suggests each idea once.
- **A better skill.** When a run that used a skill fails, or you correct the bot in your next
  message ("no…", "actually…", "that's wrong"), the bot rewrites the skill and says what
  changed.

To review ideas:

1. You get a notification. Open **Inbox** → **Needs you**. Ideas show as cards, for example "Ada
   suggests a skill: weekly-report" or "Ada suggests improving weekly-report".
2. Read the steps, the tools it **Uses**, or the line-by-line change.
3. Select **Save skill** or **Apply change**, or **Dismiss**.

Ideas wait for the bot's owner. To apply them without asking, add an action rule that allows the
bot's `skills.create` or `skills.update`. See [Autonomy and approvals](/guide/autonomy).

Plugin skills are never changed this way.

## See how a skill is doing

In **Settings** → **Skills**, select **How it's doing** on a skill to see how many times it was
used, how often it went well, failures, corrections, the last problem, and **Earlier versions**.
Every change to a skill, by a person or a bot, keeps the old text.

## Skills as files

Every skill (and routine) can be exported as Markdown files, edited anywhere and imported back, or
kept in sync with a GitHub repository. See [Workspace files](/develop/workspace-files).

## Limits

- Skill ideas appear in **For you** and as a notification, not as a card in the chat.
- Learning counts only runs since the feature arrived on your server; older history doesn't count.
- Runs in group chats don't lead to skill ideas.
- Without an OpenAI API key for embeddings, similar runs are matched by shared words only.
- Skills from plugins are managed with the plugin. See [Plugins](/develop/plugins).

## Related

- [Chatting with a bot](/guide/chat)
- [Teach by showing](/guide/teach)
- [Workspace files](/develop/workspace-files)
- [Plugins](/develop/plugins)
- [Autonomy and approvals](/guide/autonomy)
