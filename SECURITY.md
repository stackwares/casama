# Security Policy

## Reporting a vulnerability

Email **security@kasama.dev** (placeholder until launch) with a description, reproduction steps and the affected version. Please do not open public issues for vulnerabilities.

We acknowledge reports within 3 business days and aim to ship a fix within 30 days for high-severity issues. We credit reporters in the release notes unless you prefer otherwise.

## Scope

In scope: the API and worker, the sandbox supervisor and computer images, row-level security policies, the Flutter app, the CLI and the self-host installer.

Areas we especially care about: cross-tenant data access, sandbox escape, secret leakage into model context or logs, and prompt-injection paths that bypass approvals.

## Supported versions

Only the latest release receives security fixes until 1.0.
