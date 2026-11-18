---
title: Can AI agents run on local models like Ollama?
h1: Can AI agents run on my own models?
description: Yes. An AI agent can use a local model through Ollama, LM Studio or vLLM if the agent software accepts an OpenAI-style endpoint. What works and what doesn't.
lead: Yes. An agent can use a model on your own computer through Ollama, LM Studio or vLLM, as long as the agent software accepts an OpenAI-style endpoint. It costs nothing per message and nothing leaves your network. The trade-off is skill on long, tool-heavy tasks.
updated: 2026-11-18
order: 10
---

## What "your own model" can mean

| Option | What it is | You pay |
|---|---|---|
| A local model | A model running on your machine or network through Ollama, LM Studio or vLLM | Hardware and electricity |
| Your own API key | You buy model usage straight from a provider | The provider's price, with no middleman |
| A plan you already have | Sign in with a subscription such as ChatGPT instead of a key | Your existing subscription |

All three need an agent that lets you choose the model. Many hosted agents don't: they run a fixed
model and bill you for it.

## What local models are good at

- **Privacy.** Prompts, files and results stay on your machine.
- **Cost.** No per-message charge, so routine work is free.
- **Simple, frequent jobs**: sorting, summarising, tagging, drafting short replies.
- **Embeddings** for memory and search.

## Where they fall short

- **Long tasks with many tools.** Agents call tools dozens of times in a row. Smaller models lose
  track sooner, pick the wrong tool more often and recover from errors less well.
- **Browsing and screenshots.** Reading a web page from an image needs a model with vision.
- **Speed.** Without a strong GPU, each step is slow, and a task has many steps.

## A setup that works

Most people who run local models don't use them for everything:

1. A local model for private or simple bots.
2. A hosted model, on your own key, for hard tasks.
3. A fallback: if the first model is unavailable, the bot uses the second.

## How to connect one

Start the model server, then give your agent its address. For Ollama on the same machine that is
usually `http://127.0.0.1:11434/v1`. Pull a model with tool support first, and a separate small
model for embeddings if the agent uses memory search.

## Local models in Casama

Self-hosted Casama accepts any OpenAI-style server: Ollama, LM Studio, vLLM or your own. Each bot
has a main model and fallbacks, so one bot can run locally while another uses a provider key.
Calls to a local model are recorded in Usage at $0. You can also use keys for Anthropic, OpenAI,
Google Gemini, xAI or OpenRouter, or sign in with a ChatGPT plan.

On Casama Cloud, Casama picks and runs the models for you. Choosing your own model is part of
[self-hosting](/self-hosted), which is free.

## Questions

### Which local model should I use?

Pick the largest model with tool calling that your hardware runs at a usable speed, and test it on
a real task. The [bots and models guide](https://docs.casama.ai/guide/bots) has current advice.

### Does the bot's computer need a GPU?

No. The model runs wherever your model server is. The bot's computer only runs the tools.

### Can I mix local and hosted models?

Yes, per bot, with fallbacks.

## Related questions

- [How do I self-host an AI agent?](/learn/how-to-self-host-an-ai-agent)
- [Self-hosted or hosted AI agent: which should I choose?](/learn/self-hosted-or-hosted-ai-agent)
- [Which AI agents let you choose the model or use your own API keys?](/learn/which-ai-agents-let-you-choose-the-model)

{{cta}}
