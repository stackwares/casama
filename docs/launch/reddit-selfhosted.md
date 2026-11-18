# r/selfhosted

**Title:** Casama: self-hosted AI bots with their own sandboxed computers (AGPL-3.0, one install script)

I've been building Casama, a self-hosted platform for AI "teammates": bots with memory that work on
their own Docker computers (shell, browser, files), on schedules or webhooks, and ask before risky
actions.

- `./install.sh --domain your.domain` sets up Supabase, the API/worker, sandbox supervisor, egress
  proxy, TURN relay and Caddy with generated secrets. Re-running upgrades.
- Backups/restore via `casama selfhost backup|restore`; Prometheus metrics and a Grafana dashboard.
- Any model incl. local Ollama; no telemetry unless you turn it on (weekly anonymous counts only).
- Native apps (iOS/Android/desktop/web) connect to your server address.
- No domain or open ports? `casama selfhost remote on` gives the server a `casama.link` address your
  phone can reach, free. Chats, memory and files stay on your box; only the relay and push
  notifications pass through us.
- Local models through Ollama, LM Studio or vLLM are recorded at $0, and memory search can stay
  local too.
- Templates for Coolify, Dokploy and CasaOS are in `deploy/`. They parse but I haven't run them on
  those platforms yet, so testers are very welcome.

Requirements: Docker, 8 GB RAM for a few concurrent computers. gVisor recommended on Linux.
Feedback on the compose setup very welcome.
