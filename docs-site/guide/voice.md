# Voice and calls

Talk to your bots instead of typing. Dictate messages, have replies read aloud, call a bot live,
and let a bot ring your phone when something needs you. Voice runs on your workspace's own provider
keys.

## Which keys you need

Add keys in **Settings** → **Model keys** → **Add key**.

| Feature                      | Needs                                                                             |
| ---------------------------- | --------------------------------------------------------------------------------- |
| Dictation                    | An OpenAI or Deepgram key                                                          |
| Read aloud                   | A Google AI key (Gemini Flash-Lite), or an OpenAI, ElevenLabs, Cartesia or Fish Audio key |
| Live calls                   | A Google AI (Gemini) key. OpenAI Realtime is used only when there is no Google key. Included on Casama Cloud, and on servers whose admin set a server-wide key |
| Bot rings your phone         | A live-call key (Gemini or OpenAI), plus push set up on the server for iOS and Android |
| Wake word                    | No key: it runs on your device                                                     |

Every minute, second or character of voice is recorded in [Usage](/guide/usage). The provider bills
your own account.

## Dictate a message

1. In a chat, tap **Dictate** in the message box. Allow microphone access the first time.
2. Speak, then tap **Stop and transcribe**.
3. The text lands in the message box. Edit it if you like, then send.

Dictation uses OpenAI (`gpt-4o-mini-transcribe`) or Deepgram (`nova-3`). Google's transcriber costs more once the transcript text is included, so it is not the default.

## Have a reply read aloud

Open a bot message's actions and choose **Read aloud**. Audio is saved per message and voice, so
replaying it doesn't call the provider again.

## Choose a bot's voice

1. Open **Bot settings** → **Voice**.
2. Pick a **Read-aloud provider**: Google, ElevenLabs, OpenAI, Cartesia or Fish Audio. Automatic uses Google when that key exists.
3. Optionally enter a **Voice id** from that provider. Leave it empty for a default voice.
4. Pick a **Dictation provider**: OpenAI or Deepgram.
5. Tap **Save**.

**Automatic (first key found)** uses whichever matching key the workspace has.

## Call a bot live

Live calls and phone calls use **Gemini Live** when the workspace has a Google AI key, and the
server's own Google key when the workspace has none. **OpenAI Realtime** is used only when neither
exists. The bot's voice on Gemini is one of Gemini's built-in voices (Kore by default).

1. In a chat, tap **Start a voice call** (the phone icon in the header).
2. Wait for **Live**, then talk. Use **Mute** and **Hang up** as on a phone call.

If the workspace has no live-call key, the call screen says so, with **Get a free key from Google**
(Google AI Studio) and **Add a Google AI key** (opens **Model keys** with Google picked). Only
owners and admins can add keys.

### The call screen

The bot appears as its Casama cloud mascot, animated for the call. Bots without a mascot icon
appear as the lavender Casama cloud.

- While you talk, it listens: a soft smile, blinks, glances and a nod.
- While it talks, its mouth moves, it bounces a little and its orb pulses. It grows slightly with
  its voice.
- It fades when you mute, and turns grey if the call drops.
- On phones, calls play through the speaker. Tap the audio button (**Speaker**) to switch to the
  earpiece (**Phone**). With Bluetooth or wired headphones connected, it lists them to pick from.
- **Captions** shows the last few lines of the conversation under the orb. Turn them off for just
  the orb; the choice is remembered on the device.
- With reduced motion turned on in your system settings, the mascot holds still.

What to know:

- Before it uses a tool, the bot says so ("Let me check that"), so the call doesn't go quiet. A
  tool that takes more than about 12 seconds hands its result to the chat, and the bot tells you.
- Each tool shows as a card above the captions, in plain words with what it's about ("Searching
  the web", "best time to repot a fern"). It spins while it runs, shows a check when it's done and
  then folds away. Cards that take a while count the seconds.
- When an action needs your OK, its card asks right there: tap **Allow** or **Not now** without
  leaving the call. The bot hears your answer and carries on.
- The bot keeps its persona and a small set of tools suited to talking: memory, knowledge, web
  search, notes to you, routines, watchers, tickets, usage and your device data. Each tool call runs
  with the bot's normal approvals. If an action needs your approval, the bot tells you, and you
  approve it in the app.
- For bigger jobs, anything that needs its computer, files, the browser or connected apps, the bot
  starts the task in the chat and tells you. It runs in the background with all the bot's tools, and
  the result appears in the conversation.
- To let the bot use specific connected-app tools live, such as creating a GitHub issue while you
  talk, open the bot's settings → **Voice** → **Tools on calls** and tick them. Each tool you add
  goes with every call, so it adds a little to each call's cost; pick only the ones you'll use by
  voice.
- A call with no speech from either side for 2 minutes ends by itself, so a forgotten call doesn't
  keep running.
- On Gemini Live, **Usage** records what the call actually cost, from the token counts Gemini
  reports; other calls are estimated by the minute.
- You can interrupt. When you start speaking, the bot stops talking and listens.
- The call's transcript is saved to the conversation.
- Screen tools, such as clicking around the bot's desktop, aren't offered during a call.

## Start a call with a wake word

On desktop and Android, say a phrase to start a live call with a chosen bot.

1. Open **Settings** → **Wake word**.
2. Turn on **Listen for the wake word**.
3. Set the **Phrase**: two or three words, such as "hey casama".
4. Choose **Call this bot**.

The first time, the app downloads an open-source on-device model, about 18 MB. Listening happens
only on your device while Casama is open. Nothing is sent anywhere until the call starts.

## When a bot calls you

A bot can ring you when something is worth interrupting you for and talking beats a message. Your
device rings like a normal call, with the bot's name and the reason.

| Device            | How it rings                                                      |
| ----------------- | ----------------------------------------------------------------- |
| iPhone            | The system call screen (CallKit), even when the app is closed     |
| Android           | A full-screen calling screen, even when the app is closed         |
| Desktop and web   | A ringing banner over every screen, with **Answer** and **Decline** |

When you answer, the live call opens in the same conversation and the bot speaks first. The rules:

- It rings for 45 seconds. If you don't answer, you get a notification with the reason.
- Your quiet hours apply. During quiet hours nothing rings, and you get a notification with the
  reason when they end. See [Attention and notifications](/guide/attention).
- Only one call rings for you at a time.
- The bot can only call the person it's working for.

### Server setup for ringing phones

If you self-host, phones need push credentials on the server:

| Platform | Settings                                                                                         |
| -------- | ------------------------------------------------------------------------------------------------ |
| iOS      | `APNS_KEY_P8` (the `.p8` key, inline or a file path), `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_VOIP_TOPIC` |
| Android  | `FCM_SERVICE_ACCOUNT` (a Firebase service account, JSON text or a file path)                     |

`APNS_VOIP_TOPIC` defaults to `ai.casama.app.voip`. Without these, desktop and web still ring
through the banner while the app is open. See [Configuration](/self-hosting/configuration).

## Limits

- Live calls run on Gemini Live or OpenAI Realtime; other realtime voice providers aren't
  supported. With both keys, Gemini is used.
- On Gemini Live, use headphones on desktop computers if the bot seems to hear itself: echo
  cancellation depends on the device.
- The wake word isn't available on iOS or on the web, and on Android it listens only while the app
  is open.
- Bots can't phone other numbers, such as a business, yet.
- On OpenAI Realtime calls the mascot follows whether the bot is speaking, not how loud it is.
- Provider connections follow each provider's public docs and have been tested against stand-ins,
  not yet against every live provider.

## Related

- [Chat](/guide/chat)
- [Attention and notifications](/guide/attention)
- [Autonomy and approvals](/guide/autonomy)
- [Usage and budgets](/guide/usage)
- [Chat apps](/guide/chat-apps)
