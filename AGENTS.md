# Agent instructions

Rules for AI coding agents working in this repository.

## Finding your way

- Map of the code: `docs-site/develop/architecture.md`. How changes are made and checked:
  `docs-site/develop/contributing.md` and `agent-kit/skills/casama-contribute/SKILL.md`. Why things
  are the way they are: `docs/DECISIONS.md`.
- Building on Casama from outside (plugins, the API, A2A, templates, the gallery): the skills in
  `agent-kit/skills/` and `docs-site/develop/agents.md`.

## Before you build

- **Look in the vault before you create a key.** Before making a new API key, token, signing key or
  account, search the team password vault (Vaultwarden) for one that already exists, and reuse it.
  Make a new one only when nothing there fits, and say why.

## Tests and heavy commands

Several agent sessions share this machine. Full suites started at the same time fight over the same
cores and each one runs several times slower.

- **While you work, run only the tests for what you changed:** `pnpm --filter <pkg> exec vitest run
  <file>`, `flutter test test/<file>`, one pgTAP file.
- **Full runs go through `scripts/heavy.sh`**, which lets one heavy run go at a time on the whole
  machine, in any checkout or worktree, and queues the rest: `scripts/heavy.sh pnpm test`,
  `scripts/heavy.sh pnpm --filter @casama/db test:pgtap`, `scripts/heavy.sh pnpm typecheck`,
  `scripts/heavy.sh sh -c 'cd client && flutter analyze && flutter test'`. Run the full set once, at
  the end. A worktree from before the script existed can call the main checkout's copy by its full path.
- It may wait in line for minutes, so start it as a background command. `scripts/heavy.sh --status`
  shows who holds the lock. Never delete the lock to jump the queue; a dead holder's lock clears
  itself.
- It caps workers too (`VITEST_MAX_WORKERS=4`, `flutter test --concurrency=4`); don't raise them.

## Subagents and model choice

- **Give small or minor tasks to a smaller model like Sonnet.** That covers lookups and searches
  across files, summarizing logs or docs, mechanical edits (renames, copy changes, formatting, bumping
  versions), running and reporting tests, and checking a single file or link. Pass the model when you
  start the subagent (Claude Code's `Agent` tool: `model: "sonnet"`).
- Keep the larger model for work where judgment matters: design and architecture, plans, tricky
  debugging, security, billing and data migrations, and reviewing other agents' work.
- When unsure, start on the smaller model and move up if it gets stuck or its result looks wrong.
  Check a smaller model's result before you build on it.

## Flutter

- **Ask before any Flutter build.** Get the user's explicit permission before running `flutter build` (any
  target: `apk`, `appbundle`, `ios`, `ipa`, `macos`, `web`, `windows`, `linux`) or anything that runs a build
  for you, such as a script, `flutter run`, or `xcodebuild`/Gradle on `client/`. Say what you want to
  build and why, then wait for a yes. Permission covers that one build, not later ones.
- Running tests and analysis without asking is fine: `flutter test`, `flutter analyze`, `dart format` on
  files you changed.

## Production

- **Ask before any production deploy.** Get the user's explicit permission before changing anything that
  serves real users. That includes:
  - the production server: pulling, rebuilding or restarting services, editing its env or config, running
    migrations against its database, including `scripts/deploy-prod.sh`;
  - production infrastructure: its Cloudflare tunnel, DNS, WAF rules and Workers, including
    `scripts/deploy-web.sh` (casama.ai, docs, gallery), `scripts/deploy-app-web.sh` (app.casama.ai),
    `scripts/deploy-link-web.sh` (casama.link) and `wrangler deploy`;
  - publishing release artifacts: the "Publish images" GitHub workflow, `scripts/publish-images.sh`,
    `scripts/publish-desktop-release.sh`, `scripts/release-cli.sh`, and store uploads.
  Say what you'll change and why, then wait for a yes. Permission covers that one deploy, not later ones.
- Reading production without asking is fine: logs, status, health checks, read-only queries.
- The local dev stack and its `-dev` hostnames are not production; working on them needs no permission.

### How to deploy (D-299)

- **Server (API and worker):** push to `main`, run `scripts/deploy-prod.sh --dry-run` and show the
  user what it will do, then after their yes `scripts/deploy-prod.sh --yes`. It builds the image on the
  production server, waits for running runs, backs up, migrates, restarts and checks health. Something
  broke: `scripts/deploy-prod.sh --rollback` (migrations stay). Don't `compose pull` the API or worker
  on the server: they run the local build pinned by `CASAMA_SERVER_IMAGE`.
- **Images for self-hosters:** `gh workflow run "Publish images" -f only=<names>` (empty = all), on
  GitHub's native amd64 and arm64 runners; it moves the `selfhost` tag. `scripts/publish-images.sh` is
  the fallback. After new supervisor, TURN or computer images, `docker pull` them on the server too.
- **Web (casama.ai, docs, gallery):** `scripts/deploy-web.sh`.
- **casama.link's page (D-317):** show `scripts/deploy-link-web.sh --dry-run`, then after a yes
  `scripts/deploy-link-web.sh --yes`. It needs the casama.link zone on the Stackwares account.
- **Web app (app.casama.ai, D-316):** build with `CASAMA_OFFICIAL_BUILD=1 scripts/build-web.sh
  --dart-define=CASAMA_API_URL=https://api.casama.ai --dart-define-from-file=config/firebase.json
  --dart-define-from-file=config/telemetry.json` (a Flutter build: ask). A bare `scripts/build-web.sh`
  is the self-host build: it talks to localhost and the deploy script refuses it. Show
  `scripts/deploy-app-web.sh --dry-run`, then after a yes `scripts/deploy-app-web.sh --yes`. Never a
  bare `wrangler deploy` in `client/`: the script puts files of 25 MiB or more in R2 first.
