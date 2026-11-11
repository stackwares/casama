# Autonomy, approvals and action rules

Every bot decides for itself when to act and when to check with you first. You control that
with three things: the bot's **autonomy** level, the **risk** of each tool, and **action rules**
for specific kinds of actions. Use this page to choose how much a bot may do on its own and to
understand exactly when it will stop and ask.

## Choose a bot's autonomy

1. Open the bot's chat and tap its name at the top (or open the menu and choose **Bot settings**).
2. Under **Autonomy**, pick a level.
3. Tap **Save changes**.

| Level in the app | Value in the API and CLI | The bot asks before |
| --- | --- | --- |
| **Ask before acting** | `ask_always` | Every action that changes something |
| **Ask for risky actions** (default) | `ask_risky` | High-risk actions, medium-risk actions after it has read untrusted content, and tools that always confirm |
| **Act on its own** | `autonomous` | Nothing, except high-risk actions on your own computer |

Under every level, a bot never asks for built-in tools that only look at things (reading,
listing, searching, taking screenshots) or for the [self-only actions](#actions-that-never-ask)
below. Tools from connected apps marked **Read-only** still ask under **Ask before acting**.

With the CLI, set the level when you create a bot:

```sh
casama bot create "Ada" --credential <key-id> --autonomy ask_always
```

A bot that manages other bots can change autonomy too, but it can never give any bot, itself
included, more autonomy than it has.

## How risk is decided

Each tool has a risk level: low, medium or high. Some tools work out their risk from the
arguments. For example, a shell command is low risk inside the bot's workspace folder, and high
risk when it deletes things outside it.

Tools from apps you connect get a level per tool. On the connection's page you can set each
tool to **Read-only**, **Makes changes** or **Always asks**, which map to low, medium and high
risk. See [Connections](/guide/connections).

A few tools ask under **Ask for risky actions** whatever their risk, because they change your
own things or cost money: image and video generation, changes to your calendar, and buying a
call to a paid data service.

## Approvals

When a bot needs your OK, the run pauses and an approval request appears in two places:

- The chat, as a card under the bot's message.
- **Inbox → Approvals**, for every bot you can use. The tab shows a count when something is
  waiting.

Each request shows the bot, the tool, its risk (**Low risk**, **Medium risk** or **High risk**)
and the arguments it wants to use, with secrets removed.

To answer it:

1. Open the card in the chat, or go to **Inbox → Approvals**.
2. Read what the bot wants to do.
3. Tap **Approve**, **Deny** or **Always allow**.

| Choice | What happens |
| --- | --- |
| **Approve** | The step runs and the bot carries on. |
| **Deny** | Only that step fails. The bot is told, and it continues without it. |
| **Always allow** | The step runs, and Casama adds an action rule so this bot runs this tool without asking from now on. |
| No answer for 24 hours | The request expires and is treated like a deny. |

A run that waits for approval costs nothing while it waits, and it survives server restarts.
Anyone who can use the bot can answer. If someone already answered, you see **This request was
already decided or has expired.**

### Push notifications for approvals

The person who started the run and the bot's owner both get a push notification. Approvals from
a chat or voice call come through even during quiet hours, because someone is waiting in the
conversation. Approvals from routines and other background work wait until your quiet hours
end. See [Notifications and attention](/guide/attention).

You can also approve or deny from an AI app connected over MCP, if your workspace allows it. See
[Connect AI apps to Casama](/guide/mcp).

## Action rules

Action rules decide per action instead of per bot. Use them when one autonomy level doesn't fit,
for example "send email to my own company without asking, but always ask before emailing anyone
else."

### Add a rule

1. Open **Bot settings → Action rules**.
2. Tap **Add a rule**.
3. Under **When the bot is**, pick a category: **Sending messages**, **Payments**, **Deleting**,
   **Publishing**, **Sharing and invites** or **Signing in**.
4. Under **It should**, pick a behavior.
5. Optionally limit it with **Only to these domains (comma separated)** or **Up to this amount**.
6. Turn on **For every bot in the workspace** to make it a workspace rule.
7. Tap **Save**.

| Behavior | What it does |
| --- | --- |
| **Go ahead** | Runs without asking, whatever the autonomy. |
| **Go ahead within limits** | Runs without asking only when every recipient is in an allowed domain (subdomains count) and the amount is under the limit. Outside the limits, the rule doesn't apply. Needs at least one limit. |
| **Ask me first** | Always asks, even under **Act on its own**. |
| **Hand it to me to finish** | The bot never does the step itself. It prepares everything and asks you to finish, taking over its computer screen if it's working there. |

Each rule shows a plain-language summary, such as "Sends messages to anyone at example.com
without asking". The list groups rules by category, with tool rules (from **Always allow**)
under **Specific tools**.

### Who can change rules

- Workspace rules need a workspace owner or admin.
- A bot's own rules need someone who manages that bot.
- Bots can't create, change or delete rules, including bots that manage other bots.

Deleting a rule is recorded in the workspace's audit log.

### Which rule wins

1. Casama finds the rules that match the call: by exact tool, by tool group (for example every
   tool from one connected app), or by category.
2. A rule with limits only matches when the call is within them.
3. The most specific rule wins: the bot's own rule over a workspace rule, then tool over group
   over category, then a rule with limits over one without.
4. On a tie, **Ask me first** or **Hand it to me to finish** wins.
5. If no rule matches, the bot's autonomy decides.

Categories come from the tool's own declaration, or from words in its name (for example
`send`, `email`, `pay`, `delete`, `publish`, `share`, `password`). Recipients and amounts are
read from argument fields such as `to`, `cc`, `recipients` and `amount`.

Rules by exact tool or tool group, and limits by exact recipient, can be created through the
API. See [API](/develop/api).

## Actions that never ask

Some actions change only the bot's own state inside Casama, where you can see and undo them.
These never ask for approval under any autonomy level, including **Ask before acting**:

- Its notes (memory) and its own routines. What a routine then does still goes through
  approvals.
- Messages, notifications and cards for you.
- Board tickets, comments and suggestions.
- Housekeeping: loading a skill, making a checkpoint, organizing the sidebar.

Anything that reaches outside Casama or costs money still follows the normal rules: sending
through chat apps or email, web requests, the shell, browsing, payments, publishing or sharing
pages, calls, and creating, archiving or rewriting bots. An **Ask me first** rule still wins over
a self-only action.

## Actions that always ask or always go to you

| Action | Rule |
| --- | --- |
| Paying with a virtual card | Always asks, whatever the autonomy or rules. **Always allow** doesn't apply. See [Payments](/guide/payments). |
| Changing a password or two-step settings | Always handed to you to finish. A rule can't change this. |
| High-risk actions on your own computer | Always ask, even under **Act on its own**. See [Your own computer](/guide/companion). |

## Untrusted content

Web pages, emails, files and output from connected apps can contain text written to trick a bot.
Casama protects against this in three ways:

- Untrusted content reaches the model inside labeled blocks, and the bot is told never to follow
  instructions found inside them.
- Under **Ask for risky actions**, once a run has read untrusted content, medium-risk actions ask
  for approval until you approve something again.
- Secrets never reach the model. Bots use placeholders such as `{{secret:NAME}}`, and Casama fills
  in the value only when the request goes to a host the secret allows. See
  [Privacy and security](/guide/privacy).

## The loop guard

A bot that keeps retrying the same thing wastes your budget. On top of the step, time and budget
limits, each run has a loop guard:

- The same action with the same arguments a third time in one run isn't run. The bot is told it
  already tried twice and to change approach or say what's blocking it. Looking-only actions
  (reads, lists, searches, snapshots, screenshots) are exempt, since they repeat normally.
- Five failed steps in a row (errors, refusals or skipped repeats) end the run. You see a message
  that the bot kept hitting the same problem and stopped to save your budget.

## Checkpoints as a safety net

Before a shell command that deletes data (such as `rm -rf`, `git reset --hard` or uninstalling
packages), Casama saves a checkpoint of the bot's computer. Bots can also make checkpoints
themselves before risky work. Restoring a checkpoint puts the computer's files back as they were.
See [Computers](/guide/computers).

## Limits

- The app adds action rules by category only. Rules for a specific tool come from **Always
  allow**; rules for a tool group or exact recipients need the API.
- Approvals can't be answered from the CLI. Use the app, or an AI app connected over MCP.
- Checkpoints are automatic only before destructive shell commands, not before every high-risk
  action.

## Related

- [Bots](/guide/bots)
- [Notifications and attention](/guide/attention)
- [Usage, budgets and plans](/guide/usage)
- [Computers](/guide/computers)
- [Connections](/guide/connections)
