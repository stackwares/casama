# Vendor usage: Phase 5 non-production setup results

Date: 2026-11-20. Companion to `docs/VENDOR-USAGE-PLAN.md` (§5, §10, Phase 5). This file records
what was actually done and checked, and what is still blocked. Vault items are named only; no secret
value is in this file. **Nothing was changed on the production server, its env, or any deploy.**
No emails or messages were sent. No Flutter build was run.

## Summary

| Item | State |
|---|---|
| `alerts@casama.ai` alias | Done earlier (Zoho CLI, on the hello@ mailbox), verified |
| "Alerts" label + filter | **Blocked**: no safe path found (below) |
| Google usage reader: key | **Done**: key created, verified, saved to the vault |
| OpenRouter credits | **Verified** with the existing management key |
| Composio org usage | **Blocked**: needs an org-level key; scope unclear (below) |
| Cloudflare Billing Read token | **Blocked**: dashboard sign-in needs a 2FA code (below) |
| MapTiler | **Not created, on purpose**: only full-access tokens exist |
| HERE | **Deferred**: not switched on |
| VPS env (`VENDOR_ALERT_EMAILS`, `GOOGLE_USAGE_SA_JSON`, ...) | **Not touched**: needs Oliver's yes |

## Google (Map Tiles usage)

- Service account `casama-usage-reader@kasama-ai.iam.gserviceaccount.com`, role Monitoring Viewer on
  `kasama-ai` (created earlier).
- A JSON key was created with `gcloud iam service-accounts keys create` straight into a 0600 file in
  the session scratchpad (never printed). Key id `cf629184de13…` (key ids are not secret).
  The only other key on the account is Google's system-managed one.
- Verified read-only access with that key in a throwaway gcloud config: Cloud Monitoring
  `timeSeries.list` for `serviceruntime.googleapis.com/api/request_count`, service
  `tile.googleapis.com`, last 24 h, answered HTTP 200 with one series (9 requests). This confirms the metric, but not its tile-only method filter; see the live application-reader check below.
- Vault item (folder Keys & Signing): **Casama · Google usage reader service account key
  (casama-usage-reader, kasama-ai)**. Username field `GOOGLE_USAGE_SA_JSON`. SHA-256 of the vault
  copy matched the file's before deletion. The temp file, the throwaway gcloud config and the token
  header were deleted.
- To revoke: service account → Keys page in the Google Cloud console.
- Not done: setting `GOOGLE_USAGE_SA_JSON` on the VPS (production env change).

## OpenRouter

- Used the existing vault items **OpenRouter · Casama · management key** and **OpenRouter · Casama ·
  server key**; no new key made. Responses were filtered to numbers; no body was printed.
- `GET /api/v1/credits` with the management key: HTTP 200, fields `total_credits` and `total_usage`
  (used 3,792.55 of 3,804.99 purchased, so about **$12.44 left**). That is under the $50 low-balance
  email line mentioned in the plan, so a top-up is probably due now.
- `GET /api/v1/key` with the server key: HTTP 200, `limit` 50, `limit_remaining` about 49.96,
  `usage_daily` about 0.04, `usage_monthly` about 8.34. The server key can also call `/credits`
  (HTTP 200), so the plan can read credits with the key the server already holds.
- Reader contract (plan §3) is confirmed. Nothing else needed for this vendor.

## Composio (blocked)

- `POST /api/v3.1/org/usage/summary` with the existing vault item **Composio API key: Casama org,
  casama_prod project**: HTTP 401, "No x-org-api-key or Authorization: Bearer token provided". A
  project key does not work; an org-level credential is needed.
- Dashboard (signed in, org `casama`): Settings → General has "Organization Access Tokens" with
  **Generate**, described only as "org wide access tokens". Its scope is not shown, and the "Scoped
  API keys" card on the page links to the IP allowlist page, not a key form. Because a read-only scope
  could not be confirmed, no token was generated (plan §5 allows read-only credentials only).
- The local `composio` CLI is logged in to the org named `stackwares`, not `casama`, so it was not
  used as a stand-in.
- **To unblock:** Oliver confirms whether an org access token is acceptable (it may be full access),
  or Composio support/docs confirm a usage-only scope. Then generate it in that page, copy it with
  the clipboard pattern in AGENTS.md, and save it to the vault. Until then Admin shows Composio as
  "Not set up".

## Cloudflare Billing Read token (blocked)

- `cf` CLI is signed in with OAuth on the Stackwares account, but `cf accounts tokens
  permission-groups list` returns 403 (9109), so it cannot create tokens.
- The dashboard in the shared browser was signed out. "Continue with Google" for the saved profile
  reached the **2FA code** page. Secure code entry was not completed in that session, so sign-in stopped there and the tab was closed. No token was created.
- **To unblock:** Oliver signs in to dash.cloudflare.com in the shared browser (or gives the 2FA step
  to a session that can), then create an account-owned token on Stackwares with only Account →
  Billing → Read, save it to the vault as **Casama · Cloudflare API token: usage read (Billing
  Read)**, and set `VENDOR_CLOUDFLARE_BILLING_TOKEN` and `VENDOR_CLOUDFLARE_ACCOUNT_ID` on the VPS after
  approval. Confirm the Billable Usage API accepts that scope during live verification; the reader is implemented.
- Note: the sign-in click put a Cloudflare Google-SSO link (a one-time sign-in JWT, valid 30 minutes
  and already used) into this session's tool output. It has expired; nothing to rotate.

## MapTiler and HERE

- MapTiler: not created. Its Admin API issues only full read/write service tokens (plan §11 note),
  so the plan's "read-only" rule blocks it. The vault holds **Casama · MapTiler Cloud API key
  (CASAMA_MAPTILER_KEY)**, a map key; it was not tried against the analytics API and should not be
  assumed to grant it. Options: Oliver explicitly accepts a full-access token, or MapTiler shows
  "Not set up" / own count.
- HERE: not enabled, so no key was made.

## Zoho: `alerts@casama.ai` label and filter (blocked)

- The alias exists (see plan §11). A filter that labels mail to `alerts@casama.ai` "Alerts" has to be
  made in Zoho Mail (Settings → Filters). The CLI's `filter` command filters command output; it does not create an incoming-mail filter.
- The shared browser's existing Zoho session is for another organization. A fresh incognito profile
  reached the hello@casama.ai password step; the password could not be passed in (the page could not
  read the clipboard in that profile), so sign-in stopped. The clipboard was cleared and the tab
  closed. No mailbox setting was changed and no message was sent.
- **To unblock (about two minutes by hand):** sign in to Zoho Mail as hello@casama.ai (vault item
  **Casama · hello@casama.ai Zoho Mail login (super admin)**), Settings → Filters → New: *To* contains
  `alerts@casama.ai` → apply label "Alerts" (create it), keep in Inbox.

## External resources changed

1. Google Cloud: one new JSON key on `casama-usage-reader@kasama-ai.iam.gserviceaccount.com`
   (id `cf629184de13…`).
2. Vaultwarden: one new item (**Casama · Google usage reader service account key (casama-usage-reader,
   kasama-ai)**, folder Keys & Signing).
3. Nothing else. Read-only calls only: OpenRouter `/credits` and `/key`, Composio usage (401),
   Google Monitoring `timeSeries.list`, Cloudflare `cf whoami` and a permission-group list (403).

## Still needing Oliver

1. Production: set `VENDOR_ALERT_EMAILS=alerts@casama.ai` and `GOOGLE_USAGE_SA_JSON` on the VPS, then
   deploy (separate yes; `scripts/deploy-prod.sh --dry-run` first).
2. Zoho Alerts filter (above).
3. Composio org token decision; Cloudflare Billing Read token (2FA); MapTiler decision.
4. OpenRouter top-up (about $12 left).
5. Check each reading against the vendor's own dashboard once the check runs (plan Phase 5).

## Parent review and live application-reader verification

The generic Google metric includes bootstrap and viewport requests. Live inspection confirmed
that the method is a **resource** label, not a metric label. The reader and regression test were
corrected to filter `resource.labels.method="maps_api.tas.TileService.GetTileMedia"`. This method
is now the default for `GOOGLE_USAGE_TILE_METHOD`; an override remains available. Both actual
application readers were called with the vault credential and returned 4 tile requests on
2026-11-20 (daily and monthly), excluding the bootstrap/viewport calls. Temporary key files were
removed after verification. No production configuration was changed.

The new OpenRouter balance warning is seeded at $50 to match the existing account warning.
MapTiler and Composio remain unconfigured under the approved read-only scope; no broad token is
automatically authorized by the implementation request. HERE remains disabled.
