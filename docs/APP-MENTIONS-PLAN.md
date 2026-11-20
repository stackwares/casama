# @mention an app in chat: plan

Status: **done** (D-434; written 2026-11-19; implemented Phases 0–3 on 2026-11-20; live, confirmed by Oliver 2026-11-20).

Recorded as decision **D-434** in `docs/DECISIONS.md`.

## 0. Summary

People type `@` in the composer and pick a connected app: `@Gmail find the invoice from Acme`. The
message keeps the app as a pill with its logo. The run starts with that app's tools already loaded
and a one-line note that the person pointed at it.

Three things get better:

1. **The bot stops guessing.** "Check my email" could mean Gmail, Zoho Mail or Outlook.
2. **One model step is saved** on bots with many tools. Today the bot reads the tool index, calls
   `tools.load`, then calls the tool (D-106). With a mention the tools are there on the first step.
3. **Connecting is easier to find.** The same menu offers apps that aren't connected yet.

A mention is a hint and a preload. It never grants access, never forces a tool call and never skips
an approval.

Not in this plan: mentioning files, memories, people or built-in tool groups (`@Browser`). See §12.

## 1. What exists today

| Piece | Where | What it does |
|---|---|---|
| Bot mentions | `packages/domain/src/mentions.ts` `parseMentions`, D-118 | `@Name`, `@everyone` in group chats wake bots. Text only, longest name first. |
| Mention picker | `client/lib/features/groups/group_chats.dart` `MentionController`, `MentionPicker` | Chips above the composer in group chats; Tab, Enter, arrows, Esc. Direct chats have no `@` menu. |
| Mention pills | `client/lib/features/chat/widgets/mentions.dart` `MentionScope` | Draws `@Name` as a pill with the bot's avatar; only members' names count. |
| `/` skill picker | `chat_screen.dart` `_SkillPicker`, D-104 | Picked skills go as `SendMessageRequest.skills` (max 5), stored as `{type: "skill", name}` parts, read by `partsSkills` in `packages/agent/src/run.ts`. |
| Lazy tools | `packages/agent/src/lazy-tools.ts`, D-106 | Over 30 tools: core tools plus an index. Groups are `mcp.github`, `composio.<name>`, `browser`… |
| Remembered groups | `rememberedTools`, `conversations.tool_groups` | A run starts with up to 6 groups (6,000 tokens) the conversation used before. |
| Connections | `Integration` (`packages/contracts/src/autonomy.ts`), kinds `mcp`, `openapi`, `composio`, `pipedream`, `local_mcp`, `a2a` | Tool names are `<kind>.<name>.<tool>` (`integrationToolName`). `app_id` links to the catalog app for the logo. |
| App logos | `client/lib/features/integrations/app_logo.dart` `AppLogo` | Bundled marks, gallery `logo_url`, or an initial. |
| Empty-chat app tiles | `client/lib/features/chat/widgets/app_tiles.dart` | Already joins catalog, integrations, the bot's attached ids and hub apps. The picker needs the same join. |

One wrinkle: a Composio or Pipedream hub is **one** integration holding many apps. Its lazy group is
`composio.<name>` for all of them, and tools are named by toolkit (`gmail_send_email`). So "Gmail
through Composio" is a tool-name prefix inside a group, not a group.

## 2. What a mention means

An **app** here is anything a bot reaches through a connection:

- an integration attached to the bot (`mcp`, `openapi`, `local_mcp`, `a2a`);
- one app inside a Composio or Pipedream hub (a toolkit);
- a plugin's tools (naming to confirm in Phase 0).

Rules:

- **It's inline text plus a structured part.** The message text carries `@Gmail`, so it reads right
  in history, in copies, in edits and in chat apps. The stored message also carries
  `{type: "app", integration_id, toolkit?, label}`, so the pill and the run don't depend on
  matching names later (the app may be renamed or removed).
- **Pills come from the message's own parts.** A message draws `@Gmail` as a pill only when its
  parts include an app with that label. A stray "@gmail" in pasted text stays plain.
- **Typed without picking still works.** The server resolves exact `@name` matches against the
  apps the answering bot can use and adds the parts itself. The client's `apps` field is there for
  precision (two Gmail accounts, a hub toolkit). §11 choice 2.
- **Max 3 apps per message.**
- **No access change.** A bot that isn't allowed the app doesn't get it. Tool risk, approvals,
  autonomy and Full access (D-394) are untouched.

## 3. Server

### 3.1 Contracts (`packages/contracts`)

- `SendMessageRequest.apps`: optional, max 3, each `{ integration_id: Uuid, toolkit?: string }`.
- Message part `{ type: "app", integration_id, toolkit?, label, app_id? }`. `app_id` is the catalog
  id, for the logo.
- Regenerate `openapi.json`, the TS client (`packages/client`) and the Dart client
  (`dart/casama_api`).

### 3.2 Resolving (`packages/domain/src/app-mentions.ts`, new)

`parseAppMentions(text, apps)` works like `parseMentions`: longest label first, not inside a word or
an email address, case-insensitive. It matches an app's display name (`Gmail`, `Google Calendar`)
and its integration name (`google_calendar`).

In `POST /v1/conversations/{id}/messages` (`apps/server/src/api/routes/bots.ts`):

1. Load the apps the answering bot can use (attached integrations with status `ok`, plus connected
   hub toolkits).
2. Take the client's `apps`, drop any the bot can't use.
3. Add text matches not already covered.
4. Store up to 3 as parts, next to the skill parts.

Edit and resend (`/messages/{id}/edit`) resolves again from the new text, the way it keeps picked
skills today.

### 3.3 The run (`packages/agent/src/run.ts`, `lazy-tools.ts`)

- `partsApps(content)` beside `partsSkills`.
- Each app maps to a load target: a group (`mcp.github`) or, for a hub toolkit, the tool names in
  the hub's group that start with `<toolkit>_`.
- **Lazy run:** the targets load before the remembered groups, within their own budget (default
  8,000 tokens across the mentioned apps). An app over budget isn't loaded; the note names its group
  so the bot loads what it needs by name. The loaded list stays sorted by name, so the same
  mentions make the same tool list.
- **Not a lazy run** (30 tools or fewer, or check-ins): every tool is already sent; only the note
  applies.
- **The note** is added to the message the model sees, not to the stored text:
  `The person pointed at these apps for this message: Gmail (mcp.gmail). Use them if the request
  needs an app.`
- **Remembering:** unchanged. A group joins `conversations.tool_groups` only when the run calls it.
- **Prompt cache:** adding a group at the start changes the tool list, which costs the same cache
  miss `tools.load` would have cost mid-run, minus the extra model call. Never worse than today.

### 3.4 Group chats

- An app mention wakes nobody. Who answers follows D-118 as before.
- Every woken bot gets the mention if it can use the app.
- If no woken bot can, the run records a `notice` run event (new code `app_not_available`:
  "Writer can't use Gmail. Add it in the bot's settings."), like `bot_to_bot_off`.
- A bot's own reply that contains `@Gmail` means nothing.

### 3.5 Chat apps, voice, API

- **Slack, Telegram, Teams, iMessage (Phase 3):** no picker there, so text resolving (§3.2 step 3)
  does the work. Slack's own `@user` tokens are already stripped before we see the text.
- **Voice:** no change.
- **API and MCP:** `apps` on send is public API; documented in `docs-site/develop/api.md`.

## 4. App (Flutter)

All native, no WebViews.

### 4.1 The `@` menu

One menu for direct and group chats, built on `MentionController` (same keys). Rows, not chips,
like the `/` picker, each with `AppLogo` or `BotAvatar`:

1. **Bots** (group chats only): as today, with Everyone.
2. **Apps**: what this bot can use, most recently used first.
3. **Add to this bot**: connected in the workspace but not attached to this bot. Picking attaches
   it (for people allowed to; others see it greyed with "Ask an admin").
4. **Connect** (after 2 typed letters): catalog matches. Opens `showConnectApp`, then inserts the
   mention when it finishes.

Picking inserts `@Label ` in the text and remembers the ref for sending. Deleting the text drops the
ref. Empty state for a bot with no apps: one row, "Connect an app".

### 4.2 Sending and drawing

- `chatController.send(..., apps:)` beside `skills:`. A failed send restores them, like skills.
- `MentionScope` learns the message's app parts: pill with the logo; tapping opens the
  integration's detail screen. A removed app's pill stays, greyed, and opens nothing.
- The composer hint gains "@ for apps" where it already says "/ for skills" (check the exact
  string).

### 4.3 Older apps

Build 44 and earlier get messages with a part type they don't know. Phase 0 checks they skip it and
show the plain text `@Gmail`. If any shipped build fails on it, the server leaves the part out for
clients below a minimum version.

## 5. Privacy and safety

- A mention adds no permission and no data flow that the bot's connections didn't already allow.
- Text resolving can't be used to reach an app from outside: it only matches apps the answering bot
  already has, and the result is a preload and a hint.
- Analytics carry the catalog `app_id` only. A custom connection's name is never sent.

## 6. Analytics

Add to `packages/contracts/analytics/catalog.json`:

- `app_mentioned`: `kind`, `app_id` (catalog apps only), `surface` (`app`, `chat_app`, `api`),
  `picked` (menu or typed), `count`.
- `app_mention_connect_started`: `app_id`, from the Connect row.

What to watch: share of messages with a mention, connect starts from the menu, and `tools.load`
calls per run before and after.

## 7. Cost

No new paid service; `docs/COSTS.md` doesn't change. Expected effect is a saving: one model step
less on lazy runs where the bot would have called `tools.load`. Measure with
`packages/evals/src/compare.ts` on a subset run with and without mentions.

## 8. Docs

- `docs-site/guide/`: the chat page and the connections page get a short "Point the bot at an app"
  section.
- `docs-site/develop/api.md`: `apps` on send, the `app` part.
- `agent-kit` skills that describe sending messages, if they list the fields.
- `CHANGELOG.md`, one decision entry.

## 9. Tests

- **Domain:** `app-mentions.test.ts` (longest label, emails, case, two apps, overlap with a bot's
  name).
- **Agent:** `run.test.ts` (mentioned group loaded on the first request, stable order, over-budget
  app gets the note only, a disallowed app isn't loaded, hub toolkit loads only its tools, note
  absent from stored text).
- **API:** send with `apps`, typed without picking, an app the bot lacks, max 3, edit and resend,
  group chat notice.
- **Flutter:** widget tests for the menu (sections, keys, Connect row), the pill, a removed app's
  pill, send failure restoring refs; the existing `group_chats_test.dart` stays green.
- Full suites once at the end through `scripts/heavy.sh`.

## 10. Phases

### Phase 0: checks (done 2026-11-20)

- **Plugin tool naming & grouping:** Plugin stdio MCP servers are `integrations` with `kind = 'computer_mcp'` (remote ones use `kind = 'mcp'`). Tools are named `${kind}.${name}.${tool}` via `integrationToolName`. `INTEGRATION_KINDS` in `packages/agent/src/lazy-tools.ts` was missing `'computer_mcp'` and `'a2a'`; adding both gives each plugin server (`computer_mcp.<name>`) and A2A agent (`a2a.<name>`) its own lazy group. Hub integrations store connected slugs in `config.toolkits` (`composio`) or `config.apps` (`pipedream`), and their tool names start with `<normalized_slug>_`.
- **Shipped builds & unknown parts (§4.3):** Verified across `client/lib/core/supabase_backend.dart`, `client/lib/core/backend.dart`, `client/lib/features/chat/chat_controller.dart`, and `dart/casama_api`. Every reader filters `content` parts by `p['type'] == ...` and ignores unknown part types, so build 44 and earlier cleanly show plain `@Label` text. No minimum-version stripping is needed on the server.
- **Who may attach an integration to a bot:** `POST /v1/bots/{id}/integrations` checks RLS `public.can_manage_bot(bot_id)` (the bot's creator, a workspace owner/admin on a team-visible bot, or a user with an `edit`/`admin` bot grant), plus `local_mcp` requires `config.owner_user_id === user_id`.
- **Token budget:** `estimateTokens` uses `ceil(JSON.stringify(specs).length / 4)`. A typical tool spec is ~120–220 tokens; Composio Gmail (~20–30 tools) is ~3.5k–5.5k tokens and medium MCP servers are ~3k–7k tokens, while very large 50+ tool MCP servers exceed 10k tokens. Keeping `MENTIONED_TOOL_TOKENS = 8_000` preloads normal apps (and 2–3 smaller ones) while falling back to the note-only hint on oversized servers.

Done when: this plan is updated with the answers. **Done.**

### Phase 1: server (1.5 days)

Contracts, `parseAppMentions`, send and edit routes, `partsApps`, preload, the note, analytics
event, tests.

Done when: an API call with `apps` loads the tools on the first model request in `run.test.ts`.

### Phase 2: app (2 days)

The `@` menu in direct and group chats, sending, pills, the Add and Connect rows, widget tests.

Done when: the flow works on the local web app against the local stack. Store builds wait for
Oliver's yes.

### Phase 3: everywhere else (1 day)

Group chat notice, chat apps through text resolving, docs, changelog, decision entry.

Done when: `@Gmail` in a Telegram message loads Gmail's tools in a test with a scripted model.

Deploys (server, docs, web app, store builds) each need Oliver's yes.

## 11. Choices for Oliver

| # | Choice | Default |
|---|---|---|
| 1 | `@` for both bots and apps, or a second symbol (`+`) for apps | One `@` menu with sections |
| 2 | Does `@gmail` typed without picking count? | Yes, when it exactly matches an app the bot can use |
| 3 | A bot and an app share a name in a group chat (`@Notion`) | The bot wins the text; the menu labels the two rows "Bot" and "App"; picking the app still loads it |
| 4 | Show apps that aren't connected in the menu | Yes, after 2 typed letters, as a Connect row |
| 5 | Mention = hint, or force the bot to use the app | Hint. "@Calendar am I free?" may need no tool call |
| 6 | Max apps per message | 3 |
| 7 | Chat apps (Slack, Telegram…) in this round | Yes, Phase 3, text only |
| 8 | Routine prompts that contain `@App` | Later; not in this plan |

## 12. Risks and later ideas

- **False matches on typed text** ("follow @stripe on X"). The cost is a preload and a mild hint.
  If it shows up in practice, switch choice 2 to picked-only inside the app.
- **Big apps blow the budget.** Handled by the note-only fallback; Phase 0 measures real sizes.
- **Two connections of the same app** (work and personal Gmail). The menu shows both with their
  account labels; typed text picks the most recently used.
- **Later:** `@Browser`, `@Computer` and other built-in groups; mentioning files and memories;
  mentions in routine prompts; a bot suggesting "@ an app next time" after a wrong guess.
