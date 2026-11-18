---
title: AI personal assistant that does the task, not just the reply
h1: An AI personal assistant that does the task
card: Personal assistant
crumb: Personal assistant
description: A Casama bot books trips and tables, compares prices in its own browser, fills in forms and asks before paying. Free to start.
lead: Most AI assistants tell you how to do something. A Casama bot does it on a computer of its own, remembers how you like things, and asks before paying for anything.
updated: 2026-11-18
order: 1
---

## What the bot does

- **Books and reserves.** Tables, trips, tickets and appointments, in its own browser, on the real sites.
- **Compares.** Prices, options and reviews across several sites, returned as a short table with links.
- **Fills in forms.** Renewals, sign-ups and returns, with your details filled in from what it remembers.
- **Keeps track.** Reminders, renewals and a morning brief of what today needs.
- **Watches.** A price, a page or a delivery, and tells you when it changes.

## Where it stops to ask

- Paying for anything, always.
- Sending a message or an email in your name.
- Anything you marked "always ask".

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

1. You: "Find a table for four near the office on Friday at 7, Italian, not too loud."
2. The bot searches the booking sites, checks reviews for noise, and returns three options.
3. You: "The second one."
4. It fills in the booking and stops: "Reserve Trattoria Nove, Friday 19:00, 4 people. Approve?"
5. You approve from your phone's lock screen. It confirms and adds it to your calendar.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Assistant** persona (or **Travel**, for trips), or describe the bot you want in the welcome chat.
2. Connect your calendar and mail so it knows your day.
3. Tell it your preferences once: airline, seat, diet, budget. It saves them to memory, which you can read and edit.
4. Leave autonomy on **Ask for risky actions** until you trust it.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## Questions

### Can it use my accounts?

It works in its own browser. Logins from 1Password or Bitwarden are filled in for the sites you allow, and the AI model never sees them.

### What does it cost?

The Free plan includes $1 of credits a month. A typical booking task costs a few cents of model usage.

### Can I reach it without the app?

Yes: Telegram, WhatsApp, iMessage, SMS, email and other chat apps can be connected to a bot.

See [what else Casama bots do](/use-cases/), or compare the [best AI personal assistants](/compare/best-ai-personal-assistants).

{{cta}}
