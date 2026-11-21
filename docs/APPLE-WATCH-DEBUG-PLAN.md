# Apple Watch extensive debugging plan

Status: **not started** (written 2026-11-21; waiting on Oliver's decisions in §7 and permission for the Phase 1 Xcode/Flutter builds).

Related plans and specs: [WATCH-PLAN](WATCH-PLAN.md) (D-410), [WATCH-PROTOCOL](WATCH-PROTOCOL.md), [BOT-WIDGET-PLAN](BOT-WIDGET-PLAN.md), [IOS-DEBUG-FINDINGS](IOS-DEBUG-FINDINGS.md).

---

## 0. Why this plan exists and what we found before starting

The Apple Watch code (`client/ios/CasamaWatch/`, `client/ios/CasamaWatchWidgets/`, `client/ios/Shared/`, `client/ios/Runner/WatchBridge.swift`, `client/lib/features/watch/`, `apps/server/src/api/routes/watch.ts`, `packages/agent/src/watch.ts`, `packages/agent/src/notifications.ts`, `packages/agent/src/apns.ts`, `supabase/migrations/20270207100001_watch_keys.sql`) is written and passes pure macOS model tests (`scripts/test-watch-swift.sh`), server Vitest suites, pgTAP RLS tests, and Flutter unit tests.

However, per [WATCH-PLAN](WATCH-PLAN.md) and [PLANS](PLANS.md), **none of the watchOS SwiftUI app, WidgetKit extension, notifications, or WatchConnectivity flow has ever been compiled for `watchos`/`watchsimulator`, run on a watch simulator, or tested on a physical Apple Watch**. An audit of the current tree turned up six structural gaps that a debug pass must address first:

1. **Zero runtime logging across all watch targets.** Searching `client/ios/CasamaWatch/`, `client/ios/CasamaWatchWidgets/`, `client/ios/Shared/`, and `client/ios/Runner/WatchBridge.swift` shows **0** `os.Logger`, `os_log`, `print`, or `NSLog` calls. Every network failure (`WatchAPI.map`), decode drop (`LossyList`, `try?`), keychain status (`WatchKeyStore`), App Group fallback (`WatchGroup`, `BotPictureStore`), `WCSession` state transition, APNs registration error (`didFailToRegisterForRemoteNotificationsWithError`), notification suppression, and SSE reconnect fails silently.
2. **Hardcoded cloud URL blocks standalone code sign-in against local dev.** `WatchAccount.defaultServer` in `client/ios/Shared/WatchStore.swift` is hardcoded to `https://api.casama.ai`. `AppModel.swift` has `#if DEBUG` launch arguments `-CasamaWatchCode`, `-CasamaWatchNoPush`, and `-CasamaWatchOpen`, but **no server override** (unlike Wear OS's `-PdefaultServer`). Because the D-410 audit fixes and watch migrations are not yet deployed to production, standalone code sign-in on a simulator cannot reach the local stack unless a `#if DEBUG` override (`-CasamaWatchServer`) or paired-iPhone sign-in is used.
3. **Silent App Group / Keychain fallback splits app and extension.** `WatchKeyStore.swift` falls back to `group: false` on `errSecMissingEntitlement`, and `WatchGroup` / `BotPictureStore` fall back to per-process `UserDefaults.standard` / `cachesDirectory` if `group.ai.casama.app.watch` is unavailable. In an unsigned or mis-provisioned build, the watch app appears signed in while `CasamaWatchWidgets` reads an empty store and shows "Open Casama to sign in".
4. **Xcode build graph / CocoaPods separation is untested.** `Watch.xcconfig` intentionally avoids Flutter's `Debug.xcconfig`/`Release.xcconfig` to keep iOS CocoaPods out of `CasamaWatch` (`ai.casama.app.watchkitapp`) and `CasamaWatchWidgets` (`ai.casama.app.watchkitapp.widgets`), and `Runner.xcodeproj` embeds both targets. Running `xcodebuild -project client/ios/Runner.xcodeproj -list` stalls on "Resolve Package Graph"; builds must be verified through `Runner.xcworkspace`, `flutter run`, and `flutter build ipa` to prove there is no Xcode script-phase cycle (`Embed Watch Content` vs `Thin Binary`).
5. **Watch simulators exist locally, but paired testing has specific constraints.** This Mac has the `watchOS 27.2` simulator runtime installed with three active phone+watch pairs (`iPhone 18 Pro Max` + `Series 12 46mm`, `iPhone Air` + `Series 12 42mm`, `iPhone 17` + `Ultra 4 49mm`) and two standalone watches (`SE 3 40mm`, `SE 3 44mm`). Meanwhile `iPhone 18 Pro` (currently used by iOS debug runs) has **no** paired watch.
6. **Production APNs & App IDs are still pending.** `APNS_KEY_P8`, `APNS_KEY_ID`, and `APNS_TEAM_ID` are not yet configured in production (`BOT-WIDGET-PLAN`, `WATCH-PLAN` §16), and `ai.casama.app.watchkitapp` / `ai.casama.app.watchkitapp.widgets` need Apple Developer App IDs + provisioning profiles with `group.ai.casama.app.watch` and keychain sharing on the first signed build.

---

## 1. Ground rules & safety

- **Never log secrets.** In `os.Logger` or debug overlays, never print the raw watch key (`cwt_...`), `Authorization` headers, Supabase JWTs, full APNs device tokens, `APNS_KEY_P8`, or message/prompt bodies. Log only the first 8–12 chars of the key's SHA-256 fingerprint (`WatchKeyMaker.fingerprint`), HTTP status, `WatchProblem.code`, `errSec*` OSStatus, and truncated correlation IDs.
- **Ask before Flutter/Xcode builds (`AGENTS.md`).** Phase 1+ commands that invoke `xcodebuild`, `flutter run`, or `flutter build` on `client/` require Oliver's explicit yes before running.
- **One Flutter build in `client/` at a time.** Never run concurrent `flutter test`/`flutter run`/`xcodebuild` in the same checkout (they collide on `client/build` and `DerivedData`).
- **Respect running simulators.** Leave already-booted devices (`iPhone 18 Pro`, `Casama_Wear_Small_Round`) untouched; shut down only simulators we boot when finished.
- **Find-and-triage discipline (matching `docs/IOS-DEBUG-FINDINGS.md`).** Log every discovered issue in `docs/APPLE-WATCH-DEBUG-FINDINGS.md` with severity (**P0** crash/data loss/security bypass, **P1** broken feature, **P2** wrong behavior/UI layout, **P3** polish/tooling), exact repro steps, logs, and screenshots before fixing in clean, tested commits.

---

## 2. Observability & debugging harness (build once, debug everything)

Without instrumentation, watchOS failures inside WidgetKit extensions, background `WKRefreshBackgroundTask` wakes, and `WCSession` background transfers are invisible. Add `#if DEBUG` (and safe release `os.Logger` metadata) tooling first:

### 2.1 Unified `os.Logger` subsystem (`ai.casama.watch`)
Add a tiny shared logger (`client/ios/Shared/WatchLog.swift`, Foundation/`os` only so `test-watch-swift.sh` keeps compiling cleanly) with category loggers:
- `auth`: `WatchKeyStore` OSStatus (`errSec*`), `group` vs fallback keychain hit, `keyLocked`, `IssuedSignIns` accept/reject decisions.
- `link`: `PhoneLink` & `WatchBridge` `WCSession` `activationState`, `isPaired`, `isWatchAppInstalled`, `isReachable`, `sendMessage` vs `transferUserInfo` fallback, `held` request counts/TTLs.
- `net`: `WatchAPI` method, path, HTTP status, `WatchProblem.code`, latency ms, `ETag`/304 vs 200, `retryAfter`, `URLSession` `URLError.code`.
- `sse`: `RunFollower` connect/disconnect, server 110s rollover, heartbeat `: ping`, parse drops, backoff wait.
- `push`: `didRegisterForRemoteNotifications` (sandbox flag + token length + 6-char hash, never raw token), `didFailToRegisterForRemoteNotificationsWithError`, `willPresent` suppression, `didReceive` action ID, `NotificationController` `canAllow`/privacy masking.
- `widget`: `GlanceLoader` timeline reload reason, `WatchGroup.container != nil`, `GlanceAge.isStale`, `BotPictureStore` hit/miss/download status, `AllowRequestIntent` / `RunControlIntent` outcomes.
- `audio`: `Recorder` mic permission, `AVAudioSession` setup, meter peak/duration, `nothingHeardStop`, file size in bytes, `AskQueueStore` enqueue/retry/drop, `Speaker` server MP3 vs `AVSpeechSynthesizer` fallback.

Capture all streams live in one terminal with:
```sh
xcrun simctl spawn <WATCH_UDID> log stream --level debug --style compact \
  --predicate 'subsystem == "ai.casama.watch" OR subsystem == "com.apple.watchconnectivity" OR process == "CasamaWatch" OR process == "CasamaWatchWidgets"'
```
And from the paired phone:
```sh
xcrun simctl spawn <PHONE_UDID> log stream --level debug --style compact \
  --predicate 'process == "Runner" AND (category == "watch" OR eventMessage CONTAINS[c] "WCSession" OR eventMessage CONTAINS[c] "WatchBridge")'
```

### 2.2 `#if DEBUG` launch switches & diagnostics view
Extend the existing `#if DEBUG` flags in `client/ios/CasamaWatch/AppModel.swift` (`-CasamaWatchCode`, `-CasamaWatchNoPush`, `-CasamaWatchOpen`):
1. **`-CasamaWatchServer <url>`**: overrides `WatchAccount.defaultServer` in `#if DEBUG` so standalone code sign-in on a simulator can target `http://localhost:8787` or `https://api-dev.casama.ai` directly without pairing an iPhone first.
2. **`-CasamaWatchSandbox <YES|NO>`**: test toggling `WatchDeviceInfo.apnsSandbox` behavior during push-token registration audits.
3. **Hidden `#if DEBUG` Diagnostics sheet in `SettingsView`** (tapped 5x on version footer `WatchDeviceInfo.appVersion` in `MoreViews.swift`): displays non-secret runtime health at a glance — active server URL, `orgId` (8-char prefix), key present + keychain mode (`shared-group` vs `local-fallback`), `AppGroup` container reachable (`true/false`), `WCSession` (`supported/activated/reachable/hasCompanion`), `lastGlance` age + `ETag`, `offlineQueue.count`, `pushSent` status, `BotPictureStore` cached file count, and a **"Force Refresh + Reload Complications"** button.

---

## 3. Target matrix & simulator/device lab

| Target / Pair | Phone UDID | Watch UDID | Dimensions | Focus |
|---|---|---|---|---|
| **Primary pair (46mm)** | `iPhone 18 Pro Max` (`CCE4E5F9-C1D6-4094-AF29-1A9011E22EB7`) | `Apple Watch Series 12 (46mm)` (`DAEE92A1-C71B-4C6B-9A92-7206C2B2607B`) | 46 mm | Full paired flow: `WatchBridge`, notifications, Live Activity, complications, Smart Stack |
| **Small paired (42mm)** | `iPhone Air` (`ECB3A00C-90BD-41F7-8F8B-EEEFAB92FBEE`) | `Apple Watch Series 12 (42mm)` (`D91E23C4-A203-4987-8E2D-5959F95847FE`) | 42 mm | Compact layout, text wrapping, bottom bar crowding |
| **Ultra paired (49mm)** | `iPhone 17` (`F28DDB6E-79B2-4487-ADE3-A83FC29132A1`) | `Apple Watch Ultra 4 (49mm)` (`DAA480BA-5413-463E-893C-E7B2D007FFFE`) | 49 mm | Ultra Action Button (`RunRoutineControl` / `AskControl`), wide cards |
| **Smallest standalone** | *(none)* | `Apple Watch SE 3 (40mm)` (`7C16426A-2041-467C-84D2-7A0E0CF325FA`) | 40 mm | Independent app (`WKRunsIndependentlyOfCompanionApp`), code sign-in, 40mm truncation & Dynamic Type |
| **Real hardware** *(Oliver)* | Physical iPhone | Physical Apple Watch (watchOS 26+) | — | Real APNs, mirrored lock-screen notifications, wrist detection passcode (`WristCheck`), Double Tap gesture, cellular/Wi-Fi without phone, battery/thermal |

---

## 4. Phased debugging & verification plan

### Phase 0 — Baseline non-build checks (no Xcode/Flutter build required)
Verify all contracts, pure logic, server routes, and script generators before compiling watch targets:
1. Run `scripts/test-watch-swift.sh` (verifies `Shared/` Swift models & `WatchLogic` against `packages/contracts/fixtures/watch/` and `bot-avatar-vectors.json`).
2. Run `node scripts/gen-watch-strings.mjs --check` (or diff `WatchStrings.swift` against `client/lib/l10n/app_en.arb`) to verify zero drift in `WatchL10n`.
3. Run targeted watch suites (via `scripts/heavy.sh` or targeted vitest/flutter test):
   - `pnpm --filter @casama/contracts exec vitest run test/watch-fixtures.test.ts`
   - `pnpm --filter @casama/domain exec vitest run test/watch.test.ts`
   - `pnpm --filter @casama/agent exec vitest run test/watch.test.ts test/watch-push.test.ts`
   - `pnpm --filter @casama/server exec vitest run test/watch.test.ts`
   - `pnpm --filter @casama/db test:pgtap watch_keys`
   - `cd client && flutter test test/features/watch/`
4. Start the local backend stack (`scripts/dev-up.sh`) and verify `/readyz` on `http://localhost:8787` and (if testing on physical devices / real APNs / `https://` strict paths) `https://api-dev.casama.ai`.
5. **Static Xcode project & plist/entitlement audit:**
   - Verify `CasamaWatch` and `CasamaWatchWidgets` build phase order in `client/ios/Runner.xcodeproj/project.pbxproj` (`Embed Watch Content` vs `Run Script` / `Thin Binary`).
   - Verify `Shared/` file membership across both `CasamaWatch` and `CasamaWatchWidgets` targets (confirm `WatchLog.swift` or any shared helper is in both PBXSourcesBuildPhases).
   - Verify `PrivacyInfo.xcprivacy` in both `CasamaWatch` and `CasamaWatchWidgets` covers `UserDefaults` (`CA92.1` reason code) and file timestamp APIs (`BotPictureStore.prune`).
   - Check `Info.plist` keys: `WKCompanionAppBundleIdentifier` (`ai.casama.app`), `WKRunsIndependentlyOfCompanionApp = true`, `WKSupportsLiveActivityLaunchAttributeTypes = ["RunActivityAttributes"]`, `NSAllowsLocalNetworking = true`, `NSMicrophoneUsageDescription`, `UIBackgroundModes = ["remote-notification"]`, `CFBundleURLTypes` (`casama`).

---

### Phase 1 — Xcode / Flutter build & simulator boot verification *(requires Oliver's yes for Flutter/Xcode builds)*
Prove the watch targets compile cleanly for `watchsimulator`, `watchos`, and `Runner` without breaking normal iOS builds:
1. **Workspace preparation:** `cd client && flutter pub get && (cd ios && pod install)` to ensure `Generated.xcconfig` and CocoaPods workspace are current.
2. **Standalone watchOS scheme compile:**
   ```sh
   xcodebuild -workspace client/ios/Runner.xcworkspace \
     -scheme CasamaWatch \
     -configuration Debug \
     -destination 'platform=watchOS Simulator,id=DAEE92A1-C71B-4C6B-9A92-7206C2B2607B' \
     build
   ```
   Check for:
   - WatchOS 26/27 SDK deprecations or compiler errors in `CasamaWatch`, `CasamaWatchWidgets`, and `Shared/` (which were previously only compiled against macOS SDK in `test-watch-swift.sh`!).
   - Asset catalog (`Assets.xcassets`, `WatchAssets.xcassets`) missing app icons, mascot images (`winky`, `sleepy`, `shy`, `thinker`, `giggly`), or accent colors.
   - AppIntents metadata extraction warnings (`WatchIntents.swift`, `Siri.swift`, `WatchControls.swift`).
3. **Full paired Runner + Watch build (`flutter run` / `xcodebuild -scheme Runner`):**
   - Boot paired `iPhone 18 Pro Max` + `Apple Watch Series 12 (46mm)`.
   - Verify `flutter run -d CCE4E5F9-C1D6-4094-AF29-1A9011E22EB7 --dart-define=CASAMA_API_URL=http://localhost:8787` succeeds and embeds `Watch/CasamaWatch.app` + `PlugIns/CasamaWatchWidgets.appex` into `Runner.app`.
   - Verify `flutter build ios --no-codesign` and `flutter build ipa` (if certs/profiles exist, or dry-check archive) hit **no** `Cycle inside Runner` error between `Embed Watch Content` and Flutter's `Thin Binary`.
4. **Verify Entitlements & App Group Container at launch:**
   - Confirm in `log stream` that `WatchGroup.container != nil` and `WatchKeyStore` writes with `group: true` (`errSecSuccess`) rather than falling back to `group: false` (`errSecMissingEntitlement`).
   - Confirm `CasamaWatchWidgets` reads the exact same `UserDefaults(suiteName: "group.ai.casama.app.watch")` and `bot-images/` directory as `CasamaWatch`.

---

### Phase 2 — Pairing, Sign-In, Key Lifecycle & Cross-Device State
Test every path in `docs/WATCH-PROTOCOL.md` §1–3, `PhoneLink.swift`, `WatchBridge.swift`, `watch_bridge.dart`, `watch_screen.dart`, and `routes/watch.ts`:

| # | Scenario | What to test & inspect | Pass criteria |
|---|---|---|---|
| 2.1 | **Automatic paired iPhone sign-in** | Launch `CasamaWatch` while `Runner` is signed in on paired iPhone | `sign_in` arrives via `sendMessage`, Dart registers fingerprint (`POST /v1/watch-keys`), watch shows `"Signed in as <name>"` pill and loads `NowView`; Settings → Watch lists the watch with `name`, `model` (e.g. `46 mm`), `app_version`, `os_version` |
| 2.2 | **Background / terminated iPhone wake** | Terminate `Runner` on iPhone, launch `CasamaWatch`, tap *Try again* | `transferUserInfo` wakes `Runner` (`WatchBridge.activate()` in `didFinishLaunching`), request is held in `UserDefaults` (`casama.watch.requests` with `at` ms), answered via `takeRequests()` on next Flutter launch |
| 2.3 | **iPhone signed out → later signs in** | Watch sends `sign_in` while iPhone is signed out; then sign in on iPhone | Watch stays on `SigningInView(waiting: true)` (`PhoneReask` every 30s on `becameActive`); once iPhone finishes sign-in, `catchUp()` → `takeRequests()` automatically signs watch in |
| 2.4 | **App Lock enabled on iPhone (D-375)** | Enable App Lock on iPhone, initiate watch sign-in | Phone prompts `watchLockAskProvider`; declining returns `reason: "declined"` and stops `PhoneReask` auto-spam; approving calls `_startPrivate` (`show_details: false`) once and signs watch in |
| 2.5 | **Standalone code sign-in (`CasamaWatchCode`)** | Boot standalone `SE 3 (40mm)` with `-CasamaWatchCode YES -CasamaWatchServer http://localhost:8787` | Watch calls `POST /v1/watch/codes`, renders 8-char code (`XXXX YYYY`) + live countdown; polling `GET /v1/watch/me` returns `401 watch_code_pending` (without wiping key or tripping `WATCH_FAILED_KEYS_PER_MINUTE`!). Entering code in Settings → Watch (or Web `app-dev`) signs watch in |
| 2.6 | **Code edge cases** | Wrong code 5×, expired 10m code, cancel button (`xmark`) | 5 wrong codes → `429`; expired code → `401 invalid_watch_key` → `.codeExpired` screen; `New code` rotates cleanly |
| 2.7 | **Plain HTTP vs HTTPS server rules (`WatchServer.usable`)** | Phone connected to `http://localhost:8787` vs `http://192.168.x.x:8787` vs `http://example.com` vs `https://api-dev.casama.ai` | LAN/localhost HTTP succeeds; non-local HTTP sets `needsHttps = true` and shows `WatchL10n.needsHttps` without accepting the server |
| 2.8 | **Workspace switching** | Switch workspace on iPhone while watch is active / asleep | `WatchBridge.workspaceChanged` re-registers fingerprint for new `org_id`, deletes old key if new id issued, sends `context`; watch wipes old `GlanceCache`, fetches new `GET /v1/glance` & `GET /v1/watch/me` |
| 2.9 | **Sign-out & Revocation vectors** | (a) Sign out from watch Settings; (b) Remove watch on phone; (c) Phone Sign Out; (d) Sign Out Everywhere (`DELETE /v1/watch-keys`); (e) Remove user from org (`20270211100001`) | Key deleted from Keychain, `GlanceCache`, `AskQueueStore`, `BotPictureStore`, and complications wiped; `401` transitions to `SignedOutView` and stays signed out until user taps Sign in (never auto-re-requests); `403 watch_key_not_allowed` does **not** wipe key |
| 2.10 | **Keychain pre-first-unlock (`keyLocked`)** | Simulate `errSecInteractionNotAllowed` / background wake before unlock | Watch enters `keyLocked = true`, does not wipe key or ask phone; `becameActive()` calls `adoptKeyIfReadable()` and recovers cleanly |
| 2.11 | **10-watch cap & reinstall** | Register >10 keys for same user/org; delete & reinstall watch app | Oldest LRU key pruned server-side; reinstall re-registers fingerprint seamlessly (`paired_by` preserved, `push_token` reassigned to new key) |

---

### Phase 3 — Core Screens, Actions, Risk Gates & SSE Streaming
Exercise every screen (`NowView`, `NeedsListView`, `ApprovalView`, `SuggestionView`, `PhoneOnlyView`, `AskView`, `RunView`, `ChatView`, `BotsView`, `UpNextView`, `BriefView`, `TalkView`, `SettingsView`) and every server error path:

1. **Glance caching & ETag (`WatchAPI.glance`):**
   - Cold launch shows skeleton placeholder (never a spinner) or cached glance immediately, then refreshes in background.
   - Verify `If-None-Match` returns `304 Not Modified` when unchanged, `GlanceCache.touchGlance()` updates `savedAt`, and `isStale` clears when back online.
   - Test malformed/partial JSON rows in `Glance` (`LossyList` skips bad items without blanking the whole screen).
   - Test `madeAt` race: ensure stale response cannot overwrite a newer cached glance written by the widget extension.
2. **Approvals & Risk Enforcement (`ApprovalView`, `AllowRequestIntent`, `WristCheck`):**
   - **Low risk:** single tap **Allow**; verify `WristCheck` (`deviceOwnerAuthenticationWithWristDetection`) behavior on simulator (with & without passcode set -> `LAError.passcodeNotSet` shows `WatchL10n.lockToAllow`!) and on physical watch (on wrist vs off wrist).
   - **Medium risk:** renders `HoldToAllowButton` (0.8s fill, label color transition `amberText` → `onAmber`, haptic click on completion, cancel/reset on release <0.8s); test VoiceOver mode switches to tap + `confirmationDialog`.
   - **High risk / `payment` (`data.call` or money):** renders **Review on iPhone** + **Deny** only; verify server refuses forged `POST /v1/approvals/{id}/decision` with `403 watch_allow_refused` (`detail: high_risk|payment|setting|not_yours`), and `always_allow: true` returns `403 watch_always_allow`.
   - **Watch allowance levels (`watch_prefs.allow`: `medium`, `low`, `none`):** toggle in Settings → Watch on iPhone and verify `ApprovalView` and `NeedsRectView` complication update within 30s (including on active SSE streams via `keyNow`).
   - **Conflict & cross-workspace codes:** approve on phone first → watch tap shows `alreadyAnswered` tick (`409 approval_already_decided`); open approval from another workspace → `404 not_found` shows `PhoneOnlyView` (`notOnWatch`), never "Already answered".
3. **Suggestions, Routines & Brief:**
   - `SuggestionView`: **Do It** starts run (`started` flash), **Not now** dismisses (`done` flash), `402` out-of-credits shows `outOfCredits` + **Open on iPhone** button.
   - `UpNextView`: sorted by `nextAt`, **Run Now** triggers routine and respects `busy` lock & error notes.
   - `BriefView`: renders latest brief, `nextAt`, `hideWords` privacy, and **Chat** navigation.
4. **SSE Run Streaming (`RunFollower`, `WatchSSE.swift`, `GET /v1/watch/runs/{id}?stream=1`):**
   - Start a long multi-step run and open `RunView`. Verify initial snapshot arrives immediately, step counter & `RunClock` tick, `: ping` keepalives don't trigger spurious UI flashes, and `RunChange` plays distinct haptics (`.notification` on `needsOk`, `.success` on `finished`, `.failure` on `problem`).
   - Verify **110s server rollover**: wait >110s on an active run and confirm server closes cleanly and `RunFollower` reconnects seamlessly without losing state or showing an offline banner.
   - Verify **3-stream limit (`WATCH_STREAMS_PER_KEY = 3`)**: open 4 concurrent streams with the same watch key (via curl/test script + simulator) and confirm the 4th closes the oldest cleanly.
   - Verify **Stop button** (`POST /v1/runs/{id}/cancel`), **Take Over** (`Open on iPhone`), and **Undo** from `AskView`'s `heard` stage.
   - Verify **60 req/min rate limit (`429 rate_limited` + `Retry-After`)**: ensure rapid refreshes/streams stay well under 60/min and handle 429 gracefully without wiping the key.

---

### Phase 4 — Voice Recording, Offline Ask Queue, Dictation & Read Aloud
1. **Voice Ask (`AskView.swift` / `Recorder`):**
   - Verify microphone permission prompt (`NSMicrophoneUsageDescription`) and denied state (`micDenied` view).
   - Speak into Mac mic routed to simulator: verify `LevelBars` animate, silence detection stops recording after `1.5s` below `-42 dBFS`, `6s` silence auto-cancels without sending, `60s` hard cap works.
   - Verify temp `.m4a` file size (<1.1 MB), upload in `POST /v1/watch/ask`, transcription (`heard` preview with 2.5s auto-advance + **Undo**), and cleanup of temp audio file (`AskQueueStore.purgeTemp()`) on all exit paths (success, error, `onDisappear`).
   - Test error codes: `400 nothing_heard` / `bad_audio` → `didntCatch`, `409 voice_unavailable` → `couldntReach`, `402` → `outOfCredits`.
   - Test **Type instead** (`TextFieldLink` with Scribble/dictation/keyboard) and **Starters** list.
2. **Offline Queue (`AskQueueStore` & `AppModel.sendKept`):**
   - Disable network (toggle Mac/simulator network or point dev proxy down), record a voice ask and a typed ask: verify `.m4a` moves to `WatchGroup.container/asks/<key>.m4a`, `NowView` shows `keptOffline` banner, and `queue` persists across app relaunch.
   - Reconnect within 10 minutes: verify automatic flush on `networkChanged(true)` / `refresh()` with `Idempotency-Key` (verify double-delivery produces only **1** conversation & **1** message via `derivedKey`).
   - Age a kept ask >10 minutes (adjust `askedAt` in debug or wait): verify `confirmAsk` alert ("Send / Discard") appears on `RootView`.
   - Test retry vs drop policy (`AskQueuePolicy.afterFailure`): `5xx` keeps for retries; `4xx` drops and shows `askDropped` notice (held in `heldNotice` if app was in background!).
3. **Read Aloud (`Speaker` in `RunView.swift`):**
   - Test server voice (`GET /v1/messages/{id}/speech` MP3 via `AVAudioPlayer`) and fallback on-device `AVSpeechSynthesizer` when server voice is off or fails.
   - Verify `hideReplyText = true` suppresses `canSpeak` (`403 watch_details_hidden` server-side) and hides Read Aloud button on watch.

---

### Phase 5 — Notifications, Mirrored vs Direct APNs, Quick Replies & Handoff
1. **Simulator APNs payload suite (`xcrun simctl push`):**
   Create deterministic `.apns` fixture files in a scratch folder (never committed with secrets) covering every category and edge case in `docs/WATCH-PROTOCOL.md` §4:
   - `APPROVAL` (`low`, `medium`, `high`, `payment`, `can_allow: tap|hold|phone`, `urgent: true` time-sensitive)
   - `SUGGESTION` (`DO_IT`, `NOT_NOW`)
   - `REPLY` (`conversation_id`, `message_id`, `bot_id`, quick replies + `UNTextInputNotificationResponse` dictated reply)
   - `brief`, `routine`, `failed`, `takeover`
   - Cross-workspace (`org_id` != watch's `orgId`) → verify `isElsewhere` strips notification action buttons (`notificationActions = []`) and shows `"In another workspace"`!
   - Privacy modes: `show_details = false`, `hide_reply_text = true`, private glance (`flags.private = true`) → verify `ApprovalNotificationController` fetches details only when allowed and masks them when hidden.
   - `watch-handoff` suppression: verify `willPresent` returns `[]` when `tag == "watch-handoff"` so "Open on iPhone" doesn't echo back onto the watch while the watch app is active.
2. **Action button execution paths (`NotificationRouter`):**
   - Cold-launch the watch app directly from a notification action (`ALLOW`, `DENY`, `DO_IT`, `REPLY`) to verify `AppModel.shared.start()` + `adoptKeyIfReadable()` runs **before** checking `model.phase == .signedIn`.
   - Verify failed notification actions (`offline`, `notFound`, `forbidden`) leave a `pendingNote` and open the relevant screen (`ApprovalView`, `SuggestionView`, `ChatView`) so failures are never silent.
3. **Open on iPhone (`openOnPhone` & `/v1/watch/handoff`):**
   - With `Runner` in foreground → `PhoneLink.ask` returns `front: true`, iPhone navigates via `WatchOpen` / GoRouter immediately, no redundant push sent.
   - With `Runner` backgrounded/terminated or out of reach → watch calls `POST /v1/watch/handoff` and phone receives high-priority push notification opening the exact deep link (`PhoneRoutes`).
4. **Physical hardware APNs & mirroring tests (once Apple push key & App IDs are live):**
   - Lock paired iPhone + wear unlocked Apple Watch: verify mirrored iPhone push renders `CasamaWatch` custom `WKUserNotificationHostingController` layout (`ApprovalNotificationView`, `SuggestionNotificationView`, `ReplyNotificationView`), **Allow** / **Deny** execute with the watch's own key, and Double Tap triggers the primary non-destructive action (`ALLOW`).
   - Turn iPhone completely off (Airplane Mode / powered off), keep watch on Wi-Fi or cellular: verify direct APNs push to `watch_keys.push_token` (`apns-topic: ai.casama.app.watchkitapp`, `push_sandbox` matching build type) arrives on wrist.
   - Re-enable iPhone so both iPhone and direct Watch APNs fire together: verify `apns-collapse-id: n-<notification_id>` collapses them into a single notification (no duplicate alerts!).

---

### Phase 6 — Complications, Smart Stack, Controls, Siri, Bot Pictures & Live Activity
1. **All 10 WidgetKit complications (`Complications.swift`) across watch faces:**
   - Add each widget (`WatchInlineWidget`, `WatchNeedsCircularWidget`, `WatchNeedsCornerWidget`, `WatchNeedsRectWidget`, `WatchAskWidget`, `WatchCreditsWidget`, `WatchBotWidget`, `WatchUpNextWidget`, `WatchWorkingWidget`, `WatchBriefWidget`) to faces on 40mm, 42mm, 46mm, and 49mm simulators.
   - Check every state: signed out, needs > 0 (1 vs many), all clear, working run, routine upcoming, credits gauge, stale (>30m `GlanceAge.isStale` shows `"as of"` and drops live accents), private workspace (`hideWords`), Always-On `privacySensitive()` redaction, and tinted watch faces (`.widgetAccentable()`).
   - Verify interactive button on `NeedsRectView` (`AllowRequestIntent`): tap when `needsCount == 1 && risk == .low && allow != "none"` → runs in extension, refreshes glance, reloads timelines.
2. **Smart Stack relevance (`GlanceProvider.relevance()` & `GlanceLoader.score()`):**
   - Trigger each priority state (needs waiting → score 100; live run → 70; routine within 30m → 50; brief within 1h → 30; idle → 0) and verify Smart Stack surfaces the right card.
3. **Bot pictures in Watch & Complications (`BotPictureStore.swift`):**
   - Assign a bot a custom `image:<uuid>:<c1><c2>` avatar on the server, refresh watch glance, and verify `BotPictureStore.ensure` downloads the 128px PNG into `group.ai.casama.app.watch/bot-images/` and calls `reloadWidgets()` so complications show the photo (falling back cleanly to initials on the two extracted colors when offline).
4. **Controls (`WatchControls.swift`):**
   - Add `AskControl`, `TalkControl` (configured bot), and `RunRoutineControl` (configured routine) to watchOS Control Center, Smart Stack, and Ultra 4 Action Button. Verify deep-link launch via `OpenWatchIntent` (`WatchOpen.takePending()` on cold start!) and direct execution via `RunControlIntent`.
5. **Siri & App Shortcuts (`Siri.swift`):**
   - Test `AskCasamaIntent`, `WhatNeedsMeIntent`, and `RunRoutineNowIntent` via Xcode / Shortcuts app / Siri simulator (`"What needs me in Casama"`, `"Run my <routine> in Casama"`), including privacy masking (`flags.isPrivate || flags.hideReplyText` omits item text in Siri dialog).
6. **iPhone Live Activity on Watch (`CasamaWidgets.swift` + `CasamaWatchApp.swift`):**
   - Start a bot run from the iPhone so `IslandActivities` creates a `RunActivityAttributes` Live Activity.
   - Verify `.supplementalActivityFamilies([.small])` renders Casama's custom compact watch layout in the Smart Stack and tapping it launches `CasamaWatch` directly into `RunView` via `onContinueUserActivity(NSUserActivityTypeLiveActivity)`.

---

### Phase 7 — Privacy, Accessibility, Layout & Stress Matrix
1. **Wrist-down Always On (`isLuminanceReduced`):**
   - Verify `hideWhenWristDown = true` replaces `PrivateText` with grey capsules, mutes `BotMarkView`, and changes `Card` fill to subtle outline (`0.22` white stroke), while keeping counts, bot names, and `RunClock` visible. Toggle `hideWhenWristDown = false` in Watch Settings and re-check.
2. **Dynamic Type & Reduce Motion:**
   - On `40mm SE 3` and `46mm Series 12`, crank Dynamic Type to maximum accessibility size (`AX5`): verify `NowView` caps live runs to 1 and hides Brief (`big == true`), no buttons clip/truncate off-screen, and `HoldToAllowButton` remains usable.
   - Toggle `Reduce Motion`: verify `WorkingRing`, `LevelBars`, and `DoneOverlay` stop looping/sliding animations cleanly.
   - Enable `VoiceOver`: verify `HoldToAllowButton` switches to tap + confirmation dialog, `CodeView` spells out characters individually (`WatchCodeFormat.spoken`), and `Card`s combine accessibility labels logically.
3. **Background refresh & resource budgets:**
   - Trigger simulated `WKApplicationRefreshBackgroundTask` in Xcode (`Debug → Simulate Background Fetch` / `e -l objc` or scheme background task) and verify `WatchSync.refreshGlance(quick: true)` finishes well inside the ~4s budget (`quickSession` 8s/10s) and calls `setTaskCompletedWithSnapshot(false)` on every branch.
   - Inspect memory footprint of `CasamaWatchWidgets` extension (watchOS widget extensions have tight ~30 MB jetsam limits — verify `BotPictureStore.memory` 24-image cap and `CGImageSource` decoding don't spike memory).

---

## 5. Known risks & watchpoints to scrutinize during debugging

| Risk / Watchpoint | Where in code | What could break in real execution |
|---|---|---|
| `Localizable` / string literals vs `WatchL10n` | `WatchIntents.swift`, `Siri.swift`, `WatchControls.swift` | Control `displayName` uses `LocalizedStringResource(stringLiteral: WatchL10n.controlAsk)` while `AppIntent.title` uses string literals — verify watchOS App Intents indexing doesn't reject non-literal `LocalizedStringResource` at build or runtime |
| `WatchKeyStore` fallback hides extension bug | `WatchKeyStore.swift:75-83` | Falling back to `group: false` on `errSecMissingEntitlement` lets the main app work while `CasamaWatchWidgets` fails silently |
| `RunView` / `AskView` SwiftUI `@StateObject` + `NavigationStack` | `RootView.swift`, `RunView.swift`, `AskView.swift` | Deep links replace `model.path`; verify `onDisappear` cancels `RunFollower` SSE stream and `Recorder` audio session even when `path` is mutated programmatically |
| `Sendable` / Swift 5 concurrency warnings in Xcode 27 | `PhoneLink.swift`, `BotPictureStore.swift`, `Notifications.swift` | Files use `@unchecked Sendable` and `Task { @MainActor in }`; verify zero Swift concurrency crashes or main-thread checker violations on watchOS 27.2 |
| `WatchDeviceInfo.apnsSandbox` on TestFlight | `WatchAPI.swift:384-392` | `embedded.mobileprovision` check in `#else` assumes TestFlight/App Store embeds no `development` `aps-environment`; verify actual `.ipa` Watch binary payload before shipping Phase 5 |
| `WatchDevice.model` point-width table | `AppModel.swift:919-925` | Check actual `WKInterfaceDevice.current().screenBounds.width` on Series 12 (`42mm`/`46mm`), Ultra 4 (`49mm`), and SE 3 (`40mm`/`44mm`) simulators |

---

## 6. Deliverables & exit criteria

1. **Observability PR (small, safe):** `WatchLog.swift` (`os.Logger` with zero secret leakage), `-CasamaWatchServer` `#if DEBUG` flag, and optional 5-tap Debug Diagnostics sheet in `SettingsView`.
2. **Findings log:** `docs/APPLE-WATCH-DEBUG-FINDINGS.md` recording every bug/quirk found (P0–P3), evidence (simctl logs, screenshots), and fix status.
3. **All Phase 0–4 + Phase 5/6 simulator checks green**, plus `Watch-PLAN.md` §12 / `PLANS.md` updated with what passed on simulators vs what remains on physical watch hardware / Apple Developer portal.

---

## 7. Decisions & inputs needed from Oliver

1. **Build permission:** May we run `xcodebuild` (`CasamaWatch` scheme) and `flutter run` / `flutter build ios` in `client/` to start Phase 1 compilation and simulator debugging?
2. **Debug instrumentation:** Do you want `WatchLog.swift` (`os.Logger`) + `#if DEBUG` `-CasamaWatchServer` + the 5-tap Debug Diagnostics screen added to the codebase, or keep the initial pass strictly read/test-only first?
3. **Target backend for debugging:** Should simulator debugging target the local dev stack (`http://localhost:8787` / `https://api-dev.casama.ai` via `scripts/dev-up.sh`), or also check anything against production after deploying `WATCH-PLAN` audit fixes?
4. **Physical device & APNs scope:** Do you have a physical Apple Watch (watchOS 26+) and iPhone ready for Phase 5/6 real-hardware checks, and should we leave real-APNs / App Store profile registration for a separate turn once simulator phases are clean?
