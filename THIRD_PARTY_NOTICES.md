# Third-Party Notices

Casama depends on the following third-party software, each used under its own license.
Update this file in the same pull request that adds or removes a dependency.

## Node.js packages

| Package                                 | Used in                                               | License           |
| --------------------------------------- | ----------------------------------------------------- | ----------------- |
| @biomejs/biome                          | casama (tooling)                                      | MIT OR Apache-2.0 |
| @dbos-inc/dbos-sdk                      | @casama/server (runtime)                              | MIT               |
| @modelcontextprotocol/sdk               | @casama/agent (runtime)                               | MIT               |
| pdfjs-dist                              | @casama/agent (runtime), @casama/extension (runtime) | Apache-2.0        |
| pdf-lib                                 | @casama/agent (runtime)                               | MIT               |
| sharp                                   | @casama/agent (runtime)                               | Apache-2.0        |
| @img/sharp-libvips-* (libvips, bundled by sharp) | @casama/agent (runtime)                      | LGPL-3.0-or-later |
| qrcode                                  | @casama/agent (runtime)                               | MIT               |
| jsqr                                    | @casama/agent (runtime)                               | Apache-2.0        |
| pdfmake (bundles the Roboto font)       | @casama/agent (runtime)                               | MIT; Roboto Apache-2.0 |
| docx                                    | @casama/agent (runtime)                               | MIT               |
| marked                                  | @casama/agent (runtime)                               | MIT               |
| postal-mime                           | @casama/agent (runtime)                               | MIT-0             |
| superjson                               | @casama/server (runtime)                              | MIT               |
| @hono/node-server                       | @casama/server (runtime)                              | MIT               |
| @hono/zod-openapi                       | @casama/contracts (runtime), @casama/server (runtime) | MIT               |
| @openapitools/openapi-generator-cli     | @casama/contracts (tooling)                           | Apache-2.0        |
| @resvg/resvg-js                         | casama (tooling: gallery share images)                | MPL-2.0           |
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
| tldts                                   | @casama/domain (runtime: the Public Suffix List)      | MIT               |
| turbo                                   | casama (tooling)                                      | MIT               |
| typescript                              | casama (tooling)                                      | Apache-2.0        |
| undici                                  | @casama/agent (runtime)                               | MIT               |
| werift                                  | @casama/sandbox (tests)                               | MIT               |
| vitest                                  | casama (tooling)                                      | MIT               |
| zod                                     | @casama/contracts (runtime), @casama/server (runtime) | MIT               |
| @playwright/test                        | @casama/extension (end-to-end tests)                  | Apache-2.0        |
| @types/chrome                           | @casama/extension (tooling)                           | MIT               |
| vite                                    | @casama/extension (build)                             | MIT               |
| openapi-fetch                           | @casama/client (runtime), @casama/extension (runtime) | MIT               |

## Dart packages

| Package                                                               | Used in                            | License                       |
| --------------------------------------------------------------------- | ---------------------------------- | ----------------------------- |
| args                                                                  | casama_cli                         | BSD-3-Clause                  |
| dio                                                                   | casama_api, casama_sdk, casama_cli | MIT                           |
| http                                                                  | casama_sdk, casama_cli             | BSD-3-Clause                  |
| qr                                                                    | casama_cli (sign-in code in a terminal) | BSD-3-Clause             |
| path                                                                  | casama_cli                         | BSD-3-Clause                  |
| pinenacl                                                              | casama_cli (gallery signature check) | MIT                         |
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
| file_picker_linux, file_selector_platform_interface                   | client (Linux file dialogs)        | MIT; BSD-3-Clause             |
| share_plus, web_socket_channel                                        | client                             | BSD-3-Clause                  |
| sentry_flutter                                                        | client                             | MIT                           |
| firebase_core, firebase_messaging                                     | client                             | BSD-3-Clause                  |
| flutter_webrtc                                                        | client                             | MIT                           |
| flutter_callkit_incoming                                              | client (phone calls)               | MIT                           |
| sherpa_onnx (and the downloaded sherpa-onnx GigaSpeech keyword model) | client (wake word)                 | Apache-2.0                    |
| archive                                                               | client (wake word model unpacking) | MIT                           |
| crypto                                                                | client, casama_sdk, casama_cli, computerd | BSD-3-Clause                  |
| posthog_flutter                                                       | client                             | MIT                           |
| record, just_audio                                                    | client (voice)                     | BSD-3-Clause, MIT             |
| flutter_soloud (with the SoLoud engine)                               | client (live-call audio playback)  | MIT, zlib                     |
| flutter_secure_storage                                                | client (companion, app lock)       | BSD-3-Clause                  |
| local_auth, local_auth_android, local_auth_darwin, local_auth_windows | client (app lock)                  | BSD-3-Clause                  |
| window_manager, tray_manager, hotkey_manager                          | client (desktop)                   | MIT                           |
| home_widget, receive_sharing_intent                                   | client (mobile extras)             | BSD-3-Clause, Apache-2.0      |
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
| socat                                  | TURN relay image: forwards to the relay outside (Casama Link) | GPL-2.0 (system package, unmodified) |
| cloudflared (Cloudflare's official image, pinned) | connector image: holds a server's tunnel open (Casama Link) | Apache-2.0 |
| SeaweedFS (optional compose profile)   | self-hosted S3 storage         | Apache-2.0                                     |
| X.Org server, Openbox, Mousepad        | desktop image                  | MIT/X11, GPL-2.0 (system packages, unmodified) |
| pgvector                               | database extension             | PostgreSQL License                             |
| pgTAP                                  | database tests                 | PostgreSQL License                             |
| Supabase (self-hosted services)        | platform                       | Apache-2.0 / MIT (per component)               |
| OpenAPI Generator (dart-dio templates) | code generation                | Apache-2.0                                     |
| Lucide icon data (lucide-static 1.63.0) | gallery doodle `glyphs` (`gallery/assets/lucide`) | ISC                                     |

## Fonts

| Font   | Used in                                   | License                                      |
| ------ | ----------------------------------------- | -------------------------------------------- |
| Nunito | client (headlines; `client/assets/fonts`) | SIL Open Font License 1.1 (`Nunito-OFL.txt`) |
| Noto Sans CJK | server image (PDFs bots make; Debian `fonts-noto-cjk`) | SIL Open Font License 1.1 |
| Roboto | @casama/agent (PDFs bots make; shipped in pdfmake) | Apache-2.0 |
