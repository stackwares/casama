# Chat apps

Chat apps let people reach a bot from the messaging tools they already use: Telegram, email, SMS,
Slack, WhatsApp, Messenger, Feishu and iMessage. The bot answers in the same thread, and every
conversation also shows up in the Casama app.

## How it works

- Each chat app is connected to one bot.
- A bot only answers people on the chat app's **Allowed senders** list. Messages from anyone else
  get no reply and are logged in the chat app's **Activity** as "Ignored: not on the allowed list".
- Each outside thread becomes one Casama conversation, titled with the app and the sender or
  subject, such as "Telegram: Ana". Follow-up messages in that thread continue the same
  conversation.
- Each message reaches the bot prefixed with where it came from, such as
  `(Telegram, from Ana)`, and starts a run. When the run finishes, its final reply goes back to
  the thread.
- The conversation belongs to the person who connected the chat app, and runs act for them. That
  person sees these chats in the app.

## Connect a chat app

You need to manage the bot to connect a chat app.

1. Open the bot, then **Bot profile** → **Chat apps**.
2. Tap **Connect a chat app**.
3. Choose the **App** and give the connection a **Name**.
4. Paste the credentials from the app's developer settings (see the table below). They're stored
   encrypted and never shown again.
5. Under **Allowed senders**, add one per line: email addresses (or `*@example.com` for a whole
   domain), phone numbers, or user ids.
6. Tap **Add**.
7. Casama shows the **Webhook address**. Paste it into the app's webhook settings. Telegram is the
   exception: Casama sets its webhook for you.

| App       | What you paste                                                                  | Where the webhook goes                                     |
| --------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Telegram  | **Bot token** from @BotFather                                                   | Set automatically                                          |
| Email     | **Email address**, Resend **API key**, and the webhook's **Signing secret**     | A Resend inbound webhook for received email                |
| SMS       | Twilio **Phone number**, **Account SID** and **Auth token**                     | The number's incoming-message webhook in Twilio            |
| Slack     | **Bot token** and **Signing secret**                                            | Event Subscriptions request URL, subscribed to messages    |
| WhatsApp  | **Phone number ID**, **Access token** and **App secret** from the Cloud API      | Meta webhook callback URL, with the **Verify token**       |
| Messenger | **Page access token** and **App secret**                                        | Meta webhook callback URL, with the **Verify token**       |
| Feishu    | **App ID**, **App secret**, **Encrypt key** and **Verification token**          | The app's event subscription request URL                   |
| iMessage  | Nothing; pick your **Mac**                                                      | None                                                       |

For WhatsApp and Messenger, Casama generates a **Verify token** for Meta's setup and shows it once,
right after you connect. Copy it then.

Each app's requests are checked before anything happens: Telegram's secret token, the Svix-style
signature on email, Twilio's signature on SMS, Slack's signed requests, Meta's
`X-Hub-Signature-256`, and Feishu's request signature. A request that fails the check is refused.

::: tip
Not sure what a sender's id looks like? Ask them to message the bot first. The message shows in
**Activity** as ignored, with their id. Add that id to **Allowed senders**.
:::

## Allowed senders

Matching is exact and ignores case. `*@example.com` matches any email address at that domain.

| App       | Use                                                                    |
| --------- | ---------------------------------------------------------------------- |
| Telegram  | The person's numeric Telegram user id                                  |
| Email     | Their email address, or `*@example.com`                                |
| SMS       | Their phone number in international format, such as `+13125550123`     |
| Slack     | Their Slack user id                                                    |
| WhatsApp  | Their WhatsApp number as Meta sends it: digits only, no `+`            |
| Messenger | Their page-scoped sender id                                            |
| Feishu    | Their open id                                                          |
| iMessage  | The phone number or email address they message from                    |

To change the list later, tap the chat app on the **Chat apps** screen, edit **Allowed senders**
and tap **Save**.

## Threads and replies

| App       | One conversation per                                         | How the reply goes back                       |
| --------- | ------------------------------------------------------------ | --------------------------------------------- |
| Telegram  | Chat                                                         | A message in the same chat                    |
| Email     | Sender plus subject (`Re:` and `Fwd:` are ignored)           | A reply email with `Re:` and threading headers |
| SMS       | Phone number                                                 | A text message                                |
| Slack     | Slack thread                                                 | A reply in that thread                        |
| WhatsApp  | Phone number                                                 | A WhatsApp message                            |
| Messenger | Sender                                                       | A Messenger message                           |
| Feishu    | Chat                                                         | A message in the same chat                    |
| iMessage  | Handle                                                       | An iMessage from your Mac                     |

Long replies are cut to each app's message limit: 4,096 characters on Telegram and WhatsApp, 2,000
on Messenger and 1,600 on SMS.

If a reply can't be sent, the error shows on the chat app in the list and in its **Activity**.

## Bots sending first

A bot can start a new message through one of its chat apps, for example to tell you a long job is
done. It can only message people on that chat app's allowed list, and sending is a high-risk action,
so under the default autonomy it asks you first. See [Autonomy and approvals](/guide/autonomy).

## Routines on messages

A routine can start when a matching message arrives, even from someone who isn't on the allowed
list. For example, a routine can file every invoice a vendor emails, although the vendor can't chat
with the bot. Filter by chat app, sender (`*@example.com` works), subject or message text. A message
that starts a routine isn't also answered. In the routine sheet, choose **Messages**. See
[Routines](/guide/routines).

## iMessage

iMessage has no bot API, so your own Mac does the work through the desktop app.

1. On your Mac, open the desktop app and turn on **Use this computer for bots**.
2. Under **What bots may do**, allow **Messages (iMessage)**.
3. Give the desktop app Full Disk Access in macOS System Settings, so it can read Messages.
4. In the bot's **Chat apps**, connect **iMessage** and pick your **Mac**.

Your Mac reads new messages and sends replies through Messages. Casama checks for new messages every
minute. The first check only takes a starting point, so old messages are never answered. Only the
Mac's owner can connect it, and only bots allowed on that Mac can use it. See
[Your own computer](/guide/companion).

## Manage a chat app

On the **Chat apps** screen:

- Use the switch next to a chat app to turn it off and on.
- Tap a chat app to see its **Webhook address**, edit **Allowed senders**, and read its
  **Activity**: answered, sent, started a routine, ignored or failed.
- Tap **Disconnect** to remove it. Its saved credentials are deleted.

## Limits

- Text only: attachments and images aren't passed on yet.
- Slack and Feishu don't have one-click app installs yet. Paste a bot token instead.
- Group chats on WhatsApp and iMessage aren't supported.
- iMessage needs your Mac to be on, with the desktop app running.
- The adapters follow each provider's public docs and have been tested against stand-ins, not yet
  against every live provider.
- If your server sits behind a proxy, set `PUBLIC_API_URL` so signatures and webhook addresses use
  your public address. See [Configuration](/self-hosting/configuration).

## Related

- [Chat](/guide/chat)
- [Routines](/guide/routines)
- [Your own computer](/guide/companion)
- [Autonomy and approvals](/guide/autonomy)
- [Voice and calls](/guide/voice)
