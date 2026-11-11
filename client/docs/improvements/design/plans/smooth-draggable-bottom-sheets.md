# Fix: Phone sheets slide in and out mechanically and don't follow your finger

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-draggable-bottom-sheets
- **Needs new dependency**: none

## Why

On phones, every form, picker and confirmation in Casama opens with Material's
`showModalBottomSheet`, which slides in and out on a fixed curve. It feels mechanical, and a flick
down doesn't carry its speed into the close. These sheets should feel smooth: open on a spring,
follow the finger while dragged, keep the speed of a fling, and settle like a spring. The fix is a
spring-driven sheet route. Every small sheet that sizes to its content goes through it, and it
keeps today's look: the app's sheet colour, 28px top corners, a drag handle, rising with the
keyboard, and the dimmed area behind.

**Scope: small sheets only.** These are the sheets opened with `showAdaptiveSheet` **without** a
`heightFactor`, plus `showConfirm`, `showTextPrompt` and `showChoiceSheet`, and the call screen's
audio-output picker. Tall sheets that pass a `heightFactor` (scrolling lists, search, previews)
are out of scope here. A separate change gives those a full-height sheet, so this plan leaves their
code path exactly as it is.

## Where

### 1. The shared opener (one change covers almost every small sheet)

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

The `heightFactor == null` branch inside that `showModalBottomSheet` builder is the small-sheet
case this plan moves to the spring sheet. The `heightFactor != null` case stays on
`showModalBottomSheet` (unless the tall-sheet change has already moved it, see "Steps").

Callers covered by this one change, with no edit needed (file: line of each content-sized
`showAdaptiveSheet` call):

- `lib/core/mac_bridge.dart`: 51
- `lib/core/server_address.dart`: 55
- `lib/features/admin/admin_screen.dart`: 249, 427
- `lib/features/auth/account_screen.dart`: 249
- `lib/features/auth/sign_in_screen.dart`: 30, 304, 700
- `lib/features/billing/billing_screen.dart`: 459
- `lib/features/board/board_screen.dart`: 88, 104, 428
- `lib/features/bots/action_rules_screen.dart`: 53
- `lib/features/bots/agent_import.dart`: 29
- `lib/features/bots/bot_history_screen.dart`: 178
- `lib/features/bots/bot_profile_screen.dart`: 539, 648
- `lib/features/bots/bot_template.dart`: 28
- `lib/features/bots/bots_screen.dart`: 265, 334
- `lib/features/bots/channels_screen.dart`: 77, 83, 116
- `lib/features/bots/knowledge_screen.dart`: 39
- `lib/features/bots/links_screen.dart`: 34, 101
- `lib/features/bots/plugins_screen.dart`: 28, 75
- `lib/features/chat/chat_screen.dart`: 349
- `lib/features/companion/companion_screen.dart`: 263
- `lib/features/computer/computers_screen.dart`: 24
- `lib/features/computer/live_view_screen.dart`: 188, 283, 342
- `lib/features/groups/group_chats.dart`: 42
- `lib/features/inbox/inbox_screen.dart`: 554
- `lib/features/integrations/connect_app_sheet.dart`: 21
- `lib/features/integrations/integrations_screen.dart`: 96
- `lib/features/integrations/provider_setup.dart`: 41
- `lib/features/memory/memory_screen.dart`: 22, 45
- `lib/features/notifications/checkins_sheet.dart`: 17
- `lib/features/notifications/quiet_hours.dart`: 25, 50
- `lib/features/pages/pages_screen.dart`: 87
- `lib/features/privacy/privacy_screen.dart`: 64, 71
- `lib/features/projects/projects_screen.dart`: 88
- `lib/features/routines/routines_screen.dart`: 62, 70
- `lib/features/settings/about_you_screen.dart`: 79, 99
- `lib/features/settings/gallery_screen.dart`: 508
- `lib/features/settings/password_managers_screen.dart`: 33, 35, 65
- `lib/features/settings/settings_screen.dart`: 130
- `lib/features/settings/themes_screen.dart`: 31, 42
- `lib/features/skills/skill_catalog_screen.dart`: 243
- `lib/features/skills/skills_screen.dart`: 30, 133
- `lib/features/usage/usage_screen.dart`: 545
- `lib/features/workspaces/join_flow.dart`: 581
- `lib/features/workspaces/people_screen.dart`: 297
- `lib/features/workspaces/spaces.dart`: 129, 178, 200, 549, 720, 850, 991
- `lib/features/workspaces/workspace_files.dart`: 45, 52, 54
- `lib/ui/adaptive_modal.dart`: 86
- `lib/ui/form_sheet.dart`: 255

Also covered: every `showConfirm`, `showTextPrompt` and `showChoiceSheet` call (they go through
`showAdaptiveSheet` without a `heightFactor`, in `lib/ui/adaptive_modal.dart:86` and
`lib/ui/form_sheet.dart:255` and `:371`):

- `lib/features/auth/account_screen.dart`: 221, 268, 347
- `lib/features/auth/passkeys_screen.dart`: 44, 59
- `lib/features/auth/two_step_screen.dart`: 91, 110
- `lib/features/billing/billing_screen.dart`: 54, 443, 495
- `lib/features/board/board_screen.dart`: 686
- `lib/features/bots/bot_history_screen.dart`: 79
- `lib/features/bots/bot_profile_screen.dart`: 320, 487, 713, 849, 872
- `lib/features/bots/links_screen.dart`: 222
- `lib/features/bots/plugins_screen.dart`: 83
- `lib/features/chat/chat_screen.dart`: 53
- `lib/features/computer/computer_screen.dart`: 892
- `lib/features/computer/computers_screen.dart`: 100, 111
- `lib/features/devices/device_connections_screen.dart`: 327
- `lib/features/integrations/integration_detail_screen.dart`: 47
- `lib/features/mcp/mcp_screens.dart`: 164, 189
- `lib/features/memory/memory_screen.dart`: 33
- `lib/features/notifications/quiet_hours.dart`: 35
- `lib/features/pages/pages_screen.dart`: 73, 92
- `lib/features/routines/routines_screen.dart`: 124
- `lib/features/settings/about_you_screen.dart`: 91
- `lib/features/settings/model_keys_screen.dart`: 474
- `lib/features/settings/secrets_screen.dart`: 70
- `lib/features/settings/settings_screen.dart`: 308
- `lib/features/settings/themes_screen.dart`: 99
- `lib/features/skills/skills_screen.dart`: 232
- `lib/features/teach/teach_draft_screen.dart`: 93
- `lib/features/workspaces/people_screen.dart`: 177, 621
- `lib/features/workspaces/spaces.dart`: 506

### 2. The one direct `showModalBottomSheet` call (a small list, no scrolling)

```dart
// lib/features/voice/call_screen.dart:322-356 — current
    } else {
      pick = await showModalBottomSheet<CallRoute>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  0,
                  AppSpace.lg,
                  AppSpace.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.callAudioOutput,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ),
              for (final r in available)
                ListTile(
                  key: Key('callRoute-${r.kind.name}-${r.id}'),
                  leading: Icon(_routeIcon(r.kind)),
                  title: Text(_routeName(context, r)),
                  trailing: r == _route ? const Icon(LucideIcons.check) : null,
                  onTap: () => Navigator.pop(context, r),
                ),
            ],
          ),
        ),
      );
```

```dart
// lib/features/voice/call_screen.dart:16-20 — current imports (the new import goes after shell_header)
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
```

## The fix

The article's fix: copy its file into the app and call `showSpringBottomSheet`, which has the same
shape as `showModalBottomSheet`. The route wraps the content in `SheetContainer`, which supplies
the background colour, the rounded top corners and a `Material`, so modals don't repeat them. You
edit it once to match the design. The article's code is kept as is (springs, overdrag resistance,
close thresholds, clamped scrim). These are the only adaptations, each needed in this app:

- `useRootNavigator` (default `false`): `showAdaptiveSheet` passes `true` so sheets cover the
  phone's floating tab bar, as they do today.
- Theme capture: a sheet on the root navigator still gets the themes of the screen that opened it,
  as `showModalBottomSheet` did.
- `SafeArea` at the top and a 640px max width: the sheet never goes under the status bar, like
  today's `useSafeArea: true` sheet.
- Reduced motion: when `MediaQuery.disableAnimationsOf` is on, the sheet appears and leaves
  without moving.
- `SheetContainer` in this app's design: the theme's sheet colour
  (`bottomSheetTheme.modalBackgroundColor`), 28px top corners, and today's drag handle (a 32x4
  grabber in a 48px strip, the theme's `dragHandleColor`). The coloured surface is the `Material`
  itself rather than a `ColoredBox` over a transparent `Material`. With a `ColoredBox`, Flutter
  asserts in debug that list tiles in the sheet would lose their ink splash.
- Accessibility kept from Material's sheet: the route is a named semantics scope ("Bottom sheet"),
  the scrim reads "Dismiss", and the drag handle is a "Dismiss" button for screen readers.

A scrollable inside steals the drag. In this app a form's scroll view only claims drags once its
content is taller than the sheet (for example with the keyboard open). Even then, the drag handle
strip at the top still drags the sheet.

## Steps

1. **STOP check first:** if the folder `lib/ui/glass/` exists, stop and report (see "STOP if").

2. Create `lib/ui/spring_sheet.dart` with exactly this content:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter/physics.dart';

   /// Shows a modal sheet anchored to the bottom edge of the screen.
   ///
   /// A spring-driven replacement for showModalBottomSheet. The sheet enters
   /// and exits on smooth springs, and dragging it drives the route animation
   /// directly, so the velocity of a released fling is carried into the open
   /// or close spring.
   ///
   /// The sheet surface comes from [SheetContainer]; the widget returned by
   /// [builder] brings only its content and padding. Build it on a Column with
   /// mainAxisSize: MainAxisSize.min so the sheet is only as tall as its content.
   ///
   /// [useRootNavigator] puts the sheet above everything, the phone's floating
   /// tab bar included, like the showModalBottomSheet argument of the same name.
   ///
   /// Returns a [Future] that resolves to the value passed to [Navigator.pop]
   /// when the sheet is closed.
   Future<T?> showSpringBottomSheet<T>({
     required BuildContext context,
     required WidgetBuilder builder,
     bool useRootNavigator = false,
   }) {
     final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
     return navigator.push(
       SpringSheetRoute<T>(
         builder: builder,
         // A sheet on the root navigator still gets the themes of the screen that opened it.
         capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
         barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
       ),
     );
   }

   /// A route that shows a spring-driven modal sheet at the bottom of the
   /// screen.
   class SpringSheetRoute<T> extends PopupRoute<T> {
     SpringSheetRoute({
       required this.builder,
       this.capturedThemes,
       this.barrierLabel,
       super.settings,
     });

     /// Builds the content of the sheet.
     final WidgetBuilder builder;

     /// The themes of the screen that opened the sheet.
     final CapturedThemes? capturedThemes;

     /// What screen readers call the dimmed area behind the sheet.
     @override
     final String? barrierLabel;

     // SwiftUI's .smooth spring written out as plain numbers: critically
     // damped, stiffness 4pi^2 / duration^2, at 300ms in and 200ms out.
     static const SpringDescription _enterSpring = SpringDescription(
       mass: 1,
       stiffness: 438.6,
       damping: 41.9,
     );
     static const SpringDescription _exitSpring = SpringDescription(
       mass: 1,
       stiffness: 987.0,
       damping: 62.8,
     );

     // Resistance applied when dragging past fully open.
     static const double _overdragResistance = 100;

     // Thresholds past which a released drag closes the sheet: fling speed in
     // sheet heights per second, or resting position as a fraction of height.
     static const double _closeVelocity = 0.9;
     static const double _closePosition = 0.5;

     // The widest the sheet grows, like Material's bottom sheet.
     static const double _maxWidth = 640;

     // Release velocity in sheet heights per second (positive is downward),
     // carried from the drag into the close simulation.
     double? _releaseVelocity;

     bool _popped = false;

     @override
     Color? get barrierColor => const Color(0x8A000000);

     @override
     bool get barrierDismissible => true;

     @override
     Duration get transitionDuration => const Duration(milliseconds: 300);

     @override
     Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

     // When the system asks to reduce motion, the sheet appears and leaves
     // without moving.
     bool get _reduceMotion {
       final BuildContext? context = navigator?.context;
       return context != null && (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
     }

     // The scrim fades with the clamped animation so that dragging past fully
     // open does not push the barrier curve out of range. The slide reads the
     // raw controller.
     @override
     Animation<double>? get animation {
       final Animation<double>? raw = super.animation;
       if (raw == null) return null;

       return _ClampedAnimation(raw);
     }

     @override
     AnimationController createAnimationController() {
       return AnimationController.unbounded(
         duration: transitionDuration,
         reverseDuration: reverseTransitionDuration,
         vsync: navigator!,
       );
     }

     @override
     Simulation? createSimulation({required bool forward}) {
       final double velocity = _releaseVelocity ?? 0;
       _releaseVelocity = null;
       final double target = forward ? 1 : 0;
       if (_reduceMotion) return _InstantSimulation(target);

       return SpringSimulation(
         forward ? _enterSpring : _exitSpring,
         controller?.value ?? 0,
         target,
         -velocity,
         snapToEnd: true,
       );
     }

     @override
     bool didPop(T? result) {
       _popped = true;

       return super.didPop(result);
     }

     void _dragBy(double relativeDelta) {
       if (_popped) return;

       final AnimationController controller = this.controller!;

       double delta = relativeDelta;
       if (controller.value > 1) {
         final double overshoot = controller.value - 1;
         delta *= 1 / (1 + overshoot * _overdragResistance);
       }
       controller.value -= delta;
     }

     void _endDrag(double relativeVelocity) {
       if (_popped) return;
       final AnimationController controller = this.controller!;
       final double value = controller.value;

       if (value > 1) {
         // Dragged past fully open. Settle back, damping the velocity by the
         // same resistance that was applied while dragging.
         final double overshoot = value - 1;
         final double damped = relativeVelocity / (1 + overshoot * _overdragResistance);
         _settle(value, damped);

         return;
       }

       final bool close = switch (relativeVelocity) {
         > _closeVelocity => true,
         < -_closeVelocity => false,
         _ => value < _closePosition,
       };

       if (close) {
         _releaseVelocity = relativeVelocity;
         navigator?.pop();
       } else {
         _settle(value, relativeVelocity);
       }
     }

     // Springs back to fully open from [from], carrying [velocity].
     void _settle(double from, double velocity) {
       controller!.animateWith(
         _reduceMotion ? _InstantSimulation(1) : SpringSimulation(_enterSpring, from, 1, -velocity, snapToEnd: true),
       );
     }

     @override
     Widget buildPage(
       BuildContext context,
       Animation<double> animation,
       Animation<double> secondaryAnimation,
     ) {
       final Widget sheet = Align(
         alignment: Alignment.bottomCenter,
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxWidth: _maxWidth),
           child: AnimatedBuilder(
             animation: controller!,
             builder: (context, child) {
               return FractionalTranslation(
                 translation: Offset(0, 1 - controller!.value),
                 child: child,
               );
             },
             child: Builder(
               builder: (context) {
                 // Drag deltas are normalized by the sheet's own height, so the
                 // gesture and the route animation share one coordinate space.
                 double height() => context.size?.height ?? 1;

                 return GestureDetector(
                   excludeFromSemantics: true,
                   onVerticalDragUpdate: (details) {
                     _dragBy(details.primaryDelta! / height());
                   },
                   onVerticalDragEnd: (details) {
                     _endDrag(details.velocity.pixelsPerSecond.dy / height());
                   },
                   onVerticalDragCancel: () {
                     _endDrag(0);
                   },
                   child: SizedBox(
                     width: double.infinity,
                     child: Semantics(
                       scopesRoute: true,
                       namesRoute: true,
                       explicitChildNodes: true,
                       label: MaterialLocalizations.of(context).bottomSheetLabel,
                       child: SheetContainer(
                         child: builder(context),
                       ),
                     ),
                   ),
                 );
               },
             ),
           ),
         ),
       );
       // Never under the status bar or the notch, however tall the content gets.
       final Widget safe = SafeArea(left: false, right: false, bottom: false, child: sheet);

       return capturedThemes?.wrap(safe) ?? safe;
     }
   }

   /// The surface for sheets shown with [showSpringBottomSheet]: the app's sheet
   /// colour, 28px rounded top corners and a drag handle, so the content brings
   /// only itself and its padding.
   class SheetContainer extends StatelessWidget {
     const SheetContainer({
       super.key,
       required this.child,
     });

     final Widget child;

     @override
     Widget build(BuildContext context) {
       final ThemeData theme = Theme.of(context);
       final BottomSheetThemeData sheetTheme = theme.bottomSheetTheme;

       // The coloured surface is the Material itself, so list tiles and buttons in the sheet show
       // their ink on it (a ColoredBox over a transparent Material would hide it).
       return Material(
         color: sheetTheme.modalBackgroundColor ?? sheetTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
         shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(
             top: Radius.circular(28),
           ),
         ),
         clipBehavior: Clip.antiAlias,
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             _DragHandle(color: sheetTheme.dragHandleColor ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
             Flexible(child: child),
           ],
         ),
       );
     }
   }

   /// The 32x4 grabber at the top of the sheet, in a 48px strip. Screen readers
   /// get a "Dismiss" button here, as on Material's sheet.
   class _DragHandle extends StatelessWidget {
     const _DragHandle({required this.color});

     final Color color;

     @override
     Widget build(BuildContext context) {
       return Semantics(
         label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
         button: true,
         onTap: () => Navigator.of(context).maybePop(),
         child: SizedBox(
           height: kMinInteractiveDimension,
           child: Center(
             child: Container(
               width: 32,
               height: 4,
               decoration: BoxDecoration(
                 color: color,
                 borderRadius: const BorderRadius.all(Radius.circular(2)),
               ),
             ),
           ),
         ),
       );
     }
   }

   /// An animation that forwards [parent] with its value clamped to the range
   /// 0.0 to 1.0, for consumers such as the modal barrier that should not see
   /// values past fully open.
   class _ClampedAnimation extends Animation<double> with AnimationWithParentMixin<double> {
     _ClampedAnimation(this.parent);

     @override
     final Animation<double> parent;

     @override
     double get value => parent.value.clamp(0.0, 1.0);
   }

   /// Sits at [target] from the first frame, for reduced motion.
   class _InstantSimulation extends Simulation {
     _InstantSimulation(this.target);

     final double target;

     @override
     double x(double time) => target;

     @override
     double dx(double time) => 0;

     @override
     bool isDone(double time) => true;
   }
   ```

   Then format only this new file: `dart format -l 200 lib/ui/spring_sheet.dart`.

3. In `lib/ui/adaptive_modal.dart`, add the import. Find the line `import 'form_sheet.dart';` and
   add directly below it:
   ```dart
   import 'spring_sheet.dart';
   ```
   (If an `import 'adaptive_sheet_route.dart';` line is there too, leave it where it is.)

4. In `lib/ui/adaptive_modal.dart`, inside `showAdaptiveSheet`, find the line
   `  if (_compact(context)) {` (2-space indent, directly followed by
   `    return showModalBottomSheet<T>(`). Insert this block **directly above** that line, exactly:
   ```dart
     // Phones, content-sized sheets (forms, pickers, confirmations): a spring-driven sheet that
     // follows the finger and closes with a flick down.
     if (_compact(context) && heightFactor == null) {
       return showSpringBottomSheet<T>(
         context: context,
         // Above the shell (the phone's floating tab bar), not inside the tab's navigator.
         useRootNavigator: true,
         builder: (context) {
           final view = MediaQuery.of(context);
           // Rises with the keyboard so the focused field and the main action stay visible. The
           // home-indicator inset is under the keyboard while it is open.
           return AnimatedPadding(
             duration: AppMotion.of(context, const Duration(milliseconds: 120)),
             curve: Curves.easeOut,
             padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
             child: SafeArea(top: false, bottom: view.viewInsets.bottom == 0, child: builder(context)),
           );
         },
       );
     }
   ```
   Notes:
   - If the function body already starts with a line `unfocusBeforeModal();` (or any other
     statement added by another change), keep it above your block. Your block goes directly above
     `  if (_compact(context)) {`.
   - If a block starting `  if (_compact(context) && heightFactor != null) {` is already there (the
     tall-sheet change), keep it. Put your block directly above `  if (_compact(context)) {`, which
     means after that block. Don't change it.
   - `AppMotion` comes from `../theme/app_tokens.dart`, which this file already imports.

5. **Only if** `lib/ui/adaptive_modal.dart` now contains **both** `if (_compact(context) && heightFactor == null) {`
   **and** `if (_compact(context) && heightFactor != null) {`: the old block can no longer run, so
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
   the tall sheets.

6. In `lib/features/voice/call_screen.dart`, add the import. Find the line
   `import '../../ui/shell_header.dart';` and add directly below it:
   ```dart
   import '../../ui/spring_sheet.dart';
   ```

7. In `lib/features/voice/call_screen.dart`, replace these three lines (they are at about line 323):
   ```dart
         pick = await showModalBottomSheet<CallRoute>(
           context: context,
           showDragHandle: true,
   ```
   with these two lines:
   ```dart
         pick = await showSpringBottomSheet<CallRoute>(
           context: context,
   ```
   Leave the `builder:` and everything after it unchanged. `SheetContainer` now draws the drag
   handle, so `showDragHandle` goes away.

8. Create the test file `test/spring_sheet_test.dart` with exactly this content:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/l10n/generated/app_localizations.dart';
   import 'package:casama_app/ui/adaptive_modal.dart';
   import 'package:casama_app/ui/spring_sheet.dart';

   Widget _app({bool reduceMotion = false}) => MaterialApp(
     localizationsDelegates: AppLocalizations.localizationsDelegates,
     supportedLocales: AppLocalizations.supportedLocales,
     builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion), child: child!),
     home: Scaffold(
       body: Builder(
         builder: (context) => Center(
           child: TextButton(
             key: const Key('openSheet'),
             onPressed: () => showAdaptiveSheet<void>(
               context: context,
               builder: (_) => const Padding(padding: EdgeInsets.all(24), child: Text('Sheet body', key: Key('sheetBody'))),
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
     testWidgets('a phone sheet opens on a spring and closes with a drag down', (tester) async {
       await _phone(tester);
       await tester.pumpWidget(_app());
       await tester.tap(find.byKey(const Key('openSheet')));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('sheetBody')), findsOneWidget);
       expect(find.byType(SheetContainer), findsOneWidget);
       expect(find.byType(BottomSheet), findsNothing);

       await tester.drag(find.byKey(const Key('sheetBody')), const Offset(0, 300));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('sheetBody')), findsNothing);
     });

     testWidgets('a small drag springs back, a tap outside closes', (tester) async {
       await _phone(tester);
       await tester.pumpWidget(_app());
       await tester.tap(find.byKey(const Key('openSheet')));
       await tester.pumpAndSettle();
       final open = tester.getTopLeft(find.byKey(const Key('sheetBody')));
       await tester.drag(find.byKey(const Key('sheetBody')), const Offset(0, 20));
       await tester.pumpAndSettle();
       expect(tester.getTopLeft(find.byKey(const Key('sheetBody'))), open);

       await tester.tapAt(const Offset(10, 10));
       await tester.pumpAndSettle();
       expect(find.byKey(const Key('sheetBody')), findsNothing);
     });

     testWidgets('with reduced motion the sheet is in place on the next frame', (tester) async {
       await _phone(tester);
       await tester.pumpWidget(_app(reduceMotion: true));
       await tester.tap(find.byKey(const Key('openSheet')));
       await tester.pump();
       await tester.pump();
       final first = tester.getTopLeft(find.byKey(const Key('sheetBody')));
       await tester.pumpAndSettle();
       expect(tester.getTopLeft(find.byKey(const Key('sheetBody'))), first);
     });
   }
   ```

   Then format only this new file: `dart format -l 200 test/spring_sheet_test.dart`.

9. Run `flutter test test/spring_sheet_test.dart`. All 3 tests must pass.

10. Run the sheet-heavy tests and the phone layout test:
    `flutter test test/create_menu_test.dart test/bot_profile_test.dart test/board_test.dart test/search_test.dart test/tasks_phone_test.dart test/barge_in_test.dart test/phone_layout_test.dart`.
    All must pass. (`tasks_phone_test` and `barge_in_test` open the board's move sheet and the call
    screen's audio-output sheet.)

11. Run the whole suite: `flutter test`. Compare with a run from before your change if you have
    one. Nothing that passed before may fail now.

## Check it

- `dart analyze lib/ui/spring_sheet.dart lib/ui/adaptive_modal.dart lib/features/voice/call_screen.dart test/spring_sheet_test.dart`
  shows no errors or warnings, and no issues in the two new files. (`call_screen.dart` already
  had 5 `curly_braces_in_flow_control_structures` infos before this change. Leave them.)
- `grep -c "showSpringBottomSheet<T>(" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "if (_compact(context) && heightFactor == null) {" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "import 'spring_sheet.dart';" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "showModalBottomSheet" lib/features/voice/call_screen.dart` → `0`
- `grep -c "showSpringBottomSheet<CallRoute>(" lib/features/voice/call_screen.dart` → `1`
- `grep -c "class SpringSheetRoute<T> extends PopupRoute<T>" lib/ui/spring_sheet.dart` → `1`
- `flutter test test/spring_sheet_test.dart` passes.

## Don't touch

- The dialog branch of `showAdaptiveSheet` (`return showDialog<T>(...)`, used on windows 700px
  wide and up): unchanged.
- The tall-sheet path (`heightFactor != null`): don't move it to the spring sheet. Full-height
  scrolling content needs a different sheet (a separate change). Don't remove the old
  `showModalBottomSheet` block unless step 5 says so.
- `showConfirm`, `SheetTitle`, `FormSheet`, `showTextPrompt`, `showChoiceSheet`: no edits. They
  get the new sheet through `showAdaptiveSheet`.
- `lib/theme/app_theme.dart` (`bottomSheetTheme`): unchanged. The new sheet reads its colours from
  it.
- Tests that call `showModalBottomSheet` themselves (`test/joining_test.dart`,
  `test/local_server_test.dart`, `test/agent_import_test.dart`): leave them.
- Existing widget `Key`s: keep them all.
- No new dependencies. No refactors, renames, or cleanups beyond the fix.
- Don't run `dart format` on existing files or folders (only on the files this plan creates). No
  git commands (shared tree; others commit).

## STOP if

- The folder `lib/ui/glass/` exists. The approved "Liquid Glass" redesign has started and sheets
  now belong to its glass adapters. Report back instead of editing `adaptive_modal.dart`, so the
  change goes into the adapter.
- The code at any location in "Where" doesn't match the quoted excerpt, beyond lines added by the
  related sheet or unfocus changes described in step 4 (the codebase moved on since this plan was
  written).
- `lib/ui/spring_sheet.dart` already exists.
- The fix seems to require touching something in "Don't touch".
- A test that passed before your change fails after it, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: "Small sheets on phones now open on a smooth spring, follow your finger
when dragged, and a flick down closes them at the speed you flicked. They look the same as before
(sheet colour, rounded top, handle). On a phone, open a bot's profile, tap Delete, and drag the
confirmation sheet down slowly, then flick it."
