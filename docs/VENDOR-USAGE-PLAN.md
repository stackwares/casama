# Vendor usage and balances in Admin, with alerts: plan

Status: **in progress** (approved 2026-11-20). Phases 1–4 implemented locally. Full server
checks, database policy tests, Flutter analysis/tests and the docs build pass. Phase 5 account
setup and live verification remain incomplete. No production environment change or deployment
has been performed.

- Phase 1: implemented; atomic counters and RLS tested. Auth's direct SMTP sends are excluded.
- Phase 2: implemented; all nine API readers tested with fixtures, plus header observations.
- Phase 3: implemented; hourly workflow, durable alerts, recovery, summary and renewal tests pass.
- Phase 4: implemented; contracts/client generation, owner routes and Flutter tests pass.
- Phase 5: in progress; alert alias and Google reader account created. Credentials, mailbox
  filter, production configuration and live provider reconciliation remain pending (§11).

Oliver (2026-11-20): "Does our admin console show our usages for all our services we use like
maptiler, resend, zeptomail, google maps, etc? So we can also monitor which one is almost gone or
needs refill. Maybe we also get notifications maybe via email or what?"

## 0. Summary

Admin gets a **Vendors** tab: one row per paid service Casama runs on, showing how much of its free
amount, plan quota or prepaid balance is used, when it resets, and a status (OK, low, out, unknown).
A worker step checks every vendor once an hour and **emails the instance admins** (plus an in-app
notice and a push) the first time a vendor passes 80% and again at 100% or "out". Where a vendor has
no usage API, the server counts its own calls instead, against the limit written in Admin.

Nothing here costs money: every source is a read-only API or our own counter.

## 1. What exists today

- **Admin → Services** (`GET /v1/admin/services`, `apps/server/src/api/routes/admin.ts:441`):
  configured and reachable flags for internal parts (database, worker, supervisor, email, error
  reporting). No usage, no balances; Resend shows only as "Email: Resend".
- **Admin → Margin** (D-395/D-400): our upstream cost against what we charged, from `usage_ledger`.
  That is our side of the bill, not what's left at each vendor.
- **Two alerts already work this way:** the registrar balance (`CASAMA_DOMAINS_BALANCE_ALERT`,
  `apps/server/src/sites/buying.ts:996`) and Link tunnels near the free 1,000
  (`CASAMA_LINK_TUNNEL_ALERT`). Both call `noticeInstanceOwners()` (`sites/domains.ts:223`), which
  writes an in-app notification to the instance admins with a one-per-day dedupe. Neither emails.
- **Vendor-side safety nets already set up:** Google Maps quota caps and a $5 budget (D-444),
  OpenRouter workspace budgets and a low-balance email below $50, Twilio's default $5 balance
  email, ZeptoMail's low-credit emails. They go to different inboxes and nobody sees them in one
  place.

## 2. Goals

1. One screen that answers "is anything about to run out?" for every vendor in `docs/COSTS.md`.
2. An email to the admins before a service stops, not after, and one when it does stop.
3. No vendor without a number: a usage API where there is one, our own count where there isn't.
4. Read-only credentials only; no new paid services; nothing that can change a vendor account.

## 3. Sources, per vendor

Checked 2026-11-20 against each vendor's docs. "Own count" means the server counts its calls.

| Vendor | What we show | Source | Credential needed |
|---|---|---|---|
| **OpenRouter** (models on our keys) | Credits left (USD); the server key's daily cap used | `GET /api/v1/credits` (management key, verify), `GET /api/v1/key` (`limit_remaining`, `usage_daily`) | Existing `CLOUD_MODEL_UPSTREAM_KEY`; management key for credits |
| **DeepSeek** (web search answers) | Balance (USD) | `GET https://api.deepseek.com/user/balance` | Existing key |
| **Google Map Tiles** (D-444) | 2D tiles today / 3,200 cap; this month / 100k free | Cloud Monitoring `timeSeries.list`, metric `serviceruntime.googleapis.com/api/request_count`, service `tile.googleapis.com` | **New:** service account with Monitoring Viewer on `kasama-ai` |
| **MapTiler** | Requests this billing period / plan quota | `GET https://service.maptiler.com/v1/analytics/api_usage/timeline` | **New:** MapTiler service credentials (read) |
| **HERE** (when switched on) | Raster tiles this month / 30k free | `GET https://usage.bam.api.here.com/v2/usage/realms/{realm}` (OAuth 1.0a token) | **New:** HERE access key with usage read |
| **Twilio** | Balance (USD) | `GET /2010-04-01/Accounts/{sid}/Balance.json` | Existing SID + token |
| **Name.com** | Balance (USD) | Already read for the registrar alert | Existing |
| **Composio** | Usage this period and charge (USD) | `POST /api/v3.1/org/usage/summary` | **New:** org API key (read) |
| **Cloudflare** | Workers, R2 usage this billing period | Billable Usage API | **New:** API token with Billing Read only |
| **Parallel** (web search) | Credit balance | `GET /account/service/v1/balance` needs an account OAuth token, not the API key | Own count unless the OAuth token works for a server job (§10.4) |
| **ZeptoMail** (app email) | Emails sent / credits bought; expiry date | No API. Own count of sends, against credits and expiry typed in Admin | None |
| **Resend** (newsletter, mail backup) | Emails today / 100 and this month / 3,000 (free plan) | Response headers on every send: `x-resend-daily-quota`, `x-resend-monthly-quota`; own count as backup | Existing |
| **Serper** (web search) | Queries used / credits bought | No API found. Own count | None |
| **Gemini** (voice calls, AI Studio prepay) | Spend this month | No API. Own spend from `usage_ledger` (Gemini Live rows), against the prepaid amount typed in Admin | None |
| **Unsplash** | Requests left this hour | `X-Ratelimit-Remaining` header on our calls | Existing |
| **Fixed monthly bills** (Contabo VPS, Apple, Google Play, domains) | Next renewal date and amount | Typed in Admin; reminder 14 days before | None |

Vendors that only ever bill a fixed amount (VPS, store accounts, domains) get a renewal reminder,
not a meter.

## 4. Design

### 4.1 Data

- `public.vendor_limits` (one row per vendor; edited in Admin, seeded from `docs/COSTS.md`):
  `vendor`, `label`, `kind` (`quota` | `balance` | `renewal`), `unit` (tiles, emails, USD…),
  `limit_value`, `period` (`day` | `month` | `billing_period` | `prepaid`), `period_start`,
  `expires_at`, `warn_at` (default 0.8), `enabled`.
- `public.vendor_checks` (latest reading per vendor, plus 90 days of history for a sparkline):
  `vendor`, `checked_at`, `used`, `remaining`, `limit_value`, `resets_at`, `status`
  (`ok` | `low` | `out` | `unknown`), `source` (`api` | `own_count` | `manual`), `error`.
- `public.vendor_counts` (own counts): `vendor`, `day`, `count`, upserted `+1` (or `+n`) by the
  code that calls the vendor. One small helper, `countVendor(vendor, n)`, used at each call site:
  ZeptoMail and Resend sends, Serper and Parallel searches, Unsplash calls.
- All three tables: RLS on, owner-only read through the API, `public.allow_worker`, pgTAP tests.

### 4.2 The check

A worker step `vendor-usage` in the hourly workflow (next to `domain-orders`). For each enabled
vendor it reads the source in §3, turns it into `used / limit / resets_at`, writes a
`vendor_checks` row and decides the status:

- `low` at `warn_at` (80%) of a quota, or when a balance falls under its threshold.
- `out` at 100%, a balance at or under zero, or the vendor answering "quota exceeded".
- `unknown` when the check fails three hours in a row (bad credential, API down); that's alerted
  too, once a day, so a broken check doesn't look like "fine".

Each vendor's reader is a small module in `apps/server/src/services/vendors/` with one function,
`read(env): Promise<Reading>`, and a fake for tests. A vendor without its credential is skipped and
shows "Not set up" in Admin.

### 4.3 Alerts

On a status change to `low`, `out` or `unknown` (and again when it recovers to `ok`):

1. **Email** to every address in `INSTANCE_ADMIN_EMAILS` through the account email path
   (`services/account-emails.ts`), which falls back to Resend when ZeptoMail fails (D-433). That
   matters, because ZeptoMail itself is one of the vendors that can run out. Subject:
   "Casama: MapTiler is at 82% of this month's requests". Body: used / limit, when it resets, what
   happens when it runs out (from the vendor row: "map cards fall back to OpenStreetMap",
   "sign-in emails stop"), and the vendor page link to refill or upgrade.
2. **In-app notice and push** through `noticeInstanceOwners()`, like the registrar alert.
3. **Dedupe:** one alert per vendor per status per period (a quota that's low stays one email, not
   one an hour). `out` and `unknown` repeat once a day while they last.

A **weekly summary email** (Monday morning, instance timezone) lists every vendor with its bar, so
slow drift is seen even when nothing crosses a line. It's off by default (§10.3).

### 4.4 Admin → Vendors tab

A list sorted by how close each vendor is to running out:

- Name, what it's for ("Map cards", "Sign-in emails"), a bar `used / limit` or a balance, resets
  on, status chip, source (API, counted, typed in), last checked.
- Tap a row: 90-day sparkline, the limit fields to edit (limit, period, warn at, expiry), a
  **Check now** button, and the vendor's billing page link.
- A banner on Admin's overview when any vendor is `low`, `out` or `unknown`.

API: `GET /v1/admin/vendors`, `PUT /v1/admin/vendors/{vendor}` (limits), `POST
/v1/admin/vendors/{vendor}/check`. Owner-only, in the contracts and OpenAPI like the other admin
routes, so the Dart client is generated.

### 4.5 Self-hosted servers

Self-hosters run with their own keys. The tab works the same, showing only vendors their server
has keys for; own counts work with no setup. Nothing phones home.

## 5. New credentials (all read-only; each goes into Vaultwarden in the same task)

| Credential | Scope | Where it's set |
|---|---|---|
| Google service account `casama-usage-reader` | Monitoring Viewer on `kasama-ai` only | VPS env `GOOGLE_USAGE_SA_JSON` |
| MapTiler service credentials | Analytics read | VPS env |
| HERE access key (when HERE is on) | Usage read | VPS env |
| Composio org API key | Usage read | VPS env |
| Cloudflare API token | Billing Read | VPS env |
| OpenRouter management key | Already exists (D-244); used only for `GET /credits` | VPS env (already there for provisioning) |

Before making any of these, search the vault for an existing one (AGENTS.md).

## 6. Costs

None. Every source is a free read-only API call (about 24 calls per vendor per day) or our own
counter. `docs/COSTS.md` gets one line saying the Vendors check is free, and each vendor row gets
"tracked in Admin → Vendors".

## 7. Phases

**Phase 1: the table and own counts.** Tables, migrations, pgTAP; `countVendor()` at the ZeptoMail,
Resend, Serper, Parallel and Unsplash call sites; Resend quota headers read on each send; limits
seeded from `docs/COSTS.md`. *Done when* sends and searches show up in `vendor_counts` in tests.

**Phase 2: API readers.** OpenRouter, DeepSeek, Twilio, Name.com (reuse), Google Monitoring,
MapTiler, Composio, Cloudflare, HERE, each with a fake and a test. *Done when* each reader's test
turns a recorded response into the right `used / limit / resets_at`.

**Phase 3: the check and alerts.** The hourly worker step, statuses, emails, notices, dedupe, and
the weekly summary. *Done when* a fake vendor crossing 80% sends exactly one email and one notice,
and recovering sends one "back to normal".

**Phase 4: Admin → Vendors.** Routes, contracts, generated client, the tab, the overview banner,
widget tests. *Done when* the tab shows every seeded vendor with the right status in a widget test.

**Phase 5: credentials and go-live.** Create the read-only credentials (§5), save them to the
vault, set them on the VPS (needs Oliver's yes for the production env change and deploy), check
each reading against the vendor's own dashboard once.

## 8. Tests

Server: one unit test per reader (recorded responses), the status rules, dedupe, the email
fallback path, owner-only routes. pgTAP for the three tables. Flutter: the tab and the banner.
Full suites through `scripts/heavy.sh` once at the end.

## 9. Not doing

- Changing anything at a vendor (top-ups, plan changes, raising caps) from Casama. Refills stay
  manual, on the vendor's own page.
- Stopping features automatically when a vendor is low, beyond the fallbacks that already exist
  (map tiles, mail backup). That's a separate decision per vendor.
- Tracking per-customer vendor costs; that's the Margin card's job.

## 10. Decisions (made 2026-11-20; Oliver: "Decide all for me")

1. **Alert address: `alerts@casama.ai`**, a new alias on the hello@casama.ai mailbox (the inbox that
   is read every day, with the `zmail` CLI), with a Zoho filter that labels it "Alerts" so alerts
   don't drown in support mail. Set as `VENDOR_ALERT_EMAILS` in the VPS env; when unset, alerts go
   to `INSTANCE_ADMIN_EMAILS`. Not admin@casama.ai: that's a sign-in account for the console, not
   an inbox anyone watches. No personal address goes in the repo (it's public).
2. **Thresholds:** warn at 80%, alert again at 100% or "out", for every vendor; editable per vendor.
3. **Weekly summary email: on**, Mondays 9:00 Asia/Manila, to the same address.
4. **Parallel:** our own count of searches; no account OAuth token on the server.
5. **Renewal reminders: yes**, in the same tab, 14 days and 3 days before each fixed bill.
6. **Channels:** `low` → email + in-app notice. `out` and `unknown` → email + in-app notice + push
   to the admins' phones, repeated once a day while they last. Back to `ok` → one email.

Phase 5 adds the `alerts@casama.ai` alias and filter with the `zmail` CLI.

## 11. Implementation and rollout log

2026-11-20: implementation approved and started. The database foundation has focused pgTAP
coverage for constraints, worker writes and denied direct authenticated reads (14 passing checks).

Credential audit (names only): existing vault items include OpenRouter · Casama · management key
and Composio API key: Casama org, casama_prod project. Dedicated monitoring credentials were not
found by the initial name searches for Google, MapTiler, HERE or Cloudflare. Existing tile and
infrastructure keys must not be assumed to grant usage access.

The active local Google CLI account lacks `iam.serviceAccounts.list` on `kasama-ai`; creating the
Monitoring Viewer service account needs authorized project access. Browser permission for vendor
setup has been requested. Production environment edits and deployment remain pending the
separate approval required in Phase 5. No production settings have been changed by this task.

2026-11-20 provider verification correction: MapTiler's Admin API documentation describes service
tokens as full account read/write credentials, not analytics-only credentials. Do not create a
new MapTiler service token under this plan's read-only approval. Monitoring can use an existing
explicitly authorized token or own counts where available; otherwise show Not set up. Source:
https://docs.maptiler.com/cloud/admin-api/ . The shared Zoho browser session did not show the
Casama organization/mailbox; it was closed without changes. Alias creation remains pending.

2026-11-20: `alerts@casama.ai` created using the authenticated Zoho CLI and independently verified
on the `hello@casama.ai` account. No test email sent. The CLI's `alias` and `filter` commands are
shell helpers, not mailbox aliases or incoming-mail filters; the mailbox alias used
`userManagement addEmailAlias`. The Alerts label/filter remains pending a mailbox UI/API path.
Temporary credential and account-response files were removed after verification.

Google setup update: browser project access succeeded. Created service account
`casama-usage-reader@kasama-ai.iam.gserviceaccount.com` with Monitoring Viewer. A JSON key download
was not exposed by the shared browser's download inventory or local Downloads folder. That key
was immediately deleted, and the account's Keys page confirmed no keys remain. No uncollected
active credential is left behind. Google credential capture into Vaultwarden and metric-method
verification remain pending; the service account itself is ready.

Implementation committed locally as `54831139` (not pushed or deployed). Final verification:
`pnpm typecheck`, `pnpm test`, full pgTAP, full Flutter analysis and tests, and docs build passed
through the heavy-command lock. Server: 1,345 tests passed, 2 skipped; Flutter: 1,749 passed,
22 skipped. A final focused regression verifies that unconfigured history does not prematurely
trigger a three-hour failure alert. Provider setup continues separately; this is not a claim that
Phase 5 has shipped.

Phase 5 follow-up: see [VENDOR-USAGE-SETUP.md](VENDOR-USAGE-SETUP.md). Google credential is now
saved and hash-verified in Vaultwarden, and both tile-only application readers were verified
live after correcting the resource-label filter. OpenRouter credits were verified with the
existing management key. Cloudflare login, the Zoho filter, broad-scope-only vendor credentials,
and production configuration/deployment remain unresolved. No production writes occurred.
