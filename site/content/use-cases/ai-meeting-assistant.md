---
title: AI meeting assistant for prep, notes and follow-ups
h1: An AI meeting assistant for the work before and after the call
card: Meetings
crumb: Meetings
description: A Casama bot briefs you before each meeting, files the notes afterwards and drafts the follow-ups. It doesn't join or record calls, and it asks before sending.
lead: The meeting itself is the short part. The prep before it and the follow-up after it are where things get dropped. A Casama bot does both from your calendar and the notes your meeting app already takes. It doesn't join your calls.
updated: 2026-11-18
order: 14
---

## What the bot does

- **Preps you.** A short note before a meeting, using the event's title, guests and description,
  and what it remembers about the people.
- **Files the notes.** For each meeting, a three-line summary, the decisions, and the action items
  with owners and dates.
- **Keeps them findable.** One file per meeting in a shared team folder.
- **Drafts the follow-up.** An email with the decisions and who does what.
- **Chases.** A routine can list the action items that are still open.

## What it doesn't do

Casama has no meeting bot that joins calls and records them. For the notes themselves, the bot
reads from a notes app you connect, such as Fireflies, Granola, Otter or Fathom. With no notes
app, it works from your calendar events and from notes you send it.

## Where it stops to ask

- Sending anything to anyone. The meeting notes routine asks before it sends, and sending email
  or chat messages asks under the default setting.
- Changes in a connected app that you marked "always asks".

Creating or changing calendar events doesn't ask by default. You can set it to. See
[how approvals work](/security).

## What it looks like

An example day:

1. 09:45: a brief arrives 15 minutes before a customer call. It has the guest list, the last
   thread with them and two open questions.
2. The call happens. Your notes app records it. The bot is not in the room.
3. 18:00: the meeting notes routine runs. The bot gathers the day's notes and writes a summary,
   decisions and action items for each meeting.
4. It saves one file per meeting and links them in its reply.
5. It drafts a follow-up to the customer and asks before sending. You change one date and approve.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Connect Google Calendar or Outlook to one bot.
2. Add a **Meetings** routine for prep. Choose 30, 15 or 5 minutes before, and narrow it if you
   like: only meetings with people outside your company, only meetings with a video link, or only
   certain titles.
3. Connect your notes app under Integrations, if you use one, and give it to the same bot.
4. Add the **Meeting notes** routine idea. It runs each weekday at 18:00 unless you change the
   time.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## Limits worth knowing

- In the app, a meeting routine counts from the meeting's start, up to 15 minutes after. Running
  a set time after a meeting ends is possible through the API only.
- Casama checks the calendar every 5 minutes, so a meeting added minutes before it starts may not
  be picked up in time.
- The notes-app connections follow each vendor's public documentation and haven't all been tried
  with real accounts.
- A summary is only as good as the notes it reads. Check action items and dates before you send
  them on.

## Questions

### Does the bot join my calls?

No. It works from your calendar and from the notes your meeting app takes.

### Does it record audio?

No. Recording and transcription are your notes app's job. Tell the people in the call what that
app records, as you would without Casama.

### What if I don't use a notes app?

The bot can still prepare you from the calendar, and write up notes you send it after the call.

### Will it email everyone the notes?

Only after you approve. The routine asks before it sends anything to anyone.

### Can the whole team see the notes?

The routine saves one file per meeting in the team folder, `shared/meetings/`, and links them in
its reply.

See [what else Casama bots do](/use-cases/).

{{cta}}
