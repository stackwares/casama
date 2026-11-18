---
title: How Casama keeps AI agents safe: approvals, sandboxes, secrets
h1: How Casama keeps a bot from doing what you didn't want
crumb: Security
description: Casama bots work on locked-down computers, ask before risky steps, never see your passwords, and save a checkpoint before anything destructive.
lead: A bot that can act can also act wrongly. Casama is built so the worst a bot can do is small, visible and reversible.
updated: 2026-11-18
---

## It asks before risky steps

Every tool a bot can use has a risk level: low, medium or high. Each bot has an autonomy setting
that decides what waits for you:

| Setting | The bot asks before |
|---|---|
| Ask before acting | Every action that changes something |
| Ask for risky actions (the default) | Sending email or chat messages, calling people, making a page public, deleting outside its workspace folder, paid data lookups, and anything you marked "always asks" |
| Act on its own | Nothing, except high-risk actions on your own computer |

Payments always ask, whatever the setting. A request shows the bot, the tool, its risk and exactly
what it wants to do. You can approve, deny, or allow that action from now on. A run that waits for
you costs nothing and survives a server restart.

## It works on a computer that isn't yours

Each bot has its own sandboxed Linux machine. It can't reach your devices or any file you didn't
share with it. You can watch the computer live and take control at any time.

Before a command that deletes data, Casama saves a checkpoint of the bot's computer, so you can put
the files back as they were.

## It never sees your passwords

Secrets don't reach the AI model. A bot uses a placeholder, and Casama fills in the real value only
when the request goes to a site that secret is allowed for. Logins can come from 1Password or
Bitwarden.

## It doesn't follow instructions hidden in a web page

Web pages, emails and files can contain text written to trick a bot. Casama marks that content as
untrusted and tells the bot never to follow instructions inside it. After a bot has read untrusted
content, actions that send data out ask for approval, even ones that normally wouldn't.

## It stops when it's stuck or over budget

- Each bot has a budget per run and per day. At the limit, the run stops and tells you.
- The same action with the same details isn't run a third time in one run.
- Five failed steps in a row end the run, so a confused bot doesn't spend your money retrying.

## Your data

- Your chats, memories and files are used to run Casama for you and for nothing else. They are not
  used to train AI models, sold, or used for ads.
- Each workspace is walled off from every other in the database, with a test that proves it.
- You can export everything and delete your account at any time. You can also turn on encryption
  for a workspace's content and set how long run history is kept.
- Sign-in supports two-step codes and passkeys, and the app can lock itself and ask for your face
  or fingerprint before risky actions.

If you want nothing to leave your own machine, [self-host Casama](/self-hosted), which is free.

## Report a problem

Security reports go to security@casama.ai. The
[security policy](https://github.com/stackwares/casama/blob/main/SECURITY.md) explains what to
send and what to expect.

## Questions

### Can a bot spend my money without asking?

No. Payments always ask. Model and computer costs are capped by the bot's budgets.

### Can I see what a bot did?

Yes. Every run keeps a timeline of each step, what it cost and why.

### What if a bot deletes something?

Restore the checkpoint Casama saved before the command ran.

{{cta}}
