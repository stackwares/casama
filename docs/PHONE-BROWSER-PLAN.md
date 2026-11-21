# A browser on your phone that your bots can use: plan

Status: **built, not shipped** (2026-11-21, D-472). Oliver took every decision in §13 as written
and asked for all phases in one go. The code for Phases 0 to 3 and the tools for Phase 4 are on
branch `phone-browser`. Nothing is deployed, no phone build has been made, and the stage is Off.
"Built so far" below says what exists and what was never run; §16 is what waits for Oliver.

## Built so far

| Part | Where | Checked how |
|---|---|---|
| Stage setting, pairing, the internal route's checks, step rules on the server, block counting, `where: "phone"`, the signed-in-site pick, the per-turn hint | `packages/domain/src/app-browser*.ts`, `browser-blocks.ts`, `browser-risk.ts`; `packages/agent/src/user-browser.ts`, `tools/browser.ts`; `apps/server/src/api/routes/local.ts`, `services/app-browser.ts`; migration `20270319100001_app_browser.sql` | Server, agent and domain tests against a fake phone |
| The page script | `packages/page-agent`, shipped as `client/assets/app_browser/page_agent.js` | 38 tests in Chromium and WebKit, including the server's step rules judging the facts it reads |
| The app: socket, session, site rules, settings and consent, browser view, asks, chat card, workspace switch, owner's stage panel | `client/lib/features/app_browser/` | Flutter tests with a fake web area; the site rules match all 198 shared cases |
| The native web area | `client/ios/Runner/AppDelegate.swift` (`AppBrowser`), `client/android/app/src/appBrowser/` | **Never compiled or run.** The Swift parses. A build needs Oliver's yes |
| Admin bot tools | `apps/server/src/services/admin-bot-app-browser.ts` | Tests through the real run loop |
| Build switch | `scripts/app-browser-switch.sh` | By hand |
| Store release kit | `client/store/app-browser/` | Drafts for Oliver to read |

Different from the plan as written:

- **Asks for risky steps show on the phone, not as a run event.** The server decides and sends the
  ask to the phone over the same socket; the app shows it in the chat and in the browser view.
  Simpler, and older apps never see anything new.
- **No "test phone" that drives real pages through the socket.** The two halves are tested apart:
  the server against a fake phone, and the real page script against the real step rules. Phase 0's
  real phones are the first end-to-end run.
- **The hostile pages run against the page script, not yet through the evals suite** for the phone.
- **The page script and the site lists ship as assets in every build** (Flutter can't leave an
  asset out by a build flag). They are data nothing reads without the switch; say so if a reviewer
  asks, or move them behind a build flavor before Stage 2.
- **"On this phone" on a tool row** shows only when the bot named the phone; a site that opened
  there by itself (T3) doesn't say so yet.
- **Phase 0's real-phone test comes after the build, not before it**, because Oliver asked for
  everything in one go. Its bar still decides whether each system gets the feature.

Platform and store facts were checked against Apple's, Google's and Flutter's pages on 2026-11-21
(sources at the end). Line numbers are from the same day. Re-find each one before editing.

## 0. Summary

Today a bot browses in one of two places: its own Linux computer, or the person's Chrome through
Casama for Chrome (D-323). A person on a phone has only the first. This plan adds a third place:
**a small browser inside the Casama app on a phone or tablet**, which a bot can drive while the
person watches, and which falls back to the bot's computer whenever the phone isn't there.

It stays a narrow tool. The bot's computer remains the default, because it works in the background,
keeps its sign-ins (D-030) and runs routines. The phone's browser is for three cases (§5): the
person asks for it, a site blocks the bot's computer, or the person has signed in to a site on the
phone for their bots.

| | Choice | Why |
|---|---|---|
| Where | iPhone, iPad and Android only | Desktops have Casama for Chrome and the desktop app; the web app can't do it |
| When it can work | Only while the person has that chat open on that phone | iOS stops an app's web page seconds after the app leaves the screen |
| What decides a risky step | The server, with the same rules Casama for Chrome uses | One copy of the safety rules, not a second one in the app |
| Its sign-ins | Its own cookie jar, on the phone only | Safari's and Chrome's sign-ins can't be shared; a separate jar is also the safer start |
| How it ships | Compiled into test builds only until the store release that describes it | Both stores forbid hidden features that are switched on later (below) |

Two findings change what was said in chat:

1. **"Build it now, switch it on later" can't mean hidden code in a public store build.** Apple's
   guideline 2.5.19 says "Don't include any hidden, dormant, or undocumented features in your app",
   and Google Play says "Don't include undocumented or hidden features that are designed to be
   activated remotely or after a certain amount of time". So the code is built now and kept out of
   public store builds by a build switch. It reaches the stores in the release that describes it to
   the reviewers and to people; from then on, the server decides who gets it and for which tasks
   (§6). A server off switch is fine: turning a described feature off is not hiding one.
2. **Android can do more than I said, and iPhone has less precedent.** Android's WebView has had
   isolated script worlds since androidx.webkit 1.16 (May 2026), so the page can't interfere with
   our script there either. On iPhone I found no well-known app that drives pages on the phone
   itself: Perplexity's Comet is on the App Store, but it runs its agent in a cloud browser. So
   **Android goes first**, and iPhone follows once its own review passes.

## 1. What exists today

Checked in the code on 2026-11-21.

- **One set of browser tools, two places.** `packages/agent/src/tools/browser.ts` has a `computer`
  backend (`agent-browser` on the bot's computer) and a `mine` backend (the person's Chrome).
  `backendFor` (line 225) picks one and falls back to the computer. Both speak the same 21 actions
  (`BROWSER_ACTIONS`, `packages/contracts/src/browser.ts:116`) and the same snapshot text with
  `@e1` refs.
- **How a run reaches the person's Chrome.** The extension is a browser-only device
  (`local_devices`, platform `chrome`) holding a WebSocket to the API
  (`/v1/local-computer/connect`, `apps/server/src/api/routes/local.ts:1064`). The worker calls
  `/internal/browser/:device/call` (`local.ts:729`), which checks the run acts for the device's
  owner, the bot is allowed, and the workspace switch is on, then forwards the call and writes the
  audit row for state-changing steps (`local.ts:870`).
- **Which device.** `browserDevicesFor` (`packages/agent/src/user-browser.ts:69`) takes the most
  recently seen online Chrome device. "Online" means only that the socket exists.
- **Safety rules.** Site lists are shared (`packages/domain/src/browser-guard.ts`). The rules for
  risky clicks, password, card and one-time-code fields, Enter, and text carried between sites
  live only in the extension (`apps/extension/src/lib/act/risk.ts`, 160 lines of plain TypeScript
  with no Chrome calls).
- **The phone app has no web area and no socket to the API.** Its only live channel is Supabase
  Realtime (`_userEvents`, `client/lib/core/supabase_backend.dart:3320`). The desktop app already
  opens the device socket from Dart (`client/lib/features/companion/companion_io.dart:281`). The
  app uses no platform views today.
- **The app already says which chat is on screen.** `ChatFocusReporter`
  (`client/lib/core/chat_focus.dart:19`) writes `chat_focus (user_id, client_id, conversation_id)`
  every 30 seconds while a chat is open and the app is in front; the server ignores rows older
  than 45 seconds.
- **Old app builds read device platforms strictly.** `LocalDevice.platform` decodes with
  `$enumDecode` (`dart/casama_api/lib/src/model/local_device.g.dart:293`), so one device with an
  unknown platform breaks the whole list in a shipped build.
- **No block detection.** Nothing notices a CAPTCHA or "access denied" page; the prompt tells the
  bot to ask for a takeover (`packages/agent/src/context.ts:70`).
- **Today's sign-in order** (D-468): the person's Chrome, a saved login, `secrets.request`, then a
  takeover of the bot's computer.
- **Related plans.** The floating screen card (`docs/SCREEN-CARD-PLAN.md`, approved) is the slot
  this plan shows the page in. `docs/COMPUTER-PLACES-PLAN.md` (not started) is about computers,
  not browsers; neither depends on the other.

## 2. What the phones and the stores allow

| | iPhone and iPad (WKWebView) | Android (WebView with androidx.webkit) |
|---|---|---|
| Our script kept apart from the page's | Yes, content worlds, iOS 14+ | Yes, isolated worlds, androidx.webkit 1.16+, checked on the device (`JS_INJECTION_IN_FRAME_AND_WORLD`) |
| Script in every frame, before the page's | Yes (`WKUserScript`) | Yes (`addJavaScriptOnEvent`, document start) |
| A separate cookie jar | Yes, iOS 17+ (`WKWebsiteDataStore(forIdentifier:)`) | Yes, profiles (`MULTI_PROFILE`), chosen before the first page loads |
| Shares Safari's or Chrome's sign-ins | No | No ("the system's browser app doesn't share its application data with your app") |
| Real taps and keys | No public way; script-made events are marked untrusted | Expected yes by sending touch events to the view; no Google page says so, **test in Phase 0** |
| Stop a page before it loads | Yes, every navigation and redirect | First address only; redirects are checked on landing, as the extension does |
| Picture of the page | Yes (`takeSnapshot`) | Yes; **test in Phase 0** with the app lock's screenshot block on |
| Pop-up dialogs, file pickers, downloads | Yes | Yes |
| Passkeys on other people's sites | No, only for the app's own domains | No, only for the app's own domains |
| Runs with the app in the background | No, about 30 seconds at most | Not reliably; treated as no |

Other facts that shape the plan:

- **Google sign-in may refuse.** Google bans its OAuth sign-in in embedded web views that can
  inject scripts or read cookies, which is what this is. Whether signing in directly at
  accounts.google.com is refused is not stated; assume it can be.
- **Apple, hidden features (2.5.19) and review notes (2.3.1(a)):** new features must be described
  "with specificity" in the review notes and be reachable by the reviewer.
- **Apple, data (5.1.2(i)):** personal data shared with third parties, "including with third-party
  AI", needs clear disclosure and explicit permission. **5.1.1(v):** sign-in tokens for social
  networks may not be stored off the device; ours never leave it.
- **Apple, privacy answers:** "Browsing History" is "information about content the user has viewed
  that is not part of the app, such as websites". Data counts as collected when it is kept longer
  than serving the request needs. Play has the matching type "Web browsing history".
- **Play, web views:** the rule against "a webview of a website without permission" is aimed at
  apps whose main purpose is that. It doesn't plainly apply here; that reading is mine.
- **Neither store has a rule about an agent acting on other sites.** Apple's 5.2.2 says an app that
  uses a third-party service must be permitted by its terms; the person, not Casama, chooses the
  sites.
- **Flutter packages don't fit.** `webview_flutter` has no isolated worlds or script injection.
  `flutter_inappwebview` has had no stable release in about two years, and its Android "content
  world" is an iframe trick. So this is our own native code, as the sign-in sheet was (D-243).
- **Web areas in Flutter are platform views** (`UiKitView`, `AndroidView`), with known limits on
  effects drawn over them. This would be the app's first; Phase 0 checks it on Flutter 3.50.

## 3. Principles

1. **The computer stays the default.** The phone's browser is chosen for a reason (§5), never
   because it happens to be there.
2. **Never without the person.** It works only while they have that chat open on that phone, they
   can see the page, and one touch on it pauses the bot.
3. **Falls back, never blocks.** When the phone isn't there, the bot is told so and carries on with
   its own computer.
4. **One copy of the safety rules.** Risky-step rules run on the server from the same file the
   extension uses.
5. **Sign-ins stay on the phone.** Cookies never leave the device, and the bot never sees a
   password, card number or one-time code.
6. **Nothing hidden in a store build.** Test builds until the release that describes it.
7. **A web area is for other people's websites only.** No Casama screen and no plugin screen is
   ever drawn in it (§13, decision 1).

## 4. What a person gets

- **Turning it on.** Settings → Device connections → "Browser on This Phone". The first time, a
  screen says what it is, that pages a bot reads there are sent to Casama and the bot's AI model,
  that sign-ins stay on the phone, and asks for a clear yes. Then they pick which bots may use it.
- **Signing in to a site.** From the same place they open a site in the browser, sign in
  themselves, and tap "Let My Bots Use This Site". Nothing from this browsing is sent anywhere;
  only a bot's own steps are.
- **Watching.** While a bot works there, the floating card from the screen-card plan shows the
  live page. A tap opens it full size with the site's name, the bot's name, Stop, and Take Over.
- **Taking over.** Touching the page pauses the bot at once. Hand Back resumes it. Passwords,
  cards, codes and CAPTCHAs are always the person's to type, right on the page.
- **Being asked.** The first visit to a site asks (Once, Always, Never). Risky steps (send, post,
  delete, share, sign in, submit) ask each time. Purchases and password changes are handed over.
- **Stopping.** Stop in the card, in the full view and in the chat; leaving the chat or the app
  also stops the bot's use of the phone.
- **Clearing.** One button clears the browser's data; each site can be removed on its own.

## 5. When a bot uses it (the right task)

**It can be used only when all of these are true:**

1. The server's stage allows this person (§6) and the workspace switch is on.
2. The person turned it on for this phone and allowed this bot.
3. The run was started by that person's own chat message and acts for them. Routines, check-ins,
   runs for teammates and shared links never use it.
4. The app is in front with **this chat open on this phone** (a fresh `chat_focus` row from the
   phone's client id) and the phone's socket is connected.
5. The phone's WebView is new enough (iOS 17+; on Android the feature checks in §2).

**Then it is used for one of three reasons**, each switched on separately (§6):

| | Reason | What happens |
|---|---|---|
| T1 | **The person asks** ("do it on my phone", "open it here") | The bot passes `where: "phone"` |
| T2 | **The site blocks the bot's computer** (a CAPTCHA, "access denied", "unusual traffic") | The tool result tells the bot the phone is available; the person is asked once per site before it moves there |
| T3 | **The person signed in to that site on the phone** (its "always" list) | A first `browser.open` for that site goes to the phone without asking again |

**Never:** banking, health, password manager and government ID sites unless the person switches
the kind on (the same lists as Chrome, and then it asks every run); Casama's own addresses;
anything while the chat isn't on screen.

**When the phone goes away mid-task** (the person leaves the chat or the app): the call fails with
a plain message, the page stays as it is for ten minutes, and the bot either waits for them or
starts again on its own computer. Nothing carries over between the two browsers.

**Sign-in order (D-468) with a phone in hand:** a site on the phone's list first, then the
person's Chrome, a saved login, `secrets.request`, and the takeover. Google, Apple and Microsoft
sign-ins stay with the takeover until Phase 0 shows which of them work in the phone's browser.

## 6. When it gets switched on (the right time)

These are my calls, made as Oliver asked. Each switch-on changes production, so each is one yes
from Oliver with the numbers attached; switching **off** is approved in advance (§13, decision 7).
The numbers are first picks and get revised once Stage 1 has real data.

| Stage | Who has it | Starts when |
|---|---|---|
| **0. Off** | Nobody. The server refuses pairing; public store builds don't contain it | Now |
| **1. Testers** | Oliver and named testers, on internal test builds (TestFlight internal, Play internal) | Phases 1–3 are done and Oliver has used it on an iPhone and an Android phone |
| **2. Public, when asked (T1)** | Everyone on a build that has it. Android first, iPhone when its review passes | All of: version 1.0 is approved on both stores (this doesn't ride the first review); 14 days in Stage 1 with at least 100 runs, no safety miss and no crash from it; a store release whose review notes, listing, privacy answers and privacy page describe it |
| **3. Plus blocked sites (T2)** | The same people | 14 days in Stage 2 with no safety miss, **and** the block count says it's needed: in 14 days, at least 5% of watched browser runs on the computer hit a block, or at least 20 different people did |
| **4. Plus signed-in sites (T3)** | The same people | 30 days in Stage 2 with no safety miss, and at least a quarter of phone-browser users have added a site |

- **A safety miss** is a step that should have asked, been handed over or been refused, and
  wasn't. Found by the hostile test pages, by reading the audit log, or by a report.
- **Back to Off the same day** on any safety miss in production, or if a store objects. The off
  switch needs no app release.
- **If blocks stay rare** (under 2% of watched runs for 60 days after launch), T2 is never switched
  on and this plan says so.
- **Who watches the numbers.** A weekly read-only check of production, started when Stage 1
  begins, reports when a stage's bar is met. The admin bot (D-435) gets a tool to show the stage
  and the numbers, and to change the stage with Oliver's approval.
- **The block count starts first.** Phase 0 adds block detection to the computer's browser, which
  needs only a server deploy, so the numbers for Stage 3 exist before any phone has the feature.

## 7. What's not in this plan

| Not doing | Why |
|---|---|
| Mac, Windows, Linux and the web app | Casama for Chrome and the desktop app cover them; Linux would need webkit2gtk (D-243) |
| Routines, check-ins, watchers, background use | The page can't run with the app off screen |
| Using Safari's or Chrome's sign-ins | Not possible on either system |
| Pretending to be Safari or Chrome | The browser keeps its honest name; a site that refuses it is handled by falling back |
| Passkey sign-in on other sites | The systems allow it only for an app's own domains |
| Console and network logs | Web-development work belongs on the bot's computer; those two actions answer "use your computer" |
| Several tabs | One page in v1; a link that opens a new window loads in the same view |
| Teach by showing, coding agents' browser | Later, if the phone browser earns its place |
| Updating the page script from the server | It ships inside the app; both stores forbid downloaded code that changes features |

## 8. How it works

### 8.1 Pieces

```
bot's browser.* tool ─> backendFor ─┬─ computer: agent-browser on the bot's computer
                                    ├─ mine:  the person's Chrome (extension, unchanged)
                                    └─ phone: the app's browser ─ device socket ─ app ─ page script
```

- **Server.** A third backend next to the two in `browser.ts`; the tools' `where` gains
  `"phone"`. The internal browser route learns the new device kind and runs the risky-step rules
  for it.
- **App, Dart.** A device socket client (the framing `companion_io.dart` already speaks), the site
  rules, the browser's screens, the ask cards.
- **App, native.** One small module per system (Swift, Kotlin) behind a `casama/app_browser`
  channel: the web area, its separate cookie jar, script injection in an isolated world, real
  taps on Android, pictures, dialogs, files, and stopping a navigation.
- **Page script.** A new TypeScript package, `packages/page-agent`, built to one file and shipped
  as an app asset. The same file on both systems.

### 8.2 The phone as a device

- A new browser-only platform value, `app`, on `local_devices`, next to `chrome`. One value for
  both systems; the device's name and `os_version` say which.
- **Old builds:** `GET /v1/local-devices` leaves `app` devices out unless the caller passes
  `all_platforms=true`, the pattern `all_kinds` and `all_events` already use. Only new builds
  create or list one.
- Pairing is `POST /v1/local-devices` with platform `app`, refused unless the stage allows this
  person. The row also stores the phone's chat-focus client id, so the server can tell that this
  chat is open on this phone.
- The socket opens only while the feature is on and the app is in front, and closes when it
  leaves. The server's 25-second ping already drops a dead one.
- Places that assume `chrome` today and need the wider "browser-only device" check:
  `browserDevice()` (`local.ts:714`), the connect handler (`local.ts:1079`), `createLocalDevice`
  (`local.ts:353`), `browserDevicesFor` (`user-browser.ts:76`), and the database check
  `local_devices_platform_check`.

### 8.3 The page script

- **Snapshot.** Chrome's backend reads the browser's accessibility tree; a web view has none to
  read, so the script walks the page itself: roles and names from ARIA, labels and alt text;
  visibility from computed styles and boxes, with the hidden-text rules of `hiddenNodes`
  (`apps/extension/src/lib/act/snapshot.ts:91`) as the spec. Output is the same text shape and
  `@e1` refs. Refs are kept in the page and die on navigation (`stale_ref`).
- **Acting.** Clicks check nothing covers the element first. On Android the script returns the
  element's centre and native code taps there. On iPhone it sends the pointer, mouse and click
  events itself. Typing uses the browser's own insert-text path so React and rich editors see it.
- **Talking to native.** Messages, not evaluated strings: the script registers in its isolated
  world and native sends it commands. If the phone's WebView has no isolated world, the feature
  is "not available on this phone"; there is no fallback into the page's own world.
- **Frames.** The script runs in every frame. A frame it can't see into, or focus it can't find,
  is handed to the person, as the extension does.

### 8.4 The 21 actions on a phone

| Works | How |
|---|---|
| open, url, wait, scroll, stop | Native navigation and the script |
| snapshot, read, extract | The script (`EXTRACT_TABLES_JS` unchanged) |
| click, fill, type, press | The script; real taps on Android |
| screenshot | Native picture of the web area |
| dialog | Native dialog hooks |
| upload, download | A Library file set on the field; a fetch in the page, 20 MB limit, kept in the Library |
| tabs, switch_tab | One page: `tabs` lists it, `switch_tab` with an address opens it |
| console, network, page_text | Not on a phone; the answer says to use the computer |

### 8.5 Where each safety rule runs

| Rule | Where | Notes |
|---|---|---|
| Run acts for the owner, bot allowed, stage and workspace on, chat on screen | Server | The existing checks in the internal route, plus the focus check |
| Casama's own addresses, non-web addresses | Server, and again on the phone | As today for Chrome |
| Site allowed, asked or refused; kinds off by default | Phone, before the page loads | Dart, about 100 lines, tested against the same cases as the server's and the extension's. Lists come from `browser-guard.ts` at build time, added sites from `GET /v1/browser-guard` |
| Risky click, sensitive field, Enter, text carried between sites | **Server** | `risk.ts` moves to `packages/domain` and the extension imports it. For a phone, the server first asks the page for the element's facts, decides, then sends the step; the page refuses if the element changed in between |
| Purchases, password changes, password, card and code fields | Server decides, phone shows "Your turn" | The bot is told what's left and not to try another way |
| Audit row for each state-changing step | Server | Unchanged, with the device as the target |

Asks appear as a card in the chat and a sheet over the full view, wait five minutes, then count as
no. They travel as a new run event type, so shipped builds skip it instead of failing.

### 8.6 Server and database

- One migration: the wider platform check, `local_devices.client_id`, and
  `organizations.app_browser boolean not null default true` (the workspace switch, beside
  `chrome_act`). Its number is chosen after checking every branch and worktree.
- The stage lives in `instance_settings` under `app_browser`: stage, testers, which reasons are
  on, which systems. Owner-only read and write, like app config; no deploy to change it.
- `GET /v1/app-browser` tells a signed-in app whether this person may use it and why not.
- `BrowserChoice` gains `phone()`. `backendFor` handles `where: "phone"`, the T3 pick, and never
  waits for a phone.
- Block detection reads the text a `snapshot` or `read` already returned on the computer (no
  extra call), matches known challenge and refusal pages, adds a line to the tool result when a
  phone is available, and writes a `browser.blocked` audit row with the site and whether someone
  was watching.
- The bot is told about the phone only in runs where it can be used.

### 8.7 The app

- Settings → Device connections gains "Browser on This Phone": the switch and its first-run
  screen, allowed bots, sites, the off-by-default kinds, Clear Data, Sign In to a Site.
- The full view is a native Flutter screen around the web area: site name, bot name, Stop, Take
  Over and Hand Back; an address field only in the person's own sign-in flow.
- The floating card (`client/lib/features/chat/widgets/screen_card.dart`) shows the live page
  while a bot works there. Phase 0 picks between the real web area scaled down and a picture a
  second.
- Tool rows say "on this phone". New strings go in the ARB files.
- A build switch, `CASAMA_APP_BROWSER`, compiles the Dart and native code in. Without it the app
  has none of it, and `scripts/` release builds leave it off until Stage 2's release.

## 9. Privacy and security

- **What leaves the phone:** what a bot reads or pictures in its own steps (page text, snapshot,
  screenshot) and the site names in the audit log. It goes to the server and the bot's model, as
  a page read on the bot's computer does.
- **What never leaves:** cookies and sign-ins, anything the person browses or types themselves,
  and the contents of password, card and code fields (the script never reads their values).
- **Pages are untrusted.** Hidden text is left out, results are wrapped as untrusted, and the
  rules in §8.5 apply to every step. A bot acting inside a person's signed-in site can still be
  tricked by a page; the rules make that harder, not impossible, and the docs will say so.
- **The phone is checked, not trusted:** every call is tied to a run the server already allowed.
- **Store answers to update before Stage 2:** App Store "Browsing History" (linked to the person,
  app functionality, no tracking), Play "Web browsing history", `PrivacyInfo.xcprivacy`,
  `client/store/README.md`, the privacy page, and the in-app consent screen for 5.1.2(i).

## 10. Tests

- **Page script:** run the built file inside Playwright's WebKit and Chromium against the shared
  pages (`packages/evals/src/browser-pages.ts` and the pages in
  `apps/extension/e2e/phase3.spec.ts`): the snapshot shape, hidden text, covered buttons, risky
  controls, frames.
- **A test phone:** a Node device that speaks the device socket and hosts the real page script in
  Playwright's WebKit. It lets the server tests and the evals drive the whole path with no phone.
- **Server:** stage and tester gating, the old-build list filter, chat-on-screen, routines and
  teammates refused, the probe-decide-act flow (allow, deny, handed over, element changed), block
  detection, T2 and T3, the phone leaving mid-run, the audit rows.
- **App:** widget tests for the settings, the consent screen, ask cards and the card's states;
  the Dart site rules against the shared cases.
- **Hostile pages** from `packages/evals` run against all three backends in CI.
- **Real phones:** Phase 0's site table, then the same table again before Stage 2. Native code is
  only proven by a build on a device, and each build needs Oliver's yes.

## 11. Cost

No new paid service. A page read on a phone costs the same model tokens as one read on a
computer, and uses none of the plan's computer hours. `docs/COSTS.md` gets a $0 row when Phase 2
lands.

## 12. Phases

Each phase ends at its "Done when", then the full suites run once through `scripts/heavy.sh`, then
a commit. Built in its own worktree and branch.

**Phase 0: count the blocks, and prove it on real phones.**
- Block detection on the computer's browser and the `browser.blocked` rows (server only).
- A debug-only screen with the native web area on both systems, the first page script, and a
  table of 20 real sites: shops, travel, social, news, search, webmail, single-page apps, rich
  editors, frames, long lists, and one that challenges visitors.
- Answers to: are Android's taps trusted; do iPhone's script clicks work on enough sites; does a
  picture work with the app lock on; which of Google, Apple and Microsoft sign-ins work; does the
  platform view behave on Flutter 3.50; card as live page or as pictures.

*Done when:* the table is filled in for one iPhone and one Android phone. **Bar:** reading works
on 19 of 20 on both; click and fill work on 16 of 20 on Android and 14 of 20 on iPhone. A system
under its bar doesn't get the feature in v1. Both under: the plan stops here, and the block count
is kept.

**Phase 1: the server.** Everything in §8.2, §8.5 and §8.6, the test phone, moving `risk.ts`.
*Done when:* the server tests pass against the test phone, the extension's own tests still pass
on the moved rules, and with the stage Off nothing can pair.

**Phase 2: the app.** The native modules, `packages/page-agent`, the socket client, the screens
in §8.7, the build switch. The "No WebViews" rule in `AGENTS.md` and `client/README.md` gets its
exception in the same commit.
*Done when:* on both phones, a bot asked to "do it on my phone" finishes a task on a site the
person signed in to there; touching the page pauses it; leaving the chat stops it; a build
without the switch contains none of it.

**Phase 3: the reasons, and falling back.** T2 and T3, the bot's guidance, the mid-task message,
the hostile pages on all three backends.
*Done when:* a blocked site on the computer moves to the phone after one ask; a site on the
phone's list opens there; a routine never does; every hostile page asks, hands over or is
refused.

**Phase 4: switching on.** The stages in §6: the weekly check, the admin bot's tool, the review
notes, listing text, privacy answers, privacy page and docs for the Stage 2 release.
*Done when:* Stage 2 is live on Android. iPhone, Stage 3 and Stage 4 follow their own bars.

Relative size: Phase 0 small to medium, Phase 1 medium, Phase 2 the largest, Phase 3 medium,
Phase 4 small code and a lot of waiting.

## 13. Decisions

Made as Oliver asked. Say which to change; the rest stand.

| # | Question | Decision |
|---|---|---|
| 1 | The "No WebViews in the app" rule | A narrow exception: a web area may show other people's websites as a browser a bot or the person uses. It never draws a Casama screen or a plugin's screen. Written into `AGENTS.md` in Phase 2 |
| 2 | Which devices | iPhone and iPad on iOS 17+, Android with a WebView that passes the checks in §2. Nothing on desktop or web |
| 3 | How "built but off" is done | A build switch keeps the code out of public store builds until Stage 2's release describes it. From then the server stages who gets it. Not a hidden flag in a store build (§0) |
| 4 | Which system first | Android. iPhone when its own review passes, or not at all if Phase 0's bar isn't met |
| 5 | A Flutter web view package, or our own code | Our own Swift and Kotlin, about one small module each |
| 6 | Sign-ins | The browser's own cookie jar on the phone; no disguise as Safari or Chrome; a site that refuses it falls back to the bot's computer |
| 7 | Who switches stages | The rules in §6 decide. Each switch-on is one yes from Oliver with the numbers. Switching off is approved in advance |
| 8 | Price | Free on every plan; no computer hours; normal credits |
| 9 | Routines and background runs | Never use the phone's browser |
| 10 | Workspace switch | On by default once the stage allows, beside "Bots in Members' Browsers"; an admin can turn it off |
| 11 | Where it's built | Its own worktree and branch; every Flutter build on a phone asks first |

## 14. Risks

| Risk | What happens | What we do |
|---|---|---|
| A page tricks a bot inside a signed-in site | It acts with the person's sign-in | §8.5 on every step, a separate cookie jar holding only sites the person chose, sensitive kinds off, hostile pages in CI, same-day off switch |
| iPhone's script clicks fail on too many sites | It feels broken | Phase 0's bar; Android can ship alone |
| Apple or Google object to an agent browser | A rejection or a removal | Android first, never in the first review, full review notes and a test account, the feature can be left out of a build |
| The page script reads a page differently from Chrome | A skill works in one browser and not the other | One set of pages run against all three backends |
| The person leaves mid-task | Work is lost | A plain message, the page kept ten minutes, a clean restart on the computer |
| Google sign-in refuses the browser | The most-wanted sign-in doesn't work there | Takeover on the bot's computer stays the path for it |
| Old app builds meet the new device kind | Their device list breaks | `app` devices are left out unless a build asks for them |
| The app's first platform view misbehaves | Drawing or keyboard glitches | Phase 0 checks it before anything is built on it |
| The site rules on the phone drift from the server's | A refused site loads on a phone | Shared test cases; lists generated from one file |
| Nobody needs it | Work spent on a rarely used feature | Phase 0's block count and the stage bars; T2 is dropped if blocks stay rare |

## 15. How we'll know it worked

- Runs that used a phone's browser, by reason (asked, blocked, signed-in site).
- Of blocked runs on the computer, how many finished on the phone.
- How often Stop and Take Over are used, and how often a step was asked, handed over or refused.
- How often the phone left mid-task, and whether the run then finished on the computer.
- Takeovers of the bot's computer from phones, before and after.
- Phones with it turned on, and sites added per phone.

## 16. Left for Oliver

| # | What | Why it waits |
|---|---|---|
| 1 | Say yes to merging `phone-browser` into main and pushing | Your call when it lands |
| 2 | Deploy the server (migration `20270319100001_app_browser.sql`). The stage stays Off, so nothing changes for anyone; block counting starts | A production deploy |
| 3 | Yes to a Flutter run on your iPhone and on an Android phone, with `scripts/app-browser-switch.sh on` and `--dart-define=CASAMA_APP_BROWSER=true`. This is the first time the Swift and Kotlin compile; expect fixes | Builds need your yes |
| 4 | Try the 20 sites on each phone and fill in Phase 0's table. Answers wanted: do Android's taps count as real, do iPhone's script clicks work on enough sites, does a picture work with the app lock on, which of Google, Apple and Microsoft sign-ins work | Real phones are the proof |
| 5 | Name the Stage 1 testers and say yes to Stage 1 (the admin bot proposes it, or Admin → Phone Browser) | A production change |
| 6 | Read `client/store/app-browser/`: the review notes, the privacy section, the listing lines and the guide | Legal and store text |
| 7 | For Stage 2: update the App Store privacy answers and Play Data safety, add the privacy section to the site, and submit a release built with the switch on | Store forms and uploads are yours |
| 8 | Yes to Stage 2, and later to Stages 3 and 4 when the admin bot says their numbers are met | Production changes |
| 9 | The local dev database doesn't have the migration yet: `supabase migration up --include-all` after the merge | Shared local database |

## Sources

Checked 2026-11-21.

- App Store Review Guidelines (2.3.1(a), 2.5.2, 2.5.6, 2.5.19, 5.1.1, 5.1.2, 5.2.2):
  https://developer.apple.com/app-store/review/guidelines/
- App privacy details: https://developer.apple.com/app-store/app-privacy-details/
- `WKContentWorld`: https://developer.apple.com/documentation/webkit/wkcontentworld
- `WKWebsiteDataStore`: https://developer.apple.com/documentation/webkit/wkwebsitedatastore
- Passkeys in a web view ("Supporting passkeys"):
  https://developer.apple.com/documentation/authenticationservices/supporting-passkeys
- `isTrusted`: https://dom.spec.whatwg.org/#dom-event-istrusted
- `WebViewCompat` (isolated worlds, document-start scripts, message listeners):
  https://developer.android.com/reference/androidx/webkit/WebViewCompat
- androidx.webkit releases: https://developer.android.com/jetpack/androidx/releases/webkit
- WebView profiles: https://developer.android.com/reference/androidx/webkit/ProfileStore
- WebView and the system browser's data:
  https://developer.android.com/develop/ui/views/layout/webapps/webview
- `WebViewClient`: https://developer.android.com/reference/android/webkit/WebViewClient
- Passkeys in WebView: https://developer.android.com/identity/sign-in/credential-manager-webview
- Play, Deceptive Behavior (hidden features):
  https://support.google.com/googleplay/android-developer/answer/9888077
- Play, Spam (web views): https://support.google.com/googleplay/android-developer/answer/9899034
- Play, Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Play, User Data: https://support.google.com/googleplay/android-developer/answer/10144311
- Google OAuth and embedded web views:
  https://developers.google.com/identity/protocols/oauth2/policies#browsers
- Flutter platform views: https://docs.flutter.dev/platform-integration/android/platform-views
  and https://docs.flutter.dev/platform-integration/ios/platform-views
- Comet on iPhone (cloud browser): MacStories and MacRumors, 2026-03-18. Comet on Android:
  https://play.google.com/store/apps/details?id=ai.perplexity.comet

Not confirmed by a vendor page, and so tested in Phase 0: that Android's injected touches count as
trusted; that a web view's cookies are separate from Safari's (Apple's forums say so, no reference
page does); how long a page keeps running after the app leaves the screen; whether Google refuses
a direct sign-in.
