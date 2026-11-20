# Widgets and controls

Casama's widgets put what your bots need from you, and what they'll do next, on your Home Screen,
your Lock Screen and your Mac's desktop. Controls put asking, talking and running a routine one
press away.

## The widgets

| Widget | Shows | Sizes |
|---|---|---|
| **Needs you** | How many requests, takeovers and suggestions wait on you, and the first ones with their buttons | Small, medium, Lock Screen |
| **Bot** | One bot: working (and on what), waiting for you, or idle, with its last message | Small, medium, Lock Screen |
| **Ask** | Ask a bot, start a voice call, or try one of your own starters | Small, medium; a bar on Android |
| **Routines** | What runs next, with **Run now** | Small, medium, Lock Screen |
| **Today** | Needs you, up next, what just finished and an ask field, on one widget | Large and extra large |
| **Brief** | This morning's brief, or when the next one comes | Medium, large |
| **Library** | What your bots made lately | Small, medium, large |
| **Tasks** | Where the board stands, things to review first | Medium, large |
| **Credits** | How much of this period's credits you've used, and today's spend | Small, Lock Screen |

Touch and hold a **Bot**, **Ask** or **Routines** widget to choose which bot or routines it shows.
**Settings → Widgets** in Casama shows each one and, on Android, adds it with **Add to Home screen**.

## Canvas: what your bots put there

**Canvas** is the one widget your bots fill in. Ask in a chat, in your own words: "put a daily verse
on my Lock Screen", "count down to my trip", "keep my reading streak on my home screen". The bot
can show a text, a countdown, a number with a ring, a short list or a picture, over a colour, a
gradient, a picture or one of eight built-in paintings. Casama picks the text colour so it always
reads.

- **The first time** a bot wants to show something, the chat shows a preview with **Show on my
  widgets** and **Not now**. After your yes, that bot keeps its canvas current without asking, from
  chats and routines.
- **Add the widget once.** On an iPhone or iPad: touch and hold the Home Screen or Lock Screen, tap
  **Edit**, **Add Widget**, **Casama**, **Canvas**. On a Mac: right-click the desktop, **Edit
  Widgets**, **Casama**, **Canvas**. On Android, the preview's **Add to Home screen** does it.
- **It changes by itself.** A bot can give a list once (up to 400 items) that the widget cycles
  through every day, week or few hours, or plan up to 14 changes ahead. Neither needs the bot
  again, so a year of daily verses costs one request.
- **Which canvas a widget shows**: touch and hold it to choose **Automatic** (the latest) or one by
  name. A bot keeps up to three.
- **Settings → Widgets → From your bots** lists every canvas with **Hide on a locked phone**,
  **Pause** and **Clear**, and a switch per bot to stop it showing anything.

On the Lock Screen only a short form shows: about two lines under the clock, a few words above
it. Anything a bot marks as personal, and any canvas you set to **Hide on a locked phone**, shows
just its name until you unlock.

## Acting from a widget

- **Allow** and **Deny** appear only for a low-risk request. Anything else shows **Review**, which
  opens the request so you read it first.
- **Do it** starts a suggestion, as in the app.
- **Run now** starts a routine; its progress then follows you as a Live Activity or live
  notification.
- Everything else opens Casama at the right place.

Buttons do nothing on a locked iPhone until you unlock it; that's how iOS works. With the app lock
on, buttons open Casama, and it asks to unlock first.

## The Lock Screen

On an iPhone, add **Needs you**, **Bot**, **Routines** and **Credits** under the clock, and a one-line
**Casama** above it. While the phone is locked they show counts and general words ("Milo needs your
OK"); the request itself appears once you unlock.

Android phones that offer lock screen widgets can take **Needs you**, **Bot**, **Routines** and
**Credits** there too, with the same rule.

**Canvas** goes under the clock or above it too: a verse, a countdown or a streak a bot keeps
there for you (see above).

## Controls (iPhone, iOS 18 and later)

Add these to Control Center, a Lock Screen corner, or the Action button:

- **Ask Casama** opens quick ask.
- **Talk to a bot** starts a voice call with the bot you pick.
- **Run a routine** runs the routine you pick, after you unlock.

On Android, **Ask Casama** is a Quick Settings tile. A bot can also go on your home screen as its
own icon from **Settings → Widgets**.

## On a Mac

Casama's widgets go on the desktop and in Notification Center. They show the same things and open
Casama when clicked; to act in place, use [the notch](./notch). Without the Mac app, your iPhone's
widgets can appear on the Mac too (System Settings → Desktop & Dock → **Use iPhone widgets**).

## On your wrist

Casama has its own watch apps, with complications, a Smart Stack, controls and tiles. See
[Casama on Apple Watch](./apple-watch) and [Casama on Wear OS](./wear-os).

## Keeping up

Widgets update whenever Casama is open, and on their own about every half hour. When something they
show changes, the server tells them to refresh, so a new request usually appears within a minute,
even with Casama closed. A widget that couldn't refresh says how old its data is ("as of 9:41").

A self-hosted server sends these refreshes through Casama Cloud's relay, as it does notifications;
they carry nothing but "something changed".

## Privacy

- Widgets read one summary with a key of their own. That key can't do anything else: it can't
  answer requests, read chats or send anything. Signing out deletes it.
- With the [app lock](./privacy) on, widgets show only counts, bot names and times until you turn
  on **Show details in widgets** in Settings → Widgets. A workspace that requires the app lock keeps
  details off.
- **Hide reply text** (Settings → Notifications) also hides a bot's last message in the Bot widget.

Widgets need iOS 18, Android 8 or macOS 14 or later.
