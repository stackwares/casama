# Rename: Casama Connect → Casama Link (checklist)

Decided 2026-11-15 by Oliver: the feature is **Casama Link**, addresses live on **casama.link** (bought
2026-11-15). Rename **everything**: code, DB, env, routes, docs, text. Breaking migrations is fine (no
users yet).

**Done 2026-11-15** on this branch (see the note under D-296). Differences from the plan below: the
API tag and Dart client are `casama-link` / `CasamaLinkApi` (next to the share links' `LinksApi`), the
server's deps field is `casamaLink`, linking moved to `/link/v1/sign-in/*`, and the old Cloud Connect
tables are renamed by `20270201100200_casama_link_rename.sql`, which runs before the other Casama Link
migrations so they use the new names. Still open: the prod env change and the Vaultwarden item name.

Inventory made from branch `worktree-casama-connect` on 2026-11-15. Before starting, re-run the greps
at the bottom: the branch keeps moving.

## 0. The old "Cloud Connect" is part of this

"Cloud Connect" (a self-hosted server using Casama Cloud's models/computers through a key) was folded
into Casama Connect, so it becomes Casama Link too. **Part of it is already on `main` and in
production**: table `cloud_connect_keys` / `cloud_connect_computers` (migration
`20261115000001_billing.sql`), `CLOUD_CONNECT=true` in `deploy/casama-cloud/settings.env`, routes
`/connect/v1/*`, `docs-site/guide/cloud-connect.md`. Those need a **new forward migration** (prod has
run the old one) and a **prod env change** (needs Oliver's yes at deploy time).

## 1. Do NOT rename (a different "connect")

- Connecting apps/integrations (Composio, D-204): `/v1/apps/connect*`, `connect_app_sheet.dart`,
  `ConnectAppRequest/Response`, `ConnectFlowStatus`, `ProviderConnectRequest/Response`,
  `client/test/connect_first_test.dart`, `client/test/connect_background_test.dart`, l10n keys like
  `appConnected`, `settingsConnectionsSection`, `noConnections*`, `testConnection`.
- `client/lib/core/chatgpt_connect*.dart` (ChatGPT sign-in).
- `/v1/local-computer/connect`, `/v1/admin/connections`, `packages/sandbox/test/local-reconnect.test.ts`.
- `infra/connector/` — the cloudflared connector container (name describes what it is; optional rename
  to `infra/link-connector/` only if it reads better).
- Generic words: connection, connecting, connected, reconnect, `cf-connecting-ip`, HTTP `CONNECT` in
  `infra/egress-proxy`, `DB_AFTER_CONNECT_QUERY` (Realtime), `callConnecting`.

## 2. Naming rules (watch the collisions)

"link" already means other things here: `bot_links`, `invite_links`, `link_exchanges`, `/links/*`
routes (`api/routes/links.ts`), `LINK_TTL_MS`, `LINK_POLL_SECONDS`, `LINK_SCOPES`, `PAIR_LINK_URL`,
magic links, share links, web payment links. So the prefix is **`casama_link` / `CASAMA_LINK_`**, not a
bare `link`:

| Kind | Old | New |
|---|---|---|
| Product | Casama Connect, Cloud Connect | Casama Link |
| Tables | `connect_servers`, `connect_link_requests`, `cloud_connect_keys`, `cloud_connect_computers` | `link_servers`, `link_sign_in_requests`, `link_keys`, `link_computers` |
| Env | `CONNECT_*`, `CLOUD_CONNECT` | `CASAMA_LINK_*`, `CASAMA_LINK_CLOUD` |
| Routes | `/connect/v1/*`, `/v1/connect/*`, `/v1/cloud-connect/*`, `/v1/admin/connect/*` | `/link/v1/*`, `/v1/link/*`, `/v1/admin/link/*` |
| Folders | `features/connect/`, `src/connect/` | `features/link/`, `src/link/` |
| Types | `ConnectServer`, `ConnectKey`, … | `LinkServer`, `LinkKey`, … |

Avoid doubled names: `connect_link_requests` → `link_sign_in_requests` (not `link_link_requests`),
`ApproveConnectLinkRequest` → `ApproveLinkSignInRequest`, `CONNECT_LINK_URL` → `CASAMA_LINK_SIGN_IN_URL`.

## 3. Checklist

### Database (`supabase/`)
- [x] Edit in place (never run on prod): `20270201100201_casama_connect.sql` (rename file too),
  `20270201100202_*`, `20270201100203_connect_live_view.sql`. Tables, indexes
  (`connect_servers_org_idx`, `connect_servers_sweep_idx`, `connect_link_requests_expiry_idx`),
  policies (`connect_servers_select`), constraints, functions, plan-limit fields
  (`connect_live_view`, `connect_capacity`, `connect_url`, `connect_private_notifications`).
- [x] New forward migration for the prod tables: `cloud_connect_keys` → `link_keys`,
  `cloud_connect_computers` → `link_computers`, plus their indexes, policies, constraint names
  (`*_fkey`, `*_check`, `*_key`).
- [x] `supabase/tests/casama_connect_rls.test.sql` → `casama_link_rls.test.sql`; other pgTAP files
  naming these tables; `allow_worker` policies.
- [x] Local DBs (dev stack and the second test stack): hand-run `ALTER TABLE … RENAME` / policy renames
  so they match. **Never reset.**

### Server (`apps/server/`)
- [x] `src/connect/*` (keys, push-relay, routes, servers, tunnels, turn, upkeep) → `src/link/`.
- [x] `src/api/routes/connect.ts`, `src/billing/connect.ts`, `src/services/connect-settings.ts`,
  `src/services/remote-access.ts`, `src/services/outside-relay.ts`, `src/env.ts`, `src/api/app.ts`
  (`/connect/*` mount), `src/worker/*`, plan bits in `api/routes/billing.ts`, `apps.ts`,
  `computers.ts`, `voice.ts`.
- [x] Error codes `connect_error`, `connect_unavailable`, `cloud_connect_off`, `cloud_connect_key`,
  `connect_server`.
- [x] Tests: `casama-connect.test.ts`, `cloud-connect.test.ts`, `connect-live-view.test.ts`,
  `remote-access.test.ts`, `voice.test.ts`.
- [x] Scripts: `scripts/connect-live-check.ts`, `scripts/connect-cloud-dev.ts` (untracked).

### Contracts and generated clients
- [x] `packages/contracts/src/connect.ts`, `src/routes/connect.ts`, `openapi.json` (re-emit).
- [x] Regenerate `dart/casama_api` (`connect_api.dart`, all `*connect*` models, `deserialize.dart`,
  `casama_api.dart`, `.openapi-generator/FILES`) — don't hand-rename generated files.
- [x] Signed-out routes contracts list: new paths.

### Dart packages
- [x] `dart/casama_sdk/lib/casama_connect.dart`, `lib/src/*`, tests `casama_connect_test.dart`,
  `fake_connect_cloud.dart`.
- [x] `dart/cli/lib/src/*` (help text, `selfhost remote …`, `pair`); `dart/computerd/test`.

### App (`client/`)
- [x] `lib/features/connect/` → `lib/features/link/` (connect_screen → link_screen, keep_awake,
  link_server_screen, pair_device_sheet, pairing); imports in `router.dart`, `route_title.dart`,
  `main.dart`, `settings_screen.dart`, `sign_in_screen.dart`, `local_server.dart`,
  `live_view_screen.dart`, `server_unreachable_view.dart`, `backend.dart`, `supabase_backend.dart`.
- [x] Route paths/names and analytics screen names containing `connect`.
- [x] l10n: every `cloudConnect*` and Casama Connect key and value in `app_en.arb`, then regenerate
  `l10n/generated/`.
- [x] Tests: `casama_connect_test.dart` and any others naming the feature.

### Infra, install, deploy
- [x] `infra/compose/docker-compose.yml`: `CONNECT_*` and `CLOUD_CONNECT` env, profile `connect`,
  volume `connect:` and `/connect` mount, `CONNECT_TOKEN_FILE=/connect/token`, comments.
- [x] `infra/compose/selfhost/Caddyfile`: `/connect/*` path.
- [x] `infra/connector/*`, `infra/turn/*` comments and env; `install.sh`;
  `deploy/casama-cloud/settings.env`, `deploy/render`, `deploy/railway`, `deploy/*`.
- [x] `packages/sandbox/src` (+ `docker/`), `packages/agent/src`, `packages/domain` plan defaults.
- [x] Local `.env` files and the prod env (at deploy, with Oliver's yes); Vaultwarden item names/notes.

### Docs and site
- [x] `docs/CONNECT-PLAN.md` → `docs/LINK-PLAN.md`; `docs/DECISIONS.md` (add a rename note under
  D-296, don't rewrite history); `docs/SPEC*.md`, `docs/COSTS.md`, other `docs/` hits.
- [x] `docs-site/self-hosting/remote-access.md`, `self-hosting/configuration.md` (env list),
  `guide/cloud-connect.md` → `guide/casama-link.md`, `develop/*`, `.vitepress` nav/sidebar.
- [x] `site/` (the `/pair` page and anything else naming it).
- [x] Zone default: `casama.link` as `CASAMA_LINK_ZONE` in examples (replacing oliverbytes.dev mentions).

### After
- [x] Re-run the greps below: only section-1 hits remain.
- [x] `pnpm test` (all packages), `pnpm --filter @casama/db test:pgtap`, `flutter test`,
  `flutter analyze`, `dart test` in the Dart packages.
- [x] Update memory notes (casama-connect → casama-link).

## Greps

```sh
git grep -n -i -E "casama connect|cloud connect|cloud-connect|cloud_connect|CLOUD_CONNECT"
git grep -n -E "CONNECT_[A-Z_]+" | grep -v DB_AFTER_CONNECT_QUERY
git grep -n -E "connect_(servers|link|live_view|private_notifications|capacity|url|unavailable|error)"
git grep -n -E "/connect/|/v1/connect|admin/connect|features/connect|src/connect"
git ls-files | grep -i connect | grep -v -i -E "connection|connector|chatgpt|connect_app|provider_connect|reconnect|connect_first|connect_background|connect_flow"
```
