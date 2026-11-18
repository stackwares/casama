# Billing audit, 2026-11-17

Asked by Oliver: audit the billing system for bugs, leaks and abuse. Four read-only reviews ran
in parallel (credit ledger, payment providers and webhooks, metering leaks, abuse), and every
finding was checked against the code before anything was changed. Production was only read:
markup is 1.4, no purchase is credited to two workspaces, and no workspace's creator had been
cleared (so the hole below was never used; there are 3 workspaces). Follows
[MONETIZATION-AUDIT-2026-11-13.md](MONETIZATION-AUDIT-2026-11-13.md); D-333 records the decisions.

**Status:** every finding below is fixed in the working tree and tested, **not committed or deployed**.

## Fixed

| # | Finding | Fix | Where |
| - | ------- | --- | ----- |
| 1 | **High.** A workspace admin could change `created_by`, `plan`, `suspended_*`, `storage_bytes` and `region` on their workspace through `/rest/v1`: unlimited workspaces past the cap of 5, each with free credits and a fresh Pro trial; lifting an abuse suspension; resetting the storage limit. Owners could also delete a workspace through `/rest/v1`, which wiped its credit and usage history (and any debt) and made the next workspace "first free" again. | A guard trigger refuses changes to those columns from app sessions; the delete policy and grant are gone (the server still deletes workspaces when an account is deleted). | `supabase/migrations/20270201160001_org_billing_guard.sql`, `supabase/tests/org_billing_guard.test.sql` |
| 2 | **High.** Any OpenAI key made live calls free. `billsCalls` treated a Google *or* OpenAI key as "the workspace pays", but every call is Gemini Live on the workspace's Google key or the server's (D-260). One unchecked `sk-x` gave unlimited calls on Casama's Google key. | Only a Google key counts. | `apps/server/src/billing/calls.ts` |
| 3 | **Medium.** Parallel call starts all passed one credit check (the hold was written after the provider token was made), with no limit on open calls. | The call and its hold are written first, under a per-workspace lock, against credits less unsettled usage and the hold. At most 3 open calls on the server's key per workspace (429 `too_many_calls`). No token: the call and hold are removed. | `apps/server/src/api/routes/voice.ts` |
| 4 | **Medium.** A client that never sent a heartbeat was billed 0 seconds and had its hold refunded, while talking to Google for up to 30 minutes. | A quiet call is billed the clock up to the sweep (capped at the token's 30 minutes) at the listening rate, and a call that never sent a heartbeat keeps its hold. | `apps/server/src/billing/live-calls.ts` |
| 5 | **High.** Casama Link's model proxy didn't charge for a stream cut off before visible text: reasoning wasn't counted, and the prompt wasn't charged. A non-streamed call cut off by the caller recorded nothing. The credit check was a fixed small call whatever the prompt size or `max_tokens`. | A cut-off stream is charged the prompt plus everything that came out, reasoning included. A plain call always runs to the end upstream, so its real usage is recorded. Output is capped at 32,768 tokens, and the credits needed cover this call's prompt and that cap. (Any model is still allowed: Link's model credits are pay-as-you-go by design.) | `apps/server/src/billing/link.ts` |
| 6 | **High.** A refund or chargeback after a domain was registered only set `refunded_at`. The workspace kept the domain and could transfer it out. | The domain is suspended (no site, no transfer code, no renewal, locked at the registrar) and instance owners are told. Only for the payment the order was bought with: our own refund of a duplicate payment changes nothing. | `apps/server/src/sites/buying.ts` (`applyDomainRefund`) |
| 7 | **Medium.** A late payment for an abandoned domain checkout whose name another order now holds broke the one-live-order index, so the webhook failed on every retry, leaving a charge with no domain and no refund. Two payments landing at once: the loser was never refunded. A retried amount-mismatch webhook could refund a registered order's payment. | Late payment on a taken name: refunded (`name_gone`). The losing payment of two: refunded. Mismatch on an order past checkout: only a payment that isn't the order's own is refunded. | `apps/server/src/sites/buying.ts` (`applyDomainPayment`) |
| 8 | **High.** Upgrading between paid plans topped the month up to the new plan's credits in full, but Dodo charges pro rata. Plus → Max the day before renewal paid about $2.80 for $25 of credits, and downgrading back kept them, every month. | The top-up for a move between paid plans is the share of the period left. Starting to pay (from Free or a trial) still tops up in full. | `apps/server/src/billing/service.ts` (`recompute`) |
| 9 | **Medium.** Changing plans during a web trial was allowed, which could give another plan's limits and credits before anything was paid. | Refused with 409 `trialing`. | `apps/server/src/billing/service.ts` (`checkout`) |
| 10 | **Medium.** The settle sweep counted every trialing workspace as due every minute (the trial grant's reference ends in `:trial`), and its 500-row limit had no order, so lapsed subscriptions could keep paid limits. | Trial grants count; lapsed subscriptions go first. | `apps/server/src/billing/service.ts` (`settle`) |
| 11 | **Medium.** A plan's computer hours were only checked inside runs, so live view or a terminal could keep a hosted computer running past them. | Checked on every hosted start (402 `computer_hours_exceeded`), and the meter puts computers past their hours to sleep. | `packages/agent/src/computers.ts`, `apps/server/src/api/app.ts` |
| 12 | **Low.** Self-hosted servers not behind Cloudflare took the report and submission addresses from headers the visitor sets (three spoofed reports hid any page). Casama Cloud was never affected: `cf-connecting-ip` is set by Cloudflare. | The server's `TRUSTED_CLIENT_IP_HEADER` is used first. | `apps/server/src/pages/shared.ts`, `pages/app.ts`, `pages/sites.ts`, `api/routes/sites.ts` |
| 13 | **Low.** `return_url` on checkout and the portal accepted any address. | The app's own origin or the `casama:` scheme only; anything else falls back to Billing. | `apps/server/src/api/routes/billing.ts` |
| 14 | **Low.** Two workspaces could both be credited for one store credit pack if RevenueCat listed it under both and they synced at once. | A unique index on bought-pack references across workspaces (production has no duplicates). | the same migration as #1 |
| 15 | **Medium** (was O1). Monthly credits followed the calendar month: a subscription started on the 31st got the next month's grant the next day. | Grants are labelled by the paid period (`public.grant_month`): monthly plans by the month the period started, yearly plans by the current one-month slice of the year, a trial by the month it started. | `supabase/migrations/20270201160301_billing_periods.sql`, `billing/service.ts` |
| 16 | **Medium** (was O2). Any refund, even partial or of an old renewal, ended the subscription for good, and the clawback only took the calendar month's grant. | A refund ends the period it paid for (`refunded_through`); a later paid period is honoured again. Only a full refund of the current period's payment, or a lost dispute, revokes it, and then every paid grant since that period started comes back out. | the same migration, `billing/service.ts`, `billing/dodo.ts` |
| 17 | **Medium** (was O3). One workspace could fill every run slot, all passing one credit check. | The runs queue is partitioned by workspace: at most `RUN_WORKSPACE_CONCURRENCY` (5) runs of one workspace at once, the rest wait. Runs queued by an older process get their key at start. | `apps/server/src/worker/run-queue.ts`, `worker/index.ts`, `worker/workflows.ts`, `api/workflows.ts` |
| 18 | **Medium** (was O4). Gallery rewards counted any account that installed or called `…/used`. | Only confirmed accounts 7+ days old, not the item's submitters, with a successful run using it, count. At most $110 per contributor per month; anything over is recorded and paid later or reviewed. | `supabase/migrations/20270201160101_gallery_reward_rules.sql`, `services/gallery-usage.ts`, `services/gallery-jobs.ts` |
| 19 | **Medium** (was O5). Casama Link computers had no plan limits and weren't put to sleep at zero credits. | Create and resume take a per-workspace lock and check `max_computers`, running computers and computer hours; the size is cut to the plan's. The settle sweep sleeps link computers at zero credits or past their hours, and the next resume restores that sleep's snapshot. The clock and usage are written in one transaction. | `billing/link.ts`, `billing/service.ts`, `supabase/migrations/20270201180001_link_computers_swept_snapshot.sql` |
| 20 | **Low–Medium** (was O6). "+tag" and Gmail-dot accounts on one inbox each got free credits, a trial and referral rewards; deleting an account started fresh. | `email_identities` keys these on a SHA-256 of the normalised email and outlives the account: one account per inbox gets free credits, one subscription per inbox holds the trial, and each inbox is decided once for referrals (never on the inviter's own inbox). | `supabase/migrations/20270201160401_email_identities.sql`, `billing/service.ts` |
| 21 | **Low** (was O7). Live calls trusted the app's token counts. | Calls paid from credits go through the server's relay (`LIVE_CALL_RELAY`, on): the app gets a relay secret, never the Gemini token, frames pass through unchanged, and the call is charged what Gemini reported through the relay (or the app's counts when higher). No app change needed. | `apps/server/src/api/live-relay.ts`, `api/routes/voice.ts`, `billing/live-calls.ts`, `supabase/migrations/20270201160601_live_call_relay.sql` |
| 22 | **Low** (was O8). Failed media generations, a cancel before any text and paid data before a credit check cost nothing. | Failed generations are recorded at their estimate; a cancel is charged the prompt; paid data checks credits first. | `packages/agent/src/media.ts`, `run.ts`, `data.ts` |
| 23 | **Low** (was O9). Credits given back (a hold larger than the usage, a waived run) never expired. Two web trials were possible from parallel checkouts. | A give-back refills the open lots it was spent from (what's left lapses at the end of next month). A web trial that starts although the person's trial is used gives nothing until it's paid (`subscriptions.trial_blocked`). | `supabase/migrations/20270201160501_credit_give_backs.sql`, the identities migration |
| 24 | **Low** (was O10). `max_computers` was count-then-insert. | A trigger like `enforce_max_bots`, under a per-workspace lock. | `supabase/migrations/20270201160201_max_computers_trigger.sql` |
| 25 | **Low** (was O11). Domain payments assumed USD; signed provider webhooks shared the 120/min `/hooks/*` limit; bot cards used `amount*100` for every currency. | Non-USD payments use Dodo's USD settlement or are refunded; the four signed webhooks get their own higher limit; currency exponents are right, and bot cards are USD only (the caps are in dollars). | `sites/payments.ts`, `api/app.ts`, `packages/agent/src/payments.ts`, `api/routes/payments.ts` |
| 26 | **Low** (was O12). The no-web-links-on-Android rule lives only in the app. | Documented on `POST /v1/orgs/{id}/billing/checkout`: the server can't know the device, and a header would be trivial to fake. Store rules are the client's. | `packages/contracts/src/routes/billing.ts` |

New and updated tests: `org_billing_guard`, `email_identities`, `credit_give_backs` and
`max_computers_trigger` in `supabase/tests`; `voice-cloud-calls`, `live-calls`, `live-relay`,
`link-cloud`, `domains-buy`, `pricing-d249`, `billing`, `referrals`, `run-queue`, `gallery-v2`,
`hooks-rate-limit` and `paid-data` in `apps/server/test`; `computers-limits`, `metering-leaks`,
`media-prices` and `payments-currency` in `packages/agent/test`.

## Not changed, on purpose

- **Sandbox store purchases count** (TestFlight, Play testers, App Review). One review flagged this
  as high, but it's deliberate (`billing.test.ts`, "a sandbox purchase … counts like any other"):
  Apple reviews purchases with sandbox accounts in the production build. Only testers Casama
  invites can make them. Revisit if TestFlight ever gets a public link.
- **Link's model proxy takes any model.** It's pay-as-you-go at provider cost times the markup
  (docs-site/self-hosting/casama-link-cloud.md). Only the metering was the hole.

## Still to know

Nothing from the first list is open. What these fixes leave, or change for people:

- **Bot cards are USD only.** The monthly caps are in dollars and there's no exchange rate, so a
  bot can no longer ask for a card in another currency (a UK or EU Stripe Issuing account issues
  GBP or EUR cards).
- **Live calls go through the server.** It adds a hop between the app and Google, and every
  billable call's audio crosses the API (about 100 KB/s a call). Needs a real call on a phone and
  the web app after deploying; `LIVE_CALL_RELAY=off` goes back to direct.
- **Free cloud workspaces get fewer Link computers**: link computers now count toward
  `max_computers`, so a Free workspace whose server already has one can't create another.
- **Link gaps left**: hosted computer creation doesn't count link computers in its trigger;
  `/exec` on a running link computer checks credits only (the sweep covers hours); link computers
  are billed one rate whatever their size; snapshots a sweep replaced aren't deleted.
- **Non-USD domain payments** rely on Dodo's `settlement_amount` being the USD amount. If it isn't,
  those payments are refunded as mismatches (safe, but blocks local-currency buyers).
- **One inbox, one set of free things** keeps a SHA-256 of a normalised email after an account is
  deleted. Proof-of-work difficulty and OAuth sign-up are unchanged.
- **A blocked second trial** still runs at Dodo; it gives nothing until Dodo charges it.
- **Generated types** (`packages/db/src/generated/schema.ts`) don't have the new columns yet; the
  code uses SQL for them.
