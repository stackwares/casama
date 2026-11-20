# Saved resets through the admin bot: plan

Status: **built and live 2026-11-20 (D-445, server and docs at 14281b6d)**. Oliver asked whether admin-owned bots can use
tools for saved resets; they couldn't. I proposed read tools plus approved writes, and he said "Yes
do that all now plan and build right away then commit push deploy".

Builds on `docs/ADMIN-BOT-PLAN.md` (D-435, the admin bot) and `docs/LIMIT-RESETS-PLAN.md` (D-443,
saved resets).

## 0. Summary

The admin bot gets tools for saved resets. It follows D-435's rule unchanged: **the bot only
proposes; the instance owner approves every change**, in the app, one card at a time.

- **Reads** run without asking: the feature's settings and every campaign with its counts, one
  workspace's resets and history, the log, and a preview of who a hand-out reaches and what it
  could cost.
- **Changes** each show the owner an approval card first: switch the feature and its limits,
  create a campaign, edit one, schedule, pause, resume, cancel or delete one, give one workspace a
  reset, take back an unused reset, undo a used one.

Nothing else changes: the saved-reset admin routes still refuse bots and tools, and the app's
Admin → Resets and `scripts/limit-resets.sh` stay the other two ways in.

## 1. Who and where

Exactly D-435's gate, re-checked from the database on every call:

- The admin-bot switch is on, and this is the chosen bot.
- The run is the owner's own in-app direct chat: no routine, task, voice call, chat app, group or
  sub-run.
- The sender is on the explicit `INSTANCE_ADMIN_EMAILS` list with a confirmed email, and only
  listed owners are in the bot's workspace.
- A change runs only with an approval decided by a listed owner in the last 15 minutes, never an
  "always allow". At most 60 admin-bot changes an hour across the instance.

A prompt-injected bot can at most show the owner a card to decline.

## 2. The tools

| Tool | Kind | What it does |
|---|---|---|
| `admin.resets.status` | Read | Settings (on or off, uses per period, most held, owner notices) and campaigns: state, dates, audience size, given, used, expired, refilled, budget |
| `admin.resets.workspace` | Read | One workspace's resets (held, used, taken back) and their history |
| `admin.resets.log` | Read | The log, by campaign or workspace, newest first (up to 50) |
| `admin.resets.preview` | Read | How many workspaces a hand-out reaches, by plan, and the worst-case credits and real cost |
| `admin.resets.settings` | Change | Switch saved resets on or off; set uses per period, most held, owner notices |
| `admin.resets.create` | Change | A campaign: audience, start, expiry, refill, caps, notices, and a **required total budget**; a draft unless it says to schedule |
| `admin.resets.update` | Change | Change a campaign's fields; after launch only the text, expiry, budget and reminder |
| `admin.resets.campaign` | Change | Schedule, pause, resume, cancel or delete (drafts only) a campaign |
| `admin.resets.give` | Change | A one-off reset for one workspace (refused while the feature is off) |
| `admin.resets.take_back` | Change | Take back an unused reset, or undo a used one's unspent credits |

Decisions:

- **A budget is required when the bot creates a campaign.** The app and the script allow none; a
  campaign the bot proposes always shows its most total cost on the card. The owner can set any
  amount.
- **The same rules as the app.** Every change goes through the same saved-reset service, so states,
  fixed fields after launch, the per-period and held limits and the log behave identically.
- **Two records.** The saved-reset log names the approving owner as the actor, like a change made
  in the app; `audit_log` also gets an `admin_bot.resets.*` row with the run and call, like every
  admin-bot change.
- **Untrusted text.** Workspace names and log entries come back marked as data, never instructions.
- **Cancel, take back and undo** are shown as destructive cards.

## 3. Tests

`apps/server/test/admin-bot-resets.test.ts`, through the real run loop and the worker's own
database role, like D-435's tests:

- Reads run without a card; their results arrive.
- A change with the owner's fresh yes happens and is logged in both places, with the owner as actor.
- No yes, someone else's yes, a stale yes or an "always allow": nothing changes.
- Outside the admin chat (a routine, a group chat, another bot): no card, nothing changes.
- Create without a budget is refused before any card.
- Give while switched off is refused; take back works.

## 4. Not in this plan

- Redeeming resets through a bot: workspace owners use them in the app.
- Bots other than the admin bot.
