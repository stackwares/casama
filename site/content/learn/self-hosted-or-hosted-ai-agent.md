---
title: Self-hosted or hosted AI agent: which should you choose?
h1: Self-hosted or hosted AI agent: which should you choose?
description: Host it yourself for control over data, models and cost. Use a hosted agent for no setup and no upkeep. A table of trade-offs and a way to decide.
lead: Host it yourself if you want your data on your own machine, any model you like, and no monthly fee. Use a hosted agent if you want to start in a minute and never think about servers. Some products let you do either, or both.
updated: 2026-11-18
order: 8
---

## The trade-offs

| | Self-hosted | Hosted |
|---|---|---|
| Setup | An hour or less, and a machine with Docker | Sign up |
| Upkeep | You update and back up | The vendor does |
| Where your data lives | Your machine | The vendor's servers |
| Models | Any provider, or local models | Whatever the vendor offers |
| What you pay | Your hardware, plus model providers directly | A subscription, often with usage on top |
| Limits | Your hardware | The plan's limits |
| If the vendor changes or closes | Your copy keeps running | You move |
| Reach from your phone | Needs a public address or a relay | Built in |
| Region locks | None | Sometimes |

## Choose self-hosted if

- Your email, files or customer data shouldn't sit on someone else's servers.
- You want a specific model, your own keys, or a local model so nothing leaves your network.
- You already run a home server or a VPS and Docker doesn't worry you.
- You want many users or many bots without paying per seat.
- You want to read, change or extend the software.

## Choose hosted if

- You want to try it today.
- Nobody on your team wants to look after a server.
- You'd rather pay a known monthly price than manage model keys and bills.
- You need it to be there when your own machine is off.

## The usual worries about self-hosting

**"I can't reach a home server from my phone."** That used to need a domain, port forwarding or a
VPN. A relay service can give your server a public address instead.

**"Bots need computers to work on, and that's heavy."** It is the heaviest part. Some products let
a self-hosted server borrow cloud computers for its bots and keep everything else at home.

**"I'll forget to update it."** Pick software with a one-command update, and put it in your
calendar.

**"Local models aren't good enough."** For long, tool-heavy tasks the best hosted models are still
ahead. Many people run a local model for private or simple work and a hosted one for the rest.

## You don't have to pick one

With Casama you can do either or mix them:

- **Self-hosted** is free: one command installs the whole stack with Docker on a VPS, a home
  server or a laptop, with no limit on users or bots. Use any provider, your ChatGPT plan or local
  models.
- **Casama Cloud** has a free plan and paid plans from $15 a month with credits included.
- **Casama Link** gives a self-hosted server an address your phone can reach, free, with no
  domain or port forwarding. It can also let Casama Cloud run the bot computers and model calls
  for your server, while your chats, memory and files stay with you.

The apps are the same either way, and a workspace exports in full, so you can change your mind.

## Related questions

- [How do I self-host an AI agent?](/learn/how-to-self-host-an-ai-agent)
- [Can AI agents run on my own models?](/learn/can-ai-agents-run-on-local-models)

{{cta}}
