# Store listings

The text of Casama's App Store and Google Play listings. These files are the source: change them
here, then apply them with `asc` and `gplay`. What is written here was applied on 2026-11-18;
nothing has been sent for review.

| | App Store Connect | Google Play |
|---|---|---|
| Record | "Casama: AI Teammates", app id `6833509960`, iOS 1.0 and macOS 1.0 | `ai.casama.app`, draft |
| Name / title | `app_store/en-US/name.txt` | `google_play/en-US/title.txt` |
| Subtitle / short description | `app_store/en-US/subtitle.txt` (30) | `google_play/en-US/short_description.txt` (80) |
| Description | `app_store/en-US/description.txt` (iPhone and iPad), `app_store/en-US/mac/description.txt` | `google_play/en-US/full_description.txt` |
| Keywords | `app_store/en-US/keywords.txt` (100, both platforms) | none |
| Promotional text | `app_store/en-US/promotional_text.txt`, `app_store/en-US/mac/promotional_text.txt` (170) | none |
| Review notes | `app_store/review_notes.txt` | Sign-in details in Play Console → App content |

## What is set in the stores

- **URLs.** Privacy policy https://casama.ai/privacy, privacy choices and Play's "Delete account
  URL" https://casama.ai/delete-account, support https://casama.ai/contact, marketing
  https://casama.ai. Play contact: support@casama.ai. Support and marketing URLs belong to each App
  Store version, so a new version needs them again.
- **Category.** App Store: Productivity, then Business. Play: Productivity, with the tags Personal
  assistant, Productivity and Business.
- **Age rating (App Store).** Answered for an open-ended AI assistant: unrestricted web access (a
  bot's browser can be taken over), user-generated content, messaging and chat, health or wellness
  topics, and infrequent or mild medical information, profanity, mature themes and alcohol, tobacco
  or drug references. No advertising, gambling or contests. Apple rates that 17+ (16+ on the newer
  scale). Play's target audience is 18 and older.
- **Content rights.** The app shows third-party content (web pages, gallery items, photos).
- **Price and availability (App Store).** Free, every territory except China mainland, where
  generative AI apps need a licence. Release is manual, so approval alone doesn't publish it.
- **Copyright.** 2026 Stackwares.
- **App Review.** The demo account `review@casama.ai` exists on Casama Cloud (email and password,
  no two-step, Free plan, one workspace with the bot Casama). Its password is in Vaultwarden as
  "Casama · store review account (review@casama.ai)". Play's sign-in details use the same account.

## Rules for the text

- Only claim what the shipped apps do. Features marked "Coming soon" on casama.ai stay out.
- The App Store text doesn't name other phone platforms, and no listing uses prices, "best" or
  rankings. The subscription paragraph and the Terms and Privacy links at the end are required.
- The Mac App Store build is sandboxed: it can't lend this Mac to bots, run a local server or read
  the front app for quick ask, so the Mac text doesn't mention them.
- Upload the Mac App Store build only from `scripts/package-macos-appstore.sh`. It signs with
  `macos/Runner/AppStore.entitlements` (sandboxed; Xcode's own Release config is not), adds push
  from the profile, and builds without Sparkle (auto_updater is swapped for
  `tool/appstore/auto_updater_stub`). An archive uploaded straight from Xcode would be refused.
- Before sending for review (preflight 2026-11-19): attach a screen recording of a real iPhone and
  Mac run to the review notes; keep `review@casama.ai` on Pro with extra credits (the notes say
  so); the watch and iPhone Duo screenshots need a build that contains the watch app and Duo
  layout, otherwise remove them.

## Applying changes

```sh
# App Store Connect (asc reads its key from the environment; the keychain lookup hangs)
export ASC_KEY_ID=CC7KG77GYT ASC_ISSUER_ID=69a6de87-3ae7-47e3-e053-5b8c7c11a4d1 \
  ASC_PRIVATE_KEY_PATH=~/private_keys/AuthKey_CC7KG77GYT.p8
asc metadata pull --app 6833509960 --version 1.0 --platform IOS --dir /tmp/asc-ios   # then edit the JSON
asc metadata validate --dir /tmp/asc-ios --subscription-app
asc metadata push --app 6833509960 --version 1.0 --platform IOS --dir /tmp/asc-ios --dry-run

# Google Play
E=$(gplay edits create --package ai.casama.app | jq -r .id)
gplay listings update --package ai.casama.app --edit "$E" --locale en-US \
  --title "$(cat google_play/en-US/title.txt)" \
  --short-description "$(cat google_play/en-US/short_description.txt)" \
  --full-description "$(cat google_play/en-US/full_description.txt)"
gplay edits commit --package ai.casama.app --edit "$E"
```

Play's Data safety form and app category are changed in Play Console, not through the API: the
Data safety API replaces the whole form.

## Crash reports to Firebase Crashlytics (D-416)

From the build after 2026-11-19 the iOS, Android and macOS apps also send crash reports to Firebase
Crashlytics (opt-out with the same Settings → Privacy switch; not linked to the account). Before
that build goes out for review, check the store forms still match:

- **App Store, App Privacy:** Crash Data and Performance Data are already declared (App
  Functionality, Analytics). Crashlytics adds Other Diagnostic Data (free memory, disk, battery
  state) and a per-install Crashlytics id: add **Other Diagnostic Data** (App Functionality, not
  linked, no tracking) if it isn't listed. The Firebase SDK ships its own privacy manifest, so
  `PrivacyInfo.xcprivacy` needs no change.
- **Google Play, Data safety:** App info and performance → **Crash logs** and **Diagnostics**
  (collected, not shared, optional for the user, purpose App functionality and Analytics). **Device
  or other IDs** is needed for the Crashlytics installation id if it isn't already declared for
  Firebase Cloud Messaging. Google is a service provider here, so it is not "shared".
- The privacy policy (casama.ai/privacy) names Firebase Crashlytics in the processors table.

Since D-417 an app runs only one crash reporter at a time (Sentry, Crashlytics or PostHog), switched
remotely. The answers above don't change: declare what any of them may collect, because the owner
can switch without a store review.

**Checked 2026-11-19:** App Store App Privacy now lists Other Diagnostic Data (App Functionality
and Analytics, linked like every other type there) and was published again (24 entries). Play Data
safety already declared Crash logs, Diagnostics and Device or other IDs as collected (and crash
logs and diagnostics as shared), so it needed no change.

## Still open

- Screenshots (Play phone 1080x1920, tablets 1440x2560) and the review screenshots for the
  subscriptions: made in `~/Desktop/Projects/Marketing/casama`. Play's store listing is complete
  apart from its phone screenshots (2 to 8 needed).
- A build attached to each App Store version. TestFlight builds are 0.1.0 and the store versions
  say 1.0, so one of the two has to change first.
- Google Play trader status (due February 2027). The Play account is a personal account whose
  legal name and address come from its owner's payments profile; declaring "trader" shows those
  publicly in the EU, for all 16 apps on the account. The owner decides.

## Done

- Play listing graphics, 2026-11-19: icon `google_play/icon-512.png` (the app icon with its black
  rounded corners filled in plum, since Play rounds the corners itself), feature graphic
  `Marketing/casama/art/play-feature-graphic.png`, video https://www.youtube.com/watch?v=E9x6E04ueoY.
- App Privacy published 2026-11-18 (18 data types, all linked to the user, no tracking).
- App Store Digital Services Act: the account is already declared a trader for this app.
- China mainland: excluded from the App Store (iOS and Mac share one availability; 174 of 175
  territories, new territories on). It needs a generative AI filing and an ICP licence there;
  Google Play doesn't serve China mainland.
