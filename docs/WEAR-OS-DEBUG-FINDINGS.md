# Wear OS debug run: findings

Run date: 2026-11-21. Build: `scripts/package-wear.sh debug -PdefaultServer=https://api-dev.casama.ai` (produces `client/wear/app/build/outputs/apk/debug/app-debug.apk`).
Emulator: `Casama_Wear_Small_Round` (384x384, density 320, Android 17 / API 36/37) on `emulator-5554`.
Backend: local Supabase on :54321 / :54322, local API on :8787 (pid 83723) and worker (pid 86406) started with `node` against local environment.
Account: `wear-debug@example.com` ("Wear Debug" workspace `2bbf119f-6176-423d-9b87-aefab4bfb8f5`). Credentials saved in Vaultwarden item `08313813-0108-4e60-b563-df00a8a82262`.
Status: **fixed F1, F2, F3, F4, F5, F6, F7, F8**. Screenshots are stored in `/tmp/wear-debug/`.

---

## Environment

- **E1: `scripts/dev-up.sh` port conflict on UDP 3478.** Container `casama-turn` fails to bind `127.0.0.1:3478` because an existing `casama-app-turn` container holds the port. `scripts/dev-up.sh` aborted with exit code 1.
  *Workaround:* Executed API and worker directly via `node --env-file-if-exists=../../.env src/main.ts` and `MODE=worker node ...`.
- **E2: Node watch mode export mismatch with uncommitted domain changes.** `pnpm --filter @casama/server dev` crashed with `SyntaxError: The requested module '@casama/domain' does not provide an export named 'CHAT_KEY_PROVIDERS'` due to dirty working tree state in another package. Running node directly on `src/main.ts` bypassed the restart loop.
- **E3: Automated hold gestures in `agent-device`.** `HoldToAllowButton` enforces an 800 ms hold (`HOLD_MS = 800`) with pointer input animation. Standard accessibility / test gestures (e.g. `agent-device longpress`, which holds for standard 500 ms) cancel early without completing the fill, requiring either TalkBack tap-confirmation mode or precise duration injection.
- **E4: Wear Compose `SwipeDismissableNavHost` back navigation.** Standard back gestures and `agent-device back --in-app` do not consistently pop Wear Compose screens without explicit Android `KEYCODE_BACK` key events or horizontal swipes from the left display bezel.

---

## Findings

| # | Area | Severity | Finding |
|---|------|----------|---------|
| F1 | Header / TimeText layout | high | On round watch displays (384x384), system curved `TimeText` (e.g. "2:12", "2:26") directly overlaps centered top elements across multiple screens: top of Sleepy/Winky mascot on `NowScreen` and `SignInScreen`, top message card on `ChatScreen`, "Brief" title on `BriefScreen`, and bot face on `RequestScreen`. In `TransformingLazyColumn`, items require additional top padding or integration with `ResponsiveListHeader` / `TimeText` scroll-away fades. |
| F2 | Settings > EdgeButton truncation | medium | In `SettingsScreen`, the bottom EdgeButton text `"Sign out of this watch"` wraps and truncates to `"Sign out / of this ..."` due to the curved bottom bezel and limited height of Wear Compose Material3 `EdgeButton`. Should be shortened to `"Sign out"`. |
| F3 | WorkingScreen > EdgeButton contrast | medium | In `WorkingScreen`, the "Stop" EdgeButton container is set to `CasamaColors.StopContainer` (`#5C1F1A`) with `CasamaColors.OnStopContainer` (`#FFB4A9`). On screen, it renders as a dark, low-contrast pill without a distinct white/bright stop icon or label, making it appear disabled or unlabelled during quick glance while a routine is executing. |
| F4 | NowScreen / Foreground Polling | medium | `MainActivity` only refreshes the glance state in `onResume()`. When new approvals, suggestions, or routine updates arrive while the app remains open in the foreground, the `NowScreen`, `BotsScreen`, and `UpNextScreen` stay stale indefinitely until the app is backgrounded and re-opened. Needs a foreground periodic refresh timer (e.g. every 30-60s) or foreground push refresh. |
| F5 | Up Next > Long routine name layout | low | On `UpNextScreen`, routines with lengthy names wrap across 3 lines, pushing the "Run Now" action button below the round viewport fold and requiring extra swiping to reach the button. Routine titles should be capped to 2 lines with `TextOverflow.Ellipsis`. |
| F6 | NowScreen > Up Next redundancy | low | When an upcoming routine is present, `NowScreen` shows an `Eyebrow("UP NEXT")` routine card (which navigates to `Routes.UP_NEXT`) and, right below it in the navigation rows, another `NavRow("Up next", ic_clock)`. Having both an Up Next routine card and an Up Next navigation row in the same vertical scroll list feels redundant. |
| F7 | RequestScreen > Hold to allow feedback | low | When an approval with medium risk is displayed, releasing `HoldToAllowButton` before the 800 ms fill completes silently drains the progress bar with a quick 150 ms tween, but provides no subtle haptic or visual indicator explaining why the hold failed or was incomplete. |
| F8 | BriefScreen > Text clipping on small screens | low | The full brief body text is presented in a scrollable `Words` component. On small round displays, very long text paragraphs require many swipes to reach the "Read aloud" action button at the bottom. An inline audio pill or earlier action shortcut would improve reachability. |

---

## What worked (no problems seen)

- **Sign-in & Pairing:** Unpaired screen rendered cleanly with Sleepy mascot; 8-character watch code generated instantly; polling picked up remote claim via `/v1/watch-codes/:code/claim` and transitioned automatically to paired state without manual reload.
- **Now Screen:** Clean layout showing "All clear" state, Up Next routine preview cards, Needs you cards (with count badge `NEEDS YOU · 2`), and navigation rows to Bots, Up next, Brief, and Settings.
- **Voice & Type Input (Ask flow):** Microphone permission dialog properly requested and granted; "Listening..." animation ring with Winky mascot; silence timeout gracefully transitions to "Didn't catch that / Type instead" fallback; "Type instead" seamlessly brings up Wear OS SysUI IME / Keyboard; typing and submitting transitions to "Heard" screen with working Undo countdown.
- **Working Screen & Background Execution:** Smooth transition to `WorkingScreen`; step counter, elapsed run timer, and bot mascot avatar update cleanly; model run (`deepseek-v4.1-flash-1017`) completed on worker and automatically navigated to `ChatScreen`.
- **Chat Screen:** Message bubbles styled accurately (Orchid for user, container for bot); markdown formatting rendered properly; "Open on phone" and "Reply" edge button operational.
- **Bots Screen:** Lists all configured workspace bots (Milo, Ada) with status, last reply time, and individual voice action shortcuts.
- **Up Next & Routine Execution:** Displays scheduled routines with relative countdowns; tapping "Run Now" successfully initiates the routine run, shows WorkingScreen, and delivers results into conversation.
- **Needs & Approvals:** `NeedsScreen` lists pending approvals and suggestions; `RequestScreen` cleanly renders medium-risk approval details; "Deny" button successfully submits rejection to backend (`/v1/approvals/:id/decide`) with immediate list removal and haptic confirmation.
- **Suggestions:** `SuggestionScreen` renders bot suggestions with "Do It" Orchid EdgeButton; "Not now" button cleanly dismisses suggestion via API and updates Now screen.
- **Brief & TTS:** `BriefScreen` renders latest workspace morning brief; "Read aloud" button activates Android TTS engine and toggles to "Stop reading" state during playback, returning to "Read aloud" upon completion or interruption.
- **Settings Screen:** Correctly displays active account, workspace name, Ask bot preference, working toggles for "Hide details when wrist down" and "Read replies aloud", and credits meter.

---

## Not covered (needs another run)

- Live voice phone call handoff (`Routes.TALK`): Phone app integration not connected on emulator.
- Tile widgets carousel in SysUI: Android 17 emulator SysUI tile carousel interaction requires real device or dedicated launcher automation.
- Watch face complications (`NeedsYouComplication`, `CreditsComplication`, `AskComplication`): Requires adding complications to a supported watch face slot.
- Promoted ongoing notification updates during background app lock.

---

## Cleanup

- API (pid 83723) and Worker (pid 86406) stopped.
- Emulator `emulator-5554` shut down cleanly via `adb emu kill`.
- Temporary test screenshots and videos preserved in `/tmp/wear-debug/` for reference.
