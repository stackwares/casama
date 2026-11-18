---
title: Which AI agents don't train on your data?
h1: Which AI agents don't train on your data?
description: Which AI agents say they don't train on your data, which train by default until you opt out, and which don't say. Seventeen agents checked, with sources.
lead: Casama, Hark Pro, Lindy and n8n say they don't use your data to train AI models, and Manus says so for team plans. Instinct, Meta Muse and Claude's consumer plans train by default until you switch it off. Self-hosted agents have no cloud of their own, so your model provider's policy applies. Several products don't say either way.
updated: 2026-11-18
order: 18
---

## The list

| Agent | Training on your data |
|---|---|
| **Casama** | Not used to train models |
| **Hark Pro** | Says it doesn't train on your data |
| **Lindy** | No, says Lindy |
| **n8n** | Says assistant data isn't used to train AI providers' models |
| **Manus** | Team plans say no; individual plans are unclear |
| **Grok Bot** | A training opt-out exists |
| **Instinct** | On by default; you can opt out |
| **Meta Muse** | On by default; you can turn it off |
| **Claude Cowork and Duet** | On for consumer plans unless you switch it off |
| **OpenClaw** | There is no OpenClaw cloud; your model provider's policy applies |
| **Hermes Agent** | With your own keys only your provider sees your data; Nous Portal may train on prompts unless Privacy Mode is on |
| **NanoClaw** | Not stated; self-hosted data stays on your machine |
| **Agent Zero** | Not stated; it runs on your machine and sends prompts to the model you choose |
| **nanobot** | Not stated |
| **Rakazo** | Not stated either way |
| **MausBot** | Not stated |
| **OpenBot** | Not stated for OpenBot |

Checked on November 18, 2026, from each product's privacy pages and terms; the sources are at the
end. We didn't find a statement for ChatGPT Dots. We make Casama.

## Two layers to check

An agent usually has two companies behind it: the one that makes the agent, and the one that runs
the AI model. Both see your requests.

1. **The agent maker.** Do they use your chats, files and memories to train anything? Is that on
   by default? Is the answer the same on free and paid plans?
2. **The model provider.** When the agent sends a step to a model, that provider's terms apply.
   With your own API key you choose the provider and can read its terms. With a hosted agent, ask
   which providers it uses.

A local model removes the second layer: nothing leaves your machine.

## Training isn't the only question

A product can promise no training and still keep your data longer than you'd like. Also check:

- **Who can see it.** Meta says it can technically access a Muse agent's computer today; its
  stronger private mode hasn't shipped.
- **Where it is stored.** Lindy's privacy notice doesn't say which region holds your data.
- **Whether you can export and delete it**, and how long deleted data lingers.
- **What the agent can reach.** An agent that works on your own computer can read whatever you can.

## Your data in Casama

- Your chats, memories and files are used to run Casama for you and for nothing else. They are not
  used to train AI models, sold, or used for ads.
- You can export everything, delete your account, set how long run history is kept, and turn on
  encryption for a workspace's content.
- Secrets never reach the AI model: a bot uses a placeholder, and the real value is filled in only
  for the site it's allowed for.
- On Casama Cloud, requests go to the AI models Casama runs your bots on. If you want nothing to
  leave your own machine, [self-host Casama](/self-hosted) with a local model through Ollama.

See [how Casama keeps your data safe](/security).

## Questions

### What is the most private AI assistant?

One you run yourself on a local model: nothing leaves your machine. Among hosted ones, start with
those that say they don't train on your data, then check who can access it and where it is stored.

### Does a training opt-out cover what I already sent?

It depends on the product. Its terms should say whether switching training off covers what you
already sent or only new conversations. If they don't say, ask before you rely on it.

### Do open-source AI agents train on my data?

The agent software itself usually has no cloud to send data to. Your model provider's terms decide
what happens to your prompts, unless you use a local model.

## Related questions

- [Is it safe to give an AI agent access to my email and accounts?](/learn/is-it-safe-to-give-an-ai-agent-access-to-my-email)
- [Self-hosted or hosted AI agent: which should I choose?](/learn/self-hosted-or-hosted-ai-agent)

## Sources

{{sources: hark, lindy, n8n, manus, grok-bot, instinct, meta-muse, claude-cowork, openclaw, hermes-agent, nanoclaw, agent-zero, nanobot, rakazo, mausbot, openbot}}

{{cta}}
