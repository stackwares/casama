# Admin console security implementation plan

Status: **live** (server 2026-11-20, d4570460; docs and web app build 60 with passkeys and Face ID, e042df58), D-448 and D-450; store and desktop builds pending. Built and review-fixed the same day. Authorized by Oliver: “build all now! you decide for everything!”

## Goal and decisions

Protect an unattended instance-owner console with native automatic locking and server-verified fresh authentication. Use the existing account password or emailed one-time code rather than create a weak reusable PIN or trust a local biometric boolean. No new vendor, secret, table, or paid dependency.

Defaults: lock after five minutes of inactivity, when backgrounded, on leaving the console, and using Lock now. Require explicit confirmation and reauthentication before every admin mutation. The API accepts real authentication methods from signed Supabase AMR claims only: reads within five minutes and writes within one minute. Refreshing a token never renews this window. Active consoles also reauthenticate after the five-minute server window.

GET /v1/admin/overview remains an owner-only discovery endpoint for navigation (instance aggregate counts, no user list). All other /v1/admin routes are protected before validation, replay caches, or side effects, including waitlist, support, domains, pricing, resets and connection settings. Non-admin app use remains signed in. Owner paths outside /v1/admin that could get around the lock (approving admin bot cards, an owner making a sign-in code, gallery request status) take the same one-minute fresh sign-in; see Review fixes.

## Implementation

- [x] Server: add focused admin freshness policy in apps/server/src/api/admin-security.ts, install after bearer verification and before idempotency in app.ts. Keep owner authorization independently enforced on routes. Missing/malformed/future AMR fails closed; no iat fallback, refresh, anonymous, invite or recovery proof.
- [x] Regression tests: fresh reads/writes, expired and missing proof, refresh bypass, future proof, other users and other app routes. Existing harness tokens represent fresh real sign-ins by default with explicit overrides for negative tests.
- [x] Flutter: native gate and auth dialog, idle/background/manual locks, request coordinator, explicit mutation confirmation, bounded retry only after server freshness rejection, current user identity checks. Localized text in app_en.arb, focused policy/widget tests.
- [x] Documentation: describe behavior in self-hosting docs; record the decision and update this plan and PLANS together after verification.
- [x] Verification: targeted tests during development; one serialized full TypeScript test/typecheck and Flutter analysis/test run at end. No Flutter release build or production deploy is included in this implementation request.

## Review fixes (2026-11-20)

A review found ways around the lock and two broken flows; all fixed:

- [x] Scan-to-sign-in codes: an instance owner needs a fresh sign-in to make one (the redeemed code is a brand-new session that counted as fresh on another device).
- [x] Admin bot approvals: approving needs a fresh sign-in; declining doesn't. Enforced in `decide_approval` too (migration `20270228100001`), so a direct PostgREST call can't skip the API.
- [x] Two-step accounts: the server requires aal2 when the account has an authenticator; the lock and confirmations ask for the code in place, and the router no longer moves to the two-step page while an admin form is open (it locked the console in a loop).
- [x] Locking on `inactive` (focus loss, Face ID autofill) dropped confirmations and emailed-code flows: only leaving the app (paused, hidden) locks now; an emailed code is remembered across a lock.
- [x] Decision renumbered D-445 → D-448 (D-445 to D-447 were taken).
- [x] Parallel changes share one confirmation instead of the second being dropped; no second prompt within 45 seconds of a fresh sign-in.
- [x] Lock screen suggests two-step sign-in when the account has none (an open inbox can unlock with an emailed code).
- [x] Gallery request status change takes the fresh sign-in too.

## Passkeys and Face ID (D-450, 2026-11-20)

Oliver: "build them all now in 1 go! you decide for everything else." Typing a password and a code
every few minutes is the console's main friction. Two quicker ways in, with the password and emailed
code kept as the fallback:

- [x] **Passkey** (iPhone, Android, web; where the server's passkeys work in this app): "Verify with a
  passkey" comes first on the lock screen and in every confirmation. It's a real sign-in, so the
  server's checks accept it (`amr` method `passkey`). The ceremony goes to the Auth server's endpoints
  directly and the new session is installed only when the passkey belongs to the signed-in account;
  another account's passkey changes nothing and counts as a failure.
- [x] **Two-step accounts still give the authenticator code after a passkey.** Checked in Supabase
  Auth v2.198.0: a passkey sign-in is `aal1`, and its WebAuthn setting is user verification
  *preferred*, so a security key without a PIN passes with possession alone. Letting it skip the
  authenticator would weaken the account, so the server rules and `decide_approval` stay as they are.
- [x] **Face ID, fingerprint or the device passcode** (`local_auth`, where the app lock's device check
  works) unlocks the console's screen when the server would still accept the session's sign-in for
  at least 30 more seconds (and two-step is done). It only lifts the app's own lock: the server can't
  check it, so it never counts as a fresh sign-in for changes. In practice that is a quick return to
  the app after leaving it; after the 5-minute idle lock the server's window is over anyway. The
  check opens by itself once when the lock screen is shown in the foreground.
- [x] A system sheet (passkey, Face ID) doesn't lock the console while it is open, even where it
  pauses the app (Android's Credential Manager).
- [x] Without a passkey, the lock screen suggests adding one in Settings → Passkeys.
- [x] Tests, docs (self-hosting), decision D-450.

## Validation commands

`pnpm --filter @casama/server exec vitest run test/admin-security.test.ts test/admin.test.ts`

`scripts/heavy.sh sh -c 'pnpm typecheck && pnpm test'`

`scripts/heavy.sh sh -c 'cd client && flutter analyze && flutter test'`

No browser automation is authorized or used.

## Verification record

- Targeted server policy and route tests: 12 passed.
- Full TypeScript checking: all 15 packages passed. Full test tasks: 17 passed; server: 198 files, 1,351 tests passed (2 existing live-model tests skipped).
- Targeted Flutter tests: 74 passed after the email-background fix across request interception, gate lifecycle and existing admin workflows.
- Final Flutter analysis: no issues. Final full Flutter test run: 1,763 passed, 22 existing tests skipped. The email-background regression is included and passes.
- Public documentation build: passed. No browser automation, release build or deployment performed.
