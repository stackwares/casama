# Fix: Very large system text sizes overflow and break screens

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/text-scale-factor
- **Needs new dependency**: none

## Why

Some people raise their phone's text size because small text is hard for them to read. Casama
follows that setting with no upper limit, so at the accessibility sizes (iOS AX1 to AX5 are 1.65x
to 3.1x, Android 14 goes to 2x) fixed-height rows, chips, the floating tab bar and two-column
cards overflow, clip or show the yellow-and-black overflow stripe. Capping the scale keeps every
screen intact while still honouring the setting for almost everyone who changes it.

**The cap is 1.3x, not the article's 1.1x.** 1.3x is the largest standard (non-accessibility)
size on both platforms: Android's "Largest" font size before Android 14 is exactly 1.3x, and iOS
Dynamic Type xLarge (1.12x) and xxLarge (1.24x) pass through untouched, with xxxLarge (1.35x)
only slightly reduced. The article's 1.1x would quietly undo the setting for most people who
raised it, and this app already proves larger text works on its most important screens (the
sign-in button is tested at 2x, the call screen at 1.6x). Only the accessibility sizes, where the
layouts were never designed to go, are held at 1.3x. A new test runs every screen at the cap on
the small 375x667 phone to prove it.

## Where

Nothing in the app limits `textScaler` today (a search for `textScaler|textScaleFactor` in
`lib/` finds nothing). These are the app roots that need the limit.

```dart
// lib/app.dart:67 — current (the main app's MaterialApp.router builder)
      builder: (context, child) => _DismissKeyboard(
        child: CompanionOverlay(
          child: _FirstRunSteps(push: ref.read(pushProvider), child: child ?? const SizedBox.shrink()),
        ),
      ),
```

```dart
// lib/main.dart:119 — current (the "Connecting to Casama…" / "Can't reach your server" app shown before the main app loads)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
```

```dart
// test/phone_layout_test.dart:63 — current (the every-screen layout test, runs at text scale 1.0 only)
void main() {
  for (final size in const [Size(430, 932), Size(375, 667)]) {
    testWidgets('every screen fits a ${size.width.toInt()}x${size.height.toInt()} phone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
```

```dart
// test/phone_layout_test.dart:74 — current
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
```

## The fix

The article's fix: override `MediaQuery.textScaler` in the `MaterialApp` builder with
`textScaler.clamp(maxScaleFactor: …)`, so the person's setting still applies up to the cap. Put
it in one small shared function so both app roots and the layout test use exactly the same code.

New file `lib/ui/text_scale.dart` (target, complete):

```dart
import 'package:flutter/widgets.dart';

/// The largest text scale the app follows (D-NNN). The system text size is honoured up to here:
/// Android's largest standard size (1.3x) and iOS Dynamic Type through xxLarge pass through as
/// they are. The bigger accessibility sizes are held at 1.3x so fixed-height rows, chips and the
/// tab bar don't overflow.
const double kMaxTextScale = 1.3;

/// A [MaterialApp.builder]: [child] follows the system text size, but never above
/// [kMaxTextScale]. Smaller sizes are left alone.
Widget limitTextScale(BuildContext context, Widget? child) {
  final MediaQueryData mediaQueryData = MediaQuery.of(context);

  return MediaQuery(
    data: mediaQueryData.copyWith(
      textScaler: mediaQueryData.textScaler.clamp(maxScaleFactor: kMaxTextScale),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}
```

```dart
// lib/app.dart — target (the limit is the outermost wrapper, so the companion overlay, the
// first-run pages, dialogs and sheets are all capped too)
      builder: (context, child) => limitTextScale(
        context,
        _DismissKeyboard(
          child: CompanionOverlay(
            child: _FirstRunSteps(push: ref.read(pushProvider), child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
```

```dart
// lib/main.dart — target
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: limitTextScale,
      home: Builder(
```

## Steps

Line numbers are from when this plan was written. If a file has shifted since (for example
new imports were added at the top), find each line by its quoted text; only a change in the
quoted text itself is a reason to stop.

1. Create `lib/ui/text_scale.dart` with exactly the content in "The fix". Leave `D-NNN` for
   now; step 6 replaces it. Then run `dart format -l 200 lib/ui/text_scale.dart` (this is the
   only file you may format).
2. In `lib/app.dart`, add the line `import 'ui/text_scale.dart';` directly below the line
   `import 'theme/appearance.dart';`.
3. In `lib/app.dart`, replace the `builder:` argument quoted in "Where" (5 lines starting
   `      builder: (context, child) => _DismissKeyboard(`) with the `lib/app.dart` target in
   "The fix". Edit by hand; never run `dart format` on this file.
4. In `lib/main.dart`, add the line `import 'ui/text_scale.dart';` directly below the line
   `import 'ui/glow_button.dart';`. Then, in the startup `MaterialApp(` quoted in "Where",
   insert the line `      builder: limitTextScale,` between
   `      supportedLocales: AppLocalizations.supportedLocales,` and `      home: Builder(`.
   Only that `MaterialApp`, which is the one at line 119 inside `build`.
5. Tests.
   a. In `test/phone_layout_test.dart`, add `import 'package:casama_app/ui/text_scale.dart';`
      directly below `import 'package:casama_app/theme/app_theme.dart';`.
   b. Replace these two lines:
      ```dart
        for (final size in const [Size(430, 932), Size(375, 667)]) {
          testWidgets('every screen fits a ${size.width.toInt()}x${size.height.toInt()} phone', (tester) async {
      ```
      with:
      ```dart
        // Third run: the largest system text size, which the app caps at kMaxTextScale.
        for (final (size, textScale) in const [(Size(430, 932), 1.0), (Size(375, 667), 1.0), (Size(375, 667), 2.0)]) {
          testWidgets('every screen fits a ${size.width.toInt()}x${size.height.toInt()} phone${textScale == 1.0 ? '' : ' with the largest text size'}', (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      ```
      (The existing two test names stay exactly the same.)
   c. In the same loop's `MaterialApp.router(` (the one quoted in "Where" at line 74, not the
      one in the "back from the bot profile" test further down), add the line
      `            builder: limitTextScale,` directly below
      `            supportedLocales: AppLocalizations.supportedLocales,`.
   d. Create `test/text_scale_test.dart` with this content, then run
      `dart format -l 200 test/text_scale_test.dart`:
      ```dart
      import 'package:flutter/material.dart';
      import 'package:flutter_test/flutter_test.dart';
      import 'package:casama_app/ui/text_scale.dart';

      void main() {
        Future<TextScaler> scalerAt(WidgetTester tester, double systemScale) async {
          tester.platformDispatcher.textScaleFactorTestValue = systemScale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          late TextScaler scaler;
          await tester.pumpWidget(
            MaterialApp(
              builder: limitTextScale,
              home: Builder(
                builder: (context) {
                  scaler = MediaQuery.textScalerOf(context);
                  return const SizedBox();
                },
              ),
            ),
          );
          return scaler;
        }

        testWidgets('the largest system text sizes are held at the cap', (tester) async {
          expect((await scalerAt(tester, 2.0)).scale(10), closeTo(10 * kMaxTextScale, 0.001));
          expect((await scalerAt(tester, 3.1)).scale(10), closeTo(10 * kMaxTextScale, 0.001));
        });

        testWidgets('sizes up to the cap pass through as they are', (tester) async {
          expect((await scalerAt(tester, 1.15)).scale(10), closeTo(11.5, 0.001));
          expect((await scalerAt(tester, 1.0)).scale(10), closeTo(10, 0.001));
          expect((await scalerAt(tester, 0.85)).scale(10), closeTo(8.5, 0.001));
        });
      }
      ```
6. Record the decision. Open `/Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md`,
   find the highest `## D-NNN` number in the whole file right now (others add entries in
   parallel, so read it at this moment), and append this entry at the very end of the file
   using the next free number in place of `D-NNN`:
   ```markdown
   ## D-NNN Text size follows the system setting up to 1.3x

   - **Decision**: the app follows the system text size but caps it at 1.3x (`kMaxTextScale` in `client/lib/ui/text_scale.dart`, applied in the builder of both `MaterialApp`s). Smaller sizes are untouched.
   - **Why 1.3x and not 1.1x**: 1.3x is the largest standard size on both platforms (Android's "Largest" before Android 14; iOS xLarge 1.12x and xxLarge 1.24x pass through, xxxLarge 1.35x is barely reduced). A 1.1x cap would undo the setting for most people who raised it. Only the accessibility sizes (iOS AX1–AX5, 1.65x–3.1x; Android 14 up to 2x) are held at 1.3x, because fixed-height rows, chips and the tab bar overflow there.
   - **Tests**: `client/test/text_scale_test.dart`; `client/test/phone_layout_test.dart` runs every screen at the cap on a 375x667 phone.
   ```
   Then, in `lib/ui/text_scale.dart`, replace `D-NNN` in the first doc comment with the same
   number (for example `(D-189)`).
7. Run `flutter test test/text_scale_test.dart test/phone_layout_test.dart test/app_test.dart test/barge_in_test.dart`
   from `client/`. All must pass. (`app_test.dart` and `barge_in_test.dart` already test the
   sign-in and call screens at large text with their own harness; they must still pass.)
8. Run the app yourself at the cap, as the rule asks: on an iOS Simulator set Settings →
   Accessibility → Display & Text Size → Larger Text to the largest accessibility size (or on an
   Android emulator set Display size and text → Font size to the largest), then open the bot list,
   a chat, Inbox and Settings and confirm text is larger than default but nothing overflows. If no
   simulator or emulator is available, say so in your report; the test in step 5 is the proof.

## Check it

- `dart analyze lib/ui/text_scale.dart lib/app.dart lib/main.dart test/text_scale_test.dart test/phone_layout_test.dart` reports no issues.
- `grep -c "limitTextScale" lib/app.dart` → 1
- `grep -c "builder: limitTextScale," lib/main.dart` → 1
- `grep -c "textScaler.clamp(maxScaleFactor: kMaxTextScale)" lib/ui/text_scale.dart` → 1
- `grep -c "const double kMaxTextScale = 1.3;" lib/ui/text_scale.dart` → 1
- `grep -c "D-NNN" lib/ui/text_scale.dart` → 0
- `grep -c "builder: limitTextScale," test/phone_layout_test.dart` → 1
- `grep -c "with the largest text size" test/phone_layout_test.dart` → 1
- `grep -c "Text size follows the system setting up to 1.3x" /Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md` → 1
- The `flutter test` run in step 7 passes.

## Don't touch

- `test/app_test.dart` (`harness()`), `test/barge_in_test.dart` and every other test harness:
  they build their own `MaterialApp` on purpose (some test the screens above the cap). Only the
  every-screen loop in `test/phone_layout_test.dart` gets the limit.
- Screens and widgets: don't add `textScaler`, `maxLines` or font-size changes anywhere else. If
  the capped run finds an overflow, that is a STOP, not something to fix here.
- `MediaQuery.withClampedTextScaling` or any other way of capping: use the article's
  `MediaQuery` + `textScaler.clamp` shape in `limitTextScale` only.
- No `minScaleFactor`: people who shrink text keep their setting.
- Never run `dart format` on existing files or directories (only on the two new files).
- No git commands (others commit in this shared tree).
- No new dependencies. No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written). One exception: if `lib/app.dart`'s builder has gained another
  wrapper since, keep it and still make `limitTextScale(context, …)` the outermost call.
- `test/phone_layout_test.dart`'s new "with the largest text size" run fails. Do not lower the
  cap and do not edit any screen: report the routes and the `where:` lines from the failure
  message so the developer can decide.
- Any other test in step 7 fails because of this change.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. Not a list of files, the steps already have those. For example: the app now
follows the phone's text size up to 1.3x and holds the accessibility sizes there, so screens no
longer break at the largest settings; set the simulator to the largest text size and open
Settings to see it.
