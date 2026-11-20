---
description: "Casama on Apple Watch: answer your bots, ask them something by voice and see who is working. Needs watchOS 26 and works without your iPhone nearby."
---

# Casama on Apple Watch

The watch app lets you answer your bots, ask them something by voice and see who is working, from
your wrist. It signs itself in, keeps working when your iPhone is out of reach, and leaves everything
long for the phone.

It needs watchOS 26 or later. For Wear OS watches, see [Casama on Wear OS](./wear-os).

## What you can do

| Screen | What it does |
|---|---|
| **Now** | The first screen. **Needs you** first, then each bot that is working with its step and a clock, then what runs next. Nothing waiting: **All clear**. |
| **Needs you** | Answer a request with **Allow** or **Deny**, or a suggestion with **Do It** or **Not now**. |
| **Ask** | Opens listening. Say one thing, and the bot answers. |
| **Bots** | Up to eight bots and where each stands. Tap one to see its latest chat. |
| **Up next** | Routines in the order they run, each with **Run Now**. |
| **Brief** | This morning's brief, with **Read aloud**. |
| **Settings** | Who is signed in, the bot **Ask** uses, and the privacy switches below. |

A reply shows as plain text, up to about a screen or two. A longer one ends with "Continues on
iPhone". A card, a page, a file or a picture shows as one line with **Open on iPhone**.

**Open on iPhone** opens it in Casama on the phone when the app is open in front of you. Otherwise
it leaves a notification on your phone that opens it when you tap it.

## Sign in

**From your iPhone.** Open Casama on the watch with Casama signed in on the iPhone. The phone signs
the watch in for you, and both say so. If the iPhone app isn't running, or nobody is signed in on
the phone yet, the watch says "Open Casama on your iPhone to finish" and signs in once you have.
With the [app lock](./privacy) on, the iPhone asks before it signs the watch in. If you say no
there, the watch waits until you tap **Try again**.

**With a code.** On the watch, choose **Sign in with a code**. It shows a code that lasts ten
minutes. In Casama on your phone or computer, open **Settings → Watch → Sign in a watch with a
code**, type it, check which watch is asking, and tap **Sign it in**. This works with Casama Cloud.
A [self-hosted](/self-hosting/) server signs a watch in through the iPhone.

The watch never holds your password. It makes a key of its own and only the key's fingerprint
leaves it.

## Answer a request

When a bot needs your OK, a notification comes to your wrist with **Allow** and **Deny**. The
server decides what a watch may allow:

| The request | On the watch |
|---|---|
| Low risk | **Allow** in one tap, or **Deny** |
| Medium risk | **Hold to allow**, after it shows what will be sent or changed, or **Deny** |
| High risk, or a payment | **Review on iPhone**, or **Deny** |
| A takeover, a password, a question from a connected app, a new skill | **Open on iPhone** |

**Always Allow** isn't on the watch: it changes how a bot behaves from then on, which is for the
phone. **Deny** always works. A request someone already answered says "Already answered".

The watch is signed in to one workspace, the one your iPhone is in. A notification from another
workspace of yours still reaches your wrist, without buttons: it says it is in another workspace,
and **Open on iPhone** takes you to it. Switch workspace on the phone and the watch follows.

If an answer from a notification doesn't go through (no connection, a server problem), the request
opens on the watch and says why, so you can try again.

**Needs you** lists what the watch can answer. When more is waiting than it can show (a new skill, a
question from a connected app), it says how many more are on your phone.

On a watch with Double Tap, a pinch presses **Allow** on a low-risk request. With VoiceOver, **Hold
to allow** becomes a tap with a question to confirm.

Allowing needs the watch on your wrist and unlocked. A watch with no passcode can read and deny,
not allow.

Choose how much a watch may allow in **Settings → Watch → Allow from the watch**: **Low and medium
risk** (the default), **Low risk only**, or **Never**.

## Ask by voice

Tap **Ask** and talk. It stops listening after a moment of quiet, or when you tap. What it heard
shows for a moment with **Undo**, then goes. Your own starters are under the microphone, and **Type
instead** opens the watch's keyboard, Scribble and dictation.

Each ask starts a new chat, as quick ask does on the phone. **Reply** on a bot's answer continues
that chat. If the watch is offline, the ask is kept and sent when it's back, and the screen says so.
If the server can't take a kept ask after a few tries, the watch drops it and tells you.

Dictation and **Read aloud** use the same voice service as the phone and cost the same. **Talk**,
a live call, still starts on the phone: a call on the wrist isn't built yet.

## On the watch face

**Complications** you can add to a face:

| Shape | Complication | Shows |
|---|---|---|
| Inline | **Casama** | "2 need you", else the next routine, else "All clear" |
| Circular | **Needs you** | The count |
| Circular | **Ask** | A bot's face; tap to ask it |
| Circular | **Credits** | How much of this period you've used |
| Corner | **Needs you** | The count |
| Rectangular | **Needs you** | Who needs what, with **Allow** in place for a low-risk request and **Review** for the rest |
| Rectangular | **Bot** | One bot, where it stands and its step |
| Rectangular | **Up next** | The next routine and a countdown |

**Smart Stack.** Turn the Digital Crown on the face. **Needs you** comes up when something waits,
**Working** while a bot you started is working, **Up next** shortly before a routine, and **Brief**
after it arrives.

**Controls** (Control Center, the Smart Stack, and the Action button on Apple Watch Ultra): **Ask
Casama**, **Talk to a bot**, **Run a routine**.

**Siri.** Say "Ask Casama", "Run my morning brief in Casama" (with a routine's name), or "What
needs me in Casama".

**Settings → Watch** in Casama on your iPhone shows how to add each one. Touch and hold your watch
face, tap **Edit**, then choose Casama.

Complications refresh on the watch's own schedule and whenever the watch app runs. One that
couldn't refresh for half an hour stops showing what it knew as if it were now: a large one says
how old it is ("as of 9:12") and drops its running clock and its **Allow** button, and a small one
shows the Casama mark. The server doesn't yet push refreshes to a watch face.

## Privacy

- With your wrist down, counts, bot names and clocks stay, and your words are hidden. This is
  **Hide details when my wrist is down** in the watch's **Settings**, on by default.
- **Show details on the watch** in Casama on your iPhone (**Settings → Watch**) turns off what bots
  wrote on every watch: the watch then shows counts and bot names only. It is off while the app lock
  is on, until you turn it on. Off, a notification opened on the watch shows the bot and "Needs
  your OK" without the words. The first glimpse of a notification your iPhone passes to the watch is
  drawn by the system from the phone's copy, so hide notification previews on the iPhone as well.
- **Hide reply text** (Settings → Notifications) hides reply text on the watch as it does on the
  phone.
- Nothing from a recording is kept on the watch. It keeps the last summary and the last chat it
  showed, and erases both when you sign it out.

## Remove a watch

In Casama on your iPhone, open **Settings → Watch**, find the watch under **Signed-in watches**, and
tap **Remove**. It signs out at once. You can also tap **Sign out of this watch** on the watch, or
sign out of Casama on the phone. A removed watch's complications say "Open Casama to sign in".
A signed-out watch stays signed out until you tap **Sign in** on it.

## Self-hosting

A watch talks to your own server, so the server must be reachable from the watch. Away from home,
use a [Casama Link](./casama-link) address. Sign in through the iPhone, since a watch can't learn a
server's address by itself. The watch needs https, except for a server on your home network (an
address like `192.168.1.20`, a `.local` name or a bare name), which it also reaches over http. Pushes go through Casama Cloud's relay, as they do for the phone; with
private notifications on they carry no words and the watch fetches the rest itself.

## Limits

- The watch is not the whole app. There are no settings for bots, no Library, no billing.
- Watch approvals can't be turned off for a whole workspace yet. Each person sets their own.
- An Apple Watch that stays on watchOS 10 or earlier keeps the mirrored notifications and nothing
  more.
- This is new: it hasn't been tried on every watch yet.

## Related

- [Casama on Wear OS](./wear-os)
- [Widgets and controls](./widgets)
- [Bots on the Lock Screen](./lock-screen)
- [Notifications and attention](./attention)
