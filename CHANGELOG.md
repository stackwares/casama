# Changelog

All notable changes to Casama are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/). Until 1.0, minor versions may include breaking changes;
they're called out under **Changed**.

The server, apps, CLI, SDK and MCP server share one version number.

## [Unreleased]

- One crash reporter at a time (D-417): an app runs Sentry, Firebase Crashlytics or PostHog error
  tracking, never two, and the server owner switches which one in Admin → App settings
  (`crash_reporter`, per platform over a default) without a release. Apps take a change on their
  next launch and fall back to their build's own choice when the named one isn't in the build.
  Official builds default to Sentry and upload crash symbols to every configured reporter, Sentry
  included. See [Which crash reporter runs](https://docs.casama.ai/self-hosting/configuration#which-crash-reporter-runs).
- Paste a bot's setup (D-415): bring a bot over from Grok Bot, Meta Muse, ChatGPT Dots, Claude Duet,
  Hark Pro, Instinct or another app. Casama gives you a prompt to send your old bot; paste its reply and review its
  instructions, schedules, skills, apps and memories before the bot is created. Lines that look like
  keys or card numbers are removed. See [Paste a bot's setup](https://docs.casama.ai/guide/sharing#paste-a-bot-s-setup).
- Crash reports (D-416): the official iOS, Android and macOS apps also report crashes to Firebase
  Crashlytics, and the "Share usage data and crash reports" switch in Settings → Privacy now turns
  every crash reporter off (Sentry included), deleting Crashlytics reports not yet sent. casama.ai,
  the docs, the gallery and the web app's page report script errors to Sentry; nothing loads until
  something breaks, no cookie, and Do Not Track or Global Privacy Control turns it off.
  iOS crash symbols reach PostHog again: an archive holds some dSYMs twice, and the upload now
  sends each one once. Packaging scripts also upload dSYMs and the Android R8 mapping to Crashlytics.
- A waitlist and invite gate for Casama Cloud (it stays off until an owner turns it on; self-hosted
  servers are unaffected, and existing accounts never are):
  - While it is on, a new account can be made only for an email address that was let in: from the
    waitlist, with an invite code claimed together with that address, or added by hand. A workspace
    invite also works when the workspace has a free seat. It holds for every way of signing up
    (email link, password, Apple, Google, the CLI), and a refused sign-up sends no email.
  - Joining the waitlist sends no email. People let in get one "You're in" email, at most a set
    number a day.
  - Campaign codes: an owner makes a code with a total and optional per-day number and dates.
    Members' invites: each member's Invite Friends code lets in a few friends once they have
    finished a first chat.
  - Owners run it with `scripts/waitlist.sh` (stats, admit, add, codes, on and off) or the
    `/v1/admin/signup-gate` route. `GET /v1/config` gains `signup_gate`. See
    [Getting an invite](https://docs.casama.ai/guide/getting-an-invite).
  - Fixed: when the sign-up hook refuses someone (the waitlist, `SIGNUP_ALLOWED_EMAILS`,
    `SIGNUP_INVITED_ONLY` and Casama Cloud's sign-up check), the reason now reaches the apps. Before,
    Auth showed "Unexpected status code returned from hook: 403" for every refusal.

- The `casama` CLI covers most of the app. New commands: `chats` (read, export, share, branch,
  delete), `routines` (list, create, edit, run, delete), `approvals` (answer what bots are waiting
  on), `tasks`, `watchers`, `skills`, `plugins`, `apps`, `secrets`, `knowledge`, `channels`,
  `projects`, `library` and `billing`. `bot` adds show, export, import, share, check-ins and
  starters; `runs` adds show and usage; `memory` adds edit, delete and import; `computer` adds
  restart, reset, processes, screenshot, vitals, storage, history, update and checkpoint; `org`
  adds members, invites and invite links, join requests, settings, MCP keys, git sync and the
  encryption status. Anything that deletes, revokes, resets or spends money waits for `--yes`.
  An error the server sends without a problem body now reads `http_<status>` instead of a
  library message. See [CLI](https://docs.casama.ai/develop/cli).

- Casama on Linux (D-361):
  - The Linux app no longer quits on start on desktops without a keyring service (i3, Sway and
    others), and no longer crashes when you close it.
  - Attaching and saving files works without a desktop portal: the app uses GTK's own dialog.
  - Ctrl+Shift+K and `casama://` links work outside the snap: the app installs its own desktop entry.
  - The window keeps its size between launches instead of growing a little each time.
  - Developers: the local stack, the tests and `scripts/dev-up.sh` run on Ubuntu; see Contribute.
- `casama chat` with a message exits as soon as the reply is in (it waited two minutes).
- Your bot's first look around after onboarding waits its few minutes for the apps you connect,
  even when you finish just before its regular schedule (it could run first, with nothing connected).
- Credits last longer (D-355):
  - Check-ins read your mail, calendar and board first and think once, instead of spending a
    step on each read. A scheduled look that reads exactly what the last one read ends there. A
    look that runs out of steps keeps what it found instead of failing with nothing.
  - On Casama Cloud, all of a workspace's check-ins together use at most 40% of the day's limit
    on Casama's models, and Free looks once a day (it was twice). The app's check-in sheet offers
    24 hours.
  - Long tasks send less: once a task's own steps pass 48,000 tokens, its oldest results are cut
    to their first lines.
  - A chat keeps the tools it used, so later messages don't load them again, and the date and
    time no longer make every message pay for the whole history again.
  - `CLOUD_MODEL_CHAT_SORT` can put live chat on a faster provider at a higher price; off by
    default.
  - Live calls cost less: a call carries a third of the tool text it did, the start of a long
    persona, and trims its conversation sooner (`VOICE_CONTEXT_TRIGGER_TOKENS`,
    `VOICE_CONTEXT_TARGET_TOKENS`). On a call, changing or deleting routines and setting up
    watchers now go through "start a task in the chat".
  - The tools sent with every model call are 40% smaller. Bots look up the less common cards
    (maps, drafts, events and others) with a new `ui.catalog` tool when they need one.
- Fixed: a bot on a live call now knows today's date and time, so "remind me tomorrow at nine"
  is set for the right day.
- Fixed: on Casama Cloud, the daily-limit message and the line under the credits meter told
  people to add their own model key, which does nothing there. They now say to upgrade.
- Model calls on the server's shared OpenRouter key cost about half as much (D-354): each call goes
  to the model's cheapest provider first and stays there, so its prompt cache holds from one step
  to the next. Before, OpenRouter spread calls across providers priced up to eight times apart.
  `CLOUD_MODEL_PROVIDER_SORT=off` brings the old routing back, and `CLOUD_MODEL_PROVIDERS` names
  providers to try first. A workspace's own OpenRouter key is unchanged.
- Zoho with one sign-in (D-350): one Zoho app covers Zoho Mail, CRM, Desk and Books in any Zoho
  data centre except China, with Casama's own Zoho client and no Composio. Bots get a small set of
  tools for the apps the account has. Sending email, replying to customers and sending invoices
  ask first. Self-hosted servers set `ZOHO_OAUTH_CLIENT_ID` and `ZOHO_OAUTH_CLIENT_SECRET`. Where
  it's set up, it replaces the four Composio Zoho tiles.
- Zoho Mail, Zoho CRM, Zoho Desk and Zoho Books (D-349): one-click sign-in through Composio, no URL or
  key, where the server has Composio (Casama Cloud does). The pasted-URL app is now called Zoho MCP.
- Fixed: a plugin's tool servers on a bot with no computer of its own (every bot a pack makes) now
  run on the workspace's team computer, the one the bot's runs use, instead of failing at install
  with "The bot needs a computer". Imported agent files go there too.
- Fixed: Node tool servers on bot computers (the Dev kit's among them) reach the internet: they
  get `NODE_USE_ENV_PROXY=1`, so Node's fetch uses the computer's egress proxy instead of failing
  with "fetch failed".
- Zoho (D-346): connect Zoho Mail, CRM, Desk, Projects and other Zoho apps by pasting your Zoho MCP
  server URL from mcp.zoho.com. Casama keeps the URL as a secret and only accepts Zoho's own hosts.
- Plugin tools on your own computer (D-344): installing a plugin or a pack offers to run its
  local (stdio) tool servers on your paired computer instead of the bot's, when the Casama desktop
  app is open there with Local tools on. The package goes to `~/.casama/plugins/`, only your own
  chats can use the tools, and the plugin's page says "Runs on <computer>".
- Cards for a plugin's tools (D-345): a plugin can show a tool's result as a native card from the
  apps' existing catalog (Details, Checklist, Event, Results, Map and the rest) with one file per
  tool, `com.casama/cards/<tool>.json`, binding `{{result.path}}` into the tool's structured
  result, with `each` for lists and an optional `when`. The filled card is checked like a bot's
  `ui.show`; anything that doesn't fill stays text. plugin-check lists the tools with cards and
  warns about bad ones. The Dev kit pack shows a pull request as a Details card.
- Packs (D-343): one install sets up whole bots, their skills, routines, apps to connect,
  workspace skills and looks. A pack is an Agent Plugins 1.0 plugin plus `com.casama/pack.json`,
  so it still works as a plain plugin elsewhere. The preview lists every item (untick what you
  don't want), asks the pack's questions and shows what it can reach: hosts, code, secrets,
  scheduled runs a week and knowledge pages. Updates show a diff and keep what you edited;
  removing keeps your bots unless you ask. Share as pack turns your bots into a pack file or a
  30-day link, scanned for secrets first. Gallery rules apply to packs and to pasted plugin links
  (`repo/<owner>:<repo>`). Plugins gain settings (non-secret values) and private repositories
  through the workspace's GitHub token. First-party packs: Founder kit, Dev kit, Meetings handled.
  API: `/v1/packs`, `/v1/pack-shares/{token}`, `/v1/gallery/packs`; CLI: `casama packs`,
  `casama init pack`; MCP: `list_packs`, `preview_pack`, `install_pack`.
- Reactions (D-331): react to any message with an emoji. Hold a message (or hover it) for 👍 ❤️ 😂
  😮 😢 👎 or any emoji, or double-tap for ❤️; chips with counts, who reacted, live on every
  device. One reaction per person per message. Bots read reactions as feedback (👎 counts as a
  correction for skill learning) and can react themselves with `chat.react`. Reactions go both
  ways in Telegram, Slack and WhatsApp, and work in Casama for Chrome. API:
  `PUT`/`DELETE /v1/conversations/{id}/messages/{message_id}/reaction`; MCP: `react_to_message`.
- Sites and domains (D-329): put a page, game or folder site a bot built on the web at its own
  address; connect a domain you own (Casama Cloud gets its certificate from Cloudflare,
  self-hosted servers from Caddy's on-demand TLS); on Casama Cloud, buy a domain with its DNS set
  up for you, renew it automatically, edit its DNS records and move it away whenever you like.
  `casama sites` and `casama domains` in the CLI, `sites` and `domains` helpers in
  `@casama/client` and `casama_sdk`, six MCP tools, and the `casama-sites` agent-kit skill.
- Your bots in the Mac's notch and menu bar (D-324): a working bot shows around the camera
  whatever app is in front, with Allow, Deny and Stop right there; closing the window keeps Casama
  in the menu bar (the tray on Windows and Linux). On phones, a run's progress follows you as an
  iPhone Live Activity or an Android live notification.
- Casama for Chrome (D-323): a browser extension for Chrome, Edge and Firefox that asks a bot about
  the page you're on, saves things to the Library and answers requests from the toolbar. It reads
  a page only when you ask.
- Notifications (D-312, D-325): a push when a reply is ready or a long run couldn't finish, never
  for the chat you have open; a switch for each kind (and an Android channel for each); Hide reply
  text for the lock screen; pushes are plain text, and the morning brief comes once.
- Live calls (D-327): minimise a call and keep using the app, one call at a time, the bot's
  computer live during the call, and calls that carry on when the phone locks or you switch apps.
- Local models (D-330): models that read pictures get them, and memory search can use a local
  embedding model so nothing leaves the machine.
- Links in emails and invites open the installed app (D-326), through `casama.ai/open`.
- Bots' cards can show a map (D-310), play video and audio, and check a form before it's sent
  (D-322).
- Device access (D-328): when a bot needs data you share from a device, the Allow card appears on
  its own instead of the bot saying it asked.
- Coding agents on your own computer (D-320, D-321): cancelling stops the command, and Pi joins
  Claude Code, Codex and Cursor.
- Gallery v2 (D-315): Picks, New, Trending and Starter sets rows, a signed catalog, items that say
  what they can reach, in-place updates, admin approval, and contributing from the app.
- Help & support (D-298, D-303, D-308): Casama Help answers straight away from the docs and your
  account (usage, credits, connections, bots, invites), the support team is one tap away, and
  tickets have a reference you can ask about later.
- Report and block (D-301): report a reply, a shared bot, a gallery item or a person, and block
  people from inviting you.
- Show usage on replies (D-307): a line under each reply with its cost, tokens and steps, and
  `GET /v1/runs/{id}/usage`. The plan's daily limit shows on Billing with its amount (D-311).
- Account emails (D-302): billing changes (trial, new plan, failed payment, renewal off, expiry)
  and a short welcome series.
- A public status page at `status.casama.ai` (D-304), and the store's rating prompt after a good
  moment (D-305).
- Building on Casama with a coding agent: an agent kit of skills (plugins, the API, A2A, bot
  templates, the gallery, the Casama repo) for Claude Code (`/plugin marketplace add
  stackwares/casama`), Codex, Cursor and Casama bots; a docs MCP server at
  `https://api.casama.ai/mcp/docs` (and `/mcp/docs` on self-hosted servers) that searches the docs
  and looks up API operations with no sign-in; `llms.txt` and a markdown copy of every docs page;
  Copy page and Open in Claude/ChatGPT buttons on the docs. See docs.casama.ai/develop/agents.
- `casama init plugin|skill|bot|routine` writes a starting point that passes Casama's checks, with
  an `AGENTS.md` for your coding agent.
- `npx @casama/plugin-check` checks a plugin the way Casama does at install.
- `@casama/client`: a typed TypeScript client for the HTTP API, with helpers to ask a bot, follow
  a run and decide approvals.
- The MCP server (`@casama/mcp` 0.2.0) adds `search_docs`, `read_doc`, `list_doc_pages`,
  `get_api_operation` and `check_plugin`; `--docs-only` runs them without a sign-in.
- Setting up a server on your own Mac or Linux computer is now one guided flow in the desktop app:
  **Run on This Mac** on the sign-in screen walks through Docker (with a download button, or
  opening it for you), the server, your account, an AI model and your phone, and picks up where
  it stopped if you quit half way.
- Casama Link: use a server on your own computer from your phone, with no domain, no router
  settings and no open ports. Link the server to a free Casama Cloud account
  (Settings → Casama Link, or `casama selfhost remote on`) and it gets a public address through
  a tunnel; traffic goes from your phone through Cloudflare to your computer, never through
  Casama's servers. Sign-ups close while it is on, or open to invited people only.
- Sign in on a phone by scanning a QR code from a device where you're signed in
  (Settings → Sign In on Another Device, or `casama pair`), on self-hosted servers and Casama Cloud.
- Self-hosted servers can now notify the apps from the App Store and Google Play, and ring them
  for calls, by linking to Casama Cloud (`casama selfhost remote link` for a server with its own
  domain). Private Notifications keeps the text on your server.
- Live view of a bot's desktop from away from a self-hosted server, through a relay at Casama
  Cloud (Plus and up); without it you see the screen about once a second.
- Cloud Connect (a self-hosted server using Casama Cloud's computers and models with a key) is
  now part of Casama Link.
- Projects keep one piece of work together. A project needs only a name and a bot, a topic can
  become one, and what a bot makes for it is filed under it in the Library, which has a Projects
  row. Letting the bot plan a project and work on it by itself is now a switch. Something in the
  Library can be moved into or out of a project.
- Bots can change their own setup: add MCP servers (remote, or run on their computer), use the
  workspace's connections, suggest plugins and a new look for the app, add their own action
  rules and knowledge, and quiet their notifications. Anything that lets a bot reach more always
  asks first.
- The Library: everything bots make (sites and games, reports, documents, pictures, videos, sounds
  and files a reply links to) is kept in one place, with search, filters, pins, versions, a PDF
  preview and cover for documents, copies, storage limits per plan, and sharing with the workspace
  or by a public link. Deleting a chat keeps what was made in it.
- Each bot has one General conversation for quick questions, briefs, routine results and
  suggestions; bigger work runs in topics that post a one-line result back. The Inbox tab gives way
  to Chats, with Needs you and Updates rows.
- Proactive bots: the first bot has check-ins on, with a morning brief and suggestions pushed in
  the bot's own words with Do It and Not Now buttons. Quiet hours (22:00 to 07:00) are on by
  default, and times follow your device's timezone.
- Slack as a place to work: one-click install, @mentions in channels, and approvals with buttons in
  the thread. Microsoft Teams and Discord join the chat apps, and assigning a Linear or Jira issue
  to a bot starts work on it.
- Meeting notes without a meeting bot: calendar routines can run after a meeting ends, and a
  routine idea files notes from Fireflies, Granola, Circleback, Otter, Fathom, Zoom or Google Meet.
- Routines can end on a date or after a number of runs, and bots can change every part of a
  routine.
- Pages can take input through forms, and bots can publish sites and games with their own files.
  Bots can make spoken audio.
- Export a chat, or share a read-only link to it (API).
- Calls on a local model cost nothing, and a local embedding model can power memory search.
- Plain is the default look; Casama's own look stays as a theme.
- Casama Cloud plans: Free, Plus ($15 a month), Pro ($49) and Max ($99), yearly for less, with
  extra people on Pro and Max and a 7-day Pro trial. Usage shows in dollars with a credits meter,
  failed runs don't cost model credits, and owners hear when credits run low.
- Usage analytics and crash reports for Casama Cloud and the official apps: one switch for people
  (Settings → Privacy), one for workspace admins, crash reports and funnels in PostHog, no message
  content ever; a self-hosted server sends nothing unless its owner turns it on.

The first public release. Highlights:

### Bots and chat

- Bots with instructions, a model policy with fallbacks, memory, skills, budgets and an autonomy
  level; personas and starter bots to start from; a personal bot made for you at sign-in, and a setup
  interview where a bot proposes its own setup.
- Any model through your own keys (OpenAI, Anthropic, Google, xAI, OpenRouter, OpenAI-compatible
  endpoints including local models), or a ChatGPT plan. On Casama Cloud, a workspace with no key
  of its own runs on Casama's OpenRouter key and pays for those calls from credits.
- Chats with attachments, interactive cards, edit and resend, search, shortcuts and offline reading;
  group chats with several bots; pages.
- Memory with optional external backends; knowledge sources (files, websites, GitHub, connections);
  a catalog of 38 ready-made skills in seven categories (including PDF, Word, Excel and
  PowerPoint skills), GitHub import and self-improving skills. A Gallery in Settings for themes,
  color schemes, wallpapers and skills from `gallery.casama.ai`, with the bundled looks as the fallback.
- About you: one private profile every bot reads (what to call you, pronouns, how you like
  replies, about me, and facts bots learn in chat), shared into team workspaces only when you
  turn it on there.

### Voice

- Live voice calls, in the app and on the phone, run on Gemini Live with a Google AI key. Read
  aloud, dictation, pictures and video run on OpenRouter.
- Cheaper calls: a small voice tool set with bigger jobs handed to the chat, a capped context,
  silence left out of turns, idle calls hung up after 2 minutes, and the real per-call cost
  recorded in usage. Each bot can add chosen connected-app tools to its calls.
- A new call screen: the bot's mascot animated for the call (listening, and talking while it
  speaks), with live captions.
- Calls work without a key of your own on Casama Cloud (paid from credits) and on servers with a
  server-wide `GOOGLE_AI_API_KEY`; otherwise the call screen shows where to get a free key and where
  to add it.

### Computers

- A sandboxed Linux computer per bot (headless or desktop) that sleeps when idle, with checkpoints
  before destructive commands, live view, take control and team computers.
- Providers: Docker (with gVisor on Linux), E2B, Daytona and others; the desktop companion lends
  your own machine, with local MCP servers and desktop context.
- Coding agents, teach by showing, and step replay.

### Automation and connections

- Routines on schedules, webhooks, calendar events, messages and device events; watchers,
  check-ins, projects and a ticket board.
- Built-in app connections, Composio and Pipedream, MCP servers, plugins (Agent Plugins 1.0),
  password managers, paid data services, chat apps, voice calls, device connections and
  health summaries, payments with approval, linked agents and agent-to-agent (A2A).

### Control, teams and privacy

- Approvals, action rules, a loop guard, quiet hours and attention rules; usage and budgets.
- Workspaces with roles, invites and spaces; two-step sign-in; SAML single sign-on (enterprise).
- Sign in with Apple, Google, a passkey, an email link or code, or a password; new accounts confirm
  their email.
- Row-level security on every table, encryption at rest, data export, account deletion, retention
  settings, and telemetry off by default.
- Telemetry hygiene (D-206): official build isolation with `CASAMA_OFFICIAL_BUILD=1`, gitignored client telemetry configuration, super property tracking (`app`, `environment`, `platform`, `distribution`, `server_kind`), session-deduplicated screen tracking, and dynamic web telemetry loading.

### Self-hosting and developers

- `install.sh` for a full self-hosted stack, `casama selfhost` commands, encrypted backups, a Helm
  chart, deploy templates, monitoring and Casama Link.
- An HTTP API with an OpenAPI reference, the `casama` CLI, the Dart SDK, the Casama MCP server
  (local and hosted), bot templates, routines and skills as files with git sync, and a plugin
  checker.
