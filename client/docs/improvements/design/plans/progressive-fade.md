# Fix: On pages without a top bar, scrolled text is sliced off under the status bar

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/progressive-fade
- **Needs new dependency**: none (`ShaderMask` and `LinearGradient` are in Flutter)

## Why

On pages with no app bar, content that scrolls up meets the status bar. Casama's sign-in,
two-step code, new password, "what should we call you" and invite pages stop their scroll area at
a hard invisible line under the status bar, so when the keyboard is up or the text is large, a
heading scrolling up is sliced through mid-letter. Letting the content run under the status bar
and dissolving it there with a progressive fade makes the top edge soft instead of cut, and keeps
the clock and battery clear.

## Where

Every `Scaffold` without an `appBar:` in `lib/` was checked. Seven pages scroll and have no top
fade (there is no `ShaderMask` or fade around any of them). All code below was read from the
files as they are now; line numbers are where each snippet starts. In the excerpts, `...` marks
lines left out and `// line N` marks a closing line a step edits; neither is in the file.

```dart
// lib/features/auth/sign_in_screen.dart:37 — current (SignInScreen)
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Scaffold(
      // Plain, so the bots are the only thing moving on it.
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingMascots()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                // Spaced out when it fits; scrolls when large text or a small screen doesn't.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      ...
          ),      // line 121
        ],
      ),
    );
  }
}

/// Apple and Google up front; email and password, a magic link, SSO and self-hosting folded behind reveals.
```

```dart
// lib/features/auth/two_step_screen.dart:321 — current (TwoStepPromptScreen, the code after sign-in)
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight - AppSpace.lg * 2;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              ...
            );
          },
        ),
      ),          // line 424
    );
  }
}               // last line of the file
```

```dart
// lib/features/auth/account_screen.dart:159 — current (NewPasswordScreen)
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            ...
          ),
        ),
      ),          // line 204
    );
  }
}

/// Settings → Account (D-184): the email, the password, passkeys, and signing out everywhere.
```

```dart
// lib/features/settings/name_step.dart:104 — current (_NamePageState, "what should we call you")
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final canSave = !_busy && _name.text.trim().isNotEmpty;
    return Scaffold(
      key: const Key('nameStep'),
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            // Spaced out when it fits; scrolls when the keyboard or large text doesn't.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  ...
      ),          // line 246
    );
  }
}
```

```dart
// lib/features/workspaces/join_flow.dart — current. Three pages (JoinScreen, JoinedScreen,
// JoinTeamScreen) put the shared _JoinCard, which holds the scroll view, in a SafeArea.
// :229 (JoinScreen)
    return Scaffold(body: SafeArea(child: body));
// :306 (JoinedScreen)
    return Scaffold(
      body: SafeArea(
        child: _JoinCard(
          key: const Key('joinedWelcome'),
// :353 (JoinTeamScreen)
    return Scaffold(
      body: SafeArea(
        child: _JoinCard(
          key: const Key('joinTeam'),
// :243 (_JoinCard)
  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.gutter),
        ...
      ),
    );            // line 272
  }
}
```

Checked and left alone, because nothing scrolls under the status bar there:
`lib/features/welcome/welcome_screen.dart:76`, `lib/features/routines/run_routine_screen.dart:44`
and `lib/main.dart:128` (centered content that doesn't scroll);
`lib/features/bots/bot_profile_screen.dart:124` and `lib/features/groups/group_chats.dart:36`
(loading spinners); `lib/features/home/home_shell.dart:163`, `:203`, `:240` (the shell frame; each
tab screen inside has its own app bar); `lib/features/workspaces/onboarding_screen.dart:157` (its
list scrolls below a fixed header with the logo and progress bar, never under the status bar).

**Other fixes that touch the same code.** The fix "The ends of lists get cut off above the
phone's home indicator or gesture bar" (it adds `lib/ui/bottom_padding.dart`) edits the same
`SafeArea`s and scroll paddings, but for the *bottom* edge, while this plan handles the *top*. If it
already ran, the code differs from the excerpts in exactly these ways, which are expected:
- each of these `SafeArea(` has a `bottom: false,` line (or `SafeArea(bottom: false, child: body)`
  on `join_flow.dart:229`);
- `sign_in_screen.dart` and `name_step.dart`: the inner `Padding`'s last value is
  `BottomPadding.of(context, minimum: ...)` instead of `AppSpace.lg` / `AppSpace.md`;
- `two_step_screen.dart`: line 328 became two lines,
  `final bottom = BottomPadding.of(context, minimum: AppSpace.lg);` and
  `final minHeight = constraints.maxHeight - AppSpace.lg - bottom;`, and the scroll padding reads
  `padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, bottom),`;
- `account_screen.dart` (`NewPasswordScreen`): the scroll padding reads
  `padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),`;
- `join_flow.dart` (`_JoinCard`): the scroll padding reads
  `padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.gutter, AppSpace.gutter, BottomPadding.of(context, minimum: AppSpace.gutter)),`.

Keep all of those. The steps say, at each spot, how to add the top part next to them; the two
changes combine (`SafeArea(top: false, bottom: false, ...)`, a top padding with the status bar and
a bottom padding with `BottomPadding`). Line numbers may be a few lines off; other fixes elsewhere
in these files can shift them too, so find each spot by its quoted text.

## The fix

The article's `ProgressiveFade`: a `ShaderMask` with `BlendMode.dstIn` and a five-step
`LinearGradient` (transparent, 15%, 40%, 70%, opaque) at the top of the page body, so content
dissolves gradually as it slides under the status bar. It's alpha-only, so it fades the content
itself and the wallpaper and background behind it stay as they are. Placed in
`lib/ui/progressive_fade.dart`, with two adaptations:

1. **The fade's default reach follows the real status bar** (its height plus `AppSpace.lg`, 20px)
   instead of a fixed 120px, and is zero when there's no status bar (desktop, web, a phone in
   landscape), where nothing can collide with one. Content resting below the status bar stays
   fully visible. `height:` still overrides it.
2. **The stops are measured against the masked area**, not the screen height as in the article,
   because the keyboard makes the body shorter and the fade would otherwise stretch.

For the fade to have anything to dissolve, each page's scroll view must start at the very top:
its `SafeArea` gets `top: false`, and the status bar's height moves into the scroll view's top
padding (and out of any minimum-height math), so the page looks exactly as before at rest and
only differs once content scrolls up.

New file `lib/ui/progressive_fade.dart`, exactly:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Dissolves a page's content as it scrolls up under the status bar, on pages with no app bar, so
/// it never collides with the clock and battery.
///
/// Wrap the page body, and let the scroll view start at the very top of the screen: use
/// `SafeArea(top: false)` and add the status bar's height (`MediaQuery.paddingOf(context).top`) to
/// the scroll view's top padding, so content at rest still starts below the status bar. The mask is
/// alpha-only: it fades the content itself, over any background, in light and dark mode.
class ProgressiveFade extends StatelessWidget {
  const ProgressiveFade({super.key, required this.child, this.height});

  final Widget child;

  /// How far down the fade reaches, in logical pixels. Defaults to the status bar's height plus
  /// [AppSpace.lg], so content resting below the status bar stays fully visible.
  final double? height;

  /// How far the fade reaches under a status bar [statusBar] logical pixels tall: nowhere when there
  /// is none (desktop, web, a phone in landscape), since nothing scrolls under one there.
  static double reachFor(double statusBar, {double? height}) => statusBar <= 0 ? 0.0 : (height ?? statusBar + AppSpace.lg);

  @override
  Widget build(BuildContext context) {
    final reach = reachFor(MediaQuery.paddingOf(context).top, height: height);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        // Measured against the masked area, not the screen: the keyboard makes the body shorter.
        final end = bounds.height <= 0 ? 0.0 : (reach / bounds.height).clamp(0.0, 1.0);
        if (end == 0) return const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]).createShader(bounds);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Several steps ease the content out; two colors would give a hard, linear cut.
          colors: const [Color(0x00FFFFFF), Color(0x26FFFFFF), Color(0x66FFFFFF), Color(0xB3FFFFFF), Color(0xFFFFFFFF)],
          stops: [0, end * 0.25, end * 0.5, end * 0.75, end],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
```

The mask stays in the tree even when it fades nothing, so rotating a phone (the status bar comes
and goes) never rebuilds the page and loses the typed code or scroll position.

Each page wraps its `SafeArea` on the same line, so nothing inside needs re-indenting:

```dart
// target, for example in two_step_screen.dart
    final statusBar = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ProgressiveFade(child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight - AppSpace.lg * 2 - statusBar;
            return SingleChildScrollView(
              // Starts under the status bar, so content dissolves there as it scrolls up.
              padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg + statusBar, AppSpace.lg, AppSpace.lg),
              ...
            );
          },
        ),
      )),
    );
```

`lib/features/voice/call_screen.dart` (around line 729) already fades content with a `ShaderMask`,
a top-down `LinearGradient` and `BlendMode.dstIn`; imitate its style.

## Steps

1. Create `lib/ui/progressive_fade.dart` with exactly the code in "The fix". Then run
   `dart format -l 200 lib/ui/progressive_fade.dart` (only on this new file).

2. In each file below, add the import next to the file's other `'../../ui/...'` imports
   (in `name_step.dart`, next to `import '../../ui/mascot.dart';`):
   `import '../../ui/progressive_fade.dart';`
   Files: `lib/features/auth/sign_in_screen.dart`, `lib/features/auth/two_step_screen.dart`,
   `lib/features/auth/account_screen.dart`, `lib/features/settings/name_step.dart`,
   `lib/features/workspaces/join_flow.dart`.

3. `lib/features/auth/sign_in_screen.dart`, in `SignInScreen.build`:
   - after line 39 `    final scheme = context.colorScheme;` add
     `    final statusBar = MediaQuery.paddingOf(context).top;`
   - line 46 `          SafeArea(` (right under `          const Positioned.fill(child: FloatingMascots()),`)
     becomes these two lines:
     `          ProgressiveFade(child: SafeArea(`
     `            top: false,`
     If the `SafeArea(` already has a `bottom: false,` line under it, keep that line right under
     the new `top: false,`.
   - lines 52–54 become:

     ```dart
                  builder: (context, constraints) => SingleChildScrollView(
                    // Starts under the status bar, so content dissolves there as it scrolls up.
                    padding: EdgeInsets.only(top: statusBar),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: (constraints.maxHeight - statusBar).clamp(0.0, double.infinity)),
     ```

   - line 121, the `          ),` that closes the `SafeArea` (right above `        ],`, `      ),`,
     `    );` at the end of `build`), becomes `          )),`
   - Leave `FloatingMascots` outside the fade: they float behind everything already.

4. `lib/features/auth/two_step_screen.dart`, in `_TwoStepPromptScreenState.build`:
   - after line 323 `    final scheme = context.colorScheme;` add
     `    final statusBar = MediaQuery.paddingOf(context).top;`
   - line 325 `      body: SafeArea(` becomes these two lines:
     `      body: ProgressiveFade(child: SafeArea(`
     `        top: false,`
     If a `bottom: false,` line is already there, keep it right under the new `top: false,`.
   - line 328 `            final minHeight = constraints.maxHeight - AppSpace.lg * 2;` becomes
     `            final minHeight = constraints.maxHeight - AppSpace.lg * 2 - statusBar;`
     (if it already reads `final minHeight = constraints.maxHeight - AppSpace.lg - bottom;`, make it
     `final minHeight = constraints.maxHeight - AppSpace.lg - bottom - statusBar;` and keep the
     `final bottom = ...` line above it)
   - line 330 `              padding: const EdgeInsets.all(AppSpace.lg),` (the one right under
     `            return SingleChildScrollView(`; the file has another, leave that one) becomes these two lines:
     `              // Starts under the status bar, so content dissolves there as it scrolls up.`
     `              padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg + statusBar, AppSpace.lg, AppSpace.lg),`
     (if it already reads `padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, bottom),`,
     make it `padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg + statusBar, AppSpace.lg, bottom),`
     and add the comment line above it)
   - line 424, the `      ),` that closes the `SafeArea` (right above the file's final `    );`,
     `  }`, `}`), becomes `      )),`

5. `lib/features/auth/account_screen.dart`, in `NewPasswordScreen.build`:
   - after line 161 `    final scheme = context.colorScheme;` add
     `    final statusBar = MediaQuery.paddingOf(context).top;`
   - line 163 `      body: SafeArea(` becomes these two lines:
     `      body: ProgressiveFade(child: SafeArea(`
     `        top: false,`
     If a `bottom: false,` line is already there, keep it right under the new `top: false,`.
   - line 166 `            padding: const EdgeInsets.all(AppSpace.lg),` (the one right under
     `          child: SingleChildScrollView(`; the file has another, leave that one) becomes these two lines:
     `            // Starts under the status bar, so content dissolves there as it scrolls up.`
     `            padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg + statusBar, AppSpace.lg, AppSpace.lg),`
     (if it already reads `padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),`,
     change only its second value, so it reads
     `padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg + statusBar, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),`,
     and add the comment line above it)
   - line 204, the `      ),` that closes the `SafeArea` (right above `    );`, `  }`, `}` and the
     `/// Settings → Account (D-184)` comment), becomes `      )),`

6. `lib/features/settings/name_step.dart`, in `_NamePageState.build`:
   - after line 106 `    final canSave = !_busy && _name.text.trim().isNotEmpty;` add
     `    final statusBar = MediaQuery.paddingOf(context).top;`
   - line 110 `      body: SafeArea(` becomes these two lines:
     `      body: ProgressiveFade(child: SafeArea(`
     `        top: false,`
     If a `bottom: false,` line is already there, keep it right under the new `top: false,`.
   - lines 116–118 become:

     ```dart
              builder: (context, constraints) => SingleChildScrollView(
                // Starts under the status bar, so content dissolves there as it scrolls up.
                padding: EdgeInsets.only(top: statusBar),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: (constraints.maxHeight - statusBar).clamp(0.0, double.infinity)),
     ```

   - line 246, the `      ),` that closes the `SafeArea` (right above `    );`, `  }`, `}` at the
     end of the file), becomes `      )),`
   - The `key: const Key('nameStep'),` on the `Scaffold` stays.

7. `lib/features/workspaces/join_flow.dart`:
   - In `_JoinCard.build`: after line 245 `    final muted = context.colorScheme.onSurfaceVariant;`
     add `    final statusBar = MediaQuery.paddingOf(context).top;`; line 246 `    return Center(`
     becomes `    return ProgressiveFade(child: Center(`; line 248
     `        padding: const EdgeInsets.all(AppSpace.gutter),` becomes these two lines:
     `        // Starts under the status bar (the pages leave the top of their SafeArea to it), so the card dissolves there as it scrolls up.`
     `        padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.gutter + statusBar, AppSpace.gutter, AppSpace.gutter),`
     (if it already reads `padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.gutter, AppSpace.gutter, BottomPadding.of(context, minimum: AppSpace.gutter)),`,
     change only its second value to `AppSpace.gutter + statusBar` and add the comment line above it)
     and line 272, the `    );` that ends `_JoinCard.build` (right after `      ),` and right
     above `  }`), becomes `    ));`
   - line 229 `    return Scaffold(body: SafeArea(child: body));` becomes
     `    return Scaffold(body: SafeArea(top: false, child: body));`
     (if it already reads `SafeArea(bottom: false, child: body)`, make it
     `SafeArea(top: false, bottom: false, child: body)`)
   - line 307 `      body: SafeArea(` (in `JoinedScreen`, right above `        child: _JoinCard(` and
     `          key: const Key('joinedWelcome'),`): add a new line `        top: false,` right after it
     (above a `bottom: false,` line if there is one).
   - line 354 `      body: SafeArea(` (in `JoinTeamScreen`, right above `        child: _JoinCard(` and
     `          key: const Key('joinTeam'),`): add a new line `        top: false,` right after it
     (above a `bottom: false,` line if there is one).
   - Expected side effect: the invite page's loading spinner (`JoinScreen` while the invite loads)
     now centers on the whole screen instead of the area under the status bar, about half a status
     bar higher. That's fine; don't compensate.

8. Create `test/progressive_fade_test.dart`:

    ```dart
    // Pages without an app bar let content dissolve under the status bar instead of slicing it off.
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/features/auth/account_screen.dart';
    import 'package:casama_app/theme/app_tokens.dart';
    import 'package:casama_app/ui/progressive_fade.dart';

    import 'app_test.dart' show harness, setSize;
    import 'fake_backend.dart';

    void main() {
      test('the fade reaches 20 past the status bar, and nowhere without one', () {
        expect(ProgressiveFade.reachFor(47), 47 + AppSpace.lg);
        expect(ProgressiveFade.reachFor(47, height: 120), 120);
        expect(ProgressiveFade.reachFor(0), 0);
        expect(ProgressiveFade.reachFor(0, height: 120), 0);
      });

      testWidgets('the new-password page scrolls under the status bar, faded there, and still starts below it', (tester) async {
        // Short enough that the page scrolls.
        await setSize(tester, const Size(390, 400));
        tester.view.padding = const FakeViewPadding(top: 47);
        await tester.pumpWidget(harness(FakeBackend(), const NewPasswordScreen()));
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is ShaderMask && w.blendMode == BlendMode.dstIn), findsOneWidget);
        final content = find.byKey(const Key('newPasswordScreen'));
        final scroll = find.ancestor(of: content, matching: find.byType(SingleChildScrollView));
        expect(tester.getTopLeft(scroll).dy, 0);
        expect(tester.getTopLeft(content).dy, 47 + AppSpace.lg);
      });
    }
    ```

    Then run `dart format -l 200 test/progressive_fade_test.dart` (only on this new file).
    (`setSize` already resets the view, padding included, when the test ends.)

9. Run, from `client/`:
   `flutter test test/progressive_fade_test.dart test/phone_layout_test.dart test/app_test.dart test/account_test.dart test/two_step_test.dart test/about_you_test.dart test/joining_test.dart test/passkeys_test.dart test/privacy_test.dart`

## Check it

`dart analyze lib/ui/progressive_fade.dart test/progressive_fade_test.dart lib/features/auth/sign_in_screen.dart lib/features/auth/two_step_screen.dart lib/features/auth/account_screen.dart lib/features/settings/name_step.dart lib/features/workspaces/join_flow.dart`
reports no issues.

Each grep below counts in one file:
- `grep -c "class ProgressiveFade " lib/ui/progressive_fade.dart` → 1
- `grep -c "BlendMode.dstIn" lib/ui/progressive_fade.dart` → 1
- `grep -c "ProgressiveFade(child: SafeArea(" lib/features/auth/sign_in_screen.dart` → 1
- `grep -c "padding: EdgeInsets.only(top: statusBar)," lib/features/auth/sign_in_screen.dart` → 1
- `grep -c "ProgressiveFade(child: SafeArea(" lib/features/auth/two_step_screen.dart` → 1
- `grep -c "AppSpace.lg + statusBar" lib/features/auth/two_step_screen.dart` → 1
- `grep -c "final minHeight = .* - statusBar;" lib/features/auth/two_step_screen.dart` → 1
- `grep -c "ProgressiveFade(child: SafeArea(" lib/features/auth/account_screen.dart` → 1
- `grep -c "AppSpace.lg + statusBar" lib/features/auth/account_screen.dart` → 1
- `grep -c "ProgressiveFade(child: SafeArea(" lib/features/settings/name_step.dart` → 1
- `grep -c "padding: EdgeInsets.only(top: statusBar)," lib/features/settings/name_step.dart` → 1
- `grep -c "ProgressiveFade(child: Center(" lib/features/workspaces/join_flow.dart` → 1
- `grep -c "top: false" lib/features/workspaces/join_flow.dart` → 3

The `flutter test` run in step 9 passes.

## Don't touch

- The pages listed as "checked and left alone" in "Where", and every page that has an app bar
  (`SubPage`, `ShellHeader`): their content scrolls under the bar, not the status bar.
- `FloatingMascots` on the sign-in page, the wallpaper (`lib/theme/wallpaper.dart`) and the
  `Scaffold` backgrounds: the mask fades content only. Never paint a solid color band over the top
  instead; it would cover the wallpaper.
- The bottom and side insets: leave whatever handles them now (the `SafeArea`, or `BottomPadding`
  with `bottom: false` if the home-indicator fix ran); only the top changes.
- Spacing and layout at rest: with the status bar's height moved into the scroll padding, every
  page must look exactly as before until it scrolls.
- No new strings: nothing user-facing changes, so `lib/l10n/app_en.arb` stays as is.
- If `lib/ui/glass/` exists when you run this, check whether any widget named above moved there;
  if it did, STOP and report instead of editing the old location.
- Never run `dart format` on existing files or on a directory, and run no git commands (the tree
  is shared; others commit).
- No new dependencies.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written), other than the differences listed under "Other fixes that touch
  the same code".
- The fix seems to require touching something in "Don't touch".
- A test in step 9 fails because of this change (a test that measures where a page's content sits
  with no status bar must see exactly the old position; if it doesn't, the inset was added twice
  or not removed from a minimum height).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: on the sign-in, two-step, new-password, name and invite pages,
content that scrolls up now slides under the status bar and dissolves there instead of being cut
at a hard line, while the pages look the same at rest; on a phone, open the two-step code page,
bring up the keyboard and scroll.
