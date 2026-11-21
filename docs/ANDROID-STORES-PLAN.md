# Other Android stores: plan

Status: **Phases 1 and 2 built, not yet built as an APK** (2026-11-21). Oliver asked to start on the
other Android stores, so the code and scripts went ahead on the recommended answers to §7 (stores 1–3,
per-ABI APKs, `galaxy` on web checkout). Nothing is built, uploaded or submitted: the first APK build,
every store account and every submission still need Oliver's yes. Phase 3 is waiting on him.

## 0. Goal

Ship Casama on Android outside Google Play — starting with direct APK distribution (**GitHub Releases** + **Obtainium** / **IzzyOnDroid**, **Aptoide / APKPure / Uptodown**) and **Samsung Galaxy Store**, and leaving clear extension points for **Amazon Appstore**, **Huawei AppGallery**, and **F-Droid** later.

Today, every Android build hardcodes Google Play (`PurchaseChannel.googlePlay`, `RevenueCatStore('google_play', ...)`, Play `InAppReview`, no gift codes). Distributing an APK outside Play with Play Billing fails for users without Play Services and violates non-Play store rules (e.g., Samsung Galaxy Store) or misses web checkout (no 15–30% store fee).

---

## 1. Current state in the codebase

| Area | Current behavior | File |
|---|---|---|
| Distribution flag | `kDistribution = String.fromEnvironment('CASAMA_DISTRIBUTION', defaultValue: 'direct')`; only `isMacAppStoreBuild` checks it | [`client/lib/core/distribution.dart`](../client/lib/core/distribution.dart) |
| Purchase channels | `TargetPlatform.android` always returns `[PurchaseChannel.googlePlay]` | [`client/lib/core/billing.dart`](../client/lib/core/billing.dart) |
| Gift codes | `giftCodesAllowed` returns `false` for Android | [`client/lib/core/billing.dart`](../client/lib/core/billing.dart) |
| Store instance | `defaultStore` always returns `RevenueCatStore('google_play', kRevenueCatGoogleKey, ...)` on Android | [`client/lib/core/billing.dart`](../client/lib/core/billing.dart) |
| Domain buying | `canBuyDomainsProvider` asks `purchaseChannels(...)`, so `PurchaseChannel.web` automatically enables it | [`client/lib/features/sites/domain_buying.dart`](../client/lib/features/sites/domain_buying.dart) |
| Review prompt | `_platformSupported` is `true` for all Android builds; `openStore()` calls Play `InAppReview` | [`client/lib/core/review_prompt.dart`](../client/lib/core/review_prompt.dart) |
| Telemetry | `Telemetry.distributionName` returns `'google_play'` for any Android build | [`client/lib/core/telemetry.dart`](../client/lib/core/telemetry.dart) |
| Android build script | `scripts/package-android.sh` builds `appbundle` (default) or `apk` (`--split-per-abi` or `--no-split`) without setting `CASAMA_DISTRIBUTION` | [`scripts/package-android.sh`](../scripts/package-android.sh) |
| Release publisher | `scripts/publish-desktop-release.sh` uploads macOS/Windows/Linux artifacts to `stackwares/casama-releases` (and mirrors to `stackwares/casama`), no APK yet | [`scripts/publish-desktop-release.sh`](../scripts/publish-desktop-release.sh) |
| Download links | `GET_LINKS.android` in `site/gallery-link.js` points to Google Play | [`site/gallery-link.js`](../site/gallery-link.js) |

---

## 2. Design: `CASAMA_DISTRIBUTION` on Android

### 2.1 Allowed values

Extend `CASAMA_DISTRIBUTION` (`client/lib/core/distribution.dart`) for Android:

| Value | Meaning | Billing (`purchaseChannels`) | Gift codes (`giftCodesAllowed`) | Store review prompt (`ReviewPrompt`) | Push / Google Sign-In |
|---|---|---|---|---|---|
| `play` (or `direct` default on Android when unspecified — see §2.2) | Google Play (`appbundle`) | `[PurchaseChannel.googlePlay]` | `false` | Play `InAppReview` | FCM + Google Sign-In |
| `apk` | Direct APK (GitHub Releases, Obtainium, IzzyOnDroid, Aptoide, APKPure, Uptodown) | `[PurchaseChannel.web]` (Dodo checkout) | `true` | Off (no single store) | FCM + Google Sign-In where Play Services exist |
| `galaxy` | Samsung Galaxy Store | `[PurchaseChannel.web]` if Samsung allows external billing for AI/SaaS, or Samsung IAP if required (decide in §7) | `false` if IAP, `true` if web | Off (or Galaxy Store deep link later) | FCM + Google Sign-In (Galaxy has Play Services) |
| `amazon` *(later)* | Amazon Appstore (Fire tablets) | Amazon IAP via RevenueCat (`amazon`) | `false` | Off | ADM or none; hide Google Sign-In |
| `huawei` *(later)* | Huawei AppGallery | Huawei IAP (custom) | `false` | Off | HMS Push; hide Google Sign-In |
| `foss` *(later)* | F-Droid | `[PurchaseChannel.web]` | `true` | Off | None / UnifiedPush; hide Google Sign-In |

### 2.2 Default value safety

`kDistribution` currently defaults to `'direct'` (used by desktop direct downloads and `flutter run` in local dev).
On Android:
- When `kDistribution == 'direct'` (local `flutter test` / `flutter run` without `--dart-define`) or `kDistribution == 'play'`, treat it as **Google Play** (`isGooglePlayBuild == true`) so existing tests (`billing_test.dart`, `comps_test.dart`) and default `package-android.sh` (AAB for Play) keep their exact behavior without needing extra flags.
- `scripts/package-android.sh` accepts `--distribution <play|apk|galaxy>` and passes `--dart-define=CASAMA_DISTRIBUTION=...`. It defaults to `play` for every target, including `apk`, so an APK made for a device check keeps Play billing; store APKs ask for `--distribution apk` or `galaxy`. Any other value is refused.

### 2.3 Billing, StorePurchases, and Telemetry

1. **`client/lib/core/distribution.dart`:**
   - Add `androidDistribution` helper (or `isGooglePlayBuild`, `isAndroidApkBuild`, `isGalaxyStoreBuild`) and `@visibleForTesting` override or parameter on `purchaseChannels` / `giftCodesAllowed` / `defaultStore` so unit tests can test every Android distribution without compile-time `String.fromEnvironment` limitations.
2. **`client/lib/core/billing.dart`:**
   - `purchaseChannels({required TargetPlatform platform, required bool isWeb, String? storefront, String? distribution})`:
     - `TargetPlatform.android` with `apk` (or `foss`, or `galaxy` if web checkout) → `const [PurchaseChannel.web]`.
     - `TargetPlatform.android` with `play` (or default `direct`) → `const [PurchaseChannel.googlePlay]`.
   - `giftCodesAllowed({required TargetPlatform platform, required bool isWeb, String? distribution})`:
     - `TargetPlatform.android` → `true` when the distribution uses `[PurchaseChannel.web]` (`apk`, `foss`, etc.), `false` on `play`.
   - `defaultStore(...)`:
     - On `TargetPlatform.android`, only return `RevenueCatStore('google_play', kRevenueCatGoogleKey, currentOrg)` when `isGooglePlayBuild`. Return `const NoStore()` for `apk` (and `foss`) so RevenueCat's Google Play Billing client is never initialized on non-Play builds.
3. **`client/lib/core/review_prompt.dart`:**
   - `_platformSupported`: on Android, require `isGooglePlayBuild` (so `apk` / `galaxy` builds don't prompt to rate on Google Play).
4. **`client/lib/core/telemetry.dart`:**
   - `Telemetry.distributionName`: return `'google_play'` for `play`, `'android_apk'` for `apk`, `'galaxy_store'` for `galaxy`, etc., so PostHog/analytics funnels can segment Play vs direct APK vs Galaxy Store.

---

## 3. Signing & upgrade compatibility

- **Signing key:** Use the existing upload key (`~/.config/casama/android-upload-keystore.jks` / `client/android/key.properties`, vault: `"Casama · Android upload key (ai.casama.app)"`) for `apk` and `galaxy` builds.
  - Because Google Play App Signing re-signs Play builds with Google's key, **Play installs and direct APK / Galaxy installs cannot update over each other** (documented in `docs/STORES.md`). Signing all non-Play builds with our own upload key lets users update seamlessly across GitHub Releases, Obtainium, Aptoide, APKPure, Uptodown, and Galaxy Store.
- **APK format:**
  - `scripts/package-android.sh apk` already supports `--split-per-abi` (default, ~3 per-ABI APKs: `arm64-v8a`, `armeabi-v7a`, `x86_64`) and `--no-split` (universal APK).
  - For GitHub Releases + Obtainium, `arm64-v8a` covers ~99% of modern Android phones, and uploading `arm64-v8a` + `armeabi-v7a` (or universal) works cleanly with Obtainium's APK filter.

---

## 4. Phased rollout

### Phase 1: Code & unit tests (`CASAMA_DISTRIBUTION` for Android) — built 2026-11-21
1. Update [`client/lib/core/distribution.dart`](../client/lib/core/distribution.dart), [`client/lib/core/billing.dart`](../client/lib/core/billing.dart), [`client/lib/core/review_prompt.dart`](../client/lib/core/review_prompt.dart), and [`client/lib/core/telemetry.dart`](../client/lib/core/telemetry.dart).
2. Add/update unit tests in `client/test/billing_test.dart`, `client/test/comps_test.dart`, and `client/test/review_prompt_test.dart` (if present, or a new test) covering `play`, `apk`, and `galaxy`.
3. Update [`client/README.md`](../client/README.md) documenting the new `CASAMA_DISTRIBUTION` values.
- **Done when:** `cd client && flutter analyze && flutter test test/billing_test.dart test/comps_test.dart` pass.

### Phase 2: Build & release scripts (GitHub Releases APK + Obtainium) — scripts built 2026-11-21; the download-page link waits for a real APK
1. Update [`scripts/package-android.sh`](../scripts/package-android.sh) to accept `--distribution <name>` (default `play` for `appbundle`, `apk` for `apk`), copy built APKs into `dist/` with versioned names (e.g., `dist/casama-<version>-android-arm64-v8a.apk`, `dist/casama-<version>-android-universal.apk`).
2. Update [`scripts/publish-desktop-release.sh`](../scripts/publish-desktop-release.sh) (or add an Android APK glob) so `dist/casama-$version-android-*.apk` files are attached to the GitHub release on `stackwares/casama-releases` and `stackwares/casama`.
3. Update [`site/gallery-link.js`](../site/gallery-link.js) (`GET_LINKS`) and `site/download.html` if desired to expose an `android-apk` direct download link alongside `android` (Play).
- **Done when:** dry-run / script syntax checks pass and `docs/STORES.md` is updated. (Actual `flutter build apk` waits for Oliver's explicit permission per `AGENTS.md`.)

### Phase 3: Store accounts & submissions (requires Oliver)
1. **GitHub Releases + Obtainium:** Attach the `apk` build on the next release; add Obtainium JSON / link on the download page.
2. **IzzyOnDroid:** Open a packaging request issue on `IzzyOnDroid/iod-izzyondroid` (or `rfc` repo) pointing to `stackwares/casama-releases` (note: IzzyOnDroid flags Firebase/Crashlytics as anti-features unless built without them, which is fine and expected for `apk`).
3. **Samsung Galaxy Store:** Oliver creates the Samsung Seller Portal account (saves login in Vaultwarden as `"Casama · Samsung Galaxy Store developer account"`), confirms Samsung IAP vs web checkout policy for AI SaaS apps, then we build `CASAMA_DISTRIBUTION=galaxy` and submit.
4. **Aptoide / APKPure / Uptodown:** Oliver creates free developer accounts (saved in Vaultwarden); upload the signed `apk` build.

---

## 4a. Google services check (2026-11-21)

Checked what happens on a phone without Google Play services (Huawei, Fire, de-Googled ROMs) and on
sideloaded installs. The app already copes; no code change was needed beyond billing:

| Piece | Without Play services |
|---|---|
| Firebase start-up (`Firebase.initializeApp` in `push.dart`, `crashlytics.dart`, `analytics_sinks.dart`) | Every call is inside `try`/`catch`; the app keeps running |
| Push (FCM token, permission) | `getToken` and `requestPermission` are caught, so no token is registered; no pushes, call rings or approval alerts arrive. Chat and the in-app inbox still work when open. Real fix is HMS or ADM (the later `huawei` / `amazon` distributions) |
| Google sign-in | `googleSheetUnavailable()` treats a `PlatformException` as "Google's sheet isn't available" and offers the browser sign-in; email and passkeys work |
| Wear OS bridge (`WearBridge.kt`) | Checks `GoogleApiAvailability.isGooglePlayServicesAvailable` first and does nothing otherwise |
| Firebase App Check | Not used by the Android client; sign-up uses the server's proof-of-work puzzle (`/v1/signup/challenge`) |
| Purchases | Not started on `apk`/`galaxy`: `defaultStore` returns `NoStore`, so RevenueCat's Play Billing client never runs; the paywall uses Dodo web checkout |
| Store review prompt | Off on `apk`/`galaxy` (it opens Google Play) |

Galaxy phones and most devices that get the APK have Play services, so push and Google sign-in work
there as on Play. Still to confirm on a real build: install the `apk` build on an emulator image
without Google APIs and check the app opens, the paywall shows web checkout and sign-in works.

## 5. Verification

- Unit tests: `flutter test test/billing_test.dart test/comps_test.dart`
- Static analysis: `cd client && flutter analyze`
- Full suite before push: `scripts/heavy.sh sh -c 'cd client && flutter analyze && flutter test'`
- Manual / device check (after Oliver approves a build): install `CASAMA_DISTRIBUTION=apk` APK on Android emulator/device, verify paywall opens Dodo web checkout instead of Play Billing, gift code redemption is visible in Billing, and "Rate Casama" does not try to open Play Store.

---

## 6. Files to touch

- [`client/lib/core/distribution.dart`](../client/lib/core/distribution.dart)
- [`client/lib/core/billing.dart`](../client/lib/core/billing.dart)
- [`client/lib/core/review_prompt.dart`](../client/lib/core/review_prompt.dart)
- [`client/lib/core/telemetry.dart`](../client/lib/core/telemetry.dart)
- [`client/test/billing_test.dart`](../client/test/billing_test.dart)
- [`client/test/comps_test.dart`](../client/test/comps_test.dart)
- [`client/README.md`](../client/README.md)
- [`scripts/package-android.sh`](../scripts/package-android.sh)
- [`scripts/publish-desktop-release.sh`](../scripts/publish-desktop-release.sh)
- [`docs/STORES.md`](../docs/STORES.md) and [`docs/PLANS.md`](../docs/PLANS.md)

---

## 7. Open questions for Oliver (answer before coding)

1. **Which stores to target first?** `docs/STORES.md` recommends **1 (GitHub Releases APK + Obtainium / IzzyOnDroid)**, **2 (Samsung Galaxy Store)**, and **3 (Aptoide / APKPure / Uptodown)**. Should we include all three in this rollout, or start with GitHub Releases APK + Aptoide/APKPure/Uptodown first?
2. **APK architecture on GitHub Releases / third-party stores:** Should we ship **per-ABI APKs** (`arm64-v8a` ~90 MB + `armeabi-v7a`) or a **universal APK** (`--no-split`, ~330 MB)? (Per-ABI `arm64-v8a` + `armeabi-v7a` is much smaller and works with Obtainium/APKPure/Galaxy Store.)
3. **Samsung Galaxy Store billing:** Do you want `galaxy` to start with **web checkout** (like `apk`, if Samsung's review allows it for AI/SaaS services) or do we need to integrate **Samsung IAP**? (Starting with `galaxy` = web checkout is small; Samsung IAP would be its own integration.)
4. **Go-ahead to build Phases 1 & 2?** Confirming approves implementing the `CASAMA_DISTRIBUTION` code changes, tests, and packaging script updates (any actual `flutter build apk` will still ask you first).
