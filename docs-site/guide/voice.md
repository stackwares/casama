# Voice and calls

Talk to your bots instead of typing. Dictate messages, have replies read aloud, call a bot live,
let a bot ring your phone when something needs you, and have a bot phone a business for you. Voice
runs on your workspace's own provider keys.

## Which keys you need

Add keys in **Settings** → **Model keys** → **Add key**.

| Feature                      | Needs                                                                             |
| ---------------------------- | --------------------------------------------------------------------------------- |
| Dictation                    | An OpenAI or Deepgram key                                                          |
| Read aloud                   | An ElevenLabs, OpenAI, Cartesia or Fish Audio key                                  |
| Live calls                   | An OpenAI key (OpenAI Realtime)                                                    |
| Bot rings your phone         | An OpenAI key for the call, plus push set up on the server for iOS and Android     |
| Bot calls a business for you | An OpenAI key and the workspace's Twilio account                                   |
| Wake word                    | No key: it runs on your device                                                     |

Every minute, second or character of voice is recorded in [Usage](/guide/usage). The provider bills
your own account.

## Dictate a message

1. In a chat, tap **Dictate** in the message box. Allow microphone access the first time.
2. Speak, then tap **Stop and transcribe**.
3. The text lands in the message box. Edit it if you like, then send.

Dictation uses OpenAI (`gpt-4o-mini-transcribe`) or Deepgram (`nova-3`).

## Have a reply read aloud

Open a bot message's actions and choose **Read aloud**. Audio is saved per message and voice, so
replaying it doesn't call the provider again.

## Choose a bot's voice

1. Open **Bot settings** → **Voice**.
2. Pick a **Read-aloud provider**: ElevenLabs, OpenAI, Cartesia or Fish Audio.
3. Optionally enter a **Voice id** from that provider. Leave it empty for a default voice.
4. Pick a **Dictation provider**: OpenAI or Deepgram.
5. Tap **Save**.

**Automatic (first key found)** uses whichever matching key the workspace has.

## Call a bot live

1. In a chat, tap **Start a voice call** (the phone icon in the header).
2. Wait for **Live**, then talk. Use **Mute** and **Hang up** as on a phone call.

What to know:

- The bot keeps its persona and tools. Each tool call runs with the bot's normal approvals. If an
  action needs your approval, the bot tells you, and you approve it in the app.
- You can interrupt. When you start speaking, the bot stops talking and listens.
- The call's transcript is saved to the conversation.
- Screen tools, such as clicking around the bot's desktop, aren't offered during a call.
- Tap **Avatar** to show an animated version of the bot's avatar. It breathes while listening and
  moves while the bot speaks. It follows your reduced-motion setting, and the choice is remembered
  on the device.

## Start a call with a wake word

On desktop and Android, say a phrase to start a live call with a chosen bot.

1. Open **Settings** → **Wake word**.
2. Turn on **Listen for the wake word**.
3. Set the **Phrase**: two or three words, such as "hey kasama".
4. Choose **Call this bot**.

The first time, the app downloads an open-source on-device model, about 18 MB. Listening happens
only on your device while Kasama is open. Nothing is sent anywhere until the call starts.

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

`APNS_VOIP_TOPIC` defaults to `com.kasama.app.voip`. Without these, desktop and web still ring
through the banner while the app is open. See [Configuration](/self-hosting/configuration).

## Let a bot call a business for you

A bot can phone a business for you, for example to book a table or ask about an order. It uses your
workspace's own Twilio account.

### Set it up

Admins connect Twilio once:

1. Open **Settings** → **Workspace settings** → **Phone calls**.
2. Enter the **Account SID**, **Auth token** and the number **Calls come from**.
3. Optionally change **Calls per day** (default 10) and turn on **Allow calling personal numbers**.
4. Tap **Save**. Kasama checks the account before saving.

### What happens on a call

1. The bot asks to place the call, with the number and purpose. Placing a call is a high-risk
   action, so under the default autonomy it always asks first.
2. You get a notification when the call starts. Open it to see the live transcript.
3. The bot introduces itself as an AI assistant calling on your behalf. It never pretends to be a
   person.
4. When it's done, the bot says goodbye and hangs up. It gets the full transcript and how the call
   ended, and reports back in the chat.

While the call is live you can:

- **End call** to hang up right away.
- **Take over** to have the call redirected to your own phone. Enter **Your phone number** in
  international format, such as `+13125550123`, or leave it empty to use the one you saved before.

### Call rules

- Numbers must be in international (E.164) format.
- Emergency and short numbers are never called.
- Numbers on the server's deny list are refused. Kasama Cloud keeps one.
- Each workspace has a daily cap (default 10).
- Business numbers only, by default. A number Twilio's lookup reports as personal is refused unless
  an admin turned on **Allow calling personal numbers**. Lookup mostly covers US numbers, so numbers
  of unknown type are allowed.
- Recording is always off.
- A call waits up to 20 minutes for the conversation to end.

Each call's minutes, rounded up, are recorded in [Usage](/guide/usage). Twilio bills your account.

## Limits

- Live calls need OpenAI. Other realtime voice providers aren't supported.
- The wake word isn't available on iOS or on the web, and on Android it listens only while the app
  is open.
- When a bot calls a business, you can follow the live transcript but can't listen to the audio yet.
- Calls for you work only with your own Twilio account. Kasama-provided phone numbers aren't
  offered.
- The avatar is a 2D animation of the bot's picture. A lip-synced 3D avatar isn't built.
- Provider connections follow each provider's public docs and have been tested against stand-ins,
  not yet against every live provider.

## Related

- [Chat](/guide/chat)
- [Attention and notifications](/guide/attention)
- [Autonomy and approvals](/guide/autonomy)
- [Usage and budgets](/guide/usage)
- [Chat apps](/guide/chat-apps)
