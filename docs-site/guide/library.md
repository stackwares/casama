# The Library

The **Library** holds everything your bots make for you: sites and games, reports, pictures,
videos, sounds, documents and other files. Things land there by themselves, so you don't have to
dig back through a chat to find what a bot made last week.

Open **Library** in the main navigation. On phones it's the tab between **Chats** and **Tasks**.

<figure class="casama-shot"><img src="/screens/library.png" alt="The Library showing sites, games, documents and images your bots made"></figure>

## What lands in the Library

| Kind | What it is | How it gets there |
| --- | --- | --- |
| **Page** | A report, dashboard, site or game. See [Pages](/guide/pages). | Every page a bot publishes. |
| **Image**, **Video**, **Audio** | Pictures, videos and spoken audio a bot generated. | Every one a bot makes in a chat. |
| **Document** | A PDF, or a Word, PowerPoint or Excel file. | A file the bot links in a reply, or keeps on purpose. |
| **File** | Anything else, such as a zip, a CSV or a song. | The same as documents. |

Bots give each thing a short label, such as **Site**, **Game**, **Report** or **Source**, which
shows on its tile.

### Files from the bot's computer

The Library holds only what a bot hands over to you, not everything on its computer. A file
reaches the Library when:

- **The bot links it in a reply.** Before the reply is saved, Casama copies up to 8 linked files,
  each up to 50 MB, from the bot's computer.
- **The bot keeps it on purpose.** Ask "keep that in my Library" and the bot saves the file without
  linking it.

The copy belongs to the server, so it stays even when the computer sleeps or is reset. When the bot
hands over the same file again with new contents, it becomes a new version of the same item. Casama
keeps the last 5 versions.

Files on [your own computer](/guide/companion) stay there. They are never copied to the Library.

### Documents

When a kept file is a PDF or an Office document, the bot's computer also makes a PDF of it and a
picture of its first page. The Library shows that first page as the tile's cover. **Open** opens
the original file in your own apps. The app doesn't edit documents.

To get an Office file you can edit, ask for it by name: "make this a .docx", "put it in a
spreadsheet" or "turn this into slides".

## Find things

The Library shows newest first:

- **Projects** at the top, one card per project. See [Projects](/guide/projects).
- **Pinned**, the things you pinned.
- Then everything else under **Today**, **Yesterday**, **This week** and **Earlier**.

To narrow it down:

- **Search the Library** matches titles and labels.
- **Kind chips** filter to **Sites & games**, **Images**, **Videos**, **Audio**, **Documents** or
  **Files**. Only the kinds your workspace has appear. **All** clears the filter.
- **One bot's things:** open its **Bot profile** and tap **Library**.
- **One project's things:** open the project and tap **See All** next to **Made in this project**.

The app's search also has a **Library** scope that finds the same things.

From a chat, long-press (or right-click) a page card, picture or video and choose
**Show in Library**. After a bot publishes a page, the **Show in Library** button under it opens the
Library on that bot's sites and games.

If the Library is empty, it suggests a few things to ask for, such as **A small game** or
**A one-page site**. Tap one to open **Quick ask** with the request typed in, ready for you to
finish and send.

## Open something

Tap a tile. On a phone it opens on its own screen; on a wide window it opens beside the grid. You
see a preview, the title, which bot made it, when, its version and who can see it.

| Kind | Main button | What happens |
| --- | --- | --- |
| Page | **Open**, or **Play** for a game | Opens in your browser, the same way as in [Pages](/guide/pages#find-and-open-pages). |
| Picture, video, sound | **View** | Opens in the app's viewer or player. |
| Document, file | **Open** | Opens with your device's own apps. |

Below that:

- **Project** opens the project it belongs to, when it has one.
- **From your chat with** the bot goes back to the conversation it came from.
- **Details** shows the kind, size and dimensions.
- **Made alongside** lists the other things made in the same bot run.

## Change something

Tap **Change It**. The chat it came from opens (or the bot's General chat, if that chat is gone)
with `About “Title”: ` typed in. Finish the sentence and send it. The bot finds the item and makes
the change, and a page or kept file gets a new version.

The **…** menu has the rest:

| Item | What it does |
| --- | --- |
| **Rename** | Changes the title. You can also tap the title. |
| **Pin** / **Unpin** | Keeps it on your **Pinned** shelf. Pins are yours alone. |
| **Who Can See It** | See [Share something](#share-something). |
| **Move to Project** | Files it under a project, or **No Project** to take it out. See [Projects](/guide/projects#move-something-into-or-out-of-a-project). |
| **Export PDF** | Pages only. See [Export a PDF](/guide/pages#export-a-pdf). |
| **Delete** | See [Delete something](#delete-something). |

**Rename**, **Who Can See It**, **Move to Project** and **Delete** appear only for the person it was
made for, the people who manage the bot, and workspace admins.

## Share something

Everything in the Library has one of three levels:

| Level | Who can open it |
| --- | --- |
| **Only me** | For a page, the person it was made for and the people who manage the bot. For anything else, the people who can open the chat it was made in (a private chat stays private). With no chat, the person it was made for and the bot's managers. |
| **Workspace** | Everyone in the workspace. A page goes to everyone who can see the bot. |
| **Anyone with the link** | Anyone with the public link, signed in or not. |

To make something public:

1. Open it, then open the **…** menu → **Who Can See It** → **Anyone with the link**.
2. Confirm **Make Public**. The **Public Link** appears and is copied for you.

The link is shown only this once. Public links are hidden from search engines.

A site or game can also go on the web at its own address with **Publish to the Web**. See
[Sites and domains](/guide/sites-and-domains).

What a public link shows:

- **Pictures, videos and sounds** play on a simple page.
- **Documents** get a link to open them, as a PDF when Casama made one.
- **Other files** download instead of opening in the browser.
- **Pages** open as the page. See [Share a page](/guide/pages#share-a-page).

**To stop a link**, set it back to **Only me** or **Workspace**. The old link stops working at
once. Making it public again creates a new link.

A workspace can make up to 20 public links a day from the Library.

### Reports

Every public link has a way for viewers to report it. When three different people report the same
link, it's hidden until the server's owner looks at it. On a self-hosted server, the owner reviews
reports through the API (`GET /v1/admin/reports`, and
`POST /v1/admin/creations/{id}/takedown` to take one down).

## Delete something

Open the **…** menu and tap **Delete**. It disappears from the Library at once, and **Undo**
brings it back. After 30 days it's removed for good, along with its stored files.

::: warning A deleted page's public link
Deleting a page from the Library hides it, but its public link keeps working until it's removed
for good. To stop the link at once, set the page to **Only me** first, then delete it.
:::

**Deleting a chat** keeps what was made in it. Those things stay in the Library, visible to the
person they were made for. To delete them with the chat, tick
**Also delete the N things made here** when you delete the chat.

## Copies

The API can copy anything in the Library (`POST /v1/creations/{id}/duplicate`). The copy is
private to you and titled "Copy of …". A page copies with its layout, data and files. The app
doesn't have a copy button yet.

A copy shares the stored bytes with the original instead of storing them twice, but its size still
counts toward storage. Stored bytes are deleted only when nothing in the Library uses them any more.

## Storage

On Casama Cloud, each plan includes Library storage for the workspace:

| Plan | Storage |
| --- | --- |
| Free | 1 GB |
| Plus | 10 GB |
| Pro | 50 GB |
| Max | 200 GB |

Pages, a site's files, generated pictures, videos and sounds, and kept files all count. When the
Library is full, new pages and kept files are refused and the bot tells you so. New pictures,
videos and sounds stay on the bot's computer but aren't added to the chat or the Library. Nothing
is ever deleted to make room. Delete things you don't need, or move to a bigger plan. See
[Usage and budgets](/guide/usage).

Self-hosted servers have no storage cap.

## For self-hosters

The API and worker store the Library's files, and new generated pictures, videos and sounds, in
an object store. Older media is moved out of the database a little at a time, so database backups
stop growing with media.

By default the store is the `library` Docker volume at `/data/library`, and
[backups](/self-hosting/operations#back-up-your-server) include it as `library.tar.gz`.

To use S3-compatible storage instead, set these in your `.env`:

| Name | Default | What it does |
| --- | --- | --- |
| `LIBRARY_OBJECT_STORE` | (filesystem) | `s3` to use S3-compatible storage. |
| `LIBRARY_OBJECT_DIR` | `/data/library` | Folder for the filesystem store. |
| `LIBRARY_S3_BUCKET` | (empty) | Bucket name. |
| `LIBRARY_S3_ENDPOINT` | (AWS) | Endpoint, for example `https://<account>.r2.cloudflarestorage.com`. |
| `LIBRARY_S3_REGION` | `auto` | Region. |
| `LIBRARY_S3_ACCESS_KEY_ID` | (empty) | Access key. |
| `LIBRARY_S3_SECRET_ACCESS_KEY` | (empty) | Secret key. |
| `LIBRARY_S3_PREFIX` | `library/` | Key prefix inside the bucket. |

With S3, `library.tar.gz` isn't made; back up the bucket with your storage provider's tools.

Public links and pages are served from the pages address (`PAGES_URL`), never from the app's own
address. See [Pages for self-hosters](/guide/pages#for-self-hosters).

## For developers

The Library is in the [API](/develop/api) under `/v1/creations`:

| Route | What it does |
| --- | --- |
| `GET /v1/creations` | Lists items. Filters: `kind`, `bot_id`, `conversation_id`, `project_id`, `pinned`, `q`, `sort` (`new` or `opened`) and `deleted=true` for the last 30 days' deletions. |
| `GET /v1/creations/{id}` | One item, with what was made alongside it. |
| `PATCH /v1/creations/{id}` | Changes `title`, `label`, `pinned`, `visibility` (with optional `expires_in_days` for a public link), or `project_id`. |
| `DELETE /v1/creations/{id}` | Deletes it. `POST /v1/creations/{id}/restore` undoes that. |
| `GET /v1/creations/{id}/content` | The bytes. |
| `GET /v1/creations/{id}/cover` | The cover picture. |
| `GET /v1/creations/{id}/preview` | A document's PDF. |
| `POST /v1/creations/{id}/duplicate` | A private copy. |

The CLI has no Library commands yet.

## Limits

- The app can't copy items, set an expiry on a public link, or show older versions. Copies and
  expiry are available through the API.
- The app doesn't preview a document's PDF; **Open** opens the original file.
- Pages don't get a picture cover yet. The app draws one from the title and kind.
- The Library doesn't update live. It refreshes when you open it or pull down.
- Workspaces can't see how much storage they've used in the app yet.

## Related

- [Pages](/guide/pages)
- [Projects and the ticket board](/guide/projects)
- [Chatting with a bot](/guide/chat)
- [Computers](/guide/computers)
- [Usage and budgets](/guide/usage)
- [API](/develop/api)
