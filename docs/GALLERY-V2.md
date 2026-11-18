# Gallery v2 (D-315)

Working spec for the gallery v2 build. Every workstream builds against the formats and API shapes
here, so they fit together. If you must change a shape, change it here first and say so in your
report. Compatibility rule for everything below: **shipped apps and servers must keep working.**
New fields are optional for readers, new item kinds go in new files (never into `index.json`'s
`type` enum), and old clients ignore what they don't know.

## 1. Catalog format (gallery/ item folders, checker, index files)

New optional `item.json` fields (all kinds unless noted). The checker (`gallery/check.mjs`) and
`packages/domain/src/gallery.ts` validate them with the same rules and copy them into the index
records.

| Field | Shape | Rule |
| --- | --- | --- |
| `added` | `"YYYY-MM-DD"` | Required for every item. Backfilled once from git history (first commit that added the folder). |
| `updated` | `"YYYY-MM-DD"` | Optional; date of the latest `changelog` entry when present, else `added`. Index always carries it. |
| `changelog` | `[{ "version": int, "date": "YYYY-MM-DD", "note": string<=160, "breaking"?: bool }]` | Newest first, versions strictly descending, top entry's version == `version`. Required once `version` > 1. |
| `pick` | `string<=140` | Why it's a pick. Only allowed when `featured: true`; every featured item should have one. |
| `examples` | `string[]` 1..3, each <=160 | Sample prompts ("Summarize my unread email from today"). Skills, apps, bots. |
| `access` | `{ "reads"?: string[], "writes"?: string[], "runs_code"?: bool, "computer"?: bool, "credits"?: "none"\|"low"\|"medium"\|"high" }` | What it can touch, in plain words (`reads: ["email", "calendar"]`, `writes: ["sends email"]`). Skills, apps, routines, bots, plugins. The checker forces `runs_code: true` and `computer: true` when a skill has scripts. |
| `needs` | `{ "apps"?: string[], "skills"?: string[] }` | Gallery/built-in app ids and skill ids a routine or bot needs before it works. Checker verifies skill ids exist in the gallery; app ids must exist in gallery apps or the built-in list (`packages/domain` APP_CATALOG ids). |
| `inputs` | `[{ "key": /^[a-z][a-z0-9_]{0,31}$/, "label": string<=60, "type": "text"\|"choice"\|"time"\|"timezone", "default": string (required, fits the type), "options"?: string[] (choice only, 2..8), "help"?: string<=120 }]` max 6 | Questions asked at install. **Built (catalog workstream):** `default` is required, because the index record's `document` carries the defaults filled in (servers from before inputs keep working) and a new `template` field carries the raw placeholder fields (`instructions_md`/`schedule_cron` for routines, `persona`/`starters` for bots) for newer servers to fill. Routines and bots. `{{key}}` placeholders may appear in a routine's `instructions_md` and a bot's `persona`/`starters`; a `time` input named `time` may replace the routine cron's minute/hour via `schedule_cron` placeholders `{{time.minute}}` `{{time.hour}}`. Checker: every placeholder used has an input, every input is used. |
| `remix_of` | `{ "type": string, "id": string }` | Credits the original; checker verifies it exists. |
| `min_app` | `"x.y.z"` | Lowest app version that can use it. Apps hide items above their version. |
| `min_server` | `"x.y.z"` | Lowest server version. Servers drop items above their version from every list. |
| `season` | `{ "from": "MM-DD", "to": "MM-DD" }` | Shown in the seasonal row only between these dates (may wrap the year end). |
| `author.handle` | `/^[a-z0-9][a-z0-9-]{0,38}$/` | Stable author id for author pages (GitHub login style). Optional; author pages group by handle, else by name slug. |

Existing `requires` (feature list for looks) stays and is the per-feature gate; `min_app`/`min_server`
are the general version gate.

### Skill tests
A skill folder may contain `tests.json`: `{ "cases": [{ "prompt": string<=500, "expect": string<=300 }] }`
(1..5 cases; `expect` is a plain-words rubric a judge model checks). The checker allows the file
and validates its shape; it is excluded from the installed bundle hash? **No**: it is part of the
folder and the hash like any file. `scripts/gallery-skill-tests.mts` runs them (opt-in, needs a
model key; never in `pnpm test`), and writes `gallery/tested.json` `{ "<skill-id>": { "version": n, "passed": bool, "date": "YYYY-MM-DD" } }`
which the checker folds into index records as `tested: { version, date }` when passed and the version matches.

### New kind: starter sets
`gallery/sets/<id>/item.json` + `set.json`: `{ "description": string<=200, "icon": lucide, "items": [{ "type": "app"|"skill"|"routine"|"bot"|"theme"|"scheme"|"wallpaper"|"plugin", "id": string }] (2..12) }`.
License CC0-1.0 or CC-BY-4.0. Written to `sets.json` (new file). Seed at least 4 sets (Founder kit,
Writer kit, Stay on top of email, Student kit) from existing items.

### Derived files the checker writes
- `index.json`, `apps.json`, `bots.json`, `routines.json`, `plugins.json` (as today, records gain the new fields), `sets.json` (new).
- `authors.json`: `{ schema: 1, authors: [{ handle, name, url?, items: [{ type, id }] }] }`.
- `manifest.json`: `{ schema: 1, created: "YYYY-MM-DD" (newest `updated` in the catalog, so `--check` is stable), files: { "<file>": "<sha256 hex>" } }` over every derived JSON file above (not over itself).
- `manifest.sig`: written by `gallery/sign.mjs` in CI only (one line, trailing newline; readers trim): base64 Ed25519 signature over the exact bytes of `manifest.json`, key from `GALLERY_SIGNING_KEY` (PKCS8 PEM or base64 raw 32-byte seed). `check.mjs --check` does not need the key.

### Index record additions (every *.json record)
`added`, `updated`, and when present `changelog`, `pick`, `examples`, `access`, `needs`, `inputs`,
`remix_of`, `replaced_by`, `min_app`, `min_server`, `season`, `tested`, `author.handle`, and `template` (routines/bots with inputs). Sets records: `type: "set"`, `document` = set.json.

## 2. Signed index (server)
- Env `GALLERY_PUBLIC_KEY` (base64 raw 32-byte Ed25519 public key; default = the Casama gallery key
  baked into `apps/server/src/env.ts`), `GALLERY_SIGNATURE` = `required` | `optional` (default
  `optional` until the first signed deploy, then flip to `required` in a follow-up) | `off`.
- Server fetches `manifest.json` + `manifest.sig`, verifies, and then checks each fetched JSON file's
  sha256 against the manifest. In `required` mode a bad/missing signature makes the gallery
  unavailable (`available: false`), never silently trusted. Custom `GALLERY_URL` with no key: `off`.

## 3. More than one catalog
- Env `GALLERY_SOURCES`: comma list of extra catalog base URLs, each optionally `name=url` and
  `name=url#<base64 pubkey>`. Items from an extra source get `source: "<name>"` and their ids are
  namespaced as `<name>:<id>` in API responses and installs. Default source has no `source` field.
- Same format, same checker (`node gallery/check.mjs` works in any folder laid out the same way).

## 4. Server API (packages/contracts first, then apps/server)

**Built (server workstream), final shapes; the generated client is the source of truth:**
- Workspace ids are `org_id` (body and query), as in every other route; the policy lives at
  `GET/PUT /v1/orgs/{id}/gallery-policy`.
- Approvals are their own table and routes, not the run approvals (those need a bot and a run):
  `GET /v1/orgs/{id}/gallery-approvals?status=` (admins see all, members their own) and
  `POST /v1/gallery-approvals/{id}/decision {decision}`; admins get a `gallery_approval`
  notification. The older install routes answer **403** `approval_pending` (not 202) so shipped
  apps show a message; `POST /v1/gallery/install` answers **202** with `status: "approval_pending"`
  and `approval_id`. Admins skip approval; `block` applies to everyone.
- `POST /v1/gallery/install` → `{ status: "installed"|"approval_pending", installed: {kind,id}|null, approval_id|null, missing: {apps:[{id,name}], skills:[{id,name}]} }`.
  Routines and plugins need `bot_id` (400 `bot_required`). 400 `inputs_invalid`: Problem `errors` = `[{path: <input key>, message}]`.
- `POST /v1/gallery/sets/{id}/install {org_id, bot_id?}` → `{ items: [{type, id, status: installed|approval_pending|skipped|failed|device, installed|null, error|null}], missing }` (looks come back `device`).
- 409 `access_changed`: Problem `errors` = `[{path:"reads"|"writes", message:<added>}, {path:"runs_code"|"computer"|"breaking", message:"true"}]`. The update body is `{org_id, type, id, accept_access?}` → `{updated, version}`.
- Requests: `GalleryRequest {id, kind, title, details, status, done_item_key, votes, voted, mine, created_at}`; create answers 201 (new) or 200 (the similar one, now with your vote).
- `GET /v1/gallery/sets` → `{items: [{id, name, description, icon, author, featured, items:[{type,id}], source?, added?}]}`; `GET /v1/gallery/authors` → `{items:[{handle,name,url?,items}]}`.
- Health findings are stored with reason `health:<check>` (`app_unreachable`, `composio_missing`, `dead_link`, `reports`, `min_server`); the admin queue shows them as `other` with the check at the start of the note, and gallery-request reports as `gallery_item` `request/<id>`, so shipped admin consoles keep parsing.
- Rewards credit through `credit_apply` with reason `grant` and reference `gallery_reward:<item>:<milestone>` (no new ledger reason). Credits are dollars (D-245), so the default is `{"50":10,"250":25,"1000":75}`.
- `GET /v1/me/email-preferences` always returns `gallery_digest`; `PUT` takes it optionally (left out = unchanged). The digest's unsubscribe is `/v1/email/unsubscribe/<token>?list=gallery`.
- `CreateRoutineRequest.gallery_id` (optional) records a routine made from an idea; starter bots, gallery apps and directory plugins are recognized on the existing routes.


All new item fields are optional in `GalleryItem` (and new `GallerySet`, `GalleryAuthor` types).
`GalleryItem` gains: `added`, `updated`, `changelog`, `pick`, `examples`, `access`, `needs`, `inputs`,
`remix_of`, `min_app`, `min_server`, `season`, `tested`, `source`, and `stats` (below).

### Usage counting (aggregate only, D-315 privacy rule)
- Table `gallery_installs(item_key text, user_hash text, first_at, last_used_at, primary key(item_key, user_hash))`
  where `item_key = "<type>/<id>"` (with source prefix for extra sources) and
  `user_hash = hmac_sha256(server secret, user_id || item_key)`. No user id, no workspace id stored.
  RLS on, no client access; server and worker only.
- Table `gallery_item_stats(item_key pk, installers int, installers_7d int, active_14d int, runs_ok int, runs_total int, updated_at)` rolled up by the worker hourly.
- Recorded server-side on: gallery skill install, gallery app connect, bot from gallery template,
  routine from gallery idea, plugin install from directory, set install. Looks: `POST /v1/gallery/{type}/{id}/used` (signed-in, 204, rate-limited 30/min per user, upsert only).
- "Active": `last_used_at` within 14 days. Skills update `last_used_at` when a run loads the skill;
  routines when they run; apps when their tools are called; bots when they reply (best effort, batched).
- Run success for skills and routines: `runs_ok/runs_total` from runs that used the item (last 30 days).
- Public `GET /v1/gallery/stats` (no sign-in, `Cache-Control: public, max-age=600`):
  `{ items: { "<type>/<id>": { installers?: int, trending?: int, active?: int, success?: number } } }`.
  Any number is omitted when `installers < 10` (privacy and no "1 install"). `success` omitted when `runs_total < 20`.
- `GET /v1/gallery` items carry the same `stats` object.
- Self-hosted servers: env `GALLERY_STATS_URL` (default `https://api.casama.ai/v1/gallery/stats`; `off` to hide). A server that is itself the cloud serves its own.

### Listing every kind (added by the Flutter gallery builder)
- `GET /v1/gallery?kinds=all` returns every kind in one list: looks, skills, apps, bots, routines,
  plugins and sets, each record as in its index file (sets carry `document` = set.json, so
  `document.items` lists the set's items). Without `kinds` the list stays looks and skills, as old
  apps expect. `type` also accepts `app|bot|routine|plugin|set`, and `GET /v1/gallery/{type}/{id}`
  accepts those types too. The app builds rows, search, author pages and works-with from this list.

### Installed and updates
- `GET /v1/gallery/installed?workspace_id=` →
  `{ items: [{ type, id, name, installed_version, latest_version|null, update: bool, breaking: bool, access_added: { reads: [], writes: [], runs_code: bool, computer: bool }, retired: bool, replacement?: {type,id}, changelog: [...], installed_at, target: { kind: "skill"|"bot"|"routine"|"app"|"plugin", id } }] }`
  for workspace-scoped kinds (skill, bot, routine, app, plugin). Looks are device-side; the app tracks them.
  Needs the installed version recorded at install (add columns or a `gallery_links(workspace_id, target_kind, target_id, item_key, version, installed_at)` table, RLS by workspace membership).
- `POST /v1/gallery/installed/update` `{ workspace_id, type, id, accept_access?: bool }` → applies latest (409 `access_changed` with the diff unless `accept_access: true` when access grew or the entry is breaking).
- `DELETE /v1/gallery/installed/{type}/{id}?workspace_id=` removes the installed copy.
- Retired items: `item.json` may add `replaced_by: { type, id }` (checker field, all kinds).

### Install with needs and inputs
- `POST /v1/gallery/install` `{ workspace_id, type, id, inputs?: Record<string,string>, bot_id? }` →
  `{ installed: {kind,id}, missing: { apps: [{id,name}], skills: [{id,name}] } }`. Skills in `needs`
  are installed automatically; apps can't be (the person signs in), so they come back in `missing`
  for the app to walk through. 400 `inputs_invalid` with per-key errors. Placeholders are filled
  server-side. Existing install routes keep working unchanged.
- `POST /v1/gallery/sets/{id}/install` `{ workspace_id }` → per-item results, same `missing` shape.

### Workspace controls
- Workspace setting `gallery_policy`: `{ mode: "open"|"approval"|"allowlist", allow: string[] (item keys), block: string[], approval_for: ("runs_code"|"apps"|"all")[] }`, default open.
  Admins/owners edit via `GET/PUT /v1/workspaces/{id}/gallery-policy`. Enforced in every gallery
  install path (403 `gallery_blocked`, or 202 `approval_pending` creating an approval the existing
  approvals flow shows to admins; on approve the install runs).
- Plan gating: available on every plan (governance belongs in core; decide later if Pro-only).

### Requests board
- Tables `gallery_requests(id, kind, title, details, created_by, created_at, status open|planned|done|declined, done_item_key)` and `gallery_request_votes(request_id, user_id)`.
- `GET /v1/gallery/requests?sort=top|new`, `POST /v1/gallery/requests` (rate-limited 5/day/user,
  title 4..80, details <=500, deduped by similar title → returns the existing one), `POST /v1/gallery/requests/{id}/vote` / `DELETE` to unvote.
  Instance owners set status via `PATCH /v1/gallery/requests/{id}`. Report flow covers abuse (target_kind `gallery_request`).

### Submissions (no GitHub needed) and remixes
- `POST /v1/gallery/submissions` `{ type, id?, item: {...item.json fields}, files: { "<name>": string } , remix_of? }`
  → validated with the same domain checker, then the server opens a pull request on the catalog repo
  (env `GALLERY_SUBMIT_REPO` default `stackwares/casama-gallery`, `GALLERY_SUBMIT_TOKEN` a GitHub token;
  route returns 503 `submissions_off` when unset). Author is the person's display name plus a
  `casama_user` hash in the PR body, never their email. Record in `gallery_submissions(id, user_id, item_key, pr_url, status, created_at)`.
  Limits: 5/day/user, total size <= 200 KB. Kinds: theme, scheme, wallpaper (pattern/mesh only, no image upload), skill (no scripts), routine, bot.
- `GET /v1/gallery/submissions` (mine) with status pulled from the PR (open/merged/closed), refreshed lazily.

### Author stats and contributor credits
- `GET /v1/gallery/me/items`: for items whose merged submission is mine: `{ type, id, name, stats (unthresholded for the author), reports_open, version }`.
- Reward: worker job grants credits once per item per milestone (50 active users → 500 credits,
  250 → 2,000) via the existing credit grant path, ledger reason `gallery_reward`, idempotent
  table `gallery_rewards(item_key, milestone, user_id, granted_at)`. Amounts in env
  `GALLERY_REWARDS` JSON so they can change without a release; `off` disables. Add the cost line to
  `docs/COSTS.md`.

### Monthly "New for you" email
- Account email preference `gallery_digest` (opt-in, default off), toggle in the app's email/
  notification settings. Worker job on the 1st of the month: for opted-in users, up to 6 items
  added in the last 30 days that match their connected apps or kinds they installed, using the
  existing account email layout; skip when nothing matches. Unsubscribe link sets it off.

### Nightly gallery health
- Worker job daily: gallery apps whose Composio toolkit / sign-in endpoint no longer resolves,
  dead `author.url` / plugin urls (HEAD, 3 tries), items with >= 3 open reports, `min_server` above
  the running version. Writes rows into the admin reports list (target_kind `gallery_item`,
  reason `health:<check>`) without duplicates.

## 5. Agent (packages/agent)
- Tool `gallery.search { query, types?: [...] }` → top 5 items (id, type, name, description, access,
  installed?) honoring the workspace policy.
- Tool `gallery.suggest { type, id, reason }` → shows a card in chat (A2UI-style data, no WebView):
  chat message content part `{ "type": "gallery_suggestion", "item": { type, id, name, description, icon?, access?, needs? }, "reason": string }`
  (message content parts are keyed by `type` like `text`/`ui`/`file`; the tool emits run event `gallery.shown` with the part as payload, and the
  final assistant message carries it after the `ui` parts).
  The app draws it with an **Add** button (runs the install flow incl. needs/inputs) and **Not now**.
  Limit: one suggestion per turn, never the same item twice in a conversation, never for retired or blocked items.
- Repeated-request routine hint: when a bot sees the same kind of request 3 times on different days
  (cheap heuristic over recent user messages in this conversation's memory, not a model call per
  message), it may call `gallery.suggest` for a matching routine, or suggest making one.
- "Make this a skill": tool `gallery.draft_skill { name, description, instructions_md }` returns a
  draft card `{ "type": "gallery_draft", "draft": { "type": "skill", "id": "<skill-id>", "item": { name, description, license, tags, featured, version }, "files": { "SKILL.md": string } } }`; the app shows it
  with **Save to my skills** and **Submit to the gallery** (submission route).
- Looks: "make me a dark green theme" → search gallery looks first.

## 6. Flutter app
- Gallery home: rows **Picks** (with pick note), **New** (added in 30 days, badge on cards),
  **Trending this week**, **Most used** (apps, skills, wallpapers, themes only), **Works with what
  you have** (routines/skills/bots whose `needs.apps` ⊆ connected apps, or that match them),
  **Starter sets**, **Seasonal** (when any item is in season). Rows with nothing to show are hidden.
- Filters: kind chips (existing) + category/tag, Free / needs a plan (`access.credits`), works on
  self-hosted, needs a computer. One search across every kind with tags and a small synonym map
  (mail→email/gmail/outlook, cal→calendar, ...).
- Empty search: **Request this** (requests board) and **Ask Casama to make it** (opens a chat with
  a prefilled prompt).
- Detail: **What it can access** list, **Try it** examples (opens a chat with the prompt), made by
  (Casama / Community / Reviewed = tested), version + updated + changelog, remix credit, author link,
  stats line when present ("Used by 120 people · 96% of runs finish").
- **Installed** tab: workspace items with **Update** (permission diff dialog when access grew or
  breaking), **Remove**, retired notice with replacement; device looks tracked locally with update
  when the gallery version is newer.
- Install wizard for routines/bots/sets: inputs form, then needs (install skills, connect apps one by one), then done.
- Author page: items by handle/name, links.
- **Submit to the gallery**: from a saved theme/scheme/wallpaper, a skill, routine or bot; remix
  credit when it came from the gallery. **My submissions** with PR status and author stats.
- Requests board screen: list (top/new), vote, new request.
- Chat: draws `gallery_suggestion` and `gallery_draft` parts.
- First-run picks: after About you (D-169), a "Picks for you" step pre-selecting a starter set that
  matches the answers; skippable.
- Workspace settings → **Gallery** (admins): mode, allow/block lists, approval rules.
- Email settings: **Monthly gallery picks** toggle.
- `min_app` above the running version: item hidden.

## 7. Web gallery (gallery.casama.ai)
- Same rows as the app (picks, new, trending/most used from the public stats endpoint, sets,
  seasonal), filters, author pages, requests link, empty search → request.
- A static page per item at `/i/<type>/<id>/` (generated at build into a gitignored folder, deployed
  with the site) with title, description, examples, access, author, Open in Casama, and an Open
  Graph PNG (1200x630) per item. Old `#type/id` links keep working (redirect to the page).
- `sitemap.xml`, canonical links. Badge: `/badge.svg` + `/add` docs section "Add to Casama"
  (`https://gallery.casama.ai/i/<type>/<id>/` link + badge markup).
- Public read API docs: the static `*.json` files and `/v1/gallery/stats`, documented.

## 8. Developer surfaces
- `llms.txt` (casama.ai and docs) lists the gallery JSON files; agent-kit skill notes "check the gallery first".
- MCP (`packages/mcp`): `gallery_search` tool.
- CLI: `casama gallery mirror <dir>` downloads a signed copy (verifies manifest) for offline servers;
  `casama gallery search`; `casama init --from-gallery bot/<id>|plugin/<id>`.

## 9. Docs
- docs-site guide page for the gallery (browsing, installing, updating, submitting, requests),
  self-hosting page (GALLERY_SOURCES, signature, stats URL, offline mirror), develop page (catalog
  format incl. every new field, tests.json, sets).
- `docs/DECISIONS.md` D-315 entry, `SPEC.md` gallery section, `docs/COSTS.md` reward line.
