# Bug hunt across every platform: plan

Status: **Built** (2026-11-21). Two rounds done; all open items decided and fixed except those listed as open in `reports/bug-hunt-2026-11-21.md`. Waiting on: a server deploy (3 new migrations) and app builds.

## 1. Goal

Run every Casama app on every platform we can run on this Mac, use it like a real person would,
and fix the bugs we find as we go. Each fix is small, has a test where one makes sense, and is
committed on its own. Anything too big to fix in passing becomes a row in §9 for Oliver to decide on.

Not in scope: new features, design changes, production deploys and store uploads. Those all wait for
a separate yes.

## 2. Platforms and what runs where

| # | Platform | How it runs here | Device |
|---|---|---|---|
| P1 | Web app | `flutter run -d web-server` (debug) in a worktree, :8098, T3 preview tab | Browser tab, desktop width and phone width |
| P2 | macOS app | `flutter run -d macos` (debug) in a worktree; widgets and menu bar parts by hand | This Mac |
| P3 | iOS app | `flutter run` (debug) on a simulator | iPhone 18 Pro, then iPad Pro 13" for the two-pane layout |
| P4 | Apple Watch | the CasamaWatch target through Xcode, paired with P3's simulator | Apple Watch Series 12 (46mm) |
| P5 | Android app | `flutter run` (debug) on an emulator | Pixel_10_Pro_XL, then Casama_Fold for the folding layout |
| P6 | Wear OS | `scripts/package-wear.sh` debug build on the emulator | Casama_Wear_Large_Round |
| P7 | Websites | `python3 scripts/serve-web.py` (casama.ai, gallery, docs, casama.link), T3 preview | Browser tab |
| P8 | CLI, SDK, Chrome extension | `scripts/e2e-cli.sh`, `scripts/e2e-sdk-sample.sh`, extension build + load | Terminal, browser |
| P9 | Server and database | the full test suites through `scripts/heavy.sh` | n/a |

Linux, Windows and the Snap can't run on this Mac; they get only `flutter analyze` and their own unit
tests. iOS share extension and widgets get a short check on P3, not a full pass.

Every platform runs against the **local stack** (`scripts/dev-up.sh`: Supabase, API :8787, worker),
never production, signed in as the Stackwares test account (password from Vaultwarden, read into a
file, never shown).

## 3. Resource budget

This Mac has 12 cores, 32 GB and ~240 GB free disk, shared with other agent sessions.

- **At most two Flutter builds at once**, each in its own worktree on the same commit (two builds in
  one `client/` clash on `client/build`). If load is high or `scripts/heavy.sh --status` shows a
  heavy run, one at a time.
- **At most one simulator and one emulator booted at a time** (plus a paired watch). Shut each down
  when its pass is done; check first that nobody else uses it.
- **Full test suites go through `scripts/heavy.sh`**, once at the start (baseline) and once at the end.
  While fixing, only the tests for the file I changed.
- Every process I start goes in `<scratchpad>/pids` and is stopped at the end. Worktrees are removed
  when their work is merged.

## 4. How the work is split

Three tracks run side by side:

| Track | Platforms | Runs on |
|---|---|---|
| A. Static | P9, `flutter analyze`, code audits of high-risk areas (§5.4) | Subagents + `heavy.sh`, no builds |
| B. Desktop | P1 web, then P2 macOS, then P7 websites | Worktree `bughunt-desktop` |
| C. Mobile | P3 iOS + P4 watch, then P5 Android + P6 Wear | Worktree `bughunt-mobile` |

Track A starts right away (it needs no build). Tracks B and C start after the yes in §6. P8 fits in
wherever a track is waiting on a build.

**Where fixes go:** every fix is made on branch `bughunt/2026-11-21` (worktree `bughunt-desktop`),
with its test, and committed by path. I rebase it onto `main` and fast-forward `main` after each batch
of fixes, so other sessions see them soon. Track C rebuilds from the latest branch commit at the start
of each platform. Nothing is pushed unless Oliver says so (§6).

## 5. What gets tested, in order

Order is by how many people a bug would hit: sign-in and chat first, rare settings last.

### 5.1 Every platform: the core path (do this first, on each one)

1. Cold start: splash, loading, no red error boxes, no console errors. Start offline, then go online.
2. Sign up a throwaway account and sign in with the test account. Sign out, sign back in. Waitlist gate
   and invite link. Passkey prompt where the platform has one.
3. Onboarding / first run: setup screen, picks for you, first bot.
4. Chat: send text, get a streamed reply, stop a reply, retry, edit, reactions, attachments
   (image, PDF), voice note, long reply scrolling, links, code blocks, copy. Two chats at once (D-413).
5. Bots: create, edit, picture, persona, delete. Topics (D-253). Mentions (D-434).
6. App lock (D-375), notifications permission, push arriving (where the simulator can show it).
7. Navigation: back gesture, deep links (`casama.ai/open`), rotating, resizing, dark and light theme,
   text size at 200%.
8. Error paths: server down mid-reply, slow network, expired session, out of credits.

### 5.2 Every platform: the rest of the app

Routines (create, run now, ends), computers (start, terminal, files, takeover), apps and plugins
(gallery install, cards, MCP sign-in), packs, library and files, bot email inbox, calls and the call
card, paywall and plans (billing is off locally: check screens, not purchases), own keys (D-465),
help and support tickets, settings pages one by one, account deletion with a throwaway account.

### 5.3 Platform-specific checks

| Platform | Extra checks |
|---|---|
| Web | browser back/forward with dialogs open, refresh on every route, phone width, boot screen (`boot.js`), keyboard-only use, large files to R2 |
| macOS | menu bar, island (D-324), window sizes, Run on This Mac setup, full access switch (D-394), system permission cards (D-376), widgets, quit and reopen |
| iOS | safe areas, keyboard over composer, share extension, widgets, Live Activity, iPad two-pane, split view |
| Watch | pairing, reply list, voice reply, complications, offline queue |
| Android | back button on every screen, edge-to-edge, notification channels, folding layout on Casama_Fold, app links |
| Wear | tiles, reply, rotary scroll, round-screen clipping |
| Websites | broken links, 404s, `/get/*` redirects, phone width, console errors, share cards |

### 5.4 Track A audits (code reading, no device)

One subagent per area, each told to find real bugs (wrong behaviour a user or the server would hit),
not style:

1. Chat runs and streaming: lost messages, stuck "Thinking", reconnects (server + client).
2. Billing and usage: charges, resets, free plans, own keys. (Read only: billing changes get extra care.)
3. Auth and sessions: token refresh, account switch, device token handover.
4. Client state: providers that cache errors forever, dialogs left open after navigation, `setState`
   after dispose, missing `mounted` checks.
5. Server error handling: unhandled rejections, missing input checks, 500s that should be 4xx.

Areas another session is changing right now are skipped (today: MCP OAuth and provider switching,
thread "Fix Provider Switching").

### 5.5 Known findings to start from

`reports/web-debug-2026-11-21.md` lists seven web issues found earlier today (dialogs stay open after
navigation, New bot dialog has no close button, mascot image errors, raw "Bad state" text on the call
screen, endless skeleton on the bot inbox, providers stuck on errors, bare `/computer`). Each is checked
against the current code first; the ones still real are fixed in the first batch.

## 6. What needs Oliver's yes

Each item below is a build under AGENTS.md. A yes covers that build for this bug hunt (rebuilds of
the same target as fixes land), not release builds.

| # | Build | Why |
|---|---|---|
| B1 | Web debug, `flutter run -d web-server` in worktree `bughunt-desktop` | P1 |
| B2 | macOS debug, `flutter run -d macos` in `bughunt-desktop` | P2 |
| B3 | iOS debug on simulator + the watch target through Xcode, in `bughunt-mobile` | P3, P4 |
| B4 | Android debug on emulator + Wear debug build, in `bughunt-mobile` | P5, P6 |
| B5 | Chrome extension build (`scripts/build-extension.sh`) | P8 |

Also to decide: **push** fixes to `origin/main` as batches land, or keep them local until the end?
No production deploy or store upload is part of this plan.

## 7. How a bug is handled

1. Reproduce it and write down the steps.
2. Find the cause in code. If another session is editing that file, note it and move on.
3. Fix it with the smallest change; add or update a test (`flutter test test/<file>`, one vitest file).
4. Check it on the device again (hot reload where possible).
5. Commit by path, message `fix(<area>): …`. A fix that changes behaviour on purpose gets a `D-…` entry.
6. Add it to the log in §9.

Too big, risky, or a product question: log it in §9 as "Needs Oliver" and keep going.

## 8. Done when

- Every platform in §2 has had the core path (§5.1) and its platform checks (§5.3).
- §5.2 done on at least web, macOS, iOS and Android.
- All fixes merged to `main`, full suites green through `heavy.sh`.
- Every simulator, emulator, `flutter run` and dev server I started is stopped; worktrees removed.
- A summary report in `reports/bug-hunt-2026-11-21.md`: what was tested, what was fixed (with
  commits), what's left.

## 9. Log

| # | Platform | Area | Bug | Status | Commit |
|---|---|---|---|---|---|
| 1 | Local DB | worker | `public.user_last_active` missing locally, every routine claim failed | Fixed locally (function re-created) | n/a |
| 2 | Web | chat list | Sidebar preview showed raw table markdown | Fixed | 975d17307 |
| 3 | All clients | providers | 4xx errors retried for ~40 s behind a skeleton (bot inbox, cached errors) | Fixed | ba545258f |
| 4 | All | calls | Live relay socket left open after mic denied | Fixed | 23edc4b6e |
| 5 | Web | Cmd+K | First Escape didn't close an empty search | Fixed | 5486ce40f |
| 6 | All | settings | setState/ref after await without mounted check (Privacy, Cards) | Fixed | fcd8d0a89 |
| 7 | iOS/Android | chat | Code block label and copy button covered the first line | Fixed | 0e0472359 |
| 8 | Server | agent | Stop on an OpenRouter reply crashed the worker | Fixed | 7bda19da1 |
| 9 | iOS | home | Side rail overflowed 22 px in landscape | Fixed | 5a6ce23fd batch |
| 10 | iOS | board | Open the Bot's Thread opened the main chat, not the ticket's | Fixed | 5a6ce23fd |
| 11 | iOS | share | Quick ask from share sheet: Send disabled, no back arrow | Fixed | 2a521eeab |
| 12 | iPad | home | Computer panel under the status bar in landscape | Fixed | d0432bc1e |
| 13 | Android | home | System back on Library/Tasks closed the app | Fixed | be8c1750a |
| 14 | Wear OS | chat | Old replies showed only a clock time | Fixed | 48c5fdf93 |
| 15 | Server | security | `casama_migrations` had no RLS; anon key could edit it (prod too) | Fixed in migrate scripts; prod needs deploy | e2017e573 |
| 16 | Server | streaming | DB blip in run events stream exited the API; missing final event left Thinking forever | Fixed | 83c16bf33 |
| 17 | Server | calls | Unauthenticated `/telephony/stream` message could crash the API | Fixed | b77799fe6 |
| 18 | Server | errors | ~30 routes returned 500 for non-uuid ids | Fixed (400/404) | fcb9e5a61 |
| 19 | Server | runs | Stop didn't stop remaining tool calls of the same turn | Fixed | 233d6f693 |
| 20 | Server | billing | Starting a free trial ended a comp | Fixed | ace422393 |
| 21 | Server | billing | Daily total had no floor at 0 after a saved reset | Fixed | 9e3618920 |
| 22 | Server | worker | Routine claim failure logged no DB reason | Fixed | 1f4109629 |
| 23 | Server | privacy | `POST /v1/me/blocks` returned the other person's full email | Fixed (masked) | 5365c8249 |
| 24 | Repo | lint | `pnpm lint` failed (8 errors) | Fixed | b276971a0 |

Open items ("Needs Oliver", not fixed): see `reports/bug-hunt-2026-11-21.md`.
