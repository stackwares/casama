---
title: AI scheduling assistant for your calendar and inbox
h1: An AI scheduling assistant for your calendar and inbox
card: Scheduling
crumb: Scheduling
description: A Casama bot finds times, drafts the replies, spots clashes and preps you before each meeting. It works from your calendar and mail.
lead: Scheduling is mostly reading mail and comparing calendars. A Casama bot does both, offers times, drafts the reply and keeps the week from colliding with itself.
updated: 2026-11-18
order: 7
---

## What the bot does

- **Finds times.** Reads the request, checks your calendar, proposes slots.
- **Drafts the reply.** With the slots in it, in your tone.
- **Spots clashes.** And suggests which meeting to move.
- **Preps you.** A short brief before each meeting.
- **Protects focus time.** If you tell it your rules.

## Where it stops to ask

- Sending the reply, under the default setting.
- Anything you mark "always ask" on the calendar connection.

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

1. An email arrives: "Can we meet next week?"
2. The bot checks your calendar and drafts: "Tuesday 10:00 or Thursday 14:30 both work."
3. You approve. When they pick Thursday, it adds the meeting.
4. Thursday 14:20: a brief arrives with the last thread and two open questions.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Connect your calendar and mail to one bot.
2. Tell it your rules: no meetings before 10, 30 minutes by default, lunch is sacred.
3. Add a routine that runs when a message arrives, or let check-ins handle it.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## Questions

### Does it change my calendar without asking?

Calendar changes don't ask by default; you can set them to. Sending email does ask by default.

### Does it work with Google and Microsoft calendars?

Calendars connect through Apps; the catalog lists what is available.

### Can it schedule for a team?

Yes, in a shared workspace with each person's calendar connected.

See [what else Casama bots do](/use-cases/).

{{cta}}
