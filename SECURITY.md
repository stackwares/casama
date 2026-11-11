# Security Policy

Casama runs code for people on real computers, holds their secrets, and connects to their accounts,
so we take security reports seriously and appreciate them.

## Reporting a vulnerability

Email **security@casama.ai**, or use GitHub's
[private vulnerability reporting](https://github.com/stackwares/casama/security/advisories/new).
Please don't open public issues or discussions for vulnerabilities.

Include:

- what the issue is and its impact,
- steps to reproduce, or a proof of concept,
- the affected version or commit, and whether it's self-hosted or Casama Cloud.

## What to expect

- We acknowledge your report within 3 business days.
- We keep you updated as we investigate, and agree a disclosure date with you.
- We aim to ship a fix within 30 days for high-severity issues.
- We credit you in the release notes and the advisory, unless you'd rather we didn't.

## Scope

In scope: the API and worker, the sandbox supervisor, computer images and computerd, the egress
proxy, row-level security policies, the apps, the CLI and SDK, the MCP server, and the self-host
installer and deploy templates.

We especially care about:

- data access across workspaces or users,
- escaping a computer's sandbox, or reaching private networks from one,
- secrets leaking into model input, logs, run events or exports,
- prompt-injection paths that get around approvals or action rules,
- authentication and session flaws.

Out of scope: findings that need a compromised device or server account, denial of service by
volume, missing hardening headers without a demonstrated impact, and issues in third-party services
Casama connects to.

## Safe harbor

We won't pursue legal action against good-faith research that follows this policy: test only
against your own self-hosted server or accounts you own, don't access other people's data, don't
degrade service for others, and give us reasonable time to fix the issue before you disclose it.

## Supported versions

Until 1.0, only the latest release gets security fixes. Self-hosters should upgrade promptly; see
the operations guide in `docs-site/self-hosting/operations.md`.
