# Docs refresh after 2026-11-19/20: plan

Status: **done** (2026-11-20, live on docs.casama.ai). Oliver: "go build all and decide everything for me according to the written plan", so the
recommended answers in §4 were taken: map keys documented (names only), internal-account settings in the
telemetry table, docs.casama.ai deployed on 2026-11-20 from a clean checkout of e224d818 (docs only; casama.ai and the gallery were not touched). Tracked in `docs/PLANS.md`.

Oliver asked how the documentation stands after the last two days of changes. Most feature commits
updated their guide page in the same change (weekly plans, saved resets, computer hours, waitlist,
admin bot, vendor usage, Resend backup, GA4 in `privacy.md`, @-mentioning apps). This plan covers the
gaps that were left: pages on `docs.casama.ai` that now say something wrong or leave out behavior
people will run into, and plan files whose status disagrees with `docs/PLANS.md`.

Docs only. No code, no new paid service, no secrets.

## 1. Guide pages (docs-site)

### 1.1 @-mentions in direct chats (f6da0fd3, 711a4450, 1f623db5; D-434)

`docs-site/guide/connections.md` → "Mention an app with `@`" says the `@` list in a direct chat
shows apps only. Rewrite that section:

- **Direct chats:** one `@` list. A bare `@` always opens it. It shows the apps attached to this bot,
  then popular apps to connect (so a bot with no apps still gets a list). After two typed letters,
  **Connect** offers catalog apps you haven't connected yet. Owners and admins also see **Add to this
  bot** for apps connected elsewhere in the workspace. Under **Start a group chat** it lists your
  other bots: picking one opens the group chat with both bots (or the existing one) and carries your
  draft with that bot's name in it.
- **Group chats:** the same vertical list, **Bots** first, then **Apps** (drop the old chip strip
  wording if any remains).
- **In the composer:** a mention that will count (a bot in the group, an app this bot has) shows
  bold and highlighted as you type. A plain `@word` that matches nothing stays plain text.

`docs-site/guide/group-chats.md` → "Create a group chat": add a second way to start one, with a
link: "Or, in a chat with one bot, type `@` and pick another bot under **Start a group chat**."

### 1.2 Rings that reached no device (D-438)

- `docs-site/guide/voice.md` → "When a bot calls you", the ring-limit bullet: add "A ring that
  reached none of your devices (no phone set up for calls, no computer or browser for the banner)
  doesn't count toward either limit. The bot is told you have nothing set up to ring, and you still
  get the missed-call notification."
- `docs-site/guide/limits.md` → the "Bot daily ring cap" and "Per-bot ring cooldown" rows: append
  "Rings that reached no device don't count."

### 1.3 A phone follows the account signed in on it (D-437)

`docs-site/guide/voice.md`, same section, new bullet: "Calls and notifications go to the account
signed in on the phone. When you sign out, that phone stops getting the old account's calls and
notifications; when someone signs in, they start reaching the new account right away, without
restarting the app." Add the same sentence to `docs-site/guide/attention.md` if that page has a
"where notifications go" section (check first; otherwise only voice.md).

### 1.4 Health and Always location from Settings → Permissions (0a7115da)

`docs-site/guide/devices.md` → "When the phone's permission is off": add how the two awkward ones
work, because the system doesn't behave like the others:

- **Health on iPhone:** iOS shows its Health sheet only once. After that, **Open Health** opens the
  Health app: tap your picture, then **Apps**, then **Casama**, and turn on what bots may read. The
  row counts as on once Casama can read steps.
- **Health on Android:** the row checks Health Connect's real grants, and offers to install Health
  Connect when it's missing.
- **Always location on iPhone:** the row asks for **Always** on top of **While using**. iOS gives one
  upgrade prompt; after that the row opens Settings.

### 1.5 Official MCP Registry (97a88096, 8331851c)

`docs-site/guide/mcp.md` → "Local over stdio": one line saying `@casama/mcp` is listed in the
official MCP Registry as `io.github.stackwares/casama`, so MCP clients that browse the registry can
add it from there.

## 2. Self-hosting and develop pages

### 2.1 Internal accounts (D-441)

`docs-site/self-hosting/configuration.md` → "Telemetry and observability" table: add
`INTERNAL_EMAILS` and `INTERNAL_EMAIL_DOMAINS` (comma-separated; accounts that match are marked
internal in product analytics: `is_internal` in PostHog, `traffic_type=internal` in GA4, so they can
be filtered out). Wording comes from `.env.example` lines 166–168 and D-441.

### 2.2 Map card tiles (D-444, D-428, D-310)

The map card's tile keys are build-time settings and aren't documented anywhere. Add a short
"Map cards" subsection to `docs-site/develop/contributing.md` → "Run the app" (where the other
`--dart-define` lives), and link to it from `self-hosting/configuration.md` → "Integrations":

- Order: Google Map Tiles → MapTiler → HERE → OpenStreetMap. A source without a key is skipped. A
  failing source (refused, rate-limited, offline) moves every later map in that app session to the
  next one.
- Keys: `CASAMA_GOOGLE_MAPS_KEY`, `CASAMA_MAPTILER_KEY`, `CASAMA_HERE_MAPS_KEY`, passed with
  `--dart-define` or `--dart-define-from-file=config/maps.json`. With none, maps use
  OpenStreetMap's public tiles.
- A caution, from D-444: cap a Google key's daily tile quota so overflow becomes a fallback, not a
  bill; HERE has alerts but no hard cap.

No key values and no vault item names on the public page.

## 3. Plan tracking (docs/)

### 3.1 Rows in `docs/PLANS.md`

- **APP-MENTIONS-PLAN:** move from "Not started" to "Done" (D-434; Phases 0–3 built 2026-11-20).
  Check first whether the app builds with it have shipped; if not, "Built" with "app builds".
- **WEEKLY-PLAN-PLAN:** move from "Not started" to "Built" or "Done" (D-432), after checking whether
  the server and store prices are live.
- **DOCS-REFRESH-PLAN** (this plan): its row, as added with this file.

### 3.2 Plan status lines that are out of date

Bring each plan's own status line in line with its `PLANS.md` row, checking `docs/DECISIONS.md` and
the deploy notes before writing "live":

| Plan | Status line says | PLANS.md says |
|---|---|---|
| LINK-PLAN | built on a branch | Done, live in prod |
| PLUGINS-AND-PACKS-PLAN | built on a branch, not merged | Done, live in prod |
| REACTIONS-PLAN | built, not deployed | Done, live 2026-11-17 |
| USAGE-PLAN | built, not deployed | Done, steps 1–8 live, step 9 dropped |
| SHOWCASE-PLAN | built, not committed or deployed | Done, live 2026-11-19 |
| MASTER-PLAN-2026-11 | (stale) | In progress, most stages built |
| VISUALS-PLAN | no status line | Done |
| WAITLIST-PLAN | approved, being built | In progress, Phases 1–3 live |

Each gets one line at the top, in the existing style: `Status: **done** (live <date>, D-…).` The
original status moves to "Original status:" where it carries information.

## 4. Questions for Oliver

1. **Map keys on the public docs (§2.2):** document the three `--dart-define` names for people who
   build their own app, or leave map tiles undocumented? Recommended: document them, no values.
2. **Internal accounts (§2.1):** these settings matter mostly to Casama Cloud. Document them for
   self-hosters, or put them under "Settings only Casama Cloud uses"? Recommended: the telemetry
   table, since they work on any server with analytics on.
3. **Deploy:** after the edits, deploy docs.casama.ai with `scripts/deploy-web.sh` (needs your yes,
   per AGENTS.md), or leave them for the next web deploy?

## 5. How it's done

- One commit, staged by path. `docs/PLANS.md`, `docs/WAITLIST-PLAN.md` and
  `docs-site/self-hosting/index.md` may still carry another session's uncommitted edits (admin
  security, D-448): commit only this plan's hunks, built from `git show HEAD:<file>`.
- Check: `pnpm --filter docs-site build` (or the docs site's build script) for dead links, then
  `python3 scripts/serve-web.py` and read the changed pages on :8733.
- Push to `main`; deploy only after Oliver's yes (question 3).
