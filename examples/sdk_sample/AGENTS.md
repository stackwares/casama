# AGENTS.md

`casama_sdk_sample` is a minimal external app built on the Casama Dart SDK (`casama_sdk`): it
signs up or signs in, creates a workspace, adds an OpenRouter model key, creates a bot, sends one
message and streams the run live. SDK guide: https://docs.casama.ai/develop/sdk.md. HTTP API:
https://docs.casama.ai/develop/api.md

## Layout

- `bin/sample.dart`: the whole app, one `main`.
- `pubspec.yaml`: depends on `casama_sdk` as published, with `dependency_overrides` pointing at
  `../../dart/casama_sdk` and `../../dart/casama_api` until 0.1.0 is on pub.dev.

## Rules

- Use only the SDK's public API (`package:casama_sdk/casama_sdk.dart`): `CasamaClient.connect`,
  `signIn` / `signUp`, the generated API groups (`client.workspaces`, `client.credentials`,
  `client.bots`, `client.chat`) and `watchRun` for the run's events. Don't import from `src/`.
- Keep it short and readable: it's the example the SDK docs point at.
- Never hard-code keys or passwords; they come from flags (`--email`, `--password`, `--key`).
- The `casama_api` models are generated from `packages/contracts/openapi.json`; don't edit them
  by hand.

## Check

```sh
cd examples/sdk_sample
dart pub get
dart analyze
dart run bin/sample.dart --api http://localhost:8787 --email you@example.com \
  --password '...' --key "$OPENROUTER_API_KEY" --message "Say hello"
```

`--api` defaults to `http://localhost:8787` (a local Casama stack); use
`https://api.casama.ai` for Casama Cloud.

## Docs and tools

- Every Casama doc, for agents: https://docs.casama.ai/llms.txt (each page also has a `.md`
  version, such as the ones linked above).
- Casama's agent kit for Claude Code: `/plugin marketplace add stackwares/casama`, then
  `/plugin install casama-dev@casama`.
- Casama's docs as an MCP server: `https://api.casama.ai/mcp/docs`.
