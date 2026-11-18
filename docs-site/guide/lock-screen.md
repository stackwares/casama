# Bots on the Lock Screen

When you start something with a bot on your phone, its progress follows you onto the Lock Screen
(an iPhone's Live Activity, an Android live notification), so you can put the phone down and still
see how it's going.

## iPhone: Live Activities

Each run you start gets a Live Activity:

- **On the Lock Screen** (and in StandBy): the bot, what it's doing in everyday words ("Searching
  the web"), how long it has been at it, and how many steps it has taken. **Stop** and **Open** sit
  underneath.
- **In the Dynamic Island**: the bot's mark and a small sign of how it's going, with the running
  time. Touch and hold it for the bot, its step and the buttons.
- **Needs your OK**: the activity turns orange and offers **Allow**, **Deny** and **Review**.
  Allow and Deny answer right there, after Face ID or your passcode, without opening Casama.
  Review opens the request in Casama to read it in full. A high-risk request offers only Review,
  so you always see its details first. The request's own notification still buzzes once; the
  activity never makes a sound.
- **Finished**: it stays on the Lock Screen for 15 minutes, then leaves by itself. A run you stopped
  leaves at once.

Tap the activity to open the bot's chat. **Stop** stops the bot right there, without opening
Casama (it needs no Face ID: stopping is always safe). If Casama can't do it in place, for example
just after the phone restarted, it opens and does it there. Allow, Deny and Stop need iOS 17 or
later.

It keeps up while Casama is closed: the server sends each new step (at most one every few seconds)
and sends at once when the bot needs you or finishes. If no update has come for two minutes, the
activity dims and says **Open Casama for the latest**. Runs still going when you open Casama get
their activity back, including ones iOS ended after 8 hours.

Runs you started on this phone, or that are still going when you open the app, are shown. So are
runs you start on another device, such as your Mac or the web app: a few seconds after one starts,
the server puts it on your phone too (see [Bots you start elsewhere](#bots-you-start-elsewhere)).
Routines don't take over your Lock Screen.

### Turning it off

Live Activities are an iPhone setting: **Settings → Casama → Live Activities**. With them off, the
app still shows every run inside Casama.

## Android: a live notification

Each run you start gets one notification that stays while the bot works:

- **On Android 16 and later**, it becomes a **Live Update**: a chip in the status bar with the
  running time (or **Needs you** while the bot waits for you), and a card at the top of the
  notification shade and on the lock screen.
- **On older Android**, or with Live Updates turned off for Casama, it's an ordinary notification
  that stays at the top with the bot, its step and the running time. Expand it for the steps so
  far.
- **Buttons:** **Stop** and **Open** while it works. When it needs your OK: **Allow**, **Deny**
  and **Review** (a high-risk request offers only Review). Stop, Allow and Deny work without
  bringing Casama to the front, once the phone is unlocked; if Casama isn't running, they open it
  where you can finish.
- **Finished:** it stops being pinned and clears itself after 15 minutes. A run you stopped leaves
  at once. Swipe it away and it stays away for that run.

It never makes a sound: the request's own notification is the one that tells you. It keeps up
while Casama is closed, from the server, in the same way as on an iPhone.

The **Bot** widget shows the running bot, its step and **Stop** while something runs. For every
widget, see [Widgets and controls](./widgets).

### Turning it off

Long-press the notification, or go to **Settings → Apps → Casama → Notifications**: turn off
**Bots at work** to hide these notifications, or turn off Live Updates to keep the ordinary kind.

## Bots you start elsewhere

Start a bot on your Mac, the web app or another phone, and a few seconds later it shows on this
phone's Lock Screen as well, with the same updates and the same Finished. A phone that already
shows the run doesn't get a second one. On iPhone this needs iOS 17.2 or later.

To keep runs from other devices off this phone, turn off **Settings → App → Bots you start
elsewhere** in Casama. Runs you start on this phone still show. If you share a phone, it follows
whoever signed in on it last, and it stops when you sign out.

## What shows on the Lock Screen

On both phones: the bot's name, its step in general words and the times. Never what it's searching for, file names,
sites, messages or what a request is about: those stay in the app. On a self-hosted server with
**Private Notifications** on, not even the bot's name or step leave your server (see
[Use your server on your phone](/self-hosting/remote-access#notifications)).
