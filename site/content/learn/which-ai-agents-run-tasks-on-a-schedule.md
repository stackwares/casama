---
title: Which AI agents can run tasks on a schedule?
h1: Which AI agents can run tasks on a schedule?
description: Most AI agents can run on a schedule now. They differ in what else can start them, the limits, whether your computer must stay on, and what still asks first.
lead: Most AI agents can now run a task on a schedule, such as "every weekday at 9, summarize my inbox". They differ in four ways: what else can start a task, how many schedules you get, whether your own computer has to stay on, and whether a scheduled task still asks before risky steps. A few go further and reach out first without a schedule.
updated: 2026-11-18
order: 17
---

## The list

| Agent | What can start a task |
|---|---|
| **Casama** | Schedules, webhooks, email, calendar events, check-ins |
| **OpenClaw** | Schedules, event triggers, webhooks |
| **Hermes Agent** | Schedules set up in plain language |
| **Rakazo** | Schedules, email, webhooks, GitHub events, watched changes |
| **MausBot** | Schedules, webhooks, app events |
| **OpenBot** | Schedules, at most every 15 minutes, up to 20 |
| **Agent Zero** | Scheduled tasks: cron, one-time or by hand |
| **NanoClaw** | One-time or cron tasks |
| **nanobot** | Time, interval or cron schedules, command triggers and long-running goals |
| **n8n** | Schedules and app triggers |
| **Lindy** | Schedules, plus email, Slack, calendar and meeting events |
| **Manus** | Schedules and events: 2 on Free, 20 on Pro |
| **Grok Bot** | Schedules and some events |
| **Claude Cowork and Duet** | Scheduled tasks; Duet sends a morning brief |
| **Meta Muse** | Schedules and events |
| **Hark Pro** | Scheduled tasks |
| **ChatGPT Dots** | Looks for ways to help when idle; schedules aren't described |
| **Instinct** | Reviews say it texts or calls you first |

Checked on November 18, 2026, from each product's own pages; the sources are at the end. We make
Casama.

## Four things that differ

### 1. What starts a task

A clock is the simplest trigger. Events are often more useful: a new email, a meeting ending, a
webhook from another app, a change on a page. Lindy, Rakazo and Casama start tasks from email and
calendar or meeting events. n8n has app triggers for hundreds of apps.

### 2. Limits

Some products cap schedules. Manus allows 2 on Free and 20 on Pro. OpenBot allows up to 20, run at
most every 15 minutes. Check the cap before you plan a dozen daily reports.

### 3. Whether your computer must stay on

An agent installed on your laptop only runs its schedule while the laptop is awake. MausBot says
free bots stop when your computer is off, and nanobot has to be kept running for chat apps and
schedules. Hosted agents, and self-hosted ones on an always-on server, keep going.

### 4. Whether a scheduled task still asks

A task that runs at 3 a.m. has nobody watching. Anthropic advises against scheduling Claude tasks
that send, buy or do things that are hard to undo. Look for an agent whose approvals still apply to
scheduled runs, with the request waiting for you rather than the step going ahead.

## Agents that reach out first

A schedule does what you told it. A proactive agent notices something and offers. Claude Duet sends
a morning brief. ChatGPT Dots look for ways to help when idle, and unprompted work is read-only.
Reviews say Instinct texts or calls first. Casama bots send a morning brief and suggestions you can
start with one tap.

## Routines in Casama

In Casama a scheduled or triggered task is a routine. You can ask for one in chat ("every weekday
at 9:00, summarize my inbox") or build it in the bot's profile.

- **Triggers:** once at a set time, a repeating schedule or cron expression with a timezone,
  meetings, messages, webhooks, GitHub events and events on your phone.
- **Watchers:** "tell me when" a page, price or delivery changes.
- **An end:** stop on a date or after a number of runs.
- **The same approvals:** what a routine does still goes through the bot's usual approvals, so a
  3 a.m. run waits for you before sending an email. A run that waits costs nothing.
- **Costs:** each routine lists its recent runs with what each cost, and the bot's daily budget
  still applies.

Routines run on Casama Cloud or on your own server, so they don't need your laptop. See the
[routines guide](https://docs.casama.ai/guide/routines).

## Questions

### What is a proactive AI assistant?

One that starts work without being asked: a morning brief, a reminder it thought of, an offer to
handle something it noticed. Schedules are the simple version; check-ins and suggestions go further.

### Can an AI agent send me a daily summary?

Yes. Almost every agent above can. Point it at your inbox, calendar or a set of sites and give it a
time.

### Do scheduled AI tasks cost money when nothing happens?

Each run that calls a model costs model usage, even if it finds nothing to do. Pick a schedule that
matches how often things change.

## Related questions

- [Which AI agents ask before they act?](/learn/which-ai-agents-ask-before-they-act)
- [What is an AI teammate?](/learn/what-is-an-ai-teammate)

## Sources

{{sources: openclaw, hermes-agent, rakazo, mausbot, openbot, agent-zero, nanoclaw, nanobot, n8n, lindy, manus, grok-bot, claude-cowork, meta-muse, hark, chatgpt-agent, instinct}}

{{cta}}
