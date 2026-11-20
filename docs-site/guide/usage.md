# Usage, budgets and plans

Casama tracks what every bot spends on models, cloud computers and other metered services. Use
this page to see where the money goes, cap what a bot can spend, and understand Casama Cloud plans
and credits. If you self-host, there are no plans or paywalls: you pay your providers directly and
set your own limits.

## See usage and cost

1. Open **Settings**. The **Usage** row shows this month's model spend.
2. Tap **Usage**.
3. Pick a period: **Today**, **This week**, **This month** or **This year**.

The numbers are fetched each time you open **Usage**. To fetch them again while it's open, tap the
refresh button at the top or pull down.

On Casama Cloud, a credits meter sits at the top (see [Credits](#credits)). The screen shows:

| Section | What it shows |
| --- | --- |
| **Spend**, **Runs** | Totals for the period, in dollars |
| **Spend by Day** | Spend per day (per month when you pick **This year**) |
| **By Bot** | Spend per bot. **Not tied to a bot** covers usage without one. |
| **By Model** | Spend per model. **Computers and other** covers non-model usage. |
| **By Source** | Spend and runs by where the work came from: **Chats**, **Chat apps**, **Routines**, **API and other agents**, or **Other** (usage not tied to a run) |
| **By Person** | Workspace admins only: spend and runs by who started the work. **Automatic** is work nobody started directly. |
| **Everything Metered** | Each metered kind, such as **AI models** (input and output together), **Cloud computer time**, **Live view** and **Read aloud** |

### Filter usage

Under the period, chips narrow every number on the screen:

- **All bots**: one bot (shown when the workspace has more than one).
- **All models**: one model (shown when more than one was used).
- **All sources**: chats, chat apps, routines, or the API.
- **Everyone**: **Just me**, or, for admins, any member who started work.

You can also tap a row under **By Bot**, **By Model**, **By Source** or **By Person** to filter to
it. Filters add up, for example one bot's routines on one model. Tap **Clear** to see everything
again. Exports and **Ask a Bot About This** use the filtered numbers and say what was filtered.

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

## See what each reply cost

To see what each answer costs while you chat, turn on **Settings > Show usage on replies**. It's off
by default and saved on each device.

With it on, a small line sits under the last message of every reply, for example
`$0.0420 · 18.2K tokens · 32s`. While the bot is working, the line counts up. It includes any
helper runs the bot started for that reply. Tap the line to see:

- what came out of your credits, and what your own keys or ChatGPT plan spent;
- tokens, how long the reply took, and how many steps the bot took;
- each metered item, such as model input and output for each model, cloud computer time and web
  searches.

**Open the run** from that sheet shows the reply's full timeline. Anyone who can see the chat can
see its costs. The same numbers come from `GET /v1/runs/{id}/usage`.

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
casama bot create "Anna" --credential <key-id> --run-budget 2 --daily-budget 20
```

Or pass `budget` (`per_run_usd`, `daily_usd`) when creating a bot through the [API](/develop/api).

A bot that manages other bots can set budgets for the bots it creates or edits, but never higher
than its own. When a bot hands work to a subagent, the subagent gets 20% of what the parent run
has left (at least one cent).

### Other limits on every run

| Limit | Value |
| --- | --- |
| Steps per run | 40 (8 for [check-ins](/guide/routines#check-ins)) |
| Time per run | 30 minutes |
| Repeated actions | See [the loop guard](/guide/autonomy#the-loop-guard) |

Projects have their own budget and deadline. See [Projects](/guide/projects). For every timeout,
call guardrail and workspace cap in one place, see [Limits](/guide/limits).

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
failed with a clear message and a stable code (for live calls, see
[When a live call ends for a limit](/guide/limits#when-a-live-call-ends-for-a-limit)):

| Code | Meaning |
| --- | --- |
| `budget_exceeded` | The run reached its per-run budget |
| `daily_budget_exceeded` | The bot reached its daily budget |
| `quota_exceeded` | The workspace reached its monthly spend limit |
| `out_of_credits` | A Casama Cloud workspace has no credits left |
| `cloud_daily_cap` | A Casama Cloud workspace reached its plan's [daily limit](#daily-limit). It resets at midnight UTC. |
| `computer_hours_exceeded` | A Casama Cloud workspace used its computer hours for the month, so its computer can't start. Chat keeps working on credits. |
| `plan_limit` | A Casama Cloud workspace is over a plan limit, such as how many computers can run |
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
- **Extra People** (Pro and Max, web subscriptions) sets how many people you pay for on top of the
  plan's own.
- The usage row shows what bots used this month and what it cost. Each charge, with the server it
  came from, is under **Advanced**.

Owners and admins can change plans and buy credits. Members see the plan and usage.

### Plans

| Plan | Price | Credits a month | Bots | Computers (running at once) | Computer hours a month | People | Library storage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Free** | $0 | $1 | 3 | 1 (1) | 5 | 1 | 1 GB |
| **Plus** | $15 a month or $150 a year | $5 | 10 | 2 (1) | 30 | 1 | 10 GB |
| **Pro** | $49 a month or $490 a year | $15 | Unlimited | 5 (2) | 100 | 3 | 50 GB |
| **Max** | $99 a month or $899 a year | $30 | Unlimited | 10 (2) | 300 | 10 | 200 GB |

Plus, Pro and Max can also be paid by the week ($7.99, $19.99 and $39.99). A weekly plan has the
same limits as the monthly one and gets a quarter of its credits each paid week; it has no free
trial, and extra people aren't sold on it.

Each plan also caps what its bots can spend on Casama's own model key in one day ($0.25 on Free,
$5 on Plus, $10 on Pro and $25 on Max). Bigger plans also get bigger computers: 1 vCPU and 1 GB of
memory on Free and Plus, 2 on Pro and 4 on Max. Plans can change, so **Billing** always shows the
current ones.

Library storage counts what bots keep in the [Library](/guide/library). With
[Casama Link](/guide/casama-link), Free and Plus connect one self-hosted server, Pro three and Max
ten, and live view away from home comes with Plus and up.

**Running at once:** starting another computer puts one nobody has used for 2 minutes to sleep. If
they're all in use, the start is refused until one is free.

**Pro trial:** Pro is free for 7 days, once per person, if you've never had a subscription. During
the trial the workspace gets $2 of credits and 10 computer hours; the first payment tops the month
up to $15.

**Once per person** means once per email inbox: accounts on the same inbox (such as
`you+work@gmail.com`, or Gmail with dots) share Free's $1 a month, the trial and invite rewards, and
deleting an account and signing up again doesn't start them over. Free's credits go to the first
free workspace of the inbox's first account.

A person is a member of the workspace. Free and Plus have one, the owner, so inviting someone
needs Pro or Max. On the web, Pro and Max can add more people at $12 a month each ($120 a year). One person can own up to five workspaces on Casama Cloud.

### Credits

Credits are dollars: 1 credit = $1. The credits meter at the top of **Usage** and on the **Billing**
plan card shows your balance (for example **Credits: $7.80**), a bar of how much of this month's
credits you've used, and roughly how many more runs that buys at your usual cost. The bar turns
amber at 80% and red when nothing is left.

**Credit History** on **Settings → Billing** shows where the balance came from: the latest credits
added or taken away other than usage, such as the monthly credits, a credit pack, an invite reward
or welcome bonus, a refund, or credits that expired. Each chat's cost is on **Usage**, not here.

Credits pay for everything Casama Cloud runs for you: AI models on Casama's key, cloud computer
time, live view, live calls, images and video, read-aloud and dictation, and apps connected
through Casama's own connector account. Usage is deducted from the balance every minute. Every run
on Casama Cloud needs credits, because even a short run can use some of these.

Credits belong to the workspace, not to a person. Most of them don't last forever:

| Credits | Last until |
| --- | --- |
| A month's included credits | The end of the following month |
| Credit packs bought on the web or in the desktop app, and rewards | 12 months |
| Credit packs bought in the App Store or Google Play | They never expire |

Credits that run out soonest are spent first. Only your oldest Free workspace gets Free's monthly
credits.

A run that fails because of Casama or a model provider doesn't cost model credits: its model usage
is waived, or refunded if it was already taken. Computer time is still charged, since the computer
ran. Runs that stop at a limit, loop, or that you stop yourself are charged as usual.

When a workspace's balance drops under $1 after recent use, its owners get a notification, at most
once a week.

### Daily limit

Each plan also has a daily limit on what Casama Cloud spends for you in a day: models on Casama's
key, live calls, images, read-aloud and apps. Computer time doesn't count here; it has its own
monthly hours.

| Plan | Daily limit |
| --- | --- |
| Free | $0.25 |
| Plus | $5 |
| Pro | $10 |
| Max | $25 |

The limit stops runs on its own, even with credits left. Under the credits meter, **Today's limit**
shows what's been spent today against it (for example **$0.10 of $0.25**) and when it resets. It
turns red when the limit is reached. The day resets at midnight UTC. To go past it, upgrade.

### Paywalls

When a workspace runs out of something its plan includes, the paywall opens on top of whatever
you were doing, with the reason (for example "Your plan allows 3 bots. Upgrade to add more.") and the paid plans side
by side. Close it to go back to where you were, such as a half-filled **New bot** sheet. Members
are asked to get an owner or admin to upgrade. This happens when:

- The credit balance is at or below zero. New runs are refused until you add credits or change
  plans.
- The workspace used its computer hours for the month and a bot needs its computer. Only the
  computer stops; chat keeps working on credits. **Usage** shows the hours under the credits.
- Creating another bot or computer, or adding another member, would go over the plan's limit.
- A bot's work hits another plan limit, such as the daily limit on Casama's models.

A paying workspace that runs out of credits gets a sheet of credit packs instead, with
**See Plans** under it.

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
as credits. You can earn rewards for up to 20 friends. The reward shows under **Free Usage Earned**
on the same screen, and as a line in **Credit History** on **Settings → Billing**. Tap the refresh
button at the top (or pull down) to see a new reward.

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
- Owners and admins can get each member's share of the cost (`by_person`) from `GET /v1/usage`, but
  the app doesn't show it yet.
- `casama usage` supports `day` and `month` only. Use the app for weeks and years.
- Usage costs are estimates, not invoices.
- Prices are in US dollars only.

## Related

- [Limits](/guide/limits)
- [Casama Link](/guide/casama-link)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [Projects](/guide/projects)
- [Workspaces and teams](/guide/workspaces)
- [Self-hosting configuration](/self-hosting/configuration)

## Saved resets

An administrator may give your workspace a one-time refill. See [Saved resets](/guide/saved-resets)
for using one, its expiry, and the instance-owner controls.
