# Computer updates on your terms, and live view that survives deploys (D-360)

Status: approved 2026-11-17 ("write the final plan then let's get working"). Built on branch
`computer-updates`; not merged, deployed or released.

## Why

Oliver asked what happens to bot computers that are busy (browser windows open, people watching live)
when we deploy. Measured from the code:

- **A computer's own update never interrupts it.** A running container keeps the image it started
  from. The new image is used only when the computer is created again, which its normal idle sleep and
  wake already does (`DockerProvider.sleep` archives the home folder and deletes the container; `resume`
  creates a new one from the current tag and restores the home folder). Restart in Manage does the same.
  So people can't see an update coming or choose its moment, and a computer that is always in use stays
  on an old image for as long as it is used.
- **Server deploys do interrupt live view.** Signaling runs app ↔ API ↔ supervisor ↔ Neko over
  WebSockets. `deploy-prod.sh` recreates the API, so every live view's socket closes. The app treats a
  closed socket as "WebRTC is blocked" (`LiveState.fallback`, one screenshot a second) and never tries
  the video again until the person reopens the view.
- **A supervisor restart is worse:** commands bots run through it are cut too, and the deploy script
  says nothing when a commit is going to recreate it.

## What we build

### 1. "Update available" for a computer (people choose when)

**Knowing a computer is behind.**
- `DockerProvider.imageStatus()`: running computer containers with `current: boolean`, comparing each
  container's `ImageID` with what its profile's tag (`computer-headless` / `computer-desktop`) points to
  now. This is the check the warm pool already makes (`poolMembers`). No image id on either side counts
  as current, so nobody gets a prompt we can't back up.
- Supervisor `GET /computers/images` returns it (Docker only; hosted providers and personal computers
  never get a prompt). `SupervisorClient.imageStatus()` calls it.
- New column `computers.update_available_since timestamptz`. The worker's minute tick
  (`computersIdle` workflow) runs `ComputerService.checkUpdates()`: outdated running computers get
  `coalesce(update_available_since, now())`, current ones get null. Any start (`ensureRunning` creating
  a container) clears it, since a new container always uses the current image.
- The API's `Computer` gains `update_available_since` (nullable).

**Updating.**
- `POST /v1/computers/{id}/update` with `{ force?: boolean }`: same as Restart (sleep, then wake from
  the current image, home folder kept), audited as `computer.updated`. Refused with 409
  `computer_busy` while a command is running on it (`health().runningExecs > 0`, the check idle sleep
  uses), unless `force`. Same permission as Restart (anyone who can see the computer). 409
  `no_update` when there's nothing to update, so a stale screen can't restart a computer by accident.

**In the app.**
- Computer screen header: an "Update available" card when `update_available_since` is set:
  "New tools and fixes are ready. Updating restarts the computer: your files stay, open windows and
  running programs close." with **Update now** and **Later**. Later hides it for this computer for a
  day on this device. When a bot is working on the computer, the card says so and Update now asks first.
- Live view: **Update computer** in its ⋯ menu, which opens the same confirmation. It stays out of
  the way: no chip, no modal, nothing that covers the screen.
- While updating, the button says "Updating…" and the header follows the computer's own states
  (the restart takes 20–60 s). Done: a success toast. A live view open during the update redials by
  itself (part 2).
- Nothing is ever forced while someone or something is using the computer. A computer still updates
  by itself when it goes to sleep, as today, so most computers never show the card for long.

### 2. Live view comes back by itself

- **App** (`client/lib/core/live.dart`, `live_view_screen.dart`): when the signaling socket closes or
  WebRTC fails *after the stream was live*, the screen shows "Reconnecting…" and redials with backoff
  (1, 2, 4, 8, 15, 15 s; about 45 s in all) with a new stream session each time, keeping screenshots
  underneath meanwhile. Only after that does it settle on screenshots, with a **Try again** button.
  A stream that never got live (WebRTC blocked) still falls back to screenshots at once, as now.
  Control comes back by itself after a reconnect because the lease is in the database (`_ensureControl`).
- **API** (`attachStream` in `routes/live.ts`): on SIGTERM, live sockets close with code 1012
  ("service restart"), so the app knows to redial instead of guessing. The app redials straight away on
  1012 (the new API is usually up in a few seconds).

### 3. Deploys say when computers will feel it

- `scripts/deploy-prod.sh`: before starting, list the services `compose up -d` would recreate
  (`docker compose up -d --dry-run`). When that includes the supervisor, egress proxy or TURN relay,
  print that live views will reconnect and running commands on computers will be cut, in the dry run
  and the real run. The script already waits for running runs.

## Not doing (now)

- Forcing an update on a computer in use. If a security fix ever needs it, add a "required" flag to
  the image release and a notice-then-restart, in its own decision.
- Hosted providers (E2B, Daytona, …) and personal computers: they have their own update paths.
- A per-version changelog for computer images. The card says "new tools and fixes".

## Tests

- `packages/sandbox`: `imageStatus` with a fake Docker API (current, outdated, unknown image id,
  pool members left out).
- `apps/supervisor`: `GET /computers/images` (auth, Docker only).
- `packages/agent`: `checkUpdates` sets and clears `update_available_since`; `ensureRunning` clears it.
- `apps/server`: the update route (no update → 409, busy → 409, force works, audit row, the field in
  `GET /v1/computers`), live sockets closed with 1012 on shutdown.
- `client`: the update card (shown, Later hides it, confirm when a bot is working), live view reconnect
  (socket drop after live → reconnecting → live again; never live → screenshots at once; 1012).
- Every suite (`pnpm test`, pgTAP), `flutter test`, `flutter analyze`.

## Rollout

Migration (one nullable column), server, supervisor image (publish workflow, then `docker pull` on the
server: that one supervisor restart is the last unannounced one), app build. All of it needs Oliver's
yes per AGENTS.md. Until the supervisor image is published, `checkUpdates` sees no `/computers/images`
and does nothing.
