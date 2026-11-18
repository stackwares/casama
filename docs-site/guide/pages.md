# Pages

A page is a small web page a bot publishes for you: a report, a dashboard, a tracker, a site or a
game. Ask for one when an answer is better as something to look at, keep, play or share than as a
chat message: a weekly sales summary, a project tracker, a trip itinerary, a sign-up form, a small
browser game. Pages open in your browser, stay private until you share them, and are kept in the
[Library](/guide/library).

## Ask a bot for a page

Ask in chat, for example: "Make a page that tracks our open bugs by severity, and refresh it every
morning."

The bot writes the page and publishes it. The reply shows a page card (**Page · Tap to open**). Tap
it to open the page. Under the bot's publishing step, **Show in Library** opens the Library on that
bot's sites and games.

A new page is private unless the bot was asked to share it with the workspace.

A page can refresh itself on a schedule. The bot links a routine that updates the page's data
while the layout stays the same.

To change a page, ask the bot, or open it in the Library and tap **Change It**. The bot can replace
the layout, update only the data, or change who can see it. Bots can only change their own pages.

## Sites and games

For a site or game with its own pictures, sounds, scripts and styles, the bot builds a folder on
its computer with an `index.html` and publishes the whole folder. Ask for "a small game I can play
in the browser" or "a one-page site for my business".

- A site or game can have up to 300 files and 25 MB in all.
- Its files load only from Casama's page address. Nothing from other sites can load.
- In the Library, a game's main button is **Play**; other pages show **Open**.
- Publishing the page again as one HTML file drops its files.

To put a site on the web at an address people can type, like `crumb-bakery.<sites domain>`, or on
your own domain, use **Publish to the Web**. See [Sites and domains](/guide/sites-and-domains).

Code and other working files stay on the bot's computer. To keep a copy that outlives the computer,
ask the bot to keep the folder in your Library. See [Projects](/guide/projects#files-and-code).

## Pages that take input

A page can collect answers, such as a sign-up sheet, an RSVP, a feedback form or a quiz. Ask for
it, and say what should happen with each answer: "Make an RSVP page for Saturday's dinner, and tell
me each time someone answers."

- Answers go only to the page's own address, never to another site.
- Each answer can be up to 64 KB. On a public page, each visitor can send up to 20 answers an hour.
- The bot reads the answers when you ask ("who has signed up so far?"). If you told it what to do
  with each answer, a routine starts a run for every new one. See [Routines](/guide/routines).
- Answers can be read by the person the page was made for and the people who manage the bot,
  through the bot. In a workspace that encrypts its content, they are encrypted like other content.
  See [Privacy](/guide/privacy#encrypt-workspace-content).

Bots are told never to ask for passwords, card numbers or other secrets on a page. Treat answers
from a public page as coming from strangers.

A page only takes input when the bot publishes it that way. Other pages can't send anything.

## Find and open pages

- **All pages:** open **Library** and pick **Sites & games**.
- **One bot's pages:** open its **Bot profile** → **Library**.
- **From a chat:** tap the page card, or long-press (or right-click) it and choose
  **Show in Library**.

Pages open in the browser, never inside the app's own screens:

| Platform | Where a page opens |
| --- | --- |
| iOS | Safari View Controller, inside the app |
| Android | Chrome Custom Tabs, inside the app |
| macOS, Windows, Linux | Your default browser |
| Web | A new tab |

For private and workspace pages, the app gets a single-use link that works for 60 seconds and only
for you. Your browser then keeps access to that one page for 30 minutes. Access is checked again
on every load, so removing someone's access works at once.

## Share a page

Each page has one of three visibility levels:

| Visibility | Who can open it |
| --- | --- |
| **Only me** | The person the page was made for, plus the people who manage the bot. |
| **Workspace** | Everyone who can see the bot. |
| **Anyone with the link** | Anyone with the public link, signed in or not. |

To make a page public:

1. Open the page in the **Library**, then open the **…** menu → **Who Can See It** →
   **Anyone with the link**.
2. Confirm **Make Public**. The **Public Link** appears and is copied for you.

Public links are hidden from search engines, and every public page has a way for viewers to report
it. To take a link back, set the page to **Only me** or **Workspace**; the old link stops working.
Making it public again creates a new link.

A bot can share a page too. Making a page public is a high-risk action and sharing it with the
workspace is medium risk. Both follow the bot's autonomy and any **Sharing and invites** action
rule. See [Autonomy and approvals](/guide/autonomy).

Anyone who can open a page can export it. Changing its visibility or deleting it is for the
person it was made for, the people who manage the bot, and workspace admins. Making a page public,
or taking it back, is recorded in the audit log.

See [Share something](/guide/library#share-something) for public links and reports.

## Export a PDF

Open the page in the **Library**, then open the **…** menu → **Export PDF**. The PDF is the same
page, printed by the server, and opens where pages open.

## Delete a page

Open the page in the **Library**, then open the **…** menu → **Delete**. It leaves the Library at
once, and **Undo** brings it back. After 30 days it's removed for good.

Until then, a public link to it keeps working and its refresh routine keeps running. To stop them
at once, set the page to **Only me** and turn the routine off in **Routines** before you delete it.

## What a page can and can't do

A page is an HTML document with a block of JSON data, plus its own files for a site or game. The
same page serves the app, public links and PDF export.

- **No outside requests.** Pages can't load scripts, styles, images or data from other sites. A
  one-file page must build in its images and fonts; a site or game loads them from its own files.
  Only [pages that take input](#pages-that-take-input) can send anything, and only to their own
  address.
- **No Casama actions.** Buttons on a page can't call Casama or the bot. To act on what you see, go
  back to the chat.
- **Theme.** Pages don't take on your app theme. Bots are asked to use the light and dark colors
  Casama provides, so pages follow your system's light or dark mode.
- **Size.** The HTML can be up to 2 MB and the data up to 1 MB. A site or game's files can be up to
  25 MB more.
- **Versions.** Casama keeps the last 20 versions of each page.
- **Storage.** Pages count toward the workspace's Library storage on Casama Cloud. See
  [Storage](/guide/library#storage).

## For self-hosters

Pages are served from their own address, separate from the app, so a page can never touch your
Casama session. Set `PAGES_URL` to its public address and `PAGES_PORT` to serve it from the API
process. A site or game's files are kept in the Library's object store; see
[The Library for self-hosters](/guide/library#for-self-hosters). PDF export runs in a separate
container: turn on the `pdf` Compose profile and set `PDF_RENDERER_URL=http://pdf:3000`. See
[Page PDFs](/self-hosting/configuration#page-pdfs).

## Limits

- On a self-hosted server, **Export PDF** fails until the server admin turns on the `pdf` profile.
- The app doesn't set an expiry on public links, restore old versions or list a page's answers.
  Expiry and old versions are available through the API (`PATCH /v1/pages/{id}` with
  `expires_in_days`, and `POST /v1/pages/{id}/revert`); ask the bot for the answers.
- Sites can't run code on a server or use your own domain.
- When a site is published again, its older versions' files stay stored until the page is deleted.

## Related

- [The Library](/guide/library)
- [Chatting with a bot](/guide/chat)
- [Routines](/guide/routines)
- [Autonomy and approvals](/guide/autonomy)
- [API](/develop/api)
