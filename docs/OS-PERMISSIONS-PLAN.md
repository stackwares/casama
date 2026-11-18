# System permissions from the chat: the plan

Status: **built** (2026-11-18, D-376), all four phases, every §9 default taken. Where it differs
from this text is in "As built" at the end.

## The problem

On 2026-11-18 a bot tried to work on Oliver's MacBook. Accessibility and Screen Recording were off
and no folders were shared. All the bot could do was write instructions: "System Settings → Privacy
& Security → …, then quit and reopen Casama". Nothing to tap.

This keeps coming up, and not only on the Mac. Location on a phone, camera, microphone, photos,
contacts, calendars, health, notifications, Bluetooth, local network, Full Disk Access… Every OS
has its own switches. A bot can't flip them, and a wall of instructions is where people give up.

There are two separate gates, and today only one has a card:

| Gate | Who decides | Today |
| --- | --- | --- |
| **Casama's grant**: may *this bot* read my calendar on this device? | the person, in Casama | the Allow card (D-149, D-328) |
| **The OS permission**: may *the Casama app* use the calendar at all? | the person, in the OS | nothing; the read fails or the device shares nothing |

## The idea

One card, **Permissions**, for every OS permission on every platform. It's posted by whatever hit
the wall, it shows which device it's about, and each row has a button that does the most the OS
allows:

```text
┌ Turn these on for MacBook Pro ───────────────────────┐
│ So I can see and click in your apps                   │
│                                                       │
│ ● Accessibility          Off      [ Turn on ]         │
│ ● Screen Recording       Off      [ Turn on ]         │
│ ● Shared folders         None     [ Choose ]          │
│                                                       │
│ Opened on your MacBook: flip the switch there.        │
│                                   [ Not now ] [ Continue ] │
└───────────────────────────────────────────────────────┘
```

Each row's state updates live as the device reports it. When every row is on, Continue lights up
and sends "They're on, go ahead" as the person's message, so the bot carries on.

**What it can't do:** no OS lets an app or a bot grant a permission remotely, and that's right. The
person always makes the last tap on the device itself. The card cuts the path to: one tap, land on
the exact switch (or the system prompt), flip it, and see the row confirm.

## 1. The permission list (one registry, shared)

`packages/domain/src/os-permissions.ts` holds every permission Casama knows. The server uses it for
labels and reasons, the app for how to check, ask and open settings on each platform. A permission
id is a plain string, so new ones can ship without breaking older apps (§6).

| id | Label | iOS | Android | macOS | Windows | Linux / web |
| --- | --- | --- | --- | --- | --- | --- |
| `location` | Location | prompt → Settings | prompt → app settings | prompt → Privacy pane | `ms-settings:privacy-location` | browser prompt |
| `location_always` | Location in the background | upgrade prompt → Settings | prompt → app settings | — | — | — |
| `camera` | Camera | prompt → Settings | prompt → app settings | prompt → pane | `ms-settings:privacy-webcam` | browser prompt |
| `microphone` | Microphone | prompt → Settings | prompt → app settings | prompt → pane | `ms-settings:privacy-microphone` | browser prompt |
| `speech` | Speech recognition | prompt → Settings | — | prompt → pane | — | — |
| `photos` | Photos | prompt (full / limited) → Settings | prompt → app settings | prompt → pane | — | — |
| `contacts` | Contacts | prompt → Settings | prompt → app settings | prompt → pane | `ms-settings:privacy-contacts` | — |
| `calendar` | Calendars | prompt → Settings | prompt → app settings | prompt → pane | `ms-settings:privacy-calendar` | — |
| `reminders` | Reminders | prompt → Settings | — | prompt → pane | — | — |
| `health` | Health | HealthKit sheet → Health app | Health Connect screen | — | — | — |
| `notifications` | Notifications | prompt → Settings | prompt (13+) → app settings | prompt → Notifications pane | `ms-settings:notifications` | browser prompt |
| `notification_access` | Read notifications | — | listener settings | — | — | — |
| `activity` | Motion & fitness | prompt → Settings | prompt → app settings | — | — | — |
| `bluetooth` | Bluetooth | prompt → Settings | prompt → app settings | prompt → pane | — | — |
| `local_network` | Local network | triggered → Settings | — | triggered → pane | — | — |
| `accessibility` | Accessibility | — | — | prompt → Accessibility pane | — | AT-SPI check, text help |
| `screen_recording` | Screen Recording | — | — | prompt → Screen Recording pane, **relaunch** | — | portal prompt (Wayland) |
| `automation` | Control other apps | — | — | prompt per app → Automation pane | — | — |
| `full_disk` | Full Disk Access | — | — | pane only (no prompt) | — | — |
| `input_monitoring` | Input Monitoring | — | — | prompt → pane | — | — |
| `shared_folders` | Shared folders | — | — | Casama setting | Casama setting | Casama setting |
| `local_tools` | Local tools (MCP) | — | — | Casama setting | Casama setting | Casama setting |

"prompt → X" means: if the OS has never asked, the button shows the system prompt (one tap, best
odds). If the person already said no, the OS won't ask again, so the button opens X instead:
iOS can only open Casama's own Settings page, Android its App info page (or the exact screen for
special ones), macOS the exact Privacy pane (`x-apple.systempreferences:com.apple.preference.security?Privacy_<Name>`),
Windows the exact `ms-settings:` page. The last two rows are Casama's own settings: the button
opens that screen in the app.

Each entry also says: whether a change needs a relaunch (`screen_recording`, sometimes
`accessibility` for already-running helpers), whether it can be checked without prompting (most
can; `local_network` can't, so it shows "Unknown" until used), and the plain-words reason to show.

**Only permissions the app already declares.** A row for a permission the build doesn't declare
(say, camera on the Mac, which has no `NSCameraUsageDescription` today) shows "Not available on
this device" with no button. Adding a declaration is a separate change for the feature that needs
it, never part of this card.

## 2. Devices report what they have

Each device the person uses reports its permission states without prompting: on start, on resume
(the person may have just come back from Settings), and when a check sees a change. Mac and Windows
apps also re-check every few seconds while a Permissions card for them is open, because no focus
change happens when the person flips a switch in System Settings.

- **Computers** (`local_devices`): a new `permissions` jsonb, `{ "<id>": "granted" | "denied" |
  "not_asked" | "limited" | "unknown" | "unavailable", ... }`, sent over the device socket.
- **Phones and other app installs** (`device_sources`): the same jsonb, sent with the regular
  device sync.

Migration: one `permissions jsonb not null default '{}'` column on each table. RLS unchanged (the
owner and admins already read the row; the worker already has access).

The bot's "who you're talking with" block (D-169) gets one line per device with what's missing
that matters for what it shares: "MacBook Pro: Accessibility and Screen Recording are off, no
shared folders." So the bot doesn't try what can't work, and can explain why before trying.

## 3. Who posts the card

**The thing that failed posts it, not the model** (the D-328 lesson: a bot said it had sent a card
it never sent). One run shows each device + permission once.

- **Desktop tools on someone's own computer** (`desktop.*`, `packages/agent/src/tools/desktop.ts`):
  agent-desktop's permission errors and "no desktop session" map to `accessibility` and
  `screen_recording`. The exact macOS error codes need a real Mac run to confirm (not in the repo).
- **Shell and file tools on someone's own computer**: no shared folders → `shared_folders`; macOS
  "Operation not permitted" under protected folders → `full_disk`.
- **`device.read` and device writes** (`packages/agent/src/device-data.ts`): when the grant exists
  but the device reports the OS permission off, or shares nothing for that kind because of it. If
  the grant is missing too, the one card shows both: an "Allow <bot>" row (today's Allow card) and
  the OS row under it.
- **Local MCP / plugin tools** may return an MCP error with `data.casama_permission: "<id>"`; the
  run turns that into the card too, so a plugin that needs the camera gets the same flow.
- **`device.request_permission`** (new tool) for a bot that wants to ask *before* trying, for
  example at the start of a task it knows needs Screen Recording. Same event, same once-per-run rule.

The model's tool result says: "Showed the person a card to turn on X on <device>. Wait for them;
don't repeat the steps in text." If the person has no device that could grant it (the bot asked for
the camera but the person only has a Linux server), no card: the error says so in plain words.

## 4. The card and its buttons

- **Event:** `device.permission_needed` `{ device_ref, device_name, platform, permissions: string[],
  reason, bot_id, grant_kind? }`. A new event, not a new field on `device.access_requested`, so
  older apps skip it cleanly (they parse kinds strictly; see the comment in `events.ts`).
- **Component:** `Permissions` in Casama's A2UI catalog (`packages/domain/src/a2ui.ts`, next to
  D-310/D-335/D-337). `ui.show` and plugin cards can use it too, through the same validator.
- **New button kind: a device action.** Today a card button only sends the person's answer as a
  message (D-086, D-345). This one asks a device to do something instead:
  `{ "action": "device", "device_ref": "...", "do": "request" | "open_settings" | "open_casama_setting" | "relaunch", "permission": "<id>" }`.
  It never calls a tool and never changes a grant, so approvals and rules are untouched. Only the
  device's owner sees working buttons; anyone else in the conversation sees the card read-only.

**Where the action runs:**

| You tap on… | The permission is on… | What happens |
| --- | --- | --- |
| the same device | the same device | the app asks the OS directly: prompt, or open the pane |
| your phone | your Mac or PC | API → device socket → the desktop app opens the pane and brings it to the front. The row says "Opened on MacBook Pro" |
| your Mac | your phone | API → `device_requests` + a data push → a notification on the phone, "Tap to turn on Location for <bot>". Tapping it opens Casama straight into the system prompt. iOS and Android won't let an app show a prompt from the background, so the tap is required |
| the web app | anything | the same as "your Mac" for other devices; for the browser itself, the browser's own prompt |

**Relaunch:** for `screen_recording` the row turns into "Restart Casama to finish" with a button.
The desktop app relaunches itself and reconnects, and the card's row flips to on. A run in progress
just sees the device go offline for a moment (D-096's offline message, then back).

**Not now:** dismisses the card and tells the bot. The same bot doesn't post a card for the same
device + permission again for 24 hours unless the person asks, so a routine can't nag every run.

## 5. Store and platform rules

- This card is the "explain before the system prompt" step Apple asks for (guideline 5.1.1): the
  system prompt only shows after the person taps Turn on, never on its own.
- No prompts at launch; nothing requested that the feature in front of the person doesn't need.
- Android `location_always`, notification access and Health Connect each have their own screen;
  Play's background-location rule still needs the in-app disclosure we already show before asking.
- Mac App Store build: a sandboxed app can't control other apps through Accessibility, so that row
  says "Use the Casama download from casama.ai for this" with a link (web link rules from
  the store-web-links memory don't apply: it's not a payment).

## 6. Older apps

- Apps before this change skip `device.permission_needed` and the `Permissions` component (unknown
  components are skipped, D-345). The tool result still gives the bot the steps in words, so the
  bot falls back to today's text when the run knows the app is too old to draw the card (the run
  knows the client build from the conversation's last client).
- Permission ids are strings; an id the app doesn't know shows as a plain row "Update Casama to turn
  this on here".

## 7. Phases

1. **Registry, reporting, context line.** `os-permissions.ts`; the two `permissions` columns; desktop
   apps and phones report states; the bot's context line. Nothing visible yet except better bot
   answers.
2. **The card on the same device.** Event, component, device action handled locally (prompt or
   settings) on iOS, Android, macOS, Windows, web. Desktop tools, shell/file tools and `device.read`
   post it. Live re-check while it's open. Relaunch on macOS.
3. **Across devices.** Phone → computer through the device socket; computer/web → phone through
   `device_requests` + push. `device.request_permission`. MCP `casama_permission`.
4. **Settings screen.** Settings → This device → Permissions: the same rows, always available, so
   the person can fix things before a bot ever asks. Same widget as the card.

## 8. Tests

- Domain: the registry is complete for every platform column; the validator accepts `Permissions`
  and refuses an unknown action.
- Agent: a desktop permission error posts one card per run per permission; `device.read` with grant
  but OS off posts the combined card; the model's result text; Not now's 24-hour quiet.
- API: device socket action reaches only the owner's device; a teammate can't trigger it;
  `device_requests` row + push for a phone; reported states saved and shown in the context line.
- App: widget tests for each row state and each `do`; the same-device path calls the platform
  handler; an unknown id shows the update row; read-only for non-owners.
- **Live checks (Oliver, need app builds):** Mac Accessibility + Screen Recording from the phone,
  with the relaunch; iPhone location from the Mac; Android notifications; Windows camera.

## 9. Decisions to confirm (defaults in bold)

1. Card posted by the failing tool, plus an explicit `device.request_permission` tool: **both**.
2. Cross-device for phones uses a push the person taps: **yes** (no way around it on iOS/Android).
3. Not now quiets that bot for that device + permission for **24 hours**.
4. Mac App Store build: the Accessibility row points to the download: **yes**.
5. Settings → This device → Permissions screen ships in the same track (Phase 4): **yes**.
6. Build all four phases in one go in a worktree: **yes, after go-ahead**.

Not part of this plan: adding new permission declarations (camera on the Mac and so on), and any
way for a bot to change a permission without the person's tap.

## As built (2026-11-18)

- **Decision D-376**, not a new D-36x number (D-363 was taken by the local MCP plan).
- **Fewer permissions.** §1 listed what each OS has; the list ships only what Casama's builds
  declare: no camera or location on the Mac, no camera or photos on Android, and no reminders,
  motion, Bluetooth, local network or Input Monitoring anywhere. Windows has microphone and
  notifications (settings pages); Linux has only Casama's own shared folders and local tools.
- **No combined Allow + system row.** The Allow card (D-328) and the Permissions card stay separate
  cards; both appear when both gates are closed.
- **Not an A2UI component.** The card is event-driven like the Allow card (§4's component and
  device-action button kind weren't needed); plugins reach it through `casama_permission`.
- **Phones get a notification only**, no `device_requests` row: older apps parse that table's
  action strictly.
- **Mac screenshots added** (not in the plan): computerd's screenshot was X11 only, which was the
  real cause of "no desktop session" on a Mac.
- **Full Disk Access isn't detected from shell errors** ("Operation not permitted" is too vague a
  signal); it's reachable through `device.request_permission` and Settings → Permissions.
- **Left for Oliver:** a Mac, iOS and Android build to compile the native bridges, then on real
  devices: Mac Accessibility + Screen Recording from the phone with the restart; whether the Privacy
  pane links open on macOS 27; iPhone location from the Mac through the notification; Android
  notification access; the Mac screenshot after Screen Recording is on. Merging the branch, the
  migration on production and the deploy each need a yes.
