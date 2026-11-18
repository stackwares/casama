---
title: nanobot alternative: Casama vs nanobot (2026)
h1: nanobot alternative: how Casama compares
card: nanobot
crumb: nanobot
description: A nanobot alternative where each bot gets its own sandboxed computer and asks before risky steps. How Casama and HKUDS's nanobot differ, with sources.
lead: nanobot, from the University of Hong Kong's Data Intelligence Lab, is a lightweight, MIT-licensed personal agent in Python. It began as a much smaller take on OpenClaw, runs on the machine you install it on, and reaches more chat apps than almost anything else, including WeChat and Feishu. Casama is the alternative for people who want each bot on its own sandboxed computer, approvals on from the start, native apps and a hosted option.
updated: 2026-11-18
order: 16
---

## Casama and nanobot at a glance

{{compare: nanobot}}

Facts about nanobot come from its README, documentation and website, and were checked on November 18,
2026. The sources are at the end of this page.

## How they differ

nanobot is a small program you run on your own machine. Its file and shell tools work in a folder you
choose, with an optional sandbox, and in its config both the workspace limit and the sandbox start
off. Casama puts each bot on its own isolated Linux computer, so a mistake stays on that machine, and
risky tools wait for your approval.

nanobot is strongest on reach and simplicity: sixteen chat apps, any model with fallbacks, and code
small enough to read. Casama is broader around the agent: apps on every platform, team workspaces
with roles, budgets, a Library for everything bots make, and Casama Cloud if you don't want to run
anything.

## Choose nanobot if

{{best-at: nanobot}}

## Choose Casama if

- You want each bot on its own computer instead of the machine you installed it on.
- You want risky steps to wait for you without configuring a sandbox first.
- You want native apps on phones and desktops, with notifications.
- More than one person will use it, each with their own workspace and memory.
- You want a hosted version as well as self-hosting.

## Worth knowing about nanobot

{{limits: nanobot}}

## Moving from nanobot to Casama

Recreate your agent as a Casama bot and copy what matters from its memory files into the bot's
instructions and memories. Scheduled automations become routines. Self-hosted Casama accepts the
same model choices: provider keys, a ChatGPT plan or a local model. Casama connects to Feishu but
not to WeChat, QQ or DingTalk, so keep nanobot for those.

Start on [Casama Cloud's free plan](https://app.casama.ai), or
[run Casama on your own server](/self-hosted).

## Questions

### Is nanobot related to OpenClaw?

It started as an assistant inspired by Clawdbot, OpenClaw's earlier name, written to be far smaller,
and its bundled skills still follow OpenClaw's skill format.

### Is nanobot free?

Yes. It is free under the MIT licence; you pay your model provider or run a local model.

### Who makes nanobot?

HKUDS, the Data Intelligence Lab at the University of Hong Kong, with outside contributors.

### Can several people share one nanobot?

They can chat with it through allowed chat apps, but they share one memory and one admin. Its docs
suggest separate instances for separate people.

## Sources

{{sources: nanobot}}

See how Casama compares with [other AI agents](/alternatives/).

{{cta}}
