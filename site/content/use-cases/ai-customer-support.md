---
title: AI customer support agent that asks before refunds
h1: An AI customer support agent that asks before refunds
card: Customer support
crumb: Customer support
description: A Casama bot answers customers from your help docs in email and chat apps, looks up their orders, and asks you before giving any refund.
lead: A support bot is only safe if it knows what it may not promise. A Casama bot answers from your help documents, looks up orders, and stops for you before any refund.
updated: 2026-11-18
order: 6
---

## What the bot does

- **Answers from your docs.** It uses the knowledge you give it, not guesses.
- **Works where customers write.** Email, WhatsApp, Telegram, Messenger, SMS, Slack, Teams, Discord.
- **Looks things up.** Orders, bookings and accounts, through the apps you connect.
- **Hands over.** When it isn't sure, it asks a person in your team and learns the answer.
- **Reports.** How many it answered, what it escalated, and what the docs didn't cover.

## Where it stops to ask

- Refunds and credits.
- Anything that changes a customer's account, if you mark that tool "always asks".
- Replies outside what your documents cover, if you set it to draft only.

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

1. A customer writes on WhatsApp at 02:10 asking where their order is.
2. The bot looks up the order, sees it shipped, and replies with the tracking link.
3. Another asks for a refund. The bot answers that it has passed the request on, and an approval appears on your phone.
4. In the morning: 23 answered, 1 refund waiting, 2 questions the docs didn't cover.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Support** persona.
2. Add your help centre and policies as knowledge.
3. Connect a chat app and set who may write to the bot.
4. Connect your order system and mark refund tools **Always asks**.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## Questions

### Which channels does it support?

Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu, iMessage, Microsoft Teams and Discord.

### Can it issue refunds?

Only with your approval, if you set the refund tool to always ask.

### Can several people approve?

Yes. Anyone who can use the bot can answer its requests.

See [what else Casama bots do](/use-cases/).

{{cta}}
