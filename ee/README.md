# Casama Enterprise features (`ee/`)

Source-available under the [Casama Enterprise License](LICENSE) (draft): readable and free to try,
production use needs a license key. Everything outside this folder is open source (AGPL-3.0, with
the SDKs and tools under Apache-2.0) and works without it (the open-source edition,
[LICENSING.md](../LICENSING.md)). Contributions here need the
[Contributor License Agreement](../CLA.md), like every contribution.

The server loads this folder only through `apps/server/src/ee.ts`. Import it there, never directly,
or the open-source edition check in CI fails.

| Feature      | What it does                                                                                               | Endpoint                                  |
| ------------ | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| Audit export | Download a workspace's audit log as CSV or JSON for a date range                                           | `GET /v1/orgs/{id}/audit-log/export`      |
| SSO (SAML)   | Register a workspace's SAML identity provider with Supabase Auth; members sign in with "Continue with SSO" | `POST /v1/orgs/{id}/sso`, `GET`, `DELETE` |
| Audit forwarding | Stream a workspace's audit log to your own systems (D-146) | `/v1/orgs/{id}/audit-forwarders` |

License keys are Ed25519-signed JWTs (`CASAMA_LICENSE_KEY`) carrying the customer, features, seats
and expiry, checked against [`server/license-public.pem`](server/license-public.pem). Without a
valid key the endpoints answer 402 `license_required`; the rest of Casama is unaffected.

Issue a key (maintainers, with the private signing key): `node ee/scripts/issue-license.ts --customer
"Acme" --features audit_export,sso --seats 50 --days 365`.

How to set up SSO for a workspace: see [Workspaces and teams](../docs-site/guide/workspaces.md).

Planned: advanced roles (viewer and billing roles, per-bot permissions) and priority support tooling.
