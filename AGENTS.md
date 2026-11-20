# Agent instructions

Rules for AI coding agents working in this repository.

## Hard rules

Breaking one of these does real damage. The sections below explain each one.

- Never print a secret (key, token, password, personal details) in chat or tool output.
  See "Credentials and the vault".
- Never reset or wipe the local database. See "Local data".
- Never `git add -A`, `git add .` or `git commit -a`, and never reset, stash, check out or clean
  files you didn't change. See "Shared working tree and git".
- Ask before any Flutter build and before any production deploy. See "Flutter" and "Production".
- Big features get a written plan and the user's go-ahead before code. See "Before you build".
- Stop every long-running process you started before you finish. See "Processes you start".
- **A tool named here isn't available to you** (`request_secret`, `preview_*`, `html_render`,
  `send_to_user`, `ListAgents`): stop and tell the user what you need. Never work around it by
  asking for a secret in chat, printing one, or starting your own headless browser. Subagents are
  the exception: see "Subagents and model choice".

## Finding your way

- Map of the code: `docs-site/develop/architecture.md`. How changes are made and checked:
  `docs-site/develop/contributing.md` and `agent-kit/skills/casama-contribute/SKILL.md`. Why things
  are the way they are: `docs/DECISIONS.md`.
- `docs/DECISIONS.md` is thousands of lines long; don't read it whole. Find the entry you need with
  `grep -n '^## D-212 ' docs/DECISIONS.md` or a keyword search, then read only that entry.
- Building on Casama from outside (plugins, the API, A2A, templates, the gallery): the skills in
  `agent-kit/skills/` and `docs-site/develop/agents.md`.

## Everyday commands

Run from the repository root unless a line says otherwise. The full list is in
`docs-site/develop/contributing.md`.

- Lint and types: `pnpm lint`, `pnpm --filter <pkg> typecheck` (one package; the full
  `pnpm typecheck` goes through `scripts/heavy.sh`).
- One server test file: `pnpm --filter @casama/server exec vitest run test/<file>.test.ts`.
- One pgTAP file: `pnpm --filter @casama/db test:pgtap <part of the file name>`.
- Flutter: `cd client && flutter analyze`, `flutter test test/<file>`.
- Generated code after a contract change: `pnpm gen`.
- Local stack: `scripts/dev-up.sh` (Supabase, computer services, API and worker; Ctrl-C or
  `scripts/dev-up.sh --down` stops it). Record its PID (see "Processes you start").
- New migrations: `supabase migration up --include-all`. Never a reset.

## Before you build

- **Big feature: write the plan first.** Put it in `docs/<NAME>-PLAN.md` (shape:
  `docs/ANALYTICS-PLAN.md`) and stop for the user's answers. A "yes" to an idea is not a go-ahead to
  code; code starts when the user approves the plan or says to build it. A small, clearly scoped fix
  needs no plan.
- **No WebViews in the app.** Every screen is native Flutter. Plugin UI is data plus A2UI screens drawn
  with the app's own component catalog; grow that catalog instead of embedding web content. Opening a
  link in the system browser or in-app browser tab is fine.
- **Paid services:** any change that adds or changes a paid dependency (a new vendor, a new usage kind,
  a price change) updates `docs/COSTS.md` in the same change and records real cost in `usage_ledger`.
- **Cloud models:** Casama's OpenRouter key only accepts an allowlist of models (D-364). Changing a
  cloud model starts with adding the new one to that allowlist, or every call fails with "Model blocked
  by guardrail".
- **Look in the vault before you create a key.** Before making a new API key, token, signing key or
  account, search the team password vault (Vaultwarden) for one that already exists, and reuse it.
  Make a new one only when nothing there fits, and say why.
- **Secrets you create** (API keys, tokens, signing keys) go into the team password vault in the same
  task, never only into a `.env` file.

## Shared working tree and git

Several sessions edit this same checkout at once, and each one commits from it.

- **When to commit:** commit your own finished work when the task is done and its tests pass, unless
  the user said not to. Don't push unless the user asks, or the task is a deploy that needs it (see
  "How to deploy").

- **Stage by path, right before your own commit:** `git add <your files>`, never `git add -A`,
  `git add .` or `git commit -a`. Delete files with plain `rm`, not `git rm`, until you commit.
- **Check the index is empty before you stage** (`git diff --cached --stat`). If it isn't, another
  session is mid-commit: leave its files alone, wait a minute and check again. Still not empty after
  a few minutes: stop and ask the user; never unstage or commit someone else's files. Never leave
  anything staged when you stop.
- **A file with someone else's edits in it** (`git diff <file>` shows hunks you didn't write): commit
  only your hunks. `git add -p` is interactive and won't work for you; instead:

  ```sh
  git diff <file> > /tmp/mine.patch   # then delete the other session's hunks from the patch
  git apply --cached --check /tmp/mine.patch && git apply --cached /tmp/mine.patch
  git diff --cached <file>            # must show only your changes
  ```

  Or build your version from `git show HEAD:<file>` plus your changes and stage it with
  `git update-index --cacheinfo 100644,$(git hash-object -w <copy>),<file>`. Never edit away the
  other session's changes in the working file. In `docs/DECISIONS.md`, check your commit adds only
  your own `## D-…` entry.
- Before you commit, read `git diff --cached --stat` once more for files you didn't mean to include.
- Never reset, stash, check out or clean files you didn't change; they may be someone's work in
  progress.
- The public repo's history was restarted (D-406). A pre-push hook refuses commits from the old
  history; don't work around it.

## Local data

- **Never reset or wipe the local database.** No `supabase db reset`, `DROP`, `TRUNCATE` or bulk
  `DELETE` on the local dev database, and never chain one behind `||` as a fallback. Apply new
  migrations with `supabase migration up --include-all`. Server tests make their own databases and
  never need a reset.

## Credentials and the vault

The team password vault is Vaultwarden. Use the `bw` CLI for it. Secret values never go into the
chat, tool output, logs or commits. On 2026-11-19 one lookup leaked into a transcript, and five
keys had to be rotated.

- **Never print or show sensitive information in this chat.** That means passwords, API keys,
  tokens, private keys, TOTP seeds, backup codes, session cookies, connection strings with
  passwords, and people's personal details (phone numbers, birthdays, home addresses, payment
  details). It covers your replies, `send_to_user`, `html_render` and anything a tool prints back to
  you, since tool output is part of the transcript too. Don't run commands that print secrets:
  `cat .env`, `env`/`printenv`, `docker inspect`, `docker compose config`, `curl -v` with an auth
  header, `set -x` around a secret, or a snapshot or screenshot of a page that shows one. Pick out
  just the names (`grep -o '^[A-Z_]*=' .env`, `jq 'keys'`), or check that a value is set
  (`[ -n "$VAR" ]`) or matches (`shasum`). When you need to quote output that contains a secret,
  redact it first (`sk-…abcd`, `***`). The user asking for a value doesn't change this: tell them
  the vault item that holds it.
- **Never use the bitwarden MCP's `list` or `get`.** They return whole items: passwords, TOTP seeds,
  backup codes, private keys. Don't pass a secret as an MCP tool argument either (`create_item`,
  `edit_item`), because arguments end up in the transcript too.
- **Unlock:** reuse the MCP's session:
  `export BW_SESSION="$(security find-generic-password -s bitwarden-mcp-session -w)"`, then
  `bw sync`. If `bw status` still says `locked`, ask the user for the master password with
  `request_secret` (`delivery: "file"`), never in chat, and run
  `export BW_SESSION="$(bw unlock --passwordfile "$file" --raw)"`.
- **Find an item by name only:** `bw list items --search <word> | jq -r '.[] | .id + "  " + .name'`.
  Always search before you create a key or account (see "Before you build").
- **Read a value into a file, not onto the screen:** `umask 077; bw get password <id> >
  <scratchpad>/secret`, then use it as `"$(cat <scratchpad>/secret)"` or pipe it in (`--rawfile`,
  `--passwordfile`, stdin). Delete the file when you're done. No `echo`, `cat` or `set -x` on it.
- **Save a new secret in the same task.** Write the value to a 0600 file in your scratchpad as you
  get it, then create a login item in the folder "Keys & Signing"
  (`b94857b0-90f8-4f29-b49c-65ffcd240cfe`):

  ```sh
  bw get template item | jq --rawfile pw "$file" \
    --arg name "Casama · <what it is>" --arg user "<ENV_VAR_NAME>" \
    --arg uri "<page where it is revoked>" --arg notes "<scope, where it's used, key id, date>" \
    '.type=1 | .name=$name | .folderId="b94857b0-90f8-4f29-b49c-65ffcd240cfe" | .notes=$notes
     | .login={username:$user, password:($pw|rtrimstr("\n")), uris:[{uri:$uri}]}' \
    | bw encode | bw create item | jq -r '.id + "  " + .name'
  ```

  Name it like the existing items ("Casama · PostHog project key (Stackwares 637030)"). Notes say
  what it can do, which project or account it belongs to, where it's set (file, server, Worker
  secret), its key id, and the date. To replace a value:
  `bw get item <id> | jq --rawfile pw "$file" '.login.password=($pw|rtrimstr("\n"))' | bw encode |
  bw edit item <id>`.
- **Check it without showing it:** compare a hash of the vault copy with the deployed copy
  (`shasum -a 256`), not the values.
- **Secrets made in a browser** (a dashboard shows a key once): in `preview_evaluate`, copy it with
  a textarea and `document.execCommand('copy')` (the tab must be visible), then
  `pbpaste > "$file"; pbcopy < /dev/null`. To type one into a page, `pbcopy < "$file"` and read it
  with `navigator.clipboard.readText()` in the page. Don't snapshot the page while a secret is on
  screen.
- **A key only the user can give** (a login, an account's password, a PIN): ask with
  `request_secret`, then save it as above.
- **In your reply,** name the vault item, never the value. If a value does reach the chat or a log,
  tell the user right away so it can be rotated.

## Tests and heavy commands

Several agent sessions share this machine. Full suites started at the same time fight over the same
cores and each one runs several times slower.

- **While you work, run only the tests for what you changed:** `pnpm --filter <pkg> exec vitest run
  <file>`, `flutter test test/<file>`, one pgTAP file.
- **Full runs go through `scripts/heavy.sh`**, which lets one heavy run go at a time on the whole
  machine, in any checkout or worktree, and queues the rest: `scripts/heavy.sh pnpm test`,
  `scripts/heavy.sh pnpm --filter @casama/db test:pgtap`, `scripts/heavy.sh pnpm typecheck`,
  `scripts/heavy.sh sh -c 'cd client && flutter analyze && flutter test'`. Run the full set once, at
  the end. A worktree from before the script existed can call the main checkout's copy by its full
  path.
- It may wait in line for minutes, so start it as a background command. `scripts/heavy.sh --status`
  shows who holds the lock. Never delete the lock to jump the queue; a dead holder's lock clears
  itself.
- It caps workers too (`VITEST_MAX_WORKERS=4`, `flutter test --concurrency=4`); don't raise them.

## Processes you start

A process outlives the session that started it. A `flutter run -d web-server` left behind by a finished
session once ran for 19 hours with nobody using it, holding memory, CPU, a port and `client/build`.

- **Stop every long-running process you started before you finish.** That covers `flutter run`, dev
  and web servers (`serve-web.py`, `vite`, `pnpm dev`), `tail -f` feeding a fifo, watchers, tunnels and
  log streams. Kill it by PID (`kill <pid>`, its feeder too), then check it's gone (`ps -p <pid>`,
  `lsof -iTCP:<port> -sTCP:LISTEN`).
- **Write each PID down when you start it.** Put it in `<scratchpad>/pids` with what it is (for
  example `83857 flutter run web-server :8098`), so you can stop it later, even after your context is
  summarized. Prefer the harness's background commands over `nohup`, `&` or `setsid`, which hide the
  process from you.
- **Leave one running only when the user asks.** Then name it in your final reply: what it is, PID,
  port, and how to stop it.
- **Stopping someone else's leftover:** a process whose parent is `1`, whose working directory or
  fifo sits in another session's scratchpad, and whose session has ended (check with `ListAgents` or
  the T3 thread) is an orphan. Tell the user what it is and who started it, and stop it after their
  yes. If its session is still running, ask that session instead.
- **Remove your worktrees when the work is merged** (`git worktree remove <path>`). Each one carries
  its own `client/build`, `node_modules` and Xcode DerivedData, several GB apiece, and they filled the
  disk once.

## Subagents and model choice

- **Give small or minor tasks to a smaller model like Sonnet.** That covers lookups and searches
  across files, summarizing logs or docs, mechanical edits (renames, copy changes, formatting, bumping
  versions), running and reporting tests, and checking a single file or link. Pass the model when you
  start the subagent, with whatever subagent tool your harness has (in Claude Code, the `Agent`
  tool with `model: "sonnet"`). No subagent tool: do the task yourself.
- Keep the larger model for work where judgment matters: design and architecture, plans, tricky
  debugging, security, billing and data migrations, and reviewing other agents' work.
- When unsure, start on the smaller model and move up if it gets stuck or its result looks wrong.
  Check a smaller model's result before you build on it.
- **Handing work to a smaller model saves cost; it is never a condition for doing the work.** If you
  can't start a subagent (no subagent tool, or the model isn't offered), do the task yourself,
  including builds and deploys the user approved. Never stop or refuse because a subagent isn't
  available. Media jobs below are the only exception.
- **Media jobs go to set models.** Image generation (pictures, icons, wallpapers, share cards):
  `model: codex/gpt-6-luna`. Voice narration and music: `model: antigravity/gemini-4-hydrogen-medium`,
  and that agent must use Gemini TTS for voices and Lyria for music, never the system's own speech
  (macOS `say`, `espeak`, OS voices) or other native TTS. Existing scripts in the Marketing workspace:
  `casama/showreel/scripts/tts_gemini.py` (voice) and `casama/showreel/scripts/lyria-film.py` (music);
  the key is `GEMINI_API_KEY` in `casama/showreel/.env`. No Gemini key or quota: stop and say so, don't
  fall back to system speech.
- **New web pages can have AI pictures.** Whenever you create a new web page (casama.ai, docs,
  gallery, casama.link, a blog post), decide whether visuals would make it better, such as a header
  picture, an illustration or a share card. If they would, you may have them made without asking:
  start a subagent with `model: codex/gpt-6-luna` to generate the images, then check them before
  you put them on the page. If that model isn't available, skip the pictures and say so; don't
  pick another image model unasked. Skip it where a picture adds nothing, such as a reference page or a
  table of settings.

## Browser

- **When a task needs a real browser, use T3 Code's in-app browser tab** (the `preview_*` tools:
  `preview_open`, `preview_navigate`, `preview_act`, `preview_snapshot`, and so on). That covers
  checking a web page or the web app, clicking through a flow, signing in to a dashboard, filling a
  form, and recording a change. The user can watch it in the panel and step in when needed.
- Don't start your own headless Chrome, Playwright or Puppeteer for this, and don't open the user's
  desktop browser. A plain page read with no clicking still goes through web fetch.
- A hidden preview tab pauses `requestAnimationFrame`, so animations and dialogs may not run until the
  tab is visible. Close any tab you opened when you're done, unless the user is still using it.
- **Preview the websites with `python3 scripts/serve-web.py`** (casama.ai on :8731, gallery :8732,
  docs :8733, casama.link :8734). It keeps every link between the sites local; a bare
  `python3 -m http.server` sends links to production.

## Simulators and emulators

- **Shut down the iOS Simulators and Android Emulators you used when you're done.** They hold
  gigabytes of memory and several cores, which slows every other session on this machine. You don't
  need to ask first, but only shut down a device after you've checked that nothing else needs it.
- Before you shut one down, check that no other agent, session or person is using it:
  - This shows any process still driving a device:

    ```sh
    ps -ax -o pid,etime,command | grep -E "flutter (run|test|drive)|agent-device|xcodebuild test|adb -s|simctl (launch|spawn|io)|maestro|appium" | grep -v grep
    ```

    Look for the device's id or name (`xcrun simctl list devices booted`, `adb devices`) and for a
    working directory or worktree that isn't yours (`lsof -p <pid> | grep cwd`).
  - A device you didn't boot yourself (it was already running when you started) belongs to someone
    else: leave it running.
  - The user may be watching or using it in T3 Code's Device panel or on screen. If it's open there
    and you didn't open it, or you're unsure, leave it.
- If it's free: close your T3 device session with `device_close`, then shut the device down with
  `xcrun simctl shutdown <udid>` for a simulator or `adb -s <serial> emu kill` for an emulator. Shut
  down only that device, never `simctl shutdown all` or `pkill`/`killall` on Simulator, qemu or
  emulator processes.
- If another session still uses it, leave it running and say so in your reply. Never shut down or
  restart a device to free it up for yourself; boot another one or wait.

## Flutter

- **Ask before any Flutter build.** Get the user's explicit permission before running `flutter build`
  (any target: `apk`, `appbundle`, `ios`, `ipa`, `macos`, `web`, `windows`, `linux`) or anything that
  runs a build for you, such as a script, `flutter run`, or `xcodebuild`/Gradle on `client/`. Say what
  you want to build and why, then wait for a yes. Permission covers that one build, not later ones.
- Running targeted tests and analysis without asking is fine: `flutter test test/<file>`,
  `flutter analyze`. Full runs still go through `scripts/heavy.sh`.
- **One Flutter command in `client/` at a time.** Two `flutter test` or build runs in the same checkout
  clash on `client/build` ("Failed to copy native_assets.json", tests that fail to load). If another
  session is running one, wait, or work in your own worktree.
- **Flutter 3.50** (D-212). New Dart files import `package:material_ui/material_ui.dart` (and
  `cupertino_ui`), never `package:flutter/material.dart`. Don't run `pub get` with another Flutter
  version; it rewrites `client/.dart_tool` for everyone. Check first: `flutter --version` must say
  3.50.x; if it doesn't, stop and tell the user.
- **`dart format` only files you created.** The existing client code isn't at `dart format`'s width,
  so formatting an existing file rewraps lines you never touched. Edit existing files by hand, and
  never format a whole folder.

## Production

- **Ask before any production deploy.** Get the user's explicit permission before changing anything
  that serves real users. That includes:
  - the production server: pulling, rebuilding or restarting services, editing its env or config,
    running migrations against its database, including `scripts/deploy-prod.sh`;
  - production infrastructure: its Cloudflare tunnel, DNS, WAF rules and Workers, including
    `scripts/deploy-web.sh` (casama.ai, docs, gallery), `scripts/deploy-app-web.sh` (app.casama.ai),
    `scripts/deploy-link-web.sh` (casama.link) and `wrangler deploy`;
  - publishing release artifacts: the "Publish images" GitHub workflow, `scripts/publish-images.sh`,
    `scripts/publish-desktop-release.sh`, `scripts/release-cli.sh`, and store uploads.

  Say what you'll change and why, then wait for a yes. Permission covers that one deploy, not later
  ones.
- Reading production without asking is fine: logs, status, health checks, read-only queries.
- The local dev stack and its `-dev` hostnames are not production; working on them needs no
  permission.

### How to deploy (D-299)

- **Server (API and worker):** push to `main`, run `scripts/deploy-prod.sh --dry-run` and show the
  user what it will do, then after their yes `scripts/deploy-prod.sh --yes`. It builds the image on the
  production server, waits for running runs, backs up, migrates, restarts and checks health. Something
  broke: `scripts/deploy-prod.sh --rollback` (migrations stay). Don't `compose pull` the API or worker
  on the server: they run the local build pinned by `CASAMA_SERVER_IMAGE`.
- **Images for self-hosters:** `gh workflow run "Publish images" -f only=<names>` (empty = all), on
  GitHub's native amd64 and arm64 runners; it moves the `selfhost` tag. `scripts/publish-images.sh` is
  the fallback. After new supervisor, TURN or computer images, `docker pull` them on the server too.
- **Web (casama.ai, docs, gallery):** `scripts/deploy-web.sh`. It has no dry run, so tell the user
  which pages changed (check them locally with `scripts/serve-web.py`), then deploy after their yes.
- **casama.link's page (D-317):** show `scripts/deploy-link-web.sh --dry-run`, then after a yes
  `scripts/deploy-link-web.sh --yes`. It needs the casama.link zone on the Stackwares account.
- **Web app (app.casama.ai, D-316):** build with `CASAMA_OFFICIAL_BUILD=1 scripts/build-web.sh
  --dart-define=CASAMA_API_URL=https://api.casama.ai --dart-define-from-file=config/firebase.json
  --dart-define-from-file=config/telemetry.json` (a Flutter build: ask). A bare `scripts/build-web.sh`
  is the self-host build: it talks to localhost and the deploy script refuses it. Show
  `scripts/deploy-app-web.sh --dry-run`, then after a yes `scripts/deploy-app-web.sh --yes`. Never a
  bare `wrangler deploy` in `client/`: the script puts files of 25 MiB or more in R2 first.
- **Android to Google Play: the Wear OS app goes with it.** Whenever you make a new Android build to
  upload to Play, on any track (internal, closed, open, production), also build the Wear OS app from
  the same commit and version (`scripts/package-wear.sh`, a release bundle) and upload it to the
  matching Wear OS track in the same release. Never ship a phone build to Play without its watch
  build. Both builds and the upload each still need the user's yes, as above.
- **Mac builds ship both ways.** Whenever you make a new Mac build to release, ship both versions from
  the same commit and version: the direct download (notarized DMG from `scripts/package-macos.sh`,
  published as a GitHub release with `scripts/publish-desktop-release.sh`) and the sandboxed Mac App
  Store build (`scripts/package-macos-appstore.sh`, uploaded to TestFlight or App Store Connect).
  Never release one without the other. Each build and each upload still needs the user's yes, as
  above.
- **Install every non-sandboxed release build on this Mac.** As soon as a Developer ID build is ready
  (the notarized DMG from `scripts/package-macos.sh`), install it into `/Applications/Casama.app`,
  replacing the copy already there. Quit Casama first if it's running, check the app with
  `spctl -a -vv -t exec` (it must say "Notarized Developer ID"), copy it in with `ditto`, detach the
  DMG and confirm the installed `CFBundleVersion` is the new build. Installing needs no extra yes; the
  build itself still does.
