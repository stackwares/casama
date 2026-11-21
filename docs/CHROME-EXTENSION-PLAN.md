# Casama for Chrome: the browser extension plan

Status: **approved, D-323** (2026-11-16). It reopens D-123. Oliver said yes to decisions 1, 2
and 4 and left the rest to the recommendations in §16. Store rules and Chrome APIs below were checked against Google's pages on
2026-11-16 (sources at the end).

## 0. Summary

Casama can't go into the Chrome Web Store as the app it is today. The store rejects an extension
whose only job is to open a web page, app.casama.ai refuses to be framed (`X-Frame-Options: DENY`),
and the Wasm build is 48 MB. So the extension is a new, small TypeScript client, not the Flutter app.

What it is for, in one sentence, which is also the store's "single purpose" statement:

> Casama for Chrome connects your browser to your Casama bots: ask a bot about the page you're on,
> send it things to keep or work on, and let it work in your tabs while you watch.

Everything in this plan hangs off that sentence. "Feature packed" is fine with the store as long as
every feature serves the one purpose; unrelated extras (a new tab page, an ad blocker, coupons) are
what get an extension rejected, so they are out (§7).

The features fall into seven groups (§6):

| Group | What it gives a person |
|---|---|
| **Ask** | A side panel chat with any bot, with the page, selection, PDF, video transcript or a screenshot attached |
| **Capture** | Save to the Library, memory, knowledge or the board; highlights; "watch this page" |
| **Act** | Bots work in your own signed-in browser, inside a labelled tab group, with Stop always in reach |
| **Stay in the loop** | Approvals, secret requests, notifications, search, routines and usage without opening the app |
| **Browser as a device** | The browser joins Device connections: "what am I looking at", browser triggers, activity recap |
| **On-device AI** | Free, private quick answers from Chrome's built-in model where the computer supports it |
| **Settings and trust** | Site access modes, a never-list, "what was sent" on every message, admin policy |

It is built in five phases (§15). Phase 1 (Ask, Capture, Stay in the loop) is a complete product on
its own and is the first public listing. Phase 3 (Act) is the differentiator and the hard part.

One finding corrects what was said in chat earlier: Chrome's `debugger` permission, which real
browser control needs, **cannot be an optional permission**. Adding it in a later update turns the
extension off for existing users until they accept the new warning once. The plan accepts that one
prompt (§8, decision 2).

## 1. What exists today

Nothing of the extension exists. D-123 (Oliver, 2026-11-10) removed "your own browser" from the
spec before any code was written. What Casama already has that the extension stands on:

| Already built | Where | What the extension does with it |
|---|---|---|
| Typed TypeScript client with run-following helpers | `packages/client` (`@casama/client`) | The whole API layer. It runs in browsers |
| Send a message, follow a run (SSE), cancel | `/v1/conversations/{id}/messages`, `/v1/runs/{id}/events`, `/v1/runs/{id}/cancel` | Side panel chat. A message takes 100,000 characters and 10 attachments |
| Quick ask with context chips, used once | D-152, `client/lib/features/desktop/desktop_context.dart` | Same idea and the same text block ("From / Browser tab / Selected text"), so bots see one format |
| Approvals, secret requests, suggestions | `/v1/approvals`, `/v1/secrets/requests`, `/v1/suggestions` | The Inbox tab and notification buttons |
| Library, memory, knowledge, tasks, watchers, search | `/v1/creations`, `/v1/knowledge-sources`, `/v1/tasks`, `/v1/watchers`, `/v1/search` | Every Capture feature has an endpoint already |
| Scan-to-sign-in codes | `/v1/auth/pairing-codes`, `/v1/auth/pairing-codes/redeem` | Signing the extension in with no password typed into it |
| A person's own machine as a bot computer | D-066: `/v1/local-devices`, the device WebSocket, `packages/sandbox/src/local.ts` | Act: the browser pairs as a browser-only device over the same tunnel |
| Browser tools with element refs | `packages/agent/src/tools/computer.ts` (`browser.open`, `snapshot`, `read`, `click`, `fill`, `type`, `press`, `scroll`, `screenshot`) | Act keeps these names and refs so skills and replays carry over |
| Action rules and autonomy | `action_rules`, D-066 "high risk always asks on a person's own machine" | Act's safety model. No new approval system |
| Teach by showing and replays | `/v1/teach` (steps are click, type, key, scroll), `/v1/replays` | Teaching in your own browser posts the same steps |
| Device connections, requests and triggers | `/v1/device-sources`, `/v1/device-requests`, platform `web` already in the enum | Browser as a device |
| Push targets | `devices` table (FCM tokens, platform `web` allowed), attention rules | Extension notifications |
| Voice | `/v1/voice/transcribe`, `/v1/messages/{id}/speech`, `/v1/voice/session` | Dictation, read aloud, live call in the panel |
| Remote settings and analytics | `/v1/app-config`, `packages/contracts/analytics/catalog.json`, `/v1/me/analytics-opt-out` | Kill switch, feature flags, events |

Gaps the extension closes that are already written down as open: the Windows browser tab in quick
ask ("no stable API without a browser extension", `docs/NEEDS-FROM-OLIVER.md`), and the web app's
share target and on-request screen snapshot (D-152).

Two things do not exist and have to be built (§10): `browser.*` tools only know how to run the
`agent-browser` command on a computer, and local devices only know `macos`, `windows` and `linux`.

## 2. What the store and Chrome allow

These rules shape the design, so they come before the features.

**Store policy**

- **Single purpose.** One narrow, easy-to-understand purpose. Unrelated bundles must be split.
- **Minimum functionality.** No extension whose purpose is launching another app or web page, and
  none whose function comes only from linking elsewhere.
- **Limited use (tightened 2026-07-01, enforced from 2026-08-01).** Data collected must be strictly
  necessary for the disclosed purpose. Collecting browsing activity is prohibited unless it is a
  user-facing feature described prominently in the listing and in the extension. No ads use, no
  sale. People at Casama may read a user's data only with that user's consent for that data, or in
  the narrow security and legal cases.
- **Disclosure and consent.** What is collected and why is shown prominently before it happens,
  and the person agrees. Later changes are disclosed again. A page on our site must state that
  data use follows the Limited Use rules.
- **No remote code.** All logic ships in the package. No remote scripts, no `eval` of fetched text,
  no "interpreter for remote commands, even fetched as data". Remote logic is allowed only through
  the Debugger API and the User Scripts API. Remote config and feature flags are fine when the
  logic they switch is in the package. Minified code is fine; obfuscated code is not.
- **Narrowest permissions.** No permission may be asked for ahead of the feature that needs it.
- **Notifications** may not carry promotions.
- **New in 2026:** extensions built to get around the safety limits of AI services are banned. We
  don't do that, and the listing should not sound like it.

**Review**

- Most reviews finish in a few days; they can take a few weeks. Broad site access, sensitive
  permissions, lots of code, a new developer account and a new extension each slow it down.
- A new permission that carries a warning switches the extension off on update until the person
  accepts. Optional permissions asked for at run time don't do this.
- These permissions cannot be optional: `debugger`, `declarativeNetRequest`, `devtools`,
  `geolocation`, `mdns`, `proxy`, `tts`, `ttsEngine`.

**Chrome facts the design leans on**

| Fact | Consequence |
|---|---|
| `sidePanel.open()` only works from a user action (toolbar click, shortcut, right-click menu, a click on an extension page or content script) | The panel never opens by itself. A notification click can open a tab, not the panel |
| `activeTab` is granted by the toolbar icon, a shortcut or the right-click menu, not by a click inside the side panel | Without wider site access, switching tabs means pressing the shortcut again before the panel can read the new page. This is why "site access" is a first-run choice (§8) |
| An open WebSocket with traffic keeps the service worker alive (Chrome 116) | The device tunnel for Act can live in the service worker, with a 20-second heartbeat |
| Silent web push is allowed for extensions (Chrome 121) | Notifications and badge updates arrive with the panel closed |
| The debugger attaches to tabs and frames, with child frames in one session (Chrome 125), and offers the Accessibility, DOM, Input, Page, Network, Console, Runtime and Emulation domains among others | It can do everything `agent-browser` does, in the person's real tabs |
| While attached, Chrome shows its own "started debugging this browser" bar on every tab; its Cancel detaches | We can't hide it, so we use it: Cancel is treated as Stop |
| `tabGroups` can name, colour, collapse and move groups; tabs join a group through `tabs.group` | The bot's tab group |
| One offscreen document at a time; reasons include audio playback, user media and DOM parsing | Read aloud, tab audio and parsing share one document |
| Built-in AI (Prompt, Summarizer, Translator) is available to extensions from Chrome 138 on desktop with about 22 GB free disk and more than 4 GB of video memory, or 16 GB of RAM and 4 cores | On-device features are a bonus where available, never a requirement |
| At most four suggested keyboard shortcuts; they need Ctrl or Alt; people can add more themselves | Pick the four that matter (§6, A8) |

## 3. Goals and what this is not

**Goals**

1. A real presence in the Chrome Web Store that brings new people to Casama and gives current
   users a reason to keep Casama open all day.
2. The most complete bot-in-the-browser extension: everything the leading ones do (Claude in
   Chrome, HARPA, Sider, Monica), plus what only Casama has: many bots, memory, routines, the
   Library, approvals with rules, self-hosting, and the same bots on the phone.
3. Works with Casama Cloud, a self-hosted server and a Casama Link address, from one listing.
4. Passes review the first time and stays inside the 2026 data rules with room to spare.

**Not goals**

- Replacing the app. Setup, billing, admin, the board and bot editing stay in the app; the
  extension links to them.
- A second place where product rules live. Approvals, action rules, limits and credits are decided
  by the server, as today.

## 4. Principles

1. **Read only when asked.** The extension reads a page when the person asks about it, or when a
   bot they allowed is working in its own tab group. It never reads pages in the background.
2. **Show what was sent.** Every message lists the context that went with it. Each part can be
   switched off before sending, as in quick ask.
3. **Always visible, always stoppable.** While a bot acts there is a frame, a banner with Stop and
   Chrome's own bar. Touching the tab pauses the bot.
4. **The server decides.** The extension asks the API whether an action may happen. It holds no
   rules of its own that a tampered copy could skip.
5. **Smallest permission that works, asked at the moment it is needed**, with a sentence saying why.
6. **Small and fast.** The panel paints in well under a second. The package stays under a few
   megabytes. No framework heavier than the job.
7. **Same words as the app.** Bots, routines, Library, Approvals, computers, and "your browser" for
   the new thing.

## 5. Words

| Word | Meaning |
|---|---|
| **Casama for Chrome** | The extension. The store name is "Casama" |
| **The panel** | The side panel: Chat, Inbox, Library, Search |
| **Context** | What goes with a message: page address, title, selection, page text, screenshot, file |
| **Site access** | How much of the web the extension may see: on click, on sites you pick, or on all sites |
| **Your browser** | This Chrome, paired so allowed bots can work in it |
| **The bot's tab group** | The one group a bot may act in, named after the bot |
| **Page command** | A saved prompt run with `/` or from the selection bar |

## 6. The full feature set

Phase numbers refer to §15. "Opt-in" means off until the person turns it on.

### A. Ask

| # | Feature | What the person gets | Built on | Phase |
|---|---|---|---|---|
| A1 | Side panel chat | Pick a bot; start or continue a conversation (General, topics, group chats); streamed replies; Stop | `sidePanel`; messages and run events through `@casama/client` | 1 |
| A2 | Cards in replies | Buttons, forms with checks, images, video and audio that bots show. Anything the panel can't draw becomes an "Open in Casama" card | A TypeScript renderer for the basic card catalog (D-086, D-322) | 1 |
| A3 | Context chips | Page address and title, selected text, readable page text, a screenshot of what's visible. Each is a chip that can be switched off; long text shows its size | `activeTab`, `scripting`, `tabs.captureVisibleTab`; the D-152 text block | 1 |
| A4 | Region screenshot | Drag a box over part of the page and ask about it | A page overlay | 1 |
| A5 | PDFs | The text of the PDF open in the tab, or the file itself as an attachment | Bundled pdf.js | 1 |
| A6 | Video transcripts | YouTube transcript with timestamps; "what did they say about X"; ask at the current moment | Reads the page's caption tracks | 1 |
| A7 | Right-click menu | On a selection: Ask, Explain, Summarize, Translate, Rewrite, Remember. On a link, image or page: Ask about it, Save it, Watch it | `contextMenus` | 1 |
| A8 | Keyboard shortcuts | Open the panel; ask about the selection; screenshot to bot; save the page | `commands` (four suggested) | 1 |
| A9 | Address bar | Type `ca`, a space and a question | `omnibox` | 1 |
| A10 | Attachments | Drop files, paste pictures, drag an image from the page into the chat | Panel | 1 |
| A11 | Voice | Dictate a message; have a reply read aloud | `/v1/voice/transcribe`, `/v1/messages/{id}/speech`, offscreen audio | 1 |
| A12 | Live call | Talk with a bot in the panel while looking at the page | `/v1/voice/session` | 2 |
| A13 | Page commands | Saved prompts run with `/` ("Summarize for my team", "Draft a reply"). A bot's skills appear in the same list. Synced to the account | A small new table (§10) | 2 |
| A14 | Other tabs as context | Type `@` to add other open tabs, or a whole tab group | Optional `tabs` | 2 |
| A15 | Selection bar | A small bar beside selected text with the top actions and your page commands. Opt-in per site access | Content script | 2 |
| A16 | Write in any text box | A button or shortcut in a field: draft, rewrite, shorten, reply in your voice (from About you); the text is inserted for you to send | Content script | 2 |
| A17 | Site helpers | YouTube (summary, chapters), Gmail (thread summary, draft reply), GitHub (pull request and issue summary, review notes), search results (an answer beside them), long threads on X, LinkedIn and Reddit, shopping pages (compare, watch the price). Each helper has its own switch | Content scripts per site | 2 |
| A18 | Translate and read a page | Translate the page in place; read it aloud | On-device Translator where available, otherwise the bot | 2 |
| A19 | Point at it | Click a table, button or section to mean "this" | Page overlay | 2 |
| A20 | This page before | Reopening a page shows your past chats and highlights about it | `/v1/search` by address; conversations remember their source address (§10) | 2 |

### B. Capture

| # | Feature | What the person gets | Built on | Phase |
|---|---|---|---|---|
| B1 | Save to Library | The page as Markdown, PDF or a screenshot; an image; a selection as a note; into a Project if wanted | `/v1/creations`, the server's PDF renderer | 1 |
| B2 | Remember this | A selection or fact into a bot's memory or About you | Memory, `/v1/me/facts` | 1 |
| B3 | Add to knowledge | This page, or this whole site as a website source, for one bot or the workspace | `/v1/knowledge-sources` | 1 |
| B4 | Make a task | A ticket with the link, selection and screenshot | `/v1/tasks` | 1 |
| B5 | Offline queue | Captures made offline are kept and sent later | `storage` | 1 |
| B6 | Send to the bot's computer | A link's file or an upload goes into the bot's files | `/v1/computers/{id}/files` | 2 |
| B7 | Highlights | Highlights stay on the page, show again next visit, and bots can read them | Content script, creations | 2 |
| B8 | Read it for me | Queue pages; the bot reads them and puts the summary in the next brief | Tasks, the brief (D-312) | 2 |
| B9 | Send these tabs | A window or tab group goes to a bot as one research set | Optional `tabs` | 2 |
| B10 | Watch this page | Pick part of a page: "tell me when it changes" or "when the price drops". Public pages are checked by the server; signed-in pages in your browser (Phase 3) | `/v1/watchers` | 2, 3 |
| B11 | Bookmarks and reading list | Bring them in once as knowledge. Opt-in | Optional `bookmarks`, `readingList` | 4 |
| B12 | Record this tab | A short video with sound for a bot, such as a bug report | `tabCapture`, offscreen | 4 |

### C. Act: bots in your own browser

| # | Feature | What the person gets | Built on | Phase |
|---|---|---|---|---|
| C1 | Pair this browser | "Let bots use this browser": pick which bots, see it under Device connections, unpair any time | `/v1/local-devices` with a browser-only device | 3 |
| C2 | The same browser tools | Open, snapshot, read, click, fill, type, press, scroll and screenshot, with the same element refs, so existing skills and replays work. New: list and switch tabs, wait, upload, download, answer page dialogs | `debugger`; a browser backend on the server (§9.5) | 3 |
| C3 | The bot's tab group | Named and coloured after the bot. The bot acts only inside it. Drag a tab in to share it, out to take it back. Other tabs are never read | `tabs.group`, `tabGroups` | 3 |
| C4 | Always visible | A frame and a banner with Stop on tabs being worked in; a live step list in the panel; Chrome's own bar, whose Cancel also stops | Overlay, `debugger.onDetach` | 3 |
| C5 | Take over, hand back | Touching the tab pauses the bot. Hand back resumes it. The "hand off" action rule lands here | Takeovers | 3 |
| C6 | Site permissions | Per site: this once, always, or never. Some kinds of site are off by default. Workspaces can set their own lists | New columns on the device (§10) | 3 |
| C7 | Approvals | Sending, paying, deleting, publishing, sharing and signing in follow action rules. High-risk steps always ask in your own browser. Purchases and password changes are always handed to you | `action_rules`, D-066 | 3 |
| C8 | Fill this form | From About you, memory or a file. The bot fills; you check and submit | C2, `/v1/me/about` | 3 |
| C9 | Get the data out | A table, list or several pages of results into CSV, a sheet or the Library | C2 | 3 |
| C10 | Downloads and uploads | What a bot downloads goes to the Library or its computer. Library files can be put into a page's upload field | Optional `downloads`; debugger file input | 3 |
| C11 | Teach by showing, in your browser | Do the task once in a tab; Casama turns it into a draft skill. Password fields are never recorded; any field can be marked secret | `/v1/teach` | 3 |
| C12 | Replays | Saved steps run in your browser without the model | `/v1/replays` | 3 |
| C13 | Routines and watchers here | A routine or watcher that needs your sign-ins runs when this browser is online. If it isn't, it waits or uses the bot's cloud computer; the person chooses | Routines, watchers | 3 |
| C14 | Work in the background | The bot works in a collapsed group while you browse, and notifies you when it needs you or is done | C3, D3 | 3 |
| C15 | For developers | The bot reads console errors, network requests and the page structure of a tab in its group | Debugger's Console, Network and Log domains | 3 |
| C16 | Coding agents | Coding agents on your computer (D-320) check their work in this browser | Local MCP path (D-096) | 4 |
| C17 | Sites' own tools | When a page offers tools to agents (WebMCP), use them instead of clicking | Origin trial since Chrome 149; the interface is still changing | Watch |

Sign-ins: bots never type passwords in your browser. You are already signed in, which is the point.
A step that needs a sign-in is handed to you. Password managers (1Password, Bitwarden) stay a
feature of bots' own computers.

### D. Stay in the loop

| # | Feature | What the person gets | Built on | Phase |
|---|---|---|---|---|
| D1 | Badge | How many things are waiting for you; a colour while a bot works in this browser | `action` badge | 1 |
| D2 | Inbox tab | Approvals (Approve, Deny, Always allow), secret requests in a protected field that goes straight to the server, connect buttons, suggestions, running work with Stop | `/v1/approvals`, `/v1/secrets/requests/{id}/fulfill`, `/v1/suggestions` | 1 |
| D3 | Notifications | "Needs you" and "done" only, by default, with Approve and Deny buttons. Attention rules apply | Web push in the service worker, `devices` | 1 |
| D4 | Search | Everything in Casama from the panel | `/v1/search` | 1 |
| D5 | Library and pages | Recent things bots made; open them | Creations, page view links | 1 |
| D6 | Routines | List, Run now, pause | `/v1/routines` | 1 |
| D7 | Usage | Credits and plan at a glance; "See plans" opens the web app | `/v1/usage` | 1 |
| D8 | Switchers | Workspace, bot, account, and server (Casama Cloud, self-hosted, Casama Link) | `/v1/config` | 1 |
| D9 | Today's brief | The brief, in the panel | Notifications | 2 |
| D10 | Live view | Watch a bot's cloud computer in the panel or a small floating window | `/v1/computers/{id}/stream-session` | 4 |

### E. Browser as a device

All opt-in, per kind, under Device connections, with the same grants, retention and "what reached
the model" record as phone and desktop data (D-149).

| # | Feature | What the person gets | Built on | Phase |
|---|---|---|---|---|
| E1 | One-click sign-in | "Connect Chrome" in the web app signs the extension in | `externally_connectable`, pairing codes | 0 |
| E2 | What am I looking at? | A bot you allowed, on any surface (phone, Telegram), can ask this browser for the current tab on request | `/v1/device-sources/{key}/requests`, new kind `browser_tab` | 4 |
| E3 | Quick ask everywhere | The desktop app's quick ask gets the browser tab on Windows and Linux, through the server | `/v1/device-requests` | 4 |
| E4 | Browser triggers | Routines start when you open a site you named, finish a download, or add a bookmark. Only that event is sent | `/v1/device-sources/{key}/events` | 4 |
| E5 | Activity recap | Minutes per site per hour, site names only, for end-of-day recaps | Kind `activity`, the strict summary schema | 4 |
| E6 | Find that page | "The article I read last week": history and bookmark search on request | Optional `history`, `bookmarks` | 4 |
| E7 | Meeting captions | You start it on a Google Meet call; a banner shows; the captions go to the bot as a transcript for the Meeting notes routine | Content script on Meet | 4, decision 7 |

### F. On-device AI

| # | Feature | What the person gets | Phase |
|---|---|---|---|
| F1 | Quick answers on this computer | Summarize, explain and translate a selection free, with nothing leaving the computer, when Chrome's built-in model is present. Hidden otherwise | 2 |
| F2 | Send less | A long page is trimmed to the relevant parts on the computer before it's sent, which saves credits | 2 |
| F3 | Private model rule | Where a person requires a private model for browser data, the on-device model is used or the request is refused | 4 |

### G. Settings and trust

| # | Feature | Phase |
|---|---|---|
| G1 | Site access: on click, on sites you pick, or on all sites; changeable any time | 1 |
| G2 | Never-list, plus a guard that won't capture or act on pages with password or card fields or on known banking, health and password-manager sites | 1 |
| G3 | Which context chips are on by default (address and title on; page text off) | 1 |
| G4 | "What was sent" on every message, with a link to the run's timeline | 1 |
| G5 | Analytics switch, using the account's existing opt-out | 1 |
| G6 | First-run screen that explains what is sent and asks for agreement; uninstall feedback page; What's new | 1 |
| G7 | Signed-in devices list and "sign out everywhere" | 1 |
| G8 | Light and dark, plain backgrounds; English only; full keyboard and screen-reader use | 1 |
| G9 | Admin policy: a workspace switch for the extension and for Act, and Chrome managed settings (server address, site lists, Act off) | 3 |

## 7. What we're not shipping, and why

| Not shipping | Why |
|---|---|
| The Flutter app inside the extension | Store rule on launchers, 48 MB, sign-in tied to app.casama.ai, every update through review |
| New tab page, homepage or default search | Each is its own "single purpose" in the store's eyes, and none helps a bot |
| Ad blocking, coupons, affiliate links, a tab manager | Unrelated to the purpose; affiliate rules are a review magnet |
| Reading pages in the background, "suggestions as you browse" | Breaks principle 1 and sits on the wrong side of the 2026 browsing-activity rule |
| Incognito | Off by default in Chrome; we never ask for it |
| Copying your sign-in cookies to a bot's cloud computer | It would let cloud bots work signed in, but exporting sessions is the riskiest thing an extension can do |
| Solving CAPTCHAs, hiding from bot detection | Against site rules and store policy |
| Bots typing passwords, or submitting payments by themselves | Always handed to the person |
| A "skip all approvals" mode in your own browser | D-066 already says high-risk always asks on a person's machine |
| Running JavaScript a model wrote, outside the Debugger API | The store's remote-code rule allows remote logic only through the Debugger and User Scripts APIs |
| Bot-written page restyling (user scripts) | Possible later; needs a per-extension Chrome toggle most people never find |
| Act in Firefox or Safari | Firefox has no debugger API; Safari has no side panel |

## 8. Permissions

| When | Permission | Install warning | Used for |
|---|---|---|---|
| Phase 1, required | `sidePanel`, `activeTab`, `scripting`, `contextMenus`, `storage`, `unlimitedStorage`, `alarms`, `offscreen`, `gcm` | None | Panel, reading the page on request, menus, settings, offline saves, retries, audio, pushes |
| Phase 1, required | `notifications` | "Display notifications" | Approvals and "done" |
| Phase 1, optional | Site access: chosen sites or all sites | Asked at first run, not at install | Following the active tab, selection bar, helpers; also a self-hosted server's address |
| Phase 2, optional | `tabs` | "Read your browsing history", asked when first used | `@` other tabs, send these tabs |
| Phase 3, **required** | `debugger` | "Access the page debugger backend" and "Read and change all your data on all websites" | Act |
| Phase 3, optional | `tabGroups`, `downloads` | Asked when the browser is paired | The bot's tab group, bot downloads |
| Phase 4, optional | `bookmarks`, `readingList`, `history`, `tabCapture` | Asked per feature | E and B features that need them |

Notes:

- Casama Cloud needs no site permission to call the API: the server allows the extension's origin
  (§10). A self-hosted server on an older version is reached by granting that one address.
- The first-run screen offers the three site access modes and recommends "all sites", because of
  the `activeTab` limit in §2. Reading still happens only when asked.
- `debugger` can't be optional and can't be asked for before Act exists. So Phase 3's update
  switches the extension off once for people who installed earlier, until they accept. The update
  before it says so in What's new, and the panel explains it on first open afterwards.

## 9. How it works

### 9.1 Pieces

```
apps/extension (TypeScript, built with Vite; one package, a manifest per browser)
├─ background   service worker: session, push, menus, shortcuts, device tunnel, retries
├─ panel        side panel app: Chat, Inbox, Library, Search, settings shortcuts
├─ content      page scripts, injected on request: extract, overlay, picker, selection bar, helpers
├─ cdp          Act: attach, snapshot with refs, input, screenshots, dialogs, console, network
├─ offscreen    audio playback, tab audio, HTML parsing
├─ options      full settings page; onboarding and consent
└─ _locales/en  strings (English only for now, structured for more)
```

The panel is plain web UI. The "no WebViews" rule is about the app; an extension can only be web.
It follows the app's look: plain white or dark grey backgrounds, the same type.

### 9.2 Signing in

No password is typed into the extension.

1. **From the web app (Casama Cloud):** "Connect Chrome" in app.casama.ai makes a pairing code and
   hands it to the extension (`externally_connectable` lists only `https://app.casama.ai/*`). The
   extension redeems it at `/v1/auth/pairing-codes/redeem` and is signed in.
2. **From any signed-in Casama app:** paste the sign-in link or code that the app shows under
   "Sign in another device". This is the route for self-hosted and Casama Link servers.
3. **By email code:** type the server address and email, then the one-time code from the email.

New people: the first-run screen has "Create an account", which opens sign-up in the web app and
returns through route 1.

The access token lives in `storage.session` (memory, gone when Chrome closes). The refresh token
and the device token live in `storage.local`, readable only by the extension's own pages, never by
page scripts, and never in `storage.sync`.

### 9.3 Sending a message with context

- The panel asks the background for the active tab's context. The background injects the extractor
  with `scripting.executeScript` (allowed by `activeTab` or site access) and takes the screenshot.
- Text context goes in the message as the D-152 block, extended with "Page text:". Selections are
  cut at 8,000 characters as in quick ask; page text has its own cap and shows its size on the chip.
- Screenshots and files go as message attachments.
- Replies stream from `/v1/runs/{id}/events`. The panel catches up by sequence number if it was
  closed and reopened.

To check in Phase 0: whether a picture attached to a message needs the bot's computer awake. A
screenshot question shouldn't start a computer; if it does today, add a path that doesn't.

### 9.4 Notifications and the badge

The service worker subscribes to web push and registers the token in `devices`. Pushes are plain
text (D-312). "Approve" and "Deny" on a notification call `/v1/approvals/{id}/decision`. The badge
count comes with each push and is refreshed when the panel opens. If push can't be made to work
with the server's current sender, the fallback is a one-minute check while Chrome is open.

### 9.5 Act: bots in your browser

**Pairing.** The extension registers as a local device with platform `chrome` and one capability,
`browser`. The service worker opens the existing device WebSocket (`/v1/local-computer/connect`)
and keeps it alive with a heartbeat while the browser is paired and turned on.

**Routing.** Today every `browser.*` tool runs `agent-browser` through `exec` on a computer. That
splits into a small interface with two backends:

```
browser.* tool ─> BrowserBackend ─┬─ exec backend       agent-browser on the bot's computer (today)
                                  └─ extension backend  requests over the device tunnel to this Chrome
```

A browser-only device is not a bot's computer. The bot keeps its own computer for shell and files
and uses the person's browser only for `browser.*`. Which browser a run uses: the person's, when
the conversation was started from the extension or they say "in my browser", the browser is
online, and that bot is allowed; otherwise the bot's own. The tools take an optional `where`
(`mine` or `computer`) for the cases in between. Owner only, as in D-091: only runs acting for that
person may use their browser.

**Doing the work.** The extension attaches the debugger only to tabs in the bot's group and only
while a run is using them, then detaches. A snapshot is built from the accessibility tree with the
same `@e1` refs `agent-browser` gives, so a bot can't tell the two apart. Clicks and keys are real
input events. Frames inside the page are reached in the same session.

**Why the debugger and not page scripts.** It is the route the store's remote-code rule allows for
server-driven actions. It also gives real input events, reaches frames, sets upload fields, handles
page dialogs and reads the console and network, none of which page scripts do reliably. This is
the same choice Claude in Chrome makes.

**Stopping.** Stop in the banner, Stop in the panel, Chrome's Cancel, closing the group, unpairing
and going offline all cancel the run's browser work at once. Tool calls fail fast when the browser
is offline, as they do for the desktop companion.

### 9.6 Browser as a device

The extension registers one more device source, platform `web`, with the kinds the person turned
on. Requests ("what's the current tab") arrive over the same tunnel and are answered within the
existing 10-second window. Triggers post only the named event. The activity recap sends hourly
summaries of site names and minutes, checked by a strict server schema like `ActivitySummary`.

### 9.7 On-device AI

Feature-detected with `LanguageModel.availability()`. When the model isn't there, the buttons are
absent rather than disabled. Nothing depends on it.

### 9.8 Remote settings and updates

`/v1/app-config` carries feature flags and a minimum version. That is the kill switch: Act, any
site helper or the whole extension can be turned off from the server within minutes, without a
store review. All the code those flags switch is in the package.

Site helpers break when sites change their pages. Each helper checks for the elements it needs and
hides itself when they are missing, and reports that as an analytics event with no page data.

## 10. Server and app changes

| Change | Where | Phase |
|---|---|---|
| Allow the extension's origin in CORS by default | `apps/server/src/api/app.ts` | 0 |
| "Connect Chrome" and "Sign in another device" show a pasteable link | `client/` (web and desktop) | 0 |
| A picture attachment that doesn't wake a computer, if needed (§9.3) | `apps/server`, `packages/agent` | 1 |
| `devices.platform` accepts the extension; push sender handles its token | Migration, `apps/server` | 1 |
| Conversations remember the page they started from; search by address | `packages/contracts`, migration | 2 |
| Page commands, per person | `packages/contracts`, migration, RLS, `allow_worker`, pgTAP | 2 |
| Local device platform `chrome`; `allowed_sites`, `blocked_sites` | `packages/contracts/src/local.ts`, migration | 3 |
| `BrowserBackend` with the exec and extension backends; `where` on the tools | `packages/agent/src/tools/computer.ts` | 3 |
| Tunnel accepts browser requests from a browser-only device | `apps/server/src/api/routes/local.ts`, `packages/sandbox/src/local.ts` | 3 |
| Casama's own addresses can't be acted on (§11) | `packages/domain` | 3 |
| Workspace switches for the extension and for Act | `packages/domain`, admin screen | 3 |
| Device kind `browser_tab`; browser trigger events | `packages/contracts/src/device-data.ts` | 4 |
| Device connections screen lists the browser | `client/` | 3, 4 |
| Analytics events for the extension | `packages/contracts/analytics/catalog.json` | 1 on |
| Docs: a guide page, the privacy page, SPEC rows put back, decisions, costs | `docs-site/guide/chrome.md`, `site/privacy.html`, `SPEC.md`, `docs/` | each phase |
| Build and publish scripts; CI job | `scripts/build-extension.sh`, `scripts/publish-extension.sh` (asks first), `.github/workflows/ci.yml` | 0 |

New signed-out routes go on the contracts list, new tables get row-level security,
`public.allow_worker` and a pgTAP test, as always.

## 11. Security and privacy

**The session.** The extension holds a full account session, like the web app. Mitigations: tokens
are kept away from page scripts, the access token is memory-only, refresh tokens rotate, and the
devices list can sign the extension out from anywhere.

**Pages are untrusted.** Everything read from a page is data, never instructions. In Act:

- Text that isn't visible is left out of snapshots.
- Steps that send, submit, buy, delete, publish or share follow action rules; high-risk ones always
  ask in a person's own browser.
- Typing something read on one site into a different site asks first.
- A run can be limited to the sites it started with; leaving them asks.
- Each action is written to the run timeline and the audit log, with a screenshot.

**Places bots can't go.** Browser pages (`chrome://`), other extensions, the Chrome Web Store,
local files, incognito windows, and **Casama's own web app, API and sign-in addresses**. That last
one matters: a bot must not be able to click Approve on its own approval or edit its own rules
through the app's screens. Banking, health portals and password managers are off by default and
ask every time if the person turns them on.

**Secrets.** Secret requests are filled in a protected field in the panel and go straight to the
API. The value never enters the chat, storage or the page.

**What people at Casama can see.** Page content sent to a bot is the person's content, handled
like any chat message. Support staff read it only when the person shares it in a ticket (D-298).

**Analytics.** Feature use only: which button, which phase of a flow. Never page addresses, titles
or content. The bundled PostHog build with no remote loading, behind the existing opt-out.

**Supply chain.** Dependencies are pinned and few. The store build is reproducible from the tagged
commit, and the publish script prints the package's hash before upload.

**Testing.** Unit tests (Vitest). End-to-end with Playwright loading the built extension in
Chromium. One set of fixture pages run against both browser backends, so snapshots, refs and
actions stay identical. Hostile fixture pages (hidden instructions, fake approve buttons, lookalike
forms) in `packages/evals`.

## 12. The store listing

| Item | Plan |
|---|---|
| Developer account | A dedicated address (it can't be changed later), 2-Step Verification on, one-time fee of about $5 (confirm at sign-up) |
| Publisher | Verified through Search Console; casama.ai is already verified there, so the listing shows it as the official site |
| Name and summary | "Casama". Summary within the manifest's 132 characters: "Your AI bots in Chrome: ask about any page, save what matters, and let a bot work in your tabs while you watch." |
| Category | Workflow and planning, or Tools |
| Icon and pictures | 128×128 icon; up to five 1280×800 screenshots (panel chat, context chips, Inbox, save menu, and from Phase 3 the bot's tab group); 440×280 small tile (listings without one rank lower); 1400×560 marquee; a short video |
| Single purpose | The sentence in §0 |
| Permission reasons | One line per permission, taken from §8 |
| Remote code | "No". Server-driven actions go through the Debugger API (Phase 3) |
| Data use | Tick: personally identifiable information, authentication information, personal communications, web history, user activity, website content. Certify no sale, no unrelated use, no credit decisions |
| Privacy policy | `casama.ai/privacy` gains an extension section and the Limited Use statement |
| Support and home page | `casama.ai`, `docs.casama.ai/guide/chrome` |
| Test account for reviewers | A Casama Cloud account with a bot, given in the reviewer notes, so every feature can be reached |
| Trusted testers | Each phase goes to a private tester group before it goes public |

Things that get listings rejected, to avoid: keyword-stuffed descriptions, claims the extension
doesn't deliver, a permission with no visible feature, and data-use answers that don't match the
privacy page.

Every upload to the store is a release and needs Oliver's yes each time, as `AGENTS.md` says.

## 13. Other browsers

| Browser | Plan |
|---|---|
| Brave, Arc, Vivaldi, Opera | Install from the Chrome Web Store. Checked in testing; nothing extra |
| Edge | Same package to Edge Add-ons (free). Edge has the same side panel. No `chrome.gcm`, so approval notifications come from the once-a-minute check; other news shows in the panel and badge. Phase 5 |
| Firefox | Its sidebar uses a different interface and it has no debugger API, so Ask, Capture and Stay in the loop only (no Act, browser as a device, tab recording, meeting notes, or the page kit, whose content script needs storage closed to content scripts). Its own build from the same code. Phase 5 |
| Safari | No side panel. Not planned |
| Phones | Chrome on phones doesn't run extensions. The share sheet in the app covers it |

## 14. Cost and pricing

| Item | Cost |
|---|---|
| Chrome Web Store developer fee | About $5, once. Goes in `docs/COSTS.md` |
| Edge Add-ons | $0 |
| Push | $0 (the browser's push service) |
| On-device AI | $0 |
| Hosting | $0. Act runs on the person's computer, like the desktop companion |
| Analytics | A little more PostHog volume, inside today's per-person estimate |
| The store's cut | None. The store has no payments; upgrades open the web paywall, which the store-links rule allows on web |

What costs credits: asking about a page is a normal run, and a long page is a lot of input. The
size chip, the page-text cap and on-device trimming (F2) keep that visible and small.

Recommended pricing: the extension is free on every plan, and normal limits and credits apply. Act
is free too, since it costs us nothing to host. See decision 4.

## 15. Phases

Each phase ends at its "Done when", then all test suites run (`pnpm test`, pgTAP, the extension's
own), then a commit. Phases 2 and 3 don't depend on each other and can be built side by side.

**Phase 0: foundations.** Scaffold `apps/extension`, build and CI, the three sign-in routes, server
and workspace switchers, token handling, the options page, the first-run consent screen, remote
flags, the end-to-end harness, the CORS default, the developer account.
*Done when:* a built extension loaded in Chromium signs in to the local dev stack by each route,
lists bots, and signs out; CI builds the store zip.

**Phase 1: ask, capture, stay in the loop (first public release).** A1–A11, B1–B5, D1–D8, G1–G8.
*Done when:* from a news article, a PDF and a YouTube video, a question with context gets a
streamed answer with cards; a page is saved to the Library and shows in the app; an approval raised
on the phone is approved from a Chrome notification; the listing is submitted with Oliver's yes.

**Phase 2: everywhere on the page.** A12–A20, B6–B10 (public pages), D9, F1–F2.
*Done when:* with site access on, the selection bar and "write in any text box" work on Gmail and
three ordinary sites; each site helper survives a changed page by hiding; a watcher made by pointing
at a price fires on a test page; on a computer with Chrome's model, a selection is summarized with
the network off.

**Phase 3: your own browser.** C1–C15, B10 for signed-in pages, G9, the `debugger` update.
*Done when:* the acceptance test from the original spec passes: a bot finishes a task on a site the
person is signed in to, without signing in again, and never reads other tabs. Plus: the shared
fixture pages pass on both backends; every hostile fixture is refused or asks; Stop works from all
five places; a skill taught in the browser replays in it; Casama's own addresses are refused.

**Phase 4: browser as a device, and the long tail.** E2–E7, B11–B12, C16, D10, F3.
*Done when:* a bot on Telegram answers "what's on my screen" from the paired browser with the read
shown in the timeline; "when I open my bank's site" does *not* work (blocked kind) while "when I
open the team wiki" starts its routine; quick ask on Windows carries the tab.

**Phase 5: other browsers.** Edge listing; Firefox build without Act.
*Built (2026-11-17):* Edge's listing kit for the unchanged store zip (`store/edge/`); the Firefox
build (`--mode firefox`, sidebar, no Act, device, recording, captions or page kit) with its AMO kit
(`store/firefox/`), a source zip for Mozilla's review, Mozilla's linter in CI, and an end-to-end
test in Firefox against the local server. Uploads wait for Oliver (§19).

Relative size: Phase 0 small, Phase 1 large, Phase 2 large, Phase 3 the largest and the riskiest,
Phase 4 medium, Phase 5 small.

## 16. Decisions for Oliver

| # | Question | Recommendation |
|---|---|---|
| 1 | Reopen D-123 and build the extension, including "your own browser"? | Yes. It is the one thing a store listing can offer that the app can't |
| 2 | Go public at Phase 1 and accept one "accept new permissions" prompt at Phase 3, or stay in private testing until Phase 3 so the public never sees a permission change? | Public at Phase 1. A light first listing reviews faster, builds the publisher's record, and few people are affected by the one prompt. The alternative is a first submission with `debugger` from a brand-new developer, the slowest review there is |
| 3 | One extension, or a light one plus a separate "browser control" one? | One. Two listings split the reviews, the users and the story |
| 4 | Is the extension free on all plans, Act included? | Yes. It costs nothing to host and it is the acquisition channel. Limits and credits apply as usual |
| 5 | Recommend "all sites" access on the first-run screen? | Yes, with the other two modes one tap away. Without it the panel can't follow tab switches (§2) |
| 6 | Which sites are off for Act by default? | Banking and payments, health portals, password managers, government ID sites, plus Casama's own addresses, which are always off |
| 7 | Meeting captions (E7)? Casama's line today is "no bot in your calls"; this keeps that, but it records what others say | Leave for Phase 4 and decide then. It needs a consent notice and a look at recording law |
| 8 | Activity recap and history search (E5, E6)? They are the features closest to the store's browsing-activity rule | Build last, off by default, and drop them if review pushes back |
| 9 | Store name and account email | "Casama", from a dedicated developer address under the Stackwares Google account |
| 10 | Where it's built | A separate worktree and branch, as Casama Link was |

## 17. Risks

| Risk | What happens | What we do |
|---|---|---|
| Prompt injection in your own browser | A page tricks a bot into acting with your sign-ins | §11: untrusted pages, rules on every risky step, cross-site check, blocked places, hostile fixtures in evals. The risk gets smaller, not zero, and the docs say so |
| Review rejects or stalls the `debugger` update | Act is late | Phase 1 is already live and unaffected; reviewer notes explain the Debugger API use and give a test account |
| The 2026 data rules are read strictly | A feature has to change | Read only when asked; E5 and E6 are droppable; data-use answers match the privacy page |
| Chrome's debugging bar puts people off | They think something is wrong | First-run and pairing screens show it and explain it; we attach only while working |
| Site helpers break | A button disappears | Self-hiding helpers, remote off switch, an event when it happens |
| A second card renderer drifts from the app's | Cards look or behave differently | Only the basic catalog; shared fixtures; "Open in Casama" for the rest. Look at the open-source A2UI web renderer before writing one |
| Two browser backends drift apart | A skill works on a computer but not in your browser | One fixture set run against both in CI |
| Token theft from the extension | Full account access | §11 session handling; devices list; short access tokens |
| A long page burns credits | Surprise cost | Size chip, cap, on-device trimming |
| Policy or API changes at Google | Rework | Flags for everything; `debugger` use kept behind one module; WebMCP only watched for now |
| Notification noise with the desktop app also open | Double alerts | Extension default is "needs you" and "done" only |

## 18. How we'll know it worked

- Installs, and the share that sign in within a day.
- New accounts whose first session came from the extension.
- Weekly people who ask about a page; captures per person per week.
- Approvals answered from Chrome, and how fast compared with the phone.
- From Phase 3: browsers paired, runs that used a person's browser, how often Stop is pressed, and
  how often a risky step was refused.
- Store rating and review themes.
- Uninstalls, with the reason from the feedback page.

## 19. Left for Oliver

What the build can't finish without Oliver: accounts, store uploads, production. Kept up to date
as each phase lands.

| # | What | Why it waits | Phase |
|---|---|---|---|
| 1 | Create the Chrome Web Store developer account (dedicated address, 2-Step Verification, the one-time fee) | Store accounts need Oliver | 0 |
| 2 | Create the store item as a draft, then copy its public key (Package, View public key) into `DEV_KEY` and its id into `DEV_EXTENSION_ID` in `apps/extension/src/manifest.ts`, the server's `CHROME_EXTENSION_IDS` default, `infra/compose/docker-compose.yml` and `client/lib/core/chrome_extension.dart` (`test/ids.test.ts` checks they agree) | Until then the store build's id is unknown, so Casama Cloud's CORS and Connect Chrome only know the dev id | 0 |
| 3 | Deploy the server change that allows the extension's origin (`CHROME_EXTENSION_IDS`) and the web app's Connect Chrome | Production deploys need Oliver's yes | 0 |
| 4 | Set `FCM_SENDER_ID` (the Firebase project number) in production's env and deploy Phase 1's server changes: `POST /v1/media`, `media:` attachments, chrome pushes, migration `20270201150101_chrome_extension.sql` | Production env and deploys need Oliver's yes | 1 |
| 5 | Check a real push reaches the extension: sign the store or dev build in to production after item 4, raise an approval, and approve it from the notification. Locally it's covered by tests and the poll fallback, since the local stack has no Firebase project | Needs the production Firebase project | 1 |
| 6 | Read the new "Casama for Chrome" section of `site/privacy.html` (it states the Limited Use commitment), set its effective date, then `scripts/deploy-web.sh` for it, `/chrome/whats-new`, `/chrome/uninstalled` and the docs' `guide/chrome` | Legal text and a production deploy | 1 |
| 7 | Make the reviewer account on Casama Cloud: email and password, a "Researcher" bot and an "Approver" bot whose action rule asks before replying; save it to Vaultwarden as "Chrome Web Store reviewer" and paste it into the reviewer notes | Accounts on production | 1 |
| 8 | Submit Phase 1 from `apps/extension/store/listing.md`: trusted testers first, then public (decision 2). The pictures are in `apps/extension/store/` | Store uploads need Oliver's yes each time | 1 |
| 9 | The local dev database has `20270201150101_chrome_extension.sql` applied with `psql` but not recorded as applied; it's idempotent, so the next `supabase migration up` re-runs it harmlessly | Note only | 1 |
| 10 | Deploy Phase 2's server changes: migration `20270201150103_chrome_phase2.sql` (page commands, highlights, `conversations.source_url`), `/v1/me/page-commands`, `/v1/me/highlights`, `/v1/me/page-history`, `POST /v1/watchers`, the `highlights.search` tool and the brief's read-for-me line | Production deploys need Oliver's yes | 2 |
| 11 | The privacy page's Chrome section gained Phase 2 bullets (on pages, highlights and page commands, other tabs, on-device, live calls); read them before the next `scripts/deploy-web.sh`, with the docs' updated `guide/chrome` | Legal text and a production deploy | 2 |
| 12 | Submit the Phase 2 update (trusted testers, then public). Optional `tabs` is new and is asked at first use, so existing users see no prompt. Re-render the store pictures first if you want the selection bar in them | Store uploads need Oliver's yes each time | 2 |
| 13 | Try quick answers (F1) in a real Chrome with the built-in model downloaded (chrome://on-device-internals), with the network off. The tests use a stand-in model | Needs a computer with Chrome's model | 2 |
| 14 | Try a live call from the panel against production (Gemini key set): the local tests fake Gemini Live | Needs the production Gemini key | 2 |
| 15 | The local dev database has `20270201150103_chrome_phase2.sql` applied with `psql` but not recorded, like item 9 | Note only | 2 |
| 16 | Deploy Phase 3's server changes: migration `20270201150104_chrome_phase3.sql` (browser devices, `organizations.chrome_*`, `routines.browser`, browser teach sessions), the internal browser routes, the browser backend and tools in the worker, browser watchers. Browser devices need `LOCAL_COMPUTERS` on (the default) | Production deploys need Oliver's yes | 3 |
| 17 | Submit the Phase 3 update: it adds `debugger` and `tabGroups`, so existing users see Chrome's "accept new permissions" prompt once (decision 2). Use the listing's new `debugger` justification, single purpose and reviewer steps; trusted testers first | Store uploads need Oliver's yes each time | 3 |
| 18 | Read the privacy page's new "Bots in your browser" bullet and the guide's "Bots in your browser" section before the next `scripts/deploy-web.sh` | Legal text and a production deploy | 3 |
| 19 | Try Act in a real Chrome against production with a real model: a signed-in site of your own, a routine set to "my browser", and a watcher on a signed-in page. The tests drive the extension through the internal route without a model, and the server tests use a fake model | Needs production and a real model | 3 |
| 20 | Run the new `browser-hidden-instructions` eval live with the next full eval run (item in `docs/NEEDS-FROM-OLIVER.md`, now 35 tasks) | Live evals need Oliver's go-ahead | 3 |
| 21 | The local dev database has `20270201150104_chrome_phase3.sql` applied with `psql` but not recorded, like item 9 | Note only | 3 |
| 22 | Frames from other sites (out-of-process iframes) aren't in a bot's snapshot yet; same-site frames are. Chrome's flat debugger sessions would add them | A follow-up, not a blocker | 3 |
| 23 | Deploy Phase 4's server changes: migrations `20270201150105_chrome_phase3_review.sql` and `20270201150106_chrome_phase4.sql`, browser device kinds and triggers, `POST /v1/device-requests`, `GET /v1/device-triggers/browser`, `GET /v1/bots/{id}/model-privacy`, `/mcp/browser`, and the app's Device connections and quick ask changes in the next app builds | Production deploys need Oliver's yes | 4 |
| 24 | Decide meeting captions (decision 7) for real: it's built behind the `chrome_meeting_captions` remote flag, off. Turning it on for anyone is a remote-config change; read the consent step and the privacy bullet with recording law in mind first | Legal call | 4 |
| 25 | Try meeting notes on a real Google Meet call: Meet's caption markup changes, and the collector looks for its captions region by role and label. The unit tests cover the transcript only | Needs a real Meet call | 4 |
| 26 | Try a coding agent checking its work in a real browser: Claude Code reading `--mcp-config` with `${CASAMA_BROWSER_TOKEN}` and Codex's `bearer_token_env_var` against a local dev server, through the desktop app. Codex may ask before MCP tool calls in `exec`; if it does, add `approval_policy` for the server. The tests use a fake computer | Needs real Claude Code and Codex sign-ins | 4 |
| 27 | Submit the Phase 4 update: it adds `tabCapture` (no warning) and new optional permissions (`history`, `bookmarks`, `readingList`, `downloads`, `idle`, Meet's address), asked only when switched on, so existing users see no prompt. The listing has their justifications and the data-usage answer for history | Store uploads need Oliver's yes each time | 4 |
| 28 | Read the privacy page's new Phase 4 bullets (this browser as a device, bookmarks, recording a tab, meeting notes, coding agents) and the guide's two new sections before the next `scripts/deploy-web.sh` | Legal text and a production deploy | 4 |
| 29 | Live view in the extension polls the screenshot address about once a second instead of WebRTC; the app has the full viewer ("Take over in Casama"). WebRTC in the panel is a follow-up if people watch there a lot | A follow-up, not a blocker | 4 |
| 30 | The local dev database has `20270201150105_chrome_phase3_review.sql` and `20270201150106_chrome_phase4.sql` applied with `psql` but not recorded, like item 9 | Note only | 4 |
| 31 | ~~Create the Edge Add-ons developer account and submit the store zip~~ Submitted 2026-11-21, in review; Edge id `danikigkoiofpcecjobopcgdflgcmchm` (`store/edge/listing.md`) | Done | 5 |
| 32 | ~~Add the Edge id to `CHROME_EXTENSION_IDS` and `chromeExtensionIds`~~ Done 2026-11-21: `danikigkoiofpcecjobopcgdflgcmchm` is in the server and compose defaults (server deployed, 9fa874a13; CORS checked) and in the web app (build 69 live on app.casama.ai) | Done | 5 |
| 33 | Create the Firefox Add-ons (AMO) developer account and submit `casama-firefox-<version>.zip` with its `-source.zip`, using `apps/extension/store/firefox/listing.md`. Check the source zip builds the same add-on in a clean folder first (its steps are in the reviewer notes) | A store account and an upload | 5 |
| 34 | Deploy the server's `FIREFOX_EXTENSIONS` CORS rule (on by default) with the next server deploy. Until then Casama for Firefox reaches Casama Cloud only with site access for all sites, or after its "Allow access" button | A production deploy | 5 |
| 35 | Try Casama in a real Edge: the side panel, approval notifications from the once-a-minute check (Edge has no `chrome.gcm`), Act with Edge's debugging bar, quick answers with Edge's built-in model where present, and Connect Chrome after item 32. Edge isn't installed on this Mac, and the tests run in Chromium | Needs Edge | 5 |
| 36 | Try Casama for Firefox in a real Firefox: the sidebar from the toolbar button, Alt+Shift+C, the right-click menu and `ca`; Firefox's data consent at install; a notification click opening the approval; read aloud in the sidebar; "Allow access" for a self-hosted server. The test drives the add-on in Playwright's Firefox through Firefox's debugging protocol, which can't press the toolbar or open the sidebar | Needs a person at Firefox | 5 |
| 37 | Optionally re-render the store pictures in Edge's and Firefox's frames; both listings reuse Chrome's for now | Nice to have | 5 |
| 38 | Read the privacy page's "Casama for Chrome, Edge and Firefox" changes (Edge and Firefox poll instead of Google's push service) and the guide's "Edge and Firefox" section before the next `scripts/deploy-web.sh` | Legal text and a production deploy | 5 |
| 39 | `apps/server/test/crash-resume.test.ts` fails about one run in three, also on its own and without these changes: `finishCompleted` sets the run's final status before it appends `run.completed`, so a reader can see one without the other. Not fixed here, to keep this branch to the extension | An existing flaky test to look at | 5 |
| 40 | Merging the island branch (D-324) renamed this plan's migrations from `20270201100901`–`20270201101401` to `20270201150101`–`20270201150106` (contents unchanged), so they sort after main's and the island's. They were never released, but a stack that applied the old names by hand will run them once more under the new names. They are written to be safe to run twice | Note only | merge |
| 41 | Decided 2026-11-17: Chrome shows "<bot> replied" (`reply`, D-325) like the app, and the side panel reports the chat it has open (`chat_focus`, `apps/extension/src/lib/chat-focus.ts`), so a reply you're watching doesn't buzz | Done | merge |
| 42 | Google and Apple sign-in (route 4, `chrome.identity`): add `https://<extension id>.chromiumapp.org/**` to production Auth's redirect allow list (`GOTRUE_URI_ALLOW_LIST` on the server; local `supabase/config.toml` has the dev id). Do it again with the store id, Edge's id, and Firefox's `extensions.allizom.org` address before turning on `FEATURES.providerSignIn` there. Self-hosters add theirs, or use email codes | Production config, needs Oliver's yes | 5 |

## Sources

Checked 2026-11-16.

- Chrome Web Store program policies: https://developer.chrome.com/docs/webstore/program-policies/policies
- 2026 policy update (data rules, AI rule): https://developer.chrome.com/blog/cws-policy-updates-2026
- Review process: https://developer.chrome.com/docs/webstore/review-process
- Permission warnings and the permissions list: https://developer.chrome.com/docs/extensions/develop/concepts/permission-warnings
- Listing images: https://developer.chrome.com/docs/webstore/images
- Privacy fields: https://developer.chrome.com/docs/webstore/cws-dashboard-privacy
- Registering: https://developer.chrome.com/docs/webstore/register
- `sidePanel`: https://developer.chrome.com/docs/extensions/reference/api/sidePanel
- `debugger`: https://developer.chrome.com/docs/extensions/reference/api/debugger
- `tabGroups`: https://developer.chrome.com/docs/extensions/reference/api/tabGroups
- `offscreen`: https://developer.chrome.com/docs/extensions/reference/api/offscreen
- `userScripts`: https://developer.chrome.com/docs/extensions/reference/api/userScripts
- `commands`: https://developer.chrome.com/docs/extensions/reference/api/commands
- Service worker lifetime and WebSockets: https://developer.chrome.com/docs/extensions/develop/concepts/service-workers/lifecycle
- Web push in extensions: https://developer.chrome.com/docs/extensions/how-to/integrate/web-push
- Tab audio and screen capture: https://developer.chrome.com/docs/extensions/how-to/web-platform/screen-capture
- Built-in AI in extensions: https://developer.chrome.com/docs/extensions/ai/prompt-api
- Claude in Chrome (features, permission modes, safety): https://support.claude.com/en/articles/12012173-getting-started-with-claude-in-chrome
- HARPA: https://harpa.ai/
- WebMCP status is from secondary write-ups only and should be rechecked before C17 is planned.
