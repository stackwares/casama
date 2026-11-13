# Notifications and attention

Bots tell you when they need a decision, when work is done, and when they notice something. Casama
decides how loudly to tell you: a push notification now, a push later, or a quiet note in your
inbox that waits for your next brief. Use this page to set quiet hours, choose which bots may
interrupt you, and understand why a message did or didn't buzz your phone.

## Where notifications go

Every notification lands in the **Casama** row pinned at the top of **Chats**, whatever else
happens. It opens one feed:
things that need a decision come first (approvals, take-over requests, suggestions and skill
ideas), then updates newest first (briefs, routine results, messages from bots, missed calls,
published pages). Filter it with:

| Filter | What's in it |
| --- | --- |
| **All** | Everything |
| **Needs you** | Approvals, take-over and secret requests, suggestions and skill ideas. See [Autonomy and approvals](/guide/autonomy). |
| **Briefs** | Morning briefs from bots with check-ins on |
| **Pages** | Pages your bots published. See [Pages](/guide/pages). |

Tap **Mark All as Read** to clear the unread count. Approvals, take-over requests and secret
requests are marked read automatically once anyone answers them, and opening a bot's chat marks
its results read.

If you belong to several workspaces, the workspace switcher shows a dot when another workspace
has pending approvals or unread notifications.

## Turn on push notifications

The first time the app has something worth telling you, it shows **Turn on notifications**.

1. Tap **Turn on**.
2. Allow notifications in your system's prompt.

Tap **Not now** to skip; the app offers again later.

Push works in the iOS, Android and macOS apps, and in the web app when the server's build
includes web push. The Windows and Linux apps use the in-app inbox only.

::: tip Self-hosting
Push needs a Firebase project: the server needs its service account and the apps must be built
with the same project. Without it, the in-app inbox still works. See
[Configuration](/self-hosting/configuration).
:::

## Set quiet hours

Quiet hours hold pushes overnight (or whenever you choose). Your inbox still fills; the pushes
arrive when the window ends.

1. Open **Settings**, and under **App**, tap **Quiet hours**.
2. Turn quiet hours on.
3. Set **From** and **Until**. The window can cross midnight, for example 22:00 to 07:00.
4. Tap **Save**.

When quiet hours end, Casama sends the pushes that waited, except ones you already read in the
app.

### Choose per bot

1. Open the bot's chat, tap its name, and tap **Notifications from this bot**. You can also ask
   the bot to go quiet; turning itself quieter happens at once, but going back to your usual hours
   asks you first.
2. Pick one:

| Option | What it does |
| --- | --- |
| **Follow my quiet hours** (default) | Uses your quiet hours from Settings |
| **Always notify me** | This bot pushes even during your quiet hours |
| **Its own quiet hours** | This bot uses its own window instead of yours |

These settings are yours alone. Other people in the workspace set their own.

## What interrupts you, and when

Notifications fall into three groups.

**Urgent ones push right away**, even during quiet hours:

- Approvals from a chat or voice call, because someone is waiting in the conversation.
- Missed calls from a bot.
- Proactive messages a bot marked urgent, such as an urgent suggestion.

**Direct updates follow quiet hours**: approvals from routines and other background work,
messages a bot sends you, take-over and secret requests, and similar. They push now, or when
your quiet hours end.

**Proactive messages follow attention rules.** These are messages you didn't ask for in the
moment: routine results, suggestions from check-ins and similar. A suggestion's push comes from
the bot, in its own words ("Want me to book a ride to the show at 7?"), and some wait until the
time they matter, such as an hour before an event. Each has an urgency:

| Urgency | What happens |
| --- | --- |
| Urgent | Pushes now, even during quiet hours |
| Normal | Pushes, unless you're busy (see below). During quiet hours, the push waits for the window to end. |
| Low | Never pushes. It waits in your inbox for your next brief. |

## Attention rules: when you're busy

A normal-urgency proactive message doesn't push while any of these is true. It goes to your
inbox and waits for your next brief instead.

| You're busy when | How Casama knows |
| --- | --- |
| Focus is on | The latest Focus event from your devices in the last 12 hours is "on" |
| You're driving | The latest driving event in the last 3 hours is "on" |
| You're in a meeting | A timed event on the calendar you share from your devices is happening now |
| The bot has said enough today | That bot already sent 5 non-urgent pushes in the last 24 hours |

Focus, driving and calendar data come from what you share under **Settings → Advanced → Device
connections**. See [Your devices](/guide/devices). The daily limit counts per bot, so one chatty
bot doesn't use up another's.

### Your brief carries what waited

Your morning brief comes from a bot's **Check-Ins** (in its **Bot profile**). When a brief runs, it
includes the messages that waited in the last 36 hours, each with the reason it waited, so
nothing is lost. See [Routines](/guide/routines).

## Why am I seeing this?

Proactive messages in the inbox have an info button. Tap it to open **Why am I seeing this?**,
which shows:

- The rule that sent it: a routine and its trigger in words (for example "when you arrive at
  Home"), your morning brief, or a suggestion from a check-in.
- **Used:** the kinds of device data the bot looked at, if any.
- **Urgency:** low, normal or urgent.
- Why it waited, if it did. For example: "It waited while you were in a meeting and came with
  your brief."

To hear less from a bot, tap **Less like this**. The bot saves a pinned preference to send these
only when they really matter, or fold them into your brief. Only you can do this for your own
notifications.

## Limits

- Quiet hours use the time zone stored on your profile, which is UTC unless it was set
  otherwise. The app doesn't have a time zone setting yet, so set your window in UTC for now.
- Messages that wait for a brief are only delivered by a brief. If no bot has **Check-Ins** on,
  they stay in your inbox without a push.
- Focus and driving need a device that reports them. See [Your devices](/guide/devices) for
  which platforms do.
- Push on Windows and Linux isn't available.

## Related

- [Autonomy, approvals and action rules](/guide/autonomy)
- [Routines](/guide/routines)
- [Your devices](/guide/devices)
- [Voice](/guide/voice)
