# The phone browser: how its three parts talk

docs/PHONE-BROWSER-PLAN.md is the plan. This file is the contract between the parts in the app.

```
server ── device socket ── Dart (this folder) ── casama/app_browser channel ── native web area
                                                                                 └ page script
```

Everything here is compiled in only with `--dart-define=CASAMA_APP_BROWSER=true` (and the native
flag, see "Build switch"). Without it the app has no web area.

## 1. Server to app: the device socket

The same socket the desktop app uses (`client/lib/features/companion/companion_io.dart`):
`wss://<api>/v1/local-computer/connect`, header `Authorization: Device <token>`, plus
`x-casama-os: "iOS 26.1"` or `"Android 16"`.

- Server sends `{type:"ready", device_id, computer_id:null}` once.
- Server sends `{type:"request", id, method:"POST", path:"/browser/<action>", body:<base64 JSON>}`
  and `{type:"cancel", id}`.
- App answers `{type:"response", id, status:200, headers:{}}`, one
  `{type:"chunk", id, data:<base64 JSON of the result>}`, then `{type:"end", id}`.
- `GET /health` answers `{ok:true}`. Anything else is 404 `{ok:false, code:"not_found"}`.
- The app sends `{type:"hello", platform:"app", version}` on open and every 20 seconds.

The request body (`BrowserCall` in `packages/contracts/src/browser.ts`, plus what the server adds):

```
{ action, args, run: { id, bot_id, bot_name, conversation_id },
  policy: { blocked_sites, allowed_sites, allowed_kinds, own_urls },
  expect?: "<fingerprint>" }
```

The result is a `BrowserResult`: `{ok:true, text, url?, image?:{data, media_type},
file?:{name, media_type, data}}` or `{ok:false, code, message}`.

Actions the app answers:

| action | what the app does | result |
|---|---|---|
| `open` | site gate on `args.url`, then load it and wait for the page to settle (15 s cap) | `text: "Opened <title>"`, `url` |
| `snapshot`, `read`, `extract`, `scroll`, `wait` | page script command of the same name | its `text`, plus `url` |
| `url` | native `url` | `text: <url>`, `url` |
| `probe` | page script `probe` with `args` (`{ref}` or `{focused:true}`) | `text: JSON.stringify({facts, fingerprint})` |
| `ask` | show the step ask (`args.reason`, `args.step`, `args.name`, `run.bot_name`); wait up to 5 minutes | `text: "allow"`, `"deny"` or `"timeout"` |
| `handoff` | show "Your turn" with `args.reason`; answer at once | `text: "shown"` |
| `click` | page script `locate` (with `expect` as `fingerprint`); with real taps, native `tap` at its x,y then `click` with `synthetic:false`; otherwise `click` with `synthetic:true` | `text`, `url` |
| `fill`, `type`, `press` | page script, passing `expect` as `fingerprint` | `text`, `url` |
| `upload` | page script `upload` with `args.ref` and `args.file` (`name`, `media_type`, `data`) | `text` |
| `download` | site gate on `args.url`, page script `download` | `file`, `text` |
| `screenshot` | native `screenshot` | `image: {data, media_type:"image/jpeg"}`, `text: ""` |
| `dialog` | answer the pending page dialog with `args.accept`, `args.text` | `text` |
| `tabs` | one page | `text: "1: <title> <url> (current)"` |
| `switch_tab` | with `args.url`: same as `open`; otherwise nothing | `text` |
| `stop` | the bot is done: hide the "working" state, keep the page | `text: "Done"` |
| `console`, `network`, `page_text` | never arrive (the server refuses them); answer `unsupported` | |

Codes the app produces itself: `refused` (a site that is never allowed), `asked_denied` (the person
said no to a site), `handed_off`, `away` (the chat is no longer on screen, or the person took
over and didn't hand back within 8 minutes), `unsupported`, `error`, and whatever the page script
returns (`stale_ref`, `covered`, `page_changed`, ...).

Every call first checks that the run's conversation is the chat on screen. If it isn't, the answer
is `away`. A call for a different run than the one working ends the earlier run's session.

While the person has taken over (they touched the page), calls wait for Hand Back, up to 8 minutes.

## 2. Site gate (Dart)

Before a main-frame navigation loads, and again on the address a page lands on:

1. `about:blank` is allowed; a non-http(s) address is refused.
2. Casama's own addresses (`casama.ai`, `casama.link`, `kasama.ai`, their subdomains, and the
   hosts of `policy.own_urls`) are refused.
3. `policy.blocked_sites` (workspace and this phone's "never" list) are refused.
4. Off-by-default kinds (banking, health, passwords, government) are refused unless the kind is in
   `policy.allowed_kinds`; a switched-on kind asks every run.
5. `policy.allowed_sites` and sites answered "once" in this run are allowed.
6. Everything else asks: Once, Always, Never. "Always" and "never" are saved on the device row
   (`PATCH /v1/local-devices/{id}` with `allowed_sites` / `blocked_sites`). No answer in 5 minutes
   is no.

Matching is the server's: `example.com` matches itself and its subdomains, `*.example.com` only
subdomains, a leading `www.` is ignored. The reference is `appSiteDecision` in
`packages/domain/src/app-browser-sites.ts`. `pnpm --filter @casama/domain gen:app-browser` writes
the lists the Dart code reads (`client/assets/app_browser/guard.json`: Casama's domains, the
hosts of each off-by-default kind, and a regular expression per kind for the host) and the cases
the Dart code must reproduce (`client/test/fixtures/app_browser_sites.json`: for each case a
policy name, the "once" list, a url, and the expected `{kind, host?, why?, site_kind?}`). Sites
added by the server without a release come from `GET /v1/browser-guard`.

The gate applies to a bot's steps. When the person browses by hand (Sign In to a Site), only
steps 1 and 2 apply.

## 3. Dart to native: `casama/app_browser`

One web area per app, created on first use and kept while the app lives. The platform view type is
`casama/app_browser_view` (no creation params).

Methods Dart calls (all return a map or null; errors are `PlatformException`):

| method | args | returns |
|---|---|---|
| `supported` | | `{supported: bool, reason: String?, realTaps: bool}` |
| `load` | `url` | |
| `command` | `json` (a page-script command, see `packages/page-agent/README.md`) | `json` (its answer); `timeout_ms` optional, default 30000 |
| `tap` | `x`, `y` (CSS px in the viewport) | (Android only) |
| `screenshot` | `quality` (default 70) | `{data: base64 jpeg}` |
| `url` | | `{url, title, loading: bool, canGoBack: bool, canGoForward: bool}` |
| `back`, `forward`, `reload`, `stop` | | |
| `answerDialog` | `accept: bool`, `text: String?` | |
| `clearData` | `host: String?` (null clears everything) | |
| `dispose` | | |

Methods native calls on Dart:

| method | args | Dart returns |
|---|---|---|
| `navigate` | `url`, `redirect: bool`, `user: bool` (started by a real touch) | `true` to let it load |
| `pageStarted` | `url` | |
| `pageFinished` | `url`, `title` | |
| `landed` | `url` (the address actually committed, after redirects) | `true` to keep it; `false` makes native load `about:blank` |
| `userTouched` | | (a real finger touched the web area) |
| `dialog` | `kind` (`alert`/`confirm`/`prompt`), `message` | (answered later with `answerDialog`) |
| `gone` | `reason` | (the web content process ended; the page is lost) |

## 4. Build switch

- Dart: `const bool.fromEnvironment('CASAMA_APP_BROWSER')`. Every entry point into this folder
  checks it, so a build without it tree-shakes the folder away.
- iOS: Swift flag `CASAMA_APP_BROWSER` (the files are wrapped in `#if CASAMA_APP_BROWSER`).
- Android: Gradle property `casamaAppBrowser=true` adds the `appBrowser` source set and the
  `androidx.webkit` dependency.
- `scripts/` release builds leave all three off until the plan's Stage 2 release.
