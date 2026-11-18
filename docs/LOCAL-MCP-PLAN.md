# Local MCP servers that need a sign-in: the plan

Status: **proposed** (2026-11-18). Nothing built. Waiting for Oliver's go-ahead.

## The problem

Oliver asked whether Casama can drive T3 Code through its MCP server, then: "not just t3code
support though can we widen it".

T3 Code runs an MCP server at `http://127.0.0.1:3773/mcp`. Asked without a credential it answers
`401 invalid_mcp_credential`, and it publishes standard MCP OAuth: protected-resource metadata,
self-registration (`/oauth/mcp/register`), PKCE, and the scopes `orchestration:read` and
`orchestration:operate`. A lot of local tools are going this way: desktop apps and dev servers
that listen on localhost but want a token, either one you paste or one from an OAuth sign-in.

Casama's local MCP servers (D-096) come in two kinds:

| Kind | What it is | Sign-in today |
| --- | --- | --- |
| Command (stdio) | the app starts a program | env values, kept on the computer |
| Address (loopback) | `http://127.0.0.1` or `[::1]` only | **none**: no header, no OAuth |

The address bridge (`dart/computerd/lib/src/mcp_bridge.dart`, `_LoopbackUpstream`) sends only
content type, accept, protocol version and session id. So every local server that wants a token
fails, T3 Code included. The 2026-11-16 T3 Code test must have gone through a hand-made stdio
command (the app test uses `node t3-mcp.mjs` as its example). Whatever did T3 Code's sign-in
isn't in the repo, so nobody else could set it up.

Workspace connections (cloud servers) already have both: a pasted key or header
(`McpAdapter`, `auth_header`), and MCP OAuth with self-registration and PKCE (`routes/apps.ts`).
That OAuth runs **on the Casama server**, which can't reach a server on someone's `127.0.0.1`.
For local servers the sign-in has to happen on the computer itself.

## What we'd build

Five parts. Parts 1 and 2 cover T3 Code and most other local servers. Parts 3–5 make it wider.

### 1. Headers on address servers

The add form for an address server gets an optional **Sign-in** section:

- **None** (today)
- **Token**: one secret field. Sent as `Authorization: Bearer <token>`.
- **Header**: header name plus value, for servers that use `X-API-Key` and the like.

These values are stored like stdio env values: in the app's secure storage (or the 0600 file),
passed only to the embedded computerd, never to the workspace. The workspace's `summary` stays
the address. Changing a header changes the server's signature, so the bridge restarts its session.

### 2. MCP OAuth for address servers, run on the computer

When an address server answers `401` with `WWW-Authenticate: Bearer resource_metadata=…` (or
the user picks **Sign in** in the form), the desktop app does the MCP auth flow itself:

1. Read the protected-resource metadata, then the auth server's metadata. Accept only an auth
   server on the same loopback host. A local server pointing the browser at an outside auth
   server is refused, with an error that says why.
2. Register (`registration_endpoint`) as "Casama on <device name>". The redirect is a
   `LoopbackSignIn` listener on `127.0.0.1:<free port>/callback` (the helper the desktop sign-in
   already uses, `client/lib/core/desktop_sign_in_io.dart`).
3. Open the browser at the authorize URL (PKCE S256, `state`, every advertised scope by default).
   The person approves it in the other app, T3 Code's approval page for example.
4. Swap the code for tokens. Keep the access token, refresh token, expiry and client id with the
   server's other secrets on the computer.
5. computerd sends `Authorization: Bearer …`. Before expiry, or on a `401`, it refreshes once.
   If refreshing fails, the bridge answers a new error, `mcp_sign_in_needed`.

`mcp_sign_in_needed` becomes a card in the chat: **"T3 Code on MacBook needs you to sign in
again"** with a **Sign in** button. Tapping it runs the flow on that computer. The bot never sees
the token.

The add form gets a **Test connection** result for this: "Signed in as … (scopes …)" or the
reason it failed.

### 3. Servers on the local network, not just this computer

Many people run MCP servers on a NAS, a homelab box or a dev machine on the LAN. The address
kind would accept:

- `http://` on loopback (today), on private ranges (10/8, 172.16/12, 192.168/16, fd00::/8) and
  on `.local` names;
- `https://` anywhere the computer can reach, for servers behind a VPN or company network that
  the Casama server can't reach.

The form says plainly: "Bots that can use this computer can call this server." Public internet
servers still belong in workspace connections. The form suggests that when the host resolves to
a public address, but doesn't block it (it may only be reachable over the VPN).

OAuth (part 2) on a LAN server: same rule, the auth server must be the same host.

### 4. Find and import servers the person already has

The desktop app already scans for coding agents. It would also offer **Add from…** with servers
it finds in:

- **T3 Code**: when `~/.t3/userdata/server-runtime.json` exists, offer "T3 Code" with its `origin`
  plus `/mcp`, set to OAuth. Read the port each time the server starts, since it can change between
  launches.
- **Claude Code** (`~/.claude.json` user-level and project `mcpServers`), **Claude Desktop**
  (`claude_desktop_config.json`), **Cursor** (`~/.cursor/mcp.json`), **VS Code** (`mcp.json`),
  **Codex** (`~/.codex/config.toml` `mcp_servers`), **Windsurf**.

Each one is shown with a checkbox. Commands, args, env and headers come across; `${VAR}`
placeholders are filled from the person's shell environment when possible, otherwise shown as
empty fields to fill in. Env values are listed with their values hidden, and nothing is imported
without a tap. Remote (https, public) entries are offered as workspace connections instead.

### 5. Transport gaps

- **Legacy HTTP+SSE servers** (`GET /sse` + `POST /messages`), which many older servers still
  use: the address kind detects them (a `GET` that returns `text/event-stream` with an `endpoint`
  event) and bridges them like stdio.
- **Server-initiated requests**: the bridge answers "not supported" today. Elicitation (the server
  asks the person a question) would become an approval-style card. Sampling and roots stay
  unsupported. This part can wait; it's here so it isn't forgotten.

## What doesn't change

- The workspace sees only key, label, kind and summary (address or command). Tokens, headers,
  env values and OAuth clients stay on the computer.
- Which bots can use a local server (D-096 attach rules, computer allow-list) stays as it is.
- Risk: local MCP tools without annotations stay medium risk.

## Data and contracts

- `LocalMcpConfig` / `LocalMcpServer`: add `headers` (map) and `auth`
  (`none | token | header | oauth`), plus an `oauth` record (issuer, client id, token, refresh
  token, expiry, scopes) kept with the secrets. Parsing stays tolerant of the old shape.
- `packages/contracts/src/local.ts`: `kind` stays `stdio | loopback` (rename the label to
  "Address" in the UI only). Add `auth` to the summary so the workspace can show "signs in" without
  seeing anything secret.
- New bridge error code `mcp_sign_in_needed`, passed to the worker. `LocalMcpAdapter` turns it into
  the sign-in card and doesn't mark the integration broken (like an offline computer).
- No migration: local servers are integrations of kind `local_mcp` with config only.

## Phases

1. Headers on address servers (computerd, form, storage, tests).
2. OAuth on the computer + the sign-in card + T3 Code live check.
3. LAN and https addresses.
4. Find and import (T3 Code first, then Claude Code/Desktop, Cursor, VS Code, Codex, Windsurf).
5. Legacy SSE. Elicitation only if Oliver wants it now.

Decision entry: **D-363** when it starts.

## Tests

- computerd: a fake address server that wants a bearer token (refuses without it, accepts with
  it); one that wants OAuth (metadata, register, authorize, token, refresh, refresh failing →
  `mcp_sign_in_needed`); an auth server on another host is refused; legacy SSE fake.
- App: the form with each sign-in kind, secrets kept on the device and out of the sync payload
  (extend `client/test/local_mcp_test.dart`); the import list with fake config files; the
  sign-in card.
- API/worker: `mcp_sign_in_needed` through the real tunnel becomes the card, not a broken
  connection.
- Live: T3 Code on Oliver's Mac. Add it from **Add from… → T3 Code**, approve in T3 Code, then a bot
  lists projects and starts a thread.

## Open questions for Oliver

1. **LAN and https addresses (part 3):** fine to allow, with the warning? It does let any bot that
   can use the computer reach anything on that network.
2. **Import (part 4):** all the listed apps, or T3 Code + Claude Code + Cursor to start?
3. **Elicitation:** now, or later?
4. **T3 Code scopes:** ask for `orchestration:operate` (bots can start threads, send messages) or
   only `orchestration:read` by default?
