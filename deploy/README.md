# One-click deploy templates

The full stack (with sandboxed computers) needs a machine with Docker: use `./install.sh` on a VPS
(see [docs/SELF_HOST.md](../docs/SELF_HOST.md)) or the Coolify template, which runs the same compose file.

Platforms without a Docker socket (Render, Railway, DigitalOcean App Platform) run the **API and
worker only**. They use a Supabase project for Postgres and Auth (Supabase Cloud's free tier or your
own Supabase), and bots get computers from one of:

- **Cloud Connect** to Kasama Cloud (`KASAMA_CLOUD_URL`, `KASAMA_CLOUD_KEY`), or
- the users' own machines through the desktop companion (on by default), or
- a sandbox supervisor you run elsewhere with E2B or Daytona (`SUPERVISOR_URL`, `SUPERVISOR_TOKEN`).

| Platform                  | File                                             | Notes                                                   |
| ------------------------- | ------------------------------------------------ | ------------------------------------------------------- |
| Render                    | [`render/render.yaml`](render/render.yaml)       | Blueprint: API web service and worker                   |
| Railway                   | [`railway/railway.json`](railway/railway.json)   | One service per mode; set `MODE` per service            |
| DigitalOcean App Platform | [`digitalocean/app.yaml`](digitalocean/app.yaml) | `doctl apps create --spec deploy/digitalocean/app.yaml` |
| Coolify                   | [`coolify/README.md`](coolify/README.md)         | Full stack from `infra/compose/docker-compose.yml`      |

Before the first start, apply the migrations to the Supabase database:
`supabase db push --db-url "$DATABASE_URL"` (from this repository).

Required settings everywhere: `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_JWT_SECRET` (Supabase project settings), `INTERNAL_TOKEN` (32+ random characters),
`PUBLIC_APP_URL`. Billing stays off (`BILLING_ENABLED=false`).
