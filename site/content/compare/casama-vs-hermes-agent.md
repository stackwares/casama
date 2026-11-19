---
title: Casama vs Hermes Agent: which should you choose? (2026)
h1: Casama vs Hermes Agent: which should you choose?
card: Casama vs Hermes Agent
crumb: Casama vs Hermes Agent
description: Casama vs Hermes Agent, head to head: self-improving skills against a computer per bot, approvals, phone apps, teams and price. When to pick each. With sources.
lead: Pick Hermes Agent if you want one agent that writes and improves its own skills, with wide model choice and a say in where its commands run. Pick Casama if you want several bots that each have their own computer, approvals for every kind of risky action, phone apps, or a workspace for a team.
updated: 2026-11-18
order: 21
---

## The short answer

- **Hermes Agent** is one agent that gets better with use. It is free and MIT-licensed, runs on
  your own computer or server, and has Mac and Windows desktop apps and a terminal app. A hosted
  agent comes with paid Nous Portal plans.
- **Casama** is a team of bots, each with its own sandboxed Linux computer, memory you can read and
  edit, and approvals on by default. It has apps on phone, desktop and web, and a free hosted plan.
- We make Casama, so read the table and the sources and weigh our view accordingly.

## Side by side

{{compare: hermes-agent}}

Facts about Hermes Agent were checked on November 18, 2026. It is still before version 1.0 and
changes quickly, so check the sources at the end for anything that matters to you.

## Where Hermes Agent wins

{{best-at: hermes-agent}}

It also reaches more chat apps: more than 20, including Signal, against Casama's ten.

## Where Casama wins

- **A computer per bot, by default.** Hermes Agent runs commands on your machine unless you choose
  Docker, SSH or a cloud sandbox. A Casama bot starts on its own isolated machine.
- **Approvals by kind of action, not by pattern.** Hermes Agent asks about shell commands that
  match risky patterns, and its docs say scripts can get around pattern matching. Casama gives
  every tool a risk level. Under the default setting, high-risk actions such as sending email wait
  for you, and payments always ask.
- **Phone apps.** Casama has iPhone, iPad and Android apps, with approvals as push notifications.
  Hermes Agent has no phone app yet.
- **Teams.** Casama has workspaces with roles and group chats. Hermes Agent's pages don't describe
  separate user accounts.
- **Watching and undoing.** You can watch a bot's computer live and take over, and a checkpoint is
  saved before a command that deletes data.

## Where Casama is weaker

- It is new: first released in November 2026, with a small community. Hermes Agent has about
  264,000 GitHub stars.
- It has fewer chat apps.
- Casama bots can save and improve their own skills too, and suggest new ones for you to approve,
  but self-improvement is what Hermes Agent is built around. If that is the main thing you want,
  try it first.
- You choose your own model only when you self-host. On Casama Cloud, Casama picks.

## Three questions to decide

1. **One agent or several?** If you want a single agent that learns your work over time, look at
   Hermes Agent first. If you want one bot per job, each with its own limits and budget, look at
   Casama.
2. **How much do you want it to ask?** If asking about risky shell commands is enough, Hermes
   Agent does that. If you want sending, publishing and paying to wait for you too, Casama does
   that from the start.
3. **Where will you use it?** At a desk or in a terminal, either works. From your phone, or with
   colleagues, Casama fits better today.

## What moving costs

**From Hermes Agent to Casama.** Casama imports a Hermes Agent home folder: pick the folder in the
desktop app, or upload a ZIP of it. Its persona, memories, skills and scheduled jobs come over, and
you review each one first. Keys and settings files are never read. See
[Import an agent](https://docs.casama.ai/guide/sharing#import-an-agent). Reconnect chat apps, and check yours are
among Casama's ten. Self-hosting needs Docker. Casama Cloud needs nothing installed.

**From Casama to Hermes Agent.** Your workspace exports in full, and instructions are plain text.
You give up the per-bot computers, phone apps and workspace roles, and you choose and set up where
commands run.

Both are free to run yourself, so a side-by-side week costs only model usage.

## Questions

### Which has better model choice?

Hermes Agent, if you count the hosted option: it takes your own keys, Nous Portal, some
subscriptions and local models. Self-hosted Casama takes any provider, a ChatGPT plan or local
models, but Casama Cloud picks the model for you.

### Is either one free?

Both are free to self-host. Casama Cloud has a free plan. Nous Portal has a $0 tier and paid
plans.

### Which is safer?

Neither is safe without attention. The difference is the starting point: Hermes Agent runs on your
machine by default, and Casama bots run on their own machines with approvals on.

### Can I run both?

Yes. They don't conflict.

## Sources

{{sources: hermes-agent}}

More detail on the [Hermes Agent alternative page](/alternatives/hermes-agent), or see
[all comparisons](/compare/).

{{cta}}
