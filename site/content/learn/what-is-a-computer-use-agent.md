---
title: What is a computer use agent, and which let you take over?
h1: What is a computer use agent, and which ones let you take over?
description: A computer use agent works a computer like you do: screen, mouse, keyboard, browser. Where it runs, why it matters, and which agents let you take over.
lead: A computer use agent is an AI agent that operates a computer the way a person does. It looks at the screen, clicks, types, opens a browser and runs programs, instead of only calling apps through their APIs. That lets it use any website or app, including ones with no integration. The big questions are whose computer it uses, and whether you can watch it and take over.
updated: 2026-11-18
order: 20
---

## How it works

The agent runs in a loop. It takes a screenshot or reads the page, asks an AI model what to do
next, then clicks, types or runs a command. It checks the result and goes again until the task is
done or it needs you. See [how AI agents work](/learn/how-do-ai-agents-work).

Many agents mix the two styles: an API when an app has one, and the screen when it doesn't, such
as a supplier's web form or an old booking site.

## Whose computer?

| Where it works | Upside | Downside |
|---|---|---|
| **Your own computer** | Your files and sign-ins are already there | It can reach everything you can, and it stops when you shut the lid |
| **A computer of its own** | A mistake stays on that machine, and it keeps working when you're away | You sign in to sites for it, once |

The first is quicker to set up. The second is safer to leave running. See
[why give an AI agent its own computer](/learn/why-give-an-ai-agent-its-own-computer).

## Which agents let you watch and take over

| Agent | Its computer | Watch or take over |
|---|---|---|
| **Casama** | Each bot has its own sandboxed Linux computer | Watch live and take over |
| **Meta Muse** | One cloud computer per person | Watch and take over |
| **ChatGPT Dots** | Each dot has its own cloud computer | You can open it |
| **Claude Cowork and Duet** | Cowork: cloud sessions. Duet: its own cloud computer | Cowork you can watch; Duet you can't watch or take over |
| **Hark Pro** | Its own cloud browser per person | You can watch it |
| **Agent Zero** | A Docker container with its own Linux desktop, terminal and browser | A desktop you can watch |
| **Manus** | A cloud sandbox with a browser, per person | Not covered in the sources we checked |
| **Grok Bot** | One cloud computer per person, shared by all of that person's Bots | Not covered in the sources we checked |
| **Rakazo** | Each bot has its own container or cloud computer | Not covered in the sources we checked |
| **OpenClaw, Hermes Agent, nanobot** | Your machine by default | It's your own screen |

Checked on November 18, 2026; the sources are at the end. We make Casama.

## Why taking over matters

- **Sign-ins.** A site asks for a password or a two-step code. You type it yourself, and the agent
  carries on.
- **Stuck steps.** A pop-up or an odd layout confuses it. You click past it in seconds.
- **Trust.** Watching an agent work for a week is how most people decide what to let it do alone.

An agent you can only read about after the fact is harder to correct and harder to trust.

## Computer use in Casama

Each bot has its own sandboxed Linux computer with a shell, files and a browser that stays signed
in. A desktop computer adds a real screen you can watch live in the Casama app and control at any
time. When a site needs you, the bot asks you to take over: you sign in yourself in the live view,
and nothing you type reaches the bot.

The bot can't reach your devices or files you didn't share. Before a command that deletes data, a
checkpoint of its computer is saved. You can also lend a bot your own machine when it needs
something only you have. See the [computers guide](https://docs.casama.ai/guide/computers).

## Questions

### Is a computer use agent the same as browser automation?

No. Browser automation follows a script you wrote. A computer use agent decides each step itself,
so it copes with pages it hasn't seen, and it can make mistakes a script wouldn't.

### Is it safe to let an AI agent use a computer?

Safer on a computer of its own, with approvals before risky steps and a way to undo. See
[which AI agents ask before they act](/learn/which-ai-agents-ask-before-they-act).

### Can a computer use agent work while I'm away?

Yes, if its computer is in the cloud or on an always-on server. An agent on your laptop stops when
the laptop sleeps.

## Related questions

- [Why give an AI agent its own computer?](/learn/why-give-an-ai-agent-its-own-computer)
- [What is an AI agent?](/learn/what-is-an-ai-agent)

## Sources

{{sources: meta-muse, chatgpt-agent, claude-cowork, hark, agent-zero, manus, grok-bot, rakazo, openclaw, hermes-agent, nanobot}}

{{cta}}
