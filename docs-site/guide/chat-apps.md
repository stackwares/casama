# Chat apps

Chat apps let people reach a bot from the messaging tools they already use: Telegram, email, SMS,
Slack, WhatsApp, Messenger, Feishu, iMessage, Microsoft Teams and Discord. The bot answers in the
same thread, and every conversation also shows up in the Casama app. Linear and Jira work the same
way: assign an issue to the bot and it replies with a comment (see
[Give a bot a Linear or Jira issue](#give-a-bot-a-linear-or-jira-issue)).

## How it works

- Each chat app is connected to one bot.
- A bot only answers people on the chat app's **Allowed senders** list. Messages from anyone else
  get no reply and are logged in the chat app's **Activity** as "Ignored: not on the allowed list".
- Each outside thread becomes one Casama conversation, titled with the app and the sender or
  subject, such as "Telegram: Ana". Follow-up messages in that thread continue the same
  conversation.
- Each message reaches the bot prefixed with where it came from, such as
  `(Telegram, from Ana)`, and starts a run. When the bot says something before it starts working
  ("On it, cropping now."), that line goes to the thread straight away; when the run finishes,
  its final reply follows.
- If an app delivers the same message twice (Slack retries after a few seconds, for example), the
  bot answers it once.
- The conversation belongs to the person who connected the chat app, and runs act for them. That
  person sees these chats in the app.

## Connect a chat app

You need to manage the bot to connect a chat app.

1. Open the bot, then **Bot profile** → **Advanced** → **Chat apps**.
2. Tap **Connect a chat app**.
3. Choose the **App** and give the connection a **Name**.
4. Paste the credentials from the app's developer settings (see the table below). They're stored
   encrypted and never shown again.
5. Under **Allowed senders**, add one per line: email addresses (or `*@example.com` for a whole
   domain), phone numbers, or user ids. You can leave it empty and add people later; until then
   the bot answers nobody.
6. Tap **Add**.
7. Casama shows the **Webhook address**. Paste it into the app's webhook settings. Telegram is the
   exception: Casama sets its webhook for you.

| App       | What you paste                                                                  | Where the webhook goes                                     |
| --------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Telegram  | **Bot token** from @BotFather                                                   | Set automatically                                          |
| Email     | **Email address**, Resend **API key**, and the webhook's **Signing secret**     | A Resend inbound webhook for received email                |
| SMS       | Twilio **Phone number**, **Account SID** and **Auth token**                     | The number's incoming-message webhook in Twilio            |
| Slack     | **Bot token** and **Signing secret**                                            | Event Subscriptions request URL, subscribed to `message.im`, `app_mention`, `reaction_added` and `reaction_removed` |
| WhatsApp  | **Phone number ID**, **Access token** and **App secret** from the Cloud API      | Meta webhook callback URL, with the **Verify token**       |
| Messenger | **Page access token** and **App secret**                                        | Meta webhook callback URL, with the **Verify token**       |
| Feishu    | **App ID**, **App secret**, **Encrypt key** and **Verification token**          | The app's event subscription request URL                   |
| iMessage  | Nothing; pick your **Mac**                                                      | None                                                       |
| Microsoft Teams | The Azure bot's **App ID** and client secret (**App secret**)             | The Azure bot's messaging endpoint                         |
| Discord   | **App ID** (application id), **Public key** and **Bot token**                   | The application's Interactions Endpoint URL                |
| Linear    | **The bot's user ID in the tracker**, an **API key** and the webhook's **Signing secret** | A Linear webhook for issues and comments           |
| Jira      | **Site address (https://…)**, **Account email**, **The bot's user ID in the tracker**, an **API key** (API token) and the webhook's **Signing secret** | A Jira webhook for issue created, issue updated and comment created |

For WhatsApp and Messenger, Casama generates a **Verify token** for Meta's setup and shows it once,
right after you connect. Copy it then.

Each app's requests are checked before anything happens: Telegram's secret token, the Svix-style
signature on email, Twilio's signature on SMS, Slack's signed requests, Meta's
`X-Hub-Signature-256`, Feishu's request signature, Microsoft's signed token on Teams, Discord's
Ed25519 signature, `Linear-Signature` and Jira's `X-Hub-Signature`. A request that fails the check
is refused. Feishu must have an encrypt key set; Casama decrypts its messages.

::: tip
Not sure what a sender's id looks like? Connect with **Allowed senders** empty, then ask them to
message the bot. The message shows in
**Activity** as ignored, with their id. Tap **Allow** on it to add them to **Allowed senders**.
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
| Microsoft Teams | Their Microsoft Entra object id                                  |
| Discord   | Their Discord user id                                                  |
| Linear    | Their Linear user id                                                   |
| Jira      | Their Atlassian account id                                             |

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
| Microsoft Teams | Teams chat or channel conversation                     | A reply in the same conversation              |
| Discord   | Channel                                                      | A reply to the `/ask` command, or a channel message after 15 minutes |
| Linear    | Issue                                                        | A comment on the issue                        |
| Jira      | Issue                                                        | A comment on the issue                        |

Replies are sent in each app's own format, so bold, links, lists and code show properly instead
of raw `**` and `#`: Telegram and email get rich text, Slack and WhatsApp their own marks, Jira
its document format, and SMS, iMessage, Messenger and Feishu clean plain text with links written
as "text (url)". Discord, Teams and Linear show Markdown as it is. Tables become aligned text
where the app has none.

While the bot works, Telegram and Messenger show it typing. In Telegram, an 👀 reaction on your
message shows it arrived (Slack gets the same with an eyes reaction).

Long replies are sent in parts, split at a paragraph, line, sentence or word, so nothing is cut
off. Each part fits the app's limit: 1,600 characters on SMS, 2,000 on Messenger and Discord,
4,096 on Telegram and WhatsApp, 10,000 on Feishu, 25,000 on Teams, 39,000 on Slack, 30,000 on Jira
and 50,000 on Linear.

## Files, photos and voice notes

Files go both ways, as in the Casama app.

- **From the bot:** images, video, audio and files a reply carries go into the chat after the
  text, as photos, videos and documents where the app has them. That covers media the bot makes
  and files from its computer that the reply links to. With one file and a short reply, the text
  goes as the file's caption. A reply sends up to 10 files.
- **When an app can't take a file** (too big, a type it refuses, or more than 10), the bot sends a
  link to it instead, with its name and size. SMS sends pictures up to 5 MB by MMS and everything
  else as a link. Teams shows pictures up to 1 MB in the chat and sends other files as links.
- **To the bot:** photos, files and voice notes people send are saved like attachments in the app,
  so the bot can look at a picture or read a PDF. Each file can be up to 25 MB (Telegram's own
  limit for bots is 20 MB), up to 10 per message, and they count against the daily attachment
  allowance (300 files and 1 GB) of the person who connected the chat app. A file that can't come
  through still reaches the bot as a note saying which file and why. Stickers, locations and
  contacts aren't passed on yet.
- **Voice notes** are also turned into text when the workspace can transcribe, so the bot answers
  what was said.
- **On Discord**, give the slash command an optional attachment option to send the bot a file.

The bot is told which chat app it's in, and that its files are delivered there.

**About links:** a file link works for anyone who has it, without signing in, for 7 days. It only
ever goes to the chat it was made for. Deleting the file in Casama stops its links working.

If a reply can't be sent, the error shows on the chat app in the list and in its **Activity**.

## Reactions

Reactions go both ways in Telegram, Slack and WhatsApp:

- **In:** when someone on the allowed list reacts to a message in the chat app, the reaction shows
  on that message in the Casama chat, under their name in the chat app. The bot sees it the next
  time it works in the chat. Taking it back there takes it back in Casama. Reactions to messages
  sent before this feature came aren't matched.
- **Out:** when the bot reacts to a message, the reaction is added to the same message in the chat
  app. Telegram allows only its own set of reaction emoji: 😂 is sent as 🤣 and 😮 as 😱, and an
  emoji with nothing close isn't sent there (it still shows in Casama).

Notes for each app:

- **Telegram:** in groups, reactions reach the bot only when it is an admin. Chat apps connected
  before reactions came are switched over the next time a message arrives.
- **Slack:** your own Slack app needs the `reactions:read` scope and the `reaction_added` and
  `reaction_removed` bot events. Casama's Slack app asks for them; workspaces that installed it
  before need to install it again.
- **WhatsApp:** reactions come in as WhatsApp's reaction messages; nothing to set up.

Discord, Messenger, Teams, Feishu, iMessage, email, SMS, Linear and Jira don't pass reactions.

## Bots sending first

A bot can start a new message through one of its chat apps, for example to tell you a long job is
done. It can only message people on that chat app's allowed list, and sending is a high-risk action,
so under the default autonomy it asks you first. See [Autonomy and approvals](/guide/autonomy).

## Routines on messages

A routine can start when a matching message arrives. Filter by chat app, sender (`*@example.com`
works), subject or message text. Without a sender filter, a routine only hears people on the chat
app's allowed list. With one, it also hears that sender when they aren't on the list: for example, a
routine can file every invoice a vendor emails, although the vendor can't chat with the bot. A
message that starts a routine isn't also answered. In the routine sheet, choose **Messages**. See
[Routines](/guide/routines).

## Approvals in the chat

When a run started from Telegram or Slack needs your approval, the request is also posted in the
chat with **Approve** and **Deny** buttons. Only people on the chat app's allowed list can press
them; the decision counts as made by the person who connected the chat app, and the buttons are
replaced with who approved or denied it. The usual notification and the card in the app still
work. In Telegram there's nothing to set up: Casama asks Telegram for button presses itself.

## Slack

In Slack, people can message the bot directly or @mention it in a channel. The mention is removed
before the bot reads the message. An eyes reaction on the message shows it arrived.

When a run started from a Slack thread needs your approval, the request is also posted in that
thread with **Approve** and **Deny** buttons. Only people on the chat app's allowed list can press
them; the decision counts as made by the person who connected the chat app, and the message then
says who approved or denied it. The usual notification and the card in the app still work.

To use the buttons with your own Slack app, turn on **Interactivity** in the Slack app's settings
and set its request URL to the **Webhook address** followed by `/interact`. Give the bot token the
scopes `app_mentions:read`, `chat:write`, `files:read`, `files:write`, `im:history`, `im:read`,
`reactions:read` and `reactions:write`, and subscribe to the bot events `app_mention`, `message.im`, `reaction_added` and
`reaction_removed`.

### Install Casama's Slack app

A server can run its own Slack app, so people connect Slack with one click instead of pasting a bot
token. Whoever runs the server registers the Slack app and sets `SLACK_CLIENT_ID`,
`SLACK_CLIENT_SECRET` and `SLACK_SIGNING_SECRET`. The Slack app's addresses are, on the server's
public API address:

| Slack setting              | Address                |
| -------------------------- | ---------------------- |
| OAuth redirect URL         | `/hooks/slack/oauth`   |
| Event Subscriptions        | `/hooks/slack/events`  |
| Interactivity request URL  | `/hooks/slack/interact` |

`GET /v1/channels/slack/install?bot_id=…` returns Slack's sign-in address. After you approve it in
Slack, the chat app is made for that bot, with you on its allowed list. Each Slack workspace talks
to one Casama bot through the server's app; installing again for another bot moves it. Without
those settings the request answers that the server has no Slack app, and you connect your own
Slack app with a bot token as above. The app has no install button yet.

## Microsoft Teams

People message the bot in Teams chats and channels. In a channel, @mention it; the mention is
removed before the bot reads the message.

1. In Azure, create an Azure bot and a client secret for it.
2. In Casama, connect **Microsoft Teams** with the bot's **App ID** and the client secret as
   **App secret**.
3. Paste the **Webhook address** as the Azure bot's messaging endpoint, and add the Teams channel
   to the Azure bot.

## Discord

Discord only delivers ordinary messages to bots that keep a live connection open, which a webhook
server doesn't. So people talk to the bot through a slash command, such as `/ask`, with one text
option for the question.

1. In the Discord Developer Portal, copy the application's **Application ID** and **Public key**,
   and the bot's token.
2. In Casama, connect **Discord** with those as **App ID**, **Public key** and **Bot token**.
3. Paste the **Webhook address** as the application's **Interactions Endpoint URL**.
4. Register a slash command for the application with one string option.

Discord shows "thinking…" while the bot works. The reply answers the command if it's ready within
15 minutes, and otherwise arrives as a message in the channel.

## Give a bot a Linear or Jira issue

Connect Linear or Jira as a chat app and you can hand a bot an issue the way you would a teammate.

- **Assign an issue** to the tracker user that stands for the bot, or create it assigned. The bot
  starts work with the issue's title and description.
- **Comment** on an issue the bot holds to continue the conversation. Each issue is one Casama
  conversation, so the bot keeps the context.
- **The bot's reply** is posted as a comment on the issue. Changes the bot makes itself are
  ignored, so it doesn't answer its own comments.

People who assign issues or comment need to be on the **Allowed senders** list, by their Linear user
id or Atlassian account id.

### Linear

1. Create a Linear user for the bot and copy its user id. Create a personal **API key** for that
   user; the bot comments with it.
2. In Linear's settings, add a webhook for **Issues** and **Comments** pointing to the
   **Webhook address**, and copy its signing secret.
3. In Casama, connect **Linear** with **The bot's user ID in the tracker**, the **API key** and
   the **Signing secret**.

### Jira Cloud

1. Create an Atlassian account for the bot and an API token for it.
2. In Casama, connect **Jira** with your **Site address (https://…)**, the bot account's
   **Account email**, its account id as **The bot's user ID in the tracker**, the API token as
   **API key**, and a **Signing secret** you make up.
3. In Jira's system settings, add a webhook to the **Webhook address** with that secret, for issue
   created, issue updated and comment created.

The bot doesn't move the issue's status as it works; it says where things stand in its comment.

To have a bot use Linear or Jira as a tool instead (search issues, file new ones), connect the app
from [Apps and connections](/guide/connections).

## iMessage

iMessage has no bot API, so your own Mac does the work through the desktop app.

1. On your Mac, open the desktop app and turn on **Use this computer for bots**.
2. Under **What bots may do**, allow **Messages (iMessage)**.
3. Give the desktop app Full Disk Access in macOS System Settings, so it can read Messages.
4. In the bot's **Chat apps**, connect **iMessage** and pick your **Mac**.

Your Mac reads new messages and sends replies through Messages. Casama checks for new messages every
minute. The first check only takes a starting point, so old messages are never answered. Only the
Mac's owner can connect it, and only bots allowed on that Mac can use it. Photos and files go both
ways once the Mac has the latest desktop app; until then, the bot's files arrive as links. See
[Your own computer](/guide/companion).

## Manage a chat app

On the **Chat apps** screen:

- Use the switch next to a chat app to turn it off and on.
- Tap a chat app to see its **Webhook address**, edit **Allowed senders**, and read its
  **Activity**: answered, sent, started a routine, ignored or failed.
  Tap **Allow** on an ignored message to let that sender in.
- Tap **Disconnect** to remove it. Its saved credentials are deleted.

## Limits

- Feishu has no one-click install. Slack has one only on servers that run their own Slack app, and
  only through the API for now.
- Approval buttons are in Telegram and Slack only. Elsewhere, approvals arrive in the app as usual.
- On Discord, the bot hears only its slash command, not ordinary messages.
- Group chats on WhatsApp and iMessage aren't supported.
- iMessage needs your Mac to be on, with the desktop app running.
- The adapters follow each provider's public docs and have been tested against stand-ins, not yet
  against every live provider. Teams and Discord have been tested with signed test requests only.
- If your server sits behind a proxy, set `PUBLIC_API_URL` so signatures and webhook addresses use
  your public address. See [Configuration](/self-hosting/configuration).

## Related

- [Chat](/guide/chat)
- [Routines](/guide/routines)
- [Your own computer](/guide/companion)
- [Autonomy and approvals](/guide/autonomy)
- [Voice and calls](/guide/voice)
