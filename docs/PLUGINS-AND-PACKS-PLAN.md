# Plugins and packs: the plan

Status: **done** (live in production; checked against `docs/PLANS.md` on 2026-11-20, D-343).

Original status: **built on branch `t3/plugins-and-packs`, not merged, pushed or deployed** (2026-11-17), as
D-343 with every §13 decision at its default. See "Progress" at the end for what is done and what
is left. Written after Oliver asked how the "everything is a plugin" idea stands, which things are
plugins, which could be, and whether there should be content packs.

The Agent Plugins facts in §2 were read on agent-plugins.org on 2026-11-17 through a fetch agent
(pages listed under Sources). The one this design leans on most, the client folder of §8.2, must be
re-read first-hand before Phase 1. Facts that could not be checked are marked.

## 0. Summary

**Where the idea stands.** Casama is not built as "everything is a plugin", and should not be. But
most of the idea is already here under another name. Oliver asked twice to "make almost everything
contributable" (D-201, D-239, D-241), and the gallery now holds nine kinds of thing as plain data:
apps, skills, bots, routines, plugins, starter sets, themes, color schemes and wallpapers. What is
missing is not more kinds. It is **one way for them to travel together**.

Today there are five separate ways to bring something into a workspace, each with its own format
and its own install code:

| Way in | Format | Carries | Scope |
|---|---|---|---|
| Plugin (D-121) | Agent Plugins 1.0 folder on GitHub | Skills and MCP tool servers | One bot |
| Gallery item (D-184 to D-315) | `item.json` plus one document | One app, skill, bot, routine or look | Workspace, or the device for looks |
| Starter set (D-315) | `set.json` | 2 to 12 pointers to gallery items | Workspace |
| Bot template (D-110) | `casama.bot` JSON file or share link | One bot with its skills, routines, memories | Workspace |
| Workspace files (D-124) | `casama.files` folder, git sync | Routines and skills of your own bots | Same workspace |

A developer with a good idea (a tool server, the skill that teaches a bot to use it, a starter bot
and a Monday routine) has to split it across a plugin repo and four gallery pull requests, then ask
for a starter set to tie them together. A person with a good setup can share one bot, not the setup.

**The plan in three lines:**

1. **State the principle properly:** everything you *add* to Casama travels as a plugin. The core
   (run loop, computers, channels, billing) is not made of plugins and never runs plugin code.
2. **Let a plugin carry every kind Casama already knows.** The Agent Plugins format gives each app
   its own folder inside a plugin. Casama's folder, `com.casama/`, holds bots, routines, apps and
   looks in the gallery's existing formats. The plugin stays valid in every other app that reads the
   format; they use its skills and tool servers and ignore the rest.
3. **Call a plugin that brings a setup a Pack.** A pack installs for the workspace through the
   install wizard starter sets already have, updates with a diff, and can be exported from a
   workspace ("Share as pack"). That is the content pack.

| Part | What a person gets | Built on |
|---|---|---|
| **Packs from a link** | Paste a GitHub link (or tap Add to Casama on a web page): see every bot, skill, routine, app and tool it adds, answer its questions, install | Plugin fetch and pinning (D-121), gallery checkers and `installGalleryItem` (D-315) |
| **Packs in the gallery** | A Packs shelf: reviewed packs and today's starter sets together | The plugin directory (D-241), `sets.json` |
| **Updates** | Update shows what changed; things you edited stay yours | Plugin update diff, `gallery_links` |
| **Share as pack** | Turn your bots, skills, routines and look into a pack: a file, a link, or a gallery submission | Bot template export (D-110), gallery submissions (D-315) |
| **More for plugins** | Plain settings (not only secrets), tool servers on your own computer, native cards for a plugin's tools | Secrets extension, the desktop companion (D-096), A2UI (D-086) |

Three findings shape the build:

1. **The format already has the room.** Agent Plugins 1.0 defines exactly two portable kinds,
   skills and MCP servers, and says everything app-specific goes under a reverse-domain name, both
   in `plugin.json` (`extensions`) and as a folder of that name. So packs need no new package
   format, fetcher, pinning or checker shell: only new contents.
2. **Almost every kind a pack needs has a checker and an installer today.** Bots, routines, apps
   and looks are checked by `@casama/domain` and installed by `installGalleryItem`. The new work is
   the wrapper: one preview, one install record, one update, one uninstall.
3. **Installing from a link skips the workspace's gallery rules today.** `routes/plugins.ts` never
   consults the gallery policy (Open, Ask first, Only allowed). That gap is closed first, because
   packs make link installs far more powerful.

**Corrections to the chat answer that led here.** Apps are already data in the gallery (61 of
them), so "move apps into plugins" was wrong: plugins should be able to *carry* an app. Model
providers already have a declarative door (`openai_compatible`). A coding agent is better added as
a skill than as a new kind. §6 has the full list.

## 1. What exists today

### 1.1 Plugins (D-121, D-160)

- **Format and checks:** `packages/domain/src/agent-plugins.ts` (`checkPlugin`): `plugin.json`,
  `mcp.json`, `skills/<name>/SKILL.md`. Limits: 400 files, 10 MB.
- **Casama's extension:** `extensions["com.casama"].secrets` only (a name, a description, the
  server, and the environment variable or header it fills). Values go to Vault.
- **Install:** `apps/server/src/api/routes/plugins.ts` (preview resolves a GitHub ref to a commit;
  install must name that commit). Tables in `supabase/migrations/20261213000001_plugins.sql`:
  `plugins` (one row per bot, `unique (bot_id, name)`) and `plugin_files`. Skills and connections
  carry `plugin_id`, so uninstall cascades.
- **Where code runs:** stdio servers run in the bot's computer (`packages/agent/src/plugins.ts`,
  computerd's `PUT /mcp-servers`). Never on Casama's servers.
- **Developer kit:** `docs-site/develop/plugins.md`, `examples/hello-plugin`,
  `packages/plugin-check` (`casama-plugin-check`), the agent kit (`agent-kit/`, itself a plugin).
- **In the app:** `client/lib/features/bots/plugins_screen.dart`, `plugin_directory.dart`. Bots
  can suggest a plugin with a card (`plugins.suggest`, D-242) but never install one.
- **Stated limits:** per bot only; no stdio servers on the person's own computer ("Not yet" in
  D-121); no settings other than secrets.
- **How many exist:** one in the gallery (`gallery/plugins/hello-casama`) and the agent kit's
  `casama-dev`. The door is open and nearly nobody has walked through it.

### 1.2 The gallery (D-184, D-201, D-239, D-241, D-315)

| Kind | In the gallery today | Built-in copy in code | Checker |
|---|---|---|---|
| Apps | 61 (`gallery/apps/`) | 33 in `packages/domain/src/apps.ts` (`APP_CATALOG`) | `gallery-apps.ts` |
| Skills | 38 | 38 bundled in `skills/` (offline copy) | `gallery.ts`, `skill-format.ts` |
| Bots | 2 | 26 in `packages/domain/src/templates.ts` (`BOT_TEMPLATES`) | `gallery-content.ts` |
| Routine ideas | 5 | none | `gallery-content.ts` |
| Plugins (pointer plus reviewed commit) | 1 | none | `gallery-content.ts` |
| Starter sets | 5 | none | `gallery.ts` |
| Themes, color schemes, wallpapers | 8, 9, 15 | `client/looks/` (compiled in) | `gallery.ts` |

- **Install:** `apps/server/src/services/gallery-install.ts`. `installGalleryItem` handles one
  item, with install questions (`inputs`), things it needs first (`needs`) and the workspace's
  gallery policy. `installGallerySet` walks a set and answers per item: installed, approval
  pending, skipped, failed, or device (looks).
- **Tracking:** `gallery_links` (what a workspace installed, at which version, with which answers),
  `gallery_policies`, `gallery_approvals` (`supabase/migrations/20270201100801_gallery_v2.sql`).
- **Trust:** signed catalog, `access` in plain words, Reviewed badge, extra catalogs through
  `GALLERY_SOURCES`, in-app submissions that open a pull request.
- **In the app:** `client/lib/features/gallery/` (install wizard, Installed tab, submit).

### 1.3 Other bundle formats

- **Bot template** (D-110): `casama.bot` version 1, `apps/server/src/api/routes/bot-template.ts`,
  `docs-site/develop/bot-templates.md`. Export, share link (`bot_shares`, 30 days), import with a
  review screen. One bot per file. Never keys, tokens or the model choice.
- **Workspace files** (D-124): `casama.files` version 1, `packages/domain/src/workspace-files.ts`,
  git sync in `packages/agent/src/git-sync.ts`. Carries ids, so it is for keeping one workspace in
  files, not for giving a setup to someone else.
- **Import an agent** (D-122): OpenClaw and Hermes folders become a bot template.

### 1.4 What is extensible only in code

These sit behind an interface in the server and are chosen with settings. They are adapters, not
plugins, and §6 says which should stay that way.

| Thing | Where | Choices today |
|---|---|---|
| Chat apps | `packages/agent/src/channels/adapters.ts` | 12 adapters (Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu, iMessage, Teams, Discord, Linear, Jira) |
| Model providers | `packages/agent/src/gateway/`, `ProviderId` in contracts | OpenAI, Anthropic, Google, xAI, OpenRouter, ChatGPT plan, and `openai_compatible` for any other |
| Coding agents | `packages/agent/src/tools/coding.ts` (`CODING_AGENTS`) | Claude Code, Codex, Cursor, Pi |
| Memory | `packages/agent/src/memory-store.ts` (D-137) | Built in, Supermemory, Honcho |
| Computers | `packages/sandbox` (D-139) | Docker, hosted providers |
| Paid data, search, secret store, password managers, audit forwarding | D-138, D-179, D-145, D-128, D-146 | One interface each |
| Cards in replies | A2UI basic catalog plus Casama's own cards (D-086, D-310, D-322, D-337) | Fixed list, drawn natively |

## 2. What the format and the rules allow

### 2.1 Agent Plugins 1.0

- **Two portable kinds only.** The specification says version 1 "defines exactly two component
  types: skills and MCP servers", and that commands, hooks, agents, rules and LSP servers stay out
  until their formats converge.
- **App-specific data has a named place.** In `plugin.json` it goes under `extensions`, keyed by a
  reverse-domain name the app controls (`com.casama`). Each value must be an object. A client must
  ignore names it does not implement, without validating them.
- **A folder too.** The same name is a top-level folder for file-based extension data (§8.2 of the
  specification). The specification gives such folders no portable meaning, which is the point:
  other apps skip `com.casama/`, Casama reads it.
- **Nothing about dependencies, bundles, registries or settings.** Not defined. Secrets are
  explicitly left to the client. Updates: `version` should be semantic and may be used for update
  checks; no update procedure is given.
- **Who is behind it:** the homepage names a steering committee with maintainers from Amazon,
  Cursor, Microsoft, OpenAI and Vercel. No list of supporting clients was found.

What follows for Casama: a pack built as a plugin with a `com.casama/` folder is inside the
standard, loses nothing in other apps, and commits us to nothing the standard might later
contradict, as long as `com.casama/` is treated as ours to version.

### 2.2 The no-WebView rule

Oliver ruled out web panels inside the app, plugin panels included (2026-11-10). Plugin UI is data
drawn by Casama's own native widgets. MCP's own UI extension renders HTML in a frame (not
re-checked for this plan), so it is not an option; §7 F uses A2UI templates instead.

### 2.3 App stores

Nothing in this plan downloads code that runs inside the app. Packs carry text and settings; looks
and cards are data drawn by widgets that ship in the app; tool servers run on the bot's computer or
a remote host. Apple's and Google's wording on downloaded code was **not** re-read for this plan,
and nothing here changes what already ships (plugins, gallery looks).

### 2.4 GitHub

Previews read GitHub through `GitHubReader` (`GITHUB_API_URL`). GitHub limits unauthenticated API
calls to 60 an hour per address. One production server previewing packs for everyone can reach
that. Whether today's reader sends a token was not checked; Phase 2 adds a server token setting if
it does not (§14).

## 3. Goals and what this is not

**Goals**

1. One sentence a contributor can hold: *"Anything you can add to Casama, you can ship as a
   plugin."*
2. One repo for a whole idea: tools, the skill that explains them, a starter bot, a routine, the
   apps to connect, a look.
3. One install: a person sees everything a pack adds before anything is created, picks what they
   want, answers its questions, and connects what it needs.
4. A setup made in Casama can be handed to someone else as a pack, with nothing private in it.
5. Reuse: the gallery's formats, checkers, wizard, policy and tracking. No second ecosystem.

**This is not**

- A microkernel. Core features do not become plugins, and built-in lists are not rewritten.
- A way to run someone's code on Casama's servers or inside the app.
- A paid marketplace (a SPEC non-goal, and "Paid items" is "Not done" in D-315).
- A replacement for bot templates or workspace files. Both stay as they are.

## 4. Principles

1. **Kinds are fixed, items are open.** Casama knows a short list of kinds and draws or runs each
   natively. A new *kind* needs a release. A new *item* of a kind never does.
2. **The plugin is the only package.** No second package format. A pack is a plugin with a
   `com.casama/pack.json`.
3. **Code runs in two places only:** the bot's computer and remote hosts. Never the server, never
   the app.
4. **Same checker everywhere.** Developer's machine, the gallery's CI and the server run the same
   `@casama/domain` checks, so what passed review is what installs.
5. **Preview before anything exists.** Nothing is created, connected or scheduled until the person
   has seen it and said yes. What was reviewed is what installs (pinned commit).
6. **Widening asks, narrowing doesn't** (D-242). A bot can suggest a pack with a card. It can
   never install one.
7. **A pack never raises its own trust.** Its bots start at "ask before risky actions" at most, as
   gallery bots do. Its apps get no privileges built-in apps have.
8. **What you changed stays yours.** Updates and removal never overwrite or delete something the
   person edited.
9. **Nothing shipped breaks.** Build 27 parses some lists strictly (see the AppCategory lesson). New
   data goes in new endpoints, new files and optional fields, never as a new value in a list an
   installed app already reads.
10. **Private things never leave.** Exports carry no keys, tokens, secrets, chats, memories, About
    you or model choices.

## 5. Words

| Word | Meaning | Where it shows |
|---|---|---|
| **Kind** | A type of thing Casama understands: skill, tools, app, bot, routine, look | Docs only |
| **Plugin** | The package: a folder with `plugin.json`. To a person: something that adds tools to a bot | Bot settings → Plugins; developer docs |
| **Pack** | A plugin that brings a setup: bots, skills, routines, apps, looks, and maybe tools | Gallery → Packs |
| **Starter set** | A pack made only of gallery items. Shown on the Packs shelf (decision 3) | Gallery → Packs |
| **Tools** | A plugin's MCP servers, in plain words | Pack and plugin pages |
| **Reviewed** | Listed in the gallery at an exact commit a maintainer read | Badge |
| **Not reviewed by Casama** | Installed from a link | Label on the preview |

No "extension", "add-on", "bundle" or "module" anywhere. In the app, "pack" and "plugin" only.

## 6. The inventory: what is a plugin, what could be, what should not

| Thing | Today | Can a plugin carry it after this plan? | Why |
|---|---|---|---|
| **Skills** | Plugin, gallery, GitHub, bot-made | Yes (already) | The portable kind |
| **Tool servers (MCP)** | Plugin; a bot can add one (D-242) | Yes (already) | The portable kind |
| **Apps** (a vendor's hosted MCP server with sign-in) | Gallery data; 33 built in | **Yes, new** (`com.casama/apps/`) | Lets a plugin bring OAuth sign-in, which `mcp.json` cannot. Gallery-app limits apply |
| **Starter bots** | Gallery data; 26 built in; `casama.bot` files | **Yes, new** (`com.casama/bots/`) | Same document as the gallery's |
| **Routines** | Gallery ideas; workspace files | **Yes, new** (`com.casama/routines/`) | Same document as the gallery's |
| **Looks** | Gallery data; built-ins compiled in | **Yes, new** (`com.casama/looks/`) | Applied on the device, as today |
| **Install questions and plain settings** | Gallery `inputs`; plugins have secrets only | **Yes, new** | One question list for the pack; settings for tool servers (§7 F) |
| **Starter sets** | Gallery pointers | Yes: a pack's `includes` | Sets become the simplest packs |
| **Empty-chat starters** | Field on a bot | Yes, with the bot | |
| **Cards for a plugin's tools** | Fixed native cards | **Later, own mini-plan** (§7 F) | Needs an A2UI template format; native only |
| **Bot rules and knowledge sources** | Per bot, in the app | Later, with the bot (§7 F) | Only rules that narrow; sources cost credits, so shown first |
| **Coding agents** | 4 in code | **No new kind** | A skill that says how to run the CLI does the job today. Code keeps the ones with summaries, diffs and browser hand-off |
| **Model providers** | Code, plus `openai_compatible` | No | Already has its declarative door. Prices and billing must stay in core |
| **Chat apps** | 12 adapters in code | **No** | Webhook code on our servers, with signing secrets. Breaks principle 3 |
| **Memory, computers, search, paid data, secret stores, password managers, audit forwarding** | Adapters in code | **No** | Server adapters for self-hosters and `ee/`: compile-time, reviewed |
| **Core tools** (computer, browser, sites, voice, calls) | Code | No | They are the product |
| **Languages** | English only (D-038) | No | Translations are compiled into the app |
| **Hooks, commands, sub-agents** | None | No | The standard left them out until formats settle. Skills are Casama's commands (the `/` picker); bots are its agents |

**Built-in lists stay.** `APP_CATALOG`, `BOT_TEMPLATES`, bundled `skills/` and `client/looks/` are
the offline copy and the home of privileged entries (Google's shared client, admin-registered OAuth
clients, Composio routing, inbox scopes: D-239). Moving them is churn with real risk to installed
apps and no gain to anyone outside (decision 15).

## 7. The full feature set

### A. The package

1. A plugin may hold a `com.casama/` folder with `pack.json`, `bots/`, `routines/`, `apps/` and
   `looks/`. Each file is the gallery's document for that kind, plus a `name`.
2. `pack.json`: icon, a one-line summary, `inputs` (up to 6 questions, the gallery's shape),
   `needs` (apps to connect first), `includes` (gallery items by type and id, and plugins by link
   and exact commit), `examples`, which skills are for the whole workspace, and a `format` and
   `version` of its own.
3. A bot names the skills (folders in `skills/`), routines and tools it gets. Skills no bot names
   go to the whole workspace. Tools no bot names go to every bot the pack brings.
4. Limits per pack: 5 bots, 30 skills, 20 routines, 12 apps, 12 looks, 12 includes, 6 inputs,
   inside the plugin's 400 files and 10 MB.
5. `casama-plugin-check` checks all of it and prints what a person will see at install.
6. A plugin without `com.casama/pack.json` behaves exactly as today.

### B. Getting a pack

7. **From a link:** Gallery → Add from a link. Any GitHub repository or folder link.
8. **Add to Casama:** `casama.ai/open/pack?url=…` opens the installed app on the preview (D-326),
   with a badge authors can put in a README.
9. **From the gallery:** the Packs shelf lists reviewed packs (directory entries at a pinned
   commit) and starter sets. Search, tags, picks and "works with what you have" cover them.
10. **From a bot:** `gallery.search` and `gallery.suggest` include packs; `plugins.suggest` opens a
    pack's preview when the link is a pack. A card, never an install.
11. **From a file or share link** (Phase 5).
12. **Private repositories:** through a workspace `GITHUB_TOKEN` secret, as skills do (decision 14).

### C. The preview and the install

13. One page, before anything exists: who made it, where it lives, the exact commit, Reviewed or
    "Not reviewed by Casama".
14. Everything it adds, grouped by kind, each with a checkbox:
    - bots: name, what it's for, the full instructions one tap away, how much it asks;
    - skills: description; "runs scripts on the bot's computer" when it has any;
    - routines: the schedule in plain words, which bot, the full instructions;
    - apps: name, **host**, how you sign in, what a bot can do with it;
    - tools: each server's command or address, hosts, the secrets and settings it needs;
    - looks: a preview.
15. **What it can reach**, worked out by the checker, not claimed by the author: runs code, needs
    a computer, hosts it talks to, how many scheduled runs a week. The author's own `access` words
    show under it as theirs.
16. The wizard starter sets use: questions, then what it needs (connect apps one at a time, skip
    allowed), then secrets, then done. Looks end with "Use this look on this device?".
17. Per-item results, as set install gives: installed, waiting for approval, skipped, failed, on
    this device.
18. Each kind keeps its own permission rule. What the person may not add is listed as "needs an
    admin" and goes through gallery approvals.
19. The workspace's gallery policy applies to packs **and to plugins from a link** (new). "Only
    allowed" lists can name a repository.
20. Plan limits apply as for anything else (`max_bots` and the rest). Nothing is half-installed
    silently: what did not fit is in the results.
21. Install, update, removal, export and sharing are audited.

### D. Living with a pack

22. Gallery → Installed lists packs with what each added.
23. **Check for update:** the diff by kind (added, changed, removed; new hosts, secrets, schedules;
    instructions as a line diff). An update that reaches further asks first.
24. **Your edits win:** an item you changed since install keeps your version, listed as such, with
    "Use theirs" per item.
25. **Remove:** tools, secrets, and untouched skills and routines go. Bots stay unless you tick
    "Also delete the bots this pack created" (decision 7). App connections you made stay. Edited
    items stay, detached.
26. A bot's Plugins page shows tools that came with a pack ("From the pack …").
27. A pack whose repository disappears keeps working: its files were stored at install.

### E. Share as pack

28. Workspace settings → Share as pack: pick bots (each brings its instructions, starters, skills,
    routines, the apps it uses by name, and its plugins by link and commit), workspace skills, and
    this device's look.
29. Never included: keys, tokens, secret values, chats, memories, About you, knowledge contents,
    the model choice, member names.
30. A check before export: skill files and instructions are scanned for the workspace's own secret
    values (the `Redactor` in `packages/agent/src/redact.ts` already knows them) and for common key
    shapes (new), with a warning and the line.
31. Out as: a `.zip` of the pack folder; a link (signed-in viewers, 30 days, like bot shares);
    "Submit to the gallery" (the existing submission route opens the pull request).
32. Install from a pack file, in the app and with the CLI.
33. A link to a shared pack can be reported and taken down like other shared links (D-281, D-301).

### F. More for plugins

34. **Plain settings:** `extensions["com.casama"].settings`, shaped like secrets (name, label,
    type, default, the server, and the environment variable or header it fills), stored in the
    connection's config, editable later.
35. **Tools on your own computer:** a plugin's stdio servers through the desktop companion
    (D-096), the "Not yet" of D-121. Only for the person whose computer it is (D-131's rule).
36. **Cards for a plugin's tools:** a plugin declares an A2UI template per tool
    (`com.casama/cards/<tool>.json`); the tool's result fills it; the app draws it with its native
    catalog. Gets its own short plan before code (decision 10).
37. **Rules and knowledge with a bot:** a pack's bot may bring rules that narrow (ask, hand off,
    block) and website or GitHub knowledge sources, shown with their cost before install.

### G. For developers and docs

38. `docs-site/develop/packs.md`, an updated `plugins.md` and `gallery-format.md`.
39. `examples/hello-pack`: hello-plugin plus a bot, a routine, an app and one question.
40. `casama init --pack`, `casama packs preview|install|list|update|remove|export`.
41. TS and Dart client helpers, MCP tools, the agent kit's `casama-plugin` skill, `llms.txt`.
42. The GitHub Action checks packs with no change to a workflow.

### H. First-party packs

43. Three real packs published in the directory to prove the format and seed the shelf
    (decision 12).

## 8. What we're not shipping, and why

| Not shipping | Why |
|---|---|
| Plugin code on the server or in the app | Principle 3; the no-WebView rule |
| Chat apps, model providers, memory, computers, search as plugins | Server adapters with secrets and billing (§6) |
| Coding agents as a kind | A skill covers it; one more format to keep for little gain |
| Hooks, commands, sub-agents | Outside the standard's version 1; no settled format |
| Paid packs | SPEC non-goal. Gallery rewards (D-315) are the incentive |
| Packs that include packs | One level only: review stays possible |
| Memories in a pack | Personal by nature. One bot's memories can still go in a bot template, by choice |
| Rewriting built-in lists as packs | Churn and risk, no outside gain (decision 15) |
| Custom bot pictures in packs | Moderation cost. The shipped mascots only, as gallery bots |
| Language packs | English only; translations are compiled in |
| Star ratings and reviews | Same reasons as D-315 |
| A bot installing a pack by itself | Widening always asks (D-242) |

## 9. How it works

### 9.1 The folder

```text
invoice-chaser/
├── plugin.json                     Agent Plugins 1.0, unchanged
├── mcp.json                        optional tool servers, unchanged
├── skills/
│   ├── dunning/SKILL.md            a bot's skill
│   └── house-style/SKILL.md        a workspace skill (named in pack.json)
└── com.casama/
    ├── pack.json
    ├── bots/invoicer.json
    ├── routines/weekly-chase.json
    ├── apps/acme-billing/app.json  (+ logo.svg)
    └── looks/themes/ledger.json
```

`com.casama/pack.json`:

```json
{
  "format": "casama.pack",
  "version": 1,
  "icon": "receipt",
  "summary": "Chases unpaid invoices and reports every Monday.",
  "inputs": [
    { "key": "company", "label": "Your company's name", "type": "text", "default": "my company" },
    { "key": "time", "label": "When should the report arrive?", "type": "time", "default": "09:00" }
  ],
  "needs": { "apps": ["gmail"] },
  "includes": [{ "type": "skill", "id": "weekly-report" }],
  "workspace_skills": ["house-style"],
  "examples": ["Who hasn't paid this month?"]
}
```

`com.casama/bots/invoicer.json` is the gallery's `bot.json` with a `name`, and names instead of
inline copies:

```json
{
  "name": "Invoicer",
  "description": "Chases unpaid invoices politely.",
  "category": "work",
  "icon": "receipt",
  "mascot": "cool",
  "persona": "You chase unpaid invoices for {{company}}. Be polite and brief...",
  "starters": ["Who hasn't paid this month?"],
  "autonomy": "ask_risky",
  "skills": ["dunning"],
  "routines": ["weekly-chase"],
  "tools": ["notes"]
}
```

`com.casama/routines/weekly-chase.json` is the gallery's `routine.json` with a `name`
(`instructions_md`, `schedule_cron`, and `{{time.minute}} {{time.hour}}` as today).

Author, license, homepage and version come from `plugin.json`, so they are stated once.

### 9.2 Checking

`checkPack(files)` in `@casama/domain`, called by `checkPlugin` when `com.casama/pack.json` exists:

- runs `checkBotDocument`, the routine and app checkers and the look checkers on each file;
- resolves every name a bot uses against `skills/`, `com.casama/routines/` and `mcp.json`;
- applies the gallery's input rules (every placeholder has an input, every input is used);
- applies the gallery-app limits to pack apps: public https host, no Google category, no
  admin-registered client, no Composio routing, no inbox scopes, no reserved headers;
- **refuses an app whose name matches a built-in or gallery app unless its host matches too**, so a
  pack cannot dress a stranger's server as "Gmail";
- caps a bot's autonomy at `ask_risky`;
- works out the reach summary (item 15);
- a broken item is skipped with a warning and the rest still installs, as plugins do today. A
  broken `pack.json` means the folder is treated as a plain plugin, with a warning.

The gallery checker (`gallery/check.mjs`) and `packages/plugin-check` call the same function.

### 9.3 Data model

- **`packs`** (new, per workspace): name, version, description, source (`github`, `gallery`,
  `share` or `upload`, with owner, repo, path and ref), `commit_sha`, the checked summary, the
  answers to its questions, who installed it and when. `unique (org_id, name)`. RLS by membership,
  `allow_worker`, pgTAP.
- **`pack_files`** (new): the package's files, for diffs and for bots added later.
- **`gallery_links.pack_id`** (new, nullable): one row per thing a pack made, as today per gallery
  item, plus a **content hash at install**, which is how "you edited this" is known.
- **`plugins.pack_id`** (new, nullable, cascade): a pack's tools are installed through the existing
  per-bot plugin path, one `plugins` row per bot that gets them. Nothing in the worker, computerd
  or the supervisor changes.
- **`pack_shares`** (Phase 5): a hashed token, an expiry, the pack as stored files.

The existing `plugins` table keeps `bot_id not null`. Making plugins workspace-wide was considered
and left out: it touches the unique key, the RLS policies and the computer sync for no gain a pack
does not already give.

### 9.4 API (contracts first, D-002)

- `POST /v1/packs/preview` `{ org_id, url, commit? }` → the checked pack and the commit.
- `POST /v1/packs/install` `{ org_id, url, commit, items?, inputs, secrets, bot_id? }` → per-item
  results and `missing`, the set-install shape; 202 when the policy says ask first.
- `GET /v1/orgs/{id}/packs`, `GET /v1/packs/{id}`.
- `GET /v1/packs/{id}/update` (the diff), `POST /v1/packs/{id}/update` `{ commit, take_theirs? }`.
- `DELETE /v1/packs/{id}?bots=keep|delete`.
- Phase 5: `POST /v1/orgs/{id}/packs/export`, `POST /v1/orgs/{id}/packs/share`,
  `GET /v1/pack-shares/{token}`, `POST /v1/packs/import` (a file).
- `POST /v1/plugins/preview` on a pack answers with an optional `pack` summary. A newer app sends
  the person to the pack preview. **Build 27** ignores the field and installs the plugin part
  (skills and tools) on that bot, as it always did.
- `plugins.json` records gain an optional `pack` summary, worked out by the gallery checker from
  the pinned commit, so the shelf can show what is inside from the list alone (D-189).
- The Packs shelf is a new list (`GET /v1/gallery/packs`: sets and directory packs). `sets.json`
  and `GET /v1/gallery/sets` stay for installed apps.

### 9.5 Install, step by step

1. Fetch the folder at the commit (existing reader), run `checkPlugin` and `checkPack`.
2. Check the workspace's gallery policy for the pack as a whole, then per item.
3. Fill placeholders from the answers.
4. In the order set install uses (bots, skills, plugin part, apps, routines): create each item
   through `installGalleryItem`'s code path for its kind, recording a `gallery_links` row with
   `pack_id` and the content hash.
5. For each bot that gets tools: the existing plugin install, with `pack_id`.
6. Return per-item results. The app then walks `missing` (apps to connect) and offers the look.

One transaction per item, not per pack: a failed app must not undo a created bot. The results say
exactly what happened.

### 9.6 In the app

Native Flutter throughout, built from what the gallery already has.

- **Gallery → Packs:** the shelf, pack detail (grouped contents, reach, source, badge), the wizard
  (`gallery_install.dart`), Add from a link.
- **Gallery → Installed:** packs with Update and Remove.
- **Bot settings → Plugins:** unchanged, plus "From the pack …" on tools a pack brought.
- **Workspace settings → Share as pack** (Phase 5).
- **Admin → gallery rules:** repositories on the allow and block lists.

Any Flutter build or `flutter run` for these needs Oliver's yes each time. Tests and analyze do not.

### 9.7 Self-hosted servers

Packs work with the gallery off: a link is enough. `GALLERY_SOURCES` catalogs can list packs. A
company can keep a private pack repository and restrict the workspace to it. Nothing here is in
`ee/`.

## 10. Security and privacy

| Risk | What stops it |
|---|---|
| Code from a stranger | Runs only on the bot's computer or its own host, behind the egress proxy. Unchanged from D-121 |
| Instructions from a stranger (a bot or routine told to leak or spend) | Full text shown before install; autonomy capped at ask-risky; action rules still apply; each routine ticked by the person, with its schedule |
| Scheduled runs that burn credits | Schedules and runs per week on the preview; routines from a pack that is not reviewed start **off** (decision 6); plan and daily limits apply |
| A fake app that collects sign-ins | Host shown large; built-in and gallery names protected (§9.2); ids namespaced `<pack>.<id>`; gallery-app limits |
| Secrets in a pack | The format forbids them in `env` and headers; values go to Vault only through declared secrets; exports are scanned |
| A changed repository after review | Pinned commit; updates show the diff; more reach asks first |
| Members adding things admins don't want | Gallery policy now covers every link install |
| A shared pack with something harmful | Report and takedown; share links expire; viewers must be signed in |
| Private data leaving in an export | A fixed include list (§7 E), not an exclude list |
| Counting people | Installs are counted the D-315 way: aggregate, hashed, shown only from 10 people. No new telemetry |

## 11. Cost

No new paid service. Storage is a few megabytes per pack at most, in Postgres like plugin files.
GitHub reads are free within its limits (§2.4). Gallery rewards already budgeted in
`docs/COSTS.md` extend to packs at the same three tiers (decision 13); that line is updated in
Phase 4. Nothing else to add to `docs/COSTS.md`.

## 12. Phases

Each phase ends merged on a branch and tested. Deploying to production, app builds and store
uploads are separate asks, as always.

| Phase | What | Done when |
|---|---|---|
| **1. The format** | `checkPack` in `@casama/domain`; `packages/plugin-check` and `gallery/check.mjs` learn packs; `examples/hello-pack`; `docs-site/develop/packs.md` | Domain tests cover every rule in §9.2 and each refusal; `casama-plugin-check examples/hello-pack` passes and prints the install summary; hello-plugin still passes untouched; docs build |
| **2. Install on the server** | Contracts, `packs`, `pack_files`, the two new columns; preview, install, list, remove; gallery policy on packs and on plugin links; audit; GitHub token setting if needed | API tests with the fake GitHub and fake computer: hello-pack installs end to end, questions fill in, a member gets "needs an admin", the policy blocks and asks, removal leaves only kept bots and edited items, a pack-shaped link through the old plugin route still installs the plugin part; pgTAP for every new table; `pnpm test` and `pnpm --filter @casama/db test:pgtap` green |
| **3. In the app** | Packs shelf, detail, wizard, Add from a link, Installed, open links, policy screen | Widget tests for each screen and each per-item result; `flutter analyze` clean; a live check on the web app against the local stack (needs a yes for `flutter run`) |
| **4. Updates and the shelf** | Update diff, edits kept, reach-grew ask; directory entries with pack summaries; starter sets on the Packs shelf; three first-party packs; rewards | API tests: an update keeps an edited routine and replaces an untouched one, new hosts ask, a removed bot is detached not deleted; the gallery checker writes a byte-stable `plugins.json`; the three packs install on the local stack |
| **5. Share as pack** | Export, the key scan, zip, share link, import from a file, submit to the gallery, private repositories | API tests: an export of two bots re-imports in another workspace with nothing private in the files (asserted by a list of forbidden strings), a planted key is caught, links expire, reports reach the queue |
| **6. More for plugins** | (a) plain settings; (b) tools on your own computer; (c) rules and knowledge with a bot; (d) cards for tools, after its own short plan | Each lands alone with its tests. (b) needs a real Mac run by Oliver. (d) does not start before decision 10 |
| **7. The rest** | CLI, TS and Dart helpers, MCP tools, agent kit, `llms.txt`, changelog, the `DECISIONS.md` entry, `docs-site` pass | Every suite green; `pnpm gen` clean; a pack built with only the agent kit's skill passes the checker |

Phases 1 to 4 are the product. 5 is the content-pack promise for people who are not developers. 6
and 7 can follow in any order.

## 13. Decisions for Oliver

| # | Question | Default if you say nothing |
|---|---|---|
| 1 | The principle: "everything you add is a plugin; the core is not" | Yes, written into `DECISIONS.md` and the developer docs |
| 2 | One package (a plugin with a `com.casama/` folder) or a separate pack format | One package |
| 3 | Words: a **Packs** shelf in the gallery that also holds today's starter sets; **Plugins** stays under a bot | Yes |
| 4 | Packs from any GitHub link on Casama Cloud, labelled "Not reviewed by Casama" | Yes. Plugins from any link are allowed today; workspaces can restrict |
| 5 | A pack's bots start at "ask before risky actions" at most | Yes, as gallery bots |
| 6 | Routines from a pack that is not reviewed start switched off | Yes. Reviewed packs start them as ticked |
| 7 | Removing a pack keeps the bots it created unless you tick otherwise | Yes |
| 8 | Memories never go in a pack | Yes |
| 9 | Pack share links: signed-in viewers, 30 days | Yes, as bot shares |
| 10 | Cards for a plugin's tools | Later, after its own short plan. Not in the first four phases |
| 11 | Coding agents and model providers as kinds | No |
| 12 | The three first-party packs | Founder kit rebuilt as a real pack with its own bot; a developer pack (code review, a GitHub app, a pull-request routine); Meetings handled |
| 13 | Gallery rewards for packs | Yes, the same three tiers |
| 14 | Packs and plugins from private repositories, through a workspace `GITHUB_TOKEN` secret | Yes, in Phase 5 |
| 15 | Rewrite built-in apps and starter bots as data files or packs | No |
| 16 | Tools on your own computer (item 35) | Phase 6, with your Mac check |
| 17 | Paid packs | No |

## 14. Risks

| Risk | How it's handled |
|---|---|
| The standard adds agents, rules or settings later, and our folder overlaps | `com.casama/` carries its own `format` and `version`. When the standard gains a kind, Casama reads the standard's place first and ours as the fallback |
| The fact about the client folder was read through an agent, not first-hand | Re-read §8.2 of the specification before Phase 1. If wrong, the same files move under `extensions["com.casama"]` as inline JSON, with a lower size cap |
| Two installers drift (gallery items and packs) | Packs call the per-kind code `installGalleryItem` already uses; no second copy |
| A strict list in build 27 meets a new value | New endpoints and optional fields only; a contract test replays build 27's parsers against every changed response |
| GitHub's limit of 60 unauthenticated calls an hour | A server token setting; previews cached by commit (a commit never changes) |
| Review load on Oliver | Link installs need no review. The directory stays small and curated; in-app submissions already arrive as pull requests |
| Low-quality or hostile packs | Labels, the preview, the caps in §10, reports, workspace policy |
| A pack with three bots runs one stdio server on three computers | Shown on the preview ("runs on 3 computers"). Idle stops already exist |
| Scope: seven phases | Stop after Phase 4 and it is still a whole feature |
| Another format to explain | It is not one. The docs present a pack as "a plugin with a `com.casama` folder", on the plugin page |

## 15. How we'll know it worked

Telemetry stays off, so these come from what the server already counts (D-315).

- A developer ships tools, a skill, a bot and a routine from **one repository and one link**.
- The agent kit can scaffold a pack that passes the checker without a human edit.
- Packs in the directory beyond our own three within a month of launch.
- Share of new workspaces that install a pack in the first session, and whether those reach a
  finished run sooner than the rest.
- Packs still in use after 14 days, against starter sets today.
- No support ticket that says a pack changed or removed something the person had edited.

## Sources

Read on 2026-11-17 through a fetch agent; quotations in §2.1 are as that agent reported them.

- Agent Plugins, home: https://agent-plugins.org/
- Agent Plugins specification 1.0.0: https://agent-plugins.org/specification
- Manifest schema: https://agent-plugins.org/schemas/1.0.0/plugin.schema.json
- MCP schema: https://agent-plugins.org/schemas/1.0.0/mcp.schema.json

Not read for this plan: the specification's governance file and repository, MCP's UI extension,
Apple's and Google's rules on downloaded code, GitHub's rate-limit page (the 60-an-hour figure is
from memory and is checked in Phase 2).

In this repository: `docs/DECISIONS.md` (D-086, D-096, D-104, D-110, D-121, D-124, D-131, D-160,
D-201, D-239, D-241, D-242, D-315, D-326), `docs/GALLERY-V2.md`, `docs-site/develop/plugins.md`,
`docs-site/develop/bot-templates.md`, `docs-site/develop/workspace-files.md`, `SPEC.md` (Plugins;
non-goals).

## Progress (2026-11-17)

| Phase | State |
|---|---|
| 1. The format | Done: `checkPack`, plugin-check (the gallery checker needs no change: directory entries stay pointers and the server reads the pack), `examples/hello-pack`, `docs-site/develop/packs.md` |
| 2. Install on the server | Done: preview, install, list, remove, settings, link and pack policy, approvals, audit; pgTAP |
| 3. In the app | Built (`client/lib/features/packs/`): shelf, pack page, wizard, Add from a link or file, Installed, update and remove, open links, plugin settings, gallery rules. 13 widget tests; `flutter analyze` clean; no live check yet (needs a yes for `flutter run`) |
| 4. Updates and the shelf | Done: diff, edits kept, reach-grew ask, `GET /v1/gallery/packs`, three first-party packs in `packs/`, rewards |
| 5. Share as pack | Done on the server: export, key scan, share links, reports, install from files, private repositories. The app reads and saves `.zip` files. Not done: Submit to the gallery |
| 6. More for plugins | (a) settings, (b) tools on your own computer (D-344; a real Mac run is left), (c) rules and knowledge and (d) cards for a plugin's tools (D-345, docs/PLUGIN-CARDS-PLAN.md) done |
| 7. The rest | Done: CLI, TS and Dart helpers, MCP tools, agent kit, `llms.txt`, changelog, D-343 |

Changes from the plan:

- The shelf's contents are worked out by the server and cached by commit: the gallery checker
  doesn't fetch GitHub.
- An item the person may not add (workspace skills for a member) is skipped with a note, not sent
  for approval by itself. When the workspace's gallery rules need an admin, the whole install waits.
- A plugin's tools go to every bot of the pack that names any tool (servers aren't split per bot).
- A bot's rules and knowledge are created only with a new bot, not on update.
- `casama.ai/open/pack` links (item 8) route in the app; the web page and iOS universal-link paths for `/packs/share/*` are not added.
- Share as pack lives in workspace settings; no button on a bot's page links to it yet.

Left for Oliver:

1. A live check of the app screens on the web app against the local stack (`flutter run`, needs a yes): shelf, a real GitHub install, Connect and Use on the result, Add from a file, open links, Save as file and the share sheet, update and remove (including the 202 case), phone width and dark mode.
2. Apply `supabase/migrations/20270202100001_packs.sql` to the local dev database (migration up only).
3. After merging and pushing: list the three first-party packs in the gallery's `plugins.json` at
   their real commit, then re-sync casama-gallery.
4. Production deploy, and app builds, when wanted.
5. Tools on your own computer (item 35, D-344): a run on a real Mac with the desktop app.
6. ~~Decision 10: whether to build cards for a plugin's tools~~ Built (D-345, docs/PLUGIN-CARDS-PLAN.md); a live look in the app is still to do.
