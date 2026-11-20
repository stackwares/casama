---
title: What is an AI agent? A plain explanation with examples
h1: What is an AI agent?
description: An AI agent is software that uses an AI model to do a task step by step with tools, not just answer. Examples, limits and how it differs from a chatbot.
lead: An AI agent is software that uses an AI model to carry out a task for you, step by step, using tools such as a browser, files and your apps. A chatbot tells you how to do something. An agent does it and reports back.
updated: 2026-11-18
order: 1
---

## The short version

Give a chatbot the request "book a table for four on Friday" and it writes you a list of
restaurants. Give an agent the same request and it opens the booking site, picks a time, fills in
the form, asks you before confirming, and tells you when it is done.

Three things make that possible:

1. **A model that plans.** The AI model decides what to do next, looks at the result, and decides
   again. This loop repeats until the task is done.
2. **Tools.** The agent can do things, not only write: open web pages, run commands, read and
   write files, send messages, use the apps you connect.
3. **A place to work.** It needs somewhere to run those tools: your own computer, a browser, or a
   computer of its own in the cloud.

{{figure: agent-loop}}

## What an agent can do

- **Work that takes many steps**: research a topic across twenty sources and write it up, or clean
  a spreadsheet and chart it.
- **Work in your apps**: sort an inbox, draft replies, move meetings, update a ticket.
- **Work that repeats**: a morning brief, a weekly report, a price check every hour.
- **Work while you're away**: an agent with its own computer keeps going after you close the chat.

## What to look for in one

| Question | Why it matters |
|---|---|
| Where does it run? | On your machine it can touch your files. On a separate computer, mistakes stay there. |
| Does it ask first? | Sending, paying and deleting should wait for your OK. |
| Does it remember? | Without memory you explain your preferences every time. |
| Can it start by itself? | Schedules and triggers turn a helper into a teammate. |
| What does it cost? | Each step uses a model, so long tasks cost more. Look for budgets. |
| Who can see your data? | Check whether it trains on your data, and whether you can run it yourself. |

## Where agents go wrong

Agents make mistakes that chatbots can't, because they act. A model can misread a page, repeat a
failing step, or follow instructions hidden in a web page it was only meant to read. Good agent
software limits the damage: a sandboxed computer, approvals for risky steps, spending limits, and a
way to undo.

## How Casama fits

Casama is an open-source app for AI agents it calls teammates, or bots. Each bot has its own
sandboxed Linux computer, a memory you can read and edit, and rules for what it must ask before
doing. Bots run on schedules and triggers, and you reach them from apps on every platform. You can
[run it on your own server](/self-hosted) for free or use Casama Cloud.

## Related questions

- [AI agent vs chatbot: what's the difference?](/learn/ai-agent-vs-chatbot)
- [How do AI agents work?](/learn/how-do-ai-agents-work)
- [Is it safe to give an AI agent access to my email?](/learn/is-it-safe-to-give-an-ai-agent-access-to-my-email)

{{cta}}
