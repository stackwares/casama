# Device connections and health

Device connections let your bots use personal data from your phone or computer, such as your
calendar, contacts and daily health summaries. Use them when you want a bot to plan around your
schedule, look up a contact, or notice that you slept less than usual. The data is yours alone:
even workspace admins can't see it.

## Share data from a device

1. On the device, open **Settings** → **Advanced** → **Device connections**.
2. Turn on a kind of data. The system permission prompt appears only at this point.
3. Optionally set **Keep for** and **Private models only** (see below).

Each kind is off until you turn it on. Turning a kind on doesn't give any bot access yet.

## Let a bot read it

The first time a bot needs a kind of data, it asks in the chat: "Ada would like to use your
calendar". Tap **Allow** or **Not now**. The bot carries on either way.

Allowed bots show under each kind in **Device connections**. Tap **×** next to a bot to stop it.

The rules:

- A bot reads your device data only in runs acting for you: your own chats and your own routines.
  A teammate chatting with the same bot gets nothing.
- You can only allow bots you have access to.
- If your device was online in the last 15 minutes, the bot first asks it for a fresh read and waits
  up to 10 seconds. Otherwise it gets the most recent stored summaries, with their age.
- Every read shows on the run's timeline: which kind, how many items, which dates and which devices.
- Device data reaches the bot marked as untrusted, since calendar titles and similar text come from
  other people.

## What each platform shares

| Kind              | iOS | Android | macOS | Windows | Linux | What's shared                                        |
| ----------------- | --- | ------- | ----- | ------- | ----- | ---------------------------------------------------- |
| Calendar          | Yes | Yes     |       |         |       | One summary per day, from yesterday to 30 days ahead |
| Contacts          | Yes | Yes     | Yes   |         |       | Names, phone numbers and email addresses             |
| Health data       | Yes | Yes     |       |         |       | Daily and workout summaries (see below)              |
| Places            | Yes | Yes     |       |         |       | Arriving at and leaving named places                 |
| Notifications     |     | Yes     |       |         |       | Notifications from apps you pick                     |
| Computer activity |     |         | Yes   | Yes     | Yes   | Minutes per app and top window titles, per hour      |

The web app doesn't share device data. Calendar summaries hold up to 100 events a day. Data is
refreshed when the app opens or comes back to the foreground.

Places and notifications mainly drive device triggers, such as "when I leave work". See
[Routines](/guide/routines). Computer activity is part of desktop context. See
[Your own computer](/guide/companion).

## Bots adding events

A bot can add an event to your calendar. Under the default autonomy it does this without asking;
set the bot to **Ask before acting** if you want to approve each one. The event goes to the device's default writable calendar on the device seen most recently. If
that device doesn't answer within 20 seconds, the bot is told it will happen when the device is
next online.

## Health data

Health connects Apple Health on iOS and Health Connect on Android. It shares summaries only, never
raw readings such as a heart-rate series or sleep segments. The server refuses anything else.

| Summary | What it holds                                                                                                      |
| ------- | ------------------------------------------------------------------------------------------------------------------ |
| Day     | Sleep start, end, minutes and stage minutes; steps; active energy; workout count; resting heart rate; heart-rate variability; weight |
| Workout | Activity, start, end, minutes, energy, distance and average heart rate                                             |

Your device builds these summaries itself. Sleep counts for the morning it ends. Uploads cover the
last 7 days each time the app opens or comes back, so a missed morning catches up.

**Cycle tracking**, **Blood glucose** and **Blood pressure** are separate switches under Health, off
by default. Their system permissions are asked only when you turn them on, and the server drops
them unless you did.

When a bot reads health data, each day is compared with your own previous 30 days (with at least 5
earlier days), in plain words: "lower than your usual", "about your usual" or "higher than your
usual". Bots never give medical advice.

::: warning Health data and encryption
On Casama Cloud, health data is stored only when encryption at rest is on for a workspace you own.
Otherwise the upload is refused with "Health data needs encryption at rest". Self-hosted servers
decide with `HEALTH_REQUIRES_ENCRYPTION` (`auto`, `on` or `off`; `auto` requires it when billing
is on). See [Privacy and data](/guide/privacy).
:::

## Privacy settings per kind

| Setting                  | What it does                                                                                |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| **Keep for**             | How long readings are kept: **Live only**, 7, 30 or 90 days, or a year where that's the default |
| **Private models only**  | Only bots whose models all run on this machine or a private network can read it            |

Defaults are a year for calendar, contacts and health, and 90 days for places and notifications.
With **Live only**, a fresh read goes to the bot without being stored.

**Private models only** counts every model in the bot's setup, including fallbacks. Each must use a
key whose address is local or private, such as `localhost`, a private IP range, or a `.local` or
`.internal` name.

## Turn off and forget

- Turning a kind off deletes its stored readings.
- **Forget this device**, under **Your other devices**, deletes everything that device shared.
- Expired readings are deleted automatically.
- A privacy export includes your devices, readings and bot permissions, and deleting your account
  removes device data right away.

Every device reading is encrypted at rest with the key of the oldest workspace you own that has
encryption turned on, when there is one.

## Limits

- Reminders and photos have no collector in the app yet, so they don't appear in **Device
  connections**. A bot asking to add a reminder can't complete it.
- Calendar on macOS, Windows and Linux isn't collected yet.
- There's no background refresh for calendar, contacts and health. Data updates when you open the
  app.
- Collectors haven't all been checked on real phones yet.

## Related

- [Routines](/guide/routines)
- [Your own computer](/guide/companion)
- [Privacy and data](/guide/privacy)
- [Autonomy and approvals](/guide/autonomy)
