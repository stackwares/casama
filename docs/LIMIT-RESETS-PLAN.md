# Saved resets: plan

Status: **built; not deployed** (written and approved 2026-11-20). Oliver asked for "a banked reset like ChatGPT and
Claude", given out only by admins, with scheduling and expiration, then: "Make sure we have full
control of this as dev and admin only. Just write full plan for now." Every decision here is made
under his earlier "You decide everything for me". Oliver approved implementation on 2026-11-20.

It builds on `docs/USAGE-LIMITS-PLAN.md` (which window each plan's limit uses) but doesn't need it
built first, except for the Free plan (section 4).

## 0. Summary

A **saved reset** is a one-time refill of a workspace's included credits. It sits on the workspace
until an owner uses it or it expires. It is not bought credit and doesn't raise the plan's limits.
OpenAI calls this a banked reset (Codex) and Anthropic a limit reset (Claude); both hand them out
after outages, at launches and as goodwill.

- **Only the instance owner gives them out.** Nobody else can make one, earn one or change one.
- **Everything about a hand-out is set by the owner:** who gets it, when it lands, when it lapses,
  what it refills, how much it may cost in total.
- **It can be stopped at any point:** one hand-out paused or cancelled, one workspace's reset taken
  back, or the whole feature switched off, all without a deploy.
- **Every admin action is logged** and can't be edited.

## 1. Who controls what

| Who | Can do | Through |
|---|---|---|
| **Instance owner** (`INSTANCE_ADMIN_EMAILS`; on production admin@casama.ai) | Everything in section 2 | Admin → Resets in the app, and the same routes under `/v1/admin/limit-resets` |
| **Developer** | The same, from a terminal, signed in as an instance owner; plus the switch and the defaults in section 2.4 | `scripts/limit-resets.sh` (a thin wrapper on the admin routes), read-only SQL for checks |
| **Workspace owner** | See the workspace's resets and use one | Usage, the Billing card, the out-of-credits sheet |
| **Other members** | See that a reset is there | The same places, no button |
| **Bots, plugins, the public API, MCP** | Nothing | No tool, scope or route reaches it |

There is no second admin role: the gate is `isInstanceOwner`, the one the rest of Admin uses
(`apps/server/src/api/routes/admin.ts`), and everyone else gets 403 `not_instance_owner`. A
developer has no back door around it. A developer who needs to act on production signs in as the
instance owner, so the action is logged like any other.

## 2. The controls

### 2.1 A hand-out

| Setting | Values | Default |
|---|---|---|
| Name | For the owner's own list; people never see it | Required |
| Text people see | One line, up to 120 characters ("Sorry about Tuesday's outage. Here's a reset.") | Required |
| Who gets it | Any mix of: plans (each plan and period separately, so weekly can be left out); workspaces created before a date; workspaces that hit a limit in the last N days; a pasted list of workspace IDs | Every paid plan |
| Starts | Now, or a date and time | Now |
| Expires | A date and time, exact to the minute | 14 days after the start |
| Refills | Share of the period's included credits (10–100%); today's count against the daily limit (on/off); computer hours (on/off) | 100%, on, off |
| Most refilled per use | A dollar amount, or none | None |
| Budget for the whole hand-out | A dollar amount of refilled credits, or none | None |
| Tell people | Push and inbox line on arrival; reminder 24 hours before expiry | Both on |

Before it is saved, the owner sees a **preview**: how many workspaces would get it, by plan, and
the worst case in charged credits and in real cost (every workspace uses it when empty).

### 2.2 The life of a hand-out

`draft` → `scheduled` → `live` → `ended`, with `paused` and `cancelled` as stops.

| Action | Allowed when | What it does |
|---|---|---|
| Edit anything | Draft or scheduled | |
| Edit the text, the expiry, the budget, the reminder | Live or paused | An expiry can move both ways, but never to before now |
| Pause | Live | Nobody can use one from this hand-out until it is resumed. The expiry keeps counting |
| Resume | Paused | |
| Cancel | Any time before it ends | Unused resets are removed. Used ones stay used |
| Delete | Draft only | Anything that reached people is kept for the record |

Who gets it and what it refills can't change after the start. To change those, cancel it and make
another.

### 2.3 One workspace

| Action | What it does |
|---|---|
| Give a reset | A one-off for one workspace, with its own text, expiry and refill settings. For support, after something of ours broke for one customer |
| Take back | Removes an unused reset |
| Undo a use | Takes back the refilled credits that haven't been spent yet. For a mistake or abuse; spent credits are left alone |
| History | Every reset the workspace was given: from which hand-out, used or not, by whom, what it refilled |

### 2.4 The whole feature

| Setting | Where | Default |
|---|---|---|
| On or off | `billing_settings.limit_resets_enabled`, a switch in Admin → Resets. Off hides the feature from every app and refuses every use; hand-outs keep their state | **Off** |
| Uses per workspace per period | `billing_settings.limit_resets_per_period` | 1 |
| Most a workspace can hold at once | `billing_settings.limit_resets_max_held` | 3 |
| A notice to the owners when a budget runs out or a hand-out ends | Push to instance owners | On |

Servers with billing off (self-hosted) never show any of this: there are no credits to refill.

### 2.5 The log

`limit_reset_events`: one row per admin action and per use, with who, when, what, and the values
before and after. Nothing updates or deletes its rows, including the server. Admin → Resets shows
it per hand-out and per workspace, and it exports as CSV.

## 3. What using one does

- **Tops up, never adds.** It brings the period's included credits back up to the plan's amount
  (or the share the hand-out sets). Used while nearly full, it gives nearly nothing, so the app
  says what it will refill before the owner confirms.
- **With nothing to refill** it refuses and keeps the reset.
- **Refilled credits lapse when the current period ends.** A reset is not credit carried into next
  month.
- **The period is the plan's own:** the paid month, the paid week on weekly plans, the day on Free
  (section 4).
- **Today's count against the daily limit is cleared** when the hand-out says so, so the refill is
  usable the same day.
- **Computer hours** go back to the plan's amount for the month only when the hand-out says so.
- **One at a time.** With several saved, the one that expires first is used.
- **It can't be undone by the person.** Only the instance owner can undo a use (section 2.3).

## 4. Free plan

Free workspaces can be chosen like any plan. A reset refills the day's credits once
`docs/USAGE-LIMITS-PLAN.md` is built; until then it refills the month's $1. Hand-outs default to
paid plans only.

## 5. What it costs us

A dollar of charged credits costs Casama about $0.68 (markup 1.4, OpenRouter fee 1.055).

| Plan | Most one use refills | Real cost |
|---|---|---|
| Free | $1 today, $0.05 after the usage-limits plan | $0.68, then $0.03 |
| Plus | $5 | about $3.40 |
| Pro | $15 | about $10.15 |
| Max | $30 | about $20.30 |
| Weekly plans | A quarter of the above | |

Bounded three ways: the preview before saving, the budget on the hand-out, and the uses per
period. Refills are `credit_ledger` rows with their own reason (`reset`), so what a hand-out really
cost is one query, shown in Admin → Resets. `docs/COSTS.md` gets a line in the same commit as the
code.

## 6. How it works

### Data

| Table | Holds | Access |
|---|---|---|
| `limit_reset_campaigns` | A hand-out: name, text, audience, starts_at, expires_at, refill settings, budget, state, who made it | Server only |
| `limit_resets` | One reset on one workspace: campaign or one-off, text, expires_at, used_at, used_by, credits refilled, taken back or not | Members read their own workspace's rows; server writes |
| `limit_reset_events` | The log (section 2.5) | Server only; inserts only |

All three get RLS, `public.allow_worker` and pgTAP tests. Before naming the migration, check every
branch, worktree and the local database for the newest migration version.

### Server

- **The start:** the worker, every minute, moves due `scheduled` hand-outs to `live` and gives one
  reset to each workspace in the audience, once (a unique key on workspace and campaign). The
  audience is fixed at that moment.
- **The end:** the same step marks hand-outs past their expiry `ended`. An expired reset simply
  stops being usable; nothing has to run for that.
- **Using one:** `POST /v1/orgs/{id}/billing/resets/redeem`, workspace owners only. One transaction
  with a lock on the workspace's credits: check the switch, the state, the expiry, the uses this
  period and the budget; work out the refill on the server; write the credit lot, the reset and
  the log row. Two taps refill once. The request carries no amounts.
- **Budget reached:** further uses are refused ("This reset isn't available right now"), the
  resets are kept, and the instance owners get a push. Raising the budget makes them usable again.
- **Admin routes** (instance owner): list, preview, create, edit, pause, resume, cancel, delete;
  give, take back and undo for one workspace; the log; the feature settings. All in the OpenAPI
  contract.
- **Billing summary:** an optional `resets` list (text, expiry, what it would refill, whether this
  member can use it). Optional and without enums, so apps already shipped keep parsing it.
- **A refunded plan** takes its refills back with the period's credits.
- **Notices:** arrival and the 24-hour reminder go to workspace owners, as plain-text pushes
  (D-312), and only between a workspace's quiet hours.
- **Analytics:** `reset_given`, `reset_used`, `reset_expired` in the event catalog, with the plan
  and the hand-out's ID, no personal data.

### What can't happen

- A member, a bot, a plugin or an API key making, editing or extending a reset: no such route.
- A use changing its own amount: the server computes it.
- Collecting one by subscribing after the start: the audience is fixed at the start.
- Using a reset twice, or two at once: the lock and the unique key.
- An edit to the log: inserts only, for every database role.

## 7. What people see

- **Usage and the Billing card:** under the meter, "1 reset saved. Use by Dec 5, 6:00 PM." with the
  hand-out's text and a **Use Reset** button for owners.
- **Out of credits:** the sheet offers **Use Reset** first, above the plans and packs.
- **Confirm:** "Refills $4.20 of this month's credits. This can't be undone."
- **Admin → Resets:** the switch; the list of hand-outs with state, given, used, expired and
  credits refilled; the editor with its preview; a workspace lookup with give, take back, undo and
  history; the log.
- **Apps already shipped** can't use one. The first hand-out waits for the build with the button,
  and its expiry leaves time to update.

All screens are native Flutter, with strings in `app_en.arb`.

## 8. Phases

| Phase | What | Done when |
|---|---|---|
| 1 | Tables, the switch and settings, the worker's start and end, redeem, the refund rule, the billing summary field | Server tests: handed out once and only to the audience; a top-up never passes the plan's amount; one refill under two requests at once; refused when off, paused, cancelled, expired, over budget or over the uses per period; non-owners can't use one. pgTAP for RLS and the insert-only log |
| 2 | Admin routes, the preview, per-workspace actions, the log, `scripts/limit-resets.sh` | Server tests: every route refuses a non-owner; edits refused in the wrong state; undo leaves spent credits alone |
| 3 | App: the row, the sheet button, the confirm, Admin → Resets | Widget tests for each state |
| 4 | Notices, analytics events, docs (`docs-site`), `docs/COSTS.md`, `CHANGELOG.md`, the decision entry | Docs checked locally with `scripts/serve-web.py` |
| 5 | Ship: server deploy, docs deploy, app builds; then switch it on and send one reset to Oliver's own workspace as the first real check | Each deploy and build needs Oliver's yes |

The full suites run once at the end, through `scripts/heavy.sh`.

## 9. Not in this plan

- Resets people pay for, or earn (referrals, streaks).
- Giving them out through the admin bot (D-435). It can be added later as a proposed action the
  owner approves.
- A reset for everyone at once that refills without being saved first. A hand-out to every plan
  that starts now does the same job, with the person choosing when.
- Resets on self-hosted servers with billing off.

## Verification and release status

Implementation is complete locally. TypeScript typecheck, database-schema generation, API/client
generation, the docs build, full pgTAP, and the full Flutter analysis/test run passed (1,734 tests).
The final focused server run passed 12 tests, covering authorization, concurrency, budget locks,
undo, offsets, notification deduplication and CSV export. The final focused widget run passed 10 tests. Focused widget coverage includes member
and owner views, confirmation, the global switch and campaign lifecycle actions.

The full JavaScript suite found a Mousepad live-computer fixture failure (`note.txt` returned 404).
It also caught a notification-array encoding issue in this change; that issue was fixed and the
focused tests passed afterward. The Mousepad failure remains unresolved. No production deploy,
release build, store upload, feature activation or live workspace grant has been performed.
Those release actions still need Oliver’s explicit approval under AGENTS.md.

## Implementation notes

The cost preview uses the current `billing_settings.markup`. Actual billing already includes the
OpenRouter fee in both real cost and the marked-up charge, so the estimate is charged credits /
markup ($0.714 per $1 at 1.4), correcting the approximate figures in section 5. Actual usage costs
remain in `usage_ledger`. Audit CSV export streams the full filtered log; the app’s history view
loads the latest 1,000 rows. Regeneration fixes constant list defaults in the Dart generator.

## 10. Sources

How the originals work, read 2026-11-20: OpenAI,
[How banked Codex resets work](https://help.openai.com/en/articles/20001498-how-banked-codex-resets-work);
Anthropic, [About limit resets](https://support.claude.com/en/articles/17007452-about-limit-resets).
One thing taken from complaints about Codex: an expiry shown as a date with no time. Here it is
always shown to the minute, in the person's own time zone.
