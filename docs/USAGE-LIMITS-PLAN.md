# Usage limits by day, week or month: plan

Status: **not started** (written 2026-11-20). Oliver asked whether to limit people by day, week
or month, or let them choose, then said "You decide everything for me". Every decision in section 2
is made on that basis. The same day he asked for saved resets "like ChatGPT and Claude", given out
only by admins, with a schedule and an expiry: that is `docs/LIMIT-RESETS-PLAN.md`. No code until
Oliver says to build it.

## 0. Summary

People don't choose their limit window, and there isn't one window for everyone.

| Who | Window | Change from today |
|---|---|---|
| Free | **A day.** $0.05 of credits each day, gone at the day's end, plus $0.50 once to start | Today: $1 a month, at most $0.25 a day |
| Plus, Pro, Max (monthly, yearly) | **The paid month** | None |
| Plus, Pro, Max (weekly) | **The paid week** (a quarter of the month's credits, D-432) | None |
| Every plan | A daily limit on Casama's models, as a guard against runaway spend | Free's goes from $0.25 to $1 |
| Each bot | The daily and per-run budget its owner sets | None |

Only Free changes. The paid plans already work the way this plan recommends.

One thing is new for every plan: a **saved reset** (`docs/LIMIT-RESETS-PLAN.md`). The instance owner gives workspaces
a one-time refill of their included credits, which they use when they choose, before it expires.

## 1. What happens today

- **Credits are dollars** (D-245). Each plan grants credits per paid month: Free $1, Plus $5,
  Pro $15, Max $30 (D-249). A month's credits last until the end of the following month (D-246).
- **A daily limit on Casama's models** per workspace (`cloud_daily_usd`, D-244, D-311): Free $0.25,
  Plus $5, Pro $10, Max $25. It resets at midnight UTC. On paid plans it is at or near the whole
  month's credits, so it only stops runaway spend. On Free it is the limit people really meet.
- **A chat message costs about $0.009** on production since D-354 and D-355 (20 runs measured on
  2026-11-18; a small sample).

So a Free person gets about 27 messages a day for four days, then nothing for the rest of the
month. Whoever liked the app most on day one is locked out soonest, with no reason to open it
again until next month.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| 1 | No setting to choose the window | Most people wouldn't understand it, and it means three ways of counting to keep correct and explain in support |
| 2 | Paid plans keep the paid period as their window | Bot work comes in bursts. A daily or weekly slice would stop someone on a heavy day while paid credit is left. Running out early is also when a credit pack or an upgrade sells |
| 3 | Free gets credits by the day: **$0.05**, about 5 messages, not carried over | A reason to come back tomorrow, an upgrade prompt that is seen often, and a bounded cost per free person per day |
| 4 | Free gets **$0.50 once** per person, lasting 30 days | The first session sets up a bot and tries things. Five messages would end it before the person has seen what a bot does |
| 5 | Free's monthly credits go to $0 | Replaced by 3 and 4 |
| 6 | Free's daily limit on Casama's models goes from $0.25 to **$1** | The day's credits now do the pacing. The limit is left as a guard, and at $0.25 it would hold back credits a Free person earned (gallery rewards, referrals) |
| 7 | The day ends at midnight UTC | The same reset the daily limit already uses. The app shows it as a local time ("back at 8:00 AM") |
| 8 | Check-ins on Free may use 40% of the day's credits, not 40% of the daily limit | Otherwise a scan could spend the whole day's credits before the person sends a message |
| 9 | Paid plans get no pacing cap inside the month. The meter's amber at 80% and the low-credits notice stay | A second window would be a second way to be blocked |
| 10 | Both Free amounts are plan limits, editable in Admin → Pricing | They are a first guess from a small sample. Change them without a deploy once there are real numbers |
| 11 | Current Free workspaces keep the monthly credits they already have until those lapse | Nothing is taken back |

**What it costs us.** A dollar charged costs Casama about $0.68 (markup 1.4, OpenRouter fee 1.055).
A Free person active every day costs at most about $1.02 a month, against $0.68 today, plus $0.34
once for the start. A Free person active six days a month costs about $0.20, against up to $0.68
today. Most free people are the second kind, so the total should go down. That is an estimate;
section 6 says how to check it.

## 3. How it works

- **New plan limits:** `daily_credits_usd` and `welcome_credits_usd` in `plans.limits`. Free gets
  0.05 and 0.5, with `monthly_credits_usd` 0 and `cloud_daily_usd` 1. Plans without the keys work
  as today, so self-hosted and paid plans are untouched.
- **The day's credits are an ordinary credit lot** (`credit_lots`, D-246) that lapses at the next
  midnight UTC. Spending already takes the lot that lapses first, so the day's credits go before
  the start credits, and both before earned credits.
- **Granted on first use, not by a sweep.** The lot is made when the workspace first needs credits
  that day (a run starting, the billing summary being read), keyed `daily:YYYY-MM-DD:free` so it
  can happen only once. A sweep would write a row a day for every free workspace, used or not.
- **One free workspace per person** gets them, the same rule as today's free credits (D-246).
- **Start credits** are granted once per person, keyed on the person, when their first free
  workspace is made. Deleting the account and signing up again doesn't grant them twice (the same
  check the Pro trial uses, D-249).
- **Out of credits on Free** says: "You've used today's free credits. They come back at <time>.
  Upgrade for more." The server writes it, so apps already shipped show it too.
- **The low-credits notice** (under $1, weekly) skips plans with `daily_credits_usd`, or every Free
  person would get it every week.

## 4. What people see

- **Free, in the app:** the credits meter shows today's credits and when they come back, in place
  of the month's bar. "Today's limit" (D-311) is hidden on Free while the day's credits are the
  smaller number, so there is one bar and one reset time.
- **Billing API:** `GET /v1/orgs/{id}/billing` gains an optional `allowance` object (period as a
  plain string, amount, used, when it resets). Optional and not an enum, so apps already shipped
  keep parsing the response; they show the balance, which is today's credits, and stay correct.
- **Paid plans:** nothing changes.
- **Copy:** "$1 of credits a month" becomes "free credits every day" on casama.ai/pricing, the
  docs (FAQ, Usage), the paywall's Free column and the store listings in `client/store/`. The FAQ's
  daily limit line changes to $1 on Free.

## 5. Phases

| Phase | What | Done when |
|---|---|---|
| 1 | Server: the two limits, the daily lot and start credits, the check-in share, the message, the notice rule, `allowance` in the contract. Migration sets Free's limits | Server tests for: one grant a day, lapse at midnight, second free workspace gets none, start credits once per person, earned credits spend past the day's, paid plans unchanged; pgTAP for any new function |
| 2 | App: the Free meter and the out-of-credits sheet | Widget tests for Free and paid meters |
| 3 | Words: site, docs, paywall, store listings, `docs/COSTS.md`, `CHANGELOG.md`, the decision entry | Pages checked locally with `scripts/serve-web.py` |
| 4 | Ship: server deploy, web deploy, app builds | Each needs Oliver's yes |

Other sessions have uncommitted work in `packages/domain/src/budget.ts`,
`apps/server/src/billing/service.ts` and `credits_meter.dart` (computer hours in the billing
summary, 2026-11-20). Phase 1 starts after that lands, or in a worktree.

## 6. After it ships

Two weeks after the deploy, from `usage_ledger` and `credit_ledger` on production (read-only):

- Free people active on 2 or more days in their first week, before and after.
- Charged credits per free workspace per month, before and after.
- How many Free people hit the end of the day's credits, and how many of those open the paywall
  and upgrade.
- How many use up the start credits on day one.

Then adjust the two amounts in Admin → Pricing.

## 7. Not in this plan

- A choice of window for members.
- Saved resets: `docs/LIMIT-RESETS-PLAN.md`.
- Weekly or 5-hour windows on paid plans.
- Changes to paid credits, prices, credit packs or computer hours.
- Local time zones for the reset.

## 8. Saved resets

A one-time refill the instance owner gives to workspaces, used when they choose, before it expires.
It has its own plan: `docs/LIMIT-RESETS-PLAN.md`.
