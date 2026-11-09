# Kasama Enterprise features (`ee/`)

Source-available under the [Kasama Enterprise License](LICENSE) (draft): readable and free to try,
production use needs a license key. Everything outside this folder is Apache-2.0 (D-073).

| Feature      | What it does                                                                                               | Endpoint                                  |
| ------------ | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| Audit export | Download a workspace's audit log as CSV or JSON for a date range                                           | `GET /v1/orgs/{id}/audit-log/export`      |
| SSO (SAML)   | Register a workspace's SAML identity provider with Supabase Auth; members sign in with "Continue with SSO" | `POST /v1/orgs/{id}/sso`, `GET`, `DELETE` |

License keys are Ed25519-signed JWTs (`KASAMA_LICENSE_KEY`) carrying the customer, features, seats
and expiry, checked against [`server/license-public.pem`](server/license-public.pem). Without a
valid key the endpoints answer 402 `license_required`; the rest of Kasama is unaffected.

Issue a key (maintainers, with the private signing key): `node ee/scripts/issue-license.ts --customer
"Acme" --features audit_export,sso --seats 50 --days 365`.

Planned: advanced roles (viewer and billing roles, per-bot permissions) and priority support tooling.
