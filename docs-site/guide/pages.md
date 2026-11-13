# Pages

A page is a report, dashboard or tracker that a bot publishes as a small web page. Ask for one when
an answer is better as something to look at, keep or share than as a chat message: a weekly sales
summary, a project tracker, a trip itinerary. Pages open in your browser and stay private until you
share them.

## Ask a bot for a page

Ask in chat, for example: "Make a page that tracks our open bugs by severity, and refresh it every
morning."

The bot writes the page and publishes it. Under its publishing step in the chat, select
**Open in Pages** to see it. A new page is private unless the bot was asked to share it with the
workspace.

A page can refresh itself on a schedule. The bot links a routine that updates the page's data
while the layout stays the same. Such pages show **Refreshes on schedule**, and every page shows
when it was last updated.

To change a page, ask the bot. It can replace the layout, update only the data, or change who can
see it. Bots can only change their own pages.

## Find and open pages

- **All pages:** open **Inbox** and pick the **Pages** filter.
- **One bot's pages:** open its **Bot profile** → **Pages**.

Select a page to open it. The app never shows pages inside itself:

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

1. In **Pages**, open the page's menu and choose **Anyone with the link**.
2. Confirm **Make public**. The **Public link** is copied for you.

Public links are hidden from search engines. To take a link back, set the page to **Only me** or
**Workspace**; the old link stops working. Making it public again creates a new link.

A bot can share a page too. Making a page public is a high-risk action and sharing it with the
workspace is medium risk. Both follow the bot's autonomy and any **Sharing and invites** action
rule. See [Autonomy and approvals](/guide/autonomy).

Anyone who can open a page can export it. Changing its visibility or deleting it is for the
person it was made for and the people who manage the bot. Making a page public, or taking it back,
is recorded in the audit log.

## Export a PDF

In **Pages**, open the page's menu and choose **Export PDF**. The PDF is the same page, printed by
the server, and opens where pages open.

## Delete a page

Open the page's menu and choose **Delete**. Its refresh routine is turned off too.

## What a page can and can't do

A page is one self-contained HTML document with a block of JSON data. The same document serves
the app, public links and PDF export.

- **No outside requests.** Pages can't load scripts, styles, images or data from other sites, or
  send forms. Images and fonts must be built in. Everything a page shows comes from its own HTML
  and data.
- **No Casama actions.** Buttons on a page can't call Casama or the bot. To act on what you see, go
  back to the chat.
- **Theme.** Pages don't take on your app theme. Bots are asked to use the light and dark colors
  Casama provides, so pages follow your system's light or dark mode.
- **Size.** The HTML can be up to 2 MB and the data up to 1 MB.
- **Versions.** Casama keeps the last 20 versions of each page.

## For self-hosters

Pages are served from their own address, separate from the app, so a page can never touch your
Casama session. Set `PAGES_URL` to its public address and `PAGES_PORT` to serve it from the API
process. PDF export runs in a separate container: turn on the `pdf` Compose profile and set
`PDF_RENDERER_URL=http://pdf:3000`. See [Page PDFs](/self-hosting/configuration#page-pdfs).

## Limits

- On a self-hosted server, **Export PDF** fails until the server admin turns on the `pdf` profile.
- The app doesn't set an expiry on public links or restore old versions. Both are available
  through the API (`PATCH /v1/pages/{id}` with `expires_in_days`, and
  `POST /v1/pages/{id}/revert`).
- Pages don't appear in search yet.

## Related

- [Chatting with a bot](/guide/chat)
- [Routines](/guide/routines)
- [Autonomy and approvals](/guide/autonomy)
- [API](/develop/api)
