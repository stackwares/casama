---
title: AI research assistant that cites every source
h1: An AI research assistant that cites every source
card: Research
crumb: Research
description: A Casama bot reads the web and your own files on its own computer, and returns a brief or a table with every source cited. It can run every morning.
lead: Research is many small steps: search, open, read, compare, write. A Casama bot does them on its own computer and hands you a brief with every claim tied to a source.
updated: 2026-11-18
order: 5
---

## What the bot does

- **Reads widely.** Web pages, PDFs and your own Drive or Notion files.
- **Compares.** Builds a table across sources: prices, features, dates, positions.
- **Cites.** Each finding carries the page or file and the place in it.
- **Repeats.** A daily or weekly brief on the topics you follow.
- **Watches a page.** And tells you when it changes.

## Where it stops to ask

- Paid data lookups, which show their price first.
- Sending the result to anyone but you.

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

1. You: "Compare the five biggest e-bike subscriptions in Germany: price, minimum term, theft cover."
2. The bot opens each provider's site, reads the terms, and builds the table.
3. It notes two it couldn't verify and says why.
4. You: "Check this every Monday and tell me what changed." It becomes a routine.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Researcher** persona, which brings a research-report skill.
2. Connect the document stores it should read.
3. Tell it how you like results: length, format, how to cite.
4. Add a routine for anything you want regularly.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## Questions

### Does it make things up?

Any AI model can. Sources on every claim let you check, and the run timeline shows which pages it opened.

### Can it read files I upload?

Yes, and knowledge you add stays available to that bot.

### What does a long research task cost?

It depends on how many steps it takes. Each bot has a per-run budget, $1 by default, and stops there.

See [what else Casama bots do](/use-cases/).

{{cta}}
