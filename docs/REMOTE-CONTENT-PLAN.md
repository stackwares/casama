# Remote content plan

Status: approved 2026-11-18 ("build all now!", every question at its default). All phases built: 1 (D-370, D-371), 2 and 4 (D-372), 3 and 5 (D-373, D-374); see the rows marked **Built**.

## 1. Goal

Lists that change more often than we release should change without an app build, and where it's
cheap, without a server deploy. Today about thirty lists are written into the app, the server or the
Chrome extension. Some exist in two or three copies that already disagree.

Three homes, picked by who edits and how risky the content is:

| Home | Edited by | Reaches | Use for |
| --- | --- | --- | --- |
| **Gallery list** (`gallery/*.json`, signed manifest, D-239/D-315) | Casama, by pull request | Every server that reads the gallery, self-hosters too | Catalogs: coding agents, search words, onboarding content |
| **Admin setting** (`instance_settings` / `billing_settings`, Admin screens) | The server's owner | That server | Prices, models, caps, links, prompts |
| **Remote app settings** (`GET /v1/app-config`, D-241) | The server's owner | Every app and the extension, no sign-in | Links, small client-only lists, flags |

Rules for every list that moves:

- **The built-in copy stays as the fallback.** A server or gallery that can't be reached, or an
  entry that fails its check, falls back to what shipped. Nothing breaks offline.
- **Apps accept ids they don't know.** Shipped apps parse these lists leniently: skip unknown
  entries, never fail the whole list (the strict app-category enum broke shipped apps once).
- **One copy.** When a list moves, the app and the other packages read it from the server and their
  own copies become fallbacks only.
- **Security lists can only grow remotely.** A remote list adds to a safety list in code; it never
  removes from it.
- **Executable things stay signed and first-party.** Anything that becomes a command, an OAuth
  scope or a tool definition is either kept in code or comes from the signed gallery with no
  community pull requests for that file.

## 2. Coding agents (first)

**Status (2026-11-18): Phase 1 built (D-370, D-371), with the §5 defaults:** gallery list, own
agents on my computer only.

- Built: `gallery/coding-agents.json` (first-party, signed, CODEOWNERS + CI refuse outside PRs),
  `BUILT_IN_CODING_AGENTS` fallback and template checks in `packages/domain/src/coding-agents.ts`,
  `GET /v1/coding-agents`, `coding.delegate` on the loaded list, the desktop app's scan from the
  server (built-in five for older servers), one-tap Allow (`local_devices.allowed_coding_agents`),
  own agents (`own_coding_agents`, `GET`/`PUT /v1/local-devices/{id}/coding-agents`, Test via
  `POST …/coding-agents/test`).
- Added after a real run in `/private/tmp`: **Kimi Code** (`kimi -p {task} --output-format
  stream-json`, my computer only; `--yolo` can't be combined with `-p`, and it edits without asking
  anyway).
- **Unverified, not added** (no sign-ins were made):
  - Gemini CLI: no global `gemini` bin (only an npx alias); the account got `IneligibleTierError`
    (this client is no longer supported for Code Assist individuals); exit 55 in an untrusted folder.
  - OpenCode: `opencode run` returned 401 "Reconnect OpenCode Console".
  - Cline: "Unauthorized", needs signing in again. Its JSON run result has a `text` field.
  - Grok: 402, out of credits.
- Left: production deploy (server, gallery sign + sync), desktop app build; real runs of the
  unverified agents once signed in.

### 2.1 Catalog

`gallery/coding-agents.json`, first-party only, signed with the rest of the gallery manifest.
Today's five (`claude_code`, `codex`, `cursor`, `pi`, `t3code`) move there; `CODING_AGENTS` in
`packages/agent/src/tools/coding.ts` stays as the fallback.

An entry:

```json
{
  "id": "gemini",
  "label": "Gemini CLI",
  "bin": "gemini",
  "where": ["my_computer", "bot_computer"],
  "install": "npm install -g @google/gemini-cli",
  "key_name": "GEMINI_API_KEY",
  "command": {
    "my_computer": "gemini -p {task} -o json --approval-mode auto_edit",
    "bot_computer": "gemini -p {task} -o json --approval-mode yolo"
  },
  "result": "json_field:response",
  "needs_folder": false,
  "exit_messages": {}
}
```

- **Placeholders only:** `{task}`, `{folder}`, `{result_file}`. The server shell-quotes every value.
  A template that doesn't parse, or uses anything else, is refused and the fallback is kept.
- **Named behaviours stay in code**, and an entry picks one:
  - `result`: `json_result` (Claude), `marker` (Codex), `json_field:<name>` (T3 Code `reply`,
    Gemini), `stream_json`, `tail`;
  - `browser`: `claude` | `codex` | none (the C16 MCP flags);
  - `commits_for_agent`: Codex's sandbox can't write `.git`.
  An agent that fits these needs no release. A new behaviour is a server deploy, never an app build.
- **The app's scan** reads `{id, label, bin}` from the server (`GET /v1/coding-agents`) and keeps
  its built-in list for offline and older servers.
- **`coding.delegate`** validates `agent` against the loaded list and builds its description from it.
- **New agents, one tap:** an agent the user's computer hasn't run before needs one Allow on that
  computer, even with Run commands on.

Candidates to add once the catalog exists (headless modes confirmed from `--help` on Oliver's Mac,
none run for real yet): Gemini CLI, OpenCode (`opencode run --format json --auto`), Cline
(`cline … --json`), Kimi (`kimi -p … --output-format stream-json`). To check: Grok, Amp, Aider,
GitHub Copilot CLI, Qwen Code, Goose, Droid, Auggie, Crush.

### 2.2 People's own agents

Under Coding Agents in the desktop app: **Add your own**.

- **One person, one computer.** Stored with the companion device, never workspace-wide: an admin
  can't put a command on a member's Mac.
- **My computer only.** Bot computers keep catalog agents.
- **Same fields as a catalog entry:** label, `bin`, template with `{task}`, `result` choice, time
  limit. No scripts.
- **Test** runs a tiny task ("Reply with just the word pong") and shows the output before saving.
- Shown with a "Yours" label; bots reach them through `coding.delegate` like any other.
- Later: a pack may carry an agent; installing shows the exact command and needs Allow on that
  computer, like D-343's `reach_grew`.

## 3. The rest, ranked

Value = how often it changes × how much a change costs today (app build > store release > deploy).

| # | What | Where now | Copies | Home | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | **Model catalog**: featured models, defaults, small models, price/capability rows, image prices, test models | `domain/models.ts:7,18,46`, `agent/gateway/registry.ts:45`, `agent/media.ts:79`, `worker/workflows.ts:657` | App fallback in `core/supabase_backend.dart:48` | Admin setting (next to `cloud_models`) | Changes monthly. `DEFAULT_TEST_MODELS` is already stale (`gemini-2.5-flash`, `grok-3-mini`). Prices feed billing: check on save, keep the regex rows as fallback. Delete the app fallback. **Built (D-373):** Admin > Services > Model catalog; app fallback removed; test models from the catalog. |
| 2 | **Gallery search words** | `agent/gallery.ts:68` (~40), `mcp/gallery.ts:112` (11), `client/.../gallery_logic.dart:189` (~40) | 3, already different | Gallery list | Cheapest clear win: one list, app and MCP read it. **Built (D-372):** `gallery/lists/search-words.json` (52 keys, the union of the three); agent, MCP and app read it, built-in words as fallback. |
| 3 | **Built-in starter bots win over the gallery** | `domain/templates.ts:29` (26), `services/gallery.ts:642` | Server | Gallery list | Editing one of the 26 in the gallery has no effect: the built-in copy is used first. Make the gallery copy win and keep built-ins as the offline fallback. **Built (D-372):** 26 copies in `gallery/bots/`; `starterBots()` puts the gallery copy first, built-ins stand in offline. |
| 4 | **Links**: status, docs, legal (still Apple's EULA), where to get keys, manage subscription, Docker downloads | ~14 URLs across `support_screen.dart`, `purchase_terms.dart:11`, `onboarding_screen.dart:153`, `call_screen.dart:804`, `provider_setup.dart:29`, `billing_screen.dart:144`, `docker_check.dart:83`, … | App only | Remote app settings: `links` map | A broken link is an app build today. Legal links will change when Casama's own terms go up. **Built (D-372):** `links` map in app settings (https only); 15 names in the app, old URLs as fallback. |
| 5 | **App catalog curation**: starter apps in an empty chat, order, descriptions | `client/.../app_tiles.dart:16` (6), `domain/apps.ts:113` (39), `agent/welcome.ts:77` | App + server | Display fields only, as an admin/gallery overlay | Keep OAuth scopes, MCP URLs and `ZOHO_MCP_HOSTS` in code. Bundled logos stay in the app with the existing fallback. **Built (D-372):** `lists/app-curation.json`: display fields + `order` for built-in apps, `starter_apps` on the catalog. |
| 6 | **Onboarding**: focus choices, intro, first task, starter-set match words | `agent/welcome.ts:23-140`, `client/.../gallery_picks_step.dart:97` | Server + app | Gallery list (match words into each set's `tags`) | A new starter set gets no matching until an app build today. Keep focus ids and `WELCOME_STEPS` stable for analytics. **Built (D-372):** `lists/welcome.json` read by `agent/welcome.ts`; match words in each set's `tags`. |
| 7 | **Sensitive sites for the browser guard** | `domain/browser-guard.ts:96,161` (~54 hosts), extension `lib/guard.ts` | Server + extension | Remote add-only list | Extension changes need a Chrome Web Store release today. Add-only. **Built (D-374):** Admin > Services > Browser guard sites, `GET /v1/browser-guard`, extension reads it hourly. |
| 8 | **Check-in and setup prompts**, Composio triggers, setup guide | `agent/checkins.ts:19,39,48,95`, `composio-triggers.ts:19`, `tools/setup.ts:13` | Server | Admin setting, versioned | Keep the parts code checks for (`Write my morning brief for today.` prefix, `NOTHING_NEW`, `quiet day`) outside the editable text. Run the evals before a new version goes live. **Built (D-374):** gallery-only (`gallery/prompts`), versioned, prompt evals on PRs and nightly. Composio triggers stay in code. |
| 9 | **Model-key providers**: grouping, order, hints, cloud keys | `client/.../model_keys_screen.dart:20,42,51,73,182`; chat providers also in `model_picker.dart:32`, `bots_screen.dart:674` | 3 in the app | Server `PublicConfig` | `cloudKeyProviders` says it should shrink as Casama Cloud supplies keys. **Built (D-374):** `/v1/config` `key_providers`; one app fallback. |
| 10 | **Welcome email series and gallery digest** | `services/account-emails.ts:55,133-580` | Server | Admin setting | Copy only. Billing and domain emails stay in code. **Built (D-372):** **Email words** admin setting (`email_copy`, `/v1/admin/email-copy`): subject, preheader, title, intro, button. |
| 11 | **Domain TLDs and purchase caps** | `domain/sites.ts:521`, `sites/buying.ts:50` | Server | `billing_settings` | Prices are already there; TLDs are env-only today. **Built (D-373):** Admin > Pricing > Cost tables; `CASAMA_DOMAINS_TLDS` is the fallback. |
| 12 | **Cost tables**: voice, Gemini Live, computers, media | `agent/voice.ts:277,658`, `agent/computers.ts:40`, `MEDIA_PRICES` | Server | Admin → Pricing | Billing: validate on save; keep code values as fallback. **Built (D-373):** Admin > Pricing > Cost tables; Admin rates win over `COMPUTER_RATES`. |
| 13 | **Empty-state starters**: Library (6), Tasks (3), support questions (4) | `library_starters.dart:23`, `board_screen.dart:1753`, `support_screen.dart:698` | App | Gallery list, like routine ideas | Low change rate; batch with #6. **Built (D-372):** `lists/starters.json` via `GET /v1/gallery/lists`; English only, built-in copy as fallback. |
| 14 | **Extension prompts** | `extension/lib/intent.ts:52`, `panel/chat.ts:87` | Extension | Remote app settings | It already reads `/v1/app-config` (`lib/remote-config.ts`). **Built (D-372):** `prompts` in app settings (`selection.*`, `write.*`), last fetched copy, own text as fallback. Quick reactions not moved. |
| 15 | **Small duplicates**: tool-call app names (20), DNS provider names (14), quick reactions (6) | `ui/tool_words.dart:236`, `sites/domains_providers.dart:51`, `core/backend.dart:14` | App + server | Server sends the name with the id | Mostly removing duplicate copies, not remote editing. **Built (D-372):** `names` (apps, DNS providers) in `/v1/app-config`, `dns_provider_name` on domains, `quick_reactions` setting. |

**Stays in code:** the computer CLI list (`context.ts:198`, must match the image), Zoho scopes and
tools, chat channel adapters, payment blocklists and blocked IP ranges, theme presets, icon maps,
file-type sets, the wake-word model URL and hash (a security pin).

## 4. Phases

1. **Coding agents**: catalog + `GET /v1/coding-agents` + the app reads it + own agents + one-tap
   Allow. Then add Gemini CLI, OpenCode, Cline, Kimi after a real run each.
2. **Cheap wins**: search words (#2), gallery bots win (#3), links (#4), small duplicates (#15).
3. **Models and prices** (#1, #11, #12) in Admin, with validation and fallbacks.
4. **Content**: onboarding and empty states (#6, #13), app catalog curation (#5), extension prompts
   (#14), emails (#10).
5. **Careful ones**: guard sites add-only (#7), prompts with versions and evals (#8), model-key
   providers (#9).

Each phase: tests for the fallback path and for an unknown id in a shipped app's parser, a decision
entry, docs. App builds and production deploys still need Oliver's yes each time.

## 5. Questions for Oliver

1. Coding agents catalog: gallery list (every server, self-hosters included) or Admin setting
   (Cloud only)? Default: gallery.
2. Own agents on the bot's computer too, or my computer only? Default: my computer only.
3. Prompts (#8): editable in Admin at all, or gallery-only so every change is a reviewed pull
   request? Default: gallery, versioned, evals in CI.
4. Phase order as above?
