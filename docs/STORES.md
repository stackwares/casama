# Stores: where Casama ships

One page for every store and directory that carries a Casama build: the ones that are live, the ones
in review, and the ones we plan to add. Update the row in the same commit as any change to a
listing (submitted, approved, rejected, new version live, dropped).

Status as of **2026-11-21**. Directories, awesome lists and MCP registries are tracked separately in
`docs/launch/listings.md`.

Rules that apply to every row:

- Every upload or submission is a release: it needs Oliver's yes each time (AGENTS.md "Production",
  memory "no store uploads").
- Secrets live in Vaultwarden. This page names vault items, never values.
- Store text and screenshots come from `client/store/` (README lists every setting) and the
  Marketing workspace (`store-assets` skill). Keep the wording the same across stores.
- Build number is `version:` in `client/pubspec.yaml`, shared by every platform (now `0.1.0+68`).

## Status at a glance

| Store | Platform | Status | Next step |
|---|---|---|---|
| Google Play (phone, tablet) | Android | Closed testing Alpha 0.1.0 (44) sent for review 2026-11-19 | Open testing / production when Oliver says |
| Google Play (Wear OS) | Wear OS | Tracks exist (`wear:internal`, `wear:beta`, `wear:production`) | Ship with every phone release (AGENTS.md) |
| App Store (iPhone, iPad, Watch inside) | iOS | Listing, privacy, IAPs ready; never sent for review | First review when Oliver says |
| Mac App Store | macOS | Same record as iOS; profiles regenerated 2026-11-19 | Ships together with the direct DMG |
| Direct download (GitHub Releases) | macOS, Windows, Linux | `scripts/publish-desktop-release.sh` | Each release with its Mac App Store twin |
| Chrome Web Store | Chrome, Brave, Arc, Vivaldi, Opera | Submitted 0.1.0 on 2026-11-21, pending review (id `kkfppfhkjnenffibmnkphnbejidkmbkj`) | Wait |
| Edge Add-ons | Edge | Submitted 0.1.0 on 2026-11-21, in review (about 7 business days) | Wait |
| Firefox Add-ons (AMO) | Firefox | Submitted 0.1.0 on 2026-11-21, pending review (`casama@casama.ai`) | Wait |
| Snap Store | Linux | Name `casama` approved 2026-11-18; classic confinement request not filed | File classic request, first upload |
| Microsoft Store | Windows | MSIX packaging exists (`scripts/package-windows.ps1`); no listing | Decide; reserve the name |
| Web app | Browser | Live at app.casama.ai | n/a |
| Samsung Galaxy Store | Android | **Planned** | See "Other Android stores" |
| GitHub Releases APK (+ Obtainium, IzzyOnDroid) | Android | **Planned** | See "Other Android stores" |
| Amazon Appstore | Fire tablets only | **Maybe** | See "Other Android stores" |
| Huawei AppGallery | Android without Google | **Later** | See "Other Android stores" |
| F-Droid | Android (FOSS only) | **Later** | See "Other Android stores" |
| Aptoide, APKPure, Uptodown | Android | **Maybe** | See "Other Android stores" |
| China mainland stores (Xiaomi, OPPO, vivo, Tencent, Baidu) | Android | **Not doing** | China is off on purpose (no CAC AIGC filing) |

## Live and in review

### Google Play

| Field | Value |
|---|---|
| Developer account | Stackwares (id 6609804826699409799), owner ciphere.bytes@gmail.com (Anna May A Valdez's personal account; passed the 12-testers / 14-days rule) |
| App | Casama: AI Teammates, package `ai.casama.app`, Play app id 4974011891118212365 |
| Signing | Play App Signing. Upload key `~/.config/casama/android-upload-keystore.jks`; vault: "Casama · Android upload key (ai.casama.app)" and "… keystore file (base64)" |
| Billing | Play Billing through RevenueCat (`kRevenueCatGoogleKey`), Play only; no web checkout on Android |
| Trader status | Declared 2026-11-19 (public contact dev@stackwares.com) |
| Testers | Email list "Casama team" + "License Testers" |
| CLI | `gplay` (profile play-publisher); skills `publish-gplay`, `gplay-populate-iap-info` |
| Build | `scripts/package-android.sh` + `scripts/package-wear.sh` (Wear goes with every Play release) |
| Status | Alpha 0.1.0 (44) closed testing sent for review 2026-11-19; managed publishing off |

### App Store and Mac App Store

| Field | Value |
|---|---|
| Team | `V8V5US964Z` |
| App | Casama AI (id 6833509960, SKU CASAMA), bundle `ai.casama.app`; shown as "Casama: AI Teammates" |
| Subscriptions | Group "Casama" 22574241: plus/pro/max × monthly/yearly, credit packs `ai.casama.credits.10/.25`, all ready to submit |
| Billing | StoreKit through RevenueCat; web checkout also shown on the US storefront only |
| API keys | ASC key CC7KG77GYT, IAP key HW9SYD2XPL (both in vault, Keys & Signing) |
| Mac profiles | "Casama Mac App Store", "Casama Widgets Mac App Store" (+ Developer ID twins for the DMG) |
| Territories | All except China mainland (App Compliance answered No for both CAC entries) |
| CLI | `asc`; skills `publish-asc`, `asc-metadata-sync`, `app-store-preflight-skills` |
| Build | `scripts/package-ios.sh`, `scripts/package-macos-appstore.sh` (with `CASAMA_DISTRIBUTION=appstore`) |
| Status | Never sent for review. Watch app ships inside the iOS record when built |

### Desktop direct download

| Field | Value |
|---|---|
| Where | GitHub Releases on stackwares/casama; download page casama.ai/download, links in `GET_LINKS` (`site/gallery-link.js`) |
| Mac | Notarized DMG, `scripts/package-macos.sh`; always shipped with the Mac App Store build; installed into /Applications here |
| Windows | MSIX + WinSparkle feed, `scripts/package-windows.ps1` (`MSIX_CERT`, `WINSPARKLE_KEY`) |
| Linux | `scripts/package-linux.sh` bundle |
| Publish | `scripts/publish-desktop-release.sh` |

### Browser extension

| Store | Ids | Notes |
|---|---|---|
| Chrome Web Store | Item `kkfppfhkjnenffibmnkphnbejidkmbkj` | Listing `apps/extension/store/listing.md`; reviewer login in vault "Chrome Web Store reviewer"; submitted 0.1.0 (pending review) |
| Edge Add-ons | Product `8bf15261-6f8c-40ad-a8e6-cf36378a68ab`, Store `0RDCKCP6QHRC`, CRX `danikigkoiofpcecjobopcgdflgcmchm` | Same zip as Chrome; listing `apps/extension/store/edge/listing.md`; Oliver's Partner Center account |
| Firefox AMO | id `casama@casama.ai` (slug `casama`, version 6740612) | Own build (`scripts/build-extension.sh firefox`); source zip verified reproducible; submitted 0.1.0 (pending review) |

Both Chrome and Edge ids must be in the server's `CHROME_EXTENSION_IDS` and in
`chromeExtensionIds` (`client/lib/core/chrome_extension.dart`). Both are.

### Snap Store

| Field | Value |
|---|---|
| Name | `casama` (approved 2026-11-18) |
| Package | `snap/snapcraft.yaml`, `scripts/package-snap.sh` (classic confinement, D-392) |
| Status | Classic request on forum.snapcraft.io not filed; nothing uploaded |

## Other Android stores

### What decides how hard each one is

Three things in the app tie it to Google Play and Google's services:

1. **Billing.** `client/lib/core/billing.dart` sends every Android build to Play Billing through
   RevenueCat. Play Billing only works on devices with the Play Store, and a store that has its own
   payment rules may reject an app that uses Google's.
2. **Push.** `firebase_messaging` (FCM) needs Google Play services. Huawei phones (since 2019) and
   Amazon Fire tablets don't have them, so pushes, call rings and approval alerts would not arrive.
3. **Google sign-in.** `google_sign_in` also needs Play services. Email, passkeys and Apple sign-in
   still work, so this is a smaller gap.

There is one more catch: users can't update across stores if the builds are signed with different
keys. Play re-signs with Google's app signing key, so an APK we sign ourselves can't update over a
Play install, and the reverse. Each store's users stay on that store.

### The change in the app that every non-Play store needs

Extend `CASAMA_DISTRIBUTION` (`client/lib/core/distribution.dart`, today `direct` or `appstore`) to
Android: `play` (default for `package-android.sh`), `galaxy`, `amazon`, `huawei`, `apk`, `foss`.
Then `purchaseChannels()` picks billing per distribution instead of per platform:

| Distribution | Billing | Push | Google sign-in |
|---|---|---|---|
| `play` | Play Billing (as today) | FCM | Yes |
| `galaxy` | Samsung IAP if Samsung requires it for subscriptions, otherwise web checkout. Check at sign-up | FCM (Galaxy phones have Play services) | Yes |
| `amazon` | Amazon IAP through RevenueCat (RevenueCat supports Amazon) | Amazon Device Messaging, or none at first | Hide |
| `huawei` | Huawei IAP (RevenueCat doesn't support it: own integration) | HMS Push Kit | Hide; Huawei ID optional |
| `apk` (GitHub, Aptoide, APKPure, Uptodown) | Web checkout (Dodo), as on desktop: no store fee, no store rule against it | FCM where Play services exist | Yes where available |
| `foss` (F-Droid) | Web checkout | None, or UnifiedPush | Hide |

That change is a code change with tests; it should get its own plan doc (`docs/ANDROID-STORES-PLAN.md`)
before any of the stores below that need it.

### The stores, in the order we recommend

| # | Store | Reach | Account and cost | Needs from the app | Effort |
|---|---|---|---|---|---|
| 1 | **GitHub Releases APK** (+ **Obtainium** reads it, **IzzyOnDroid** repo can index it) | Tech users, self-hosters, people without Play | None: our repo. IzzyOnDroid: a request issue on their GitLab; they flag Firebase and other non-free libraries as anti-features | `apk` distribution (web checkout); add the APK to `publish-desktop-release.sh`; a `GET_LINKS` entry | Small |
| 2 | **Samsung Galaxy Store** | Every Samsung phone; preinstalled | Samsung Seller Portal account, free; business info and tax forms. Review a few days | `galaxy` distribution; answer the Samsung IAP question first | Small to medium |
| 3 | **Aptoide / APKPure / Uptodown** | Large in emerging markets | Free developer consoles; APK upload | Same APK as #1 | Small each |
| 4 | **Amazon Appstore** | Fire tablets only: Amazon closed its Appstore on other Android devices in August 2025 | Amazon developer account, free | `amazon` distribution, Amazon IAP, no FCM | Medium, small payoff |
| 5 | **Huawei AppGallery** | Huawei phones outside China | Huawei developer account; identity check | `huawei` distribution: HMS Push, Huawei IAP, no Google sign-in | Large |
| 6 | **F-Droid** | Privacy-minded users | Free; they build from our source themselves | A `foss` build with no Firebase, RevenueCat, Google sign-in or Crashlytics | Large |
| — | **China stores** (Xiaomi, OPPO, vivo, Tencent, Baidu) | China | Need a Chinese entity and the CAC AIGC filing | — | Not doing |

Xiaomi GetApps, OPPO and vivo also run global stores; their reach outside China is mostly India and
Southeast Asia. Revisit after the stores above.

### Next steps

1. Oliver picks which stores to add (recommended now: 1, 2 and 3).
2. Write `docs/ANDROID-STORES-PLAN.md` for the `CASAMA_DISTRIBUTION` change and get it approved.
3. Oliver creates each store account (store accounts need him); save logins in Vaultwarden as
   "Casama · <store> developer account".
4. Fill the row below for each store as it goes.

## Per-store details to collect

Copy this block into the store's section when we start on it.

| Field | Value |
|---|---|
| Account / owner | |
| Vault item | |
| App id / package / listing URL | |
| Signing key (same as Play upload key, or its own) | |
| Billing | |
| Push | |
| Build command and `CASAMA_DISTRIBUTION` | |
| Content rating / privacy / data forms done | |
| Review time seen | |
| Status and date | |
| Fees (also in `docs/COSTS.md`) | |
