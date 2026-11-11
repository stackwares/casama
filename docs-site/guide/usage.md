# Usage, budgets and plans

Casama tracks what every bot spends on models, cloud computers and other metered services. Use
this page to see where the money goes, cap what a bot can spend, and understand Casama Cloud plans
and credits. If you self-host, there are no plans or paywalls: you pay your providers directly and
set your own limits.

## See usage and cost

1. Open **Settings**. The **Usage** row shows this month's model spend.
2. Tap **Usage**.
3. Pick a period: **Today**, **This week**, **This month** or **This year**.

The screen shows:

| Section | What it shows |
| --- | --- |
| **Spend**, **Tokens in**, **Tokens out**, **Runs** | Totals for the period |
| **Spend by day** | Spend per day (per month when you pick **This year**) |
| **By bot** | Spend per bot. **Not tied to a bot** covers usage without one. |
| **By model** | Spend per model. **Computers and other** covers non-model usage. |
| **Everything metered** | Each metered kind: **Model input**, **Model output**, **Cloud computer time**, **Live view** and **Read aloud** |

To keep a copy, tap **Export CSV** or **Export JSON**.

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

1. On the **Usage** screen, tap **Ask a bot about this**.
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
| `no_model_configured` | The bot has no model. Add a model key and pick a model in **Bot settings**. |

## Casama Cloud plans and credits

On Casama Cloud, each workspace has a plan. Open **Settings → Billing** to see it.

- **Your plan** shows the plan, how it's billed (**Billed on the web**, **Billed through the App
  Store** or **Billed through Google Play**), when it renews or ends, and your **Credits**
  balance.
- **Plans** lists what each plan includes: a number of bots, computer hours a month and credits a
  month.
- **This month** lists billable usage: cloud computers, live view and model credits.

Owners and admins can change plans and buy credits. Members see the plan and usage.

### What credits pay for

Credits pay for what Casama Cloud provides: cloud computer time, live view time, and model calls
through [Cloud Connect](/guide/cloud-connect). Usage is deducted from the balance every minute.
Model calls on your own model keys are never charged; you pay your provider directly.

Each plan adds its included credits once a month. Purchases and credits belong to the workspace,
not to a person.

### Paywalls

When a workspace runs out of something its plan includes, the app shows **Upgrade your plan**
with a short reason. Tap **See plans** to open **Billing**, or **Not now**. This happens when:

- The credit balance is at or below zero. New runs are refused until you add credits or change
  plans.
- The workspace used its computer hours for the month.
- Creating another bot or computer would go over the plan's limit.

### Where you can buy

| Where you use the app | Subscriptions | Credit packs |
| --- | --- | --- |
| iPhone, iPad and the Mac App Store app | In-app purchase. In the US, a web checkout link too. | Not sold here |
| Android | Google Play | Not sold here |
| Web, Windows, Linux and the Mac app from the web | Web checkout | Web checkout |

To manage or cancel a subscription, tap **Manage subscription**. If you bought on a phone and
reinstalled, tap **Restore purchases**. Cancelling a store subscription keeps access until the end
of the paid period; a refund ends it.

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

## Related

- [Cloud Connect](/guide/cloud-connect)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [Projects](/guide/projects)
- [Workspaces and teams](/guide/workspaces)
- [Self-hosting configuration](/self-hosting/configuration)
