# Firefox Add-ons listing: Casama for Firefox

Everything addons.mozilla.org (AMO) asks for, ready to paste (plan §13, D-323 Phase 5). Firefox
gets its own build from the same code: Ask, Capture and Stay in the loop. It leaves out bots in your
own browser (Firefox has no debugger API), the browser as a device, recording a tab, meeting
notes and the helpers on pages; `src/lib/browser.ts` lists what each browser offers.

Nothing here has been uploaded. The AMO developer account (free, a Firefox account), the listing
and every version wait for Oliver (plan §19). Uploading is a release: Oliver's yes each time
(AGENTS.md).

## Package

- `scripts/build-extension.sh firefox` makes:
  - `apps/extension/dist/casama-firefox-<version>.zip`, the add-on;
  - `apps/extension/dist/casama-firefox-<version>-source.zip`, the committed source that builds it,
    for Mozilla's review (the code is bundled, so AMO asks for it).
- Mozilla's linter: `npx addons-linter@10.15.0 apps/extension/dist/firefox` (CI runs it). At Phase 5
  it reports no errors. Its warnings are pdf.js's own (`Function`, `document.write` in its legacy
  build, used only to read a PDF's text), one `innerHTML` that renders a bot's reply after
  `src/lib/md.ts` escaped it, and `data_collection_permissions` on Firefox for Android (not
  offered: Firefox for Android has no sidebar).
- Id: `casama@casama.ai` (`GECKO_ID` in `src/manifest.ts`). Minimum Firefox 140 (an ESR), for
  Mozilla's data consent at install.
- The API: Firefox gives each install its own `moz-extension://` address, so the server allows any
  of them (`FIREFOX_EXTENSIONS`, on by default). Production gets it with the next server deploy.

## How it differs from Chrome (for the listing and support)

- The panel is Firefox's sidebar: the toolbar button and Alt+Shift+C open it.
- Sign in by pasting a link from Sign In on Another Device, or by email code. Firefox has no way for
  the web app to hand it a sign-in, so there's no "Connect" button.
- Notifications have no Approve and Deny buttons in Firefox: clicking one opens the approval in the
  web app. Approval notifications come from a once-a-minute check (Firefox has no `chrome.gcm`);
  other news (routine results, bot messages) shows in the sidebar and the badge only.
- No helpers on pages (selection bar, write button, site helpers, highlights): their content script
  runs only where content scripts can't read the extension's storage, and Firefox can't close
  `storage.local` to them, where the sign-in is kept. The settings card is hidden.
- Read aloud plays in the sidebar, so it stops when the sidebar closes.
- Keyboard shortcuts are changed in Firefox's add-ons manager (the More tab opens it).

## Listing

| Field | Value |
|---|---|
| Name | Casama |
| Add-on URL | https://addons.mozilla.org/firefox/addon/casama/ |
| Summary (250 max) | Your AI bots in your browser: ask about any page, save what matters, and answer what your bots need without leaving your tab. |
| Categories | Other, and Alerts & Updates (AMO has no productivity category) |
| Tags | ai, assistant, productivity, summarize, sidebar |
| Support email | hello@casama.ai |
| Support website | https://docs.casama.ai/guide/chrome |
| Homepage | https://casama.ai |
| License | GNU Affero General Public License v3.0 |
| Privacy policy | Yes: the text of https://casama.ai/privacy#chrome (AMO wants the policy pasted; it covers every browser) |
| Icon | `public/icons/icon-128.png` (AMO takes the manifest's icons) |
| Screenshots (1280×800) | `store/screenshot-1-chat.png`, `-2-context`, `-3-inbox`, `-4-library`, `-5-settings` (Chrome's frame; the panel is the same page; re-render in Firefox later, plan §19) |
| Experimental | No |
| Requires payment | No (needs a Casama account; free to start) |

### Description

```text
Casama for Firefox connects your browser to your Casama bots.

ASK ABOUT ANY PAGE
Open the sidebar and ask any of your bots about the tab you're on. The page's address and the text you've selected go with your message; switch on the page's text, a PDF's text, a YouTube video's captions or a screenshot when you want them. Every chip shows its size, and "What was sent" under each message shows exactly what went.

Replies stream in, with the bot's cards and buttons. Stop a reply, copy it, or have it read aloud. Attach files, paste pictures, drag a box over part of the page, or dictate.

SAVE WHAT MATTERS
Save a page to your Casama Library as Markdown, a PDF or a screenshot, into a project if you like. Remember a selection, add a page to a bot's knowledge, make a task from it, or bring your bookmarks into a bot's knowledge once. Saves made offline go when you're back.

MORE FROM THE PAGE
Type / for your saved page commands, @ to add other tabs, or point at the part of the page you mean. Watch part of a page, like a price, and hear when it changes. Talk with a bot in a live call while you look at the page.

RIGHT-CLICK, SHORTCUTS AND THE ADDRESS BAR
Ask about a selection, link or image from the right-click menu. Keyboard shortcuts open the sidebar, ask about the selection, screenshot part of the page or save it. Type "ca" in the address bar to ask straight away.

STAY IN THE LOOP
See what your bots need in the Inbox: approve or deny a step, answer requests, accept suggestions and stop runs. A notification tells you when a bot needs you, and the toolbar badge shows what's waiting.

PRIVATE BY DESIGN
It reads a page only when you ask, never in the background. It never reads Casama's own pages or pages with a password or card field, and you can add your own sites to a never-list. Your sign-in stays in this browser.

Works with Casama Cloud and with self-hosted Casama servers. You need a Casama account (free to start) at https://casama.ai. Letting bots work in your own tabs needs Chrome or Edge.
```

## Data collection (Firefox's consent at install)

The manifest declares what goes to the person's own Casama server, and Firefox shows it at install:

| Data | Required or optional | When |
|---|---|---|
| Authentication information | Required | Sign-in tokens with the person's Casama server |
| Personal communications | Required | The messages people send their bots |
| Website content | Required | Page text, selections, screenshots and files, when the person sends them |
| Bookmarks | Optional, asked when pressed | "Bring in your bookmarks" sends the list to a bot's knowledge once |

Nothing is sold or shared with anyone else; usage counts (which features are used, if usage
analytics is on in the person's account) never carry page addresses or content.

## Permissions (for the reviewer notes)

| Permission | Why |
|---|---|
| `activeTab` | Reads the tab you're on (address, title, selection, text) when you ask a bot about it or save it. |
| `scripting` | Reads the selection and readable text, a PDF's text or a video's captions, only when asked; draws the box for a part-of-page screenshot; puts a bot's draft into a text box. |
| `contextMenus` | "Ask Casama", "Save to the Library" and similar right-click items. |
| `storage`, `unlimitedStorage` | Sign-in, settings, and saves waiting while offline, in this browser only. |
| `alarms` | Retries offline saves and checks for approvals once a minute. |
| `notifications` | Tells you when a bot needs your approval or finishes. |
| Optional `tabs` | Asked the first time you type @ or use "Send these tabs": lists your open tabs' titles to pick from. |
| Optional `bookmarks` | Asked when you press "Bring in your bookmarks". |
| Optional host permissions | Asked at first run (all sites, sites you list, or none): lets the sidebar read the tab you're on when you ask, and reach a self-hosted Casama server. |

## Notes for reviewers

```text
Casama for Firefox needs a Casama account. Please use this test account on Casama Cloud:

  Email: <reviewer account email, from Vaultwarden "Chrome Web Store reviewer">
  Password: <from the same Vaultwarden item>

Steps:
1. After installing, the extension's settings open in a tab. Tap "Agree and continue", pick "On all sites" or "When you click", and tap Continue.
2. In another tab, sign in at https://app.casama.ai with the account above (Continue with Email, then Use a Password Instead). Open Settings, Sign In on Another Device, copy the sign-in link, and paste it under "Paste a sign-in link" in the extension's settings.
3. Open any news article, select a sentence, and click the Casama button in the toolbar. The sidebar opens with the "Researcher" bot. Type a question and press Enter: the reply streams in.
4. Library tab: tap "Markdown" to save the page.
5. Send "Ask me to approve something" to the "Approver" bot: an approval appears in the Inbox.

What is read and when: a page is read only when the user sends a message, uses the menu or a shortcut, or saves. "What was sent" under each message shows exactly what went with it. Everything goes to the user's own Casama server, nowhere else. No remote code.

Source code: casama-firefox-<version>-source.zip is the commit this build came from (AGPL-3.0). To build it (macOS or Linux, Node 24+, pnpm 12.18 via corepack):

  unzip casama-firefox-<version>-source.zip -d casama && cd casama
  pnpm install --frozen-lockfile --filter @casama/extension...
  scripts/build-extension.sh firefox

The add-on is apps/extension/dist/firefox (zipped as apps/extension/dist/casama-firefox-<version>.zip). The code isn't minified. pdfjs-dist 6.5.438 (Mozilla's pdf.js) is bundled unchanged from npm to read PDFs' text.
```

## Before each version

1. `scripts/build-extension.sh firefox` and the linter (above).
2. Check the source zip builds the same add-on (the steps in the reviewer notes, in a clean folder).
3. Oliver's yes, then upload the add-on and the source zip on AMO.
