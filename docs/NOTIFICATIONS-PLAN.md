# Notifications: replies that reach you, and pushes people keep turned on

Status: **approved and built, D-325** (2026-11-16). Oliver took every default in §11; §13 is the
wire contract as built. This plan sits next to D-324 (the island): the island shows *state* and never makes a
sound, and this plan covers the pushes that *alert*.

## 0. Summary

Today, if you ask a bot something, lock your phone and wait, nothing tells you the answer is
ready. A normal chat reply sends no push. A push arrives only when the bot happens to call
`notify.user`, a routine has `notify` on, or something needs you (an approval, a secret, a call).
For an assistant you hand work to and walk away from, the most important notification is the one
that's missing.

The plan, in order of value:

| # | What | Why |
|---|---|---|
| A | **Reply-ready push** when a chat run you started finishes after you stopped watching | The missing core notification |
| B | **Couldn't finish** push when that run fails | Long runs that fail are silent today |
| C | **Don't buzz the chat you're looking at**, on any device | Without it, A is noise |
| D | **Foreground handling** in the app: a small in-app banner, never the system one | Behaviour with the app open is undefined today |
| E | **Badge** on the app icon that matches the inbox | A missed push still shows |
| F | **Android channels** per kind, and high priority where someone is waiting | Everything lands in "Miscellaneous" today, and Doze can delay it |
| G | **Per-kind settings** (Replies, Needs you, Routines, Suggestions, Account) | People mute one kind instead of all of Casama |
| H | **Approve / Deny** buttons on approval pushes, **grouping** by conversation | Fewer taps, a tidy lock screen |

Quick reply from the notification, and pushes for messages from *other people* in shared chats,
come later (§10).

## 1. What exists today

| Built | Where | Notes |
|---|---|---|
| `NotificationService.notify()`: inbox row and push, quiet hours (D-109), attention holds and the 5-a-day cap for proactive kinds (D-153, D-312), plain text (D-312) | `packages/agent/src/notifications.ts`, `attention.ts` | Every push goes through it. Non-proactive kinds have `urgency = null`, so they never count toward the cap |
| FCM HTTP v1 sender with `tag` (Android tag, iOS `apns-collapse-id`), `category`, data-only pushes | `FcmPushSender` in the same file | No `channel_id`, no Android priority on notification pushes, no `thread-id`, no `badge` |
| Cloud relay for self-hosted servers, private notifications (generic text) | `packages/agent/src/push-relay.ts`, `apps/server/src/services/link-settings.ts` | New push fields must pass through the relay |
| Deferred pushes after quiet hours, skipped if already read | `sendDeferred()` | Reused as is |
| Kinds that push: `bot_message` (`notify.user`), `routine_result`, `suggestion`, `approval_request`, `secret`, `takeover`, `call_missed`, `outbound_call`, `link_exchange`, `project`, `credits_low`, `server_capacity` | `run.ts`, `tools/autonomy.ts`, `checkins.ts` and others | No `reply` kind |
| App: device registration, tap → deep link, suggestion **Do it** / **Not now** (D-247) | `client/lib/core/push.dart`, `client/ios/Runner/AppDelegate.swift`, `client/android/.../SuggestionPush.kt` | No `onMessage` handler. No iOS foreground presentation set. No badge |
| Inbox and badge count in the app | `inboxBadgeProvider` in `client/lib/core/providers.dart` | Pending approvals + takeovers + unread notifications. The Mac dock badge already uses it |
| Quiet hours, per person and per bot | `client/lib/features/notifications/quiet_hours.dart`, `user_bot_settings` | The only notification setting |
| Android channels | Only `Suggestions` (`SuggestionPush.kt`) | Everything else falls back to FCM's default channel |

Gaps found while reading the code:

- **No reply push** (see the summary). `run.ts` has a `notify` step only for routines.
- **Foreground pushes are dropped silently** on Android and iOS: FCM doesn't draw notification
  messages while the app is open, and the app has no `onMessage` handler. So an approval that
  arrives while you're in another screen shows only through the inbox count.
- **One channel for everything on Android.** You can't mute routine results in system settings
  without muting approvals too, and notification pushes go at normal priority, which Doze may hold.
- **No read state per conversation.** The server can't tell whether you're looking at a chat.

## 2. Principles

1. **Push what you asked for, and what needs you.** Replies to your own requests, failures and
   approvals always qualify. Proactive messages keep their caps and holds.
2. **Never buzz what you're looking at.** If any of your devices has that chat open and in front,
   no device buzzes.
3. **One notification per conversation.** A newer reply replaces the older one.
4. **Same words everywhere.** The push, the in-app banner and the inbox row carry the same plain
   text (D-312).
5. **Old apps keep working.** Every new push field is optional, and an old app gets a correct, if
   plainer, push.
6. **Self-hosters get it too.** Through the relay, with private notifications still honoured.

## 3. Words

| Word in the app | Means | Not |
|---|---|---|
| **Reply ready** | A run you started from chat finished | "Run completed" |
| **Couldn't finish** | That run failed | "Error", "Run failed" |
| **Needs you** | Approvals, secrets, takeovers, missed calls | "Action required" |

## 4. Features

### A. Reply-ready push

Sent from the run's end, next to the routine `notify` step in `run.ts`, when **all** of these
are true:

- `trigger` is `chat` or `mention`, and `createdBy` is a person. Not `voice` (you're on the call),
  not `message` (the reply goes back into Telegram, Slack and the other chat apps, which push for
  themselves), not routines (they have their own step), not sub-runs or delegations.
- The run **completed** (B covers failed runs). A run the person cancelled sends nothing.
- It ran for at least **10 seconds** (decision 1). Quick answers arrive while you're still looking.
- No device of that person has this conversation open and in front (C).
- That person hasn't turned Replies off (G).

What it carries:

- **Title:** the bot's name. For the default bot it's the conversation's title, since the phone
  already says "Casama" (as D-312 did for briefs).
- **Body:** the reply in plain text, cut at 240 characters (`pushText`). A reply that is only a
  card says "Sent you <card title>". With private notifications on, the relay's generic text
  replaces both, as today.
- **Link:** `/bots/{bot}/chat?c={conversation}`.
- **Tag:** `reply-{conversation}`, so a second reply replaces the first.
- **Kind:** `reply`, `urgency` null: it doesn't count toward the 5-a-day cap, and attention holds
  don't apply, because you asked for it. **Quiet hours do apply** (decision 2): the push waits
  until they end, and `sendDeferred` drops it if you've opened the chat by then.
- **Group chats with several bots:** each bot's reply replaces the last under the same tag, so
  you see the latest one, not three.

If a run waits for an approval, the approval push goes out as today, and the reply push follows
when the run finishes.

### B. Couldn't finish

The same rules and the same tag, sent from `finishFailed`. Title: the bot's name. Body:
"Couldn't finish: " plus the run's failure message (already in plain words,
`failureMessage()`). Runs stopped by a limit (`stuck_looping`, budget) count as failed. Runs the
person cancelled don't.

### C. Don't buzz the chat you're looking at

The server needs to know what's on screen. The app reports it:

- `PUT /v1/devices/focus` `{ conversation_id | null }`, sent when a chat opens, when the app comes
  to the front with a chat open, and every 30 seconds while it stays like that. `null` when the
  chat closes or the app goes to the background.
- Stored on `devices` as `focus_conversation_id` and `focus_at`. A focus older than 45 seconds is
  ignored, so a killed app never blocks pushes for long.
- `notify()` for `reply` checks: if any of the person's devices has a fresh focus on this
  conversation, it writes the inbox row as read and sends no push to any device.

This also stops the Mac-open, phone-buzzes case. Old apps never send focus, so their owners get
the push and, with the app open, D makes it harmless.

Not chosen: Realtime presence (the worker can't cheaply ask who is subscribed), and reading
messages to decide (we have no per-conversation read state, and adding it is a bigger change).

### D. Foreground handling in the app

- `FirebaseMessaging.onMessage` in `push.dart`. On iOS and macOS, set foreground presentation to
  none, so the app always decides.
- If the push's `conversation_id` is the chat on screen: drop it and mark it read.
- Otherwise show **one small in-app banner** at the top (bot avatar, title, one line, tap to
  open, swipe away, gone after 4 seconds). A new banner replaces the old one.
- Approvals and other Needs-you pushes use the same banner with a **Review** button.
- **Web:** the FCM web SDK already sends foreground pushes to `onMessage`, so the same code
  covers it. The service worker keeps drawing pushes while the tab is in the background.

### E. Badge

- **iOS and macOS:** every push sets `aps.badge` to the person's count: pending approvals and
  takeovers plus unread inbox rows (the same sum as `inboxBadgeProvider`, worked out in one query
  on the server). The app sets the badge again whenever the count changes while it's open (a
  small method channel in `AppDelegate`), so opening the inbox clears it.
- **Android:** launchers badge from the notifications on screen. Nothing to send, but reading a
  chat in the app cancels its reply notification (by tag), so the dot goes away.
- **Reply rows and the inbox:** `reply` rows count toward the badge while unread. They are
  marked read when their conversation opens. The inbox *list* leaves them out (the chat is where
  you read them), so the inbox doesn't fill with copies of chat messages (decision 3).

### F. Android channels and priority

Created in `MainActivity` at start. The server sets `android.notification.channel_id`, and an old
app without the channel falls back to the default one, as today.

| Channel | Kinds | Importance |
|---|---|---|
| **Replies** | `reply` | High |
| **Needs you** | `approval_request`, `secret`, `takeover`, `call_missed` | High |
| **Routines and briefs** | `routine_result`, `bot_message` | Default |
| **Suggestions** | `suggestion` (exists) | High, as today |
| **Account** | `credits_low`, `server_capacity`, `project`, `link_exchange` | Low |

`android.priority: HIGH` for Replies and Needs you, so Doze doesn't hold them. iOS approvals
started from chat use `interruption-level: time-sensitive` (decision 4), the same rule that
already lets them through quiet hours.

### G. Per-kind settings

Settings → **Notifications** becomes a screen, holding quiet hours (moved from Settings), the
check-ins sheet, the gallery digest switch and these five rows:

| Row | Default | Off means |
|---|---|---|
| Replies | On | No reply or Couldn't finish pushes |
| Needs you | On | Inbox only. The row warns that bots will wait longer |
| Routine results | On | Inbox only |
| Suggestions and check-ins | On | Inbox only (the check-ins sheet still controls whether they run) |
| Account | On | Inbox only |

Stored as `profiles.push_prefs jsonb` (`{"routines": false}`, missing = on). `notify()` maps each
kind to its row. When the row is off, the inbox row is still written with a new `push_status`
value `off`. On Android each row also links to its channel's system page.

Per bot, the existing quiet setting on the bot's profile stays the way to silence one bot.

### H. Buttons and grouping

- **Approvals:** an iOS category `APPROVAL` and Android buttons with **Approve** and **Deny**.
  Both open the app and act at once (the D-247 **Do it** pattern: `openTarget` routes
  `/approvals/{id}/approve` or `/deny`), then show the result. Approve needs the phone unlocked
  (`.authenticationRequired` on iOS, `setAuthenticationRequired` on Android 12+). High-risk
  approvals get **Review** only (decision 5). Android draws approval pushes itself from data
  messages, as suggestions do, but only for apps that say they can (`data_pushes`).
- **Grouping on iOS:** `aps.thread-id` set to the conversation for replies and to the bot for
  everything else, so the lock screen stacks them. Android bundles four or more by itself (FCM
  HTTP v1 has no group key).

## 5. Data

One migration:

- `devices.focus_conversation_id uuid null`, `devices.focus_at timestamptz null`.
- `profiles.push_prefs jsonb not null default '{}'`.
- `notifications_push_status_check` gains `off`.
- RLS: devices stay owner-only. The worker writes notifications as today (`allow_worker`).
- pgTAP: a person can set focus only on their own devices, and only for a conversation they can
  read.

## 6. Server

| Change | Where |
|---|---|
| `reply` step at the end of completed runs and in `finishFailed`, with the rules in A and B | `packages/agent/src/run.ts` (a `replyPush()` helper in `notifications.ts`) |
| Focus check, prefs check, `off` status, badge count | `NotificationService.notify()` / `pushTo()` |
| `PushMessage` gains `channel`, `priority`, `threadId`, `badge`, `interruption` | `notifications.ts`, `FcmPushSender`, `RecordingPushSender` |
| The relay passes the new fields through, and private mode still blanks the text | `push-relay.ts`, `apps/server/src/link/push-relay.ts` |
| `PUT /v1/devices/focus`, `GET/PATCH /v1/me/push-prefs` | `apps/server/src/api/routes/`, `packages/contracts` (OpenAPI, then regenerate `packages/client`) |
| Kind → row and channel map, in one place | `packages/domain` |

## 7. App

| Change | Where |
|---|---|
| `onMessage`, foreground presentation off, banner, drop on matching chat | `client/lib/core/push.dart`, new `client/lib/ui/push_banner.dart` |
| Focus reports from the chat screen and the app lifecycle | `client/lib/features/chat/` (the chat controller), `backend.dart`, `supabase_backend.dart` |
| Mark reply rows read when a chat opens, cancel the reply notification by tag | the notifications provider, `MainActivity.kt` / `AppDelegate.swift` method channel |
| Badge method channel (iOS, macOS uses the existing dock badge) | `AppDelegate.swift` |
| Channels, approval buttons | `MainActivity.kt`, `SuggestionPush.kt` (generalised to `PushDrawer.kt`), `AppDelegate.swift` |
| Notifications settings screen | `client/lib/features/notifications/notifications_screen.dart` (new), `settings_screen.dart`, `app_en.arb` |
| `pushKind()` learns `reply` and `failed` for `push_opened` | `push.dart` |

## 8. Privacy and costs

- A reply push puts the first 240 characters of a reply on the lock screen. That's the same as
  `notify.user` and routine results today. Private notifications (self-hosted through the relay)
  blank it. The Replies row in G is the way out for Cloud users, and decision 6 offers a
  "Hide reply text" switch.
- Focus reports say only *which conversation is open on which device*, kept 45 seconds in effect
  and overwritten in place. They are never logged or sent to analytics.
- FCM and APNs are free. The server adds one indexed `devices` read per qualifying run end, and
  the app sends one small request every 30 seconds while a chat is on screen. Nothing for
  `docs/COSTS.md`.

## 9. Tests

- `packages/agent/test/notifications.test.ts`: reply sent after 10 s, not before. Not for voice,
  message, routine, sub-run or cancelled runs. Suppressed by a fresh focus on any device, not by
  a stale one. Deferred in quiet hours and dropped if read. Off when the row is off. Tag, channel,
  priority, thread-id and badge in the FCM body. Failed runs say "Couldn't finish". Doesn't count
  toward the 5-a-day cap.
- Relay test: the new fields pass through, and private mode blanks the text.
- Contracts: the two new routes are signed-in only.
- pgTAP: the focus and prefs columns.
- Flutter: `openTarget` for approve and deny, the foreground decision (drop / banner), the
  settings screen.
- One live check on a phone per platform (Phase 2): lock the phone mid-run and get the reply.

## 10. Later (not in this plan)

- **Quick reply from the notification** (iOS text input action, Android RemoteInput). It has to
  call the API from the background with a session, which is native work on both platforms and a
  security review of its own.
- **Messages from other people** in shared and group chats (Groups). That needs per-person read
  state, which this plan avoids.
- **A digest** of reply pushes that were muted or held.
- **Desktop notifications on Windows and Linux** (no FCM there).

## 11. Decisions to approve (defaults in bold)

| # | Question | Default |
|---|---|---|
| 1 | How long must a run take before its reply pushes? | **10 seconds** |
| 2 | Do quiet hours hold reply pushes? | **Yes**: you get them when quiet hours end, unless you've already read them |
| 3 | Do reply pushes appear in the inbox list? | **No**: they count toward the badge and are read when the chat opens |
| 4 | Time Sensitive (iOS) for approvals started from chat | **Yes**: needs the Time Sensitive capability in the iOS app |
| 5 | Approve from the notification | **Yes for low and medium risk**, after unlocking the phone. High risk shows **Review** only |
| 6 | A "Hide reply text on the lock screen" switch for Cloud users | **Yes**, off by default. The push then says "<bot> replied" |
| 7 | Who gets the reply push in a shared conversation | **Only the person who asked** |

## 12. Phases

| Phase | Builds | Done when | Needs Oliver |
|---|---|---|---|
| **1. Server** | A, B, C (server side), F's server fields, the migration, the routes, the relay | Tests pass. On the current app, a locked phone gets the reply push and the open app shows nothing | A production deploy |
| **2. App basics** | D, the focus reports, E, F's channels, read on open | With the app open the banner shows, the open chat stays quiet, the badge matches | A Flutter build per platform for the live check |
| **3. Control** | G, H, iOS thread-id and Time Sensitive | Each row mutes its kind. Approve and Deny work from a locked phone | A Flutter build. The Time Sensitive capability in the App ID |

Phase 1 works on its own with apps already in people's hands, which is why it goes first. A
decision entry (D-325) goes into `docs/DECISIONS.md` when the plan is approved, and the docs page
on notifications (`docs-site/`) is updated in each phase.

## 13. Wire contract (as built)

Approved 2026-11-16 with every §11 default ("Go and build all now", D-325). The app talks to
Supabase directly for these, as it already does for `profiles.quiet_hours` and `devices`, so
there are no new `/v1` routes.

**Database** (migration `20270201100901_notifications_d325.sql`):

- `public.chat_focus (user_id uuid, client_id text, conversation_id uuid null, updated_at timestamptz)`,
  primary key `(user_id, client_id)`, owner-only RLS, `allow_worker`. The app upserts it (C).
  A focus is fresh for 45 seconds.
- `profiles.push_prefs jsonb not null default '{}'`: `replies`, `needs_you`, `routines`,
  `suggestions`, `account` (booleans, missing = on) and `hide_reply_text` (missing = off).
- `devices.push_version smallint not null default 0`. Apps from D-325 write `2`: on Android they
  draw approval pushes themselves (data-only, buttons).
- `notifications.push_status` gains `off` (row kept, no push: pref off, or chat on screen).

**Kinds and groups** (`packages/domain`, `pushGroup(kind)`):

| Group | Kinds | Android channel | Priority |
|---|---|---|---|
| `replies` | `reply` | `replies` | high |
| `needs_you` | `approval_request`, `secret`, `takeover`, `call_missed` | `needs_you` | high |
| `routines` | `routine_result`, `bot_message` | `routines` | normal |
| `suggestions` | `suggestion` | `suggestions` | high |
| `account` | everything else | `account` | normal |

**Reply rows:** kind `reply`, payload `{title, body, link, bot_id, run_id, conversation_id, tag:
"reply-<conversation>", failed?: true}`. The app leaves `reply` rows out of the inbox list and
marks a conversation's unread `reply` rows read when the chat opens.

**FCM data keys** (all strings, every push): `notification_id`, `kind`, `link`, and when known
`tag`, `conversation_id`, `bot_id`, `approval_id`, `risk`, `suggestion_id`. Data-only pushes
also carry `title`, `body`, `category`, `channel`.

**Per platform:**

- Android: `android.notification.channel_id`, `tag`; `android.priority: HIGH` for high groups.
  Approvals to `push_version >= 2` devices go data-only and the app draws them with **Approve** /
  **Deny** (not for `risk = high`: **Review**).
- iOS and macOS: `aps.thread-id` (`conversation_id`, else `bot_id`, else kind), `aps.badge`,
  `apns-collapse-id` from `tag`, `aps.category = APPROVAL` for approvals below high risk (actions
  `approve` and `deny`), `interruption-level: time-sensitive` for urgent approvals.
- Web: `webpush.notification.tag`.
- Windows and Linux (no FCM): while the app runs, it draws new unread rows with
  `push_status = 'sent'` from Realtime as system notifications when its window isn't focused.
