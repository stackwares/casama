---
title: Your own AI server, reachable from your phone
h1: Your own AI server, reachable from your phone
description: How Casama Link gives a self-hosted Casama server an address your phone can reach, with store apps and push notifications, and what passes through Casama.
lead: Self-hosting usually ends at your front door. The server runs, and then you leave the house and it might as well not exist. Casama Link is how a server on your laptop becomes an app on your phone.
updated: 2026-11-18
author: oliver
---

## The problem

Two things stop a home server from feeling like an app.

The first is the address. A machine behind a home router can't be reached from a phone on a mobile
network without a domain and port forwarding, or a VPN on every device.

The second is notifications. A phone app gets push notifications only through Apple's and
Google's services, tied to the app in the store. A server you run yourself has no way in.

## What Casama Link does

**An address.** Your server gets its own `casama.link` address over HTTPS. There is nothing to
configure on the router and no domain to buy.

**Sign-in by scanning.** The desktop app shows a QR code. Scan it with the Casama app from the
App Store or Google Play and you're signed in to your own server.

**Notifications.** When a bot needs an approval or finishes a task, the notification reaches the
store app on your phone.

## What passes through us, and what doesn't

Your bots, chats, memory and files stay on your server. Casama Cloud keeps a record of the linked
server: its name, its address and when it last checked in. It passes notifications along.

Each linked server holds one key, and what the key may do depends on how it was made. A key made
by linking can hold an address and send notifications. It can't spend credits.

## What it costs

Remote access is free on every plan, for any self-hosted server. Watching a bot's computer live
while you're away from home comes with Plus and up.

## Turning it on

From the desktop app: **Settings → Casama Link → Use on Your Phone**.

From a terminal:

```
casama selfhost remote on
```

If your server already has its own domain and you only want notifications in the store apps:

```
casama selfhost remote link
```

## The optional second half

Bot computers are the heaviest part of running Casama yourself. If your machine is small, or runs
on a platform without Docker, Casama Link can also let Casama Cloud run the bots' computers and
model calls for your server. That part is billed to a cloud workspace. Everything else stays at
home.

## Why we built it this way

The alternative was to tell self-hosters to bring a domain and a reverse proxy, and accept that
most people would never use their server from a phone. An agent you can't reach when it needs an
approval isn't much use.

Steps and details: [use your server on your phone](https://docs.casama.ai/self-hosting/remote-access).
Background: [self-hosted or hosted](/learn/self-hosted-or-hosted-ai-agent).
