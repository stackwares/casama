---
title: Self-hosted AI agents: run Casama on your own server
h1: Self-hosted AI agents, on a server you own
crumb: Self-hosted
description: Run Casama's AI agents on your own VPS, home server or laptop with one command. Free, open source, any model, and reachable from your phone.
lead: Casama runs on your own hardware with one command. Your chats, memory and files stay on your machine, you choose the models, and it costs nothing.
updated: 2026-11-18
---

## What you get

A self-hosted Casama is the full product, not a cut-down edition:

- **Bots with their own computers.** Each bot works on a sandboxed Linux machine with a shell,
  files and a browser. You can watch it live and take over.
- **Any model.** Bring keys for Anthropic, OpenAI, Google Gemini, xAI or OpenRouter, sign in with
  your ChatGPT plan, or point a bot at a local model in Ollama, LM Studio or vLLM. Local models
  are recorded at $0.
- **Approvals.** Risky steps wait for your OK. You set the rules per bot and per action.
- **Routines.** Bots start on a schedule, on a webhook, on an email or a calendar event.
- **Apps everywhere.** The same apps for iPhone, iPad, Android, Mac, Windows, Linux and the web
  sign in to your server.
- **No limits.** As many users, bots and computers as your hardware can carry.

## Install it

You need a machine with Docker. To try it on your own computer:

```
git clone https://github.com/stackwares/casama && cd casama
./install.sh --local
```

For a server other people reach over the internet, point a domain at the machine first:

```
./install.sh --domain casama.example.com
```

The installer checks Docker, creates every secret, starts the stack and waits until it is healthy.
With Docker already installed it takes about 15 minutes, most of it building images. The
[quick start](https://docs.casama.ai/quick-start) walks through signing in and your first bot.

Prefer no terminal? The desktop app for Mac and Linux can run a server on the computer it is
installed on: choose **Run Casama on This Computer** on the sign-in screen.

## Use it from your phone

A server on a laptop or a home network normally can't be reached from outside. Casama Link fixes
that for free: your server gets its own `casama.link` address, with no domain, port forwarding or
VPN to set up. Scan a code with the Casama app to sign in, and notifications reach your phone like
any other app's. Your chats, memory and files stay on your server.

## Self-hosted or Casama Cloud?

| | Self-hosted | Casama Cloud |
|---|---|---|
| Price | Free | Free, then $15, $49 or $99 a month |
| Where your data lives | Your machine | Casama's servers |
| Models | Any provider, your ChatGPT plan, or local models | Casama picks and runs them |
| Model costs | You pay providers directly; local models are free | Paid from credits |
| Setup | One command and Docker | Sign in |
| Upkeep | You update and back up | Casama does |

You can also mix them: keep your server and let Casama Cloud run the bot computers and model calls
for it.

## Questions

### What hardware does it need?

One machine with Docker runs everything: the database, the API, the worker and the bots' computers.
The docs list the [requirements](https://docs.casama.ai/self-hosting/) and production advice.

### Is anything held back from the open-source edition?

The app is open source under AGPL-3.0. A separate `ee/` folder holds a few enterprise features under their own
licence; Casama builds and works without it.

### Can I run it with only local models?

Yes. Point a bot at an OpenAI-style endpoint such as Ollama. Nothing has to leave your network.

{{cta}}
