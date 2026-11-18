---
title: AI sales assistant for lead research and outreach drafts
h1: An AI sales assistant that researches first and never sends for you
card: Sales
crumb: Sales
description: A Casama bot researches leads, builds prospect lists with sources, and drafts outreach and follow-ups. It hands the drafts to you and never sends them itself.
lead: Good outreach starts with reading, and reading takes time. A Casama bot looks up each lead, cites what it found and drafts a short, specific message. You decide what gets sent.
updated: 2026-11-18
order: 9
---

## What the bot does

- **Researches a lead.** What the company does, recent news, likely priorities and the person's
  role, with links.
- **Builds a prospect list.** Companies that look like your best customers, each with the signal
  that makes them a fit and where it was found.
- **Drafts outreach.** A short first message that refers to something specific, plus follow-ups.
- **Keeps a pipeline.** A simple file on its computer: company, person, stage, next step, date.
- **Remembers.** Your ideal customer, your tone and what you corrected last time.

## Where it stops to ask

- Sending anything. The Sales and Outbound prospector personas are told never to send messages
  themselves, and sending email or chat messages asks for approval under the default setting
  anyway.
- Paid data lookups, such as finding an email address. The approval shows the price first.
- Changes in a connected app that you marked "always asks".

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

An example, with made-up companies:

1. You: "Find 20 companies like our best customer, a 40-person logistics firm in the Netherlands."
2. The bot asks two questions about size and the role to contact, then searches public sources on
   its own computer.
3. It returns a list of 20 with a source link and a fit score for each, and says which three it
   is least sure about.
4. You pick five. It drafts a first message under 100 words for each, and one follow-up.
5. You edit two lines and send them yourself, or approve the bot's request to send.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Sales** persona for researching named leads, or **Outbound prospector**
   for building lists. Edit the instructions to describe your ideal customer.
2. Connect your CRM and mail under Apps, if you want the bot to read them. HubSpot and Zoho CRM
   are in the catalog. Mark each tool read-only, makes changes, or always asks.
3. Start with research and drafts only. Read them for a week and correct what is off.
4. Add a routine, such as "every Monday at 9:00, list the leads that went quiet and draft a
   follow-up for each".

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## What it won't do for you

- It can be wrong about a company. Check the links before you repeat a claim to a prospect.
- It doesn't replace the conversation. It prepares it.
- The Outbound prospector persona is told to respect opt-outs and local rules on cold outreach,
  and not to collect personal emails from behind logins. The rules where you sell are still yours
  to know.

## Questions

### Will it email prospects on its own?

Not unless you change that on purpose. The personas hand drafts to you, and sending asks for
approval by default.

### Does it work with my CRM?

HubSpot and Zoho CRM are in the app catalog. Other tools connect through connector services or an
MCP server, where one exists.

### Where does the lead data come from?

Public web pages the bot reads on its own computer, apps you connected, and paid data lookups you
approved. It lists its sources.

### Can a team share it?

Yes, in a shared workspace. See [AI agents for small business](/use-cases/ai-agents-for-small-business).

See [what else Casama bots do](/use-cases/).

{{cta}}
