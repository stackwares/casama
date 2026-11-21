# MCP servers in chat: plan

Status: **built** (2026-11-21, D-473). All six phases are done and tested; nothing is deployed and
no app build has been made. What differs from the sections below is in "Status of the build" at the
end and in D-473.

Original status: not started (written 2026-11-21). Every decision is made (§3, Oliver: "decide all
for me"), then "build all in one go".

## 1. Goal

A bot can suggest any MCP server in a chat, and the person connects it right there: tap the card,
sign in or paste a key, pick the tools, and the bot carries on. That covers servers in Casama's
catalog, servers in the public MCP registry, and custom ones by address. No trip to Settings.

## 2. What exists today (checked 2026-11-21)

| Piece | Where | What it does | Gap |
|---|---|---|---|
| `connections.offer` (core tool, D-259) | `packages/agent/src/tools/settings.ts` | Card with a Connect button per app; the app opens the connect sheet and tells the bot "connected" afterwards | Catalog and gallery apps only; any other id is refused |
| `mcp.add` | same file | Bot adds a server for itself by https address or by a command on its computer; the person approves | Key or header auth only. A server that needs a browser sign-in is added "not answering" |
| `mcp.remove`, `connections.attach`, `connections.list` | same file | Remove, attach, list | None for this plan |
| App sign-in (OAuth) | `apps/server/src/api/routes/apps.ts` (`connectApp`, `/oauth/callback`, `integration_oauth_flows`) | Discovery, self-registration or client metadata document, PKCE, token refresh | Starts from a catalog `app_id` only (`findApp`); owners and admins only |
| Custom server in Settings | `POST /v1/integrations` (`kind: mcp`) | Address plus an optional key | No browser sign-in |
| Local servers on a paired Mac (D-096, D-363) | computerd, `local_mcp` | Sign-in, import, questions | The bot can't suggest one |
| Card actions in the app | `client/lib/features/chat/local_actions.dart` | `app:connect`, `app:route` | No action for a server that isn't in the catalog |

So the missing parts are: a sign-in for a server that isn't in the catalog, a card for it, and a
way for the bot to find servers.

## 3. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | New tool or extend one? | Extend `connections.offer` with `servers` (up to 2 per card, next to `apps`). It is already a core tool, so no new tool definition goes out with every model call |
| 2 | What the bot passes | `name`, `why`, and `url` (https). `url` may be left out; then the sheet asks the person for the address. That is the path for addresses that hold a key (Zoho style, D-346) |
| 3 | Addresses in the chat | The tool refuses an address with a user, password or query string, so no key lands in the transcript. The card shows the host only |
| 4 | How the server signs in | The API probes the address: no auth, browser sign-in (OAuth), or a key. The sheet shows the matching form. The bot doesn't have to know which |
| 5 | Sign-in on another host | Allowed (many servers use a separate sign-in host). The sheet names the sign-in host before the browser opens |
| 6 | Who may connect | Same rule as catalog apps today: owners and admins. Nothing changes for members |
| 7 | Whose connection it is | A workspace connection (`kind: mcp`), shown in Settings → Integrations as "Added in chat by <bot>". It is attached only to the bot that offered it; other bots use `connections.attach` |
| 8 | Which tools | After connecting, the sheet lists the server's tools with a switch each, all on. Done saves the list as the bot's tool allowlist |
| 9 | Trust label | Catalog, gallery and public-registry servers show their source. Anything else shows "Not checked by Casama" on the card and the sheet |
| 10 | Risk of a custom server's tools | Never below medium, whatever the server claims about itself, so the person's approval settings apply. Tool descriptions keep today's length limits |
| 11 | Full access (D-394) | Never skips the tap. Connecting a server always needs the person |
| 12 | `mcp.add` | Stays for keys and for commands on the bot's computer. When a remote server asks for a browser sign-in, it returns "needs sign-in: use connections.offer with servers" instead of adding a dead connection |
| 13 | Finding servers | A new lazy tool `mcp.find` searches the public MCP registry for remote https servers (cached a day). Not a core tool |
| 14 | Servers on the person's own Mac | Last phase: an offer with `command` opens the app's add-local-server sheet, prefilled, on a Mac with Run on This Mac. Elsewhere the bot runs it on its own computer with `mcp.add` |
| 15 | Limit | 25 chat-added servers per workspace; the tool says so when it's reached |
| 16 | Plain-http servers | Refused, as in `mcp.add`. A self-hosted Casama on plain http can't do browser sign-in (D-168); the sheet offers the key form and says why |
| 17 | Calls, watch, routines | A routine or call may show the card; nothing connects without a tap in the app. No watch screen |
| 18 | Cost | No paid dependency (the registry is free), so no `docs/COSTS.md` change |
| 19 | Old app builds | Server buttons go out only to app builds that know the new action; older ones get today's "More apps" button and a line naming the address to add in Settings (see Phase 0, check 3) |

## 4. How it works

1. The bot calls `connections.offer` with `servers: [{ name: "Linear", url: "https://mcp.linear.app/mcp" }]`
   and a reason.
2. The tool checks the address, skips servers the workspace already has (matched by host and path,
   and tells the bot to attach instead), and shows a card: reason, a "Connect Linear" button, the
   host, and the trust label. The button's action is `app:connect_server` with the name, address
   and bot id.
3. The app opens the connect-server sheet (native Flutter, built from the parts of
   `connect_app_sheet.dart`). It calls the probe and shows one of: Connect (no auth), Sign in
   (opens the system browser or in-app browser tab), or a key field.
4. The API creates the connection and attaches it to the bot. For sign-in it reuses the catalog
   flow: discovery, self-registration or the client metadata document at `/oauth/client.json`,
   PKCE, the same `/oauth/callback`, tokens in Vault, the same refresh.
5. The sheet lists the tools; the person switches off any they don't want and taps Done.
6. The app sends the `connected` action, as it does for catalog apps, and the bot goes on with the
   tools from its next message.

## 5. Changes

**Contracts (`packages/contracts`)**
- `ProbeServerRequest` / `ProbeServerResponse` and `POST /v1/apps/probe`: `{ org_id, url }` →
  `{ auth: "none" | "oauth" | "key", host, sign_in_host?, source: "catalog" | "gallery" | "registry" | "unknown", app_id? }`.
  When the address belongs to a catalog app, `app_id` is set and the app uses the normal app sheet.
- `ConnectAppRequest` gains `server: { url, name }` (instead of `app_id`), `bot_id` and
  `tool_allowlist`. Exactly one of `app_id` and `server`.
- `pnpm gen` for the Dart and TS clients.

**Server (`apps/server`)**
- `connectApp` takes the `server` form: same admin check, the limit from §3 #15, the guarded fetch
  for every outbound request, flow rows with `app_id = 'custom'`.
- `/oauth/callback` finishes custom flows: creates the `mcp` integration with
  `config.added_in_chat_by = <bot id>`, attaches it to the bot, lists the tools.
- The probe: an unauthenticated `initialize`; a 401 with protected-resource metadata means sign-in,
  any other 401 or 403 means key, success means none. Rate-limited per person.
- Risk floor for custom servers (§3 #10) where tool risk is read from a connection's cache.
- Audit rows: `integration.offered_by_bot`, `integration.connected_in_chat`.

**Agent (`packages/agent`)**
- `OfferArgs.servers`, the card, the already-connected check, and the description (kept short: it
  goes out with every call).
- `mcp.add`: the sign-in hint (§3 #12).
- `mcp.find` (lazy): query → up to 8 servers with name, address and one line each.
- One prompt line where connection guidance lives: for an app outside the catalog, look with
  `mcp.find` and offer the server; never send the person to Settings to add it by hand.

**App (`client`)**
- `app:connect_server` in `local_actions.dart`; `connect_server_sheet.dart` (new file,
  `material_ui` imports); the trust label and host on the card through the existing A2UI
  components (no new component).
- Settings → Integrations shows "Added in chat by <bot>" on those rows.
- New strings in every locale file.

**Docs**
- `docs-site` integrations guide, `CHANGELOG.md`, `docs/ARCHITECTURE.md`, one `docs/DECISIONS.md`
  entry per phase (take the next free number at build time), this file's status and its
  `docs/PLANS.md` row.

## 6. Phases

Each phase ends with its own tests green and a commit. Nothing is deployed and no Flutter build is
run without Oliver's yes.

| Phase | Work | Done when |
|---|---|---|
| 0. Checks | (1) Probe five public servers by hand (for example Linear, Notion, Sentry, Stripe, one key-only server) and note which sign-in route each takes. (2) Confirm the public registry's search API and its fields. (3) Find how the server knows the app's build, for §3 #19; if it can't, ship the action in an app release first and switch the card on after. (4) Check `integration_oauth_flows.app_id` accepts `custom` without a migration | Findings written at the end of this file; any decision they change is updated |
| 1. Server | Probe, custom connect, callback, risk floor, limit, audit | Server tests with a fake MCP server and a fake sign-in server: none, key, sign-in, sign-in on another host, plain http refused, private address refused, member refused, limit reached |
| 2. Agent | `connections.offer` servers, `mcp.add` hint, prompt line | Agent tests: card shape, address with a query refused, already-connected skipped, hint returned |
| 3. App | Action, sheet, tool switches, Settings label, strings | Widget tests for the three forms and the `connected` follow-up; `flutter analyze` clean; one live check on the web app against the local stack |
| 4. Finding | `mcp.find` over the registry, cached | Agent test with a recorded registry reply; a live chat where "connect me to <service>" ends in a working card |
| 5. Local | Offer with `command` on a Mac with Run on This Mac | Widget test for the prefilled sheet; live check on this Mac |

Then, each after its own yes and in the usual order: server deploy, web app, Android with Wear OS,
iOS, Mac.

## 7. Risks

| Risk | Handling |
|---|---|
| A web page or message tells the bot to offer a hostile server | Nothing connects without the person's tap; the card and sheet show the host and "Not checked by Casama"; tools start at medium risk; full access doesn't skip it |
| The API is made to call private addresses | Every probe and sign-in request goes through the guarded fetch; redirects are re-checked |
| A key ends up in the chat | Addresses with a query or credentials are refused by the tool; such addresses are typed into the sheet |
| A server's sign-in refuses self-registration | The sheet says the server doesn't allow new apps to sign in and offers the key form when the probe saw one |
| Old app builds show a dead button | §3 #19 |
| The registry lists a bad server | The source label says "public registry", not "checked"; the same tap, host and risk rules apply |

## 8. Not in this plan

- Members connecting servers without an admin.
- A review or allowlist of custom servers for a workspace.
- Stdio servers on a phone.
- Suggesting plugins (already there: `plugins.suggest`).

## Status of the build (2026-11-21)

Phase 0 findings:

- Linear, Notion, Sentry and Stripe answer 401 with OAuth metadata (browser sign-in); DeepWiki and
  Context7 answer without one. A key-only server answers 401 or 403 with no metadata.
- The public registry is `GET https://registry.modelcontextprotocol.io/v0/servers?search=&version=latest`;
  each entry has `remotes` with a type and a URL.
- The server can't tell which app build it is talking to. §3 #19 changed: a server's button is an
  `app:route` with the server beside the path, so older builds open Settings instead.
- `integration_oauth_flows.app_id` is plain text: `custom` needs no migration.

Differences from the plan:

- Two new routes (`/v1/apps/probe`, `/v1/apps/connect-server`) instead of new fields on
  `/v1/apps/connect`. The sheet narrows the bot's tools with the existing attach route.
- Two trust states, not three: the registry can't be looked up by address (§3 #9).
- The limit counts servers marked unverified, whoever connected them.

Left to do, each after Oliver's yes: push, server deploy, web app, then the app builds.
