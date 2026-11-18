---
title: Run AI agents on your own server and use them from your phone
h1: How do I run AI agents on my own server from my phone?
description: Run the agent software on a computer at home, give it an address your phone can reach without port forwarding, and sign in with a native app.
lead: Run the agent software on a computer you own, give that computer an address your phone can reach, and sign in from a phone app. The hard part used to be the address. A relay now does it with no domain, port forwarding or VPN.
updated: 2026-11-18
order: 11
---

## Why it's awkward

A server on your laptop or in a cupboard at home sits behind your router. Your phone, out on a
mobile network, can't reach it. The usual fixes all have a catch:

| Way | Catch |
|---|---|
| Port forwarding and a domain | You open your home network to the internet and manage certificates |
| A VPN to your home network | Every phone needs a VPN app that is switched on |
| A VPS instead of a home server | Monthly cost, and your data is no longer at home |
| A tunnel service | Extra setup, and another company in the path |

And reaching the server is only half of it. A real phone app also needs push notifications, which
only work through Apple's and Google's services, tied to the app in the store.

## What you need for it to feel like a normal app

1. **An address** that works from any network, over HTTPS.
2. **A native app** on the phone that can sign in to your server, not only a web page.
3. **Notifications** that arrive when a bot needs you or finishes.
4. **An easy sign-in**, since typing a long address and a password on a phone is no fun.
5. **Your data staying home.** Traffic should pass through to your machine, not be stored along
   the way.

## How Casama does it

Casama is an open-source AI agent app you can run on your own computer for free. Its relay is
called Casama Link.

1. **Run the server.** One command with Docker, or choose **Run Casama on This Computer** in the
   Mac or Linux app.
2. **Turn on Casama Link.** Choose **Use on Your Phone** in the desktop app's settings, or run
   `casama selfhost remote on`. Your server gets its own `casama.link` address. Nothing to set up
   on your router.
3. **Scan the code.** Open the Casama app from the App Store or Google Play and scan the QR code
   on your computer's screen. You're signed in.
4. **Get notifications.** Approvals and finished tasks reach your phone like any other app's.

Your bots, chats, memory and files stay on your server. Casama's side keeps a record of the linked
server (its name, its address and when it last checked in) and passes notifications along.

## What it costs

Remote access through Casama Link is free on every plan, including for self-hosted servers.
Watching a bot's computer live while you're away from home comes with Plus and up.

## Good to know

- **The computer must be on.** A laptop that sleeps takes your bots with it. A small always-on
  machine, or a VPS, avoids that.
- **Bot computers are the heavy part.** If your machine is small, Casama Link can also let Casama
  Cloud run the bots' computers while everything else stays on your server.
- **You can use your own domain instead.** Casama Link is optional. With your own domain you can
  still link the server so notifications reach the store apps.

The [remote access guide](https://docs.casama.ai/self-hosting/remote-access) has every step.

## Related questions

- [How do I self-host an AI agent?](/learn/how-to-self-host-an-ai-agent)
- [Self-hosted or hosted AI agent: which should I choose?](/learn/self-hosted-or-hosted-ai-agent)
- [Which AI agents have iPhone and Android apps?](/learn/which-ai-agents-have-iphone-and-android-apps)

{{cta}}
