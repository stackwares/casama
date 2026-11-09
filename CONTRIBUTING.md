# Contributing to Kasama

Thanks for helping. This guide covers setup, the rules every change follows and how to submit it.

## Setup

See "Local development" in the [README](README.md). `pnpm install && supabase start && pnpm dev` is all you need.

## Rules

1. **Contracts first.** Change the Zod schemas or routes in `packages/contracts`, run `pnpm gen`, then implement. Never hand-write duplicate types or a Dart client.
2. **Database changes only through migrations** in `supabase/migrations`, with row-level security enabled on every new table in the same migration, and pgTAP tests in `supabase/tests`.
3. **No secrets** in code, logs, prompts or fixtures.
4. **Small pull requests with tests.** Lint, typecheck and tests must pass.
5. **User-facing strings** in the Flutter app live in ARB files.
6. **New dependencies** are listed in `THIRD_PARTY_NOTICES.md`.
7. **Decisions** the spec does not cover go in `docs/DECISIONS.md`.

## Developer Certificate of Origin

We use the [Developer Certificate of Origin](https://developercertificate.org/) instead of a CLA. Sign off every commit:

```sh
git commit -s -m "Add bot budget checks"
```

This adds a `Signed-off-by: Your Name <you@example.com>` line, which certifies that you wrote the change or have the right to submit it under the project license.

## Checks

```sh
pnpm lint && pnpm typecheck && pnpm test
supabase test db              # RLS tests
(cd dart && dart analyze && dart test cli)
```
