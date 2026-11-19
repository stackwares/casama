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
  `Retry-After`. Keys that don't work are counted per address (an IPv6 address by its /64), 30 a
  minute; a key that worked in the last ten minutes and a watch waiting on its code aren't counted,
  so junk sent from a shared address doesn't lock out the watches there.
- Every error is a problem document with a `code`. Watches read the `code`, not only the status:
  a 404 with `not_found` is "not in this watch's workspace" (say so and offer Open on phone), which
  is not "already answered" (`approval_already_decided`, 409) or gone (`approval_not_found`).
- Allowing from the watch: `POST /v1/approvals/{id}/decision` answers `403 watch_allow_refused`
  with `detail` set to the reason (`high_risk`, `payment`, `setting`, `not_yours`) when the request
  is phone-only, and `403 watch_always_allow` for `always_allow: true`. Deny always works. A tool
  that spends money (a payment, a paid data call) is `payment`, whatever its risk. The answer to a
  watch never carries the request's arguments (`args_redacted` is empty), and with Show details off
  its `tool_name` and `summary` are empty too: a watch's view of a request is
  `GET /v1/watch/approvals/{id}`.
- Send `X-Casama-Surface: app|notification|complication|smart_stack|tile|control|siri` on actions,
  for counting (`watch_action`); `POST /v1/watch/ask` also takes it as `surface` in the body.
- A sign-in code works until it is allowed, replaced by a new one or ten minutes old. Looking it
  up (`GET /v1/watch-codes/{code}`) doesn't use it up; a person who types five wrong codes in an
  hour waits (429).
- Other codes: `watch_code_not_found` (404: wrong, used or expired code), `watch_key_taken` (409:
  that fingerprint belongs to someone else), `wrong_token_kind` / `bad_token` (400 on
  `PUT /v1/watch-keys/current`), `bot_not_found`, `chat_not_found`, `run_not_found`,
  `approval_not_found` (404), `nothing_to_send`, `nothing_heard`, `bad_audio` (400),
  `voice_unavailable` (409: no transcription on this server or workspace), `watch_details_hidden`
  (403 on read aloud when details are off or reply text is hidden), `not_found` (404: the target
  is in another workspace than the key's).
- At most 3 run streams per key: a fourth closes the oldest. A stream ends within 30 seconds of its
  key being removed, and follows a change to Show details, Hide reply text or the allow level
  within the same 30 seconds.
- A bot's chat without a `conversation_id` (`GET /v1/watch/chats/{bot_id}`) is the person's own
  latest chat with that bot, never a coworker's chat with a shared bot.
- `can_speak` is false for a reply whose words are hidden (details off, or Hide reply text).
- Keys go with the membership: leaving a workspace or being removed from it deletes the person's
  watch keys (and widget keys) there. `DELETE /v1/watch-keys` (the person's session only, never a
  watch key) deletes all of their watch keys in every workspace and answers `{ "deleted": n }`:
  the phone's "Sign Out Everywhere".
- Registering a fingerprint again (`POST /v1/watch-keys`: the phone moved to another workspace, a
  reinstall) updates the key and keeps how it was first signed in (`paired_by`). The "is signed
  in" notice and the `watch_paired` event are for a new key only.

## 2. The phone link

Same messages on both watches. Apple: WatchConnectivity dictionaries (`sendMessage` when reachable,
else `transferUserInfo`). Wear OS: Data Layer `MessageClient` on path `/casama/watch`, body UTF-8
JSON. Capabilities: the phone app declares `casama_phone`, the watch app `casama_watch`.

| Direction | `type` | Other fields |
|---|---|---|
| watch → phone | `sign_in` | `request_id`, `fingerprint`, `platform` (`watchos`/`wearos`), `name`, `model`, `app_version`, `os_version` |
| watch → phone | `open` | `link` (an app route to open on the phone), `title` (optional: what it is, for a notification) |
| phone → watch | `signed_in` | `request_id`, `server`, `org_id`, `org_name`, `person_name` |
| phone → watch | `sign_in_failed` | `request_id`, `reason` (`signed_out`, `declined`, `error`) |
| phone → watch | `context` | `server`, `org_id`, `org_name`, `person_name` (the phone switched workspace; the key was re-registered for it) |
| phone → watch | `sign_out` | none |

- **`signed_in` is for one request.** A watch accepts it only when `request_id` is one it issued
  for the key it holds now (it keeps the last few, and forgets them when the key is wiped). An
  answer to an older key's request, or one that arrives after the watch signed out, changes nothing.
- **A watch asks by itself only the first time.** After the person signed it out, or the phone or
  the server removed it, it shows "Signed out" with a button and waits for a tap.
- **Open on phone.** Apple: `open` is sent with a reply handler and the iPhone answers
  `{ "front": true|false }` (true only while the app is on screen); it opens the link either way.
  Without `front: true` (no answer in a few seconds, an older phone app) the watch also calls
  `POST /v1/watch/handoff`, which leaves a notification on the person's phones. Android: when the
  phone app isn't on screen it posts its own notification that opens the link (it can't come to
  the front from the background); with no phone in reach the watch calls the handoff route.

## 3. The phone app's channel `casama/watch`

Between Flutter and `WatchBridge.swift` / `WearBridge.kt`. Native code holds sign-in requests
(UserDefaults / SharedPreferences) until they are answered: one per fingerprint (a newer request
from the same watch replaces the older), each stamped with when it arrived (`at`, milliseconds),
and dropped after 15 minutes. `takeRequests` reads them without clearing; `answer` removes the one
it answers. A request that arrives while nobody is signed in on the phone stays held and is
answered once someone signs in.

| Caller | Method | Arguments → result |
|---|---|---|
| native → Dart | `request` | `{request_id, platform, fingerprint, name, model?, app_version?, os_version?, at?}` |
| native → Dart | `open` | `{link, title?}` |
| Dart → native | `takeRequests` | → `List<Map>` of held requests (not cleared) |
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
| `org_id` | whenever the push is about a workspace: which one. A watch answers only requests in its key's workspace; for another it offers Open on phone instead of buttons |
| `approval_id`, `risk` | `approval` |
| `can_allow` | `approval`, in the copies sent to a watch's own token only: `tap`, `hold` or `phone`, what this person's watch may do (the rule `GET /v1/watch/approvals/{id}` answers with). Absent in the phone's copy (and so in Apple's mirrored one): ask the server then |
| `suggestion_id` | `suggestion` |
| `conversation_id`, `message_id`, `run_id` | `reply`, `failed`, `brief`, `routine` |
| `title`, `body` | Wear data messages (Apple uses `aps.alert`) |
| `user_id` | Wear data messages: whose push it is |

- Apple categories: `APPROVAL`, `SUGGESTION`, `REPLY`. The watch registers the same identifiers,
  with actions `ALLOW`, `DENY` (APPROVAL), `DO_IT`, `NOT_NOW` (SUGGESTION) and its own layout for
  `REPLY` (quick replies + Reply).
- Apple direct pushes (the watch's own token, topic `ai.casama.app.watchkitapp`) use the same
  `apns-collapse-id` as the phone's copy.
- Wear OS: pushes to the watch's own Firebase token are data-only; the watch app draws them. Once it
  has registered its own token it turns the phone's bridging off for Casama, so nothing shows twice.
- Which watches hear a push: an Apple Watch's own token gets the pushes of the workspace its key
  is in (the iPhone mirrors the rest). A Wear OS watch's token gets the person's pushes from every
  workspace, because with bridging off nothing else would reach the wrist; `org_id` tells it which
  it can answer.
- **Show details off** (`watch_prefs.show_details`): the copies sent to a watch's own token carry
  general words instead of the real ones. The title is the bot's name (else "Casama"); the body is
  "Needs your OK" (`approval`), "Has a suggestion" (`suggestion`), "Replied" (`reply`), "Couldn't
  finish" (`failed`), "Finished a routine" (`routine`), "Your brief is ready" (`brief`), "Needs you
  to take over" (`takeover`) or "New activity". Ids, `watch_kind`, the category, the collapse id,
  `org_id`, `can_allow` and `bot_name` stay. The phone's own copy is unchanged, so what an iPhone
  mirrors to an Apple Watch follows the phone's settings.
- Through Casama Cloud's relay with private notifications on, the relay gets no text for a watch
  either: "Casama" / "New activity", in the Wear data too.

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
