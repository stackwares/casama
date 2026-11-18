---
title: AI coding agents your bot can hand work to
h1: AI coding agents your bot can hand work to
card: Coding
crumb: Coding
description: A Casama bot can hand a coding task to Claude Code, Codex or Cursor on its own sandboxed computer or yours, and report back with what changed.
lead: A coding agent is good at code and bad at knowing when to run. A Casama bot can hand a task to Claude Code, Codex or Cursor, on a sandboxed computer, and come back with a summary and the changed files.
updated: 2026-11-18
order: 8
---

## What the bot does

- **Runs a coding agent for you.** Claude Code, Codex, Cursor, Pi or T3 Code.
- **Chooses where.** On the bot's sandboxed computer, on your own machine through the desktop app, or in Cursor's cloud.
- **Reports.** A summary, the files that changed and, for cloud agents, a pull request link.
- **Starts on triggers.** A new issue, a failing build, a schedule.
- **Keeps your machine safe.** On the bot's computer, the agent can't touch your files.

## Where it stops to ask

- Opening a pull request.
- High-risk actions on your own computer, always.
- Deleting anything outside its workspace folder.

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

1. You, from your phone: "Use Claude Code to fix the failing tests in the billing package."
2. The bot starts the agent on its computer with the repository checked out.
3. Ten minutes later: "Fixed 3 tests. Changed 2 files. Here's the diff."
4. You ask it to open a pull request. It asks first, then does.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. For the bot's computer: add the coding agent's API key as a named secret.
2. For your own computer: install the agent's command-line tool, sign in, and share the project folder in the desktop app.
3. Ask the bot in plain words which agent to use and where. The **Coder** persona brings a code-change skill.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## Questions

### Which coding agents work?

Claude Code, Codex, Cursor, Pi and T3 Code on your own computer; Claude Code, Codex and Cursor on the bot's computer; Cursor in the cloud.

### Does Casama replace my coding agent?

No. It runs the one you choose, on a schedule or from your phone, with approvals around it.

### Can I use it with MCP?

Yes. Casama has an MCP server, so a coding assistant can also hand work to your bots.

See [what else Casama bots do](/use-cases/).

{{cta}}
