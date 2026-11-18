---
title: AI social media assistant that drafts and waits to post
h1: An AI social media assistant that drafts the week and waits for your OK
card: Social media
crumb: Social media
description: A Casama bot plans a weekly content calendar and drafts posts for each channel in your voice. It queues drafts for approval and doesn't post by itself.
lead: The hard part of social media is turning up every week with something worth reading. A Casama bot plans the calendar and drafts each post in your voice. Posting stays with you until you decide otherwise.
updated: 2026-11-18
order: 11
---

## What the bot does

- **Plans the week.** What to post, where, when, and which of your themes it fits.
- **Drafts per channel.** Length and format to suit each one, with an image idea.
- **Writes variants.** Two or three versions of a post or headline to test.
- **Keeps your voice.** It holds your brand voice, audience and themes in memory, where you can
  read and edit them.
- **Suggests replies.** Ideas for answering comments, for you to use or ignore.
- **Plans campaigns.** A launch plan with a way to measure each idea.

## Where it stops to ask

The Social persona is told never to post or reply publicly itself. It queues drafts for approval.
To make that a hard rule that doesn't depend on instructions:

- Add an action rule for **Publishing** set to **Ask me first**, or to **Hand it to me to finish**
  if you want to press the button yourself.
- If you connect a posting tool, mark it **Always asks**.
- Sending email or chat messages already asks under the default setting.

See [how approvals work](/security).

## What it looks like

An example week:

1. Monday 09:00: the weekly content plan routine runs. The bot drafts five posts with a day,
   a channel, the copy and an image idea for each.
2. You open the plan on your phone, rewrite one opening line and drop one post.
3. You tell it: "Less formal. No exclamation marks." It saves that and uses it next week.
4. On Wednesday you ask for three versions of the launch post. You pick the second.
5. You post them yourself, or approve each one when the bot asks.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Social** persona. It comes with a weekly content plan routine on Monday
   mornings. For campaigns, ads and landing pages, use the **Marketer** persona.
2. Tell it your voice, your audience and three or four themes. Paste in a few posts you liked.
3. Add the Publishing rule above before you connect any account that can post.
4. Read the first two weeks of drafts closely and correct them. The corrections stay in memory.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## What it won't do for you

- It doesn't know what happened in your business this week unless you tell it or connect a source.
- A draft can state something untrue. The Marketer persona is told never to make claims the
  product can't back up, and you should still read every post.
- Casama's app catalog has no social networks of its own today. Posting goes through a connector
  service, the bot's browser with you signed in, or your own hands.

## Questions

### Will it post without asking?

Not with the setup above. The persona queues drafts, and a Publishing rule set to "Ask me first"
wins even if the bot is otherwise allowed to act on its own.

### Can it make the images?

A bot can generate images. That uses credits, and by default it doesn't ask first, so set a budget.

### Can it reply to comments for me?

It can draft replies. The Social persona doesn't reply publicly itself.

### Can more than one person review the drafts?

Yes. In a shared workspace, anyone who can use the bot can answer its approval requests.

See [what else Casama bots do](/use-cases/).

{{cta}}
