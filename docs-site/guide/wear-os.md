# Casama on Wear OS

The watch app lets you answer your bots, ask them something by voice and see who is working, from
your wrist. It signs itself in, keeps working when your phone is out of reach, and leaves everything
long for the phone.

It needs Wear OS 3 or later (a watch from 2021 or newer, such as a Pixel Watch or a Galaxy Watch).
For Apple Watch, see [Casama on Apple Watch](./apple-watch).

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
phone". A card, a page, a file or a picture shows as one line with **Open on phone**. Swipe right to
close any screen.

**Open on phone** opens that screen in Casama on your phone. If Casama isn't open there, it leaves
a notification on the phone instead; tap it to go to the same place.

## Sign in

**From your phone.** Open Casama on the watch with Casama signed in on the phone. The phone signs
the watch in for you, and both say so. If the phone app isn't running, the watch says "Open Casama
on your phone to finish"; open it within fifteen minutes, or tap **Try again** on the watch. With
the [app lock](./privacy) on, the phone asks before it signs the watch in.

A new watch asks the phone by itself. A watch that was signed out doesn't: tap **Sign in** on it
when you want it back.

**With a code.** On the watch, choose **Sign in with a code**. It shows a code that lasts ten
minutes. In Casama on your phone or computer, open **Settings → Watch → Sign in a watch with a
code**, type it, check which watch is asking, and tap **Sign it in**. This works with Casama Cloud.
A [self-hosted](/self-hosting/) server signs a watch in through the phone.

The watch never holds your password. It makes a key of its own, keeps it encrypted on the watch, and
only the key's fingerprint leaves it.

## Answer a request

When a bot needs your OK, the watch shows its own notification with **Allow** and **Deny**. The
server decides what a watch may allow:

| The request | On the watch |
|---|---|
| Low risk | **Allow** in one tap, or **Deny** |
| Medium risk | **Hold to allow**, after it shows what will be sent or changed, or **Deny** |
| High risk, or a payment | **Review on phone**, or **Deny** |
| A takeover, a password, a question from a connected app, a new skill | **Open on phone** |

**Always Allow** isn't on the watch: it changes how a bot behaves from then on, which is for the
phone. **Deny** always works. A request someone already answered says "Already answered". With
TalkBack, **Hold to allow** becomes a tap with a question to confirm.

**Do It** on a suggestion starts it. If it can't start, the suggestion stays: with no credits left
the watch says "Out of credits", and for any other reason it offers **Open on phone**, where
Casama says why.

Choose how much a watch may allow in **Settings → Watch → Allow from the watch**: **Low and medium
risk** (the default), **Low risk only**, or **Never**.

Once the watch app has its own notifications, Casama tells the system not to show the phone's copy
on the watch, so a request shows once. If you turn notifications off for Casama on the watch, the
phone's copies show on the watch again.

The watch is signed in to one workspace, the one your phone had selected. A request, suggestion or
reply from another of your workspaces still shows on the watch, with **Open on phone** and no
other buttons: answer it on the phone.

If more things wait than the watch can show (a new skill, a question from a connected app), the
**Needs you** list says how many more are on your phone.

## Ask by voice

Tap **Ask** and talk. It stops listening after a moment of quiet, or when you tap. What it heard
shows for a moment with **Undo**, then goes. Your own starters are under the microphone, and **Type
instead** opens the watch's voice and keyboard input.

Each ask starts a new chat, as quick ask does on the phone. **Reply**, in a notification or on a
bot's answer, continues that chat. If the watch is offline, the ask or reply is kept and sent when
it's back, and the screen says so. If nothing was heard, it says "Didn't catch that" and sends
nothing. A kept ask the server won't take is removed, and the watch says which one.

Dictation and **Read aloud** use the same voice service as the phone and cost the same. **Talk**,
a live call, still starts on the phone: a call on the wrist isn't built yet.

## Tiles and complications

**Tiles.** Swipe left from the watch face and tap **+** to add one:

| Tile | Shows | Button |
|---|---|---|
| **Needs you** | The count and the first request | **Allow** for low risk, **Open on phone** for what only the phone can answer, else **Review** |
| **Ask** | A bot's face and two starters | **Speak** |
| **Up next** | The next routine and the one after | **Run Now** |
| **Bot** | One bot, where it stands, its last line | **Ask** |

**Complications.** Touch and hold the watch face to add one:

- **Needs you**: the count (short text), or the first request (long text).
- **Credits**: how much of this period you've used.
- **Ask**: a bot's face; tap to ask it.

**Settings → Watch** in Casama on your phone shows how to add each one.

A bot you started from the watch also shows on the watch face while it works, and clears when it's
done. On Wear OS 7 this is a Live Update.

Tiles and complications refresh on a timer and whenever the watch app runs. One that couldn't
refresh says how old it is. Wear Widgets aren't built yet; tiles work on every supported watch.
The server doesn't yet push refreshes to a tile or a complication.

## Privacy

- With your wrist down, counts, bot names and clocks stay, and your words are hidden. This is
  **Hide details when my wrist is down** in the watch's **Settings**, on by default.
- **Show details on the watch** in Casama on your phone (**Settings → Watch**) turns off what bots
  wrote on every watch: the watch then shows counts and bot names only. It is off while the app lock
  is on, until you turn it on.
- **Hide reply text** (Settings → Notifications) hides reply text on the watch as it does on the
  phone.
- Nothing from a recording is kept on the watch. It keeps the last summary and the last chat it
  showed, and erases both when you sign it out.

## Remove a watch

In Casama on your phone, open **Settings → Watch**, find the watch under **Signed-in watches**, and
tap **Remove**. It signs out at once. You can also tap **Sign out of this watch** on the watch, or
sign out of Casama on the phone. A removed watch's tiles and complications say "Open Casama to sign
in". It stays signed out until you tap **Sign in** on the watch.

## Self-hosting

A watch talks to your own server, so the server must be reachable from the watch. Away from home,
use a [Casama Link](./casama-link) address. Sign in through the phone, since a watch can't learn a
server's address by itself. The address must start with `https`, or be plain `http` on your home
network (`localhost`, a `.local` name, or an address such as `192.168.1.10`); with any other
address the watch says it can't reach your server instead of signing in. Pushes go through Casama Cloud's relay, as they do for the phone; with
private notifications on they carry no words and the watch fetches the rest itself.

## Limits

- The watch is not the whole app. There are no settings for bots, no Library, no billing.
- Watch approvals can't be turned off for a whole workspace yet. Each person sets their own.
- This is new: it hasn't been tried on every watch yet.

## Related

- [Casama on Apple Watch](./apple-watch)
- [Widgets and controls](./widgets)
- [Bots on the Lock Screen](./lock-screen)
- [Notifications and attention](./attention)
