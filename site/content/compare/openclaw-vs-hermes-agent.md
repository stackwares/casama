---
title: OpenClaw vs Hermes Agent (2026): compared, with a third option
h1: OpenClaw vs Hermes Agent: which should you run?
card: OpenClaw vs Hermes Agent
crumb: OpenClaw vs Hermes Agent
description: OpenClaw vs Hermes Agent compared on licence, safety defaults, models, apps, chat channels and price, with Casama as a third option. Sources and dates.
lead: OpenClaw and Hermes Agent are the two most-starred open-source personal agents, and both are free and MIT-licensed. Pick OpenClaw for the most chat apps and phone apps. Pick Hermes Agent for an agent that writes its own skills. If you want each agent on its own sandboxed computer with approvals on by default, look at Casama as well.
updated: 2026-11-18
order: 1
---

## Side by side

{{compare: openclaw, hermes-agent}}

Checked on November 18, 2026. Both projects ship new versions most weeks, so check the sources at
the end for anything that matters to you.

## The short answer

- **OpenClaw** is about reach. It connects to about 29 chat apps and has native apps for Mac,
  Windows, Linux, iPhone and Android. It has no paid tier at all.
- **Hermes Agent** is about one agent getting better. It writes and refines its own skills, keeps
  searchable memory, and lets you choose where its commands run. It has no phone app yet. The
  optional Nous Portal sells models and a hosted agent.
- **Both** run on your own machine by default and leave it to you to switch on isolation. Both use
  your own model keys, some subscriptions, or local models.

## Safety defaults

This is the difference people overlook. Per each project's own documentation:

- OpenClaw runs tools directly on the host by default. Sandboxing is optional, and command
  approvals don't prompt until you configure them.
- Hermes Agent runs commands on your machine by default and asks for approval when a command
  matches a list of dangerous patterns. Its docs say pattern matching can be got around by scripts.

Neither is unsafe if you set it up with care. Both expect you to do that setup.

## Choose OpenClaw if

{{best-at: openclaw}}

## Choose Hermes Agent if

{{best-at: hermes-agent}}

## Where Casama fits

Casama is a third kind of open-source agent. Where these two are one agent on your computer, Casama
is a team of bots that each get their own sandboxed Linux machine, apart from your devices:

- Approvals are on from the start, for every kind of risky action, and payments always ask.
- A checkpoint is saved before destructive commands.
- There are native apps on phone and desktop, with push notifications.
- Workspaces, roles and group chats make it usable by more than one person.
- You can self-host it free, or use Casama Cloud, which has a free plan.

It has fewer chat apps than either (ten), and a far smaller community: it was first released in
November 2026.

## Worth knowing

**OpenClaw**

{{limits: openclaw}}

**Hermes Agent**

{{limits: hermes-agent}}

## Questions

### Which is easier to install?

Both install with one command and have desktop downloads. OpenClaw also has phone apps.

### Which has more users?

OpenClaw, by GitHub stars: about 395,000 against about 264,000 for Hermes Agent on the day we
checked.

### Can I run both?

Yes. They don't conflict, and some people run Hermes Agent for coding and OpenClaw for chat apps.

### Are they free?

Both are free and MIT-licensed. You pay your model provider. Hermes Agent's optional Nous Portal
has paid plans.

## Sources

{{sources: openclaw, hermes-agent}}

More: [OpenClaw alternatives](/alternatives/openclaw) and
[Hermes Agent alternatives](/alternatives/hermes-agent).

{{cta}}
