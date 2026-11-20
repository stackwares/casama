# Admin console security implementation plan

Status: **live** (2026-11-20): server, docs, web app 63, iPhone 63 (TestFlight), Android 63 and Wear OS (Play internal); D-448, D-450, D-452, D-453. Mac builds pending. Built and review-fixed the same day. Authorized by Oliver: “build all now! you decide for everything!”

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

## One check, three ways: passkey, PIN, or password and code (D-452, 2026-11-20)

Status: **live** (server, docs and web app build 62, 2026-11-20). Oliver approved: "go and build
all", then the deploy. Oliver: "passkeys are enough", then "maybe
just allow the admin set a 4-6 digit pin? either a custom PIN / Password + 2FA / Passkey?", then
"make it 6 PIN".

### Ways in

The lock screen and every confirmation offer, in this order, whatever the account has set up:

1. **Face ID or fingerprint** (unchanged from D-450): lifts the app's own lock only, while the server's
   window from the last check is still open.
2. **Passkey:** one Face ID or fingerprint prompt. It counts as the whole check, also on an account
   with an authenticator (Oliver's call: "passkeys are enough"). Trade-off accepted: Supabase also
   accepts a security key that never asks for a PIN, and the server can't tell the difference.
3. **Admin PIN:** exactly 6 digits, set by the owner.
4. **Password, plus the authenticator code** when the account has one: always there, the way back
   when the others fail.

### The check goes to our server, not a new sign-in

Today a passkey replaces the app's session with a new one (and that session still owes its
authenticator code). Instead, each way records a **fresh admin check** on the current sign-in session:

- New table `public.admin_step_ups` (session id, user id, when, which way). RLS on, no policies: only
  the API writes it. Rows older than a day are deleted as new ones are written.
- `POST /v1/admin/checks/passkey`: the app runs the passkey sheet against Supabase's passkey
  endpoints as now, sends the resulting proof token to the API, and ends that extra session. The API
  verifies the token's signature, that it's the same account, and that its `passkey` sign-in is under
  a minute old. The check's time is the passkey's own time, so sending the same proof again gains
  nothing; a proof is also refused for a second session.
- `POST /v1/admin/checks/pin`: the API checks the PIN and records the check.
- Password and code keep working as today (a real sign-in in the token).
- The API's admin rules (5 minutes for reads, 1 minute for changes) and the database's
  `decide_approval` rule accept either a real sign-in in the token or a fresh check for this session.
  A check counts as the second step too. Both endpoints are exempt from the freshness rule they
  satisfy, and both are owner-only.

### PIN rules

- **6 digits.** No obvious ones: all the same digit (000000), runs (123456, 654321), or repeated
  pairs or triples (121212, 123123).
- **Server-side only.** A salted scrypt hash in a new owner-only table (`admin_pins`, RLS on, no
  policies); nothing on the device. It never signs anyone in: it only confirms on a session that is
  already signed in to that account.
- **Setting, changing or removing the PIN** (Admin console → Security) needs a fresh check by passkey or
  password and code, never by the old PIN.
- **5 wrong PINs in a row turn it off.** After that, only a passkey or password and code work, then you
  set a new PIN. Each wrong attempt is logged; the owner gets an email when the PIN is turned off.
- Tries are counted on the server per account, so a second device or a script doesn't get extra
  guesses.

### Build list

- [x] Migration: `admin_step_ups`, `admin_pins`, `fresh_admin_sign_in()` accepts a fresh check.
- [x] API: the two check endpoints, PIN set/change/remove, the admin rules accept checks; contract and
  `pnpm gen`.
- [x] App: passkey check without a session swap (removes D-450's `signInAgainWithPasskey`), PIN
  entry on the lock screen and in confirmations, Admin → Security to set or change the PIN, Face ID
  window counted from the last check.
- [x] Tests: server (proof checks, replay, PIN limits, two-step), pgTAP for `decide_approval`, Flutter.
- [x] Docs (self-hosting), decision D-452, this plan and PLANS.
- [x] Ship: server (migration applied), docs and web app build 62 live 2026-11-20; store builds later.

## The screen lock is the whole check (D-453, 2026-11-20)

Status: **live** (2026-11-20, build 63; Mac left out). Oliver: "a screen lock is totally enough", then "go and
do everything now except Mac builds".

- [x] A P-256 key in the phone's secure chip (`biometric_signature`), unlocked by Face ID, a
  fingerprint or the passcode, signs a one-time server challenge; the server checks it with the
  stored public key and records a full check on the session.
- [x] Migration `20270306100001_admin_device_keys.sql`; API: devices list/add/remove, challenge, check.
- [x] App: Face ID first on the lock screen and in confirmations, opening by itself (at most once every
  30 seconds); offer after a passkey or password unlock; Admin → Security lists and removes devices.
  Replaces D-450's local-only unlock.
- [x] The recorded loop: no repeat prompts; a lock right after an unlock is reported with its reason.
- [x] Tests, docs, D-453.
- [x] Ship: server, docs, web app 63; iPhone 63 on TestFlight; Android 63 and Wear OS on Play internal.
- [ ] Mac builds (direct download and Mac App Store): left out on Oliver's word.

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
