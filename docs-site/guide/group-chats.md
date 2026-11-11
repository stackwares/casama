# Group chats

A group chat puts several bots in one conversation with you, so they can split a job and build on
each other's work. Use one when a task needs more than one specialist, like a researcher, a writer
and a designer working on the same launch.

## Create a group chat

You need at least two bots in the workspace.

1. In the sidebar, select **Add** (the **+** button), then **New group chat**.
2. Optional: give it a **Name**. Without one, the chat is named after its bots.
3. Under **Bots**, pick 2 to 10 bots. The first one you pick **Leads the group**.
4. Select **Create**.

Group chats are listed under **Group chats** in the sidebar, each with its number of bots.

## Choose who answers

Who answers depends on how you address the message. As you type `@`, the app suggests the group's
bots and `everyone`, and a line above the field says who will answer.

| You write | Who answers |
| --- | --- |
| `@Ana find three examples` | Ana. Mention several bots to wake each of them. |
| `@everyone plan the launch post` | The lead. It makes a plan that @mentions a bot for each part, and those bots start on their parts. |
| No mention | The last bot that spoke, or the lead if no bot has spoken yet. |

Every bot you wake works at the same time, in the same chat. Each reply is headed with the name of
the bot that wrote it. Attachments and skills picked with `/` work as in any chat; see
[Chatting with a bot](/guide/chat).

## Bots talking to bots

When a bot's reply @mentions another bot in the group, that bot starts working too. This lets the
lead hand out parts of a plan, or one bot ask another for help.

To stop loops, a chain of bot-to-bot mentions stops after 6 hops for each message you send. Then
the chat waits for a person.

Bots treat each other's messages as chat, not as instructions from you. Each message from another
bot reaches a bot labeled with who said it and that it didn't come from you.

### Turn bot-to-bot messages off

Owners and admins can stop bots from messaging each other across the whole workspace.

1. Go to **Settings** → **Workspace settings**.
2. Turn off **Bots can talk to each other**.

With the switch off:

- A bot's @mentions of other bots in a group chat start no work. The chat shows a short note
  naming the bots that weren't told.
- `@everyone` still reaches the lead, which can plan, but the bots it names aren't woken.
- People can still @mention any bot, and each bot can still split its own work into subagents.
- Bots can't hand work to each other with delegation either. See
  [Bots working together](/guide/bots-together).

Changes to the switch are recorded in the workspace's audit log.

## What each bot keeps

A group chat doesn't merge the bots. Each one keeps its own:

- instructions, model and computer
- memory (what it learns in the group goes to its own memory)
- autonomy, action rules and approvals
- budget, so one bot's spending never uses another's

## Who can see a group chat

You see a group chat only if you can see every bot in it. If one of its bots is private and you're
not on its sharing list, the whole group chat is hidden from you. See
[Templates, sharing and import](/guide/sharing).

## Limits

- You can't add or remove bots after creating a group chat. Create a new one instead.
- Up to 10 bots per group chat.
- Edit and resend isn't available in group chats; messages are kept in one line.
- A message you send while bots are working doesn't join their runs. It starts new work for the
  bots it wakes.
- Runs in group chats don't feed skill suggestions. See [Skills](/guide/skills).

## Related

- [Chatting with a bot](/guide/chat)
- [Bots working together](/guide/bots-together)
- [Bots and models](/guide/bots)
- [Autonomy and approvals](/guide/autonomy)
