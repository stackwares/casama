<p align="center">
  <img src="client/assets/bots/casama-winky-animated.svg" width="160" alt="Casama's cloud mascot, winking">
</p>

<h1 align="center">Casama</h1>

<p align="center">
  <strong>Casama™: open-source AI teammates with their own computers.</strong><br>
  Bots that remember, reach out first, work on real computers, ask before risky steps, and run on any model.
</p>

<p align="center">
  <a href="https://app.casama.ai">Open the app</a> ·
  <a href="https://docs.casama.ai/quick-start">Quick start</a> ·
  <a href="https://docs.casama.ai/introduction">What is Casama</a> ·
  <a href="https://docs.casama.ai/self-hosting/">Self-hosting</a> ·
  <a href="https://docs.casama.ai/develop/api">Build on Casama</a> ·
  <a href="https://gallery.casama.ai">Gallery</a> ·
  <a href="https://docs.casama.ai">Docs</a>
</p>

<p align="center">
  <a href="LICENSING.md"><img src="https://img.shields.io/badge/license-AGPL--3.0-7a3fa8" alt="License: AGPL-3.0, SDKs Apache-2.0"></a>
  <a href="https://github.com/stackwares/casama/releases"><img src="https://img.shields.io/github/v/release/stackwares/casama?color=7a3fa8&include_prereleases" alt="Latest release"></a>
  <a href="https://status.casama.ai"><img src="https://img.shields.io/badge/status-status.casama.ai-7a3fa8" alt="Status"></a>
  <a href="https://github.com/sponsors/stackwares"><img src="https://img.shields.io/badge/sponsor-GitHub%20Sponsors-7a3fa8?logo=githubsponsors" alt="Sponsor Casama on GitHub"></a>
  <a href="https://www.opensourcealternatives.to"><img src="https://www.opensourcealternatives.to/badge-osa.svg" alt="As seen on Open Source Alternatives" height="20"></a>
</p>

<p align="center">
  <a href="https://discord.gg/e86XbXFHwz"><img src="https://img.shields.io/discord/1572818163685523536?label=Discord&logo=discord&logoColor=white&color=5865F2" alt="Join Casama on Discord"></a>
  <a href="https://x.com/CasamaAI"><img src="https://img.shields.io/badge/X-@CasamaAI-000000?logo=x" alt="Follow Casama on X"></a>
  <a href="https://bsky.app/profile/casama.ai"><img src="https://img.shields.io/badge/Bluesky-@casama.ai-0285FF?logo=bluesky&logoColor=white" alt="Follow Casama on Bluesky"></a>
  <a href="https://www.youtube.com/@casamaai"><img src="https://img.shields.io/badge/YouTube-@casamaai-FF0000?logo=youtube&logoColor=white" alt="Casama on YouTube"></a>
  <a href="https://www.facebook.com/casamaai"><img src="https://img.shields.io/badge/Facebook-casamaai-1877F2?logo=facebook&logoColor=white" alt="Casama on Facebook"></a>
</p>

---

## What is Casama?

Casama is an open-source app for AI teammates that each have their own computer, remember how you
work and ask before anything risky. Its bots browse, fill in forms, write files and run code on a
sandboxed Linux machine you can watch and take over, and they start work on schedules and triggers,
so they keep going after you close the chat. It is for people and small teams who want an AI agent
that does real work without setting it up in code. Casama is open source under AGPL-3.0 and free to
self-host with any AI model, and it is also offered as Casama Cloud.

## Key facts

- **License:** AGPL-3.0 for the product. The SDKs, CLI, MCP server and plugin kit are Apache-2.0.
  One optional folder, `ee/`, has its own license; Casama works fully without it. [LICENSING.md](LICENSING.md)
- **Platforms:** native apps for iPhone, iPad, Android, Mac, Windows and Linux, plus the web, a
  command-line tool and an MCP server.
- **Models:** any provider (OpenAI, Anthropic, Google, xAI, OpenRouter or any OpenAI-compatible
  endpoint), local models through Ollama, LM Studio or vLLM, or a ChatGPT plan when self-hosted.
  On Casama Cloud, Casama picks the models.
- **Pricing:** free to self-host, with no paywall and no limits. Casama Cloud: Free, $15, $49 or
  $99 a month. [Pricing](https://casama.ai/pricing)
- **Where it runs:** your own server, Mac or Linux computer (Docker and 8 GB of memory), or Casama Cloud.
- **Status:** pre-1.0. Expect rough edges, and please [report them](https://github.com/stackwares/casama/issues).
- **Made by:** Stackwares: Oliver Martinez (founder and CEO), Anna May A. Valdez (co-founder, product),
  April Dawn D. Martinez (customer success) and Kelly Avia Martinez (social and community). [About](https://casama.ai/about#who-makes-it)
- **Links:** [casama.ai](https://casama.ai) · [docs](https://docs.casama.ai) ·
  [gallery](https://gallery.casama.ai) · [download](https://casama.ai/download) ·
  [web app](https://app.casama.ai)

## What a bot can do

- **Work on a computer of its own.** Each bot has an isolated Linux computer with a shell, files and
  a browser. Watch it live, take control, or restore a checkpoint.
- **Remember.** Bots keep memory you can read and edit, plus instructions, skills and knowledge sources.
- **Work while you're away.** Schedules, webhooks, email, calendar events and check-ins start work
  without you, and a morning brief tells you what happened.
- **Ask before risky steps.** By default a bot waits for your OK before sending email or chat
  messages, calling people, making a page public or deleting outside its workspace. Payments always
  ask. A checkpoint is saved before destructive commands.
- **Meet you in your chat apps.** Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu,
  iMessage, Microsoft Teams and Discord.
- **Connect to your tools.** One-click apps such as GitHub, Notion, Linear and Google, any MCP
  server, plugins, and an MCP server of its own so AI apps and coding tools can reach your bots.

The full list is under [Features](#features).

<p align="center">
  <a href="site/assets/film/casama-film-v8-16x9.mp4">
    <img src="docs/media/film-v8-poster.jpg" width="820" alt="Watch the Casama film: your AI assistant, with a computer of its own">
  </a>
  <br>
  <a href="site/assets/film/casama-film-v8-16x9.mp4">▶ Watch the film</a> (94 seconds, with sound)
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/screenshots/hero-dark.png">
    <img src="docs/media/screenshots/hero-light.png" alt="Casama on Mac and iPhone: Milo publishes Stardust Drift, a game he made, while his computer's live desktop plays it in the side panel">
  </picture>
</p>

## How Casama compares

| | License | Where it runs | A computer for the agent | Asks before risky steps | Choice of model | Chat apps | Price |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Casama** | AGPL-3.0 | Your own server, Mac or Linux computer, or Casama Cloud | Each bot has its own sandboxed Linux computer you can watch and take over | Yes, by default; a checkpoint is saved before destructive commands | Any provider, a ChatGPT plan or local models when self-hosted; Casama picks on Cloud | 10, including Slack, Teams, WhatsApp, Telegram and iMessage | Self-hosted: free. Cloud: Free, $15, $49 or $99 a month |
| **OpenClaw** | MIT | Your own computer or server only; no hosted version | Runs on your machine; a sandbox is optional and off by default | Optional, and off by default | Your own keys, a ChatGPT or Claude plan, or local models | About 29, including WhatsApp, Telegram, Discord, Slack, Signal, iMessage and Teams | Free; you pay your model provider |
| **Hermes Agent** | MIT | Your own computer or server; a hosted agent comes with paid Nous Portal plans | Your machine by default; Docker, SSH or cloud sandboxes are optional | For shell commands that match risky patterns | Your own keys, Nous Portal, some subscriptions, or local models | More than 20, including Telegram, Discord, Slack, WhatsApp, Signal, Teams and iMessage | Free; optional Nous Portal at $0, $20, $100 or $200 a month |
| **Manus** | Closed | Manus's cloud; a desktop app can run commands on your computer | A cloud sandbox with a browser, per person | None described in the cloud; three modes on your own computer | Manus picks; no choice on standard plans | Slack and email | Free plan with 300 credits a day; Pro from $20 up to $200 a month; Team from $20 a seat |
| **Grok Bot** | Closed | xAI's cloud only | One cloud computer per person, shared by all of that person's Bots | An automatic check decides; you can add up to 20 "ask first" rules | No choice, and you aren't shown which model ran | X, Slack, Microsoft Teams | $30, $100 or $200 a month; no free plan |
| **Rakazo** | Apache-2.0 | Your own server, a desktop app, or Rakazo's cloud | Each bot has its own container or cloud computer | Yes: an Ask mode, or an Auto mode where a model decides when to ask | Your own keys, a ChatGPT plan, local models, or Rakazo credits at the provider's price | Slack and Teams; iMessage, WhatsApp and Telegram only when self-hosted | Self-hosted: free. Cloud: $15, $49 or $99 a month, or credits from $20 |
| **Claude Cowork and Duet** | Closed | Anthropic's cloud; it reaches your computer through the desktop app | Cowork: cloud sessions you can watch. Duet: its own cloud computer that you can't watch | Cowork: depends on the mode you pick. Duet: asks before sending, paying, signing or deleting | Claude models only | The Claude apps only | Included in paid Claude plans and counted against their limits |

Where others are ahead:

- **OpenClaw** reaches about 29 chat apps, has no paid tier at all, is run by a nonprofit, and has
  the largest community of any project here.
- **Hermes Agent** writes and refines its own skills, and lets you choose where commands run:
  locally, in Docker, over SSH or in a cloud sandbox.
- **Manus** needs nothing set up and turns out finished slide decks, websites and wide research.
- **Rakazo** charges for hosted model usage at the provider's price, with no markup.
- **Claude Cowork** makes finished Word, Excel, PowerPoint and PDF documents from your own files.
- **Casama** is the newest here, with a small community, and it has fewer chat apps than OpenClaw
  or Hermes Agent. On Casama Cloud you don't choose the model.

Facts about other products were checked on November 18, 2026, against their own sites and docs.
Every one has its source at [casama.ai/compare](https://casama.ai/compare), along with head-to-head
pages such as [Casama vs OpenClaw](https://casama.ai/compare/casama-vs-openclaw) and
[the best open-source AI agents](https://casama.ai/compare/best-open-source-ai-agents). We make
Casama, so check the sources for anything that matters to you.

## Questions people ask

### Is Casama free?

Yes, to self-host. The software is open source under AGPL-3.0, with no paywall, no limit on users or
bots, and no license key. You pay only for the AI model you use, or nothing with a local model.
Casama Cloud, the hosted service, has a free plan and paid plans at $15, $49 and $99 a month.

### Can I self-host Casama?

Yes. On any machine with Docker and 8 GB of memory, clone this repository and run
`./install.sh --local` for a trial, or `./install.sh --domain <your domain>` for a server. On a Mac
or Linux computer, the desktop app's **Run on This Mac** (or **Run on This Computer**) sets it up for
you. [Casama Link](#casama-link) lets your phone reach that server with no domain or open ports.

### Does Casama work with local models?

Yes, on a self-hosted server. Point a bot at Ollama, LM Studio, vLLM or any server with an
OpenAI-style API, and it runs for free on your own hardware. Local models that read pictures get
them, and memory search can run on the same machine. Long, tool-heavy tasks still go better on the
strongest hosted models.

### How is Casama different from OpenClaw?

OpenClaw is one free, MIT-licensed agent that runs on your own computer, with about 29 chat apps;
its sandbox and approval prompts are off until you turn them on. Casama is a team of bots, each on
its own sandboxed Linux computer, that ask before risky steps from the start and can be shared in a
workspace with roles. You can self-host Casama free or use Casama Cloud. OpenClaw has more chat apps
and a much larger community. [Casama vs OpenClaw](https://casama.ai/compare/casama-vs-openclaw)

### Is it safe to let Casama use my email?

Casama is built so mistakes are small and visible. By default a bot asks before sending email or
chat messages, and payments always ask. Passwords and keys never reach the AI model: a bot uses a
placeholder that Casama fills in only for the site that secret belongs to. Text in emails and web
pages is treated as untrusted, and after a bot has read it, actions that send data out ask first.
Budgets and a loop guard stop a run that goes wrong. [How Casama keeps bots safe](https://casama.ai/security)

### Does Casama train AI models on my data?

No. Your chats, memories and files are used to run Casama for you and are not used to train AI
models. On a self-hosted server they never leave your machine, apart from what you send to the model
provider you chose.

## Try it

On any machine with Docker and 8 GB of memory:

```sh
git clone https://github.com/stackwares/casama && cd casama
./install.sh --local
```

When it's up, open the Casama app on the same computer ([desktop](https://github.com/stackwares/casama/releases)
or [web](https://app.casama.ai)), choose **Sign in or create account** → **More options** → **Server**,
enter the address it prints, and create the first account. Add a model key or a local Ollama
endpoint, and make your first bot. Running it on a server with a domain:
[Self-host in about 15 minutes](#self-host-in-about-15-minutes).

## Two ways to run it

| | Casama Cloud | Self-hosted |
| --- | --- | --- |
| **Start** | Sign up at [app.casama.ai](https://app.casama.ai) or in the apps | `./install.sh` on any machine with Docker ([below](#self-host-in-about-15-minutes)) |
| **Models** | Casama picks them, paid from credits | Your own keys, a local model or your ChatGPT plan |
| **Computers** | Run for you | Run on your server, or borrowed from Cloud through [Casama Link](#casama-link) |
| **Price** | Free plan, then paid plans ([below](#casama-cloud)) | Free, with no paywall and no limits |

Both use the same apps, CLI and API.

## Features

- **Persistent bots**: instructions, memory, [skills](docs-site/guide/skills.md),
  [knowledge sources](docs-site/guide/memory.md) and budgets, with personas, starter bots and a
  setup interview where the bot proposes its own setup. [Bots and models](docs-site/guide/bots.md)
- **One conversation, many topics**: each bot has a General chat for quick questions, briefs and
  results, and bigger work runs in topics that report back.
  [Chatting with a bot](docs-site/guide/chat.md)
- **Bots that reach out first**: a morning brief, and suggestions with Do It and Not Now buttons
  when a bot spots something in your mail or calendar it could handle. Quiet hours are on by
  default. [Check-ins](docs-site/guide/routines.md#check-ins)
- **A real computer each**: an isolated Linux computer that sleeps when idle. Watch it live, take
  control, restore checkpoints, or lend your own machine through the desktop app.
  [Computers](docs-site/guide/computers.md)
- **Teach by showing**: do a task once on the bot's computer while Casama records it, and the bot
  turns the recording into a skill it can repeat. [Teach by showing](docs-site/guide/teach.md)
- **The Library**: sites and games, reports, documents, pictures, videos and sounds a bot makes are
  kept with versions, grouped by [project](docs-site/guide/projects.md), and shareable with a link.
  Replies can carry buttons, forms, maps, video and audio the app draws natively.
  [The Library](docs-site/guide/library.md) · [Pages](docs-site/guide/pages.md)
- **Works while you're away**: schedules, webhooks, calendar, message and device triggers, watchers,
  and routines that end on a date or after a number of runs.
  [Routines](docs-site/guide/routines.md) · [Meeting notes](docs-site/guide/meetings.md)
- **Bots working together**: bots split up work, hand tasks to each other, manage other bots, hand
  coding to Claude Code, Codex, Cursor, Pi or T3 Code and come back with the pull request, and
  talk to bots outside your workspace over A2A.
  [Bots working together](docs-site/guide/bots-together.md) ·
  [Coding agents](docs-site/guide/coding-agents.md)
- **You stay in charge**: autonomy levels, approvals, action rules, budgets, a loop guard and a full
  timeline of every run. Bots can even pay for things with a single-use card you approve each time.
  [Autonomy](docs-site/guide/autonomy.md) · [Payments](docs-site/guide/payments.md)
- **Any model**: OpenAI, Anthropic, Google, xAI, OpenRouter or any OpenAI-compatible endpoint,
  including free local models through Ollama, LM Studio or vLLM. Local models that read pictures
  get them, and memory search can run on the same machine. Self-hosters can sign in with a ChatGPT
  plan. On Casama Cloud, Casama picks the models. [Bots and models](docs-site/guide/bots.md)
- **Connected to your tools**: one-click apps (GitHub, Notion, Linear, Google and more), meeting
  notes apps, MCP servers, plugins, password managers and device data, with secrets kept out of the
  model's sight. Phone and computer data (calendar, contacts, health summaries) too, when you allow it.
  [Connections](docs-site/guide/connections.md) · [Devices](docs-site/guide/devices.md)
- **Where you already work**: Slack (with approval buttons in the thread), Microsoft Teams, Discord,
  Telegram, WhatsApp, Messenger, Feishu, iMessage, email and SMS; assign a bot a Linear or Jira
  issue; group chats with several bots.
  [Chat apps](docs-site/guide/chat-apps.md) · [Group chats](docs-site/guide/group-chats.md)
- **Voice and calls**: dictate, have replies read aloud, call a bot live or let it ring your phone.
  Minimise a call and keep using the app; it carries on when you lock the phone, and you can watch
  the bot's computer during the call. [Voice and calls](docs-site/guide/voice.md)
- **Sites at their own address**: publish a site a bot made in one tap, at a free address on
  Casama's sites domain or on your own domain. On Casama Cloud you can buy a domain in the app, with
  the DNS set up for you, and it renews itself. [Sites and domains](docs-site/guide/sites-and-domains.md)
- **Never more than a glance away** *(coming soon)*: a working bot shows in your Mac's notch and
  menu bar (the tray on Windows and Linux), and on your phone's Lock Screen as a Live Activity or
  Android live notification, with Stop, Allow and Deny right there. Casama for Chrome, Edge and
  Firefox asks a bot about the page you're on and saves things to your Library. A push tells you
  when a reply is ready, with a switch for each kind of notification.
  [Notch and menu bar](docs-site/guide/notch.md) · [Lock Screen](docs-site/guide/lock-screen.md) ·
  [Casama for Chrome](docs-site/guide/chrome.md) · [Notifications](docs-site/guide/attention.md)
- **Teams and sharing**: workspaces with roles and invites, bots shared with teammates or passed on
  as templates anyone can import. [Workspaces](docs-site/guide/workspaces.md) ·
  [Sharing](docs-site/guide/sharing.md)
- **Your server on your phone**: [Casama Link](#casama-link) gives a server on your own computer a
  `casama.link` address your phone signs in to by scanning a QR code. Free on every plan.
- **An open gallery**: themes, skills, apps, starter bots, routine ideas, starter sets and plugins
  at [gallery.casama.ai](https://gallery.casama.ai). Each item says what it can reach, the catalog is
  signed, installs update in place, and workspace admins can require approval. Anyone can add to it
  with a pull request or straight from the app, and every app picks it up without a release.
  [Gallery](gallery/README.md)
- **Built to build on**: an HTTP API, a CLI, TypeScript and Dart SDKs, an MCP server for AI apps,
  plugins, bot templates and agent-to-agent (A2A). Coding agents get an
  [agent kit](agent-kit/) of skills and a docs MCP server. [Build on Casama](docs-site/develop/agents.md)
- **Private by design**: row-level security on every table, encryption at rest with replaceable keys,
  data export and deletion. A self-hosted server sends no telemetry unless you turn it on.
  [Privacy](docs-site/guide/privacy.md)

### See it

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/screenshots/mac-group-dark.png">
    <img src="docs/media/screenshots/mac-group-light.png" alt="A group chat on Mac: you ask @everyone to plan Sam's birthday, Nova hands the invite to Ada and the RSVP page to Milo, and Ada's invite comes back">
  </picture>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/screenshots/mac-nova-dark.png">
    <img src="docs/media/screenshots/mac-nova-light.png" alt="Casama on Mac: Nova plans a weekend in Kyoto and shows each day's stops on a map in the chat">
  </picture>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/screenshots/iphone-dark.png">
    <img src="docs/media/screenshots/iphone-light.png" alt="Casama on iPhone: your bots with their mascots, Nova's Kyoto plan on a map, Milo's bakery site, and Juno ready to start">
  </picture>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/screenshots/ipad-dark.png">
    <img src="docs/media/screenshots/ipad-light.png" alt="Casama on iPad: Milo plays Stardust Drift, a game he made, live on his own computer while you watch">
  </picture>
</p>

## Self-host in about 15 minutes

You need a machine with Docker.

```sh
git clone https://github.com/stackwares/casama && cd casama
./install.sh --local                          # a trial on this machine
./install.sh --domain casama.example.com      # or a server with a domain pointed at it
```

Then open the app, tap **Let's Go** → **More Options**, enter your server's address, and create the
first account, which becomes the server's owner. Add a model key, a local model or your ChatGPT
plan under **Settings** → **Model keys**. On a Mac or Linux, the desktop app can also do all of
this for you: **Run on This Mac** (or **Run on This Computer**) on the sign-in screen walks through
Docker, the server, your account, a model and your phone (it needs Docker and about 10 GB of disk).

To use that server from your phone, turn on [Casama Link](#casama-link). The full guide covers requirements, configuration, upgrades
and backups: [Self-hosting](docs-site/self-hosting/index.md).

## Casama Cloud

[Casama Cloud](https://casama.ai) is the hosted service, for when you'd rather not run a server.
Sign up at [app.casama.ai](https://app.casama.ai) or in the apps. Casama picks the models and runs
the computers, and each plan includes monthly credits for models, computers and voice. You can buy
more credits or add your own model keys.

| Plan | Price | Credits a month | Bots | Computer hours a month | People |
| --- | --- | --- | --- | --- | --- |
| **Free** | $0 | $1 | 3 | 5 | 1 |
| **Plus** | $15 a month | $5 | 10 | 30 | 1 |
| **Pro** | $49 a month (7-day free trial) | $15 | Unlimited | 100 | 3 (+$12 each) |
| **Max** | $99 a month ($899 a year) | $30 | Unlimited | 300 | 10 (+$12 each) |

Self-hosting needs none of this. Plans can change, so the app's **Billing** screen and
[Usage, budgets and plans](docs-site/guide/usage.md) always have the current ones.

## Casama Link

[Casama Link](docs-site/guide/casama-link.md) connects a server you run yourself to Casama Cloud.
Your bots, chats, memory and files stay on your server. It has two parts, and you can use either
one or both:

- **Remote access (free on every plan):** your server gets an address like
  `https://k7qm2xfd9abc.casama.link` that your phone can reach, with no domain and no open ports.
  Sign in by scanning a QR code, and get notifications in the App Store and Google Play apps. Run
  `casama selfhost remote on`, or open **Settings** → **Casama Link** in the desktop app.
  [Use your server on your phone](docs-site/self-hosting/remote-access.md)
- **Cloud computers and credits (paid):** your server's bots run on Casama Cloud's computers or pay
  for model calls from Cloud credits, for when you don't want to host computers or manage keys, or
  your platform has no Docker. [Cloud computers and credits](docs-site/self-hosting/casama-link-cloud.md)

## Platforms

| Where | How |
| --- | --- |
| iOS, iPadOS, Android, macOS, Windows and Linux | The Flutter app in [`client`](client) |
| The web | The same app at [app.casama.ai](https://app.casama.ai), or served by your own server |
| Your browser *(coming soon)* | Casama for Chrome, Edge and Firefox, in [`apps/extension`](apps/extension). [Casama for Chrome](docs-site/guide/chrome.md) |
| The terminal | The `casama` CLI: `brew install stackwares/tap/casama`, or a binary from [Releases](https://github.com/stackwares/casama/releases). [CLI](docs-site/develop/cli.md) |
| AI apps and coding tools | The Casama MCP server. [Connect AI apps](docs-site/guide/mcp.md) |
| Your own software | The [HTTP API](docs-site/develop/api.md), the [TypeScript client](docs-site/develop/typescript.md) and the [Dart SDK](docs-site/develop/sdk.md) |
| Coding agents | The [agent kit](agent-kit/): skills, a docs MCP server and `casama init`. [Build with AI agents](docs-site/develop/agents.md) |

## Documentation

The documentation is at [docs.casama.ai](https://docs.casama.ai). Its source is in
[`docs-site/`](docs-site/) (a VitePress site; `pnpm --filter @casama/docs dev` serves it locally).

|                     |                                                                                                                                                                                                                                                                                                                  |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Get started**     | [What is Casama](docs-site/introduction.md) · [Quick start](docs-site/quick-start.md) · [FAQ](docs-site/faq.md)                                                                                                                                                                                                  |
| **Guides**          | [Bots](docs-site/guide/bots.md) · [Chat](docs-site/guide/chat.md) · [Library](docs-site/guide/library.md) · [Projects](docs-site/guide/projects.md) · [Sites and domains](docs-site/guide/sites-and-domains.md) · [Computers](docs-site/guide/computers.md) · [Routines](docs-site/guide/routines.md) · [Connections](docs-site/guide/connections.md) · [Voice and calls](docs-site/guide/voice.md) · [Notifications](docs-site/guide/attention.md) · [Notch and menu bar](docs-site/guide/notch.md) · [Lock Screen](docs-site/guide/lock-screen.md) · [Casama for Chrome](docs-site/guide/chrome.md) · [Casama Link](docs-site/guide/casama-link.md) · [Autonomy](docs-site/guide/autonomy.md) · [Workspaces](docs-site/guide/workspaces.md) |
| **Self-hosting**    | [Install](docs-site/self-hosting/index.md) · [Configuration](docs-site/self-hosting/configuration.md) · [Use it on your phone](docs-site/self-hosting/remote-access.md) · [Operations](docs-site/self-hosting/operations.md) · [Troubleshooting](docs-site/self-hosting/troubleshooting.md)                         |
| **Build on Casama** | [Build with AI agents](docs-site/develop/agents.md) · [HTTP API](docs-site/develop/api.md) · [CLI](docs-site/develop/cli.md) · [TypeScript](docs-site/develop/typescript.md) · [Dart SDK](docs-site/develop/sdk.md) · [Plugins](docs-site/develop/plugins.md) · [Webhooks](docs-site/develop/webhooks.md)                     |
| **Contributors**    | [How Casama is built](docs-site/develop/architecture.md) · [Contribute](docs-site/develop/contributing.md) · [Decision log](docs/DECISIONS.md) · [Product spec](SPEC.md)                                                                                                                                         |

## Architecture

A TypeScript API and worker (one codebase) on Postgres with row-level security, a sandbox
supervisor that alone talks to Docker, one container per bot computer behind an egress proxy, and a
Flutter app for every platform. [How Casama is built](docs-site/develop/architecture.md) maps the
repository and follows one message from the app to a computer and back.

## Contributing

Contributions are welcome, from typo fixes to features. [CONTRIBUTING.md](CONTRIBUTING.md) explains
the development setup, the checks and how to send a change. Every commit needs a
[DCO](https://developercertificate.org/) sign-off (`git commit -s`), and every contributor signs the
one-time [CLA](CLA.md). Please follow the
[Code of Conduct](CODE_OF_CONDUCT.md). How decisions are made is in [GOVERNANCE.md](GOVERNANCE.md).

- **Questions and ideas**: [GitHub Discussions](https://github.com/stackwares/casama/discussions)
- **Bugs and feature requests**: [GitHub Issues](https://github.com/stackwares/casama/issues)

## Sponsors

Casama is free to self-host, with no limit on users or bots. If you run it yourself, at home or at
work, you can help keep it that way through
**[GitHub Sponsors](https://github.com/sponsors/stackwares)**, from $5 a month or one time.
Sponsorships pay for releases on every platform, security fixes, plugin reviews and docs.
Sponsors at $25 and up are listed here, and teams at $100 and up on
[casama.ai/open-source](https://casama.ai/open-source). Using [Casama Cloud](https://casama.ai/pricing)
pays for the project too.

<!-- sponsors -->
Be the first: [become a sponsor](https://github.com/sponsors/stackwares).
<!-- /sponsors -->

## Security

Please report vulnerabilities privately to **security@casama.ai** or through GitHub's private
vulnerability reporting, never in a public issue. [SECURITY.md](SECURITY.md) explains what's in
scope and what to expect.

## License

The product (server, worker, agent and the apps) is under [AGPL-3.0](LICENSE). The SDKs, CLI, MCP
server, plugin kit, examples and docs are under [Apache-2.0](LICENSES/Apache-2.0.txt), so whatever
you build on Casama can use any license. `ee/` is source-available under the
[Casama Enterprise License](ee/LICENSE) and needs a license key in production. Without `ee/`,
Casama is fully open source and works on its own. A
commercial license is available for organisations that can't use AGPL (hello@casama.ai).
[LICENSING.md](LICENSING.md) explains the split; see also [NOTICE](NOTICE),
[TRADEMARKS.md](TRADEMARKS.md), [CLA.md](CLA.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

**Casama™**, the Casama logo and the bot mascots are trademarks of Stackwares. The license covers the
code, not the name: forks are welcome under their own name ([TRADEMARKS.md](TRADEMARKS.md)).
