# Casama app

The Flutter app for iOS, Android, macOS, Windows, Linux and the web. It talks to a Casama server
through the generated Dart SDK (`dart/casama_sdk`) and Supabase (sign-in and live updates).

## Run it

Start a local server first (see [CONTRIBUTING.md](../CONTRIBUTING.md#development-setup)), then:

```sh
flutter pub get
flutter run -d macos --dart-define=CASAMA_API_URL=http://localhost:8787
```

Any Flutter device works: `-d chrome`, an iOS simulator, an Android emulator, `-d windows` or
`-d linux`. The app reads the Supabase address and key from the server, so the server address is
the only setting. People can also change it at sign-in (**More options** → **Server**).

## Build settings

Pass these with `--dart-define=NAME=value`. All are optional.

| Setting | What it does |
| --- | --- |
| `CASAMA_API_URL` | The default server address (default `http://localhost:8787`; empty on web means the page's own origin) |
| `CASAMA_DISTRIBUTION` | `direct` (default; a signed download with every feature) or `appstore` (the sandboxed Mac App Store build, which turns off features that reach outside the app) |
| `CASAMA_HELP_URL` | Where **Help** in the macOS menu bar points (default: the docs on GitHub) |
| `CASAMA_SELFHOST_BUNDLE` | Where **Run Casama on this computer** downloads the server from |
| `SENTRY_DSN`, `POSTHOG_API_KEY`, `POSTHOG_HOST`, `ERROR_REPORTING` | Error reporting (off unless set) |
| `FIREBASE_*` | Push notifications for official builds (see `config/firebase.json`) |

## Layout

| Path | What it is |
| --- | --- |
| `lib/core/` | App-wide services: the `Backend` interface and its Supabase implementation, routing, providers, push, voice, the offline cache, shortcuts |
| `lib/features/` | One folder per feature (chat, bots, computer, routines, settings and so on) |
| `lib/ui/` | Shared widgets: sheets, cards, buttons, the page layout |
| `lib/theme/` | Colors, type, spacing and motion tokens |
| `lib/l10n/` | `app_en.arb`, the source of every string in the app; run `flutter gen-l10n` after editing |
| `test/` | Widget tests against a fake backend (`test/fake_backend.dart`) |
| `integration_test/` | End-to-end tests against a running local server (`scripts/e2e-app.sh`) |

## Checks

```sh
flutter gen-l10n
flutter analyze
flutter test
```

`scripts/e2e-app.sh [device]` runs the end-to-end tests against a local server with recorded model
responses. Format only the files you change (`dart format <files>`).

## Conventions

- State with Riverpod (no code generation); navigation with go_router.
- Every user-facing string goes in `lib/l10n/app_en.arb`.
- The app stays fully native: no embedded web views.
- New screens use the shared page layout and form components in `lib/ui/`.
