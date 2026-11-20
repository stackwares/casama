# Moving from Grok Bot to Casama

This guide maps Grok Bot's ideas onto Casama's, and walks through moving your Bots. The quickest way
is to paste each Bot's setup into Casama: its name, instructions, schedules, skills and apps come over,
and you sign in to its apps again. You can also rebuild a Bot by hand.

Casama is not affiliated with xAI or Grok Bot. Grok Bot is a trademark of its owner.

## What maps to what

| In Grok Bot | In Casama | Read |
| --- | --- | --- |
| A Bot | A bot, with its own instructions, model, memory, skills, routines and computer | [Bots and models](/guide/bots) |
| One cloud computer shared by all your Bots | A sandboxed Linux computer for each bot | [Computers](/guide/computers) |
| Schedules and events | Routines: once, repeating, meetings, messages, GitHub or a webhook | [Routines and triggers](/guide/routines) |
| Templates and the template marketplace | The open gallery, plus Share as Template and Import a bot | [Templates, sharing and import](/guide/sharing) |
| Team Bots in Slack or Teams | Chat apps connected to a bot, and workspaces for the people | [Chat apps](/guide/chat-apps), [Workspaces and teams](/guide/workspaces) |
| A workflow you record once | Teach by showing: record it on the bot's computer and it becomes a skill | [Teach by showing](/guide/teach) |
| "Ask first" rules | A bot's autonomy level and action rules | [Autonomy and approvals](/guide/autonomy) |
| A weekly usage pool, then billing at token cost | Credits on Casama Cloud with a budget per run and per day, or your own model keys when self-hosted | [Usage, budgets and plans](/guide/usage) |

## Before you start

1. **Choose where Casama runs.** Casama Cloud has a free plan, and bots run on models Casama picks.
   On your own server you bring a model key and can use any provider, a ChatGPT plan or local models.
   See [self-hosting](/self-hosting/) and [pricing](https://casama.ai/pricing).
2. **Collect what each Bot has.** From Grok Bot, write down each Bot's instructions, its schedules, the
   apps it uses and the channels it answers in. If you shared a Bot as a template, you have its
   configuration in the template link.
3. **Remove secrets from what you copy.** Don't paste keys or passwords into instructions. Casama
   stores credentials separately, and they never travel inside a template.

## Paste a Bot's setup

1. In Casama, select **Add**, then **Import an Agent**, then **Paste a Bot's Setup**, and pick
   **Grok Bot**.
2. **Copy** the prompt and send it to your Grok Bot. It answers with its setup in a fixed format.
3. Paste the whole reply into Casama and select **Next**.
4. Review the name, instructions, routines, skills and memories, untick what you don't want, and
   import.

Schedules become routines. Events don't come over, and a note names the closest Casama trigger for
each one. Lines that look like keys or passwords are removed. See
[Paste a bot's setup](/guide/sharing#paste-a-bot-s-setup) for the format and what becomes what.

If your Bot doesn't answer in the format, paste its instructions from Grok Bot instead: they become
the new bot's instructions.

## Bots by hand

1. In the sidebar, select **Add**, then **New bot**.
2. Under **Persona**, pick a starting point or leave it on **Blank**, then paste the Grok Bot
   instructions into **Instructions**. The gallery has [starter bots](https://gallery.casama.ai/#bot)
   for common jobs.
3. Give it a name, and on a self-hosted server pick a model key and model under **Advanced**.
4. Set how often it asks before acting. New bots start on **Ask for risky actions**.

The main difference: every bot has its own computer. In Grok Bot, one computer and one set of files and
sign-ins is shared by all of a person's Bots. In Casama a bot's computer, files and sign-ins belong to
that bot, and you can watch it live and take over. Bots in a workspace that have no computer of their
own use the workspace's team computer, which is one per workspace. See [Computers](/guide/computers).

You can set a cost cap for each bot, per run and per day, in its profile. See
[Bots and models](/guide/bots#budgets-and-run-limits).

## Schedules and events become routines

Ask the bot in chat ("Every weekday at 9:00, summarize my inbox") and it creates the routine itself, or
open the bot's profile, then **Routines**, then **New routine**.

- A schedule becomes **Repeats**, or **Once** for a single time.
- An event becomes **Meetings** or **Messages**, or a webhook or GitHub trigger under **Advanced**.
- You can set a routine to end on a date or after some runs.

Casama doesn't promise a one-to-one match for every Grok Bot event type. Check each one against the
trigger list in [Routines and triggers](/guide/routines). The gallery has routine
[ideas](https://gallery.casama.ai/#routine), such as a morning plan or weekly review.

## Templates become the gallery

Grok Bot shares a Bot as a link that someone else adds as a copy. Casama does the same with
**Bot profile**, then **Advanced**, then **Share as Template**: save a file or copy a link, valid for
30 days. Recipients see what comes with it, then import it. Keys and sign-ins never come with a template.

To start from a ready-made bot, routine, skill or app instead, browse the
[gallery](https://gallery.casama.ai). The matching items for Grok Bot's templates are listed on
[Grok Bot templates and the Casama equivalents](https://casama.ai/compare/grok-bot-templates).

## Team Bots in Slack or Teams become chat apps

In Casama a chat app connects one bot to one messaging tool: Telegram, email, SMS, Slack, WhatsApp,
Messenger, Feishu, iMessage, Microsoft Teams or Discord.

1. Open the bot, then **Bot profile**, **Advanced**, **Chat apps**, **Connect a chat app**.
2. Choose Slack or Microsoft Teams, and paste the credentials from your Slack app or Azure bot. The
   chat app shows a webhook address to paste back into the tool.
3. Under **Allowed senders**, add the people who may talk to the bot. Until you do, it answers nobody.

You create the Slack or Teams app yourself, since Casama doesn't install one for you. Each thread becomes
one conversation that people on the workspace also see in the Casama app. For several people to share
a bot inside Casama, invite them to a [workspace](/guide/workspaces): by default everyone there can
chat with a bot, and you can make a bot private to chosen people. Roles are Owner, Admin and Member.
You can also put several bots in one [group chat](/guide/group-chats).

## Recorded workflows become teach

Grok Bot can learn a workflow from one recording. Casama can too, on a bot with a desktop computer:

1. Open the bot's computer, then **Open Live View**, then **Take Control**.
2. Open **More**, then **Teach a task**, and do the task once. Mark anything sensitive as a secret.
3. Tap **Stop**. The bot drafts a skill from your steps, and you review, save and try it.

You can also save the steps as a replay that runs without the model. See [Teach by showing](/guide/teach).

## A Bot's email address becomes a bot's email address

Grok Bot gives each account one address shared by all its Bots. Casama gives each bot its own:
open the bot, then **Bot profile** → **Email address**, and pick a name. Mail from you is a chat
message the bot answers; mail from strangers is kept but starts nothing. Plus addresses
(`ada+shop@`) give each job a lane, and routines can watch them. See
[A bot's email address](/guide/bot-email).

## What's different

- **Models.** On Casama Cloud, Casama chooses the model. On a self-hosted server you choose it, per bot.
- **Hosting.** Grok Bot runs only in xAI's cloud. Casama can run on your own server for free.
- **Spend.** Casama shows what each reply cost, and a run stops when it reaches its budget.
- **Maturity.** Casama is new and has a smaller community than Grok Bot.

## Next

- Prices side by side: [Grok Bot pricing](https://casama.ai/compare/grok-bot-pricing) and
  [Is Grok Bot free?](https://casama.ai/compare/is-grok-bot-free)
- The full comparison: [Casama vs Grok Bot](https://casama.ai/compare/casama-vs-grok-bot)
