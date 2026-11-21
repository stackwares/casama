# The phone browser: what a store release needs

For the release that first contains the phone browser (docs/PHONE-BROWSER-PLAN.md §6, Stage 2).
Until that release, public store builds don't contain it (`scripts/app-browser-switch.sh off`).
Nothing here is submitted without Oliver's yes.

Both stores forbid features that ship hidden and are switched on later (Apple 2.5.19, Google Play
"Deceptive Behavior"). So the release that carries it must describe it: to the reviewer, in the
listing, in the privacy answers and on the privacy page. Check each box before submitting.

## Checklist

- [ ] The build was made with the switch on (all three parts: the Dart define, the iOS flag, the
      Android marker). `scripts/app-browser-switch.sh status` says `on`.
- [ ] The server's stage lets the reviewer's account in: stage `testers` with the reviewer's user
      id, or stage `on` for that system.
- [ ] Review notes below are pasted into App Store Connect ("Notes for Review") and Play Console
      ("App access" instructions).
- [ ] The reviewer account has a bot allowed on the phone browser and one site added, so the
      feature can be reached in a minute.
- [ ] App Store "App Privacy": **Browsing History** added (linked to the person, App
      Functionality, not used for tracking). `client/ios/Runner/PrivacyInfo.xcprivacy` gets the
      matching `NSPrivacyCollectedDataTypeBrowsingHistory` entry in the same commit as the
      switch-on, and `client/store/README.md`'s table is updated.
- [ ] Play "Data safety": **Web browsing history** collected, not shared, for App functionality;
      data is encrypted in transit; people can ask for deletion.
- [ ] The privacy page has the section in `privacy-section.md`, with its date set.
- [ ] The listing's "what's new" and description carry the lines in `listing.md`.
- [ ] `docs-site/guide/phone-browser.md` is published from `guide.md`.
- [ ] `docs/STORES.md` rows are updated when each store answers.

## Review notes (paste, then fill in the account)

> **New in this version: a browser your bot can use on this phone.**
>
> Casama bots can already browse the web on their own cloud computer. This version adds a small
> browser inside the app that a bot can use on the phone itself, while the person watches. It is
> built on WebKit (WKWebView) on iOS and Android System WebView on Android.
>
> **Where to find it:** Settings → Device Connections → Browser on This Phone. Turning it on shows
> a consent screen first. The person chooses which bots may use it.
>
> **How to try it (about one minute):**
> 1. Sign in with the review account below. The feature is already on for it.
> 2. Open the chat with the bot "Shopper" and send: "Open example.com on my phone and tell me the
>    page's heading."
> 3. A card appears in the chat showing the page. Tap it to see the full browser, with Stop and
>    Take Over. The first visit to a site asks: Once, Always or Never.
>
> **What it does and doesn't do:**
> - It works only while that chat is open on the phone's screen. Leaving the chat or the app stops
>   it. It never runs in the background.
> - The person sees every step and can stop the bot by touching the page.
> - Steps that send, post, delete, share or sign in ask the person first, each time. Purchases and
>   password changes are never done by a bot: they are handed to the person.
> - A bot never types or reads a password, a card number or a one-time code.
> - Banking, health, password manager and government ID sites are off unless the person switches
>   that kind on, and then every visit asks.
> - Sign-ins and cookies stay on the phone, in a store used only by this browser. They are not
>   sent to our servers.
> - What a bot reads on a page (its text, or a picture of it) is sent to our server and to the AI
>   model the bot uses, so the bot can act on it. The consent screen says so, and our privacy
>   policy has a section on it.
> - The script that reads pages ships inside the app. No code is downloaded.
>
> Review account: (email and password from the vault item "App review account")

## Decisions already made (plan §13)

No disguise as Safari or Chrome; no passkeys on other sites; one page, no tabs; iPhone and iPad on
iOS 17 or later; Android phones whose WebView supports profiles and isolated script worlds.
