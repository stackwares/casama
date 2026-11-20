---
title: How approvals work in Casama, and what never asks
h1: How approvals work in Casama, and what never asks
description: The rules for when a Casama bot must ask first: risk levels, three autonomy settings, payments that always ask, and what changes after a bot reads a web page.
lead: An approval system fails in two ways. Ask too often and people stop reading. Ask too rarely and the first mistake is the last time anyone trusts the bot. These are the rules we settled on.
updated: 2026-11-18
author: oliver
---

## Risk belongs to the action

Every tool a bot can use has a risk level: low, medium or high. Some tools work theirs out from
what they are asked to do. A shell command inside the bot's own workspace folder is low risk. The
same command deleting things outside it is high.

For apps you connect, you set the level per tool: read-only, makes changes, or always asks.

## Three settings

| Setting | The bot asks before |
|---|---|
| Ask before acting | Every action that changes something |
| Ask for risky actions | Sending email or chat messages, calling people, making a page public, deleting outside its workspace, paid data lookups, and tools marked "always asks" |
| Act on its own | Nothing, except high-risk actions on your own computer |

New bots start on the middle one. Under it a bot does most work without asking, which is the
point: an approval should mean something.

## What always asks

- **Paying with a card.** Whatever the setting. "Always allow" doesn't apply.
- **High-risk actions on your own computer.** A bot's sandbox can be restored. Your laptop can't.
- **Changing a password or two-step settings.** These are handed to you to finish.

## What never asks

A bot's notes to itself, its own routines, messages to you, tickets and checkpoints never ask.
They change only the bot's own state inside Casama, where you can see and undo them. Asking about
those would train you to tap Approve without reading.

## After a bot reads something from outside

Web pages, emails and files can contain text written to trick a bot. So the rules tighten during a
run: once a bot has read outside content, actions that send data out of Casama ask first, even
ones that normally wouldn't. That lasts until you approve something. A line in an email can't
quietly become a web request.

One more: after reading outside content, creating or changing a routine asks first. Otherwise a
web page could schedule work for later, when nobody is watching.

## What an approval looks like

A card in the chat, a "Needs you" count at the top of the app, a push notification, and buttons in
Slack. It shows the bot, the tool, its risk and exactly what it wants to do, with secrets removed.
You can approve, deny, or always allow that tool for that bot.

Deny fails only that step. The bot is told and carries on without it. No answer for 24 hours
counts as a deny. A waiting run costs nothing and survives a server restart.

## The safety net under it

Approvals depend on a person reading. So before a command that deletes data, Casama saves a
checkpoint of the bot's computer anyway. If you approve the wrong thing, you can put it back.

The full rules are in the [autonomy guide](https://docs.casama.ai/guide/autonomy), and the code
that applies them is in the [repository](https://github.com/stackwares/casama).
