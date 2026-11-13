# Usage, budgets and plans

Casama tracks what every bot spends on models, cloud computers and other metered services. Use
this page to see where the money goes, cap what a bot can spend, and understand Casama Cloud plans
and credits. If you self-host, there are no plans or paywalls: you pay your providers directly and
set your own limits.

## See usage and cost

1. Open **Settings**. The **Usage** row shows this month's model spend.
2. Tap **Usage**.
3. Pick a period: **Today**, **This week**, **This month** or **This year**.

On Casama Cloud, a credits meter sits at the top (see [Credits](#credits)). The screen shows:

| Section | What it shows |
| --- | --- |
| **Spend**, **Runs** | Totals for the period, in dollars |
| **Spend by Day** | Spend per day (per month when you pick **This year**) |
| **By Bot** | Spend per bot. **Not tied to a bot** covers usage without one. |
| **By Model** | Spend per model. **Computers and other** covers non-model usage. |
| **Everything Metered** | Each metered kind, such as **AI models** (input and output together), **Cloud computer time**, **Live view** and **Read aloud** |

To keep a copy, tap **Export CSV**. Token counts and **Export JSON** are under **Advanced**.

::: tip
Costs are estimates from token counts and published prices. Your model provider's bill is the
final word.
:::

From the CLI:

```sh
casama usage --period day    # or month (the default)
```

It prints the total and each bot's cost and tokens. For machine-readable output, put `--json`
before the command: `casama --json usage`.

## Ask a bot about your usage

1. On the **Usage** screen, tap **Ask a Bot About This**.
2. Under **Which bot should look at this?**, pick a bot.

Casama starts a new chat with that bot and sends a summary of the period. The bot can also check
live numbers itself: every bot has a read-only usage tool that reports the workspace's spend for a
day, week, month or year, by bot, model, day and metered kind. You can ask any bot "what did we
spend this week?" at any time.

## Bot budgets

Every bot has two spending limits:

| Limit | Default | What happens when it's reached |
| --- | --- | --- |
| Per run | $1 | The run stops with "This run reached its budget" |
| Per day | $10 | The bot's runs stop, and new ones are refused until the next day (midnight UTC) |

Set them when you create a bot with the CLI:

```sh
casama bot create "Ada" --credential <key-id> --run-budget 2 --daily-budget 20
```

Or pass `budget` (`per_run_usd`, `daily_usd`) when creating a bot through the [API](/develop/api).

A bot that manages other bots can set budgets for the bots it creates or edits, but never higher
than its own. When a bot hands work to a subagent, the subagent gets 20% of what the parent run
has left (at least one cent).

### Other limits on every run

| Limit | Value |
| --- | --- |
| Steps per run | 40 |
| Time per run | 30 minutes |
| Repeated actions | See [the loop guard](/guide/autonomy#the-loop-guard) |

Projects have their own budget and deadline. See [Projects](/guide/projects).

## Workspace quotas

On a self-hosted server, the instance owner can cap each workspace in the admin console:

1. Open **Settings → Admin console → Workspaces**.
2. Find the workspace and tap **Edit quotas**.
3. Set **Max bots** and **Monthly spend limit (USD)**. Leave a field empty for no limit.
4. Tap **Save**.

The monthly limit counts the workspace's spend since the start of the calendar month (UTC). See
[Workspaces and teams](/guide/workspaces#the-admin-console).

## When a run hits a limit

Limits are checked when a run starts and before every model step. A run that hits one ends as
failed with a clear message and a stable code:

| Code | Meaning |
| --- | --- |
| `budget_exceeded` | The run reached its per-run budget |
| `daily_budget_exceeded` | The bot reached its daily budget |
| `quota_exceeded` | The workspace reached its monthly spend limit |
| `out_of_credits` | A Casama Cloud workspace has no credits left |
| `computer_hours_exceeded` | A Casama Cloud workspace used its computer hours for the month |
| `max_steps_exceeded` | The run used all its steps |
| `wall_time_exceeded` | The run ran out of time |
| `stuck_looping` | The bot kept failing the same way and stopped |
| `no_model_configured` | The bot has no model. Add a model key and pick a model in **Bot profile**. |

## Casama Cloud plans and credits

On Casama Cloud, each workspace has a plan. Open **Settings → Billing** to see it.

- **Your plan** shows the plan, how it's billed (**Billed on the web**, **Billed through the App
  Store** or **Billed through Google Play**), when it renews or ends, your **Credits** balance and
  the credits meter.
- **Plans** lists what each plan includes: a number of bots, computer hours a month and credits a
  month.
- **Credits** (paid plans only) lists the credit packs you can buy.
- The usage row shows what bots used this month and what it cost. Each charge, with the server it
  came from, is under **Advanced**.

Owners and admins can change plans and buy credits. Members see the plan and usage.

### Plans

| Plan | Price | Credits a month | Bots | Computers | Computer hours a month | Seats |
| --- | --- | --- | --- | --- | --- | --- |
| **Free** | $0 | $1 | 2 | 1 | 5 | 1 |
| **Plus** | $15 a month or $150 a year | $5 | 5 | 2 | 30 | 2 |
| **Pro** | $39 a month or $390 a year | $10 | 20 | 5 | 100 | 5 |
| **Max** | $149 a month or $1,490 a year | $50 | 50 | 10 | 400 | 10 |

Yearly plans cost ten months' price. Each plan also caps what its bots can spend on Casama's own
model key in one day. Plans can change, so **Billing** always shows the current ones.

A seat is a member of the workspace. Free has one seat, the owner, so inviting someone needs a paid
plan. One person can own up to five workspaces on Casama Cloud.

### Credits

Credits are dollars: 1 credit = $1. The credits meter at the top of **Usage** and on the **Billing**
plan card shows your balance (for example **Credits: $7.80**), a bar of how much of this month's
credits you've used, and roughly how many more runs that buys at your usual cost. The bar turns
amber at 80% and red when nothing is left.

Credits pay for everything Casama Cloud runs for you: AI models on Casama's key, cloud computer
time, live view, live calls, images and video, read-aloud and dictation, and apps connected
through Casama's own connector account. Usage is deducted from the balance every minute. Every run
on Casama Cloud needs credits, because even a short run can use some of these.

Credits belong to the workspace, not to a person, and they don't last forever:

| Credits | Last until |
| --- | --- |
| A month's included credits | The end of the following month |
| Credit packs and rewards | 12 months |

Credits that run out soonest are spent first. Only your oldest Free workspace gets Free's monthly
credits.

### Paywalls

When a workspace runs out of something its plan includes, the paywall opens on top of whatever
you were doing, with the reason (for example "Your plan allows 2 bots.") and the paid plans side
by side. Close it to go back to where you were, such as a half-filled **New bot** sheet. Members
are asked to get an owner or admin to upgrade. This happens when:

- The credit balance is at or below zero. New runs are refused until you add credits or change
  plans.
- The workspace used its computer hours for the month.
- Creating another bot or computer, or adding another member, would go over the plan's limit.

On the Free plan, **Billing** also shows an **Upgrade to Pro** banner that opens the paywall.

### Where you can buy

| Where you use the app | Subscriptions | Credit packs |
| --- | --- | --- |
| iPhone, iPad and the Mac App Store app | In-app purchase. In the US, a web checkout link too. | In-app purchase |
| Android | Google Play | Google Play |
| Web, Windows, Linux and the Mac app from the web | Web checkout | Web checkout |

Credit packs come in $10 and $25 of credits, for workspaces on a paid plan. On the web they cost
their face value. In the App Store and Google Play they cost a little more, because the stores keep
a share.

To manage or cancel a subscription, tap **Manage Subscription**. If you bought on a phone and
reinstalled, tap **Restore Purchases**. Cancelling a store subscription keeps access until the end
of the paid period; a refund ends it.

### Invite friends

On Casama Cloud, everyone has a personal invite code and link under **Settings → Invite Friends**.
When a friend signs up with your code and finishes their first chat, you each get $2 of free usage
as credits. You can earn rewards for up to 20 friends.

A friend who signed up without your link can still enter your code under **Got a Friend's
Code?**, within a week of signing up. Self-hosted servers don't show invites.

## Self-hosting: no paywall

Billing is off on a self-hosted server unless you turn it on. **Settings → Billing** is hidden,
and the workspace has no plan limits. If you open the billing screen anyway, it says **Billing is
off on this server. Self-hosted Casama has no limits.** Bot budgets and any quotas the instance
owner sets still apply.

## Limits

- The app doesn't edit bot budgets yet. Set them at creation with the CLI or API, or ask a bot that
  manages bots to lower them. Changing an existing bot's budget isn't available in the app or the
  CLI.
- `casama usage` supports `day` and `month` only. Use the app for weeks and years.
- Usage costs are estimates, not invoices.
- Prices are in US dollars only.

## Related

- [Cloud Connect](/guide/cloud-connect)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [Projects](/guide/projects)
- [Workspaces and teams](/guide/workspaces)
- [Self-hosting configuration](/self-hosting/configuration)
