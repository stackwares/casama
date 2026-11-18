---
title: Open-source AI agents with their own computers | Casama
h1: Open-source AI agents you can read, run and change
crumb: Open source
description: Casama is an open-source AI agent app under AGPL-3.0: bots with their own computers, memory and approvals, plus apps for every platform.
lead: Casama is open source under AGPL-3.0. The server, the apps for every platform, the CLI and the SDKs are all in one public repository.
updated: 2026-11-18
---

## What is open

Everything you need to run Casama for yourself or your team is in
[the repository](https://github.com/stackwares/casama):

- **The server**: the API, the worker that runs bots, and the sandbox that gives each bot a
  computer.
- **The apps**: iPhone, iPad, Android, Mac, Windows, Linux and web, from one codebase.
- **The CLI, the SDKs** for TypeScript and Dart, and an MCP server so other AI tools can talk to
  your bots.
- **The gallery**: skills, starter bots, routines, apps and looks, with a public catalog anyone can
  add to.

The licence is AGPL-3.0: use it, change it and run it, at work or at home. If you change Casama and
let other people use your version, you share your changes under the same licence. The SDKs, CLI,
MCP server and plugin kit are Apache-2.0, so whatever you build on Casama can use any licence.
One folder, `ee/`, holds
a few enterprise features under a separate licence. Casama builds and runs without it, and the
[licensing page](https://github.com/stackwares/casama/blob/main/LICENSING.md) says exactly what is
where.

## Why it matters for an AI agent

An agent acts for you. It reads your mail, signs in to your accounts and spends your money. That is
a lot to hand to software you can't inspect.

- **You can see what it does.** The rules that decide which actions ask first are code you can
  read, not a promise.
- **You choose the model.** Self-hosted bots use any provider, your own keys or a local model.
- **It can't be taken away.** If a vendor closes, changes its prices or leaves your country, a
  hosted agent goes with it. Your own copy keeps running, and your workspace exports in full.
- **Your data stays where you put it.** On your own server, chats, memory and files never leave
  your machine.

## What makes Casama different from other open-source agents

Most open-source agent projects are one of two things: a framework for developers to build agents
with, or a single assistant that runs in a terminal or a chat app on your own computer. Casama is a
finished product for people who don't write code, with a team of bots:

| | Casama |
|---|---|
| A computer per bot | Each bot gets its own sandboxed Linux machine, apart from your devices |
| Asking first | Rules per action; risky steps wait, and a checkpoint is saved before anything destructive |
| Real apps | Native apps on phone, tablet and desktop, with push notifications and live calls |
| Teams | Workspaces with roles, group chats with people and bots, shared spaces |
| Starting on its own | Schedules, webhooks, email, calendar events and check-ins |
| Hosted option | Casama Cloud, if you'd rather not run a server |

## Build on it

Everything the apps do goes through an open HTTP API. Plugins give bots new skills and tools from a
GitHub repository, and packs share whole bots with their routines. If you build with Claude Code,
Codex or Cursor, the [agent kit](https://docs.casama.ai/develop/agents) gives your coding agent
Casama's docs and API reference.

## Questions

### Is Casama free?

Self-hosting is free with no limit on users or bots. Casama Cloud has a free plan and paid plans
from $15 a month. See [pricing](/pricing).

### Can I use it at work?

Yes. AGPL-3.0 allows commercial use, including running it for your business and your customers.
If you change Casama and offer your version to others, share those changes under AGPL-3.0. If
that doesn't suit your company, a commercial licence is available from hello@casama.ai.

### How do I contribute?

Read the [contributing guide](https://github.com/stackwares/casama/blob/main/CONTRIBUTING.md).
Gallery items (skills, bots, routines) are the easiest place to start.

{{cta}}
