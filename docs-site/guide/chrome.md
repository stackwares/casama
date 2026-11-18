# Casama for Chrome

Casama for Chrome connects your browser to your Casama bots. Ask a bot about the page you're on,
send it things to keep or work on, and answer what your bots need without opening the app. It
works in Chrome, and in browsers that install from the Chrome Web Store (Brave, Arc, Vivaldi,
Opera). It also comes for [Edge and Firefox](#edge-and-firefox).

It reads a page only when you ask: when you start a message about it, switch on a chip, use its menu or a shortcut, or save it. Switching tabs only updates the chips with the new tab's address and title. Nothing is read in the background, and nothing leaves your browser until you send or save.

## Install and sign in

1. Install **Casama** from the Chrome Web Store, then pin it to the toolbar from the puzzle-piece
   menu.
2. The extension's Settings open. Read what it sends and tap **Agree and continue**.
3. Choose where it may read pages (see [Site access](#site-access)). **On all sites** is
   recommended.
4. Sign in one of three ways:
   - **With the web app**: in [app.casama.ai](https://app.casama.ai), open **Sign In on Another
     Device** and tap **Connect Chrome**. The web app hands the sign-in to the extension.
   - **With a sign-in link**: in the app, tap **Sign In on Another Device**, copy the link and
     paste it into the extension.
   - **With an emailed code**: type your email address, then the six-digit code.

To use a self-hosted server, tap **Change** next to the server before signing in and enter its address. You can
add more accounts and servers later from the **Account** menu, and switch workspaces there too.

## The side panel

Click the Casama button in the toolbar, or press <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd>, to open
the side panel. It has four tabs.

### Chat

Pick a bot and a conversation at the top, type, and press <kbd>Enter</kbd>. The reply streams in,
with the bot's cards and buttons. **Stop** ends it. Under a reply, **Copy** copies it and **Read
aloud** plays it. Hover a message and click the smiley to react with one of six emoji; click a
reaction chip to add it, or yours to take it back (see [Reactions](/guide/chat#reactions)).

Above the box, chips show what goes with your message:

| Chip | What it sends | On by default |
|---|---|---|
| **Page** | The tab's address and title | Yes |
| **Selection** | The text you've selected, up to 8,000 characters | Yes |
| **Page text** | The page's readable text, up to 60,000 characters. On a PDF it's **PDF text**; on a YouTube video it's **Transcript**, with where you are in the video | No |
| **Screenshot** | What's visible in the tab | No |

Tap a chip to switch it on or off for this message; change the defaults in Settings. Once you
start writing, each chip shows its size, since a long page is a lot for a bot to read and uses more
credits. The selection chip appears then too, if you've selected something.

Add files with **Attach**, by pasting a picture, or by dropping files or images from the page onto
the panel. **Region** lets you drag a box over the page to send just that part. **Mic** writes down
what you say (Settings asks for the microphone once).

Under each message you sent, **What was sent** lists exactly what went with it, and links to the
run's timeline in the app.

More in the box:

- Type **/** for your [page commands](#page-commands) and the bot's skills; pick one to fill the box.
- Type **@** to add another open tab, or a whole tab group, to the message. Chrome asks once to let
  Casama see your tabs' titles; a tab is read only when you pick it.
- **Point** lets you click a table, a button or a part of the page to mean "this".
- When you've selected text and Chrome's built-in AI model is on your computer, **On this
  computer** offers Summarize, Explain and Translate. The answer is made on your computer and
  nothing is sent. Without the model, these don't appear.
- **Send less of long pages** (on by default in Settings) cuts a long page down, on your computer,
  to the parts that match your question before it's sent. "What was sent" says when it did.

**Call** at the top starts a live call with the bot while you look at the page. The bot knows the
page's address and title (when the Page chip is on), and what was said is saved to the
conversation when you hang up.

When you come back to a page you chatted about or highlighted, **This page before** says so. Tap
**Show** to list those chats and highlights; only then does the panel ask your server.

### Inbox

Today's brief, when your bot has written one, sits on top. Below it, what your bots need from you:
steps waiting for approval (**Approve**, **Deny** or **Always
allow**), secrets they asked for, suggestions, and runs in progress with **Stop**. The toolbar
button's badge counts what's waiting.

### Library

Save the page to the [Library](/guide/library) as **Markdown**, a **PDF** or a **Screenshot**, into
a project if you pick one. A PDF is a clean, readable copy of the page's text; pictures stay links. Below that, send the page to a bot: **Add page to knowledge**, **Add
whole site**, or **Make a task**. Saves made while you're offline wait and go once you're back.

### More

**This page:** **Translate the page** (in place, on your computer, when Chrome can; otherwise the
bot translates it in the chat), **Read the page aloud** with your computer's voice, **Watch part of
this page** (click the part, such as a price, and the bot tells you when it changes; your server
checks public pages, without your cookies, so a page behind a sign-in can't be watched this way; a
watcher stops by itself after 90 days, you can keep up to 25 at a time, and you can pause or stop
the ones you made from the bot's watchers), **Read it for me later** (the bot sums it up in your next brief) and **Send
these tabs** (the tab group you're in, or this window's tabs, go with your next message).

Below that: search your conversations, run or pause routines, watch a bot's cloud computer
(**Live view**: **Watch** here, **Pop out** into a small window of its own, or **Take over in
Casama**; view only), see this month's usage, and open Settings.

**Record** in the chat box records the tab you're on, with its sound, for up to two minutes (press
it again to stop). Chrome shows that the tab is being shared while it records; the video goes with
your next message. Closing the panel stops it.

## On pages

With site access on all sites or on sites you pick, Casama can add a few things to pages. Each has
its own switch in Settings, under **On pages**, and none of them reads anything until you tap it.

- **Selection bar** (off until you turn it on): select text and a small bar offers Ask, Explain,
  Summarize, Translate, Highlight and your first page commands.
- **Write button** (off until you turn it on): in a text box, the round **C** button offers Draft,
  Rewrite, Shorten and Reply in my voice. The bot's text is put into the box for you to check and
  send yourself. <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>A</kbd> in a text box does the same.
- **Site helpers**: on YouTube videos (summary, chapters), Gmail threads (summary, draft reply),
  GitHub pull requests and issues (summary, review notes), search results (an answer), long threads
  on X, LinkedIn and Reddit, and shopping pages (compare, watch the price). If a site changes its
  page so a helper can't find its place, the helper hides itself.
- **Highlights**: **Highlight** in the selection bar keeps the text. It shows again on your next
  visit, and your bots can find it when you ask about something you read.

## Page commands

Saved prompts you run with **/** in the panel, such as "tldr: Summarize this page in three bullets
for my team". Add and delete them in Settings, under **Page commands**. They're kept in your
account, so every browser you sign in to has them.

The right-click menu also has **Send this link's file to the bot's computer** (public files only,
into that bot's own computer), **Read it for me
(in my next brief)** and **Watch part of this page for changes**.

## Right-click, shortcuts and the address bar

Right-click a selection, a link, an image or the page for **Casama** actions: ask, explain,
summarize, translate or rewrite a selection; remember it; save a note, link, image or the page to
the Library; add the page to a bot's knowledge; make a task.

| Shortcut | Does |
|---|---|
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd> | Open the side panel |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>A</kbd> | Ask about the selection |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> | Screenshot part of the page |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> | Save the page to the Library |

Change them at `chrome://extensions/shortcuts`.

In the address bar, type `ca`, a space, then your question to ask your last-used bot.

## Notifications

When a bot needs you or finishes, Chrome shows a notification. An approval has **Approve** and
**Deny** buttons right on it; click anywhere else on it to open the panel. Turn notifications off
in the extension's Settings. Your browser appears in the devices list in Settings, where **Sign out
everywhere** signs out every browser and device at once.

## Site access

Chrome lets an extension read a tab only with your permission. Pick one in Settings:

- **On all sites** (recommended): the panel follows you from tab to tab and can read the tab you're
  on when you ask.
- **On sites you pick**: the same, but only on the sites you list.
- **When you click**: the extension can read a tab only after you click its button, or use its menu
  or a shortcut there. When it can't, the panel shows **Allow on this site**.

Whatever you pick, it reads only when you ask.

## Pages it never reads

- Casama's own pages, including your own server's address if you self-host.
- Any page with a password or card field. Screenshots and saves skip these too.
- Banking and payment, health, password manager and government ID sites, by default.
- Sites on your **never-list** in Settings, one per line.

On those, the chips say why nothing is sent.

## Privacy

What you send becomes part of the conversation on your Casama server, like any message. The
extension keeps your sign-in and settings in this browser only and never syncs them to your other
computers. See [Privacy and security](/guide/privacy) and the
[privacy policy](https://casama.ai/privacy#chrome).

## Bots in your browser

Bots you pick can open pages and act in this browser, where you're already signed in to your sites,
so they never need your passwords.

**Pair it.** In the panel, open **More**, pick the bots under **Your browser** and press **Let bots
use this browser**. The browser then shows in the app under Settings, Device connections, where you
can unpair it too. A workspace owner can turn this off for everyone in the workspace's settings.

**Which browser a bot uses.** A chat you start from the extension uses your browser while it's
online; other chats use the bot's own computer. Say "in my browser" to ask for yours. A routine or
a page watcher can be set to use your browser, and to wait for it (or use the bot's computer) when
it's offline. Only the person who made a routine can point it at their own browser: if someone else
edits it, it goes back to the bot's computer. A page watcher runs on its own, so it only reads sites
you set to **Always allow** and never asks.

**What you see.**

- Each bot works in its own tab group, named after it, usually collapsed while you browse. It
  only ever sees the tabs in that group: drag a tab in to share it, drag it out to take it back.
- A tab a bot is working in has a coloured frame and a banner with **Stop**.
- Chrome shows a bar saying Casama started debugging this browser. That's how bots click and type.
  Its **Cancel** stops the bot too.
- The panel's **More** tab lists each bot's steps as it goes, with **Stop**.

**Taking over.** Click or type in the tab and the bot pauses ("You took over"). Press **Hand back**
in the banner or the panel when you're done.

**What asks you first.** A small Casama window (and a notification) asks before:

- a bot uses a site for the first time: **Allow this once**, **Always allow** or **Never**;
- a click that sends, deletes, publishes, shares or signs in, or a form's Enter key that does;
- pressing Enter (or Ctrl or Cmd with Enter) in a text box outside a search box, since chat and
  comment boxes send that way;
- typing text it read on one site into another site;
- putting a file into a page's upload field.

No answer within 5 minutes counts as no.

**What bots never do.** Purchases, password changes, password fields, card numbers and one-time
codes are handed to you: the bot stops and says what's left. Casama's own pages are always off, so a
bot can't approve its own steps. Banking and payment, health, password manager and government ID
sites are off too; you can let bots ask to use a kind in **Settings**, under **Your browser**, where
you also list the sites they may use without asking and the sites they may never use. Your
never-list covers bots as well. Text a page hides from people (invisible, off the page, tiny) is left
out of what the bot reads.

**More it can do.** Read the page, fill forms (from About you, memory or a file), copy tables into a
CSV, download files with your sign-in into the Library, put Library files into upload fields,
answer page dialogs, and, for developers, read the tab's console and network requests.

**Stopping.** Any of these stops the bot's work in your browser at once and cancels its task: the
banner's **Stop**, **Stop** in the panel, Chrome's **Cancel**, closing the bot's tab group, or
unpairing. If the browser loses its connection, the step under way ends and the bot carries on once
it's back.

**Teach by showing.** Under **Your browser**, pick a bot and press **Teach in this tab**, then do the
task once. Casama records the pages you open by address, what you click and what you type (never
passwords) and writes a skill; **Save skill** keeps it. The steps replay in your browser without the
model.

**For administrators.** Chrome's enterprise policies can set `ServerAddress`, `ActDisabled`,
`BlockedSites`, `AllowedSites` and `ExtensionDisabled` for Casama for Chrome.

Prompt injection: a page may try to talk a bot into something. The asks above, the hidden-text
filter and the blocked places make that much harder, but not impossible, so keep an eye on what a
bot does on sites that matter.

## This browser as a device

Bots you allow can ask this browser a few things from anywhere: Telegram, your phone, a routine.
Each is off until you turn it on in **Settings**, under **This browser as a device**, and Chrome asks
for its permission then.

- **The tab in front:** for "what am I looking at?". Its address, title, your selection and, with
  site access, its text. Read only when a bot asks, never kept. The desktop app's quick ask on
  Windows and Linux uses it too, to know which tab you're on.
- **History and bookmarks:** for "the article I read last week". Only the pages matching the search
  go, at most 50; never kept.
- **Start routines:** a routine can start when you open a site it names, a download finishes or you
  add a bookmark. Only those events are sent, and only when one of your routines starts on them.
  Banking, health, password manager and government ID sites, and Casama's own, never start routines.
- **Activity recap:** minutes per site, per hour (site names only, never pages or titles), for
  end-of-day recaps. Kept 30 days.

Which bots may ask is in the app under Settings, Device connections, where you can stop a bot
asking. **Private models only** sends what this browser shares, and page content you send from the
panel, only to bots whose models all run privately; otherwise Chrome's built-in model answers on
this computer where it can ("Nothing was sent"), or nothing is sent.

**Bring in your bookmarks** puts your bookmarks (and reading list) into a bot's knowledge as one
list of titles and addresses, once. Nothing syncs after that.

**Meeting notes from captions**, where your workspace has it: on a Google Meet call, open the
panel's **More** tab and press **Take notes from captions** after telling the others (there's a
note to paste into the Meet chat). A banner shows on your screen while it runs. Turn on captions in
Meet first: the notes come from them, and no audio is recorded. **Stop and write notes** sends the
transcript to the bot; **Stop without sending** sends nothing. Recording what others say can need
their consent where you are.

## Coding agents in your browser

When a bot runs Claude Code or Codex on your computer and this browser is paired and lets that bot
in, the coding agent can open pages in your browser to check its work, including local addresses
such as `http://localhost:3000`. It works in the bot's tab group under the same rules as the bot:
the same asks, blocked sites and Stop. Its access ends when the bot's task does.

## Edge and Firefox

**Edge**: install **Casama** from Edge Add-ons. It's the same extension, with the side panel and
everything on this page. Two differences: Edge has no push service for extensions, so approval
notifications arrive within a minute rather than at once, and other news (a routine's result, a
bot's message) shows in the panel and the toolbar badge without a notification; and quick answers
on your computer use Edge's own built-in model where your Edge has one.

**Firefox** (140 or newer): install **Casama** from Firefox Add-ons. It covers asking about pages,
saving, page commands, the right-click menu, shortcuts and the Inbox. It doesn't have
[bots in your browser](#bots-in-your-browser) (Firefox has no interface for it),
[this browser as a device](#this-browser-as-a-device), recording a tab, meeting notes, or the
helpers [on pages](#on-pages) (the selection bar, write button, site helpers and highlights):
Firefox can't keep the extension's sign-in out of reach of scripts running on pages. Also:

- The panel is Firefox's sidebar. The toolbar button and <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd>
  open it.
- Sign in with a sign-in link or an emailed code. There's no **Connect Chrome** step: Firefox
  doesn't let a web page hand the extension a sign-in.
- Approval notifications have no **Approve** and **Deny** buttons. Clicking one opens the approval
  in the web app, and they arrive within a minute. Other news shows in the sidebar and the badge.
- **Read aloud** plays in the sidebar, so it stops when you close the sidebar.
- At install, Firefox shows what the extension sends to your Casama server: your sign-in, your
  messages and the page content you send. Bringing in bookmarks asks separately.

