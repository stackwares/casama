---
title: Which AI agents let you choose the model or use your own key?
h1: Which AI agents let you choose the model or use your own API keys?
description: Open-source AI agents usually take your own API keys, subscriptions and local models; hosted ones usually pick for you. Seventeen agents checked, with sources.
lead: Almost every open-source AI agent lets you choose the model: your own API key, a subscription you already pay for, or a local model. Almost every hosted one picks the model for you. Casama does both: on your own server you choose any provider or a local model, and on Casama Cloud, Casama picks.
updated: 2026-11-18
order: 16
---

## Three ways to bring a model

1. **Your own API key.** You pay the provider, such as Anthropic, OpenAI or Google, for what you
   use, with nothing added in between.
2. **A subscription you already have.** Some agents sign in with a ChatGPT, Claude or other plan,
   so there is no new bill, within that plan's limits.
3. **A local model.** Run one with Ollama or a similar tool on your own hardware. Nothing is billed
   and nothing leaves the machine, but local models are weaker on long tasks.

## The list

| Agent | Choice of model |
|---|---|
| **Casama** | Self-hosted: any provider, a ChatGPT plan, or local models. Cloud: Casama picks |
| **OpenClaw** | Your own keys, a ChatGPT or Claude plan, or local models |
| **Hermes Agent** | Your own keys, Nous Portal, some subscriptions, or local models |
| **Rakazo** | Your own keys, a ChatGPT plan, local models, or Rakazo credits at the provider's price |
| **Agent Zero** | Your own keys, a ChatGPT sign-in, or local models through Ollama or LM Studio |
| **nanobot** | Your own keys, Codex, Copilot or Grok sign-in, or local models; fallbacks supported |
| **NanoClaw** | Claude by default, with a key or subscription; Codex, Cursor and OpenCode as options |
| **MausBot** | None included: it drives AI tools you're already signed in to, or API keys |
| **OpenBot** | Your own keys or subscriptions, or any OpenAI-style endpoint |
| **n8n** | Many providers with your own keys, or local models through Ollama |
| **Lindy** | Lindy picks per task; you can choose per task |
| **Claude Cowork and Duet** | Claude models only |
| **ChatGPT Dots** | OpenAI's model; no choice |
| **Manus** | Manus picks; no choice on standard plans |
| **Grok Bot** | No choice, and you aren't shown which model ran |
| **Meta Muse** | Meta's Muse Spark model only |
| **Hark Pro** | Hark chooses; no choice |

Checked on November 18, 2026, from each product's own pages; the sources are at the end. Instinct
doesn't say which model it uses. We make Casama.

## Why it matters

- **Cost.** With your own key you pay the provider's price and can send easy work to a cheaper
  model. With a subscription, an agent can be no extra cost at all.
- **Quality.** The best model for writing code isn't always the best for reading a long contract.
  Choosing lets you match the model to the job.
- **Privacy.** With your own key, your provider's data policy applies, and you can pick a provider
  whose terms you've read. A local model keeps everything on your machine.
- **Lock-in.** An agent tied to one model maker moves only as fast as that maker does.

## The trade-off

Choosing a model means setting it up: a key to create, a bill to watch, a local server to keep
running. Hosted agents that pick for you skip all of that. If you don't want to think about models,
a hosted plan is fine. If you do, an agent that takes your own key is worth the setup.

## Models in Casama

On a self-hosted server you add keys for Anthropic, OpenAI, Google Gemini, xAI or OpenRouter, sign
in with a ChatGPT plan, or point Casama at local models through Ollama. You pay providers directly,
and local model calls are recorded at $0. Each bot has its own model, with fallbacks if one is unavailable.

On Casama Cloud, Casama picks the models, so there are no keys to add, and you pay in credits, where a
credit is a dollar. You can't bring your own key there. If choosing the model matters to you,
[self-host Casama](/self-hosted), which is free.

## Questions

### Which AI agents work with OpenRouter?

Any agent that takes an OpenAI-style endpoint can usually use OpenRouter. Self-hosted Casama has
OpenRouter as one of its built-in providers.

### Can I use my ChatGPT subscription with an AI agent?

Some agents can sign in with it: OpenClaw, Rakazo, Agent Zero and self-hosted Casama say so, and
nanobot can use a Codex sign-in. Check the plan's own limits.

### Is a local model good enough for an agent?

For short, routine tasks, often yes. For long tasks with many steps, hosted models are still
stronger. See [can AI agents run on local models](/learn/can-ai-agents-run-on-local-models).

## Related questions

- [Can AI agents run on local models like Ollama?](/learn/can-ai-agents-run-on-local-models)
- [How much does an AI agent cost a month?](/learn/how-much-does-an-ai-agent-cost)

## Sources

{{sources: openclaw, hermes-agent, rakazo, agent-zero, nanobot, nanoclaw, mausbot, openbot, n8n, lindy, claude-cowork, chatgpt-agent, manus, grok-bot, meta-muse, hark}}

{{cta}}
