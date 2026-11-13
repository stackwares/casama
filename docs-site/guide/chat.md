# Chatting with a bot

A chat is where you give a bot work and see it happen: its replies, each step it takes, the files
it makes and any questions it has for you. Each bot keeps its own conversations, and what it learns
in one chat it can recall in the others.

## Start a conversation

1. Select a bot in the sidebar (on a phone, tap it in **Chats**).
2. Type in the message field and send.

Opening a bot takes you to your **General** chat with it. That's where you talk day to day, and
where the bot reaches out: morning briefs, routine results and suggestions land there.

Work that needs its own space runs in a **topic**:

- **Do it** on a suggestion opens a topic where the bot does the work, then posts a one-line
  result back in General with a link to the topic.
- To start a topic yourself, select **New topic**.
- Topics with something going on show as chips at the top of General. **Needs you** comes first,
  then those the bot is working on.
- **All topics** lists every one. Topics idle for a week move under **Older**.
- Inside a topic, the **General** chip takes you back.

New topics get a title from their first messages.

Long chats stay quick and cheap: once a chat's history passes about 16,000 tokens, the bot keeps
the most recent part word for word and a summary of the rest.

An open chat stays live on every device. A message you send from your phone shows up, with the
bot's reply streaming in, on your laptop with the same chat open, and the same goes for a teammate
in a shared chat or a routine that posts into it. The bot list updates live too, so a bot made on
one device appears on the others.

On the desktop and the web, **Enter** sends and **Shift+Enter** starts a new line. On phones, use
the send button.

## While the bot works

A bot first says in one short line what it's about to do, then works without running commentary.
Each tool it uses (a command, a file, the browser, a web search) shows as a step in the chat, and
longer runs collapse earlier steps behind **Show … earlier steps**. Any text the bot writes
between steps stays in the thread as its own message.

- **Stop** ends the current run. It shows in place of **Send** while the message field is empty.
  A stopped request stays stopped: the bot won't pick it back up on your next message unless you
  ask again.
- **Activity** (in the **More** menu) lists every run of the bot. Each run opens a
  **Run timeline** with every event, its cost and tokens.
- If a run fails, the chat says why in plain words, with **Details** and **Open run timeline**.
- If a run uses all its steps or time, the bot still replies with what it got done, what blocked
  it and what it suggests.
- Ask a bot what it's doing from another chat and it knows about its work elsewhere.

### Send more while it works

You don't have to wait. In a chat with one bot, start typing while it works and **Stop** turns
into **Send**. Your message joins the run in progress: before its next step the bot reads it,
marked as sent while it was working, and decides whether to fold it in, switch to it, or finish
first. If the run ends before it sees your message, the message gets its own follow-up run.

Group chats work differently: every message there starts new runs for the bots it wakes. See
[Group chats](/guide/group-chats).

## Attach files

1. Select **Attach**, then **Files**, **Photo library** or **Take photo**. On the desktop and the
   web you can also drop files onto the chat.
2. Files upload straight away to `~/workspace/uploads` on the bot's computer. Send waits until
   they finish.
3. Write your message and send.

| Rule | Limit |
| --- | --- |
| Files per message | 10 |
| Size of one file | 25 MB |
| Images also shown to vision models | First 4, up to 5 MB each |

Every model sees the list of attached files (path, name, type and size) and can open them on its
computer. **Photo library** is available on mobile and macOS, and **Take photo** on mobile. A bot
with no computer can't take attachments.

## Files the bot shares

When a bot makes a file, it links it by its path on the bot's computer, like
`[report.md](workspace/report.md)`. Those files appear under the reply: images (PNG, JPEG, GIF,
WebP) as thumbnails, and documents, data, code, archives, audio and video as file cards, up to 8
per reply.

Images and videos a bot generates show under its reply by themselves, even when the bot has no
computer. Videos on a bot's computer show a first frame and their length once the computer is
awake; looking at them never wakes a sleeping computer.

Tap a file to open the preview, then choose **Open**, **Save** or **Share**. Files without a
preview can still be opened or saved. Everything a bot makes on its computer also stays in its
**Files**; see [Computers](/guide/computers). If a bot's reply links to a file that isn't there,
Casama makes the bot fix the reply before you see it.

## Interactive cards

For choices and short forms, a bot can show an interactive card in the chat instead of asking you
to type: buttons, option chips, a few fields. The setup interview and the welcome chat use them.

- Tap a button or fill in the fields and submit. Your answer is sent as a normal message that sums
  up what you chose.
- A list of answers is lettered (A, B, C…). A card with two or more questions asks them one at a
  time: answer and tap **Next**, or **Skip**; the last step has the card's own button.
- An answered card stays in the thread, dimmed and marked **Sent**.
- A bot shows one card at a time and waits for your answer before going on.
- Links on a card open in your browser, and only for web addresses.
- If a card can't be drawn, you see "This part of the reply couldn't be shown."

Cards use the open A2UI protocol and are drawn natively by the app, in its own theme. Showing a
card never needs your approval.

## Use a skill with /

To make sure a bot follows a particular skill, attach it to your message.

1. Type `/` in an empty message field. The bot's enabled skills appear under **Attach a skill**.
2. Keep typing to filter, then pick a skill. It shows as a chip above the field.
3. Write your message and send.

The bot loads the skill's instructions before it starts. You can attach up to five skills to one
message. See [Skills](/guide/skills).

## Edit and resend

You can change a message you sent and rerun the conversation from that point.

1. Long-press your message (or right-click it with a mouse) and choose **Edit**.
2. Change the text and send. The bot answers the new version.

The original version and its replies are kept. Messages with more than one version show arrows
(**Previous version**, **Next version**) to switch between them. Attachments and skills from the
original come along. Only the shown version reaches the model.

Edit works on your own messages in chats with one bot, and not while a run is going.

## Message actions

With a mouse, hover over a message to see **Copy**, **Edit** (your own), **Read aloud** and
**Share** under it. Right-click adds them to the text menu. On a touch screen, long-press a
message: the bubble shrinks a little as you hold, then the menu opens.

| Action | What it does |
| --- | --- |
| **Copy** | Copies the text. |
| **Edit** | Your own messages only; see above. |
| **Read aloud** | Reads a reply with the bot's voice. See [Voice and calls](/guide/voice). |
| **Select text** | Opens the text so you can select part of it. |
| **Share** | Opens your system's share sheet. |

## Delete a chat

1. In the chat, open the **More** menu (**…**) and choose **Delete Chat**. You can also delete a
   chat from **All topics**: use its delete button, or long-press it. If you delete General, your
   most recent topic becomes General.
2. Confirm.

The chat's messages, photos and files are deleted for everyone who can see it. Usage records stay,
and anything the bot remembered from the chat stays in its memory. A deleted chat with one bot
starts fresh; a deleted group chat takes you back to your chats. You can't delete a chat while the
bot is working in it.

You can delete chats you started. People who manage a bot can delete any chat with it. To clear
everything at once, open the bot's profile and choose **Delete All Chats**; group chats and chats
the bot is busy in are left alone. Single messages can't be deleted; edit and resend instead.

## Routines in your chat

When you ask a bot in chat to do something later ("remind me in an hour", "every weekday at 9"),
it creates a routine without asking you first. The routine's results come back to that same chat,
with a notification. In the thread, a run started by a routine shows as **Routine "…" ran**
instead of a message from you.

Routines made in Settings, and morning briefs, post to your **General** chat with that bot. See
[Routines](/guide/routines).

## Search

Search finds messages, chats, memories, skills, routines, tickets and files across the workspace.

- **Desktop and web:** press **Cmd+K** (macOS) or **Ctrl+K**, or use the search button in the
  sidebar.
- **Phones:** the search button in the **Chats** header, next to **+**.

Before you type, search suggests where to go: **Recent** searches (kept on this device), **Jump
back in** with the bots you talked to last, **Needs you** when something is waiting in your inbox,
and **Go to** for Quick ask, Tasks, Skills and Settings.

From the first letter, matching bots and places show under **Top hits**. From two letters, the
server's results join them, grouped by type. Tap a chip under the field (**All**, **Chats**,
**Memories**, **Skills**, **Routines**, **Tickets** or **Files**) to search only that kind; each
chip shows how many it found. If nothing matches, **Ask … about "…"** starts a Quick ask with the
bot you talked to last.

Results open the item itself: a message opens its chat scrolled to it, a memory opens its editor,
a routine is highlighted in its list, a ticket opens its sheet, and files open in the preview. On a
tablet or computer, use the arrow keys and **Enter** to open a result, and **Esc** to clear or
close. Search covers only bots and chats you can see.

File search looks at names and contents under `~/workspace` on up to three computers that are
awake. Sleeping computers aren't woken for a search; start one to include its files. With
encryption at rest turned on, search matches titles and meaning, not exact words in encrypted
text. See [Privacy and security](/guide/privacy).

## Shortcuts

| Shortcut | Where | What it does |
| --- | --- | --- |
| **Cmd+K** / **Ctrl+K** | Desktop and web app | Opens search. |
| **Cmd+Shift+K** / **Ctrl+Shift+K** | Desktop app, anywhere on the computer | Opens **Quick ask**: a quick request that starts a new chat with the bot you pick. |
| **Ask a bot**, **Run a routine** | Siri, Spotlight and Shortcuts on iOS 16 and macOS 13 or later | Asks a bot a question, or runs a routine and opens the chat where its results arrive. |
| **Quick ask**, **Ask …**, **Run …** | Long-press the app icon on Android | Quick ask, ask one of your first two bots, or run your first routine. |

## Offline

The mobile and desktop apps keep a copy of what they've shown you: your workspaces, your bots, and
the last 100 messages of each chat you've opened. Chats open instantly from this copy and refresh
from the server.

When you're offline, the app still opens and stays signed in. Saved bots and messages stay
visible, and the chat shows **Offline. Showing saved messages.** with **Try again**. Interactive
cards aren't saved. The copy is deleted when you sign out.

## Limits

- The web app keeps no offline copy.
- Edit and resend works only in chats with one bot. In group chats, messages are kept in one line.
- Skills you pick with `/` don't come along on a message you send while the bot is working.
- A conversation summary made before an edit (long chats are summarized as they grow) may still
  mention the other version.
- Siri phrases need iOS 16 or macOS 13; older systems don't offer them.

## Related

- [Bots and models](/guide/bots)
- [Group chats](/guide/group-chats)
- [Skills](/guide/skills)
- [Routines](/guide/routines)
- [Autonomy and approvals](/guide/autonomy)
