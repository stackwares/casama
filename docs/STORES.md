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

✅ = yes · 📝 = started, not finished · ⏳ = waiting for the store's review · ❌ = not yet ·
❓ = not checked · ➖ = not doing / doesn't apply.

"Account" means our developer or publisher account on that store exists and is ready to publish.
"Listing" means the store page (text, images, ratings, privacy forms) is filled in; 📝 is a draft.
"Submitted" means sent for the store's public release (or published, where there is no review).
"Testing" means a test channel has a build testers can install: TestFlight, Play internal / closed /
open testing, Snap beta and so on. "Live" means anyone can install it from the store's public page.

| Store | Platform | Account | Listing | Submitted | Testing | Live | Where it stands | Next step |
|---|---|:-:|:-:|:-:|:-:|:-:|---|---|
| **Web app** (app.casama.ai) | Browser | ➖ | ➖ | ✅ | ➖ | ✅ | Live | — |
| **Direct download** (GitHub Releases) | macOS | ✅ | ✅ | ✅ | ➖ | ✅ | v0.1.0 macOS DMG released 2026-11-21 on `stackwares/casama-releases` (Windows and Linux installers not uploaded yet) | Upload Windows and Linux v0.1.0 installers when built; each release with its Mac App Store twin |
| **Google Play** (phone, tablet) | Android | ✅ | ✅ | ❌ | ✅ | ❌ | Internal testing 0.1.0 (67) available. Closed testing (Alpha) 0.1.0 (49) approved and published 2026-11-20 (Console: track active, "Last published on November 20"). Production: track Inactive, 0.1.0 (67) is a draft with 0 countries, never sent for review (Console checked 2026-11-21) | Production when Oliver says |
| **Google Play** (Wear OS) | Wear OS | ✅ | ✅ | ❌ | ✅ | ❌ | Internal testing 0.1.0 (1000000067) available. `wear:production` 0.1.0 (1000000067) is a draft, never sent for review (no changes in review in the Console, 2026-11-21); `wear:beta` (open testing) empty. Wear has no closed track | Production with the phone release (AGENTS.md) |
| **App Store** (iPhone, iPad, Watch inside) | iOS | ✅ | ✅ | ❌ | ✅ | ❌ | TestFlight internal ("Casama team") has 0.1.0 (67). External "Public Beta" group: 67 ⏳ in Beta App Review since 2026-11-20; public link https://testflight.apple.com/join/n21dCaRu works once approved. App Store version 1.0 still "Prepare for Submission" | App Review when Oliver says |
| **Mac App Store** | macOS | ✅ | ✅ | ❌ | ✅ | ❌ | Same as iOS: TestFlight internal has 0.1.0 (67); "Public Beta" 67 ⏳ in Beta App Review since 2026-11-20 (same link). Mac version 1.0 "Prepare for Submission" | Ships together with the direct DMG |
| **Chrome Web Store** | Chrome, Brave, Arc, Vivaldi, Opera | ✅ | ✅ | ✅ | ➖ | ⏳ | 0.1.0 in review since 2026-11-21 (id `kkfppfhkjnenffibmnkphnbejidkmbkj`) | Wait |
| **Edge Add-ons** | Edge | ✅ | ✅ | ✅ | ➖ | ⏳ | 0.1.0 in review since 2026-11-21 (about 7 business days) | Wait |
| **Firefox Add-ons** (AMO) | Firefox | ✅ | ✅ | ✅ | ➖ | ⏳ | 0.1.0 in review since 2026-11-21 (`casama@casama.ai`) | Wait |
| **Snap Store** | Linux | ✅ | 📝 | ❌ | ❌ | ❌ | Name `casama` approved 2026-11-18; classic confinement request not filed | File classic request, first upload |
| **Microsoft Store** | Windows | ✅ | ✅ | ❌ | ❌ | ❌ | Account and listing set up in Partner Center (Oliver, 2026-11-21); no package uploaded. The Store build needs the Partner Center identity in `msix_config` (see "Microsoft Store" below) | Fill in the ids, build a Store MSIX, submit when Oliver says |
| **Homebrew Cask** (`stackwares/tap/casama`) | macOS | ✅ | ✅ | ✅ | ➖ | ✅ | Live on our own tap (`brew install --cask stackwares/tap/casama`, v0.1.0); official `Homebrew/homebrew-cask` planned once notable | Submit to `Homebrew/homebrew-cask` when notable |
| MacUpdate, Softpedia, Uptodown, Softonic, Mac Informer | macOS | ❌ | ❌ | ❌ | ➖ | ❌ | Planned (free listings) | See "Other Mac stores" |
| MacUpdater, Latest, Applite | macOS | ➖ | ➖ | ➖ | ➖ | ❌ | Nothing to submit: they read Homebrew or our Sparkle feed | Comes with the cask |
| Setapp | macOS | ❌ | ❌ | ❌ | ➖ | ❌ | Maybe: needs its own build and a pricing decision | See "Other Mac stores" |
| Flathub (Flatpak) | Linux | ➖ | ❌ | ❌ | ❌ | ❌ | Planned | See "Other Linux stores" |
| AUR (`casama-bin`) | Arch Linux | ❌ | ❌ | ❌ | ➖ | ❌ | Planned | See "Other Linux stores" |
| AppImage (+ AppImageHub) | Linux | ➖ | ❌ | ❌ | ➖ | ❌ | Maybe | See "Other Linux stores" |
| Own apt / dnf repository (.deb, .rpm) | Debian, Ubuntu, Fedora | ➖ | ❌ | ❌ | ➖ | ❌ | Maybe | See "Other Linux stores" |
| Fedora COPR, nixpkgs, Ubuntu PPA, elementary AppCenter | Linux | ➖ | ➖ | ➖ | ➖ | ➖ | Not now | See "Other Linux stores" |
| GitHub Releases APK (+ Obtainium, IzzyOnDroid) | Android | ✅ | ❌ | ❌ | ➖ | ❌ | Code and scripts ready (2026-11-21); no APK built yet | First `--distribution apk` build (needs Oliver's yes), then attach to the GitHub release |
| Samsung Galaxy Store | Android | ❌ | ❌ | ❌ | ❌ | ❌ | Code ready (`--distribution galaxy`, web checkout); no account | Oliver makes the Seller Portal account and confirms Samsung allows web checkout |
| Aptoide, APKPure, Uptodown | Android | ❌ | ❌ | ❌ | ➖ | ❌ | Maybe | See "Other Android stores" |
| Amazon Appstore | Fire tablets only | ❌ | ❌ | ❌ | ❌ | ❌ | Maybe | See "Other Android stores" |
| Huawei AppGallery | Android without Google | ❌ | ❌ | ❌ | ❌ | ❌ | Later | See "Other Android stores" |
| F-Droid | Android (FOSS only) | ➖ | ❌ | ❌ | ➖ | ❌ | Later | See "Other Android stores" |
| China mainland stores (Xiaomi, OPPO, vivo, Tencent, Baidu) | Android | ➖ | ➖ | ➖ | ➖ | ➖ | Not doing: China is off on purpose (no CAC AIGC filing) | — |

When a store's state changes, flip its marks in the same commit (AGENTS.md).

Notes on the Account and Listing marks:

- Snap: the publisher account exists (it owns the name `casama`); the store page fills from
  `snap/snapcraft.yaml` on the first upload, plus screenshots and links added in the snapcraft.io
  dashboard afterwards.
- Microsoft Store: account and listing confirmed by Oliver on 2026-11-21.
- Homebrew, Flathub, F-Droid, AppImageHub and our own package repositories have no account to make:
  they take a pull request from GitHub (Flathub, Homebrew, AppImageHub) or GitLab (F-Droid).
- The GitHub APK uses our GitHub org (✅); its "listing" is the release notes and the download page.

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
| Status (checked with `gplay`, 2026-11-21) | internal 0.1.0 (67) completed; alpha (closed testing) 0.1.0 (49) completed, promoted from internal 2026-11-20, approved and published 2026-11-20; production 0.1.0 (67) draft; wear:internal 0.1.0 (1000000067) completed; wear:production 0.1.0 (1000000067) draft; beta and wear:beta empty. Managed publishing off, so Alpha reaches testers on approval. Until the app is published, Play only allows drafts outside internal testing |

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
| TestFlight (checked with `asc`, 2026-11-21) | Internal group "Casama team": every build, iOS + Mac, latest 0.1.0 (67). External group "Public Beta" (public link https://testflight.apple.com/join/n21dCaRu, feedback on): build 67 iOS + Mac waiting for Beta App Review since 2026-11-20 |
| Status | App Store versions 1.0 (iOS, Mac) in "Prepare for Submission": never sent for App Review. Watch app ships inside the iOS record when built |

### Desktop direct download

| Field | Value |
|---|---|
| Where | GitHub Releases on `stackwares/casama-releases` (mirrored on `stackwares/casama`); download page casama.ai/download, links in `GET_LINKS` (`site/gallery-link.js`) |
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

### Microsoft Store

| Field | Value |
|---|---|
| Account | Oliver's Microsoft Partner Center account (the same one that publishes the Edge add-on) |
| Listing | Set up in Partner Center (Oliver, 2026-11-21) |
| Store ID / Product ID | _to fill in from Partner Center → Product identity_ |
| Package identity | _to fill in: Package/Identity/Name, Package/Identity/Publisher (`CN=…`), Publisher display name_ |
| Package | `scripts/package-windows.ps1` (`msix` package, config `msix_config` in `client/pubspec.yaml`) |
| Status | No package uploaded |

The MSIX we ship on GitHub has `store: false` and our own identity (`ai.casama.app`, publisher
"Casama", signed with `MSIX_CERT`). A Store upload instead needs `store: true` and the exact
identity name, publisher and publisher display name from Partner Center's Product identity page,
and is left unsigned: Microsoft signs it. Store installs update through the Store, so the Store build
should skip WinSparkle. Both builds come from the same commit and version.

### Snap Store

| Field | Value |
|---|---|
| Name | `casama` (approved 2026-11-18) |
| Package | `snap/snapcraft.yaml` (base core24, grade stable), `scripts/package-snap.sh` (classic confinement, D-392: the computer companion, Docker and quick ask need the host) |
| CI | `.github/workflows/desktop.yml` builds the `.snap` next to the Linux tarball as an artifact (x64 and arm64) |
| Upload | `snapcraft upload --release=<channel> dist/casama_*.snap`; Snapcraft login in Vaultwarden once made |
| Status | Classic request on forum.snapcraft.io not filed (a classic snap can't be published until Canonical approves it, usually a week or two); nothing uploaded |

## Other Mac stores

Everything here distributes the **direct download**: the notarized Developer ID DMG from
`scripts/package-macos.sh`, which updates itself with Sparkle (feed `appcast-macos.xml`, published by
`scripts/publish-desktop-release.sh`). Only Setapp needs a build of its own. None of them replaces
the Mac App Store listing; both ship together as AGENTS.md says.

| # | Store | Reach | What it takes | Effort |
|---|---|---|---|---|
| 1 | **Homebrew Cask** | Developers and power users (`brew install --cask casama`); also feeds Applite, Latest and MacUpdater | A cask file in a pull request to `Homebrew/homebrew-cask`: the DMG URL on GitHub Releases, sha256, `auto_updates true` (Sparkle updates it), `livecheck` on the appcast, `zap` paths for `~/Library` cleanup. Homebrew rejects casks for apps that aren't yet "notable" (GitHub stars, forks, watchers) and self-submitted ones get a closer look. Fallback until then: our own tap `stackwares/homebrew-tap` (`brew install --cask stackwares/tap/casama`), which CI can bump on each release. Free | Small |
| 2 | **Setapp** | About a million paying Mac users; curated, one subscription for all apps | Apply as a developer (review of the app and the company). Setapp apps can't show their own paywall or take payments: Setapp pays us by usage (about 70% of the share for usage, more for users we refer). Needs a Setapp build (`CASAMA_DISTRIBUTION=setapp`): Setapp's framework for licensing, its own bundle id (`ai.casama.app-setapp`), its own update channel (no Sparkle), and a decision on what Setapp members get from Casama Cloud (which plan, how much usage) since our costs are per use. Setapp also lists iOS apps in the EU | Large, and a pricing decision for Oliver |
| 3 | **MacUpdate** | Long-running Mac download directory | Free developer account; listing with the DMG link, screenshots, description from `client/store/`. Keeps the version current if we give it the appcast | Small |
| 4 | **Softpedia, Uptodown, Softonic, Mac Informer** | Download directories with search traffic | Free submission forms; some find the app themselves. Uptodown's developer account also covers Android and Windows | Small each |
| 5 | **MacUpdater, Latest, Applite** | Update and install tools | Nothing to submit: they read Homebrew casks or Sparkle feeds. They pick Casama up once the cask exists | None |
| — | MacPorts | Developers | Builds from source; Homebrew covers the same people | Not now |
| — | Paid bundles (BundleHunt, StackSocial) | Deal hunters | Sell lifetime licences at a deep discount; doesn't fit a per-use cloud service | Not doing |

Next steps for Mac, in order: the Homebrew cask (or our own tap until Casama is notable enough),
then MacUpdate and the free directories; Setapp only after Oliver decides what Setapp members get.

## Other Linux stores

Where Linux users find apps: Ubuntu's App Center shows the Snap Store; GNOME Software, KDE Discover,
Pop!_Shop, Linux Mint and Fedora show Flathub. Snap plus Flathub covers almost every desktop. The
rest are for people who install from the terminal.

All of them repackage the same Flutter bundle `scripts/package-linux.sh` already makes
(`casama-<version>-linux-<arch>.tar.gz`), so most are packaging work, not app work. Flathub is the
exception: its sandbox can't reach the host the way the snap's classic confinement does.

| # | Store | Reach | What it takes | Effort |
|---|---|---|---|---|
| 1 | **Flathub** | Default store on Fedora, Mint, Pop!_OS, elementary, Steam Deck; shown in GNOME Software and KDE Discover | A manifest `ai.casama.app.yml` in a pull request to `flathub/flathub`, plus AppStream metainfo (`ai.casama.app.metainfo.xml`: description, screenshots, release notes, OARS rating). It may use our prebuilt tarball from GitHub Releases instead of building from source. Flathub's reviewers refuse broad host access (`--talk-name=org.freedesktop.Flatpak`, the Docker socket, `--filesystem=host`), so the Flatpak build turns those features off the way the Mac App Store build does: a `CASAMA_DISTRIBUTION=flatpak` value. Verified-publisher badge: a token at `https://casama.ai/.well-known/org.flathub.VerifiedApps.txt`. Free | Medium |
| 2 | **AUR** (`casama-bin`) | Arch, Manjaro, EndeavourOS | A `PKGBUILD` that downloads the release tarball and checks its sha256, and a `.desktop` file. An AUR account with an SSH key (vault). Each release bumps `pkgver` and the checksum, which CI can do. Free | Small |
| 3 | **AppImage** (+ AppImageHub) | Any distro, no install | Wrap the bundle with `appimagetool`, attach to GitHub Releases next to the tarball; AppImageHub listing is a pull request to `AppImage/appimage.github.io`. Can self-update with zsync. Free | Small |
| 4 | **Own apt and dnf repository** | Debian, Ubuntu, Fedora users who want `apt upgrade` updates | Build `.deb` and `.rpm` from the bundle (`nfpm` or `fpm`), sign with a repository GPG key (vault), host on R2 behind `pkg.casama.ai`, or on Cloudsmith's free open-source plan. Install instructions on casama.ai/download | Medium |
| — | Fedora COPR | Fedora | Builds from source in Fedora's own build system; a Flutter build there is hard. Flathub reaches Fedora anyway | Not now |
| — | nixpkgs | NixOS | Community usually packages popular apps itself; a pull request to nixpkgs is possible later | Not now |
| — | Ubuntu PPA | Ubuntu | Launchpad builds from source only, with no network during the build; doesn't fit Flutter. The snap covers Ubuntu | Not now |
| — | elementary AppCenter | elementary OS | Curated, wants apps made for elementary's own design; Flathub reaches elementary users anyway | Not now |

Next steps for Linux, in order: file the snap's classic request and make the first upload (Oliver's
yes); then AUR and AppImage (small, packaging only); then Flathub, which needs the `flatpak`
distribution value in the app and its own small plan.

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

**Built 2026-11-21** (plan: `docs/ANDROID-STORES-PLAN.md`): `play`, `apk` and `galaxy` work in
`client/lib/core/distribution.dart`, billing, review prompt and telemetry, with tests. Build one with
`scripts/package-android.sh apk --distribution apk` (or `galaxy`); it writes
`dist/casama-<version>-android-<abi>.apk`, and `scripts/publish-desktop-release.sh` attaches those to
the GitHub release. `amazon`, `huawei` and `foss` are not built. No APK has been built or uploaded yet.

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

1. ~~Oliver picks which stores to add~~ Started on 1, 2 and 3 (2026-11-21).
2. ~~Plan and `CASAMA_DISTRIBUTION` change~~ Built; first APK build needs Oliver's yes (Flutter build).
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
