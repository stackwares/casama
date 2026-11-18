# Licensing

Casama is open source. The product (server, worker, agent, apps) is under the
[GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). What you build on Casama with (SDKs,
CLI, plugin kit, examples, docs) stays under the [Apache License 2.0](LICENSES/Apache-2.0.txt).
One folder, `ee/`, has its own license (D-403).

| What | License | In short |
|---|---|---|
| **The product:** `apps/` (server, worker, supervisor, browser extension), `client/` (the apps for every platform), `packages/` (except the ones below), `dart/computerd`, `infra/`, the websites, scripts and everything not listed elsewhere | [AGPL-3.0-only](LICENSE) | Use, change, self-host and sell it. If you change it and let other people use it, over a network or by giving them a copy, you must offer them your changed source code under AGPL-3.0. |
| **What you build with:** `packages/client` (TypeScript SDK), `packages/mcp`, `packages/plugin-check`, `dart/casama_api`, `dart/casama_sdk`, `dart/cli`, `agent-kit/`, `examples/`, `packs/`, `docs-site/`, the OpenAPI document (`packages/contracts/openapi.json`), and the shared format files in `packages/domain/src` that start with `SPDX-License-Identifier: Apache-2.0` | [Apache-2.0](LICENSES/Apache-2.0.txt) (each folder has its own `LICENSE`) | Use them in anything, open or closed, with no copyleft. Plugins, bots, integrations and apps that talk to Casama through its API, SDKs, CLI or MCP server are your own work under any license you like. |
| `ee/` (enterprise features) | [Casama Enterprise License](ee/LICENSE) | Read it, change it, and try it freely. Production use needs a paid license key. You can't resell it or host it for others. |
| The Casama name, logo and mascots | Trademark, not licensed | Forks are welcome under their own name. See [TRADEMARKS.md](TRADEMARKS.md). |
| Third-party code and adapted skills | Their own licenses | Listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md); adapted skills keep their license file in their folder. |
| Gallery items (the casama-gallery repository) | Each item's own license | CC0 or CC-BY-4.0 for looks, MIT or Apache-2.0 for skills, shown on each item. |

## What AGPL-3.0 means in practice

- **Using Casama, for yourself, your family, your company or your customers:** nothing changes. No
  fee, no key, no obligation, as long as you don't change the code.
- **Self-hosting a changed Casama** that other people use (your team, your customers, the public):
  give those users a way to get the source of the version you run, for example a link in the app
  or on your site (AGPL section 13). Your changes are under AGPL-3.0 too.
- **Building on Casama** through its API, SDKs, CLI, MCP server, plugins, skills, packs or gallery
  items: your work is yours, under any license. Those interfaces are Apache-2.0 on purpose.
- **Shipping a changed copy** (an app, an image, a package): include the source, or a written offer
  of it, under AGPL-3.0, keep [NOTICE](NOTICE), and use your own name and logo.

## A commercial license

If AGPL-3.0 doesn't work for your organisation (for example, a policy that forbids it, or a
product built on a changed Casama that you can't publish), Stackwares offers Casama under a
commercial license. Write to hello@casama.ai.

## The open-source edition

Delete `ee/` and what's left is entirely open source (AGPL-3.0 and Apache-2.0) and works on its
own. The server reports the open-source edition, and the enterprise endpoints answer
`402 license_required`, as they do on an enterprise build without a key. Nothing a single person or
a small team needs is missing.

`scripts/oss-edition.sh <dir>` writes that edition from the current commit, and CI builds and tests
it on every change, so it can't quietly start depending on `ee/`.

## What goes in `ee/`

One question decides where new work goes: **would someone running Casama for themselves, their
family or a small team want it?** Then it goes in the open core.

Features only larger organisations need go in `ee/` behind a license feature: single sign-on
(SAML), audit-log export and forwarding, advanced roles, compliance controls. Existing open
features never move into `ee/`.

What's in `ee/` today is listed in [ee/README.md](ee/README.md).

## Contributing

Every contribution needs the [Contributor License Agreement](CLA.md), signed once by commenting on
your pull request, and a sign-off on each commit (`git commit -s`, the
[Developer Certificate of Origin](https://developercertificate.org/)). The CLA lets Stackwares
offer the code under the commercial license and ship the apps in the app stores, while your
contribution stays open source under the license of the folder you changed. You keep your
copyright.

## Questions

Licensing, commercial licenses, enterprise keys or partnerships: hello@casama.ai.
