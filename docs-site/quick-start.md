# Quick start

## 1. Get a server

Self-host on any machine with Docker (about 15 minutes, see [Self-hosting](/self-hosting)):

```sh
git clone https://github.com/stackwares/kasama && cd kasama
./install.sh --domain kasama.example.com   # or --local for a trial on this machine
```

## 2. Install a client

- **Apps**: macOS, Windows, Linux, iOS, Android and web. At sign-in, tap **Use a different server**
  and enter your server's address.
- **CLI**: `brew install stackwares/tap/kasama` (or download a release binary), then
  `kasama config --api-url https://kasama.example.com`.

## 3. Create an account, a workspace and a bot

The first account on a server is its owner. In the app the onboarding walks you through a model key
and your first bot. With the CLI:

```sh
kasama signup --email you@example.com
kasama org create "My team" && kasama org use my-team
kasama credential add --provider openrouter          # paste your key; or openai, anthropic, ...
kasama bot create Ada --credential <id>              # defaults to GPT-6 Luna on OpenRouter
kasama chat Ada "Research the top 3 open-source vector databases and write a comparison to report.md"
```

No API key? Run a local model with Ollama and add it with
`kasama credential add --provider openai_compatible --base-url http://localhost:11434/v1`.

## 4. Next steps

- Let the bot work on a schedule: [Routines](/guide/routines)
- Decide what it may do alone: [Autonomy and approvals](/guide/autonomy)
- Control bots from your coding tool: [MCP server](/guide/mcp)
