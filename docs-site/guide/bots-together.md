# Bots working together

Bots can split up work, hand tasks to each other, manage other bots, and talk to bots outside your
workspace. Use this when one job is too big for one context, when a specialist bot should take
part of it, or when your bot needs something from a contact's bot.

## Subagents

A bot can start a subagent: a short-lived copy of itself with a fresh context, for a
self-contained task such as researching one question. The subagent returns a summary, and the
parent bot carries on.

- **Budget:** 20% of what the parent run has left, unless the bot asks for less.
- **Time limit:** 10 minutes by default, up to an hour.
- **Tools:** the same as the parent's, or fewer if the bot narrows them.

Subagents show on the parent run's timeline, with their status and summary.

## Hand a task to another bot

A bot can delegate a task to another bot in your workspace by name, then wait for its result. For
example, a planner bot can ask a writer bot for a draft.

- The task appears in the other bot's chats as a new conversation titled "Task from" and the
  delegating bot's name.
- The other bot works under its own settings and approvals, with a budget taken from the delegating
  run, as with subagents.
- Delegation can go at most 3 levels deep. A bot can't hand a task back to a bot that's already
  working on the same chain, so loops are refused.

In a group chat, bots can also @mention each other. See [Group chats](/guide/group-chats).

## Turn off bot-to-bot messages

Owners and admins can stop bots from talking to each other.

1. Open **Settings** → **Workspace settings**.
2. Turn off **Bots can talk to each other**.

When it's off:

- A bot's @mentions of other bots in a group chat start nothing. The chat shows an info line naming
  the bots that weren't told.
- Delegating to another bot fails, and the failure shows on the timeline.
- Subagents still work, and people can still @mention bots.

The switch is on by default, and changes are recorded in the audit log.

## Bots that manage bots

A bot can list, create, update and archive bots, and organize the sidebar into folders. It can also
manage another bot's routines.

| Action                       | Risk                                         |
| ---------------------------- | -------------------------------------------- |
| List bots                    | Read-only                                    |
| Organize folders             | Low                                          |
| Update a bot                 | Medium; high when it changes autonomy or budget |
| Create a bot                 | High                                         |
| Archive a bot                | High (a bot can't archive itself)            |

High-risk actions ask first under the default autonomy. See [Autonomy and approvals](/guide/autonomy).

A bot can never give any bot, itself included, more than it has:

- No higher autonomy level than its own.
- No larger per-run or daily budget than its own.
- No more tools. A new bot starts with no connections unless the creating bot copies its own.

A new bot copies the creating bot's model settings, belongs to the person the bot is working for,
and counts toward the workspace's bot limit. Every action is in the audit log.

### Undo a change

Every change to a bot's settings is kept, with who made it: a person or a bot.

1. Open **Bot profile** → **Settings history**.
2. Find the change and tap **Restore**, then confirm.

The current settings stay in the history, so you can undo the restore too.

### Folders and archived bots

- **Bot profile** → **Folder** moves a bot into a folder in the sidebar.
- **Bot profile** → **Archive Bot** hides a bot from the sidebar. Archived bots can't run and don't
  count toward the bot limit.
- To restore one, open **Archived bots** from the bot list and tap **Bring back**.

## Linked bots

Link your bot with a trusted contact's bot, so they can ask each other for things, like finding a
dinner slot. Each bot answers under its own person's rules and shares only what the request needs.
Both of you see every exchange.

### Link two bots

1. Open **Bot profile** → **Linked bots** and tap **Invite a contact**.
2. Enter your **Contact's name**, the name your bot will use for them.
3. Copy the invite and send it to your contact. It works once, for 7 days.
4. Your contact opens **Linked bots** on one of their bots, taps **Accept an invite**, pastes it and
   enters your name.

Until then the link shows "Waiting for your contact to accept". Inviting and accepting are the two
approvals: nobody is linked without both. Your contact can be on the same Casama server or a
different one.

### How asking works

- Your bot sends a request to the linked bot by the contact's name. Sending is a medium-risk action
  in the send category, so it follows your bot's approval rules.
- The other bot receives it as a request from your bot on your behalf. It runs as its owner, with
  their approvals, rules and budgets, so it may wait for its person to approve.
- On the same server, your bot waits up to 5 minutes for the answer.
- Every exchange is listed under **Exchanges** on both sides, and the receiving person gets a
  notification. Each of you sees only your own side.

To end a link, tap **Unlink**. It ends for both of you, on both servers.

## Agent-to-agent (A2A)

A2A is an open protocol for AI agents to give each other tasks. Casama speaks A2A 1.0 in both
directions.

### Let outside agents use a bot

1. An owner or admin opens **Settings** → **Workspace settings** and turns on
   **Agent-to-agent (A2A)**. It's off by default.
2. Someone who manages the bot opens **Bot profile** → **Publish as an A2A agent** and turns it
   on.
3. Copy the **Agent card** address and give it to whoever runs the outside agent.
4. The outside agent also needs a workspace API key, created under **Connect AI apps** in
   workspace settings. See [MCP server](/guide/mcp).

The outside agent acts as the person who owns the API key, and that person must be able to use the
bot. Each task becomes a run with the bot's usual approvals, budgets and rules, and is recorded in
the audit log. Sending the same context again continues the same conversation. If a task is waiting
for an approval, the outside agent sees it as still working.

Turning the workspace switch off unpublishes every bot.

### Give a bot an outside agent

1. Open **Settings** → **Integrations** → **Custom server**.
2. Set **Type** to **AI agent (A2A)**.
3. Enter a **Name**, the **Agent address or agent card URL**, and an optional **Access token**.
4. Tap **Save**, then give it to the bot under **Integrations for this bot**.

The bot gets one tool for that agent, described from the agent's card. It waits up to 10 minutes
for the task to finish, then returns the answer, or says the agent needs more input. Calling an
outside agent is a medium-risk action.

For the protocol details, see [Agent-to-agent (A2A)](/develop/a2a).

## Limits

- A2A streaming and push notifications aren't offered yet. Outside agents wait for a reply, or poll
  for a long task.
- A bot can't grant another bot more autonomy, budget or tools than it has, even with your approval.

## Related

- [Group chats](/guide/group-chats)
- [Autonomy and approvals](/guide/autonomy)
- [Apps and connections](/guide/connections)
- [Agent-to-agent (A2A)](/develop/a2a)
- [Sharing bots](/guide/sharing)
