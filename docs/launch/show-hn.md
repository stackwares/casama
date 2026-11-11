# Show HN: Casama – self-hostable AI teammates with their own computers

Hi HN, I built Casama, an open-source (Apache-2.0) home for AI bots that keep working for you.

Each bot has memory, a persona and a sandboxed Linux computer (shell, files, browser, optional
desktop). You chat from iOS, Android, desktop, web or a CLI; watch the bot's computer live and take
control mid-task; and set how much it may do alone. Risky actions wait for your approval, and a
checkpoint is taken before destructive commands. Routines and webhooks keep bots working while you
are away.

It runs on your server with one script (Supabase, the API and worker, a Docker sandbox supervisor
with an egress proxy, a TURN relay and Caddy). Bring any model: OpenRouter, OpenAI, Anthropic,
Google, xAI or a local Ollama. The desktop app can also lend your own machine to a bot, limited to
folders you share.

Some details HN might care about:

- Durable runs on DBOS: kill the worker mid-run and it resumes where it was.
- Every table has row-level security; a test sweeps every API route as another tenant.
- Computers reach the internet only through an egress proxy that blocks private and metadata
  addresses; no capabilities, read-only root, non-root user, gVisor on Linux.
- An MCP server lets you drive your bots from Claude Code or Cursor.

Repo: https://github.com/stackwares/casama · Docs: https://docs.casama.ai
I'd love feedback on the self-hosting experience and on what bots should be allowed to do alone.
