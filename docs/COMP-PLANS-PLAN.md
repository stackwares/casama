# Free plans for friends (comps): plan

Status: **not started** (written 2026-11-21). Waiting on Oliver's answers in §12 and the go-ahead to build.

Asked by Oliver (2026-11-21): "what's the best way to give out discounts to my friends right now? or
actually free plans but only for specific plans?"

## 1. Goal

Let an instance owner give a person a paid plan (Plus or Pro, say) for free, for a set time, without
a card, a store or a checkout. Two ways in:

1. **Grant:** the owner names the person by email, picks the plan and the length, and it applies right
   away.
2. **Gift code:** the owner makes a code tied to one plan and one length, possibly usable by several
   people, and shares it. The friend redeems it themselves.

While the comp lasts, the workspace really is on that plan: the app says **Pro**, Pro's limits apply
and Pro's monthly credits arrive each month. When it ends, the workspace drops back to Free by
itself, the way a lapsed subscription does today.

**Not in scope:** percentage discounts on paid checkout (see §11, "Other routes"), comps on
self-hosted servers (billing is off there), and anything a non-owner can create.

## 2. Why not what exists

| Existing tool | Why it doesn't fit |
|---|---|
| `entitlements.overrides` (used on Oliver's workspace 2026-11-16) | Raises limits only. The app still says Free and no monthly credits arrive, because `recompute()` grants credits from the plan (`apps/server/src/billing/service.ts`, `summary()` hides override credits on purpose since 10649cf5). Nothing ends it |
| Invite codes (D-211) | $2 each, not a plan |
| Saved resets (D-443) | Clears one limit once, not a plan |
| App Store offer codes, Play promo codes | Work, but one platform per code, Play asks for a card, and the subscription starts charging when the free period ends. Kept as an option in §11 |
| Dodo discount codes | Checkout has no code field today (nothing in `billing/dodo.ts`). Friends still go through checkout with a card, and it renews at full price afterwards |

## 3. The key idea: a comp is a subscription row

`BillingService.recompute(orgId)` already takes the best entitled row in `public.subscriptions`
(highest `plans.sort`, status in `ENTITLED`, `current_period_end` in the future) and writes the
workspace's entitlement, plan name, limits and monthly credits from it. The per-minute `settle()`
sweep already recomputes any workspace whose `valid_until` has passed or whose monthly grant is due.

So a comp is a `subscriptions` row with `source = 'comp'`, `status = 'active'`, the comped
`plan_code` and `current_period_end` set to the comp's end. Everything else (limits, the plan name on
screen, credits, expiry, a real purchase taking over when it ranks higher) is code that already runs.
What's new: the source value, the monthly grant for a period longer than a month, the grant and code
plumbing, and the app treating `comp` as a source with nothing to manage.

## 4. Data

One migration (check the version against every branch and worktree first; see the
migration-collision note in memory):

- **`subscriptions.source`:** add `'comp'` to the check constraint (now `dodo`, `app_store`,
  `google_play`, from `20261115000001_billing.sql` and `20270201100401_revenuecat.sql`). Comp rows use
  `external_id = 'comp:<comp id>'`, so the existing unique `(source, external_id)` holds.
- **`public.comps`:** one row per comp handed out.
  `id, org_id, user_id (who it was for), plan_code, starts_at, ends_at, subscription_id,
  granted_by (owner user id), code_id (null for a direct grant), note, revoked_at, revoked_by,
  created_at`.
- **`public.comp_codes`:** `id, code_hash (sha256; the code itself is shown once), plan_code,
  months, max_redemptions, redeemed_count, redeem_by, note, created_by, disabled_at, created_at`.
- **`public.comp_settings`** (or keys in `instance_settings`): `enabled` (default off),
  `plans` (allowed plan codes, default `["plus", "pro"]`), `max_months` (default 12),
  `max_active` (cap on comps running at once across the instance, default 50).
- **Plans allowed:** monthly plan codes only (`plus`, `pro`, `max` if allowed). Weekly and yearly
  codes are refused: their grant rules (D-432, the yearly branch of `grant_month`) assume a paid
  period, and a comp has none.
- **RLS:** all three tables have RLS on with no `authenticated` policies; only the API and
  `public.allow_worker` reach them. Workspace members see their comp through the billing summary,
  never the tables. pgTAP tests check that.
- **Audit:** every grant, extension, revoke, code create, disable and redemption writes an
  `audit_log` row (`admin.comp.*`, `comp.redeemed`).

### Monthly credits during a long comp

`public.grant_month(sub)` returns `to_char(current_period_end - 1 month)` for a monthly plan. A comp
whose period ends three months out would get the same label every month, so credits would arrive
only once. Add a branch before the monthly one:

```sql
when s.source = 'comp' then to_char(
  (s.created_at at time zone 'utc') + make_interval(months => greatest(0,
    (extract(year from age(now() at time zone 'utc', s.created_at at time zone 'utc')) * 12
     + extract(month from age(now() at time zone 'utc', s.created_at at time zone 'utc')))::int)),
  'YYYY-MM')
```

That's the month of the comp counted from its start, the same idea as the yearly branch. The
`settle()` "due" query already calls `grant_month(e.subscription_id)`, so each new comp month is
picked up within a minute. `expire_credits()` already lapses included credits after the following
month, so unused comp credits don't pile up.

## 5. Server

New `apps/server/src/billing/comps.ts` (class `Comps`, used by `BillingService`):

- `grant({ email | userId, planCode, months, note, grantedBy })`: finds the person (through a
  `public.worker_*`-style security-definer lookup, since the worker never reads `auth`; the API may
  read it). Picks the workspace the way D-211 does: their oldest owned workspace, else the oldest
  one they belong to, unless the caller names `orgId`. Refuses: plan not allowed, months over
  `max_months`, `max_active` reached, banned account, a workspace that already has an active comp
  (offer extend instead), comps switched off. Inserts the `subscriptions` row and the `comps` row in
  one transaction, then `recompute(orgId)`.
- `extend(compId, months)`: moves `ends_at` and `current_period_end`, then recomputes.
- `revoke(compId, by)`: sets `status = 'expired'`, `current_period_end = now()`, `revoked_at`, then
  recomputes. Credits already granted stay (as with a refunded store month, nothing is clawed back;
  see §12 Q6).
- `createCode({ planCode, months, maxRedemptions, redeemBy, note })`: 10 characters of Crockford
  base32 with a `G-` prefix (so it can't be mistaken for an invite code, 6 characters, or a workspace
  code, 8). Returns the code once; only the hash is stored.
- `redeem(userId, orgId, code)`: the signed-in person must own the workspace. Refuses: unknown,
  disabled or used-up code, past `redeem_by`, a person who already redeemed any comp code (one per
  person, by user and by confirmed email, like `claim_trial`), a workspace with an active comp. Wrong
  codes count against the D-167 guessing limit. Locks the code row so two redemptions can't both take
  the last place.
- **A real purchase while comped:** both rows exist, `recompute()` keeps the higher-ranked plan
  (`plans.sort`) as it does today. Buying the same plan while comped is blocked in the paywall
  (§7), so nobody pays for what they have. A comp never calls `claim_trial`, so it doesn't use up the
  person's free trial.
- **When a comp ends:** `settle()` already finds `valid_until < now()`, recomputes, and the workspace
  falls back to Free or to any paid subscription. Seven days before the end, the worker queues a
  push and an email (ZeptoMail, D-318), unless §12 Q5 says no: "Your free Pro ends on <date>. Keep it
  from $49 a month."

### Routes

Instance owner only (`requireOwner`, the explicit `INSTANCE_ADMIN_EMAILS` list), in
`apps/server/src/api/routes/admin.ts`:

| Route | What it does |
|---|---|
| `GET /v1/admin/comps` | Active and recent comps (person's first name and masked email, workspace, plan, dates, source: grant or code) |
| `POST /v1/admin/comps` | Grant |
| `PATCH /v1/admin/comps/{id}` | Extend, or revoke with `{ "revoke": true }` |
| `GET /v1/admin/comp-codes` | Codes with use counts (never the code) |
| `POST /v1/admin/comp-codes` | Create; the response carries the code once |
| `PATCH /v1/admin/comp-codes/{id}` | Disable, or change `redeem_by` and `max_redemptions` |
| `GET` / `PUT /v1/admin/comp-settings` | The switch, allowed plans and caps |

For people:

| Route | What it does |
|---|---|
| `POST /v1/me/comp/redeem` | `{ code, org_id }`. Owner of that workspace only |
| `GET /v1/comp/preview?code=` | No sign-in; "3 months of Pro" or "not valid". Same rate limit as the referral preview |

### Contracts

`packages/contracts/src/billing.ts`: `BillingSource` gains `comp`. `BillingSummary` gains
`comp: { plan_code, ends_at, from: "grant" | "code" } | null`. New admin schemas. Then `pnpm gen`
(Dart client and the OpenAPI document).

### Script

`scripts/comps.sh`, written like `scripts/limit-resets.sh` (owner token from a file, never on the
command line, only `/v1/admin/comp*` routes):

```sh
scripts/comps.sh grant friend@example.com pro 3 "Beta friend"
scripts/comps.sh extend <comp-id> 2
scripts/comps.sh revoke <comp-id>
scripts/comps.sh code pro 3 --uses 10 --until 2026-12-31 "Friends Dec"
scripts/comps.sh list
```

## 6. Store rules: where a code may be typed (important)

App Store guideline 3.1.1 bars an iOS or Mac App Store app from unlocking paid features with its own
codes ("license keys, … promo codes"). An entitlement granted somewhere else is allowed (3.1.3(b),
multiplatform services), which is how a grant already works. Google Play's payments policy points the
same way. So:

- **Grants** work on every platform, because nothing happens inside the app.
- **Gift codes are redeemed only on the web**: app.casama.ai and the casama.ai link page (below),
  plus the direct-download desktop builds. The iOS, Android and Mac App Store builds show no code
  field and don't mention codes. This follows the same split as the store web links, which appear only on web, desktop and
  iOS in the US.
- **Link:** `casama.ai/g/<code>`, served by the site worker like `casama.ai/i/<code>`. It shows what
  the code gives ("3 months of Pro, free"), then **Redeem on the web** (opens
  app.casama.ai/redeem?code=…, sign in or sign up, pick a workspace if they own several, confirm).
  The page tells phone users to then open the app, where the plan appears. No App Link or Universal
  Link for `/g/`, so the phone apps never open a redeem screen.

## 7. App (Flutter)

- **Billing screen:** a comp shows as the current plan with "Free until <date>" (new string) in place
  of "Renews on". No **Manage subscription** button: `onManage` already requires
  `source != 'default'`; add `!= 'comp'`. The paywall hides buying the comped plan itself ("You have
  Pro free until <date>") and still offers higher plans. In the last 7 days, a "Keep Pro" button opens
  the normal paywall for that plan.
- **Redeem screen** (web and direct desktop builds only, behind the same platform check the store web
  links use): Settings → Billing → **Have a Code?** and route `/redeem?code=`. A field, the preview
  line, a workspace picker for people who own more than one, **Redeem**.
- **Admin:** no new screen in this plan (D-435 left the admin console screen out too). The script and
  §9's bot tools cover it.
- New strings in `app_en.arb`, Title Case for buttons and titles. New Dart files import
  `package:material_ui/material_ui.dart`.

## 8. Analytics and costs

- **Events** (server, in `packages/contracts/analytics/catalog.json`, with GA4 twins): `comp_granted`
  (plan, months, from), `comp_redeemed` (plan, months), `comp_ended` (plan, reason: expired, revoked,
  replaced_by_purchase), `comp_converted` (a paid subscription started within 30 days of a comp
  ending, or during it). No email or code in properties.
- **Costs:** comps cost real money: the monthly credits are spent on real model and computer usage.
  `docs/COSTS.md` gets a "Comps" section in the same change: the worst case per comp per month is the
  plan's `monthly_credits_usd` plus included computer hours, times `max_active`. Usage is already in
  `usage_ledger` and grants in `credit_ledger` (reference `monthly:<month>:<plan>`), so the real cost of
  comps is a query by `subscriptions.source = 'comp'`; the plan adds that query to
  `docs/COSTS.md`.

## 9. Admin bot (optional, Phase 3)

Add to D-435's tools, same rules (only proposes, every write approved by a listed owner in the app,
15-minute approval, rate caps): `admin.comps.list` (read), `admin.comps.grant`,
`admin.comps.revoke`, `admin.compCodes.create`. The code from `create` is shown in the approval
result inside the owner's one-to-one chat only. This changes D-435's "nothing about plans or billing"
line, so it gets its own decision entry.

## 10. Phases

**Phase 1: grants (the part Oliver needs now)**
- Migration: source `comp`, `comps`, `comp_settings`, `grant_month` branch, grants and RLS; pgTAP.
- `Comps.grant/extend/revoke`, admin routes, contracts, `pnpm gen`, `scripts/comps.sh`.
- App: "Free until", no Manage button, paywall hides the comped plan.
- `docs/COSTS.md`, decision entry, `docs-site` self-host note (comps are a Cloud feature), CHANGELOG.
- **Done when:** a server test grants Pro for 3 months, sees Pro limits and the first month's credits,
  advances the clock a month and sees the second grant, a third, then sees Free after the end; revoke
  drops to Free at once; a store purchase of Max during a Pro comp wins; a comp doesn't touch
  `claim_trial`. Locally: grant to a test account with the script and check the Billing screen.

**Phase 2: gift codes**
- `comp_codes`, create/disable routes, `redeem`, `preview`, guessing limit, one-per-person check.
- `casama.ai/g/<code>` page on the site worker, the web redeem screen, the platform gate.
- End-of-comp reminder (push and email) and the analytics events.
- **Done when:** tests cover a used-up code, two redemptions racing for the last place, a second code
  for the same person, a non-owner redeeming, an expired code, and the store builds showing no
  field (a widget test per platform flag).

**Phase 3: admin bot tools** (only if §12 Q7 says yes).

Each phase: targeted tests while working, the full suites once at the end through `scripts/heavy.sh`,
commit by path. No deploy, push or Flutter build without asking.

## 11. Other routes (for comparison, not planned)

- **App Store offer codes / Play promo codes:** set up in App Store Connect and Play Console, no code
  from us. Good for "1 month free, then pay"; poor for "free for friends", for the reasons in §2.
  Can be done any time alongside this plan.
- **Dodo discount codes:** a code field in web checkout (`allow_discount_code` on the checkout
  session) for real discounts, like 50% off for 3 months. Worth a small separate change if Oliver
  wants percentage discounts for people who will pay; it doesn't solve free plans without a card.

## 12. Decisions for Oliver

| # | Question | Default if you don't mind |
|---|---|---|
| 1 | Which plans can be comped? | Plus and Pro. Max only by a direct grant, never by a code |
| 2 | Longest comp? | 12 months; extend by hand after that |
| 3 | Cap on comps running at once? | 50 |
| 4 | Gift codes at all, or only grants by email? | Both: grants in Phase 1, codes in Phase 2 |
| 5 | Remind the friend 7 days before the end, with a "Keep Pro" offer? | Yes, one push and one email |
| 6 | On revoke, keep credits already granted this month? | Keep them |
| 7 | Admin bot tools (Phase 3)? | Not now; the script is enough |
| 8 | Does a comp follow the person or the workspace? | The workspace (the oldest one they own), like referral credits; extend or move it by hand |
| 9 | Should comped workspaces count in revenue dashboards as Pro? | No: `source = 'comp'` is left out of MRR and conversion numbers, and shown on its own |
