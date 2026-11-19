# Watch protocol (D-410)

The wire formats the server, the phone app and both watch apps share. The plan is
`docs/WATCH-PLAN.md`; the HTTP contract is `packages/contracts/src/watch.ts` and
`packages/contracts/src/routes/watch.ts`; sample answers are in `packages/contracts/fixtures/watch/`.
Decisions taken: all 18 defaults in the plan's §13.

## 1. The key

- The watch makes 32 random bytes and keeps `cwt_` + base64url(bytes, no padding) (47 characters)
  in its own keychain / Keystore-wrapped storage. It never leaves the watch except in the
  `Authorization: Watch <key>` header to the server.
- Fingerprint: lowercase hex of `sha256("casama-watch-key:" + key)` (UTF-8). This is what the phone,
  the phone link and the code request carry, and what the server stores as `key_hash`.
- Default server for code sign-in: `https://api.casama.ai`. Sign-in through the phone tells the
  watch its server (self-hosted works only that way).
- `401` from the server with any code means the key is gone: wipe the key, the cache and every
  complication/tile, show "signed out". Two exceptions a watch knows by its state: while it shows
  a sign-in code, `GET /v1/watch/me` answers `401 watch_code_pending` until the code is allowed
  (keep polling every `poll_every_s`), and `invalid_watch_key` then means the code ran out.
- A route a watch key may not use answers `403 watch_key_not_allowed` (not 401, so a watch never
  wipes its key over it). More than 60 requests a minute per key: `429 rate_limited` with
  `Retry-After`.
- Allowing from the watch: `POST /v1/approvals/{id}/decision` answers `403 watch_allow_refused`
  with `detail` set to the reason (`high_risk`, `payment`, `setting`, `not_yours`) when the request
  is phone-only, and `403 watch_always_allow` for `always_allow: true`. Deny always works.
- Send `X-Casama-Surface: app|notification|complication|smart_stack|tile|control|siri` on actions,
  for counting (`watch_action`); `POST /v1/watch/ask` also takes it as `surface` in the body.
- Other codes: `watch_code_not_found` (404: wrong, used or expired code), `watch_key_taken` (409:
  that fingerprint belongs to someone else), `wrong_token_kind` / `bad_token` (400 on
  `PUT /v1/watch-keys/current`), `bot_not_found`, `chat_not_found`, `run_not_found`,
  `approval_not_found` (404), `nothing_to_send`, `nothing_heard`, `bad_audio` (400),
  `voice_unavailable` (409: no transcription on this server or workspace), `watch_details_hidden`
  (403 on read aloud when details are off or reply text is hidden), `not_found` (404: the target
  is in another workspace than the key's).
- At most 3 run streams per key: a fourth closes the oldest. A stream ends within 30 seconds of its
  key being removed.

## 2. The phone link

Same messages on both watches. Apple: WatchConnectivity dictionaries (`sendMessage` when reachable,
else `transferUserInfo`). Wear OS: Data Layer `MessageClient` on path `/casama/watch`, body UTF-8
JSON. Capabilities: the phone app declares `casama_phone`, the watch app `casama_watch`.

| Direction | `type` | Other fields |
|---|---|---|
| watch → phone | `sign_in` | `request_id`, `fingerprint`, `platform` (`watchos`/`wearos`), `name`, `model`, `app_version`, `os_version` |
| watch → phone | `open` | `link` (an app route to open on the phone) |
| phone → watch | `signed_in` | `request_id`, `server`, `org_id`, `org_name`, `person_name` |
| phone → watch | `sign_in_failed` | `request_id`, `reason` (`signed_out`, `declined`, `error`) |
| phone → watch | `context` | `server`, `org_id`, `org_name`, `person_name` (the phone switched workspace; the key was re-registered for it) |
| phone → watch | `sign_out` | none |

## 3. The phone app's channel `casama/watch`

Between Flutter and `WatchBridge.swift` / `WearBridge.kt`. Native code holds sign-in requests that
arrive while Flutter isn't running (UserDefaults / SharedPreferences) until `takeRequests`.

| Caller | Method | Arguments → result |
|---|---|---|
| native → Dart | `request` | `{request_id, platform, fingerprint, name, model?, app_version?, os_version?}` |
| native → Dart | `open` | `{link}` |
| Dart → native | `takeRequests` | → `List<Map>` of held requests (cleared) |
| Dart → native | `answer` | `{request_id, ok, server?, org_id?, org_name?, person_name?, reason?}` |
| Dart → native | `setContext` | `{server, org_id, org_name, person_name}` |
| Dart → native | `signOut` | `{}` |
| Dart → native | `status` | → `{supported, paired, installed}` |

Dart keeps the fingerprints it registered (they aren't secret) with the key ids, so it can
re-register them for another workspace and delete them when the phone signs out.

## 4. Pushes a watch reads

The phone's pushes (Apple mirrors them to the watch) and the pushes sent straight to a watch's own
token carry these data keys, all strings, beside whatever the phone already reads:

| Key | When |
|---|---|
| `watch_kind` | always: `approval`, `suggestion`, `reply`, `failed`, `brief`, `routine`, `takeover`, `other` |
| `kind` | always, but the phone's own values (`approval_request`, `reply`, `routine_result`…): watches read `watch_kind` |
| `notification_id` | inbox pushes (not "Open on phone") |
| `tag` | when the push has a collapse id (always when the person has an Apple Watch with its own token: `n-<notification_id>`) |
| `link` | always: an app route |
| `bot_id`, `bot_name`, `bot_avatar` | when a bot is involved |
| `approval_id`, `risk` | `approval` |
| `suggestion_id` | `suggestion` |
| `conversation_id`, `message_id`, `run_id` | `reply`, `failed`, `brief`, `routine` |
| `title`, `body` | Wear data messages (Apple uses `aps.alert`) |

- Apple categories: `APPROVAL`, `SUGGESTION`, `REPLY`. The watch registers the same identifiers,
  with actions `ALLOW`, `DENY` (APPROVAL), `DO_IT`, `NOT_NOW` (SUGGESTION) and its own layout for
  `REPLY` (quick replies + Reply).
- Apple direct pushes (the watch's own token, topic `ai.casama.app.watchkitapp`) use the same
  `apns-collapse-id` as the phone's copy.
- Wear OS: pushes to the watch's own Firebase token are data-only; the watch app draws them. Once it
  has registered its own token it turns the phone's bridging off for Casama, so nothing shows twice.

## 5. Strings

`node scripts/gen-watch-strings.mjs` writes `client/ios/Shared/WatchStrings.swift` (`WatchL10n`)
and `client/wear/app/src/main/res/values/watch_strings.xml` (`R.string.watch_*`) from the `watch*`
keys of `client/lib/l10n/app_en.arb` (`watchPhone*` keys are the phone's own).

## 6. Colours

| Role | Dark (watches are always dark) |
|---|---|
| Background | `#000000`; cards `#1C1C1E` (Apple) / surface container (Wear) |
| Needs you | amber `#F0A84A` |
| Working | green `#5FD49A` |
| Main button | orchid `#F2B0EC`, text on it `#3B0A3D` |
| Stop, high risk | red `#FF6B6B` |
| Secondary text | `#9A9AA0` |
