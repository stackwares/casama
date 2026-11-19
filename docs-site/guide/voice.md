# Voice and calls

Talk to your bots instead of typing. Dictate messages, have replies read aloud, call a bot live,
and let a bot ring your phone when something needs you. Bots can also make spoken audio for you,
such as a voiceover.

On Casama Cloud, voice runs on Casama's own keys and is paid from your
[credits](/guide/usage#credits), so there are no keys to add and no voice providers to pick. If
you're out of credits, dictation uses your device's own speech recognition instead. The rest of
this section is for self-hosted servers, where voice runs on your workspace's own provider keys
(or keys the server's admin set up for everyone).

## Which keys you need

Add keys in **Settings** → **Model keys** → **Add Key**.

| Feature                      | Needs                                                                             |
| ---------------------------- | --------------------------------------------------------------------------------- |
| Dictation                    | An OpenRouter key, or the server's shared one                                      |
| Read aloud                   | An OpenRouter key, or the server's shared one                                      |
| Spoken audio a bot makes     | An OpenRouter key, or the server's shared one                                      |
| Live calls                   | A Google AI (Gemini) key, used only for calls. Included on Casama Cloud, and on servers whose admin set a server-wide key |
| Bot rings your phone         | A Google AI key for the call, plus push set up on the server for iOS and Android |
| Wake word                    | No key: it runs on your device                                                     |

Every minute, second or character of voice is recorded in [Usage](/guide/usage). On your own keys,
the provider bills your own account.

## Dictate a message

1. In a chat, tap **Dictate** in the message box. Allow microphone access the first time.
2. Speak, then tap **Stop and transcribe**.
3. The text lands in the message box. Edit it if you like, then send.

Dictation uses Whisper Large V3 Turbo on OpenRouter: the workspace's OpenRouter key, or the
server's shared one when the workspace has none.

If the dictation service fails or isn't available, the app falls back to your device's own speech
recognition, where the device has one.

## Have a reply read aloud

Open a bot message's actions and choose **Read aloud**. It uses Gemini 3.8 Flash-Lite TTS on
OpenRouter, on the workspace's OpenRouter key or the server's shared one. Audio is saved per message
and voice, so replaying it doesn't call the provider again.

## Choose a bot's voice

Read aloud and calls always use Gemini voices, and dictation always uses Whisper, so there's no
service to pick.

1. Open **Bot profile** → **Voice**.
2. Optionally enter a **Voice id**: one of Gemini's built-in voices, such as Kore or Puck. Leave it
   empty for Kore.
3. Tap **Save**.

## Bots that make spoken audio

Ask a bot for a narration, a voiceover, a podcast intro or a message read in a voice, and it can
make the audio itself.

- It turns up to 4,000 characters into speech per clip, in a Gemini voice such as Kore, Puck or
  Charon. For longer pieces it makes several clips and joins them on its computer.
- The audio plays under the bot's reply. It's saved on the bot's computer when it has one, and kept
  in the [Library](/guide/library).
- Under the default autonomy, the bot asks you before it makes audio.
- It uses the same speech service as read aloud (Gemini 3.8 Flash-Lite TTS on OpenRouter) and is
  counted the same way in [Usage](/guide/usage). On Casama Cloud it's paid from credits.

Music and sound effects aren't supported.

## Call a bot live

Live calls and phone calls use **Gemini Live**, on the workspace's Google AI key, or the server's
own Google key when the workspace has none. The bot's voice is one of Gemini's built-in voices
(Kore by default).

1. In a chat, tap **Start a voice call** (the phone icon in the header).
2. The bot picks up and speaks first, like someone answering the phone: it says hi, by your name
   when it knows it, and asks what it can do. Then talk. Use **Mute** and **Hang up** as on a
   phone call.

On Casama Cloud, calls are included and paid from credits; a workspace with no credits left sees
the paywall instead. On a self-hosted server with no live-call key, the call screen says so, with **Get a free key from Google**
(Google AI Studio) and **Add a Google AI key** (opens **Model keys** with Google picked). Only
owners and admins can add keys.

### Keep a call going while you use the app

A call keeps going when you leave the call screen. Go back, switch tabs, open another chat or tap
a link, and the call carries on.

- **On phones**, the call shrinks to a bubble with the bot's face that floats over every screen.
  A ring around it pulses with the bot's voice, and the call's timer sits underneath.
  - Drag it anywhere. It snaps to the nearest side and remembers which.
  - Tap it to go back to the call.
  - Press and hold it for **Mute** and **End Call**.
  - A mic-off badge means you're muted. An amber dot means the bot needs your OK for something.
- **On wide windows** (Mac, web and tablets in landscape with the sidebar), the call docks at the
  bottom of the sidebar instead: the bot, the timer, **Mute** and **End Call**. Click it to open
  the call.
- The call screen has a **Minimize** button in its header, which does the same as going back.
- The chat the call belongs to shows a bar at the top: "On a call with Ava, tap to return".
- While the call screen is open on a phone, the screen stays on.

You can be on one call at a time. Calling a second bot asks **End call with Ava and call Max?**:
**End and Call** saves the first call and starts the second. Calling the same bot again just opens
its call. If a bot rings you during a call, answering ends the current call first; on desktop the
banner's answer button says **End and Answer**.

### When the bot works on something during a call

Ask for something bigger on a call ("book the dentist", "find a flight on Friday") and the bot
starts it as a task in the chat and keeps talking with you.

- A **Working on it** card and a strip under the bot's name ("Working on: find a flight · 0:42")
  stay while it runs. Tap the strip to watch it.
- The call doesn't hang up for quiet while a task runs or waits for you.
- When the task finishes, fails or needs you, the bot tells you, waiting until nobody is speaking.
  If it needs your OK, **Allow** and **Not now** are right on its card.
- **Watch it work:** when the task uses the bot's computer, a small live picture of its screen
  appears on the call (beside the call on wide windows). Tap it to see the screen full size and
  take over; the call carries on in the bubble, and tapping the bubble brings you back. The small
  picture updates once a second; video only starts when you open it full size.
- Say **"stop that"** to stop what the bot started on this call, or **"show me"** to see its screen.
- After you hang up, the chat shows a short recap: how long the call was and what was started on
  it, each with a link to what it did.

### Calls with the screen off

A call carries on like a phone call when you lock the phone or switch apps.

- **iPhone:** the call shows in the green pill and on the lock screen, like any call. Mute and end
  it from there, or with your AirPods or headset buttons. (In mainland China, where Apple doesn't
  allow this, the call still carries on in the background without the lock screen controls.)
- **Android:** a call notification shows the bot, the call's length, **Mute** and **End Call**.
  Tap it to go back to the call.
- **iPhone lock screen and Dynamic Island:** the call also shows there with the bot, the
  timer and what the bot is working on. On iOS 17 and later it has **Mute** and **End Call**; tap
  it to go back to the call.
- **Mac menu bar:** the menu bar shows the bot's name and the call's length. Its menu has the
  call at the top, with **Mute**, **End Call** and **Show Call**.
- **Another call comes in** (a phone call, FaceTime, Siri or an alarm): your call goes on hold.
  The bot waits quietly, and when you're back it carries on. The timer reads "On hold" meanwhile.
- **Unplugging headphones** moves the call to the speaker; it doesn't stop.
- **Changing networks** (leaving Wi-Fi) shows "Reconnecting" for a moment, then the call goes on.
- **On the web**, the call keeps going in a background tab, and the tab's title shows "On a call"
  with the time.
- Swiping the app away ends the call. What was said is already saved.

A call in an existing chat knows how that chat went: the bot hears its last few messages (typed or
spoken; up to 20, about 600 tokens, long ones cut short) before it picks up, so you can carry on
where you left off.

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
- The bot keeps the start of its persona (the first 1,500 characters) and a small set of tools
  suited to talking: memory, knowledge, web search, notes to you, reminders and routines, tickets,
  usage and your device data. Each tool call runs with the bot's normal approvals. If an action
  needs your approval, the bot tells you, and you approve it in the app.
- For bigger jobs, anything that needs its computer, files, the browser or connected apps, the bot
  starts the task in the chat and tells you. It runs in the background with all the bot's tools, and
  the result appears in the conversation. Changing or deleting a routine and watching something
  for changes go the same way.
- On a long call the bot keeps the last few minutes in mind: after about five minutes of talk, the
  oldest part is dropped. Everything said is still saved to the chat.
- To let the bot use specific connected-app tools live, such as creating a GitHub issue while you
  talk, open the bot's settings → **Voice** → **Tools on calls** and tick them. Each tool you add
  goes with every call, so it adds a little to each call's cost; pick only the ones you'll use by
  voice.
- A call with no speech from either side for 2 minutes ends by itself, so a forgotten call doesn't
  keep running.
- The bot can hang up too: say goodbye or "that's all" and it says goodbye and ends the call once
  it has finished speaking. An older app version can't, so the bot asks you to tap **End Call**.
- On Gemini Live, **Usage** records what the call actually cost, from the token counts Gemini
  reports; other calls are estimated by the minute.
- You can interrupt. When you start speaking, the bot stops talking and listens.
- The call's transcript is saved to the conversation as you talk, a turn at a time, so nothing is
  lost if the app closes or crashes. If the app goes away mid-call (swiped away, out of battery, no
  network for good), the server ends the call after 2 minutes and records its real length.
- Screen tools, such as clicking around the bot's desktop, aren't offered during a call.

## Start a call with a wake word

On desktop and Android, say a phrase to start a live call with a chosen bot.

1. Open **Settings** → **Wake word**.
2. Turn on **Listen for the wake word**.
3. Set the **Phrase**: two or three words, such as "hey casama".
4. Choose **Call this bot**.

The first time, the app downloads an open-source on-device model, about 18 MB. Listening happens
only on your device while Casama is open. Nothing is sent anywhere until the call starts. The wake
word stops listening while you're on a call and starts again when the call ends.

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

- Live calls run on Gemini Live only; other realtime voice providers aren't supported.
- On Gemini Live, use headphones on desktop computers if the bot seems to hear itself: echo
  cancellation depends on the device.
- The wake word isn't available on iOS or on the web, and on Android it listens only while the app
  is open.
- Bots can't phone other numbers, such as a business, yet.
- Provider connections follow each provider's public docs and have been tested against stand-ins,
  not yet against every live provider.

## Related

- [Chat](/guide/chat)
- [Attention and notifications](/guide/attention)
- [Autonomy and approvals](/guide/autonomy)
- [Usage and budgets](/guide/usage)
- [Chat apps](/guide/chat-apps)
