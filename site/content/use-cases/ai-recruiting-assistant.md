---
title: AI recruiting assistant that screens and leaves the decision
h1: An AI recruiting assistant that screens to a scorecard and leaves the decision to you
card: Recruiting
crumb: Recruiting
description: A Casama bot scores applicants against a written scorecard, quotes its evidence and drafts replies. A person makes every decision, and nothing is sent unasked.
lead: Reading every application properly takes hours, and tired readers are inconsistent. A Casama bot scores each applicant against the same written scorecard and shows the evidence. It recommends. A person decides.
updated: 2026-11-18
order: 12
---

## What the bot does

- **Writes a scorecard with you.** Must-haves, nice-to-haves and deal-breakers for the role. It
  asks for one if it is missing.
- **Scores each applicant.** One line of evidence per criterion, quoted from what they sent.
- **Recommends.** Advance, hold or decline, with the reason.
- **Builds a shortlist.** The same format for everyone, so you can compare.
- **Drafts the messages.** A kind, specific note for each person, and interview invites for the
  shortlist.
- **Helps with next steps.** With your calendar connected, it can propose interview times.

## Where it stops to ask

- **Every decision.** The Recruiting screener persona is told that a person makes every final
  decision and that it never rejects anyone directly.
- Sending any email, under the default setting.
- Changes in a connected app that you marked "always asks".

You set these rules per bot and per action. See [how approvals work](/security).

## What it ignores on purpose

The Recruiting screener persona is told to ignore, and never infer, age, gender, ethnicity,
religion, disability, family status and other protected traits, and not to use photos or names as
signals. Instructions are not a guarantee. Read the evidence lines, sample the "decline" pile
yourself, and check the rules on automated screening where you hire.

## What it looks like

An example, for a made-up role:

1. You: "Screen today's applicants for the support lead role." You attach the scorecard and
   twelve applications.
2. The bot scores each one. For "has led a team", it quotes the line from the CV, or writes "no
   evidence found".
3. It recommends four to advance, three to hold and five to decline, and marks two it is unsure
   about.
4. You move one from "decline" to "hold" and tell it why. It remembers the correction.
5. It drafts interview invites for the shortlist. You read them and approve each send.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Recruiting screener** persona.
2. Write the scorecard for one role, or ask the bot to draft one and edit it.
3. Give it the applications: send the files in chat, or connect the mailbox or folder where they
   arrive. Mark connected tools read-only to begin with.
4. Make the bot private to the people who hire, so applicants' details aren't open to the whole
   workspace.
5. Compare its first batch with your own reading before you rely on it.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## What it won't do for you

- It doesn't interview anyone, and it doesn't judge character.
- It can miss something a careful reader would catch, or misread an unusual CV.
- Casama's app catalog has no applicant tracking system of its own today. Applications come in as
  files, by mail, or through a connector service.

## Questions

### Does the bot reject candidates?

No. It recommends and drafts. A person decides, and sending asks for approval by default.

### Is it fair?

It applies one scorecard to everyone and shows its evidence, which makes its reasoning checkable.
That is not the same as being free of bias. Keep a person reviewing the outcomes.

### Where is applicant data kept?

In your workspace and on the bot's computer. It is not used to train models. If you want it on
your own machine, self-host Casama.

### Can it schedule the interviews?

It can propose times and draft the invite. See [AI scheduling assistant](/use-cases/ai-scheduling-assistant).

See [what else Casama bots do](/use-cases/).

{{cta}}
