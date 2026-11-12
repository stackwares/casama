# Agent instructions

Rules for AI coding agents working in this repository.

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
    migrations against its database;
  - production infrastructure: its Cloudflare tunnel, DNS, WAF rules and Workers, including
    `scripts/deploy-web.sh` (casama.ai, docs, gallery) and `wrangler deploy`;
  - publishing release artifacts: `scripts/publish-images.sh`, `scripts/publish-desktop-release.sh`,
    `scripts/release-cli.sh`, and store uploads.
  Say what you'll change and why, then wait for a yes. Permission covers that one deploy, not later ones.
- Reading production without asking is fine: logs, status, health checks, read-only queries.
- The local dev stack and its `-dev` hostnames are not production; working on them needs no permission.
