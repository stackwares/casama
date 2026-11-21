# macOS debug run: findings

Run date: 2026-11-21. Build: `flutter run -d macos --debug` in `client/` (Flutter 3.50.0).
Backend: local Supabase on :54321, API on :8787 and worker started by hand (see E1).
Account: `setup-test@example.com` ("Setup Test's space"), shared with two other sessions.
Status: **findings only, nothing fixed**. Screenshots are in `/tmp/kasama-debug/shots/`.

## Environment

- **E1: `scripts/dev-up.sh` fails at the compose step.** Container `casama-turn` can't bind UDP
  `127.0.0.1:3478`, because the `casama-app-turn` container (a separate "casama-app" compose stack) already
  holds it. The script exits before it starts the API and worker. Workaround used: started
  `pnpm --filter @casama/server dev` and `dev:worker` by hand. Side effect: supervisor, egress and SearXNG
  were never started, so "computer" features were not testable.
- **E2: Swift warnings at build time.** `Runner/Island.swift:802` uses `Selector(("accessibilityAttributeValue:"))`
  instead of `#selector`. Plugin warnings (firebase_analytics, firebase_messaging, purchases) come from
  outside the repo. A Swift Package Manager adoption notice is printed for some plugins.
- **E3: cold debug build took about 8 minutes** (macOS Runner target, machine under load from other sessions).

## Findings

| # | Area | Severity | Finding |
|---|------|----------|---------|
| F1 | Settings > Sign In on Another Device | medium | Opening it shows a "Confirm admin action / This action changes the instance" password dialog. Showing a QR sign-in code isn't an instance change, so the copy or the gate looks wrong. |
| F2 | Dialogs | low | Escape does not close the "Confirm admin action" dialog. Escape does close the Quiet hours and Notifications dialogs. |
| F3 | Settings > People | low | The invite link is `http://localhost:8080/join/...`. Check that it uses the public URL when the server has one. |
| F4 | Settings > Appearance | low | Theme grid ends in blank placeholder tiles, and a theme is named "Saved Theme". Check whether the tiles are a loading state that never resolves. |
| F5 | Settings > Usage | low | Chart y-axis shows $0.25 to $0.75 ticks when every day is $0.00. |
| F6 | Chat | low | The chat history shows "Mac check 1: hello" three times in a row with no reply. This may come from another session's tests or from a double-send. Needs a check. |

| F7 | Setup wizard | medium | Escape does not close the "Set Up Casama on This Mac" wizard (the X button does). The "Finish setting up" card still shows "Continue Setup" while steps 1 to 4 (Docker, Server, Account, AI model) already show as done; only the Phone step is left. |
| F8 | Call screen | medium | The call button opens "Call with Casama" even though the workspace has no Google AI key. Mute, Captions and Hang up are shown for a call that can't exist. Escape does not leave the screen; only the back arrow does. |
| F9 | Right panel, Team computer | low | The header said "Stopped" while Manage (a few seconds later) showed "Running" with CPU, memory and three processes. May be a real wake-up from another session, or a stale header. Needs a check. |
| F10 | Bot profile | low | A "Change Casama's picture" tooltip stays on screen over the avatar's edit badge and hides it. |
| F11 | Startup log | low | `Failed to foreground app; open returned 1` printed at launch. `supabase.auth: Refresh session` is logged twice at the same moment right after start. |
| F12 | Settings | low | "Hide reply text" appears in both the Notifications dialog and App lock > More privacy, so the same setting can be reached from two places. |
| F13 | Permissions | low | Notifications shows "Unknown" with a "Turn on" button, and Speech recognition and Contacts show "Not asked yet". Check what Unknown means when macOS has already answered. |

## What worked (no problems seen)

- Cold launch signed in to the local API; no Flutter exceptions or overflow errors in the log for the whole run (0 matches for `exception` or `overflowed`).
- Nav: Needs you, Updates, Bots, Library, Tasks, Settings, search (jump-to), new bot, new group chat (needs two bots), workspace switcher.
- All Settings pages opened and rendered: People, Workspace settings, Usage, Admin console (locked, correct), Appearance, Quiet hours, Notifications, Cards, Widgets, Watch, Wake Word, Integrations (Apps), Skills, Casama Link, Model keys, Account, Two-step, App lock, Privacy, Secrets, Computers, Device connections, Permissions.
- Chat: send and stream reply ("Thinking...", then the reply in about 5 s), topics, find in chat, bot profile, new-ticket and new-project dialogs.
- Narrow window (620 px wide) switches to a single-column phone layout without overflow.

## Not covered (needs another run)

- Computer features beyond the panel tabs: supervisor, egress and SearXNG were not running (E1), so the Screen, Terminal and Files tabs were only checked for idle state.
- Create flows that cost real work or data: creating a ticket, project, bot, group chat, routine, memory or secret; connecting an app; Export or Delete account; sign out and sign in; two-step setup.
- Voice (needs a Google AI key), Casama Link and the cloud setup steps, widgets, the menu-bar Island (`Runner/Island.swift`), notifications, app lock, auto-update, paywall and purchases, deep links.
- Light theme and other themes; window resize to tablet widths.

## Cleanup

Flutter app stopped (`q`). The API and worker I started by hand are gone; port 8787 now belongs to another session's API (pid 7813), which I left alone. The dev stack's Supabase and Docker were already running and were left as they were.
