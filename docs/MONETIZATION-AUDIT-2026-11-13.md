# Monetization audit, 2026-11-13

> **Status (2026-11-13, evening):** every item below has been fixed. Findings 1–4 and B1–B2 shipped
> in D-246 (live). Findings 5, 6 and 8–17 and B3, B5 and B7, plus the paywall list, are in D-248.
> D-249 repriced the plans (B6 became extra seats). Still open: Casama's own Terms of Use page
> (Apple's standard EULA stands in), and setting `COMPUTER_HOST_CAPACITY` (or D-250's memory budget)
> on the production server.

Business model, pricing, metering, paywalls and store rules for Casama Cloud. Read-only: nothing
was changed or deployed. Production was only read (queries, function grants).

Sources: docs/COSTS.md, D-070, D-071, D-186, D-188, D-211, D-236, D-244, D-245, the server billing
code, the app's paywall and Billing screens, and production's `usage_ledger`, `plans` and grants.
"Verified" means the code path (and where noted, production) was read end to end.

## Verdict

The pricing itself holds up: runs are cheap (production average **$0.005 a run** before markup, so
about $0.007 billed), margins stay at 67–77% even if every plan is fully used, and break-even on the
$60–80 monthly floor is about six Plus subscribers.

What doesn't hold up yet is **collection**. There's a live hole that gives anyone an unlimited
workspace. Several things Casama pays for (images, video, read-aloud) are recorded as not
billable, and some paths skip the credit gate. The paywall would likely fail App Review and can
bill people for two subscriptions at once. Prod also can't take money yet: D-244's plans aren't
committed or deployed.

## Fix now (live in production or blocks launch)

| # | Finding | Where | Status |
|---|---|---|---|
| 1 | **Anyone can make an unlimited workspace.** `create_organization` is granted to `authenticated`, and a new organization defaults to plan `selfhost` (`{"unlimited": true}`): no credit gate, no bot, computer, hour or seat limits. Only the API path calls `recompute` afterwards. A signed-in user calling `POST /rest/v1/rpc/create_organization` skips it, and settlement never repairs it. | `20261109000001_workspaces.sql:15,240`; `billing_stubs.sql:40`; `service.ts:576-582` | **Verified, prod grant confirmed** |
| 2 | **Images, video and read-aloud on Casama's keys are free.** The inserts leave out `billable` and `meta`, the trigger only sets billable for computer and stream seconds, and no markup is applied. They're not in the daily cap either, and video runs without asking, so a bot or routine can loop 20-second videos on the server's Gemini key. Prod already has six such rows ($0.98). | `autonomy.ts:854,912`; `worker/voice.ts:121-131`; `run.ts:1645` | **Verified in prod** |
| 3 | **One person, unlimited free workspaces**, each with $1 a month, 5 computer hours and a $0.25 daily model allowance. | `create_organization` | Verified |
| 4 | **The credit gate only applies when the bot's main model is on Casama's key.** Fallbacks on Casama's key, Composio app calls, paid data calls, dictation and media all spend with no gate, so balances can go arbitrarily negative. | `run.ts:1657-1680`, `:3171`; `data.ts:286` | Verified |
| 5 | **No Terms or Privacy links on the paywall**, and Billing's plan buttons have no period, auto-renew text or links. Likely App Review rejection (3.1.2). | `paywall.dart:1020-1110`; `billing_screen.dart:236-254` | Verified |
| 6 | **Double subscriptions.** On Play, a different plan is bought as a new subscription (no `ChangeSubscriptionParam`), so Plus and Pro both bill. Web checkout always starts a new Dodo subscription, so a Pro subscriber picking Max pays $39 + $149 every month. Nothing stops a web subscriber from also subscribing through Apple. (iOS alone is fine: one subscription group.) | `core/billing.dart:150`; `service.ts:460-488` | Verified |
| 7 | **Prod can't charge anyone.** Prod still has the old plans (Free, and Pro with $20 credits), no `billing_settings`, and no D-244 prices or products. The D-244 migration and paywall rewrite are uncommitted in another session. | prod `plans`; `20270129000001_pricing.sql` (untracked) | Verified |

## Money leaks (fix before real volume)

| # | Finding | Where |
|---|---|---|
| 8 | Live voice calls are billed from what the app reports (`seconds`, `usage` in the request). A killed or modified app records $0 for up to 30 minutes per token. New sessions only check `balance <= 0`. | `api/routes/voice.ts:274-299`, `:146` |
| 9 | Cancelled or failed model streams record nothing: a long answer cancelled before the end is free. | `run.ts:1960-1986` |
| 10 | Running computers are charged only when they stop, and nothing stops one at zero credits. `computer_hours` counts finished rows only. | `computers.ts:202-214,385-388` |
| 11 | Refunds keep the credits: a refunded subscription keeps its monthly grant, and refunded store packs aren't clawed back (only Dodo packs are). | `service.ts:168,286`; `app-store.ts:178`; `google-play.ts:154` |
| 12 | Monthly grants multiply: the key is `monthly:<month>:<plan>`, so switching plans in a month grants each one (up to $131). Grants follow the calendar month, not the billing period. | `service.ts:400` |
| 13 | Cloud Connect sells models at markup 1 (`CLOUD_MODEL_MARKUP`), so it loses OpenRouter's 5.5%. It allows any model, has no daily cap and no reserve, and a client that disconnects before the last chunk isn't metered. | `env.ts:131`; `connect.ts:73-77,283` |
| 14 | Downgrades don't shrink anything: an expired Max workspace keeps 50 bots, 10 computers and 10 members. Simultaneous creates can race past limits. | `limits.ts:22-44` |
| 15 | Referral welcome bonus is uncapped: each disposable account earns $2 for itself (plus $2 for the inviter, capped at 20). | `referral_fixes.sql:81-87` |
| 16 | **No host-wide computer cap.** The VPS fits about 9 one-GB computers and Max allows 10 per workspace. Containers have per-computer limits, but nothing caps the total, so a few paying users can starve the API and Postgres. | `sandbox/src/docker/provider.ts:284` |
| 17 | Memory embeddings on Casama's key aren't recorded (tiny). | `worker/index.ts:243-250` |

Checked and sound: Dodo webhook signatures and dedupe, the App Store certificate chain and
sandbox/production split, Play push auth, one store transaction crediting one workspace, refund
replay protection.

## Business model

**B1. Credit packs undercut the Plus plan.** Free plus a $10 pack gives $11 of credits for $10.
Plus gives $5 for $15. For anyone who wants more AI use rather than more bots, the pack wins,
and packs earn 16% against Plus's 70%.
*Recommend:* sell packs only to paying plans. A Free user who runs out then sees the upgrade,
which is the conversion moment you want. If packs stay open to everyone, give plans clearly better
credit value instead (for example Plus $8, Pro $20, Max $80). That still keeps 55–70% margin when
fully used.

**B2. Credits never expire.** Monthly grants pile up forever: that's an unbounded liability, and
no unused credit ever expires to offset costs.
*Recommend:* included credits carry over for one month (balance capped at 2× the monthly
amount); packs last 12 months, stated at purchase.

**B3. The out-of-credits moment sells the wrong thing.** Running dry mid-chat opens the
subscription paywall, which never lists packs. A Max yearly user who runs out can't buy anything
(their own plan shows as "Current plan"), and the headline doesn't say why the paywall opened.
*Recommend:* a dedicated out-of-credits sheet. Packs come first for paying users (they're cheaper
to sell and keep the subscription), the upgrade comes first for Free users, and the sheet says
"You're out of credits".

**B4. Unit economics are healthy, and better than COSTS.md assumes.** On production data a run is
about $0.007 billed, so Free's $1 is about 135 runs a month, Plus about 670 and Pro about 1,350.
Computers on Docker cost about $0.008 an hour. The real cost risks are the leaks above and server
capacity (B5), not the prices.

**B5. Capacity is the hidden fixed cost.** Max's 10 computers per workspace is more than the
whole current server. Before selling Max, add a host-wide cap with a queue (finding 16) and plan
the dedicated server (€159/month, about 28 computers). One Max subscriber covers it.

**B6. Seats are priced flat** (Pro 5 seats for $39). Fine for launch. Revisit with per-seat team
pricing once workspaces with more than one member show up.

**B7. Revenue can't be measured.** Purchase events carry no amount, no `kind` (plan or pack) and
no `source` (which paywall). There's no plan-selection event. Store packs never send the server's
`purchase` event. ARPU, LTV and paywall conversion can't be calculated.

## Paywall and stores (beyond 5 and 6)

- **Default offer:** a Free user who hits the 2-bot limit lands on Pro yearly ($390 up front).
  Default to Plus monthly, or A/B test it.
- **Headline:** always says "Pro", even when Plus or Max is selected. Plus and Max buyers also see
  "Welcome to Pro!".
- **"2 months free":** hardcoded. Store prices are set per country, so work it out from the
  store's raw prices.
- **Max yearly:** has no App Store price yet. With no store product, the button is a dead
  "Continue" showing a hardcoded USD price, and failed product loads aren't retried.
- **Store purchases:** only verified after Billing or the paywall has been opened. Ask to Buy
  approvals and redelivered purchases wait. Start the verifier at launch.
- **Purchase feedback:** pending, failed and restored purchases show nothing. Someone who paid
  but failed verification sees nothing happen. Restore never reports a result.
- **Pro yearly user taps Monthly:** they're offered Pro monthly, because the current-plan check
  compares exact plan codes.
- **Members:** members (non-admins) get no Restore button.
- **Docs:** D-070 says packs are web only, but D-244 sells them in the stores. Update D-070.
  D-236 still describes the old side-by-side paywall.

## Suggested order

1. Close the unlimited-workspace hole (#1, #3): new organizations default to `free` when billing is
   on, or `create_organization` is revoked from `authenticated` and only the API creates them. Cap
   workspaces per person.
2. Make media and read-aloud billable with markup, and put them under the gate and daily cap (#2).
   Gate every billable path, not just the primary model (#4).
3. Store compliance and double billing (#5, #6): Terms and Privacy on the paywall and Billing,
   plan changes as upgrades (Play `ChangeSubscriptionParam`, Dodo plan change, one active channel).
4. Finish and deploy D-244 (#7), with B1 and B2 decided first, since they change the plan table.
5. Out-of-credits sheet with packs (B3) and purchase analytics with amounts (B7).
6. Leaks 8–15, then the capacity cap (16) before selling Max.
