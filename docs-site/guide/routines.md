# Routines

<img class="doc-art" src="/art/routines.webp" srcset="/art/routines-800.webp 800w, /art/routines.webp 1600w" sizes="(max-width: 760px) 100vw, 688px" width="1600" height="900" alt="A garden under an arc of sky from sunrise to starry night, with lanterns marking the hours.">

A routine is work a bot does later on its own: once at a time you pick, on a repeating schedule, or
when something happens, such as a webhook, a meeting, a message or an event on your phone. Use
routines for reminders, daily reports, follow-ups and anything you'd otherwise have to ask for
again and again.

This page also covers watchers ("tell me when...") and check-ins (a morning brief and suggestions),
which are built on the same machinery.

## Create a routine

The quickest way is to ask the bot in chat: "Remind me in 20 minutes to call Ana" or "Every weekday
at 9:00, summarize my inbox". The bot creates the routine itself, and creating or changing its own
routines doesn't need your approval, unless the run has just read untrusted content such as a web
page or an email. What the routine later does still goes through your usual
[approvals](/guide/autonomy).

To create one yourself:

1. Open the bot's chat, open the **More** menu and tap **Bot profile**, then **Routines**.
2. Tap **New routine**.
3. Enter a **Name** and **Instructions**: what the bot should do each time. Or tap one of the
   **Ideas** at the top (a weekly review, a morning plan, bill reminders…) to fill in the name,
   instructions and schedule, then change anything. Ideas come from the
   [open gallery](https://gallery.casama.ai/#routine).
4. Pick a trigger: **Once**, **Repeats**, **Meetings** or **Messages**, and fill in its options
   (below). **GitHub** and **Webhook** are under **Advanced**, with the cron expression and
   timezone.
5. Tap **Create**.

## Manage routines

Each routine in the list shows its trigger, when it runs **Next** and when it ran **Last**.

- Use the switch to turn a routine on or off. An off routine shows **Off**.
- Open its **More** menu and tap **Run Now** to start it immediately. **View run** opens the run.
- **Edit** in the same menu changes its name and instructions, its schedule and timezone (or, for a
  one-time routine, when it runs), and lists its recent runs with what each cost.
- **When It Ends** sets or removes its end (below).
- **Delete** stops it for good. Results it already posted stay in their conversation.

The **Routines** widget and the **Run a routine** control show what runs next and start a routine
without opening Casama ([Widgets and controls](./widgets)).

You can also ask the bot to list, change or delete its routines. It can rename one, change its
instructions, schedule, timezone or device event, pause or resume it, set or remove its end, and
turn a one-time routine into a repeating one or back ("make that reminder daily", "stop the standup
after Friday").

## Ending a routine

A repeating or event routine can end on its own. In **New routine** (or **When It Ends** on an
existing one), set **Ends**:

- **Never**: it keeps going until you turn it off.
- **On a date**: pick the **Last day** and time. It doesn't run after that.
- **After some runs**: it stops after that many runs. On an existing routine the count starts
  over from now.

The card shows **Ends** with the date, or how many runs are left. Once it ends it switches itself
off and shows **Off**. To start it again, give it a later end or remove the end. **Run Now** doesn't
count as one of its runs. One-time routines don't need an end: they already stop after their run.

## One-time routines

Choose **Once**, then tap **In 15 min**, **In 1 hour** or **Tomorrow 9:00**, or pick a date and
time. The routine runs a single time and then switches itself off.

When you ask a bot for a reminder in chat, it creates a one-time routine, not a repeating one.

## Repeating schedules

Choose **Repeats**, then pick **Every day**, **Weekdays**, **Every week** or **Every hour**. For
the daily, weekday and weekly choices, set the **Time** (and the **Day** for **Every week**).

For anything else, open **Advanced** and write your own **Cron expression**. Cron uses five
fields: minute, hour, day of month, month and weekday. For example, `30 17 * * 5` runs at 17:30
every Friday. A schedule the choices can't show reads as **Custom** with the schedule in words.

The **Timezone** field, also under **Advanced**, takes an IANA name such as `America/Chicago`. The
schedule follows that zone, including daylight saving changes, and the sheet shows **Times are
in** with the zone. Check it before you tap **Create**: the app fills it in from your device when
it can, and otherwise uses `America/Chicago`.

## Webhooks

A webhook routine runs whenever another service posts to its URL. The run gets the request body,
and the event name when the sender includes one.

1. Open **Advanced** and choose **Webhook** for any service, or **GitHub** for a GitHub repository
   webhook.
2. Tap **Create**.
3. Copy the **URL** and the **Signing secret**. The secret is shown only once.
4. Add the URL as a webhook in the other service, signed with the secret.

Every request must be signed with HMAC-SHA256 of the raw body: GitHub sends `X-Hub-Signature-256`,
and other services send `X-Casama-Signature: sha256=<hex>`. Unsigned or wrongly signed requests are
ignored. Casama answers `202 Accepted` either way, so nobody can probe which routines exist. See
[Webhooks](/develop/webhooks) for signing examples.

## Meeting triggers

A meeting routine runs around events on a connected calendar, for example a prep note 15 minutes
before every meeting with a customer.

1. Connect Google Calendar or Outlook first. See [Connections](/guide/connections).
2. In **New routine**, choose **Meetings** and pick the **Calendar**.
3. Pick when to run: **30 min**, **15 min** or **5 min** before, **At start**, or **15 min** after.
4. Optionally narrow it down:
   - **Only meetings with people outside my company**: at least one guest's email domain differs
     from yours.
   - **Only meetings with a video link**: a Meet, Zoom, Teams, Webex or Whereby link anywhere in
     the event.
   - **Only titles containing (optional)**.
5. Tap **Create**.

Casama checks the calendar every 5 minutes, looking 36 hours ahead, and skips cancelled events. Each
matching event starts one run, within a minute of its time. If the event moves before then, the run
moves with it. The run gets the event's title, times, guests, link, location and description.

## Message triggers

A message routine runs when an email or chat message to the bot matches your filters. Without a
**From** filter it only hears people the bot already chats with. Set **From** (an address, a
number, `*@company.com`, or `*` for anyone) to hear from someone else. For example, a vendor's
invoice email can start a routine that files it.

1. Connect the app first under **Bot profile → Advanced → Chat apps**. See [Chat apps](/guide/chat-apps).
2. In **New routine**, choose **Messages**.
3. Set at least one filter:
   - **App**: one chat app, or **Any app**.
   - **From (address, number, or \*@company.com)**.
   - **Subject contains**.
   - **Message contains**.
4. Tap **Create**.

A message that starts a routine isn't also answered as a normal chat message. The run treats the
message as untrusted content, so instructions inside it can't take over the bot.

## Device triggers

A device routine runs when something happens on your own phone or computer. Ask the bot to set one
up, for example "When I leave work, text me the grocery list" or "When a PDF lands in Downloads,
file it". Device routines only ever fire for the person who created them; a teammate's routine
never sees your events.

| Event | Fires when | Needs |
| --- | --- | --- |
| Wake | You wake up, from last night's sleep in your health data. Once a day. | Health data on your phone |
| Arrive, leave | You arrive at or leave a named place, such as Home or Work. | Places on iOS (Android has no background location) |
| Leave now | It's time to leave for your next calendar event that has a location, based on live travel time plus a buffer (5 minutes by default). | Places, a connected calendar, and a Google Maps or Mapbox key |
| Workout ended | A workout ended in the last 6 hours. | Health data on your phone |
| Notification | A notification arrives from an app you picked. One-time codes are masked. | Android's notification access |
| File added | A new file appears in a watched folder, optionally matching a pattern such as `*.pdf`. | Watched folders in the desktop app |

Set up places, watched apps and watched folders in **Settings → Advanced → Device connections**.
Casama keeps only place names and times, never a location trail. See [Devices](/guide/devices) for setup and
privacy details.

The routine starts as soon as the event reaches the server. A retried upload never starts it twice.

## Where results go

A routine posts its results in a chat with you, so they read like the rest of your conversation:

- A routine the bot created in chat posts back into that chat.
- A routine made in **Routines** posts into your **General** chat with that bot (see
  [Chat](/guide/chat)).
- Morning briefs always go to **General**.

The start of each run shows as "Routine “Daily summary” ran" rather than as a message from you, and
the open chat updates when the result arrives.

You also get a notification with the result, linked to the chat. Casama's
[attention rules](/guide/attention) decide when it reaches you, and the notification says which
routine sent it.

Routine runs are normal runs, with the usual step, time and budget limits. See
[Usage and budgets](/guide/usage).

## Watchers

A watcher keeps an eye on something and wakes the bot only when it changes. Ask the bot "tell me
when..." and it creates one.

| Kind | Watches |
| --- | --- |
| Page | The visible text of a web page, optionally from a given heading or phrase on. It can read signed-in pages in the bot's browser when the computer is awake. |
| Reply | A new comment from a person on a [ticket](/guide/projects). |
| Result | The result of a read-only tool from one of the bot's [connections](/guide/connections). |
| Time | A moment in time. It fires once and finishes. |

How watchers work:

- Checks run every 15 minutes by default, and as often as every minute.
- The first check only records the starting point.
- Checks don't use the model, so an unchanged check costs nothing. When something changes, the bot
  gets a run with what changed, your condition and what to do, and decides whether it counts.
- When it counts, the bot tells you: a line in your General chat with the bot that opens the
  watcher's own topic, and a notification. A watcher you asked for from a chat app answers there
  too. When the change isn't what you asked about, you hear nothing.
- A watcher can expire after a set number of days.

To manage them, open **Bot profile → Watchers**. Each shows **Watching**, **Paused**, **Done** or
**Expired** and how many times it fired. Use **Pause**, **Resume** or **Delete**, or open it to see
its conversation.

Watchers fetch outside pages, so creating one follows the bot's normal approval rules.

## Check-ins

Check-ins are how a bot reaches out first: a morning brief, and a look every few hours for things
that need you, like a trip to plan or an email to answer. The personal bot Casama makes for you
when you first sign in starts with them on. Other bots start with them off.

1. Open **Bot profile → Check-Ins**.
2. Turn them on and set **Morning brief at** (8:00 by default), **Look every** (1, 2, 3, 4, 6, 12
   or 24 hours; 3 by default) and **Daily limit** (default $1). A look once a day runs six hours
   after the brief.
3. Tap **Save**.

Briefs and suggestions go to the person who turned check-ins on, in their timezone. They're posted
in your **General** chat with the bot. A brief covers today and what's ahead, and its first
sentence is the notification you get. On a day with nothing to tell, it says so in the chat without
a push. A bot has one morning brief: to change what it covers, ask the bot, and to change its time,
use **Check-Ins**. Suggestions the brief makes are cards under it rather than pushes of their own. A suggestion is a card there: **Do it** opens a topic where
the bot does it and reports back in General, **Not now** puts it away. Several at once come as one
card with a **Do it** on each; tap a row to read it in full. Answered rows say what happened
(*Started 12:50*, *Put away* or *Expired*), and a started one opens its topic. If the bot can't
start yet, for example because the workspace reached its daily limit, the app says why and the
suggestion stays, so you can try again later. The bot asks one thing at a time: while a card in General is still
unanswered, new suggestions wait under **Needs you** instead of piling up in the chat. Suggestions are also
collected under **Needs you** at the top of **Chats**:

- **Suggestions**: things the bot thinks you should act on, each with the
  bot's own one-line take. Tap **Do it** to open a topic where the bot does it (its actions still
  go through approvals), or **Dismiss** and choose **Just this once** or **Don't suggest it
  again**.

A suggestion also arrives as a push from the bot, in its own words, following your
[attention rules](/guide/attention): low-urgency ones wait for your brief, and a suggestion tied to
a time (leaving for the airport, booking a ride before a show) can wait until then. On iPhone and
Android the push has **Do it** and **Not now** buttons. **Do it** opens the chat with the bot
working on it in a topic; **Not now** clears the push and leaves the suggestion under
**Needs you**.

The bot also takes an extra look when there's something new to look at:

- **After you connect an app**, a few minutes later. Several connections close together share one
  look.
- **When something happens**: new mail from a person or a calendar change in the next 48 hours in
  Gmail, Google Calendar or Outlook connected through Composio (when the server has Composio's
  events set up), or a new event in the next 48 hours on a calendar your phone shares. These looks
  are at least 2 hours apart, at most 6 a day for each bot, wait for your quiet hours to end, and
  aren't on the Free plan.

To save money, scheduled looks skip your [quiet hours](/guide/attention) (on from 22:00 to 07:00
unless you change them; the brief covers the night). If you haven't
opened Casama for a week, the bot looks at most once a day, and after a month it stops until
you're back.

Check-ins use the bot's cheap model when it has one, and stop for the day once they reach the daily
limit. Each check-in run gets up to 8 steps (instead of the usual 40) and trims app reads at
8,000 characters so briefs and looks finish quickly. Their cost comes out of your usage like any
other run. A look that finds nothing writes nothing and sends nothing. If your phone shares health
data, the brief can also run when you wake up, and the scheduled time becomes the fallback.

A look starts by reading your recent mail (Gmail), the next two days of your Google Calendar and
the board, before the bot thinks about any of it. When a scheduled look reads exactly what the
last one read, it ends there and costs only those reads. Looks you or an app asked for always run
in full, and so do looks by a bot that has other apps connected or that you share phone data with.

On Casama Cloud, all of a workspace's check-ins together use at most 40% of the day's limit on
Casama's models, so they can't use up what your own messages need.

On Casama Cloud, plans limit how many bots can check in and how often they look:

| Plan | Bots with check-ins | Look at most every | Looks when something happens |
| --- | --- | --- | --- |
| **Free** | 1 | 24 hours | No |
| **Plus** | 2 | 3 hours | Yes |
| **Pro** | 5 | 1 hour | Yes |
| **Max** | 20 | 1 hour | Yes |

Going past a limit opens the paywall. After a downgrade, the oldest bots keep their check-ins.
Self-hosted servers have no such limits.

## Limits

- Check-ins (morning briefs and looks) are capped at 8 steps per run rather than 40. See
  [Limits](/guide/limits).
- Device routines can only be created by asking a bot; **New routine** doesn't offer them.
- Focus and Do Not Disturb events, and Android's first unlock as a wake-up signal, aren't collected
  yet.
- Android hears notifications only while the Casama app's process is running.
- Calendar changes are picked up by the 5-minute check; Casama doesn't receive change
  notifications from calendar providers yet.
- Watchers can't watch email or chat replies yet; replies on tickets work.
- In the app, **Edit** changes a routine's name, instructions and timing but not its trigger. To
  use a different trigger, make a new routine.

## Related

- [Webhooks](/develop/webhooks)
- [Chat apps](/guide/chat-apps)
- [Devices](/guide/devices)
- [Attention and notifications](/guide/attention)
- [Projects and the ticket board](/guide/projects)
- [Limits](/guide/limits)
