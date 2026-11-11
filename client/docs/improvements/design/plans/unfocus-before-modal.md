# Fix: The keyboard pops back up after closing a sheet, picker or menu

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/unfocus-before-modal
- **Needs new dependency**: none

## Why

On phones, when someone types in a field (a bot's name, a routine, the chat composer, a secret)
and then taps something that opens a sheet, a picker, a menu or a scan screen, Flutter remembers
the field. When that modal closes, focus goes back to the field and the keyboard slides up again,
covering half the screen, though the person was done typing. Putting the keyboard away before any
modal opens fixes this. It has to use `FocusManager.instance.primaryFocus?.unfocus()`, the field
that actually has focus, not `FocusScope.of(context).unfocus()`, which only finds the nearest
scope. This app opens almost every sheet and dialog through one function, so one line there fixes
nearly all of them. A handful of pickers, menus and scan screens open on their own and each needs
the same line.

This applies on phones and tablets (iOS and Android, web included), where the keyboard is on
screen. On desktop, a click outside the field already unfocuses it. A modal opened from the
keyboard (for example Cmd+K search while typing in the composer) should give focus back to the
field when it closes, so the helper does nothing there.

## Where

### 1. The shared opener: every `showAdaptiveSheet`, `showConfirm`, `showTextPrompt`, `showChoiceSheet`

```dart
// lib/ui/adaptive_modal.dart:1-22 — current
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'form_sheet.dart';

bool _compact(BuildContext context) => AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;

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
```

Pages with a text field whose modals all go through that opener. They are covered by the one
change in step 2, with no edit (file: line of each `showAdaptiveSheet` / `showConfirm` /
`showTextPrompt` / `showChoiceSheet` call). This includes the bot profile's folder and computer
choice sheets, the create-bot sheet, the ticket form, the routine editor's sheets, the chat's
attach and edit sheets, and the sign-in screen:

- `lib/core/server_address.dart`: 55
- `lib/features/admin/admin_screen.dart`: 249, 427
- `lib/features/auth/account_screen.dart`: 221, 268, 347
- `lib/features/auth/sign_in_screen.dart`: 30, 304, 700
- `lib/features/board/board_screen.dart`: 88, 104, 428, 686
- `lib/features/bots/action_rules_screen.dart`: 53
- `lib/features/bots/agent_import.dart`: 29
- `lib/features/bots/bot_profile_screen.dart`: 320, 487, 539, 648, 713, 849, 872
- `lib/features/bots/bots_screen.dart`: 265, 334
- `lib/features/bots/channels_screen.dart`: 77, 83, 116
- `lib/features/bots/knowledge_screen.dart`: 39
- `lib/features/bots/links_screen.dart`: 34, 59, 101, 222
- `lib/features/bots/model_picker.dart`: 61
- `lib/features/bots/plugins_screen.dart`: 28, 75, 83
- `lib/features/bots/template_picker.dart`: 58
- `lib/features/chat/chat_screen.dart`: 53, 349, 939
- `lib/features/companion/companion_screen.dart`: 263
- `lib/features/computer/computers_screen.dart`: 24, 100, 111
- `lib/features/computer/live_view_screen.dart`: 188, 283, 342
- `lib/features/devices/device_connections_screen.dart`: 327
- `lib/features/groups/group_chats.dart`: 42
- `lib/features/integrations/connect_app_sheet.dart`: 21
- `lib/features/integrations/integrations_screen.dart`: 96
- `lib/features/integrations/provider_setup.dart`: 41, 158
- `lib/features/memory/memory_screen.dart`: 22, 33, 45
- `lib/features/notifications/checkins_sheet.dart`: 17
- `lib/features/privacy/privacy_screen.dart`: 64, 71
- `lib/features/projects/projects_screen.dart`: 88
- `lib/features/routines/routines_screen.dart`: 62, 70, 124
- `lib/features/settings/about_you_screen.dart`: 79, 91, 99
- `lib/features/settings/gallery_screen.dart`: 508
- `lib/features/settings/model_keys_screen.dart`: 474
- `lib/features/settings/password_managers_screen.dart`: 33, 35, 65
- `lib/features/settings/secrets_screen.dart`: 70
- `lib/features/settings/settings_screen.dart`: 130, 308, 533
- `lib/features/settings/themes_screen.dart`: 31, 42, 99
- `lib/features/skills/skill_catalog_screen.dart`: 243
- `lib/features/skills/skill_library.dart`: 18, 21
- `lib/features/skills/skills_screen.dart`: 30, 133, 232
- `lib/features/teach/teach_draft_screen.dart`: 93
- `lib/features/workspaces/people_screen.dart`: 177, 297, 621
- `lib/features/workspaces/spaces.dart`: 178, 200, 506, 549, 720, 850, 991
- `lib/features/workspaces/workspace_files.dart`: 45, 52, 54
- `lib/ui/form_sheet.dart`: 255, 371

### 2. Modals opened directly, on pages where a field can have focus

```dart
// lib/features/workspaces/spaces.dart:470-472 — current (EncryptionSection's confirm dialog, on the
// Workspace settings page, which has the workspace-name field)
    Future<void> toggle(bool v) async {
      if (v) {
        final ok = await showDialog<bool>(
```

```dart
// lib/features/routines/routines_screen.dart:314-315 — current (routine editor: time picker; the
// editor has the name, instructions and trigger fields)
  Future<void> _pickRepeatTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
```

```dart
// lib/features/routines/routines_screen.dart:323-324 — current (routine editor: date then time picker)
  Future<void> _pickTime() async {
    final date = await showDatePicker(context: context, initialDate: _runAt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
```

```dart
// lib/features/notifications/checkins_sheet.dart:62-64 — current (check-ins sheet: time picker; the
// sheet has a text field)
              : () async {
                  final p = _time.split(':').map(int.parse).toList();
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: p[0], minute: p[1]));
```

```dart
// lib/features/workspaces/join_flow.dart:533-534 — current (join sheet: the scan screen opens over
// the invite-code field)
                    onPressed: () async {
                      final v = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanInvitePage()));
```

```dart
// lib/features/settings/totp_scan.dart:1-6 and 23-24 — current (the scan button sits inside the
// secret form's value field, and in the chat's secret-request card next to the composer)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/widgets.dart';
```
```dart
      onPressed: () async {
        final link = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanPage()));
```

```dart
// lib/features/chat/widgets/message_actions.dart:57-58 — current (long-press menu on a message,
// opened with showMenu while the composer may be focused)
  Future<void> _menu(BuildContext context, Offset at) async {
    HapticFeedback.mediumImpact();
```

```dart
// lib/features/settings/about_you_screen.dart:244-245 — current (a fact's ⋮ menu, on the page with
// the name, pronouns, reply-style and about-me fields)
      trailing: PopupMenuButton<String>(
        tooltip: l10n.moreActions,
```

```dart
// lib/features/settings/model_keys_screen.dart:567-569 — current (a key's menu, on the page with the
// inline add-key form)
            PopupMenuButton<String>(
              key: Key('keyMenu-${k.id}'),
              tooltip: l10n.moreActions,
```

```dart
// lib/features/workspaces/people_screen.dart:440-441 — current (a pending invite's menu, on the page
// with the email-invite field)
                trailing: PopupMenuButton<String>(
                  key: Key('pendingMenu-${i.id}'),
```

## The fix

The article's fix: call `FocusManager.instance.primaryFocus?.unfocus();` before opening a modal.
It lives in one small helper next to the shared opener, limited to iOS and Android as explained in
"Why":

```dart
// target: lib/ui/adaptive_modal.dart (new import + helper + first line of showAdaptiveSheet)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
...
bool _compact(BuildContext context) => AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;

/// Puts the keyboard away before a sheet, dialog, picker or menu opens, so closing it doesn't bring
/// the keyboard back: the person was done typing. Phones and tablets only. With a hardware keyboard
/// (desktop), focus going back to the field afterwards is what people expect.
void unfocusBeforeModal() {
  if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

/// Opens [builder] as a bottom sheet on phones ...
Future<T?> showAdaptiveSheet<T>({
  ...
  double dialogMaxHeight = 720,
}) {
  unfocusBeforeModal();
  if (_compact(context)) {
  ...
```

For the direct openers, `unfocusBeforeModal();` is the first statement of the handler, before the
picker, dialog, menu or scan screen opens. For `PopupMenuButton`, the handler that opens the menu
belongs to Flutter. `onOpened: unfocusBeforeModal,` runs in the same frame the menu is pushed,
before the menu takes focus. It was checked that the field then stays unfocused after the menu
closes, and without it the field gets focus back.

## Steps

1. In `lib/ui/adaptive_modal.dart`, find the line `import 'package:flutter/material.dart';` and add
   directly **above** it:
   ```dart
   import 'package:flutter/foundation.dart';
   ```

2. In `lib/ui/adaptive_modal.dart`, find the line
   `bool _compact(BuildContext context) => AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;`
   and add directly below it (one blank line first):
   ```dart

   /// Puts the keyboard away before a sheet, dialog, picker or menu opens, so closing it doesn't bring
   /// the keyboard back: the person was done typing. Phones and tablets only. With a hardware keyboard
   /// (desktop), focus going back to the field afterwards is what people expect.
   void unfocusBeforeModal() {
     if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
       FocusManager.instance.primaryFocus?.unfocus();
     }
   }
   ```

3. In `lib/ui/adaptive_modal.dart`, find these two lines (end of `showAdaptiveSheet`'s parameters):
   ```dart
     double dialogMaxHeight = 720,
   }) {
   ```
   and add as the very next line (the first statement of the function body, 2-space indent):
   ```dart
     unfocusBeforeModal();
   ```
   It must stay the first statement even if other changes have added `if (_compact(context) && heightFactor ...)`
   blocks to this function. Those come after it.

4. In `lib/features/workspaces/spaces.dart`, inside `Future<void> toggle(bool v) async {`, replace
   ```dart
         if (v) {
           final ok = await showDialog<bool>(
   ```
   with
   ```dart
         if (v) {
           unfocusBeforeModal();
           final ok = await showDialog<bool>(
   ```
   (The file already imports `../../ui/adaptive_modal.dart`.)

5. In `lib/features/routines/routines_screen.dart`:
   - Replace `  Future<void> _pickRepeatTime() async {` with these two lines:
     ```dart
       Future<void> _pickRepeatTime() async {
         unfocusBeforeModal();
     ```
   - Replace `  Future<void> _pickTime() async {` with these two lines:
     ```dart
       Future<void> _pickTime() async {
         unfocusBeforeModal();
     ```
   (The file already imports `../../ui/adaptive_modal.dart`.)

6. In `lib/features/notifications/checkins_sheet.dart`, replace
   ```dart
                 : () async {
                     final p = _time.split(':').map(int.parse).toList();
   ```
   with
   ```dart
                 : () async {
                     unfocusBeforeModal();
                     final p = _time.split(':').map(int.parse).toList();
   ```
   (The file already imports `../../ui/adaptive_modal.dart`.)

7. In `lib/features/workspaces/join_flow.dart`, replace
   ```dart
                       onPressed: () async {
                         final v = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanInvitePage()));
   ```
   with
   ```dart
                       onPressed: () async {
                         unfocusBeforeModal();
                         final v = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanInvitePage()));
   ```
   (The file already imports `../../ui/adaptive_modal.dart`.)

8. In `lib/features/settings/totp_scan.dart`:
   - Find `import '../../core/widgets.dart';` and add directly below it:
     ```dart
     import '../../ui/adaptive_modal.dart';
     ```
   - Replace
     ```dart
           onPressed: () async {
             final link = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanPage()));
     ```
     with
     ```dart
           onPressed: () async {
             unfocusBeforeModal();
             final link = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanPage()));
     ```

9. In `lib/features/chat/widgets/message_actions.dart`, replace
   `  Future<void> _menu(BuildContext context, Offset at) async {` with these two lines:
   ```dart
     Future<void> _menu(BuildContext context, Offset at) async {
       unfocusBeforeModal();
   ```
   Leave the `HapticFeedback.mediumImpact();` line that follows as it is. (The file already imports
   `../../../ui/adaptive_modal.dart`.)

10. In `lib/features/settings/about_you_screen.dart`, replace
    ```dart
          trailing: PopupMenuButton<String>(
            tooltip: l10n.moreActions,
    ```
    with
    ```dart
          trailing: PopupMenuButton<String>(
            tooltip: l10n.moreActions,
            onOpened: unfocusBeforeModal,
    ```

11. In `lib/features/settings/model_keys_screen.dart`, replace
    ```dart
                  key: Key('keyMenu-${k.id}'),
                  tooltip: l10n.moreActions,
    ```
    with
    ```dart
                  key: Key('keyMenu-${k.id}'),
                  tooltip: l10n.moreActions,
                  onOpened: unfocusBeforeModal,
    ```

12. In `lib/features/workspaces/people_screen.dart`, replace
    ```dart
                    key: Key('pendingMenu-${i.id}'),
    ```
    with
    ```dart
                    key: Key('pendingMenu-${i.id}'),
                    onOpened: unfocusBeforeModal,
    ```

13. Create the test file `test/unfocus_before_modal_test.dart` with exactly this content:

    ```dart
    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/l10n/generated/app_localizations.dart';
    import 'package:casama_app/ui/adaptive_modal.dart';

    Widget _page(FocusNode field) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              TextField(key: const Key('field'), focusNode: field),
              TextButton(
                key: const Key('openSheet'),
                onPressed: () => showAdaptiveSheet<void>(
                  context: context,
                  builder: (sheet) => TextButton(key: const Key('closeSheet'), onPressed: () => Navigator.pop(sheet), child: const Text('Close')),
                ),
                child: const Text('Open'),
              ),
              PopupMenuButton<String>(
                key: const Key('menu'),
                onOpened: unfocusBeforeModal,
                itemBuilder: (_) => const [PopupMenuItem(value: 'a', child: Text('Pick A'))],
                onSelected: (_) {},
              ),
            ],
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
      testWidgets('closing a sheet does not bring the keyboard back on a phone', (tester) async {
        await _phone(tester);
        final field = FocusNode();
        addTearDown(field.dispose);
        await tester.pumpWidget(_page(field));
        await tester.tap(find.byKey(const Key('field')));
        await tester.pump();
        expect(field.hasFocus, isTrue);

        await tester.tap(find.byKey(const Key('openSheet')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('closeSheet')));
        await tester.pumpAndSettle();
        expect(field.hasFocus, isFalse);
        expect(tester.testTextInput.isVisible, isFalse);
      });

      testWidgets('closing a menu does not bring the keyboard back on a phone', (tester) async {
        await _phone(tester);
        final field = FocusNode();
        addTearDown(field.dispose);
        await tester.pumpWidget(_page(field));
        await tester.tap(find.byKey(const Key('field')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pick A'));
        await tester.pumpAndSettle();
        expect(field.hasFocus, isFalse);
      });

      testWidgets('on desktop a sheet opened from the keyboard gives the field its focus back', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        await _phone(tester);
        final field = FocusNode();
        addTearDown(field.dispose);
        await tester.pumpWidget(_page(field));
        await tester.tap(find.byKey(const Key('field')));
        await tester.pump();
        expect(field.hasFocus, isTrue);
        // Like a keyboard shortcut: no click outside the field first (a click would unfocus it).
        tester.widget<TextButton>(find.byKey(const Key('openSheet'))).onPressed!();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('closeSheet')));
        await tester.pumpAndSettle();
        expect(field.hasFocus, isTrue);
        debugDefaultTargetPlatformOverride = null;
      });
    }
    ```

    Then format only this new file: `dart format -l 200 test/unfocus_before_modal_test.dart`.

14. Run `flutter test test/unfocus_before_modal_test.dart`. All 3 tests must pass.

15. Run the tests for the screens you touched, plus the sheet-heavy ones:
    `flutter test test/routine_editor_test.dart test/checkins_test.dart test/about_you_test.dart test/joining_test.dart test/spaces_test.dart test/secret_request_test.dart test/chat_keyboard_test.dart test/create_menu_test.dart test/bot_profile_test.dart test/board_test.dart test/search_test.dart test/phone_layout_test.dart`.
    All must pass. Then run the whole suite with `flutter test`. Nothing that passed before may fail.

## Check it

- `dart analyze lib/ui/adaptive_modal.dart lib/features/workspaces/spaces.dart lib/features/routines/routines_screen.dart lib/features/notifications/checkins_sheet.dart lib/features/workspaces/join_flow.dart lib/features/settings/totp_scan.dart lib/features/chat/widgets/message_actions.dart lib/features/settings/about_you_screen.dart lib/features/settings/model_keys_screen.dart lib/features/workspaces/people_screen.dart test/unfocus_before_modal_test.dart` reports no issues.
- `grep -c "FocusManager.instance.primaryFocus?.unfocus();" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "unfocusBeforeModal();" lib/ui/adaptive_modal.dart` → `1`
- `grep -c "unfocusBeforeModal();" lib/features/routines/routines_screen.dart` → `2`
- `grep -c "unfocusBeforeModal();" lib/features/workspaces/spaces.dart` → `1`
- `grep -c "unfocusBeforeModal();" lib/features/notifications/checkins_sheet.dart` → `1`
- `grep -c "unfocusBeforeModal();" lib/features/workspaces/join_flow.dart` → `1`
- `grep -c "unfocusBeforeModal();" lib/features/settings/totp_scan.dart` → `1`
- `grep -c "unfocusBeforeModal();" lib/features/chat/widgets/message_actions.dart` → `1`
- `grep -c "onOpened: unfocusBeforeModal," lib/features/settings/about_you_screen.dart` → `1`
- `grep -c "onOpened: unfocusBeforeModal," lib/features/settings/model_keys_screen.dart` → `1`
- `grep -c "onOpened: unfocusBeforeModal," lib/features/workspaces/people_screen.dart` → `1`
- `flutter test test/unfocus_before_modal_test.dart` passes.

## Don't touch

- `DropdownButton` / `DropdownButtonFormField` anywhere: Flutter already moves focus to the dropdown
  before its menu opens, so the keyboard doesn't come back.
- `MenuAnchor` menus (`lib/features/chat/chat_screen.dart`, `lib/features/board/board_screen.dart`,
  `lib/features/routines/routines_screen.dart`): they open in an overlay without taking focus, so
  nothing gets focus back. Their items that open sheets go through `showAdaptiveSheet` and are
  covered.
- Direct openers on pages with no field that could have focus at that moment. No edit:
  `lib/features/calls/outbound_call_screen.dart:59` and `lib/features/bots/links_screen.dart:117`
  (their only field is inside the dialog itself), `lib/features/computer/computers_screen.dart`
  (dialog and menu on the computers list), `lib/features/inbox/for_you.dart:86`,
  `lib/features/notifications/quiet_hours.dart:76`, `lib/features/voice/call_screen.dart:323`, and
  the `PopupMenuButton`s in `plugins_screen.dart`, `themes_screen.dart`, `settings_screen.dart`,
  `memory_screen.dart`, `integration_detail_screen.dart`, `pages_screen.dart` and
  `computer_screen.dart`.
- `lib/app.dart`'s `_DismissKeyboard` (tap on empty space puts the keyboard away) and
  `lib/features/chat/chat_screen.dart:342` (unfocus after sending): leave them.
- Don't use `FocusScope.of(context).unfocus()` anywhere. It is the wrong tool.
- How sheets look or move (`showModalBottomSheet` / dialog code in `adaptive_modal.dart`):
  unchanged by this plan.
- Existing widget `Key`s: keep them all. No new dependencies. No refactors, renames, or cleanups
  beyond the fix.
- Don't run `dart format` on existing files or folders (only on the test file this plan creates).
  No git commands (shared tree; others commit).

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since
  this plan was written). Line numbers that shifted are fine if the text is the same. Extra
  `if (_compact(context) && heightFactor ...)` blocks in `showAdaptiveSheet` from the sheet changes
  are expected.
- `lib/ui/adaptive_modal.dart` already defines `unfocusBeforeModal`.
- The fix seems to require touching something in "Don't touch".
- A test that passed before your change fails after it, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: "On phones, the keyboard no longer pops back up after closing a sheet,
picker, menu or scan screen opened while typing. Every sheet and dialog through the shared opener
is covered, plus the routine time pickers, scan buttons and a few menus. On a phone, type in the
routine name, tap the time chip, close the picker, and the keyboard stays down."
