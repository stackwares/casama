# Bots and models

A bot is an AI teammate with its own instructions, model, memory, skills, routines and computer.
Create one bot for each kind of job you hand out, such as an inbox assistant, a researcher or a
coder, and give each the model and limits that fit the work.

## What a bot has

| Part | What it is |
| --- | --- |
| Name and icon | A cloud mascot or initials, shown in the sidebar and on every reply. |
| Instructions | Standing instructions (its system prompt): its role, how it works, its style and limits. |
| Model | A model key from your workspace plus a model id. A bot can also have fallback models and a cheaper model for internal steps. On Casama Cloud, Casama chooses the model and you don't need a key. |
| Autonomy | How often it asks before acting. See [Autonomy and approvals](/guide/autonomy). |
| Budget | A cost cap per run and per day. See [Budgets and run limits](#budgets-and-run-limits). |
| Computer | Where it runs commands, browses and keeps files. See [Computers](/guide/computers). |
| Memory, skills, routines | What it remembers, the instructions it can load, and work it does on its own later. |

## Create a bot

On Casama Cloud, bots run on Casama's own models, so there's nothing to set up first. On a
self-hosted server you need a model key; if your workspace has none, the **New bot** sheet shows
the add-key form in place.

1. In the sidebar, select **Add** (the **+** button), then **New bot**.
2. Under **Persona**, tap one of the quick picks, or **Browse all** to see every persona (see
   [Personas and starter bots](#personas-and-starter-bots)). Leave it on **Blank** to start from
   scratch. The card under the picks shows the persona and holds its **Instructions**; edit them
   as you like.
3. Under **Name and icon**, enter a **Bot name** and pick a cloud mascot or **Initials**. If you
   leave the name empty, the bot is named Chief.
4. Self-hosted only: the model key and model Casama picked for you are under **Advanced**. Change
   them there if you like.
5. Select **Create**. The bot's chat opens, ready for your first message.

New bots start with **Ask for risky actions** autonomy (unless a persona sets another level), are
visible to everyone in the workspace, and get a budget of $1 per run and $10 per day.

From the CLI, `casama bot create` takes the same choices plus a few the app doesn't show:

```sh
casama credential list
casama bot create "Ada" --credential <key-id> \
  --fallback anthropic/claude-sonnet-5.5 \
  --cheap-model google/gemini-3.8-flash \
  --run-budget 2 --daily-budget 20 --private
```

Leave out `--model` to use the server's default model for the key's provider. See
[CLI](/develop/cli) for every flag.

## Add a model key

On a self-hosted server, bots think with your own model provider keys. Keys belong to one
workspace, are stored encrypted, and are never shown again after you save them.

On Casama Cloud this screen is called **Service keys** instead. It takes only your own keys for
search, maps and paid data (Brave Search, Tavily, Google Maps, Mapbox and Treg); models, voice and
images run on Casama's keys and are paid from your [credits](/guide/usage#credits).

1. Go to **Settings** → **Model keys**.
2. Under **Add Key**, pick a **Provider**, give the key a **Label** and paste the **API key**.
   For your own server, also enter its **Base URL**, for example `http://localhost:11434/v1`.
3. Select **Add Key**.
4. To check it, open the key's **More** menu and choose **Test Key**. Casama makes a one-token
   call and shows **Key works** with the model and the time it took.

Each key shows **Working**, **Failing** or **Not tested**. **Remove** deletes a key; bots that use
it stop working until you give them another key.

These providers can run a bot:

| Provider | Notes |
| --- | --- |
| OpenRouter | Recommended. One key reaches models from many providers. |
| OpenAI | Its first OpenAI key also gives the workspace embeddings for memory and knowledge search. |
| Anthropic | |
| Google Gemini | |
| xAI | |
| OpenAI-compatible server | Ollama, LM Studio, vLLM or any server with an OpenAI-style API. Needs a **Base URL**. |
| ChatGPT | Your ChatGPT plan, connected by signing in instead of a key. See below. |

The same screen also takes keys that give bots other abilities but can't run a bot: fal.ai
(images), Brave Search and Tavily (web search), Treg (paid data), Google Maps and Mapbox (travel
times), and Deepgram, ElevenLabs, Cartesia and Fish Audio (voice).

From the CLI: `casama credential add --provider openrouter --label Default`.

## Connect a ChatGPT plan

With an eligible ChatGPT plan you can run your bots on the plan instead of an API key. Their model
calls count toward your plan's limits, and only you can use it.

1. Open the desktop app (macOS, Windows or Linux).
2. Go to **Settings** → **Model keys** and select **Continue with ChatGPT**.
3. Sign in to ChatGPT in your browser and allow plan usage. The key appears as **ChatGPT plan**.

From the CLI, run `casama credential chatgpt` instead. Phones and the web app can't start the
sign-in, because OpenAI only returns to an address on the same computer; they point you to the
desktop app or the CLI.

How a ChatGPT plan works in Casama:

- **Only you can use it.** A run uses your plan only when it acts for you: a message you sent, a
  routine you created, or work started from one of those. In anyone else's runs the bot moves on to
  its next model, or the run fails with a message saying the plan isn't theirs.
- **Plan limits.** When you reach your plan's limit, the run stops. To continue on the bot's next
  model instead (which may cost money), turn on **Use the bot's next model at my plan limit** in
  the key's menu. The chat shows "Switched to the next model" when that happens.
- **Cost.** Plan usage is recorded in Usage at $0.
- **Status.** The key shows **Connected**, **Plan usage off** (you signed in but didn't allow plan
  usage) or **Sign in again** (the sign-in stopped working; use **Reconnect** from the desktop app).
- **Manage usage** opens your ChatGPT settings. **Remove** revokes the sign-in too.
- The plan doesn't provide embeddings. Without an OpenAI API key, memory and knowledge search use
  full-text matching only.

Self-hosted servers offer ChatGPT sign-in by default; servers with billing turned on don't. The
server's admin controls this with `CHATGPT_SIGN_IN` (see
[Configuration](/self-hosting/configuration)).

## Choose a model

On a self-hosted server, the **Model** field opens **Choose a model**, a searchable list of the
models the selected key can use. Casama Cloud shows no model fields.

- **Recommended** models come first, then **All models**.
- The list comes live from the provider: OpenRouter's catalog; the OpenAI, xAI, Anthropic and
  Google model lists; or `<base URL>/models` on an OpenAI-compatible server. Embedding, image,
  audio and batch models are left out. Lists are cached for 10 minutes.
- If the provider can't be reached, you see "Showing suggested models" with the reason.
- You can always type any model id and pick **Use "…"**.

To change a bot's model later, open its profile and change **Model key** or **Model**, then
select **Save Changes**.

### The default model

Wherever Casama suggests a model, it uses:

| Key | Default model | Model id |
| --- | --- | --- |
| OpenRouter | Muse Ember | `meta/muse-ember` |
| OpenAI | GPT-6 Luna | `gpt-6-luna` |

Other providers have no default, so you pick a model. Casama never replaces a model you chose. A
server admin can change the suggestions with `DEFAULT_MODEL_OPENROUTER` and `DEFAULT_MODEL_OPENAI`.

These built-in defaults run at **medium** reasoning effort unless the bot sets another. Through the
API, each model choice takes an optional `reasoning_effort`: `none`, `low`, `medium`, `high`,
`xhigh` or `max`.

### Fallback and cheap models

Each bot has a primary model, up to five fallback models in order, and an optional cheap model.

- **Fallbacks** take over when a model call fails with an error worth retrying (rate limits,
  provider errors, or no answer within 60 seconds) before any reply has started.
- **The cheap model** handles internal steps: memory extraction, conversation summaries and titles.
  Without one, the primary model does them.

Set fallbacks and the cheap model with `casama bot create` or the API (`model_policy`).

## Personas and starter bots

A persona fills in a bot's name, mascot and instructions in one tap. You can edit all of it before
and after creating the bot. Some personas also bring skills or routines.

1. In the **New bot** sheet, tap a quick pick under **Persona**, or **Browse all**.
2. In **Choose a persona**, search or browse by group, and select **Preview** to read a persona's
   **Instructions** and what to **Try asking**.
3. Select **Use …**.

To swap the instructions of an existing bot, open its profile and select **Load a Persona**. Only
the instructions change; skills and routines stay as they are.

| Group | Personas |
| --- | --- |
| Work | Assistant, Briefing (morning briefing routine), Support, Sales, Product, Ops (hourly health check routine), Inbox triage (weekday morning inbox routine), Outbound prospector, Recruiting screener, Coordinator |
| Research | Researcher (research-report skill), Analyst, Tutor |
| Build | Coder (code-change skill), QA, Designer, Bug triage |
| Create | Writer, Marketer, Social (weekly content plan routine), Translator |
| Life | Travel, Budget, Coach, Chef, Expense matcher |

The Coordinator plans bigger jobs, splits them into tickets and hands them to other bots. See
[Bots working together](/guide/bots-together).

More personas come from the [open gallery](https://gallery.casama.ai/#bot), such as Study buddy and
Home organizer, and show **By** whoever made them. New ones appear without an app update. Anyone can
propose one by pull request to [stackwares/casama-gallery](https://github.com/stackwares/casama-gallery);
a gallery persona asks before acting, at least before risky actions.

## Your first bot: the welcome chat

When you sign in for the first time and don't belong to a workspace yet, Casama creates a
workspace called "&lt;your first name&gt;'s space" and a private bot named Casama, and opens a chat
with it. People who join by invite skip this. To set things up by hand instead, choose
**Set Up Manually**.

The welcome chat is scripted, so it costs nothing until a model runs:

1. **Start with your Google account.** Right after your name, the bot offers **Connect Google
   Calendar**, **Gmail too** or **Not now** (when the server can connect Google). Once Google is
   connected, the bot catches you up on your next two weeks straight away and skips the questions
   below. It only reads; it sends, changes and deletes nothing.
2. With **Not now**: **What should I help with first?** Pick up to three areas, or describe
   something else. Then **Just me, my team or my business?** Both questions can be skipped.
3. On a self-hosted server with no usable model yet, a card offers **Continue with ChatGPT**,
   **Add a model key** or **Use a local model**. The bot uses the first key that has a default
   model as soon as one exists.
4. The bot suggests one app to connect for your picks (for example GitHub for coding), with
   **More apps** and **Done, next**. **My team** and **My business** add an invite card.
5. Your first task starts a real run.
6. The bot then offers the setup interview (**Let's do it**).

The welcome bot also starts with [check-ins](/guide/routines#check-ins) turned on, so it can reach
out when something needs you.

Your picks become pinned memories and a section of the bot's instructions. After the interview, a
**What I learned** card lists the memories saved in the welcome chat; untick any that are wrong,
or choose **Edit in Memory**.

## The setup interview

The setup interview is a few quick questions, after which the bot proposes its own instructions,
routines and the accounts to connect. A new bot opens straight into an empty chat, so you can just
start typing; run the interview whenever you like.

1. Open the bot's profile and select **Run Setup Again**. The welcome chat also offers it.
2. Answer three to six questions on interactive cards: the work, how you like things written, the
   tools and accounts it should use, and any schedule.
3. Review the proposal on its approval card: new instructions, up to five memories, up to five
   routines (scheduled in your timezone) and the connections to add.
4. Approve it. The bot can't sign in to accounts for you, so it tells you which ones to connect.

You can run it as often as you like. Bots created by other bots start with setup pending too.

::: tip
The proposal is high risk, so it waits for you under **Ask before acting** and **Ask for risky
actions**. A bot set to **Act on its own** applies it without asking.
:::

## Bot profile

Open a bot's chat and tap its name, or select **More** (the **…** button), then **Bot profile**.
Change the name, icon, instructions, model (self-hosted only) or autonomy, then select **Save
Changes**.

| Row | What it does |
| --- | --- |
| **Computer** | Which computer the bot uses. **Automatic** means its private computer if it has one, otherwise the team computer. |
| **Voice** | Read-aloud voice and dictation provider. See [Voice and calls](/guide/voice). |
| **Routines** | Work it does on a schedule or trigger. See [Routines](/guide/routines). |
| **Integrations for this bot** | Which workspace integrations it may use. |
| **Memory** | What it remembers. See [Memory and knowledge](/guide/memory). |
| **Folder** | Groups bots in the sidebar. |
| **Sharing** | Who can chat with, edit or manage it. See [Templates, sharing and import](/guide/sharing). |
| **Replays**, **Chat apps**, **Linked bots**, **Publish as an A2A agent** | Recorded steps, outside chat apps, trusted contacts' bots and outside agents. |
| **Knowledge** | Documents it can search and cite. |
| **Plugins** | Skills and tools from plugin packages. See [Plugins](/develop/plugins). |
| **Pages** | Reports and dashboards it published. See [Pages](/guide/pages). |
| **Watchers**, **Action rules**, **Check-Ins**, **Notifications from this bot** | What it keeps an eye on, what it may do without asking, its morning brief and suggestions, and quiet hours. |
| **Run Setup Again** | Starts a new setup interview. |
| **Share as Template** | A file or link with its instructions, skills and routines. |
| **Settings history** | Every change to its settings and who made it, with **Restore These Settings**. |
| **Delete All Chats** | Deletes every chat with the bot that you may delete. Group chats and chats it's working in stay, and so do its memories and usage records. See [Delete a chat](/guide/chat#delete-a-chat). |
| **Archive Bot** | Removes it from the sidebar and stops it running. Its chats and history are kept; bring it back from **Add** → **Archived bots**. |

## Budgets and run limits

Every run is checked against its limits when it starts and again before every model step. A run
that hits a limit stops, fails with a clear message, and keeps everything it did so far.

| Limit | Default | Error code |
| --- | --- | --- |
| Cost of one run | $1 | `budget_exceeded` |
| A bot's cost per day (UTC) | $10 | `daily_budget_exceeded` |
| Workspace monthly cost quota | None | `quota_exceeded` |
| Model steps in one run | 40 | `max_steps_exceeded` |
| Time for one run | 30 minutes | `wall_time_exceeded` |
| No model set | | `no_model_configured` |

On hosted plans, a run can also stop with `out_of_credits` or `computer_hours_exceeded`. See
[Usage, budgets and plans](/guide/usage) for quotas and spend.

When a chat run runs out of steps or time, the bot doesn't go quiet: it replies once more, without
tools, with what it got done, what blocked it and what it suggests.

Because the check runs between steps, one step can take a run slightly past its cap. A bot's cost
today shows on its card in the bot list.

## How bots load tools

A bot with many integrations can have hundreds of tools. Sending every definition on every call
costs tokens, so when a bot has more than 30 tools available, it starts with its core tools
(memory, skills, tasks, notifications, cards and setup) plus a one-line index of the other tool
groups. It loads a group when it needs it, and keeps it for the rest of the run.

You may see this as a step in the chat. Nothing else changes: the bot can still use any tool it's
allowed. Server admins can change the threshold with `LAZY_TOOLS_THRESHOLD` (`0` turns it off).

## Bots that change their own setup

Ask a bot for a new ability and it can often set it up itself. Anything that lets it reach more
always shows you an approval card first, whatever its autonomy or rules. Anything that only makes
it more careful or quieter happens straight away.

| A bot can | How it asks |
| --- | --- |
| Add an MCP server for itself: a remote one by its https address, or one it runs on its own computer with a command such as `npx -y some-mcp-server` | Always asks |
| Start using one of the workspace's connections, optionally only some of its tools | Always asks |
| Suggest a plugin | Shows a card that opens the plugin's install screen, where you review it and enter any keys |
| Suggest a new look for the app (a theme, colors, fonts, light or dark) | Shows a card. **Apply** changes the look on that device only, with **Undo** |
| Add an action rule for itself | **Ask me first** and **Hand it to me** apply at once. **Go ahead** rules always ask, and it can never allow payments or sign-ins |
| Add a website or GitHub repository to its knowledge | Like any other medium-risk action |
| Stop notifying you, or set its own quiet hours | Quieter applies at once. Going back to your usual hours asks |
| Remove a server it added, stop using a connection, remove its own knowledge | Never asks |

A key for a server goes in as `{{secret:NAME}}` from **Settings** → **Advanced** → **Secrets**.
If the secret doesn't exist yet, the bot asks you for it in the chat first, and it must be allowed
for the server's host. New tools arrive from the bot's next message.

Bots can't change billing, members, encryption keys, secrets, sharing, or their own autonomy or
budget.

## Limits

- A bot keeps its own copy of a key it gives a server. If you change the secret later, remove the
  server and let the bot add it again.
- A server a bot runs on its computer takes plain settings only, not secrets. For one that needs
  a key, use a plugin.
- The app has no fields for budgets, fallback models, the cheap model or reasoning effort. Set them
  with `casama bot create` when you create the bot, or through the API. A bot can also change
  another bot's budget with its `bots.update` tool, but never above its own.
- ChatGPT sign-in works only from the desktop app or the CLI. Hosted Casama needs OpenAI's approval
  before it can offer it.

## Related

- [Chatting with a bot](/guide/chat)
- [Autonomy and approvals](/guide/autonomy)
- [Usage, budgets and plans](/guide/usage)
- [Templates, sharing and import](/guide/sharing)
- [CLI](/develop/cli)
