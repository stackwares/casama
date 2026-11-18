# Bots in the notch and menu bar

On a Mac, Casama keeps you posted from the top of the screen, whatever app is in front: a bot's
progress around the camera (the notch) and in the menu bar. You can answer a request, stop a bot or
ask one something without opening Casama's window.

## Closing the window

Closing Casama's window keeps the app running in the menu bar, so your bots can still reach you.
**Cmd+Q** quits. Click the Dock icon, the menu bar icon or the notch to bring the window back.

## The notch

While a bot works on something you started, the notch grows to show its mark and a small
indicator. Hover over it (or click it) to open the list:

- **Working:** the bot, what it's doing in everyday words ("Searching the web"), how long it has
  been at it, and **Stop**.
- **Needs your OK:** the notch opens by itself, even with another app in front, and shows what the
  bot asks to do. **Allow** and **Deny** answer it right there; a high-risk request also offers
  **Open** to read it in full first. Nothing is ever answered without a click.
- **Wants you to take over:** **Open** takes you to the bot's computer.
- **Finished:** it shows for two seconds, then the notch goes back to rest.

The notch also shows requests that ask you from someone else's run, such as a teammate's routine.

### Ask from the notch

Open the notch and type into **Ask a bot…**. It goes to the bot you asked last (pick another from
the menu next to it), the notch closes, and the run shows in the notch like any other. If the bot
can't be reached, Casama's window opens with your message.

Drag files onto the notch to ask a bot about them: **Drop to ask a bot** opens Quick ask with the
files attached.

### A voice call in the notch

While you're on a voice call with a bot, the notch shows it: the bot's mark, a level meter that
moves with whoever is speaking, and how long the call has gone on. Hover over it for **Mute** (or
**Unmute**) and **Hang up**, which do the same as the call screen's buttons. Hanging up saves the
transcript to the chat, as usual. Click the bot's name to bring the call window back.

### Macs without a notch

On a Mac without a notch, or on an external display, a small pill stands in for it at the top of
the screen while a bot works, and leaves the screen when nothing is going on.

## The menu bar

The Casama icon in the menu bar has a dot while something needs you. Click it for the same list,
plus **Quick ask…**, **Open Casama**, **Settings…** and **Quit**.

## Windows and Linux: the tray

Windows and Linux have no notch, so the Casama icon in the tray carries the same list. Click it to
see each bot at work and what it's doing, with the same buttons: **Stop** while it works, **Allow**
and **Deny** when it asks for an OK, and **Open**. Requests that ask you from someone else's run
(a teammate's routine) show here too. The tooltip says what matters most, and on Linux the bot's
name (or **Needs you**) shows beside the icon. **Open Casama** and **Quick ask…** sit at the
bottom.

On GNOME the icon needs a tray to sit in. Ubuntu ships one as the **Ubuntu AppIndicators**
extension, which may be turned off: turn it on in the Extensions app, or run
`gnome-extensions enable ubuntu-appindicators@ubuntu.com`. Stock GNOME (Fedora and others) needs the
AppIndicator and KStatusNotifierItem Support extension. Without a tray, **Needs you** in the app's
sidebar has the same list.

## Settings

Under **Settings → App**, next to **Open at Login**:

| Setting | What it does |
|---|---|
| **Show bots in the notch** | Turn the notch off to keep only the menu bar icon. On by default |
| **Open the notch on hover** | Off: click the notch to open it. On by default |

## Privacy

- The notch never shows in screenshots, screen recordings or screen sharing, so a bot that looks at
  your screen never reads its own request off it.
- It needs no new permissions: no accessibility access, no screen recording, no input monitoring.
- It only acts on clicks. Other apps can't press its buttons.

## Accessibility

VoiceOver reads each row (bot, what it's doing, how long) and every button. With **Reduce Motion**
on, nothing pulses, and the notch opens and closes with a short fade instead of a spring.
