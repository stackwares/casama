# Fix: Tall phone sheets slide up mechanically and look dated

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/adaptive-sheet-route
- **Needs new dependency**: `stupid_simple_sheet`, pinned exactly to `0.9.1+1` (the latest stable
  release, from 2026-03-12; it supports Flutter >=3.10 and Dart >=3.5, and this app is on Flutter
  3.47 / Dart 3.13). It is pure Dart and brings `motor` and `scroll_drag_detector`, all MIT
  licensed. The article's fix is this package: its glass sheet route gives the iOS 26 sheet, and its
  plain route is used on other platforms.

## Why

On phones, Casama's tall modals open with Material's `showModalBottomSheet(isScrollControlled: true)`:
search, the model and persona pickers, file previews, the conversation list, error details, Select
text, the skill library and update sheets, the provider app picker, and the wallpaper picker. They
slide up on a fixed curve and look like an older sheet style. On iOS they should look like iOS 26
sheets: fully rounded, smooth, and closed by pulling down from the top. A list that is scrolled to
the top should hand the pull to the sheet. On Android and other platforms they get the same smooth,
draggable sheet. They also get a close (X) at the top left, which is how modals that open from the
bottom are closed (not with a back arrow), so people who can't drag still have an obvious way out.

**Scope: tall sheets only.** These are sheets opened with `showAdaptiveSheet` **with** a
`heightFactor`: fixed-height, scrolling content, 12 call sites, listed below. Small sheets that
size to their content (forms, pickers, confirmations, no `heightFactor`) are out of scope here. A
separate change moves those to a spring sheet, so this plan leaves their code path exactly as it
is.

## Where

### 1. The shared opener (one change covers every tall sheet)

```dart
// lib/ui/adaptive_modal.dart:1-9 — current
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'form_sheet.dart';
```

```dart
// lib/ui/adaptive_modal.dart:12-50 — current
/// Opens [builder] as a bottom sheet on phones and as a centered dialog on larger windows, so
/// pickers and forms sit where each device expects them. [heightFactor] gives list-style content a
/// fixed height; leave it null for content that sizes itself.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? heightFactor,
  double dialogMaxWidth = 560,
  double dialogMaxHeight = 720,
}) {
  if (_compact(context)) {
    return showModalBottomSheet<T>(
      context: context,
      // Above the shell (the phone's floating tab bar), not inside the tab's navigator.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final view = MediaQuery.of(context);
        // The home-indicator inset is under the keyboard while it is open.
        final content = SafeArea(top: false, bottom: view.viewInsets.bottom == 0, child: builder(context));
        // Rises with the keyboard so the focused field and the main action stay visible.
        if (heightFactor == null) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
            child: content,
          );
        }
        final sheetHeight = (view.size.height - view.viewInsets.bottom) * heightFactor;
        return Padding(
          padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
          child: SizedBox(height: sheetHeight - kMinInteractiveDimension, child: content),
        );
      },
    );
  }
```

The `heightFactor != null` case (the `final sheetHeight = ...` part of that builder) is what this
plan moves to the new sheet. The `heightFactor == null` case stays on `showModalBottomSheet`
(unless the small-sheet change has already moved it, see "Steps").

Callers covered by this one change, with no edit needed (each passes `heightFactor:`):

- `lib/features/bots/model_picker.dart`: 61
- `lib/features/bots/template_picker.dart`: 58
- `lib/features/chat/chat_screen.dart`: 939
- `lib/features/chat/widgets/error_details.dart`: 44
- `lib/features/chat/widgets/message_actions.dart`: 39
- `lib/features/files/file_preview.dart`: 162
- `lib/features/integrations/provider_setup.dart`: 158
- `lib/features/search/search_view.dart`: 20
- `lib/features/settings/background_screen.dart`: 273
- `lib/features/skills/skill_catalog_screen.dart`: 209
- `lib/features/skills/skill_library.dart`: 18, 21

### 2. The dependency list

```yaml
# pubspec.yaml — current last dependency line (the new dependency goes directly below it)
  passkeys: ^2.24.1
```

```markdown
<!-- ../THIRD_PARTY_NOTICES.md (repo root) — current last client row of the Dart table -->
| mocktail                                                              | client (tooling)                   | MIT                           |
```

The repo root's `THIRD_PARTY_NOTICES.md` says: "Update this file in the same pull request that adds
or removes a dependency."

## The fix

The article's fix: an extension on `Widget` named `asAdaptiveSheetRoute`. On iOS it returns
`StupidSimpleGlassSheetRoute(child: this, blurBehindBarrier: false)`. Everywhere else it returns
`StupidSimpleSheetRoute(child: this)`. You push it with `Navigator.of(context).push(...)`. The
article's tip is applied as well: a close (X) at the top left. These are the only adaptations, each
needed in this app:

- The extension takes the `BuildContext`. It reads the app's sheet colour from the theme
  (`bottomSheetTheme.modalBackgroundColor`) for the glass sheet, so dark mode and the neutral
  surfaces match. The package default would be pure white or black. It also reads
  `MediaQuery.disableAnimationsOf`: with reduced motion the sheet uses `Motion.none()` and appears
  without sliding. Otherwise it passes the package's own default motion explicitly.
- The plain route has no background, so `TallSheet` draws one with the package's `SheetBackground`
  in the app's design (sheet colour, 28px top corners). It keeps today's height, `heightFactor` of
  the screen, never taller than the space under the status bar. The iOS glass sheet always fills
  the screen (that is the iOS 26 full-height look) and draws its own 36px rounded surface.
- `TallSheet` keeps what today's sheet does: content rises with the keyboard (`viewInsets`), the
  home-indicator inset is kept clear, and there is a 48px top strip with the drag handle (the
  theme's `dragHandleColor`), now with the X at the top left.
- It pushes on the root navigator, so the sheet covers the phone's floating tab bar as today, with
  the opening screen's themes captured (as `showModalBottomSheet` did).

## Steps

1. **STOP check first:** if the folder `lib/ui/glass/` exists, stop and report (see "STOP if").

2. Add the dependency. In `pubspec.yaml`, find the line `  passkeys: ^2.24.1` and add directly
   below it (exact pin, no caret):
   ```yaml
     stupid_simple_sheet: 0.9.1+1
   ```
   (If a line `  haptic_feedback: 0.8.0` was added there by another change, keep it. Put yours
   directly below `passkeys`.) Then run `flutter pub get` in `client/`.

3. In the repo root's `THIRD_PARTY_NOTICES.md` (one folder up from `client/`), find the row that
   starts `| mocktail ` and add this row directly below it, exactly:
   ```markdown
   | stupid_simple_sheet, motor, scroll_drag_detector                      | client                             | MIT                           |
   ```

4. Create `lib/ui/adaptive_sheet_route.dart` with exactly this content:

   ```dart
   import 'dart:math' as math;

   import 'package:flutter/foundation.dart';
   import 'package:flutter/material.dart';
   import 'package:lucide_icons_flutter/lucide_icons.dart';
   import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

   import '../theme/app_tokens.dart';

   extension AdaptiveSheetRouteX on Widget {
     /// This widget as a full-height modal that opens from the bottom: the iOS 26 glass sheet on iOS,
     /// the package's plain sheet everywhere else. Pulling it down from the top closes it.
     Route<T> asAdaptiveSheetRoute<T>(BuildContext context) {
       final bool isIos = defaultTargetPlatform == TargetPlatform.iOS;
       // Reduced motion: the sheet appears and leaves without sliding.
       final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

       if (isIos) {
         return StupidSimpleGlassSheetRoute<T>(
           child: this,
           blurBehindBarrier: false,
           backgroundColor: _sheetColor(Theme.of(context)),
           motion: reduceMotion ? const Motion.none() : const CupertinoMotion.smooth(duration: Duration(milliseconds: 350), snapToEnd: true),
         );
       } else {
         return StupidSimpleSheetRoute<T>(
           child: this,
           barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
           motion: reduceMotion ? const Motion.none() : const CupertinoMotion.smooth(snapToEnd: true),
         );
       }
     }
   }

   Color _sheetColor(ThemeData theme) => theme.bottomSheetTheme.modalBackgroundColor ?? theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow;

   /// The body of a tall sheet shown with [AdaptiveSheetRouteX.asAdaptiveSheetRoute]: a top bar with
   /// a close button and the drag handle, then [builder]'s content, kept clear of the keyboard. On iOS
   /// the glass sheet draws the surface and fills the screen. Elsewhere this draws the app's sheet
   /// surface (28px top corners) at [heightFactor] of the screen, as the bottom sheet did before.
   class TallSheet extends StatelessWidget {
     const TallSheet({super.key, required this.heightFactor, required this.builder});

     final double heightFactor;
     final WidgetBuilder builder;

     @override
     Widget build(BuildContext context) {
       final view = MediaQuery.of(context);
       final body = Material(
         type: MaterialType.transparency,
         child: Padding(
           // Rises with the keyboard so the field being typed in stays visible.
           padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               const _TallSheetTopBar(),
               Expanded(
                 // The home-indicator inset is under the keyboard while it is open.
                 child: SafeArea(top: false, bottom: view.viewInsets.bottom == 0, child: Builder(builder: builder)),
               ),
             ],
           ),
         ),
       );
       if (defaultTargetPlatform == TargetPlatform.iOS) return body;

       // Never taller than the space under the status bar.
       final sheetHeight = math.min((view.size.height - view.viewInsets.bottom) * heightFactor, view.size.height - view.padding.top - view.viewInsets.bottom);
       return MediaQuery.removePadding(
         context: context,
         removeTop: true,
         child: SheetBackground(
           backgroundColor: _sheetColor(Theme.of(context)),
           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
           child: SizedBox(height: sheetHeight + view.viewInsets.bottom, child: body),
         ),
       );
     }
   }

   /// A 48px strip: the close button at the top left (modals that open from the bottom close with an
   /// X, not a back arrow) and the drag handle in the middle.
   class _TallSheetTopBar extends StatelessWidget {
     const _TallSheetTopBar();

     @override
     Widget build(BuildContext context) {
       final theme = Theme.of(context);
       final handle = theme.bottomSheetTheme.dragHandleColor ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
       return SizedBox(
         height: kMinInteractiveDimension,
         child: Stack(
           alignment: Alignment.center,
           children: [
             Container(
               width: 32,
               height: 4,
               decoration: BoxDecoration(color: handle, borderRadius: const BorderRadius.all(Radius.circular(2))),
             ),
             PositionedDirectional(
               start: AppSpace.xxs,
               child: IconButton(
                 key: const Key('sheetClose'),
                 tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                 icon: const Icon(LucideIcons.x, size: 20),
                 onPressed: () => Navigator.of(context).maybePop(),
               ),
             ),
           ],
         ),
       );
     }
   }
   ```

   Then format only this new file: `dart format -l 200 lib/ui/adaptive_sheet_route.dart`.

5. In `lib/ui/adaptive_modal.dart`, add the import. Find the line `import '../theme/app_tokens.dart';`
   and add directly below it:
   ```dart
   import 'adaptive_sheet_route.dart';
   ```

6. In `lib/ui/adaptive_modal.dart`, inside `showAdaptiveSheet`, find the line
   `  if (_compact(context)) {` (2-space indent, directly followed by
   `    return showModalBottomSheet<T>(`). Insert this block **directly above** that line, exactly:
   ```dart
     // Phones, tall sheets with a fixed height (lists, search, previews): the modern full-height
     // sheet, closed with its X or by pulling it down from the top.
     if (_compact(context) && heightFactor != null) {
       // Above the shell (the phone's floating tab bar), with the themes of the screen that opened it.
       final navigator = Navigator.of(context, rootNavigator: true);
       final themes = InheritedTheme.capture(from: context, to: navigator.context);
       return navigator.push<T>(themes.wrap(TallSheet(heightFactor: heightFactor, builder: builder)).asAdaptiveSheetRoute<T>(context));
     }
   ```
   Notes:
   - If the function body already starts with a line `unfocusBeforeModal();` (or any other
     statement added by another change), keep it above your block.
   - If a block starting `  if (_compact(context) && heightFactor == null) {` is already there (the
     small-sheet change), keep it. Put your block directly above `  if (_compact(context)) {`, which
     means after that block. Don't change it.

7. **Only if** `lib/ui/adaptive_modal.dart` now contains **both** `if (_compact(context) && heightFactor != null) {`
   **and** `if (_compact(context) && heightFactor == null) {`: the old block can no longer run, so
   delete it. Delete exactly these lines (from `  if (_compact(context)) {` to its closing `  }`),
   and nothing else:
   ```dart
     if (_compact(context)) {
       return showModalBottomSheet<T>(
         context: context,
         // Above the shell (the phone's floating tab bar), not inside the tab's navigator.
         useRootNavigator: true,
         isScrollControlled: true,
         useSafeArea: true,
         showDragHandle: true,
         builder: (context) {
           final view = MediaQuery.of(context);
           // The home-indicator inset is under the keyboard while it is open.
           final content = SafeArea(top: false, bottom: view.viewInsets.bottom == 0, child: builder(context));
           // Rises with the keyboard so the focused field and the main action stay visible.
           if (heightFactor == null) {
             return AnimatedPadding(
               duration: const Duration(milliseconds: 120),
               curve: Curves.easeOut,
               padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
               child: content,
             );
           }
           final sheetHeight = (view.size.height - view.viewInsets.bottom) * heightFactor;
           return Padding(
             padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
             child: SizedBox(height: sheetHeight - kMinInteractiveDimension, child: content),
           );
         },
       );
     }
   ```
   If only your block is there, skip this step and leave the old block in place: it still opens
   the small sheets.

8. Create the test file `test/adaptive_sheet_route_test.dart` with exactly this content:

   ```dart
   import 'package:flutter/foundation.dart';
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';
   import 'package:casama_app/l10n/generated/app_localizations.dart';
   import 'package:casama_app/ui/adaptive_modal.dart';

   Widget _app() => MaterialApp(
     localizationsDelegates: AppLocalizations.localizationsDelegates,
     supportedLocales: AppLocalizations.supportedLocales,
     home: Scaffold(
       body: Builder(
         builder: (context) => Center(
           child: TextButton(
             key: const Key('openTall'),
             onPressed: () => showAdaptiveSheet<void>(
               context: context,
               heightFactor: 0.8,
               builder: (_) => ListView(children: [for (var i = 0; i < 40; i++) ListTile(key: Key('row$i'), title: Text('Row $i'))]),
             ),
             child: const Text('Open'),
           ),
         ),
       ),
     ),
   );

   Future<void> _phone(WidgetTester tester) async {
     tester.view.physicalSize = const Size(390, 844);
     tester.view.devicePixelRatio = 1;
     addTearDown(tester.view.reset);
   }

   void main() {
     testWidgets('a tall phone sheet closes with its X', (tester) async {
       await _phone(tester);
       await tester.pumpWidget(_app());
       await tester.tap(find.byKey(const Key('openTall')));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('row0')), findsOneWidget);
       expect(ModalRoute.of(tester.element(find.byKey(const Key('row0')))), isA<StupidSimpleSheetRoute<void>>());
       await tester.tap(find.byKey(const Key('sheetClose')));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('row0')), findsNothing);
     });

     testWidgets('a tall phone sheet closes when pulled down from the top', (tester) async {
       await _phone(tester);
       await tester.pumpWidget(_app());
       await tester.tap(find.byKey(const Key('openTall')));
       await tester.pumpAndSettle();
       await tester.timedDrag(find.byKey(const Key('row0')), const Offset(0, 500), const Duration(milliseconds: 400));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('row0')), findsNothing);
     });

     testWidgets('on iOS the tall sheet is the glass sheet', (tester) async {
       debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
       await _phone(tester);
       await tester.pumpWidget(_app());
       await tester.tap(find.byKey(const Key('openTall')));
       await tester.pumpAndSettle();
       expect(ModalRoute.of(tester.element(find.byKey(const Key('row0')))), isA<StupidSimpleGlassSheetRoute<void>>());
       await tester.tap(find.byKey(const Key('sheetClose')));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('row0')), findsNothing);
       debugDefaultTargetPlatformOverride = null;
     });
   }
   ```

   Then format only this new file: `dart format -l 200 test/adaptive_sheet_route_test.dart`.

9. Run `flutter test test/adaptive_sheet_route_test.dart`. All 3 tests must pass.

10. Run the sheet-heavy tests and the phone layout test:
    `flutter test test/search_test.dart test/create_menu_test.dart test/bot_profile_test.dart test/board_test.dart test/skill_library_test.dart test/files_test.dart test/phone_layout_test.dart`.
    All must pass.

11. Run the whole suite: `flutter test`. Compare with a run from before your change if you have
    one. Nothing that passed before may fail now.

12. Build once for each mobile platform to be sure the new package resolves:
    `flutter build apk --debug` and `flutter build ios --debug --no-codesign`.

## Check it

- `dart analyze lib/ui/adaptive_sheet_route.dart lib/ui/adaptive_modal.dart test/adaptive_sheet_route_test.dart` reports no issues.
- `grep -c "stupid_simple_sheet: 0.9.1+1" pubspec.yaml` → `1`
- `grep -c "if (_compact(context) && heightFactor != null) {" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "asAdaptiveSheetRoute<T>(context)" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "import 'adaptive_sheet_route.dart';" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "StupidSimpleGlassSheetRoute<T>(" lib/ui/adaptive_sheet_route.dart` → `1`
- `grep -c "blurBehindBarrier: false" lib/ui/adaptive_sheet_route.dart` → `1`
- `grep -c "stupid_simple_sheet, motor, scroll_drag_detector" ../THIRD_PARTY_NOTICES.md` → `1`
- `flutter test test/adaptive_sheet_route_test.dart` passes.

## Don't touch

- The dialog branch of `showAdaptiveSheet` (`return showDialog<T>(...)`, used on windows 700px
  wide and up): unchanged. File preview's own close button, shown only on larger windows, stays.
- The small-sheet path (`heightFactor == null`): don't move it to this route. Small sheets that
  size to their content get a different sheet (a separate change). Don't remove the old
  `showModalBottomSheet` block unless step 7 says so.
- `lib/features/voice/call_screen.dart`'s `showModalBottomSheet` (a small sheet, not full-height):
  not this plan.
- The 12 callers listed in "Where": no edits. Keep their `heightFactor` values.
- Don't add a `ScrollConfiguration` anywhere inside sheets. The package needs Flutter's default
  scroll behaviour to hand a pull from a list to the sheet.
- `lib/theme/app_theme.dart`: unchanged (the sheet reads its colours from it).
- Existing widget `Key`s: keep them all.
- No other new dependencies. No refactors, renames, or cleanups beyond the fix.
- Don't run `dart format` on existing files or folders (only on the files this plan creates). No
  git commands (shared tree; others commit).

## STOP if

- The folder `lib/ui/glass/` exists. The approved "Liquid Glass" redesign has started and sheets
  now belong to its glass adapters. Report back instead of editing `adaptive_modal.dart`, so the
  change goes into the adapter.
- The code at any location in "Where" doesn't match the quoted excerpt, beyond lines added by the
  related sheet or unfocus changes described in step 6 (the codebase moved on since this plan was
  written).
- `flutter pub get` fails to resolve `stupid_simple_sheet: 0.9.1+1`, or a mobile build fails
  because of it.
- `lib/ui/adaptive_sheet_route.dart` already exists.
- The fix seems to require touching something in "Don't touch".
- A test that passed before your change fails after it, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: "Tall sheets on phones (search, pickers, previews) now open as modern
sheets: the iOS 26 glass sheet on iPhone and a smooth draggable sheet elsewhere. Pull down from the
top to close one, or tap the X at its top left. On a phone, open search from the home screen and
pull it down."
