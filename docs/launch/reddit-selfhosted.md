# r/selfhosted

**Title:** Kasama: self-hosted AI bots with their own sandboxed computers (Apache-2.0, one install script)

I've been building Kasama, a self-hosted platform for AI "teammates": bots with memory that work on
their own Docker computers (shell, browser, files), on schedules or webhooks, and ask before risky
actions.

- `./install.sh --domain your.domain` sets up Supabase, the API/worker, sandbox supervisor, egress
  proxy, TURN relay and Caddy with generated secrets. Re-running upgrades.
- Backups/restore via `kasama selfhost backup|restore`; Prometheus metrics and a Grafana dashboard.
- Any model incl. local Ollama; no telemetry unless you turn it on (weekly anonymous counts only).
- Native apps (iOS/Android/desktop/web) connect to your server address.

Requirements: Docker, 8 GB RAM for a few concurrent computers. gVisor recommended on Linux.
Feedback on the compose setup very welcome.
