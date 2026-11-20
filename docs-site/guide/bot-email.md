# A bot's email address

Every bot can have its own email address, like `ada@example.com`. Give it one and people can
write to it by email; it reads the mail and answers in the same thread, with files. Forward it
anything: bills, bookings, newsletters. Each thread also shows up as a chat in the Casama app.

This is a Casama Cloud service. Nothing to set up: no account, no DNS, no webhook. (Self-hosted
servers keep the [bring-your-own email chat app](/guide/chat-apps), where the address lives on
your own domain.)

## Claim an address

Open the bot, then **Bot profile** → **Email address**, and pick a name. Or just ask the bot to
get itself an address: it proposes a name and you approve the full address before anything is
claimed.

A few rules:

- One address per bot. A workspace has as many as its plan allows.
- Names are first come, first served across all of Casama Cloud.
- **A name can't be changed later**, and a released name is never given out again. Pick carefully.
- The address is for the bot: there's no login for it, and you can't use it as your own mailbox.

Right after claiming, the bot sends you a welcome mail from its new address. Reply to it, or
forward it something, and watch the thread appear as a chat.

## Who gets answers

A bot only answers mail from you and the people on its **Allowed senders** list. Mail from anyone
else is kept and shown, but starts nothing: no run, no reply. Add people under **Bot profile** →
**Email address** → **Allowed senders**, or tap **Allow** on their mail in the chat app's
Activity.

Senders are checked, not trusted on their word. A mail counts as its sender only when the
sender's domain confirms it; one that claims an allowed address without confirmation is treated
as a stranger. If you forward from a second address (a work address, say), add that address too,
or the bot stays silent.

Automatic mail — bounces, out-of-office replies, mailing lists — is never answered.

## Pause, move and release

- **Pause** stops the bot answering and sending; mail is still received and kept.
- **Move** gives the address and its mail to another bot in the workspace.
- **Release** stops receiving for good. Its mail is deleted after 30 days, and the name is never
  given out again. You can always release; a workspace can claim at most its plan's
  address limit plus 3 addresses a year.

Deleting the bot retires its address the same way.

## Routines on mail

A routine with a **Messages** trigger can watch the address: file receipts mailed to
`ada+receipts@example.com`, or send you one digest of the week's newsletters. The `+tag` part is
just a label: anyone can use any tag. Routines hear only confirmed senders unless you let them
hear everyone.

## Writing to new people

Ask the bot to write to someone new and it shows you the whole mail first: every recipient, the
subject and the text. You approve once per mail, at every autonomy level. Their replies come back
into the same chat. A first mail to someone new ends with one line saying what it is.

Mail to new people has daily limits (see [Limits](/guide/limits)), and the Free plan can't send
any. Mail that bounces or is reported too often pauses the address on its own; the instance owner
can lift the pause from Admin. Someone who answers "stop" or "unsubscribe" gets no more mail
from that address.

## Signing up for services

A bot can sign up for things with its own address and read the verification code itself: ask it
to, approve the sign-up, and it calls out when the code arrives. Never use a bot's address as the
recovery address for a bank, a domain registrar or an admin account.

## Storage and deleting mail

The Mail screen shows how full the mailbox is, such as **312 MB of 500 MB**. A mail counts with
its original and its attachments. Thirty days after a mail arrives, its original copy is deleted;
the text and attachments stay, and the space comes back.

To make room, delete mail yourself:

- **One mail:** open it and tap **Delete**.
- **Several, or whole threads:** **⋯ → Select**, pick them (or long-press a thread), then
  **Delete**.
- **Old mail:** **⋯ → Delete older mail**, then older than 30 days, 6 months or a year.

Deleted mail is gone for good. Files the bot already put into a chat stay in that chat. Bots
can't delete mail. Deleting doesn't reset the daily sending limit.

You get a notice when the mailbox is 90% full. When it's full, new mail is refused until you
delete some or upgrade.

## Limits

| | Free | Plus | Pro | Max |
| --- | --- | --- | --- | --- |
| Addresses per workspace | 1 | 2 | 5 | 15 |
| Mail a day | 20 | 50 | 150 | 300 |
| Mail to new people a day | none | 10 | 30 | 100 |
| Mailbox per address | 100 MB | 500 MB | 1 GB | 2 GB |

See [Limits](/guide/limits) for the rest. Mail-started runs spend the owner's credits like any
run; sending itself isn't charged. Casama Cloud also caps how much mail all workspaces send
together in a day; when that's reached, a send fails with "Mail is busy right now" and works
again a few hours later.
