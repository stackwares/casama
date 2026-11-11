# Third-Party Notices

Casama depends on the following third-party software, each used under its own license.
Update this file in the same pull request that adds or removes a dependency.

## Node.js packages

| Package                                 | Used in                                               | License           |
| --------------------------------------- | ----------------------------------------------------- | ----------------- |
| @biomejs/biome                          | casama (tooling)                                      | MIT OR Apache-2.0 |
| @dbos-inc/dbos-sdk                      | @casama/server (runtime)                              | MIT               |
| @modelcontextprotocol/sdk               | @casama/agent (runtime)                               | MIT               |
| @hono/node-server                       | @casama/server (runtime)                              | MIT               |
| @hono/zod-openapi                       | @casama/contracts (runtime), @casama/server (runtime) | MIT               |
| @openapitools/openapi-generator-cli     | @casama/contracts (tooling)                           | Apache-2.0        |
| @opentelemetry/api                      | @casama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/exporter-trace-otlp-http | @casama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/resources                | @casama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/sdk-node                 | @casama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/semantic-conventions     | @casama/observability (runtime)                       | Apache-2.0        |
| @scalar/hono-api-reference              | @casama/server (runtime)                              | MIT               |
| @sentry/node                            | @casama/observability (runtime)                       | MIT               |
| @types/node                             | casama (tooling)                                      | MIT               |
| cron-parser                             | @casama/domain (runtime)                              | MIT               |
| drizzle-kit                             | @casama/db (tooling)                                  | MIT               |
| drizzle-orm                             | @casama/db (runtime), @casama/server (runtime)        | Apache-2.0        |
| hono                                    | @casama/contracts (runtime), @casama/server (runtime) | MIT               |
| jose                                    | @casama/server (runtime)                              | MIT               |
| postgres                                | @casama/db (runtime), @casama/server (runtime)        | Unlicense         |
| posthog-node                            | @casama/observability (runtime)                       | MIT               |
| turbo                                   | casama (tooling)                                      | MIT               |
| typescript                              | casama (tooling)                                      | Apache-2.0        |
| undici                                  | @casama/agent (runtime)                               | MIT               |
| werift                                  | @casama/sandbox (tests)                               | MIT               |
| vitest                                  | casama (tooling)                                      | MIT               |
| zod                                     | @casama/contracts (runtime), @casama/server (runtime) | MIT               |

## Dart packages

| Package                                                               | Used in                            | License                       |
| --------------------------------------------------------------------- | ---------------------------------- | ----------------------------- |
| args                                                                  | casama_cli                         | BSD-3-Clause                  |
| dio                                                                   | casama_api, casama_sdk, casama_cli | MIT                           |
| http                                                                  | casama_sdk                         | BSD-3-Clause                  |
| path                                                                  | casama_cli                         | BSD-3-Clause                  |
| json_annotation, json_serializable                                    | casama_api                         | BSD-3-Clause                  |
| copy_with_extension, copy_with_extension_gen                          | casama_api                         | MIT                           |
| build_runner                                                          | casama_api (tooling)               | BSD-3-Clause                  |
| test, lints                                                           | all Dart packages (tooling)        | BSD-3-Clause                  |
| supabase_flutter                                                      | client                             | MIT                           |
| flutter_riverpod                                                      | client                             | MIT                           |
| flex_color_scheme                                                     | client                             | BSD-3-Clause                  |
| go_router, flutter_localizations, intl                                | client                             | BSD-3-Clause                  |
| xterm                                                                 | client                             | MIT                           |
| markdown_widget                                                       | client                             | MIT                           |
| file_picker                                                           | client                             | MIT                           |
| share_plus, web_socket_channel                                        | client                             | BSD-3-Clause                  |
| sentry_flutter                                                        | client                             | MIT                           |
| firebase_core, firebase_messaging                                     | client                             | BSD-3-Clause                  |
| flutter_webrtc                                                        | client                             | MIT                           |
| flutter_callkit_incoming                                              | client (phone calls)               | MIT                           |
| sherpa_onnx (and the downloaded sherpa-onnx GigaSpeech keyword model) | client (wake word)                 | Apache-2.0                    |
| archive                                                               | client (wake word model unpacking) | MIT                           |
| crypto                                                                | client                             | BSD-3-Clause                  |
| posthog_flutter                                                       | client                             | MIT                           |
| record, just_audio                                                    | client (voice)                     | BSD-3-Clause, MIT             |
| flutter_soloud (with the SoLoud engine)                               | client (live-call audio playback)  | MIT, zlib                     |
| flutter_secure_storage                                                | client (companion)                 | BSD-3-Clause                  |
| window_manager, tray_manager, hotkey_manager                          | client (desktop)                   | MIT                           |
| home_widget, live_activities, receive_sharing_intent                  | client (mobile extras)             | BSD-3-Clause, MIT, Apache-2.0 |
| in_app_purchase, in_app_purchase_android, url_launcher                | client (billing)                   | BSD-3-Clause                  |
| mocktail                                                              | client (tooling)                   | MIT                           |
| haptic_feedback                                                       | client                             | BSD-3-Clause                  |
| stupid_simple_sheet, motor, scroll_drag_detector                      | client                             | MIT                           |
| phone_numbers_parser                                                  | client (phone number formatting)   | MIT                           |
| passkeys (Corbado; web bundle with @github/webauthn-json vendored)    | client (passkey sign-in)           | MIT                           |

## Other software

| Software                               | Role                           | License                                        |
| -------------------------------------- | ------------------------------ | ---------------------------------------------- |
| PostgreSQL                             | database                       | PostgreSQL License                             |
| Apple Root CA - G3 certificate         | App Store signature checks     | Public certificate from apple.com              |
| Neko (m1k1o/neko), built from source   | desktop image: WebRTC streamer | Apache-2.0                                     |
| coturn                                 | TURN relay image               | BSD-3-Clause                                   |
| SeaweedFS (optional compose profile)   | self-hosted S3 storage         | Apache-2.0                                     |
| X.Org server, Openbox, Mousepad        | desktop image                  | MIT/X11, GPL-2.0 (system packages, unmodified) |
| pgvector                               | database extension             | PostgreSQL License                             |
| pgTAP                                  | database tests                 | PostgreSQL License                             |
| Supabase (self-hosted services)        | platform                       | Apache-2.0 / MIT (per component)               |
| OpenAPI Generator (dart-dio templates) | code generation                | Apache-2.0                                     |

## Fonts

| Font   | Used in                                   | License                                      |
| ------ | ----------------------------------------- | -------------------------------------------- |
| Nunito | client (headlines; `client/assets/fonts`) | SIL Open Font License 1.1 (`Nunito-OFL.txt`) |
