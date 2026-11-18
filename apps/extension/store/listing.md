# Chrome Web Store listing: Casama for Chrome

Everything the store's developer dashboard asks for, ready to paste (plan §12). The pictures in
this folder are rendered from the real extension by `e2e/store-shots.spec.ts`:

```sh
CASAMA_STORE_SHOTS=1 pnpm --filter @casama/extension exec playwright test e2e/store-shots.spec.ts
```

Nothing here has been uploaded. The developer account, the draft item and every submission wait for
Oliver (plan §19). Edge Add-ons and Firefox Add-ons have their own kits in `edge/` and `firefox/` (Phase 5).

## Package

- Build: `scripts/build-extension.sh` makes `apps/extension/dist/casama-chrome-<version>.zip`
  from the store target (no dev key, no `host_permissions`, store sign-in origins only).
- Version: from the root `package.json` (`0.1.0`).

## Store listing tab

| Field | Value |
|---|---|
| Name | Casama (from `_locales/en/messages.json`) |
| Summary (132 max) | Your AI bots in your browser: ask about any page, save what matters, and answer what your bots need without leaving your tab. |
| Category | Workflow & Planning |
| Language | English |
| Store icon | `public/icons/icon-128.png` (128×128) |
| Screenshots (1280×800) | `screenshot-1-chat.png`, `screenshot-2-context.png`, `screenshot-3-inbox.png`, `screenshot-4-library.png`, `screenshot-5-settings.png` |
| Small promo tile (440×280) | `small-tile-440x280.png` |
| Marquee promo tile (1400×560) | `marquee-1400x560.png` |
| Promo video | None yet (optional; a 30-second screen recording of screenshot 1's flow would do) |
| Official URL | https://casama.ai (verified in Search Console) |
| Homepage URL | https://casama.ai |
| Support URL | https://docs.casama.ai/guide/chrome |
| Mature content | No |

### Description

```text
Casama for Chrome connects your browser to your Casama bots.

ASK ABOUT ANY PAGE
Open the side panel and ask any of your bots about the tab you're on. The page's address and the text you've selected go with your message; switch on the page's text, a PDF's text, a YouTube video's captions or a screenshot when you want them. Every chip shows its size, and "What was sent" under each message shows exactly what went.

Replies stream in, with the bot's cards and buttons. Stop a reply, copy it, or have it read aloud. Attach files, paste pictures, drag a box over part of the page, or dictate.

SAVE WHAT MATTERS
Save a page to your Casama Library as Markdown, a PDF or a screenshot, into a project if you like. Remember a selection, add a page to a bot's knowledge, or make a task from it. Saves made offline go when you're back.

ON EVERY PAGE, WHEN YOU WANT IT
Turn on a bar beside selected text, a write button in text boxes (draft, rewrite, shorten, reply in your voice), and helpers for YouTube, Gmail, GitHub, search results, long threads and shopping pages. Type / for your saved page commands, @ to add other tabs, or point at the part of the page you mean. Highlight text to keep it; it shows again next time and your bots can find it. Watch part of a page, like a price, and hear when it changes. Queue pages for your morning brief. Talk with a bot in a live call while you look at the page.

ON YOUR COMPUTER
With Chrome's built-in AI, summarize, explain or translate a selection without sending anything. Long pages are trimmed to what matters before they're sent, to save credits.

RIGHT-CLICK, SHORTCUTS AND THE ADDRESS BAR
Ask about a selection, link or image from the right-click menu. Keyboard shortcuts open the panel, ask about the selection, screenshot part of the page or save it. Type "ca" in the address bar to ask straight away.

STAY IN THE LOOP
Approve or deny a bot's step, answer its requests, accept suggestions and stop runs, from the panel or right from a Chrome notification. The toolbar badge shows what's waiting.

BOTS IN YOUR OWN BROWSER
Let the bots you pick work in this browser, where you're already signed in, so they never need your passwords. Each works in its own named tab group and never sees your other tabs. A banner with Stop shows on every tab it uses; click into the tab to take over, hand back when you're done. Steps that send, delete, publish, share or sign in ask you first; purchases and passwords are always yours. Teach a bot a task by doing it once.

PRIVATE BY DESIGN
It reads a page only when you ask (start a message, switch on a chip, use the menu or a shortcut, or save), never in the background. It never reads Casama's own pages or pages with a password or card field, and banking, health, password manager and government ID sites are off by default. Add your own sites to the never-list. Your sign-in stays in this browser and isn't synced.

Works with Casama Cloud and with self-hosted Casama servers. You need a Casama account (free to start) at https://casama.ai.
```

## Privacy practices tab

### Single purpose

```text
Casama for Chrome connects your browser to your Casama bots: ask a bot about the page you're on, send it things to keep or work on, and answer what your bots need without leaving the browser.
```

From Phase 3 the single purpose reads: "Casama for Chrome connects your browser to your Casama bots: ask a bot about the page you're on, send it things to keep or work on, answer what your bots need without leaving the browser, and let the bots you pick work in your tabs while you watch."

### Permission justifications

| Permission | Justification |
|---|---|
| `sidePanel` | The extension's main interface is a side panel where you chat with your bots, see your Inbox and save pages. |
| `activeTab` | When you click the toolbar button or use the extension's menu or shortcut, it reads the tab you're on (address, title, selection, text) to send to your bot with your message. |
| `scripting` | Reads the open tab's selection and readable text, a PDF's text or a video's captions, only when you ask a bot about the page or save it. Draws the box you drag to screenshot part of the page and the outline when you point at part of it, and puts a bot's draft into a text box. If you turn on the selection bar, write button, site helpers or highlights, registers the script that shows them on the sites you gave access to; it reads nothing until you tap it. |
| `contextMenus` | Adds "Ask Casama", "Save to the Library" and similar items to the right-click menu for selections, links, images and pages. |
| `storage` | Keeps your sign-in, settings and saves waiting to be sent while offline, in this browser only. |
| `unlimitedStorage` | Keeps pages and screenshots you save while offline until they can be sent, which can pass Chrome's 10 MB storage limit. |
| `alarms` | Retries saves made offline and refreshes the toolbar badge (approvals waiting) once a minute. |
| `offscreen` | Plays a bot's reply aloud when you tap "Read aloud". |
| `notifications` | Shows a notification when a bot needs your approval or finishes, with Approve and Deny buttons. |
| `gcm` | Receives push messages from your Casama server so approvals and "done" notifications arrive at once, without polling. |
| `debugger` (Phase 3) | Lets the bots a person paired with this browser do browser tasks for them: open pages, read them, click, type and fill forms with real input, answer page dialogs and put files in upload fields. It is attached only to tabs in that bot's own tab group (or the tab the person is teaching in), only while the bot is working, and detached after a minute idle; Chrome's own "is debugging this browser" bar shows the whole time and its Cancel stops the bot. It is never attached to other tabs. The person pairs the browser and picks the bots first; risky steps ask them; purchases and passwords are always left to them. |
| `tabGroups` (Phase 3) | Names and colours the tab group each bot works in, and collapses it so the bot works in the background. |
| `tabCapture` (Phase 4) | "Record this tab": when the person presses Record in the side panel, records the tab they're on, with its sound, for up to two minutes, to attach to a message for their bot (a bug report, a clip). Chrome shows that the tab is being shared while it records. Nothing is recorded otherwise. |
| Optional `history` (Phase 4, asked when switched on) | When the person turns on "Let bots you allow search your history and bookmarks" and a bot they allowed asks (for example "the article I read last week"), searches the history for that question and sends at most 50 matching addresses and titles. Never kept on the server, never sent otherwise. |
| Optional `bookmarks` (Phase 4, asked when used) | The same history search includes bookmarks; "Bring in your bookmarks" sends the bookmarks list to a bot's knowledge once, when pressed; a routine can start when a bookmark is added, if the person set one up. |
| Optional `readingList` (Phase 4, asked when used) | "Bring in your bookmarks" can include the reading list, once, when pressed. |
| Optional `downloads` (Phase 4, asked when switched on) | A routine can start when a download finishes, if the person turned on "Start your routines from this browser" and made such a routine. Only the file's name is sent, and only when a routine starts on it. |
| Optional `idle` (Phase 4, asked when switched on) | The opt-in activity recap counts only minutes the person is at the computer. |
| Optional `tabs` (asked the first time you type @ or use "Send these tabs") | Lists your open tabs' titles so you can pick one to add to a message. A tab is read only when you pick it. In Phase 4, also used when the person turns on sharing the tab in front with bots they allow, routines started by opening a site, or the activity recap (site names and minutes per hour only). |
| Optional host permission for `https://meet.google.com/*` (Phase 4, asked when switched on, off by default) | Meeting notes from Meet's own captions, started by the person on a call after a consent step; a banner shows while it runs. The transcript goes to their bot only when they stop. |
| Optional host permissions (`<all_urls>`, asked at first run, never at install) | Lets the panel follow you from tab to tab and read the tab you're on when you ask, without clicking the toolbar button first. You choose all sites, sites you list, or none. Also lets the extension reach a self-hosted Casama server's address. |

### Remote code

No, I am not using remote code. All JavaScript is in the package. Phase 3's bot steps arrive from
the user's Casama server as data (an action name such as "click" with an element reference, or
"fill" with text), and the packaged code carries them out through the Debugger API's Input,
Accessibility, DOM and Page domains. The server never sends JavaScript to run.

### Data usage

Tick these, as the extension sends them to the user's own Casama server when they ask:

- [x] Personally identifiable information (the account's email address, at sign-in)
- [x] Authentication information (sign-in tokens)
- [x] Personal communications (the messages people send their bots)
- [x] Website content (page text, selections, screenshots, files, when the person sends them)
- [x] User activity (which features are used, if usage analytics is on; never page content or addresses)
- [x] Web history (the address and title of a page the person asks about or saves; from Phase 4, when the person turns it on, history search results a bot they allowed asks for, and site names with minutes per hour for the activity recap)
- [ ] Health information, financial and payment information, location: not collected

Certify all three:

- [x] I do not sell or transfer user data to third parties, outside of the approved use cases
- [x] I do not use or transfer user data for purposes that are unrelated to my item's single purpose
- [x] I do not use or transfer user data to determine creditworthiness or for lending purposes

Privacy policy URL: https://casama.ai/privacy#chrome (the section is in `site/privacy.html` and goes
live with the next `scripts/deploy-web.sh`).

## Distribution tab

- Visibility: Public (decision 2: public at Phase 1). Each phase goes to the trusted testers group first.
- Regions: All regions.
- Pricing: Free (decision 4).

## Test instructions (for reviewers)

```text
Casama for Chrome needs a Casama account. Please use this test account on Casama Cloud:

  Email: <reviewer account email, from Vaultwarden "Chrome Web Store reviewer">
  Password: <from the same Vaultwarden item>

Steps:
1. After installing, the extension's Settings open. Tap "Agree and continue", then pick "On all sites" (recommended) or "When you click" and tap Save.
2. Under "Use the web app", tap "Open the web app". On app.casama.ai, tap "Continue with Email", then "Use a Password Instead", and sign in with the account above. Then open Settings, Sign In on Another Device, and press Connect Chrome. The extension signs in by itself.
3. Open any news article, select a sentence, and click the Casama button in the toolbar. The side panel opens with the "Researcher" bot. Type a question and press Enter: the reply streams in.
4. Library tab: tap "Markdown" to save the page; it appears under "Newest in the Library".
5. Inbox tab: send the message "Ask me to approve something" to the "Approver" bot. An approval appears in the Inbox and as a Chrome notification with Approve and Deny buttons.
6. Right-click a selection for the Casama menu, or press Alt+Shift+A to ask about it.

Phase 2 features: in Settings, under "On pages", switch on "A bar beside text you select" and "A write button in text boxes". Select text on any article for the bar; click into a text box for the round C button. On a YouTube video, a small Casama bar offers a summary. Type / in the panel for page commands (add one in Settings first) and @ to add another tab.

Phase 3 (bots in your browser): in the panel's More tab, under "Your browser", tick the Researcher bot and press "Let bots use this browser". In the Researcher chat, send "In my browser, open https://example.com and tell me its heading". A Casama window asks to allow example.com: press "Allow this once". The bot opens the page in a collapsed "Researcher" tab group; the tab shows a banner with Stop and Chrome shows its debugging bar. Click into the tab to pause the bot ("You took over"), press "Hand back" to resume, or press Stop. The debugger is attached only to tabs in the bot's group.

Phase 4 (this browser as a device, all off by default): in Settings, under "This browser as a device", tick "Share the tab in front when a bot you allow asks" (Chrome asks for the tabs permission). In the Casama app (app.casama.ai), send the Researcher "What am I looking at in my browser?" and press "Allow" on the card it shows; ask again and it answers with the tab's title. In the panel, press "Record" in the chat box, then press it again to stop: the video is attached to the next message. Meeting notes from captions are off for the reviewer account.

What is read and when: the extension reads a page only when the user sends a message, uses the menu or a shortcut, or saves. It never reads Casama's own pages or pages with password or card fields. "What was sent" under each message shows exactly what went with it.

Permissions: gcm is used for push notifications from the user's Casama server (approvals). Host access is optional and asked at first run, never at install.
```

## Before each submission

1. `scripts/build-extension.sh` (checks the manifest has no `host_permissions`, and from Phase 3
   has `debugger`, `tabGroups` and the managed settings schema).
2. Re-render the pictures if the panel changed.
3. Make sure the reviewer account signs in, its Researcher and Approver bots exist, and Approver asks before it replies (an action rule).
4. Oliver's yes, then upload in the dashboard (AGENTS.md: store uploads need permission each time).
