---
title: Best open-source AI agents in 2026: nine compared
h1: Best open-source AI agents in 2026
card: Best open-source AI agents
crumb: Best open-source AI agents
description: Nine open-source AI agents you can run yourself, compared on licence, safety, models, apps and price: OpenClaw, Hermes Agent, nanobot, NanoClaw, Agent Zero and more.
lead: There are two kinds of open-source AI agent. Frameworks are kits for developers to build agents with. This page is about the other kind, finished agents you install and talk to. The best one for you depends on where you want it to work, your own machine or a computer of its own, and on how much setup you want to do for safety.
updated: 2026-11-18
order: 0
---

## The short list

| | Best for | Stars |
|---|---|---|
| **OpenClaw** | The most chat apps, the biggest community, no paid tier at all | about 395,000 |
| **Hermes Agent** | One agent that writes its own skills and improves with use | about 264,000 |
| **nanobot** | A small Python agent in the most chat apps, including WeChat and Feishu | about 50,000 |
| **NanoClaw** | A small codebase with every session in its own container | about 31,000 |
| **MausBot** | Reusing the AI subscriptions you already pay for, on your desktop | about 24,700 |
| **Agent Zero** | A full Linux desktop for the agent, free and fully hackable | about 19,900 |
| **OpenBot** | Rolling AI coworkers out across a company with admin controls | about 12,700 |
| **Rakazo** | A computer per bot, self-hosted or hosted, with no markup on models | about 9,000 |
| **Casama** | A computer per bot with approvals on by default, native apps and a free hosted plan | new |

Star counts are from GitHub on November 18, 2026. We make Casama, so weigh our place on this list
accordingly; the other eight each have their sources at the end of the page.

## Side by side

{{compare: openclaw, hermes-agent, nanobot, nanoclaw, mausbot, agent-zero, openbot, rakazo}}

## How to choose

**Where should the agent work?**

- *On my own computer.* OpenClaw, Hermes Agent, nanobot and MausBot run there by default. It is the quickest
  to set up, and the agent can reach your files and sign-ins. Turn on a sandbox if the project has
  one.
- *On a computer of its own.* Rakazo and Casama give every bot its own isolated machine by default.
  Agent Zero works in a container with its own Linux desktop, NanoClaw runs each session in a
  container, and OpenBot gives each person a container. The agent keeps working when your laptop is closed, and a
  mistake stays on its machine.

**How much do you want it to ask?**

Approvals differ more than anything else in this list. OpenClaw's are off until you configure them.
Hermes Agent asks about shell commands that match risky patterns. Agent Zero allows every tool
until you block it, nanobot has no ask step, and NanoClaw asks before installs and new tools but
not shell commands. MausBot's own site says not every
action is guaranteed to pause. OpenBot uses admin policies. Rakazo has an ask mode and an automatic
mode. Casama asks before risky actions by default, and payments always ask.

**Is it only for you?**

For a team, look at OpenBot (roles, single sign-on, audit export), Rakazo (organizations and
spaces), MausBot's paid Team plan, or Casama (workspaces with roles and group chats). OpenClaw and
Hermes Agent are built for one person or a group that trusts each other, and so are nanobot,
NanoClaw and Agent Zero.

**Do you want someone else to host it?**

Rakazo, MausBot and Casama have hosted plans at $15, $49 and $99 a month. Casama also has a free
hosted plan. Hermes Agent has an optional hosted agent through Nous Portal. OpenClaw, nanobot and Agent Zero are self-hosted only, and NanoClaw's hosted
version is invite-only.

## The nine, one by one

### OpenClaw

{{best-at: openclaw}}

Worth knowing:

{{limits: openclaw}}

### Hermes Agent

{{best-at: hermes-agent}}

Worth knowing:

{{limits: hermes-agent}}

### nanobot

{{best-at: nanobot}}

Worth knowing:

{{limits: nanobot}}

### NanoClaw

{{best-at: nanoclaw}}

Worth knowing:

{{limits: nanoclaw}}

### MausBot

{{best-at: mausbot}}

Worth knowing:

{{limits: mausbot}}

### Agent Zero

{{best-at: agent-zero}}

Worth knowing:

{{limits: agent-zero}}

### OpenBot

{{best-at: openbot}}

Worth knowing:

{{limits: openbot}}

### Rakazo

{{best-at: rakazo}}

Worth knowing:

{{limits: rakazo}}

### Casama

- You want each bot on its own sandboxed Linux computer that you can watch and take over.
- You want risky steps to wait for you from the start, with a checkpoint saved before destructive
  commands.
- You want native apps on iPhone, iPad, Android, Mac, Windows and Linux, and ten chat apps.
- You want a free hosted plan, or to self-host with any model.

Worth knowing:

- It is the newest here: first released in November 2026, with a small community.
- It has fewer chat apps than OpenClaw, Hermes Agent or nanobot.
- Choosing your own model is for self-hosted servers. On Casama Cloud, Casama picks.

## What about frameworks?

LangGraph, CrewAI, AutoGen and similar projects are for building your own agent in code. They are
a different choice: pick one if you are a developer with a specific product to build, and one of the
nine above if you want an agent to use this week.

## Questions

### Which open-source AI agent is the safest?

The one whose defaults match how careful you'll be. If you won't configure a sandbox and approvals
yourself, choose one where they are on from the start.

### Are these really free?

The software is. You pay for the AI model you use, unless you run a local model, and for your own
hardware. Hosted plans cost money.

### Can they run on local models?

All nine can use a local model, though NanoClaw's docs call its Ollama route a legacy workflow. Long, tool-heavy tasks
still go better on the strongest hosted models.

### Which is easiest to install?

OpenClaw, Hermes Agent, nanobot and MausBot install on a desktop with one command or a download.
Agent Zero has a desktop launcher that runs Docker for you. NanoClaw, Rakazo and Casama need
Docker, and Casama's Mac and Linux app can set it up for you.

## Sources

{{sources: openclaw, hermes-agent, nanobot, nanoclaw, mausbot, agent-zero, openbot, rakazo}}

One at a time: [OpenClaw](/alternatives/openclaw), [Hermes Agent](/alternatives/hermes-agent),
[Rakazo](/alternatives/rakazo), [OpenBot](/alternatives/openbot),
[MausBot](/alternatives/mausbot), [Agent Zero](/alternatives/agent-zero),
[NanoClaw](/alternatives/nanoclaw) and [nanobot](/alternatives/nanobot).

{{cta}}
