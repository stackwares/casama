# Fix: Selected text in dark mode washes out, and the selection colours are left to a library default

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/selection-color
- **Needs new dependency**: none

## Why

Casama never sets its own text-selection colours. Today the cursor, the selection highlight and the
drag handles come from FlexColorScheme's hidden default: the accent at 30% in light mode but at
**50% in dark mode**. A highlight that strong sits behind light text and washes it out. With the
Black & White scheme the text over a dark-mode selection drops to about 2.5:1 contrast, and with
Casama's own plum to about 3.8:1. The app should own these colours in its theme: the accent at 30%
behind selected text in both modes, so text over the highlight stays at 4.5:1 or better on every
scheme, and the full accent for the cursor and the handles. Every field, every `SelectableText` and
the chat's `SelectionArea` on iOS, Android, desktop and web then follows the accent you pick, in
light and dark.

## Where

There is one shared choke point: the theme every appearance is built from. `AppTheme._finish`
builds the final `ThemeData` for each scheme, font and light/dark combination, and it never sets
`textSelectionTheme`.

```dart
// lib/theme/app_theme.dart:100-116 — current (the values the new code uses are already here)
  static ThemeData _finish(ThemeData base, Appearance appearance) {
    final wallpaper = appearance.wallpaper;
    TextTheme typography(TextTheme t) => _typography(t, heading: appearance.headingFont, body: appearance.bodyFont);
    final scheme = base.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final textTheme = typography(base.textTheme).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final sheetColor = isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest;
    final selectedTint = Color.alphaBlend(scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14), sheetColor);
    final fieldFill = isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.hairline),
    );

    return base.copyWith(
      colorScheme: scheme,
```

```dart
// lib/theme/app_theme.dart:144-146 — current (where the new entry goes)
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
```

How it reaches everything: `MaterialApp` turns `theme.textSelectionTheme` into the app-wide
`DefaultSelectionStyle`, used by `SelectableText` and `SelectionArea` (for example
`lib/features/chat/widgets/chat_markdown.dart:60` and `lib/features/chat/widgets/message_actions.dart:97`).
`TextField` reads the same theme on Android and desktop, and on iOS too: Material's Cupertino bridge
takes the handle colour from `textSelectionTheme.selectionHandleColor` and uses `cursorColor` and
`selectionColor` before its own defaults. So one entry in the theme covers all of them.

## The fix

The article's fix, applied to this codebase: add `textSelectionTheme` to the `ThemeData`. Use the
accent with some opacity for the selection, and the full accent for the cursor and the handles.
Here the accent is `scheme.primary`, which follows whatever scheme the person picks (and gallery
schemes), so no colour is hard-coded.

```dart
// target: lib/theme/app_theme.dart, inside base.copyWith(...), right after dividerTheme
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),
      // Text selection in the accent: a 30% highlight behind selected text (text over it stays
      // readable in light and dark, whatever the scheme), the full accent for the cursor and handles.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: scheme.primary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
```

Why one value, 0.3, for both modes: worked out over a light field (white) and a dark one (#1E1E22),
with the body text colours. Light mode at 0.3 keeps text at 8:1 or better, even for the
black-accent scheme. Dark mode at 0.3 keeps text at 4.7:1 or better, even for the white-accent
scheme (it was 2.5:1 at today's 0.5). Don't use `isDark` here.

Match how this file already writes sub-themes: a named argument inside `base.copyWith(...)` built
from `scheme`, like `dividerTheme` and `listTileTheme` right next to it.

## Steps

1. Open `lib/theme/app_theme.dart`. Find the line
   `      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),`
   (inside `return base.copyWith(` in `_finish`). Directly below it, insert these lines exactly
   (6-space indent, like the lines around them):
   ```dart
         // Text selection in the accent: a 30% highlight behind selected text (text over it stays
         // readable in light and dark, whatever the scheme), the full accent for the cursor and handles.
         textSelectionTheme: TextSelectionThemeData(
           cursorColor: scheme.primary,
           selectionColor: scheme.primary.withValues(alpha: 0.3),
           selectionHandleColor: scheme.primary,
         ),
   ```
   No new import is needed: `TextSelectionThemeData` comes from `package:flutter/material.dart`,
   which the file already imports. Edit by hand. Do NOT run `dart format` on this file.

2. Create the test file `test/selection_color_test.dart` with exactly this content:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/theme/app_theme.dart';
   import 'package:casama_app/theme/appearance.dart';

   void main() {
     void expectAccentSelection(ThemeData theme) {
       final primary = theme.colorScheme.primary;
       expect(theme.textSelectionTheme.cursorColor, primary);
       expect(theme.textSelectionTheme.selectionHandleColor, primary);
       expect(theme.textSelectionTheme.selectionColor, primary.withValues(alpha: 0.3));
     }

     testWidgets('text selection follows the accent in light and dark', (tester) async {
       expectAccentSelection(AppTheme.light());
       expectAccentSelection(AppTheme.dark());
       const blackWhite = Appearance(schemeId: 'blackWhite');
       expectAccentSelection(AppTheme.light(blackWhite));
       expectAccentSelection(AppTheme.dark(blackWhite));
     });

     testWidgets('selectable text gets the theme selection colour', (tester) async {
       final theme = AppTheme.dark();
       late Color selection;
       await tester.pumpWidget(MaterialApp(
         theme: theme,
         home: Builder(builder: (context) {
           selection = DefaultSelectionStyle.of(context).selectionColor!;
           return const SelectableText('hello');
         }),
       ));
       expect(selection, theme.colorScheme.primary.withValues(alpha: 0.3));
     });
   }
   ```
   Then format only this new file: `dart format -l 200 test/selection_color_test.dart`.

3. Run `flutter test test/selection_color_test.dart`. Both tests must pass.

4. Run the existing theme tests: `flutter test test/design_test.dart test/phone_layout_test.dart`.
   They must pass as before.

## Check it

- `dart analyze lib/theme/app_theme.dart test/selection_color_test.dart` reports no issues.
- `grep -c "textSelectionTheme: TextSelectionThemeData(" lib/theme/app_theme.dart` → `1`
- `grep -c "selectionColor: scheme.primary.withValues(alpha: 0.3)," lib/theme/app_theme.dart` → `1`
- `grep -c "selectionHandleColor: scheme.primary," lib/theme/app_theme.dart` → `1`
- `flutter test test/selection_color_test.dart` passes.

## Don't touch

- `lib/ui/otp_code_field.dart:214-218`: its local `TextSelectionTheme` with transparent
  selection and cursor is on purpose (the code boxes draw their own caret). Leave it.
- `FlexSubThemesData` in `_subThemes` (`lib/theme/app_theme.dart:12-40`): don't add
  `inputSelectionOpacity`, `inputCursorSchemeColor` or other FlexColorScheme selection options. The
  app sets the theme itself in `_finish`, which comes after FlexColorScheme and wins.
- Don't set `cupertinoOverrideTheme`. Material already passes these colours to iOS.
- No per-widget `cursorColor:` or `selectionColor:` on any field.
- No new dependencies.
- No refactors, renames, or cleanups beyond the fix.
- Don't run `dart format` on existing files or folders, and no git commands (the tree is shared and
  other people commit).

## STOP if

- The code in "Where" doesn't match the quoted lines (the codebase moved on since this plan was
  written). Line numbers that shifted a little are fine if the text is the same.
- `lib/theme/app_theme.dart` already has a `textSelectionTheme:` entry.
- The fix seems to need a change in a file listed in "Don't touch".
- A test that passed before your change now fails because of it, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: "Text selection now follows the accent in every scheme. The highlight
is a softer 30% in dark mode, so selected text stays readable, and the cursor and handles are the
full accent. Switch to dark mode, open a chat, long-press a message, choose Select text and drag
across a few words."
