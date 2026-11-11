# Fix: Errors, successes, toggles and pickers happen in silence

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/haptic-feedback
- **Needs new dependency**: `haptic_feedback`, pinned exactly to `0.8.0` (released 2026-09-26; it
  needs Flutter >=3.47, and the app is on 3.47; Android minSdk 24, and the app's is 26; iOS 11, and
  the app's is 15). BSD-3-Clause. The article's fix is this package wrapped in a helper. Flutter's
  built-in `HapticFeedback` has no success, warning or error patterns. The package plays the iOS
  system patterns and matching ones on Android, and does nothing on desktop and web. It adds the
  Android `VIBRATE` permission through its own manifest.

## Why

Casama already ticks when you switch tabs in the floating tab bar, long-press a message or approve
a tool. Most key moments are still silent: an error snackbar, a saved form, a successful sign-in, a
purchase that went through, flipping a switch, picking from a dropdown, a choice sheet or a
segmented control, confirming a delete. A light, well-chosen haptic at those moments makes the app
feel responsive in the hand, and people miss it when it's gone. It only plays on phones. iOS
follows the System Haptics switch, and Android 13+ follows the Touch feedback setting, because the
helper plays haptics as touch feedback. Desktop and web stay silent.

## Where

### Already covered (leave as they are)

`grep HapticFeedback` today: the floating tab bar (`lib/ui/floating_tab_chrome.dart:99`, `:166`,
`selectionClick`), the one-time secret copy (`lib/ui/one_time_secret.dart:30`), the code field
(`lib/ui/otp_code_field.dart:117`, `:143`), the composer's buttons
(`lib/features/chat/widgets/composer.dart:249`), code-block copy
(`lib/features/chat/widgets/chat_markdown.dart:217`), message copy and long-press
(`lib/features/chat/widgets/message_actions.dart:34`, `:58`), tool steps
(`lib/features/chat/widgets/chat_widgets.dart:1162`, `lib/features/voice/call_activity.dart:459-463`),
invite copy (`lib/features/workspaces/join_flow.dart:615`) and app connect
(`lib/features/integrations/connect_app_sheet.dart:154`).

### Shared choke points (one edit each covers many screens)

```dart
// lib/core/widgets.dart:8 — current (last import)
import '../l10n/generated/app_localizations.dart';
```

```dart
// lib/core/widgets.dart:61-67 — current. showError backs runGuarded (241 calls), so every failed
// action's snackbar goes through it. showMessage is the neutral snackbar.
void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(context, error))));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
```

```dart
// lib/ui/adaptive_modal.dart:6 and :97 — current (showConfirm; destructive confirms such as delete,
// archive and remove go through it)
import '../theme/app_colors.dart';
```
```dart
      onSubmit: () => Navigator.pop(c, true),
```

```dart
// lib/ui/form_sheet.dart:4, :230 and :420 — current (FormSwitch's switch; showChoiceSheet's choice tap)
import '../theme/app_colors.dart';
```
```dart
        onChanged: onChanged,
```
```dart
                    onTap: () => Navigator.of(context).pop(c),
```

```dart
// lib/ui/segmented.dart:4 and :25-27 — current (AppSegmentedControl, used for the theme mode, font
// role, routine triggers and more)
import '../theme/app_colors.dart';
```
```dart
        onValueChanged: (v) {
          if (v != null) onValueChanged?.call(v);
        },
```

```dart
// lib/core/billing.dart:10 and :190-192 — current (a store purchase verified by the server)
import 'distribution.dart';
```
```dart
      await ref.read(storeProvider).complete(p);
      ref.invalidate(billingProvider);
    } catch (e) {
```

### One-off key moments

```dart
// lib/features/auth/sign_in_screen.dart:185-188 — current (_submit: password sign-in or sign-up)
      } else {
        await backend.signIn(_email.text.trim(), _password.text);
      }
    });
```
```dart
// lib/features/auth/sign_in_screen.dart:210 — current (_magicLink: sign-in email sent)
        if (resent) showMessage(context, context.l10n.magicLinkSent);
```
```dart
// lib/features/auth/sign_in_screen.dart:237-240 — current (_verifyCode: the emailed code signs in)
    setState(() {
      _busy = false;
      _codeInvalid = ok != true;
    });
```
```dart
// lib/features/auth/sign_in_screen.dart:282-283 — current (_forgotPassword: reset email sent)
      if (ok == true) {
        _resetting = true;
```
```dart
// lib/features/settings/model_keys_screen.dart:464-467 — current (testing a model key: works or fails)
    showMessage(
      context,
      r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error ?? ''),
    );
```
```dart
// lib/features/integrations/integration_detail_screen.dart:42 — current (testing an integration)
    if (r != null) showMessage(context, r.ok ? l10n.integrationOk(r.tools.length) : l10n.integrationFailed(r.error ?? ''));
```
```dart
// lib/features/routines/routines_screen.dart:200-201 — current (Run now: a SnackBar of its own)
                    final router = GoRouter.maybeOf(context);
                    ScaffoldMessenger.of(context).showSnackBar(
```
```dart
// lib/features/devices/device_connections_screen.dart:64 — current (a SnackBar of its own)
    if (ok == false) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.devicePermissionDenied)));
```
```dart
// lib/features/admin/admin_screen.dart:47-50 — current (a TabBar without a haptic)
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
```
```dart
// lib/features/computer/computer_screen.dart:346-349 — current (a TabBar without a haptic)
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.zero,
```
```dart
// lib/features/bots/bots_screen.dart:98-99, lib/features/inbox/inbox_screen.dart:247,
// lib/features/timeline/timeline_screen.dart:41 — current (pull to refresh)
              onRefresh: () async {
                ref.invalidate(botsProvider);
```
```dart
          onRefresh: refresh,
```
```dart
                onRefresh: () async => ref.invalidate(runsProvider(botId)),
```
```dart
// lib/features/board/board_screen.dart:181 — current (long-press a ticket to move it)
                Expanded(child: _GroupedList(tasks: shown, bottom: AppSpace.xxl + barInset, onLongPress: (t) => _moveSheet(t, items)))
```

### Call sites listed in the steps

- 49 switches and checkboxes without a haptic (step 13)
- 34 dropdowns without a haptic (step 14)
- 45 snackbars that report a success, a warning or a failure through the neutral `showMessage`
  (step 15)

Each is quoted verbatim, with its target, in its step.

## The fix

The article's fix: wrap the `haptic_feedback` package in a `HapticsHelper` so the `canVibrate`
check isn't repeated everywhere, then call `HapticsHelper.success()` and friends at key moments.
These are the article's pairings:

- **success**: a form submits successfully (sign-in, saved, sent, imported), a purchase goes through.
- **warning**: something to fix first (invalid email, file too large, missing permission).
- **error**: a network request failed, a test failed (every `showError`).
- **light**: a toggle switched, a tab tapped.
- **soft**: a checkbox toggled.
- **medium**: pull to refresh, a long press.
- **heavy**: confirming a delete.
- **selection**: picking from a dropdown, a choice sheet or a segmented control.

These are the only adaptations, each needed in this app:

- `usage: HapticsUsage.touch`, so Android 13+ applies the person's Touch feedback setting. Without a
  usage, the package plays them as "unknown", which some phones won't mute.
- The `canVibrate` call is wrapped in try/catch. In widget tests and on platforms without the
  plugin, it throws, and the helper then stays silent. The package already does nothing on desktop
  and web.
- `soft()` is added to the article's shorthands (its pairing list uses it for checkboxes), plus
  `debugReset()` for tests.
- `hapticOnChanged(...)`: a tiny wrapper so a switch, checkbox or dropdown keeps its existing
  `onChanged` code. A `null` handler stays `null`, so disabled controls stay disabled.
- `showSuccess`, `showWarning` and `showFailure` next to `showMessage` in `lib/core/widgets.dart`,
  so a snackbar call site says what kind of result it is and plays the matching haptic. Plain
  `showMessage` stays neutral, for "Copied" and other notices.

## Steps

1. Add the dependency. In `pubspec.yaml`, find the line `  passkeys: ^2.24.1` and add directly
   below it (exact pin, no caret):
   ```yaml
     haptic_feedback: 0.8.0
   ```
   (If another change already added `  stupid_simple_sheet: 0.9.1+1` there, keep it.) Then run
   `flutter pub get` in `client/`.

2. In the repo root's `THIRD_PARTY_NOTICES.md` (one folder up from `client/`), find the row that
   starts `| mocktail ` and add this row directly below it, exactly:
   ```markdown
   | haptic_feedback                                                       | client                             | BSD-3-Clause                  |
   ```

3. Create `lib/core/haptics.dart` with exactly this content:

   ```dart
   import 'package:flutter/foundation.dart';
   import 'package:haptic_feedback/haptic_feedback.dart';

   /// Haptics for key moments, in one place so the "can this device vibrate" check isn't repeated.
   /// iOS plays the system patterns and follows the System Haptics switch. Android plays matching
   /// patterns as touch feedback, which Android 13+ ties to the Touch feedback setting. Desktop and
   /// web have no haptics: every call does nothing there.
   class HapticsHelper {
     HapticsHelper._();

     static bool? _canVibrate;

     static Future<void> _vibrate(HapticsType type) async {
       try {
         _canVibrate ??= await Haptics.canVibrate();
       } catch (_) {
         // No haptics plugin here (a platform without one, or a widget test): stay silent.
         _canVibrate = false;
       }

       if (_canVibrate ?? false) {
         try {
           await Haptics.vibrate(type, usage: HapticsUsage.touch);
         } catch (_) {
           // A haptic that didn't play is not worth an error.
         }
       }
     }

     /// Forgets whether the device can vibrate, so a test can mock the plugin.
     @visibleForTesting
     static void debugReset() => _canVibrate = null;

     // Declarative shorthand for each type
     static Future<void> success() => _vibrate(HapticsType.success);
     static Future<void> warning() => _vibrate(HapticsType.warning);
     static Future<void> error() => _vibrate(HapticsType.error);
     static Future<void> light() => _vibrate(HapticsType.light);
     static Future<void> medium() => _vibrate(HapticsType.medium);
     static Future<void> heavy() => _vibrate(HapticsType.heavy);
     static Future<void> soft() => _vibrate(HapticsType.soft);
     static Future<void> selection() => _vibrate(HapticsType.selection);
   }

   /// [onChanged] for a switch, checkbox or dropdown that first plays [haptic] (a light tap unless
   /// told otherwise). A null [onChanged] stays null, so a disabled control stays disabled.
   ValueChanged<T>? hapticOnChanged<T>(ValueChanged<T>? onChanged, {Future<void> Function() haptic = HapticsHelper.light}) {
     if (onChanged == null) return null;
     return (T value) {
       haptic();
       onChanged(value);
     };
   }
   ```

   Then format only this new file: `dart format -l 200 lib/core/haptics.dart`.

4. `lib/core/widgets.dart`:
   - Below `import '../l10n/generated/app_localizations.dart';` add `import 'haptics.dart';`.
   - Replace the `showError` and `showMessage` functions (quoted in "Where") with exactly:
     ```dart
     void showError(BuildContext context, Object error) {
       HapticsHelper.error();
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(context, error))));
     }

     void showMessage(BuildContext context, String message) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
     }

     /// [showMessage] for something that just worked (saved, sent, imported), with a success haptic.
     void showSuccess(BuildContext context, String message) {
       HapticsHelper.success();
       showMessage(context, message);
     }

     /// [showMessage] for something the person has to fix or can't do here (an invalid email, a file
     /// too large, a missing permission), with a warning haptic.
     void showWarning(BuildContext context, String message) {
       HapticsHelper.warning();
       showMessage(context, message);
     }

     /// [showMessage] for a failure that already has its own words (an upload that didn't go through),
     /// with an error haptic. For an error object, use [showError].
     void showFailure(BuildContext context, String message) {
       HapticsHelper.error();
       showMessage(context, message);
     }
     ```

5. `lib/ui/adaptive_modal.dart` (showConfirm):
   - Directly **above** `import '../theme/app_colors.dart';` add `import '../core/haptics.dart';`.
   - Replace `      onSubmit: () => Navigator.pop(c, true),` with:
     ```dart
           onSubmit: () {
             // Confirming something destructive (delete, archive, remove) gets a firm haptic.
             if (destructive) HapticsHelper.heavy();
             Navigator.pop(c, true);
           },
     ```

6. `lib/ui/form_sheet.dart`:
   - Directly **above** `import '../theme/app_colors.dart';` add `import '../core/haptics.dart';`.
   - In `FormSwitch`, replace `        onChanged: onChanged,` with `        onChanged: hapticOnChanged(onChanged),`.
   - In `showChoiceSheet`, replace `                    onTap: () => Navigator.of(context).pop(c),` with:
     ```dart
                         onTap: () {
                           HapticsHelper.selection();
                           Navigator.of(context).pop(c);
                         },
     ```

7. `lib/ui/segmented.dart`:
   - Directly **above** `import '../theme/app_colors.dart';` add `import '../core/haptics.dart';`.
   - Replace
     ```dart
             onValueChanged: (v) {
               if (v != null) onValueChanged?.call(v);
             },
     ```
     with
     ```dart
             onValueChanged: (v) {
               final changed = onValueChanged;
               if (v == null || changed == null) return;
               HapticsHelper.selection();
               changed(v);
             },
     ```

8. `lib/core/billing.dart`:
   - Below `import 'distribution.dart';` add `import 'haptics.dart';`.
   - Replace
     ```dart
           ref.invalidate(billingProvider);
         } catch (e) {
     ```
     with
     ```dart
           ref.invalidate(billingProvider);
           // A new purchase went through (Restore Purchases replays old ones, quietly).
           if (!p.restored) HapticsHelper.success();
         } catch (e) {
     ```

9. `lib/features/auth/sign_in_screen.dart` (add `import '../../core/haptics.dart';` below
   `import '../../core/widgets.dart';` if step 13 hasn't already):
   - Replace
     ```dart
           } else {
             await backend.signIn(_email.text.trim(), _password.text);
           }
         });
     ```
     with
     ```dart
           } else {
             await backend.signIn(_email.text.trim(), _password.text);
           }
           // Signed in, or signed up and the confirmation email is on its way.
           HapticsHelper.success();
         });
     ```
   - Replace `        if (resent) showMessage(context, context.l10n.magicLinkSent);` with:
     ```dart
             if (resent) {
               showSuccess(context, context.l10n.magicLinkSent);
             } else {
               HapticsHelper.success();
             }
     ```
   - Replace
     ```dart
         setState(() {
           _busy = false;
           _codeInvalid = ok != true;
         });
     ```
     with
     ```dart
         if (ok == true) HapticsHelper.success();
         setState(() {
           _busy = false;
           _codeInvalid = ok != true;
         });
     ```
   - Replace
     ```dart
           if (ok == true) {
             _resetting = true;
     ```
     with
     ```dart
           if (ok == true) {
             HapticsHelper.success();
             _resetting = true;
     ```

10. Mixed results (success or failure from one call):
    - `lib/features/settings/model_keys_screen.dart`: replace
      ```dart
          showMessage(
            context,
            r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error ?? ''),
          );
      ```
      with
      ```dart
          if (r.ok) {
            showSuccess(context, l10n.keyOk(r.model, r.latencyMs));
          } else {
            showFailure(context, l10n.keyFailed(r.error ?? ''));
          }
      ```
    - `lib/features/integrations/integration_detail_screen.dart`: replace
      `    if (r != null) showMessage(context, r.ok ? l10n.integrationOk(r.tools.length) : l10n.integrationFailed(r.error ?? ''));`
      with
      ```dart
          if (r == null) return;
          if (r.ok) {
            showSuccess(context, l10n.integrationOk(r.tools.length));
          } else {
            showFailure(context, l10n.integrationFailed(r.error ?? ''));
          }
      ```
      (It is the last statement of that method, so the early `return` changes nothing else.)

11. SnackBars that bypass the helpers:
    - `lib/features/routines/routines_screen.dart`: replace
      ```dart
                          final router = GoRouter.maybeOf(context);
                          ScaffoldMessenger.of(context).showSnackBar(
      ```
      with
      ```dart
                          final router = GoRouter.maybeOf(context);
                          HapticsHelper.success();
                          ScaffoldMessenger.of(context).showSnackBar(
      ```
    - `lib/features/devices/device_connections_screen.dart`: replace
      `    if (ok == false) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.devicePermissionDenied)));`
      with `    if (ok == false) showWarning(context, l10n.devicePermissionDenied);`

12. Tabs, refresh, long press:
    - `lib/features/admin/admin_screen.dart`: directly below `                padding: EdgeInsets.zero,`
      inside `child: TabBar(` (the 4 lines quoted in "Where"), add
      `                onTap: (_) => HapticsHelper.light(),`.
    - `lib/features/computer/computer_screen.dart`: directly below `                          padding: EdgeInsets.zero,`
      inside `child: TabBar(` (the 4 lines quoted in "Where"), add
      `                          onTap: (_) => HapticsHelper.light(),`.
    - `lib/features/bots/bots_screen.dart`: directly below `              onRefresh: () async {` add
      `                HapticsHelper.medium();`.
    - `lib/features/inbox/inbox_screen.dart`: replace `          onRefresh: refresh,` with
      ```dart
                onRefresh: () {
                  HapticsHelper.medium();
                  return refresh();
                },
      ```
    - `lib/features/timeline/timeline_screen.dart`: replace
      `                onRefresh: () async => ref.invalidate(runsProvider(botId)),` with
      ```dart
                      onRefresh: () async {
                        HapticsHelper.medium();
                        ref.invalidate(runsProvider(botId));
                      },
      ```
    - `lib/features/board/board_screen.dart`: in line 181 replace the text
      `onLongPress: (t) => _moveSheet(t, items)` with
      `onLongPress: (t) { HapticsHelper.medium(); _moveSheet(t, items); }` (rest of the line unchanged).
    - Imports for this step: `lib/features/computer/computer_screen.dart`,
      `lib/features/inbox/inbox_screen.dart` and `lib/features/timeline/timeline_screen.dart` each
      get `import '../../core/haptics.dart';` directly below their `import '../../core/widgets.dart';`.
      The other files in steps 9-12 get theirs in step 16 (or add the same line if it's missing).

13. Switches and checkboxes: in each of these 49 places, wrap the existing `onChanged` value in
    `hapticOnChanged(...)`. Switches get the default light tap. Checkboxes pass
    `haptic: HapticsHelper.soft`. Each block shows the current line(s) (`-`) and the target (`+`).
    Drop the `-`/`+` marker. The rest of each line is exact, indentation included. For multi-line
    values only the first line (`hapticOnChanged(` is added) and the last line (`)` is added before
    the trailing comma) change. Keep everything between as it is.

1. `lib/features/auth/two_step_screen.dart:263-271` (SwitchListTile)

```diff
-                onChanged: (v) async {
-                  await runGuarded(
-                    context,
-                    () =>
-                        ref.read(backendProvider).setRequireTwoStep(org.id, v),
-                  );
-                  ref.invalidate(_requireTwoStepProvider);
-                  ref.invalidate(organizationsProvider);
-                },
+                onChanged: hapticOnChanged((v) async {
+                  await runGuarded(
+                    context,
+                    () =>
+                        ref.read(backendProvider).setRequireTwoStep(org.id, v),
+                  );
+                  ref.invalidate(_requireTwoStepProvider);
+                  ref.invalidate(organizationsProvider);
+                }),
```

2. `lib/features/board/board_screen.dart:528` (SwitchListTile)

```diff
-          onChanged: (v) => setState(() => _review = v),
+          onChanged: hapticOnChanged((v) => setState(() => _review = v)),
```

3. `lib/features/board/board_screen.dart:652` (SwitchListTile)

```diff
-            onChanged: (v) => _update(review: v),
+            onChanged: hapticOnChanged((v) => _update(review: v)),
```

4. `lib/features/bots/a2a_sheet.dart:40-45` (SwitchListTile)

```diff
-            onChanged: a.workspaceEnabled || a.published
-                ? (v) async {
-                    await runGuarded(context, () => ref.read(backendProvider).setBotA2a(botId, v));
-                    ref.invalidate(botA2aProvider(botId));
-                  }
-                : null,
+            onChanged: hapticOnChanged(a.workspaceEnabled || a.published
+                ? (v) async {
+                    await runGuarded(context, () => ref.read(backendProvider).setBotA2a(botId, v));
+                    ref.invalidate(botA2aProvider(botId));
+                  }
+                : null),
```

5. `lib/features/bots/action_rules_screen.dart:201` (SwitchListTile)

```diff
-          onChanged: (v) => setState(() => _workspace = v),
+          onChanged: hapticOnChanged((v) => setState(() => _workspace = v)),
```

6. `lib/features/bots/agent_import.dart:159` (CheckboxListTile)

```diff
-    onChanged: (v) => setState(() => onChanged(v ?? false)),
+    onChanged: hapticOnChanged((v) => setState(() => onChanged(v ?? false)), haptic: HapticsHelper.soft),
```

7. `lib/features/bots/agent_import.dart:213` (SwitchListTile)

```diff
-            onChanged: (v) => setState(() => _copyFiles = v),
+            onChanged: hapticOnChanged((v) => setState(() => _copyFiles = v)),
```

8. `lib/features/bots/agent_import.dart:353` (CheckboxListTile)

```diff
-              onChanged: (v) => setState(() => v == true ? _keep.add(i) : _keep.remove(i)),
+              onChanged: hapticOnChanged((v) => setState(() => v == true ? _keep.add(i) : _keep.remove(i)), haptic: HapticsHelper.soft),
```

9. `lib/features/bots/bot_template.dart:92` (CheckboxListTile)

```diff
-          onChanged: (v) => setState(() => _memories = v ?? false),
+          onChanged: hapticOnChanged((v) => setState(() => _memories = v ?? false), haptic: HapticsHelper.soft),
```

10. `lib/features/bots/bot_template.dart:208` (SwitchListTile)

```diff
-                SwitchListTile(key: const Key('importRoutines'), title: Text(l10n.importRoutines), value: _routines, onChanged: (v) => setState(() => _routines = v)),
+                SwitchListTile(key: const Key('importRoutines'), title: Text(l10n.importRoutines), value: _routines, onChanged: hapticOnChanged((v) => setState(() => _routines = v))),
```

11. `lib/features/bots/bot_template.dart:214` (SwitchListTile)

```diff
-                  onChanged: (v) => setState(() => _memories = v),
+                  onChanged: hapticOnChanged((v) => setState(() => _memories = v)),
```

12. `lib/features/bots/channels_screen.dart:123-126` (Switch)

```diff
-                            onChanged: (v) async {
-                              await runGuarded(context, () => ref.read(backendProvider).updateChannel(c.id, enabled: v));
-                              ref.invalidate(channelsProvider(botId));
-                            },
+                            onChanged: hapticOnChanged((v) async {
+                              await runGuarded(context, () => ref.read(backendProvider).updateChannel(c.id, enabled: v));
+                              ref.invalidate(channelsProvider(botId));
+                            }),
```

13. `lib/features/bots/knowledge_screen.dart:213` (SwitchListTile)

```diff
-            onChanged: (v) => setState(() => _shared = v),
+            onChanged: hapticOnChanged((v) => setState(() => _shared = v)),
```

14. `lib/features/bots/sharing_screen.dart:109-114` (SwitchListTile)

```diff
-                    onChanged: canAdmin
-                        ? (v) => setState(() {
-                              _private = v;
-                              _dirty = true;
-                            })
-                        : null,
+                    onChanged: hapticOnChanged(canAdmin
+                        ? (v) => setState(() {
+                              _private = v;
+                              _dirty = true;
+                            })
+                        : null),
```

15. `lib/features/companion/companion_screen.dart:83` (Switch)

```diff
-                    onChanged: (v) => runGuarded(context, () => controller.save(capabilities: v ? {...caps, c} : ({...caps}..remove(c)))),
+                    onChanged: hapticOnChanged((v) => runGuarded(context, () => controller.save(capabilities: v ? {...caps, c} : ({...caps}..remove(c))))),
```

16. `lib/features/companion/companion_screen.dart:122` (Switch)

```diff
-                                onChanged: (v) => runGuarded(context, () => controller.save(enabled: v)),
+                                onChanged: hapticOnChanged((v) => runGuarded(context, () => controller.save(enabled: v))),
```

17. `lib/features/companion/companion_screen.dart:176-184` (CheckboxListTile)

```diff
-                                onChanged: (v) async {
-                                  final ids = v == true ? {...device.allowedBotIds, b.id} : ({...device.allowedBotIds}..remove(b.id));
-                                  await runGuarded(context, () async {
-                                    await controller.save(botIds: ids.toList());
-                                    // An allowed bot uses this computer; a removed one goes back to its default.
-                                    await ref.read(backendProvider).setBotComputer(b.id, v == true ? device.computerId : null);
-                                  });
-                                  ref.invalidate(botsProvider);
-                                },
+                                onChanged: hapticOnChanged((v) async {
+                                  final ids = v == true ? {...device.allowedBotIds, b.id} : ({...device.allowedBotIds}..remove(b.id));
+                                  await runGuarded(context, () async {
+                                    await controller.save(botIds: ids.toList());
+                                    // An allowed bot uses this computer; a removed one goes back to its default.
+                                    await ref.read(backendProvider).setBotComputer(b.id, v == true ? device.computerId : null);
+                                  });
+                                  ref.invalidate(botsProvider);
+                                }, haptic: HapticsHelper.soft),
```

18. `lib/features/devices/device_connections_screen.dart:193` (SwitchListTile)

```diff
-            onChanged: busy ? null : onToggle,
+            onChanged: hapticOnChanged(busy ? null : onToggle),
```

19. `lib/features/devices/device_connections_screen.dart:264` (SwitchListTile)

```diff
-            onChanged: (v) => onSettings(DeviceKindSettings(retentionDays: settings.retentionDays, privateModel: v, extras: settings.extras)),
+            onChanged: hapticOnChanged((v) => onSettings(DeviceKindSettings(retentionDays: settings.retentionDays, privateModel: v, extras: settings.extras))),
```

20. `lib/features/devices/device_connections_screen.dart:279-285` (SwitchListTile)

```diff
-                onChanged: (v) => onSettings(
-                  DeviceKindSettings(
-                    retentionDays: settings.retentionDays,
-                    privateModel: settings.privateModel,
-                    extras: [...?settings.extras?.where((e) => e != x), if (v) x],
-                  ),
-                ),
+                onChanged: hapticOnChanged((v) => onSettings(
+                  DeviceKindSettings(
+                    retentionDays: settings.retentionDays,
+                    privateModel: settings.privateModel,
+                    extras: [...?settings.extras?.where((e) => e != x), if (v) x],
+                  ),
+                )),
```

21. `lib/features/groups/group_chats.dart:98` (CheckboxListTile)

```diff
-            onChanged: (v) => setState(() => v == true ? _picked.add(b.id) : _picked.remove(b.id)),
+            onChanged: hapticOnChanged((v) => setState(() => v == true ? _picked.add(b.id) : _picked.remove(b.id)), haptic: HapticsHelper.soft),
```

22. `lib/features/integrations/integration_detail_screen.dart:270` (Switch)

```diff
-            trailing: Switch(value: on.contains(b.id), onChanged: (v) => onChanged(b.id, v)),
+            trailing: Switch(value: on.contains(b.id), onChanged: hapticOnChanged((v) => onChanged(b.id, v))),
```

23. `lib/features/integrations/integrations_screen.dart:755` (Switch)

```diff
-                          trailing: Switch(value: attached.contains(i.id), onChanged: (v) => set(i, v)),
+                          trailing: Switch(value: attached.contains(i.id), onChanged: hapticOnChanged((v) => set(i, v))),
```

24. `lib/features/mcp/mcp_screens.dart:144-147` (SwitchListTile)

```diff
-          onChanged: (v) async {
-            await runGuarded(context, () => backend.setMcpDecideApprovals(widget.orgId, v));
-            ref.invalidate(_mcpApprovalsProvider(widget.orgId));
-          },
+          onChanged: hapticOnChanged((v) async {
+            await runGuarded(context, () => backend.setMcpDecideApprovals(widget.orgId, v));
+            ref.invalidate(_mcpApprovalsProvider(widget.orgId));
+          }),
```

25. `lib/features/notifications/checkins_sheet.dart:57` (SwitchListTile)

```diff
-        SwitchListTile(key: const Key('checkinsEnabled'), contentPadding: EdgeInsets.zero, title: Text(l10n.checkins), value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
+        SwitchListTile(key: const Key('checkinsEnabled'), contentPadding: EdgeInsets.zero, title: Text(l10n.checkins), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
```

26. `lib/features/notifications/quiet_hours.dart:105` (SwitchListTile)

```diff
-          onChanged: (v) => setState(() => _enabled = v),
+          onChanged: hapticOnChanged((v) => setState(() => _enabled = v)),
```

27. `lib/features/routines/routines_screen.dart:186-189` (Switch)

```diff
-            onChanged: (v) async {
-              await runGuarded(context, () => ref.read(backendProvider).setRoutineEnabled(r.id, v));
-              ref.invalidate(routinesProvider(r.botId));
-            },
+            onChanged: hapticOnChanged((v) async {
+              await runGuarded(context, () => ref.read(backendProvider).setRoutineEnabled(r.id, v));
+              ref.invalidate(routinesProvider(r.botId));
+            }),
```

28. `lib/features/routines/routines_screen.dart:414` (CheckboxListTile)

```diff
-                onChanged: (v) => setState(() => _outsideGuests = v ?? false),
+                onChanged: hapticOnChanged((v) => setState(() => _outsideGuests = v ?? false), haptic: HapticsHelper.soft),
```

29. `lib/features/routines/routines_screen.dart:416` (CheckboxListTile)

```diff
-              CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.calendarVideoLink), value: _videoLink, onChanged: (v) => setState(() => _videoLink = v ?? false)),
+              CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.calendarVideoLink), value: _videoLink, onChanged: hapticOnChanged((v) => setState(() => _videoLink = v ?? false), haptic: HapticsHelper.soft)),
```

30. `lib/features/settings/about_you_screen.dart:184` (SwitchListTile)

```diff
-              onChanged: _busy ? null : (on) => _save(learn: on),
+              onChanged: hapticOnChanged(_busy ? null : (on) => _save(learn: on)),
```

31. `lib/features/settings/about_you_screen.dart:193-196` (SwitchListTile)

```diff
-                onChanged: (on) async {
-                  await runGuarded(context, () => ref.read(backendProvider).setProfileSharedIn(org.id, on));
-                  ref.invalidate(profileSharedProvider(org.id));
-                },
+                onChanged: hapticOnChanged((on) async {
+                  await runGuarded(context, () => ref.read(backendProvider).setProfileSharedIn(org.id, on));
+                  ref.invalidate(profileSharedProvider(org.id));
+                }),
```

32. `lib/features/settings/password_managers_screen.dart:156` (SwitchListTile)

```diff
-        if (admin) SwitchListTile(key: const Key('pmWorkspace'), contentPadding: EdgeInsets.zero, title: Text(l10n.pmForWorkspace), value: _workspace, onChanged: (v) => setState(() => _workspace = v)),
+        if (admin) SwitchListTile(key: const Key('pmWorkspace'), contentPadding: EdgeInsets.zero, title: Text(l10n.pmForWorkspace), value: _workspace, onChanged: hapticOnChanged((v) => setState(() => _workspace = v))),
```

33. `lib/features/settings/password_managers_screen.dart:199` (CheckboxListTile)

```diff
-              onChanged: (on) => setState(() => on == true ? _chosen.add(v.id) : _chosen.remove(v.id)),
+              onChanged: hapticOnChanged((on) => setState(() => on == true ? _chosen.add(v.id) : _chosen.remove(v.id)), haptic: HapticsHelper.soft),
```

34. `lib/features/settings/settings_screen.dart:276` (SwitchListTile)

```diff
-                        onChanged: ref.read(showBotStepsProvider.notifier).set,
+                        onChanged: hapticOnChanged(ref.read(showBotStepsProvider.notifier).set),
```

35. `lib/features/settings/settings_screen.dart:288-291` (SwitchListTile)

```diff
-                          onChanged: (v) async {
-                            await runGuarded(context, () => setLaunchAtLogin(v));
-                            ref.invalidate(launchAtLoginProvider);
-                          },
+                          onChanged: hapticOnChanged((v) async {
+                            await runGuarded(context, () => setLaunchAtLogin(v));
+                            ref.invalidate(launchAtLoginProvider);
+                          }),
```

36. `lib/features/settings/settings_screen.dart:588-591` (SwitchListTile)

```diff
-            onChanged: (v) async {
-              await runGuarded(context, () => setAutoUpdateChecks(v));
-              ref.invalidate(autoUpdateChecksProvider);
-            },
+            onChanged: hapticOnChanged((v) async {
+              await runGuarded(context, () => setAutoUpdateChecks(v));
+              ref.invalidate(autoUpdateChecksProvider);
+            }),
```

37. `lib/features/skills/skills_screen.dart:153-170` (Switch)

```diff
-                                onChanged: (v) async {
-                                  final org = ref.read(currentOrgProvider)!;
-                                  await runGuarded(
-                                    context,
-                                    () => ref
-                                        .read(backendProvider)
-                                        .saveSkill(
-                                          org.id,
-                                          id: s.id,
-                                          botId: s.botId,
-                                          name: s.name,
-                                          description: s.description,
-                                          bodyMd: s.bodyMd,
-                                          enabled: v,
-                                        ),
-                                  );
-                                  ref.invalidate(skillsProvider);
-                                },
+                                onChanged: hapticOnChanged((v) async {
+                                  final org = ref.read(currentOrgProvider)!;
+                                  await runGuarded(
+                                    context,
+                                    () => ref
+                                        .read(backendProvider)
+                                        .saveSkill(
+                                          org.id,
+                                          id: s.id,
+                                          botId: s.botId,
+                                          name: s.name,
+                                          description: s.description,
+                                          bodyMd: s.bodyMd,
+                                          enabled: v,
+                                        ),
+                                  );
+                                  ref.invalidate(skillsProvider);
+                                }),
```

38. `lib/features/voice/call_tools_sheet.dart:99-103` (CheckboxListTile)

```diff
-                onChanged: (v) => setState(
-                  () => v == true
-                      ? _chosen.add(callToolName(i, t.name))
-                      : _chosen.remove(callToolName(i, t.name)),
-                ),
+                onChanged: hapticOnChanged((v) => setState(
+                  () => v == true
+                      ? _chosen.add(callToolName(i, t.name))
+                      : _chosen.remove(callToolName(i, t.name)),
+                ), haptic: HapticsHelper.soft),
```

39. `lib/features/voice/wake_word_sheet.dart:64` (SwitchListTile)

```diff
-        SwitchListTile(key: const Key('wakeWordOn'), contentPadding: EdgeInsets.zero, title: Text(l10n.wakeWordListen), value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
+        SwitchListTile(key: const Key('wakeWordOn'), contentPadding: EdgeInsets.zero, title: Text(l10n.wakeWordListen), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
```

40. `lib/features/workspaces/people_screen.dart:165-168` (SwitchListTile)

```diff
-                onChanged: (v) async {
-                  await runGuarded(context, () => ref.read(backendProvider).updateDefaultInvite(org.id, requiresApproval: v));
-                  ref.invalidate(_defaultInviteProvider(org.id));
-                },
+                onChanged: hapticOnChanged((v) async {
+                  await runGuarded(context, () => ref.read(backendProvider).updateDefaultInvite(org.id, requiresApproval: v));
+                  ref.invalidate(_defaultInviteProvider(org.id));
+                }),
```

41. `lib/features/workspaces/people_screen.dart:359` (SwitchListTile)

```diff
-                  onChanged: (v) => setState(() => _admin = v),
+                  onChanged: hapticOnChanged((v) => setState(() => _admin = v)),
```

42. `lib/features/workspaces/people_screen.dart:486-489` (SwitchListTile)

```diff
-            onChanged: (v) async {
-              await runGuarded(context, () => ref.read(backendProvider).setJoinDomain(orgId, v));
-              ref.invalidate(_domainsProvider(orgId));
-            },
+            onChanged: hapticOnChanged((v) async {
+              await runGuarded(context, () => ref.read(backendProvider).setJoinDomain(orgId, v));
+              ref.invalidate(_domainsProvider(orgId));
+            }),
```

43. `lib/features/workspaces/spaces.dart:441-444` (SwitchListTile)

```diff
-          onChanged: (v) async {
-            await runGuarded(context, () => ref.read(backendProvider).setAllowBotToBot(orgId, v));
-            ref.invalidate(_botToBotProvider(orgId));
-          },
+          onChanged: hapticOnChanged((v) async {
+            await runGuarded(context, () => ref.read(backendProvider).setAllowBotToBot(orgId, v));
+            ref.invalidate(_botToBotProvider(orgId));
+          }),
```

44. `lib/features/workspaces/spaces.dart:497` (SwitchListTile)

```diff
-          onChanged: s.available || on ? toggle : null,
+          onChanged: hapticOnChanged(s.available || on ? toggle : null),
```

45. `lib/features/workspaces/spaces.dart:654` (SwitchListTile)

```diff
-        SwitchListTile(key: const Key('memoryCopy'), contentPadding: EdgeInsets.zero, title: Text(l10n.memoryCopyExisting), value: _copy, onChanged: (v) => setState(() => _copy = v)),
+        SwitchListTile(key: const Key('memoryCopy'), contentPadding: EdgeInsets.zero, title: Text(l10n.memoryCopyExisting), value: _copy, onChanged: hapticOnChanged((v) => setState(() => _copy = v))),
```

46. `lib/features/workspaces/spaces.dart:686-689` (SwitchListTile)

```diff
-          onChanged: (v) async {
-            await runGuarded(context, () => ref.read(backendProvider).setA2aEnabled(orgId, v));
-            ref.invalidate(_a2aProvider(orgId));
-          },
+          onChanged: hapticOnChanged((v) async {
+            await runGuarded(context, () => ref.read(backendProvider).setA2aEnabled(orgId, v));
+            ref.invalidate(_a2aProvider(orgId));
+          }),
```

47. `lib/features/workspaces/spaces.dart:820` (SwitchListTile)

```diff
-        SwitchListTile(key: const Key('phoneCallsPersonal'), contentPadding: EdgeInsets.zero, title: Text(l10n.phoneCallsPersonal), value: _personal, onChanged: (v) => setState(() => _personal = v)),
+        SwitchListTile(key: const Key('phoneCallsPersonal'), contentPadding: EdgeInsets.zero, title: Text(l10n.phoneCallsPersonal), value: _personal, onChanged: hapticOnChanged((v) => setState(() => _personal = v))),
```

48. `lib/features/workspaces/spaces.dart:1076` (SwitchListTile)

```diff
-        SwitchListTile(key: const Key('infisicalMove'), contentPadding: EdgeInsets.zero, title: Text(l10n.secretStoreMove), value: _move, onChanged: (v) => setState(() => _move = v)),
+        SwitchListTile(key: const Key('infisicalMove'), contentPadding: EdgeInsets.zero, title: Text(l10n.secretStoreMove), value: _move, onChanged: hapticOnChanged((v) => setState(() => _move = v))),
```

49. `lib/features/workspaces/workspace_files.dart:171` (SwitchListTile)

```diff
-        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.gitSyncOn), value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
+        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.gitSyncOn), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
```

14. Dropdowns: in each of these 34 places, wrap the existing `onChanged` value in
    `hapticOnChanged(..., haptic: HapticsHelper.selection)`. Same format as step 13.

1. `lib/features/admin/admin_screen.dart:518-520` (DropdownButtonFormField)

```diff
-          onChanged: (v) {
-            if (v != null) setState(() => _resolution = v);
-          },
+          onChanged: hapticOnChanged((v) {
+            if (v != null) setState(() => _resolution = v);
+          }, haptic: HapticsHelper.selection),
```

2. `lib/features/board/board_screen.dart:142` (DropdownButton)

```diff
-              onChanged: (p) => setState(() => _priority = p),
+              onChanged: hapticOnChanged((p) => setState(() => _priority = p), haptic: HapticsHelper.selection),
```

3. `lib/features/board/board_screen.dart:510` (DropdownButtonFormField)

```diff
-          onChanged: (p) => setState(() => _priority = p ?? _priority),
+          onChanged: hapticOnChanged((p) => setState(() => _priority = p ?? _priority), haptic: HapticsHelper.selection),
```

4. `lib/features/board/board_screen.dart:521` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _bot = v),
+          onChanged: hapticOnChanged((v) => setState(() => _bot = v), haptic: HapticsHelper.selection),
```

5. `lib/features/board/board_screen.dart:602` (DropdownButtonFormField)

```diff
-                  onChanged: (s) => s == null ? null : _update(status: s.value),
+                  onChanged: hapticOnChanged((s) => s == null ? null : _update(status: s.value), haptic: HapticsHelper.selection),
```

6. `lib/features/board/board_screen.dart:612` (DropdownButtonFormField)

```diff
-                  onChanged: (p) => p == null ? null : _update(priority: p.value),
+                  onChanged: hapticOnChanged((p) => p == null ? null : _update(priority: p.value), haptic: HapticsHelper.selection),
```

7. `lib/features/board/board_screen.dart:626` (DropdownButtonFormField)

```diff
-                  onChanged: (v) => v == null ? null : _update(bot: v),
+                  onChanged: hapticOnChanged((v) => v == null ? null : _update(bot: v), haptic: HapticsHelper.selection),
```

8. `lib/features/bots/action_rules_screen.dart:167` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _category = v ?? 'send'),
+          onChanged: hapticOnChanged((v) => setState(() => _category = v ?? 'send'), haptic: HapticsHelper.selection),
```

9. `lib/features/bots/action_rules_screen.dart:180` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _rule = v ?? 'ask'),
+          onChanged: hapticOnChanged((v) => setState(() => _rule = v ?? 'ask'), haptic: HapticsHelper.selection),
```

10. `lib/features/bots/agent_import.dart:223-226` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() {
-            _credentialId = v;
-            _model = '';
-          }),
+          onChanged: hapticOnChanged((v) => setState(() {
+            _credentialId = v;
+            _model = '';
+          }), haptic: HapticsHelper.selection),
```

11. `lib/features/bots/bot_profile_screen.dart:378-388` (DropdownButtonFormField)

```diff
-                onChanged: (v) => setState(() {
-                  _credentialId = v;
-                  for (final k in keys) {
-                    if (k.id == v)
-                      _model =
-                          ref
-                              .read(backendProvider)
-                              .defaultModelFor(k.provider.value) ??
-                          _model;
-                  }
-                }),
+                onChanged: hapticOnChanged((v) => setState(() {
+                  _credentialId = v;
+                  for (final k in keys) {
+                    if (k.id == v)
+                      _model =
+                          ref
+                              .read(backendProvider)
+                              .defaultModelFor(k.provider.value) ??
+                          _model;
+                  }
+                }), haptic: HapticsHelper.selection),
```

12. `lib/features/bots/bot_template.dart:223-226` (DropdownButtonFormField)

```diff
-                onChanged: (v) => setState(() {
-                  _credentialId = v;
-                  _model = '';
-                }),
+                onChanged: hapticOnChanged((v) => setState(() {
+                  _credentialId = v;
+                  _model = '';
+                }), haptic: HapticsHelper.selection),
```

13. `lib/features/bots/bots_screen.dart:417-421` (DropdownButtonFormField)

```diff
-        onChanged: (v) => setState(() {
-          _credentialId = v;
-          _modelPicked = false;
-          _fillDefaultModel(keys);
-        }),
+        onChanged: hapticOnChanged((v) => setState(() {
+          _credentialId = v;
+          _modelPicked = false;
+          _fillDefaultModel(keys);
+        }), haptic: HapticsHelper.selection),
```

14. `lib/features/bots/channels_screen.dart:209-212` (DropdownButtonFormField)

```diff
-          onChanged: (k) => setState(() {
-            _kind = k ?? _kind;
-            if (_name.text.isEmpty || ChannelKind.values.any((x) => channelKindName(x) == _name.text)) _name.text = channelKindName(_kind);
-          }),
+          onChanged: hapticOnChanged((k) => setState(() {
+            _kind = k ?? _kind;
+            if (_name.text.isEmpty || ChannelKind.values.any((x) => channelKindName(x) == _name.text)) _name.text = channelKindName(_kind);
+          }), haptic: HapticsHelper.selection),
```

15. `lib/features/bots/channels_screen.dart:241` (DropdownButtonFormField)

```diff
-                onChanged: (v) => setState(() => _mac = v),
+                onChanged: hapticOnChanged((v) => setState(() => _mac = v), haptic: HapticsHelper.selection),
```

16. `lib/features/bots/sharing_screen.dart:130-133` (DropdownButton)

```diff
-                                onChanged: (v) => setState(() {
-                                  _entries[i] = (userId: e.userId, role: e.role, label: e.label, access: v ?? e.access);
-                                  _dirty = true;
-                                }),
+                                onChanged: hapticOnChanged((v) => setState(() {
+                                  _entries[i] = (userId: e.userId, role: e.role, label: e.label, access: v ?? e.access);
+                                  _dirty = true;
+                                }), haptic: HapticsHelper.selection),
```

17. `lib/features/computer/computers_screen.dart:276` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _botId = v),
+          onChanged: hapticOnChanged((v) => setState(() => _botId = v), haptic: HapticsHelper.selection),
```

18. `lib/features/devices/device_connections_screen.dart:253` (DropdownButton)

```diff
-                onChanged: (d) => d == null ? null : onSettings(DeviceKindSettings(retentionDays: d, privateModel: settings.privateModel, extras: settings.extras)),
+                onChanged: hapticOnChanged((d) => d == null ? null : onSettings(DeviceKindSettings(retentionDays: d, privateModel: settings.privateModel, extras: settings.extras)), haptic: HapticsHelper.selection),
```

19. `lib/features/integrations/integrations_screen.dart:642` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _kind = v ?? _kind),
+          onChanged: hapticOnChanged((v) => setState(() => _kind = v ?? _kind), haptic: HapticsHelper.selection),
```

20. `lib/features/mcp/mcp_screens.dart:74` (DropdownButtonFormField)

```diff
-                    onChanged: (v) => setState(() => _org = v),
+                    onChanged: hapticOnChanged((v) => setState(() => _org = v), haptic: HapticsHelper.selection),
```

21. `lib/features/notifications/checkins_sheet.dart:76` (DropdownButtonFormField)

```diff
-          onChanged: !_enabled ? null : (v) => setState(() => _every = v ?? 3),
+          onChanged: hapticOnChanged(!_enabled ? null : (v) => setState(() => _every = v ?? 3), haptic: HapticsHelper.selection),
```

22. `lib/features/privacy/privacy_screen.dart:136-140` (DropdownButton)

```diff
-                        onChanged: (d) async {
-                          if (d == null) return;
-                          await runGuarded(context, () => ref.read(backendProvider).setRetentionDays(org.id, d));
-                          ref.invalidate(_retentionProvider);
-                        },
+                        onChanged: hapticOnChanged((d) async {
+                          if (d == null) return;
+                          await runGuarded(context, () => ref.read(backendProvider).setRetentionDays(org.id, d));
+                          ref.invalidate(_retentionProvider);
+                        }, haptic: HapticsHelper.selection),
```

23. `lib/features/projects/projects_screen.dart:160` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _lead = v),
+          onChanged: hapticOnChanged((v) => setState(() => _lead = v), haptic: HapticsHelper.selection),
```

24. `lib/features/routines/routines_screen.dart:398` (DropdownButtonFormField)

```diff
-                onChanged: (v) => setState(() => _calendarId = v),
+                onChanged: hapticOnChanged((v) => setState(() => _calendarId = v), haptic: HapticsHelper.selection),
```

25. `lib/features/routines/routines_screen.dart:436` (DropdownButtonFormField)

```diff
-              onChanged: (v) => setState(() => _msgKind = v),
+              onChanged: hapticOnChanged((v) => setState(() => _msgKind = v), haptic: HapticsHelper.selection),
```

26. `lib/features/routines/routines_screen.dart:497-500` (DropdownButtonFormField)

```diff
-                          onChanged: (v) => setState(() {
-                            _weekday = v ?? _weekday;
-                            _writeCron();
-                          }),
+                          onChanged: hapticOnChanged((v) => setState(() {
+                            _weekday = v ?? _weekday;
+                            _writeCron();
+                          }), haptic: HapticsHelper.selection),
```

27. `lib/features/settings/model_keys_screen.dart:324` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _provider = v ?? _provider),
+          onChanged: hapticOnChanged((v) => setState(() => _provider = v ?? _provider), haptic: HapticsHelper.selection),
```

28. `lib/features/settings/settings_screen.dart:509` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _tts = v),
+          onChanged: hapticOnChanged((v) => setState(() => _tts = v), haptic: HapticsHelper.selection),
```

29. `lib/features/settings/settings_screen.dart:525` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _stt = v),
+          onChanged: hapticOnChanged((v) => setState(() => _stt = v), haptic: HapticsHelper.selection),
```

30. `lib/features/skills/skill_library.dart:42` (DropdownButtonFormField)

```diff
-      onChanged: onChanged,
+      onChanged: hapticOnChanged(onChanged, haptic: HapticsHelper.selection),
```

31. `lib/features/voice/wake_word_sheet.dart:77` (DropdownButtonFormField)

```diff
-          onChanged: (v) => setState(() => _bot = v),
+          onChanged: hapticOnChanged((v) => setState(() => _bot = v), haptic: HapticsHelper.selection),
```

32. `lib/features/workspaces/people_screen.dart:554` (DropdownButtonFormField)

```diff
-                  onChanged: (v) => setState(() => _role = v ?? _role),
+                  onChanged: hapticOnChanged((v) => setState(() => _role = v ?? _role), haptic: HapticsHelper.selection),
```

33. `lib/features/workspaces/people_screen.dart:564` (DropdownButtonFormField)

```diff
-                  onChanged: (v) => setState(() => _days = v),
+                  onChanged: hapticOnChanged((v) => setState(() => _days = v), haptic: HapticsHelper.selection),
```

34. `lib/features/workspaces/people_screen.dart:574` (DropdownButtonFormField)

```diff
-                  onChanged: (v) => setState(() => _uses = v),
+                  onChanged: hapticOnChanged((v) => setState(() => _uses = v), haptic: HapticsHelper.selection),
```

15. Snackbars that report a result: in each of these 45 places, rename `showMessage(` to the
    function shown (`showSuccess(`, `showWarning(` or `showFailure(`). Nothing else on the line
    changes, and the arguments stay the same. These files already import `core/widgets.dart`, where
    the three functions live. "Copied", "link copied", "up to date" and other neutral notices stay
    `showMessage`.

1. `lib/features/bots/bot_template.dart:153` → `showSuccess`

```diff
-    showMessage(
+    showSuccess(
```

2. `lib/features/bots/bot_history_screen.dart:97` → `showSuccess`

```diff
-    showMessage(context, l10n.saved);
+    showSuccess(context, l10n.saved);
```

3. `lib/features/bots/agent_import.dart:148` → `showSuccess`

```diff
-    showMessage(context, message);
+    showSuccess(context, message);
```

4. `lib/features/bots/sharing_screen.dart:81` → `showSuccess`

```diff
-    if (r != null) showMessage(context, context.l10n.sharingSaved);
+    if (r != null) showSuccess(context, context.l10n.sharingSaved);
```

5. `lib/features/bots/bot_profile_screen.dart:100` → `showSuccess`

```diff
-      showMessage(context, l10n.saved);
+      showSuccess(context, l10n.saved);
```

6. `lib/features/bots/bot_profile_screen.dart:731` → `showSuccess`

```diff
-                showMessage(context, l10n.botArchived(bot.name));
+                showSuccess(context, l10n.botArchived(bot.name));
```

7. `lib/features/settings/gallery_screen.dart:1124` → `showSuccess`

```diff
-      showMessage(
+      showSuccess(
```

8. `lib/features/settings/themes_screen.dart:50` → `showSuccess`

```diff
-      showMessage(context, context.l10n.themeImported(preset.name));
+      showSuccess(context, context.l10n.themeImported(preset.name));
```

9. `lib/features/settings/about_you_screen.dart:78` → `showSuccess`

```diff
-    if (ok == true && learn == null) showMessage(context, context.l10n.saved);
+    if (ok == true && learn == null) showSuccess(context, context.l10n.saved);
```

10. `lib/features/settings/about_you_screen.dart:104` → `showSuccess`

```diff
-    if (n != null && mounted) showMessage(context, l10n.factsImported(n));
+    if (n != null && mounted) showSuccess(context, l10n.factsImported(n));
```

11. `lib/features/privacy/privacy_screen.dart:56` → `showSuccess`

```diff
-      if (mounted) showMessage(context, l10n.exportReady((bytes.length / 1024).toStringAsFixed(0)));
+      if (mounted) showSuccess(context, l10n.exportReady((bytes.length / 1024).toStringAsFixed(0)));
```

12. `lib/features/memory/memory_screen.dart:50` → `showSuccess`

```diff
-      if (n != null && context.mounted) showMessage(context, l10n.memoriesImported(n));
+      if (n != null && context.mounted) showSuccess(context, l10n.memoriesImported(n));
```

13. `lib/features/chat/chat_screen.dart:59` → `showSuccess`

```diff
-  if (done == true && context.mounted) showMessage(context, l10n.restored);
+  if (done == true && context.mounted) showSuccess(context, l10n.restored);
```

14. `lib/features/chat/chat_screen.dart:892` → `showSuccess`

```diff
-                  if (ok == true && context.mounted) showMessage(context, l10n.removedFromProfile);
+                  if (ok == true && context.mounted) showSuccess(context, l10n.removedFromProfile);
```

15. `lib/features/auth/passkeys_screen.dart:37` → `showSuccess`

```diff
-      showMessage(context, context.l10n.passkeyAdded);
+      showSuccess(context, context.l10n.passkeyAdded);
```

16. `lib/features/auth/two_step_screen.dart:84` → `showSuccess`

```diff
-      showMessage(context, context.l10n.twoStepNowOn);
+      showSuccess(context, context.l10n.twoStepNowOn);
```

17. `lib/features/auth/account_screen.dart:75` → `showSuccess`

```diff
-      showMessage(context, context.l10n.passwordSaved);
+      showSuccess(context, context.l10n.passwordSaved);
```

18. `lib/features/auth/account_screen.dart:245` → `showSuccess`

```diff
-      showMessage(context, l10n.changeEmailSent(value));
+      showSuccess(context, l10n.changeEmailSent(value));
```

19. `lib/features/auth/account_screen.dart:355` → `showSuccess`

```diff
-  if (added == true && context.mounted) showMessage(context, context.l10n.passkeyAdded);
+  if (added == true && context.mounted) showSuccess(context, context.l10n.passkeyAdded);
```

20. `lib/features/workspaces/workspace_files.dart:48` → `showSuccess`

```diff
-      if (r != null && context.mounted) showMessage(context, l10n.filesImported(r.created.length, r.updated.length));
+      if (r != null && context.mounted) showSuccess(context, l10n.filesImported(r.created.length, r.updated.length));
```

21. `lib/features/workspaces/workspace_files.dart:91` → `showSuccess`

```diff
-                  if (context.mounted) showMessage(context, l10n.syncQueued);
+                  if (context.mounted) showSuccess(context, l10n.syncQueued);
```

22. `lib/features/workspaces/people_screen.dart:292` → `showSuccess`

```diff
-      showMessage(context, l10n.invitesSent(sent.length));
+      showSuccess(context, l10n.invitesSent(sent.length));
```

23. `lib/features/workspaces/people_screen.dart:447` → `showSuccess`

```diff
-                      if (r != null && context.mounted) showMessage(context, r.emailSent ? l10n.inviteSent(i.email) : l10n.inviteRenewed);
+                      if (r != null && context.mounted) showSuccess(context, r.emailSent ? l10n.inviteSent(i.email) : l10n.inviteRenewed);
```

24. `lib/features/routines/run_routine_screen.dart:34` → `showSuccess`

```diff
-      showMessage(context, context.l10n.routineStarted);
+      showSuccess(context, context.l10n.routineStarted);
```

25. `lib/features/files/file_preview.dart:196` → `showSuccess`

```diff
-    if (saved != null && context.mounted) showMessage(context, context.l10n.savedFile(name));
+    if (saved != null && context.mounted) showSuccess(context, context.l10n.savedFile(name));
```

26. `lib/features/teach/teach_draft_screen.dart:82` → `showSuccess`

```diff
-    showMessage(context, context.l10n.teachSaved(_name.text.trim()));
+    showSuccess(context, context.l10n.teachSaved(_name.text.trim()));
```

27. `lib/features/teach/teach_draft_screen.dart:189` → `showSuccess`

```diff
-                        if (r != null && context.mounted) showMessage(context, l10n.replaySaved(r.name));
+                        if (r != null && context.mounted) showSuccess(context, l10n.replaySaved(r.name));
```

28. `lib/features/skills/skill_proposals.dart:115` → `showSuccess`

```diff
-                  if (context.mounted) showMessage(context, isEdit ? l10n.skillUpdated(p.name) : l10n.skillSaved(p.name));
+                  if (context.mounted) showSuccess(context, isEdit ? l10n.skillUpdated(p.name) : l10n.skillSaved(p.name));
```

29. `lib/features/skills/skill_library.dart:92` → `showSuccess`

```diff
-      showMessage(context, context.l10n.skillInstalled(p.name));
+      showSuccess(context, context.l10n.skillInstalled(p.name));
```

30. `lib/features/skills/skill_catalog_screen.dart:259` → `showSuccess`

```diff
-    showMessage(context, l10n.skillInstalled(skillTitle(s.name)));
+    showSuccess(context, l10n.skillInstalled(skillTitle(s.name)));
```

31. `lib/features/billing/billing_screen.dart:100` → `showSuccess`

```diff
-    if (mounted) showMessage(context, context.l10n.restoreStarted);
+    if (mounted) showSuccess(context, context.l10n.restoreStarted);
```

32. `lib/features/bots/bot_template.dart:117` → `showWarning`

```diff
-    if (context.mounted) showMessage(context, context.l10n.notABotTemplate);
+    if (context.mounted) showWarning(context, context.l10n.notABotTemplate);
```

33. `lib/features/chat/chat_screen.dart:139` → `showWarning`

```diff
-      showMessage(context, context.l10n.noComputerForFiles);
+      showWarning(context, context.l10n.noComputerForFiles);
```

34. `lib/features/chat/chat_screen.dart:678` → `showWarning`

```diff
-          showMessage(context, context.l10n.noComputerForFiles);
+          showWarning(context, context.l10n.noComputerForFiles);
```

35. `lib/features/chat/chat_screen.dart:144` → `showWarning`

```diff
-        showMessage(context, context.l10n.fileTooLarge(name));
+        showWarning(context, context.l10n.fileTooLarge(name));
```

36. `lib/features/chat/chat_screen.dart:366` → `showWarning`

```diff
-        showMessage(context, context.l10n.micPermissionNeeded);
+        showWarning(context, context.l10n.micPermissionNeeded);
```

37. `lib/features/auth/sign_in_screen.dart:271` → `showWarning`

```diff
-      showMessage(context, context.l10n.invalidEmail);
+      showWarning(context, context.l10n.invalidEmail);
```

38. `lib/features/auth/account_screen.dart:235` → `showWarning`

```diff
-      showMessage(context, l10n.invalidEmail);
+      showWarning(context, l10n.invalidEmail);
```

39. `lib/features/chat/local_actions.dart:32` → `showWarning`

```diff
-        if (provider == 'chatgpt') showMessage(context, context.l10n.chatGptDesktopOnly);
+        if (provider == 'chatgpt') showWarning(context, context.l10n.chatGptDesktopOnly);
```

40. `lib/features/files/file_preview.dart:186` → `showWarning`

```diff
-      if (!ok && context.mounted) showMessage(context, context.l10n.noAppToOpen(name));
+      if (!ok && context.mounted) showWarning(context, context.l10n.noAppToOpen(name));
```

41. `lib/features/computer/live_view_screen.dart:214` → `showWarning`

```diff
-    if (text.isEmpty) return showMessage(context, context.l10n.livePasteEmpty);
+    if (text.isEmpty) return showWarning(context, context.l10n.livePasteEmpty);
```

42. `lib/features/computer/live_view_screen.dart:235` → `showWarning`

```diff
-    if (text == null || text.isEmpty) return showMessage(context, context.l10n.liveNothingCopied);
+    if (text == null || text.isEmpty) return showWarning(context, context.l10n.liveNothingCopied);
```

43. `lib/features/devices/device_connections_screen.dart:53` → `showWarning`

```diff
-      showMessage(context, context.l10n.healthNeedsEncryption);
+      showWarning(context, context.l10n.healthNeedsEncryption);
```

44. `lib/features/quick_ask/quick_ask_screen.dart:108` → `showFailure`

```diff
-    if (shot == null) showMessage(context, context.l10n.ctxScreenshotFailed);
+    if (shot == null) showFailure(context, context.l10n.ctxScreenshotFailed);
```

45. `lib/features/chat/chat_screen.dart:158` → `showFailure`

```diff
-        showMessage(context, context.l10n.uploadFailed(name));
+        showFailure(context, context.l10n.uploadFailed(name));
```

16. Imports for steps 9-14. Each file that now uses `HapticsHelper` or `hapticOnChanged` needs the
    helper import. Add it exactly where shown (35 files):

- `lib/features/admin/admin_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/auth/two_step_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/board/board_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/a2a_sheet.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/action_rules_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/agent_import.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/bot_profile_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/bot_template.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/bots_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/channels_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/knowledge_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/bots/sharing_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/companion/companion_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/computer/computers_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/devices/device_connections_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/groups/group_chats.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/integrations/integration_detail_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/integrations/integrations_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/mcp/mcp_screens.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/notifications/checkins_sheet.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/notifications/quiet_hours.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/privacy/privacy_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/projects/projects_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/routines/routines_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/settings/about_you_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/settings/model_keys_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/settings/password_managers_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/settings/settings_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/skills/skill_library.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/skills/skills_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/voice/call_tools_sheet.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/voice/wake_word_sheet.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/workspaces/people_screen.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/workspaces/spaces.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`
- `lib/features/workspaces/workspace_files.dart`: below `import '../../core/widgets.dart';` add `import '../../core/haptics.dart';`

    After all edits, run `dart analyze lib`. It must not report `Undefined name 'HapticsHelper'`,
    `The function 'hapticOnChanged' isn't defined`, or `Unused import: '...core/haptics.dart'`. Add
    or remove that one import line where it does.

17. Create the test file `test/haptics_test.dart` with exactly this content:

    ```dart
    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/core/haptics.dart';
    import 'package:casama_app/core/widgets.dart';
    import 'package:casama_app/l10n/generated/app_localizations.dart';
    import 'package:casama_app/ui/form_sheet.dart';

    void main() {
      const channel = MethodChannel('haptic_feedback');
      late List<MethodCall> calls;

      setUp(() {
        calls = [];
        HapticsHelper.debugReset();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'canVibrate' ? true : null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        HapticsHelper.debugReset();
      });

      List<String> played() => [for (final c in calls) if (c.method != 'canVibrate') c.method];

      Widget app(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

      testWidgets('an error snackbar plays the error haptic as touch feedback', (tester) async {
        await tester.pumpWidget(app(Builder(builder: (context) => TextButton(onPressed: () => showError(context, Exception('Nope')), child: const Text('Fail')))));
        await tester.tap(find.text('Fail'));
        await tester.pump();
        expect(played(), ['error']);
        expect((calls.last.arguments as Map)['usage'], 'touch');
      });

      testWidgets('success and warning snackbars play their haptics', (tester) async {
        await tester.pumpWidget(app(Builder(
          builder: (context) => Column(children: [
            TextButton(onPressed: () => showSuccess(context, 'Saved'), child: const Text('Save')),
            TextButton(onPressed: () => showWarning(context, 'Check the email'), child: const Text('Warn')),
          ]),
        )));
        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.tap(find.text('Warn'));
        await tester.pump();
        expect(played(), ['success', 'warning']);
      });

      testWidgets('flipping a form switch plays a light tap', (tester) async {
        var on = false;
        await tester.pumpWidget(app(StatefulBuilder(builder: (context, setState) => FormSwitch(title: 'Wi-Fi', value: on, onChanged: (v) => setState(() => on = v)))));
        await tester.tap(find.text('Wi-Fi'));
        await tester.pump();
        expect(on, isTrue);
        expect(played(), ['light']);
      });

      testWidgets('a disabled control stays disabled', (tester) async {
        expect(hapticOnChanged<bool>(null), isNull);
      });

      testWidgets('desktop plays nothing', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        await HapticsHelper.success();
        debugDefaultTargetPlatformOverride = null;
        expect(calls, isEmpty);
      });

      testWidgets('without the plugin nothing throws', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        // The test engine answers unknown channels for real, outside the test's fake clock.
        await tester.runAsync(() async {
          await HapticsHelper.error();
          await HapticsHelper.error();
        });
      });
    }
    ```

    Then format only this new file: `dart format -l 200 test/haptics_test.dart`.

18. Run `flutter test test/haptics_test.dart`. All 6 tests must pass.

19. Run the whole suite: `flutter test`. Nothing that passed before may fail. Pay attention to
    `test/create_menu_test.dart`, `test/bot_profile_test.dart`, `test/board_test.dart`,
    `test/search_test.dart`, `test/tasks_phone_test.dart` and `test/phone_layout_test.dart`.

20. Build once for each mobile platform, so the new plugin is linked: `flutter build apk --debug`
    and `flutter build ios --debug --no-codesign`.

## Check it

- `dart analyze lib test/haptics_test.dart` shows no new errors, warnings or infos compared with
  before your change (no unused imports).
- `grep -c "haptic_feedback: 0.8.0" pubspec.yaml` → `1`
- `grep -c "usage: HapticsUsage.touch" lib/core/haptics.dart` → `1`
- `grep -c "HapticsHelper.error();" lib/core/widgets.dart` → `2` (in `showError` and `showFailure`)
- `grep -c "^void show\(Success\|Warning\|Failure\)(" lib/core/widgets.dart` → `3`
- `grep -c "if (destructive) HapticsHelper.heavy();" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "hapticOnChanged(onChanged)" lib/ui/form_sheet.dart` → `1`
- `grep -c "HapticsHelper.selection();" lib/ui/segmented.dart` → `1`
- `grep -c "HapticsHelper.success();" lib/features/auth/sign_in_screen.dart` → `4`
- `grep -c "if (!p.restored) HapticsHelper.success();" lib/core/billing.dart` → `1`
- `grep -c "hapticOnChanged(" lib/features/workspaces/spaces.dart` → `6`
- `grep -c "hapticOnChanged(" lib/features/board/board_screen.dart` → `8`
- `grep -c "showMessage(" lib/features/chat/chat_screen.dart` → `0`
- `grep -c "haptic_feedback" ../THIRD_PARTY_NOTICES.md` → `1`
- `flutter test test/haptics_test.dart` passes.

## Don't touch

- The existing `HapticFeedback.*` calls listed under "Already covered": they work. Don't migrate
  them in this change.
- `lib/ui/otp_code_field.dart`: keeps its own haptics (a wrong code also shows an error snackbar).
- Neutral `showMessage` calls ("Copied", "Link copied", "Plugin is up to date", "Call ended",
  approve/deny in the inbox, the ChatGPT connect result in `model_keys_screen.dart:120`): leave
  them neutral.
- Chips (`ChoiceChip`, `FilterChip`), `PopupMenuButton` and `MenuAnchor` items: browsing and
  actions, not key moments. No haptics there.
- Don't change `runGuarded`. It already calls `showError`, which now plays the error haptic.
- No `.adaptive` switches and no design changes. No other new dependencies. No refactors, renames,
  or cleanups beyond the fix.
- Existing widget `Key`s: keep them all.
- Don't run `dart format` on existing files or folders (only on the files this plan creates). No
  git commands (shared tree; others commit).

## STOP if

- Any quoted code in "Where" or in steps 4-12 doesn't match (the codebase moved on since this plan
  was written). Line numbers that shifted are fine if the text is the same.
- In the long lists of steps 13-15, one site's text is no longer there or has changed: don't guess.
  Leave that one, finish the rest, and list the skipped `file:line` entries in your report. If more
  than 10 are missing, stop and report instead.
- `flutter pub get` can't resolve `haptic_feedback: 0.8.0`, or a mobile build fails because of it.
- `lib/core/haptics.dart` already exists.
- The fix seems to require touching something in "Don't touch".
- A test that passed before your change fails after it, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: "Key moments now have a subtle haptic on phones: errors, saves and
sign-in, purchases, switches, dropdowns, choice sheets, segmented controls, tabs, pull to refresh,
and confirming a delete. They follow the phone's haptics setting and stay silent on desktop and web.
On a phone, open Settings and flip a switch, then try to sign in with a wrong password."
