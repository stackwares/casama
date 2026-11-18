---
title: Why every Casama bot gets its own computer
h1: Why every Casama bot gets its own computer
description: The design choice behind Casama: one sandboxed Linux computer per bot. What it costs, what it buys, and why sharing one machine wasn't enough.
lead: The first design decision in Casama was also the most expensive one: every bot gets a computer of its own. Here is what that costs, what it buys, and why we didn't take the cheaper routes.
updated: 2026-11-18
author: oliver
---

## The cheaper routes

There are three easier ways to give an AI agent somewhere to work.

**Use the person's own computer.** It is free and already signed in to everything. It also means
a model that misreads a page is one command away from your documents, and the work stops when the
lid closes.

**Use a browser session.** Light and quick to start. But a browser can't unzip a file, run a
script or keep a half-finished spreadsheet until tomorrow.

**Share one machine between all of a person's agents.** Cheaper than one each. But then the bot
that reads your mail and the bot that installs whatever a research task needs live in the same
place, with the same files and the same sign-ins.

## What one computer each buys

- **Containment.** A bot can reach only the sites and accounts you allow. A mistake stays on that
  bot's machine.
- **Continuity.** The checked-out repository, the downloaded statements and the signed-in session
  are there next time.
- **Real work.** A shell, a file system and a browser, and a full desktop when a task needs one.
- **Undo.** Before a command that deletes data, the computer is saved. Restoring puts the files
  back.
- **A window.** You can watch a bot's screen live and take over the mouse.

## What it costs, and how we pay for it

A computer that is always on is expensive. So computers sleep when a bot is idle and wake in
seconds with everything intact. On Casama Cloud, plans include a number of computer hours, and a
sleeping computer uses none. On your own server, the limit is your hardware.

The second cost is sign-ins: a new computer isn't logged in to anything. Bots get access through
the apps you connect, and logins from a password manager are filled in on the way out, for the
sites you allow, without the model seeing them.

The third is the odd website that distrusts cloud browsers. When that happens you can take over
for a moment, or lend the bot your own machine for that task, where high-risk actions always ask.

## Why not let people choose a shared machine?

Once idle computers sleep, sharing one machine saves little, and the risk is the kind you only
notice afterwards. So Casama has no setting for it.

## Where this goes

A computer per bot makes other things possible: teaching a bot by showing it a task on its
screen, bots that hand work to each other without sharing files by accident, and routines that run
at night on a machine that was asleep a minute earlier.

More on the idea: [why give an AI agent its own computer](/learn/why-give-an-ai-agent-its-own-computer).
