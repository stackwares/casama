# Meeting notes

Casama doesn't send a bot into your calls. Instead, a bot works from the notes your meeting app
already takes, or from your calendar, and turns them into a summary, decisions and action items you
can find later.

## Connect a notes app

Connect the app that records or transcribes your meetings, then give it to the bot. These come
from the [open gallery](https://gallery.casama.ai/#app) and connect with one click:

| App | What a bot can read |
| --- | --- |
| Fireflies | Meeting transcripts and summaries |
| Granola | Meeting notes and transcripts |
| Circleback | Meeting notes and action items |
| Otter | Meeting transcripts and summaries |
| Fathom | Recordings, notes and summaries |
| tl;dv | Recordings and notes |
| MeetGeek | Recordings and summaries |
| Krisp | Meeting notes and transcripts |
| Plaud | Recordings, transcripts and summaries |

1. Open **Settings** → **Integrations**, pick the **Browse** tab and search for your app.
2. Connect it and choose which bots can use it. See [Apps and connections](/guide/connections).

You can also just ask a bot in chat to connect it; it shows a **Connect** button.

With no notes app, a bot can still work from your calendar events and from notes you send it.

## File the day's notes every evening

The **Meeting notes** routine idea does this for you each weekday at 6 p.m.:

- It gathers the day's notes from your connected notes app, or else from today's calendar events
  and anything you sent the bot.
- For each meeting it writes a three-line summary, the decisions, and the action items with owners
  and dates.
- It saves one Markdown file per meeting in the team folder, `shared/meetings/`, and links them in
  its reply.
- It asks you before it sends anything to anyone.

To set it up:

1. Open the bot's chat, open the **More** menu and tap **Bot profile**, then **Routines**.
2. Tap **New routine**, then **Meeting notes** under **Ideas**.
3. Change the instructions or time if you like, then tap **Create**.

See [Routines](/guide/routines) for editing, pausing and ending routines.

## Right after each meeting

A meeting routine can also run a set time after each meeting ends, such as "5 minutes after every
standup ends", so the notes are ready while the meeting is fresh.

In the app, **Meetings** routines count from the meeting's start (up to **15 min** after). To count
from the end, create the routine through the [API](/develop/api) with `anchor: "end"` on its
calendar trigger:

```json
{
  "bot_id": "…",
  "name": "Standup notes",
  "instructions": "Get this meeting's notes from my notes app and file them in shared/meetings/.",
  "trigger": "calendar_event",
  "calendar": {
    "integration_id": "…",
    "offset_minutes": 5,
    "anchor": "end",
    "title_match": "standup"
  }
}
```

Send it to `POST /v1/routines`. `offset_minutes` counts from the end, so `5` is five minutes after
the meeting ends. The other calendar filters work as in the app. See
[Meeting triggers](/guide/routines#meeting-triggers).

## Limits

- Casama has no meeting bot that joins calls and records them. Use a notes app for that.
- Counting from a meeting's end is set through the API only; the app doesn't offer it yet.
- The notes-app connections follow each vendor's public docs and haven't all been tried with real
  accounts.

## Related

- [Routines](/guide/routines)
- [Apps and connections](/guide/connections)
- [Computers](/guide/computers)
- [Library](/guide/library)
