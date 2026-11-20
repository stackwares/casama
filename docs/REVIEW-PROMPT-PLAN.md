# Asking for store reviews sooner, starting in onboarding: plan

Status: **not started** (written 2026-11-21). Waiting for Oliver's answers to §9 and his go-ahead.
No code yet.

Oliver, 2026-11-21: "we want a little more aggressive asking for reviews especially on android.
specifically asking them during the onboarding".

## 1. Where we are today (D-305)

`client/lib/core/review_prompt.dart` shows the store's own rating sheet through `in_app_review`, at
two moments: a purchase, or the 10th and then every 40th finished reply. Both moments have to pass
every one of these checks:

| Gate | Today |
|---|---|
| Days the app was used | 5 different days |
| Days since first open | 7 |
| Days since this device last asked | 120 |
| No error shown this session | yes |
| Remote flag `review_prompt` | not `false` |
| Platforms | iOS, Android, Mac App Store build |

So in practice nobody is asked in their first week, and most people who leave sooner are never
asked. The prompt has no tests. `review_prompt_shown` (with `moment`) is the only signal we get.

**What "onboarding" means in Casama now.** It isn't the `/onboarding` wizard
(`features/workspaces/onboarding_screen.dart`). Since D-263 that wizard is only the manual path. New
people go through `/welcome`:

1. **What should bots call you?** (the name step, D-169)
2. **Picks for you** (starter sets, D-315), where they tap Add or Skip for now
3. **The welcome chat** with their first bot. The empty chat has the intro film link (D-459), and
   their first finished run counts as `first_value`.

So "ask during onboarding" means asking somewhere in that flow, not in the old wizard.

## 2. What the stores allow

These rules decide where the ask can go. Breaking them costs more than a few extra ratings would
bring in.

- **Store sheet only, no question first.** Google's in-app review guidelines forbid asking
  "Do you like the app?" (or any question that predicts the rating) before or while the sheet
  shows. Apple's guideline 5.6.1 requires its API for in-app review requests. Asking only happy
  people ("review gating") breaks both. We keep calling the store sheet directly and add no screen
  of our own before it.
- **No rewards.** No credits, features or anything else for a review (both stores' policies).
- **Google Play rations it.** Play enforces a time-based limit we can't see. A call over the limit
  shows nothing and doesn't tell us. Asking more often than Play allows changes nothing for users, so
  on Android we can ask freely and let Play filter.
- **Apple allows three a year per person.** iOS shows the prompt at most 3 times in 365 days. An ask
  in onboarding uses one of those three on someone who has used the app for two minutes. Apple's
  Human Interface Guidelines also say not to ask on first launch or during onboarding. That's
  guidance, not a rejection reason.
- **Play's own guidance says to ask after the person has used the app enough to judge it.** The
  onboarding moment below waits until they've had a real reply from their bot, not just the sign-in
  screens.

## 3. The proposal

### 3.1 A new onboarding moment: the first good reply

New `ReviewMoment.firstReply`: **the first finished reply in the welcome chat, during the first-run
session.** It's the first point where the person has seen Casama do something. Before it they've only
typed their name.

- It fires when that run finishes successfully (the same place `replyFinished` fires,
  `chat_controller.dart:1862`), **about 3 seconds after** the reply is on screen, so the sheet
  doesn't cover a reply that's still drawing. It's skipped if they started typing again.
- **Gates for this moment:** no error shown this session, not already asked on this device, the
  remote flags allow it (§3.4), and a supported platform. It skips the days-used and first-open
  gates; skipping them is the whole point.
- **First-run session only.** A flag set by `/welcome` (`casama.review.firstRun`, on the device)
  marks the session. Someone who signs in on a new phone months later doesn't get it; their normal
  milestones still apply.
- **The manual path too:** the first finished reply after the `/onboarding` wizard ends
  (`onboarding_complete` with `path: manual`) counts the same way.

Rejected alternatives (see §9, decision 2 to pick one instead):
- *Right after Picks for you → Add.* The person has committed, but hasn't seen a bot reply yet.
  Play's guidance and their own judgment both point later.
- *After the name step.* Too early, and it would also spend one of Apple's three on iOS.

### 3.2 Android: looser regular gates

Play does its own rationing, so ours can be much looser:

| Gate | Today | Android, proposed |
|---|---|---|
| Onboarding moment (§3.1) | none | **on** |
| Reply milestones | 10th, then every 40th | **3rd, 10th, then every 20th** |
| Days used | 5 | **2** |
| Days since first open | 7 | **1** |
| Days since this device last asked | 120 | **30** |
| Purchase moment | gated like the others | **only the error and remote gates** (it's the best moment we have) |

### 3.3 iOS and the Mac App Store: a little looser, onboarding off by default

The limit of three a year means every ask has to count:

| Gate | Today | iOS / Mac App Store, proposed |
|---|---|---|
| Onboarding moment (§3.1) | none | **off** by default; remote flag to turn it on (§3.4) |
| Reply milestones | 10th, then every 40th | **10th, then every 40th** (unchanged) |
| Days used | 5 | **3** |
| Days since first open | 7 | **3** |
| Days since this device last asked | 120 | **90** (stays within Apple's 3 a year) |
| Purchase moment | gated like the others | **only the error and remote gates** |

The web app and the direct-download desktop builds still never ask.

### 3.4 Remote switches

Remote config only has on/off flags (`RemoteAppConfig.flags`, booleans), so the numbers live in the
code and the switches are remote. Turning them off needs no release:

| Flag | Default when the server says nothing | Turns off |
|---|---|---|
| `review_prompt` (exists) | on | every ask, everywhere |
| `review_prompt_onboarding_android` | **on** | the onboarding ask on Android |
| `review_prompt_onboarding_ios` | **off** | the onboarding ask on iOS and the Mac App Store build (turn **on** to try it) |
| `review_prompt_eager_android` | **on** | the looser Android gates (§3.2), back to the D-305 numbers |

No server or contract change: flags are an open map the server owner already sets.

### 3.5 Code shape

- `ReviewRules`: a small value class with `minDays`, `minAgeDays`, `gapDays`, a milestone function
  and `onboarding: bool`. `ReviewRules.forPlatform(platform, flags)` picks Android, Apple or the
  D-305 fallback. `ReviewPrompt` reads its numbers from it instead of the static constants.
- `ReviewMoment` gains `firstReply`. `moment()` keeps one code path: the moment decides which gates
  apply.
- The "asked" date is shared, so an onboarding ask also starts the 30 or 90 days before the next
  one, and a purchase the same week won't ask again.

## 4. Measuring it

- `review_prompt_shown` keeps its name and gets new `moment` values (`first_reply`) and a `rules`
  property (`eager_android`, `apple`, `default`). That's a catalog change: `pnpm gen` updates the GA4
  twins. It really means "we asked and the store's API was available". Neither store says whether
  the sheet showed or what was rated.
- **The real numbers come from the stores:** Play Console → Ratings (count and average by app
  version and by day) and App Store Connect → Ratings and Reviews. Take a baseline for the 4 weeks
  before the release that ships this, then compare the 4 weeks after.
- **Watch the average as well as the count.** Asking two minutes in may bring more ratings and a
  lower average. If the Android average drops by more than 0.2 stars in the 4 weeks after, turn
  `review_prompt_onboarding_android` off and look again.

## 5. Phases

**Phase 1: rules and tests.** `ReviewRules`, per-platform numbers, new moment, remote switches.
New `client/test/review_prompt_test.dart` (none exists today) covers each gate per platform, the
first-run flag, the shared asked date, and the error-this-session skip. It uses the existing
`request`/`now`/`supported` injection points.
*Done when* the test file passes and `flutter analyze` is clean.

**Phase 2: hook up the onboarding moment.** Set the first-run flag in `/welcome` and at the end of the
manual wizard. Fire `firstReply` from the chat controller with the delay and the "not typing" check.
Analytics catalog change + `pnpm gen`.
*Done when* a widget or controller test shows the first welcome-chat reply asks once and a second
reply doesn't.

**Phase 3: docs.** A `D-…` entry (next free number; check first) that updates D-305, a `CHANGELOG.md`
line, and this plan's status line plus its row in `docs/PLANS.md`. No privacy page change (no new
data). No `docs/COSTS.md` change (free APIs).

**Phase 4: check on real devices.** This needs Oliver's yes to build each one, so it isn't automatic:
- **Android:** the Play sheet only shows for an install from Play (internal testing track or internal
  app sharing). A `flutter run` build gets nothing, so this needs an internal-track build. Play's
  limit doesn't apply on internal app sharing, which makes it the easiest place to test.
- **iOS:** debug builds always show the sheet (it says it's a test and doesn't post). TestFlight
  never shows it. A debug run on the simulator is enough.

Ships with the next app release; nothing goes to the server.

## 6. Risks

- **A lower average rating on Android** from people asked two minutes in (§4 has the tripwire).
- **Covering the first reply.** The 3-second delay and the "not typing" check are there for this.
  The person can close the sheet in one tap.
- **Spending Apple's three on onboarding** if the iOS flag is turned on. That's why it's off by
  default.

## 7. Not in this plan

- A "Rate Casama" button in Settings or Help (`openStoreListing`) is out unless §9 decision 5 says
  yes. If it does, Phase 2 adds the row, with a `review_store_opened` event.
- Asking by email or push.
- A feedback screen of our own for unhappy people. Done right before the store sheet, it's the
  review gating both stores forbid. Help & support (D-298) already exists on its own.

## 8. Files

`client/lib/core/review_prompt.dart`, `client/lib/features/chat/chat_controller.dart`,
`client/lib/features/welcome/welcome_screen.dart`, `client/lib/features/bots/bots_screen.dart` (manual
path), `client/lib/core/billing.dart` (purchase gates), `packages/contracts/analytics/catalog.json`,
new `client/test/review_prompt_test.dart`.

## 9. Decisions for Oliver

| # | Question | Default if you just say "go" |
|---|---|---|
| 1 | Onboarding ask on Android? | **Yes**, at the first good reply in the welcome chat |
| 2 | Which onboarding moment: first good reply, right after Picks → Add, or after the name step? | **First good reply** (§3.1) |
| 3 | Onboarding ask on iOS and the Mac App Store build too? | **No** by default, with a remote flag to try it. It uses one of Apple's three a year |
| 4 | The looser Android numbers in §3.2 (3rd reply, 2 days, 1 day, 30-day gap)? | **Yes** |
| 5 | Add a "Rate Casama" row in Settings → Help? | **Yes**, on the phone apps and the Mac App Store build. It opens the store page, so it doesn't count toward any limit |
