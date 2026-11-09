# Third-Party Notices

Kasama depends on the following third-party software, each used under its own license.
Update this file in the same pull request that adds or removes a dependency.

## Node.js packages

| Package                                 | Used in                                               | License           |
| --------------------------------------- | ----------------------------------------------------- | ----------------- |
| @biomejs/biome                          | kasama (tooling)                                      | MIT OR Apache-2.0 |
| @dbos-inc/dbos-sdk                      | @kasama/server (runtime)                              | MIT               |
| @modelcontextprotocol/sdk               | @kasama/agent (runtime)                               | MIT               |
| @hono/node-server                       | @kasama/server (runtime)                              | MIT               |
| @hono/zod-openapi                       | @kasama/contracts (runtime), @kasama/server (runtime) | MIT               |
| @openapitools/openapi-generator-cli     | @kasama/contracts (tooling)                           | Apache-2.0        |
| @opentelemetry/api                      | @kasama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/exporter-trace-otlp-http | @kasama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/resources                | @kasama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/sdk-node                 | @kasama/observability (runtime)                       | Apache-2.0        |
| @opentelemetry/semantic-conventions     | @kasama/observability (runtime)                       | Apache-2.0        |
| @scalar/hono-api-reference              | @kasama/server (runtime)                              | MIT               |
| @sentry/node                            | @kasama/observability (runtime)                       | MIT               |
| @types/node                             | kasama (tooling)                                      | MIT               |
| cron-parser                             | @kasama/domain (runtime)                              | MIT               |
| drizzle-kit                             | @kasama/db (tooling)                                  | MIT               |
| drizzle-orm                             | @kasama/db (runtime), @kasama/server (runtime)        | Apache-2.0        |
| hono                                    | @kasama/contracts (runtime), @kasama/server (runtime) | MIT               |
| jose                                    | @kasama/server (runtime)                              | MIT               |
| postgres                                | @kasama/db (runtime), @kasama/server (runtime)        | Unlicense         |
| posthog-node                            | @kasama/observability (runtime)                       | MIT               |
| turbo                                   | kasama (tooling)                                      | MIT               |
| typescript                              | kasama (tooling)                                      | Apache-2.0        |
| undici                                  | @kasama/agent (runtime)                               | MIT               |
| werift                                  | @kasama/sandbox (tests)                               | MIT               |
| vitest                                  | kasama (tooling)                                      | MIT               |
| zod                                     | @kasama/contracts (runtime), @kasama/server (runtime) | MIT               |

## Dart packages

| Package                                      | Used in                            | License      |
| -------------------------------------------- | ---------------------------------- | ------------ |
| args                                         | kasama_cli                         | BSD-3-Clause |
| dio                                          | kasama_api, kasama_sdk, kasama_cli | MIT          |
| http                                         | kasama_sdk                         | BSD-3-Clause |
| path                                         | kasama_cli                         | BSD-3-Clause |
| json_annotation, json_serializable           | kasama_api                         | BSD-3-Clause |
| copy_with_extension, copy_with_extension_gen | kasama_api                         | MIT          |
| build_runner                                 | kasama_api (tooling)               | BSD-3-Clause |
| test, lints                                  | all Dart packages (tooling)        | BSD-3-Clause |
| supabase_flutter                             | client                             | MIT          |
| flutter_riverpod                             | client                             | MIT          |
| go_router, flutter_localizations, intl       | client                             | BSD-3-Clause |
| xterm                                        | client                             | MIT          |
| markdown_widget                              | client                             | MIT          |
| file_picker                                  | client                             | MIT          |
| share_plus, web_socket_channel               | client                             | BSD-3-Clause |
| sentry_flutter                               | client                             | MIT          |
| firebase_core, firebase_messaging            | client                             | BSD-3-Clause |
| flutter_webrtc                               | client                             | MIT          |
| posthog_flutter                              | client                             | MIT          |
| mocktail                                     | client (tooling)                   | MIT          |

## Other software

| Software                               | Role                           | License                                        |
| -------------------------------------- | ------------------------------ | ---------------------------------------------- |
| PostgreSQL                             | database                       | PostgreSQL License                             |
| Neko (m1k1o/neko), built from source   | desktop image: WebRTC streamer | Apache-2.0                                     |
| coturn                                 | TURN relay image               | BSD-3-Clause                                   |
| SeaweedFS (optional compose profile)   | self-hosted S3 storage         | Apache-2.0                                     |
| X.Org server, Openbox, Mousepad        | desktop image                  | MIT/X11, GPL-2.0 (system packages, unmodified) |
| pgvector                               | database extension             | PostgreSQL License                             |
| pgTAP                                  | database tests                 | PostgreSQL License                             |
| Supabase (self-hosted services)        | platform                       | Apache-2.0 / MIT (per component)               |
| OpenAPI Generator (dart-dio templates) | code generation                | Apache-2.0                                     |
