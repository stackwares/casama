# Fix: The keyboard stays over half the screen while you scroll forms and search results

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/dismiss-keyboard-on-scroll
- **Needs new dependency**: none

## Why

People finish typing in New bot, New routine, sign-in, the two-step code or a ticket comment, then
scroll to see the rest, and the keyboard keeps covering half the screen. The same happens after typing
in the model, persona, app, photo or workspace search and scrolling the results. Scrolling means "I'm
done typing, show me what's below", so the keyboard should get out of the way. Chats are the
exception: there people scroll up to reread a message while still typing, so the keyboard must stay
(today it closes there, and cuts off what they were writing).

## Where

Line numbers are from when this plan was written and may have moved. Find every spot by the quoted
text.

**Scrollables with text fields inside that don't set `keyboardDismissBehavior`**

1. New bot, `lib/features/bots/bots_screen.dart:433` (fields at :471 name, :496 instructions; also shown inside onboarding)
   ```dart
   // lib/features/bots/bots_screen.dart:433-434 — current
       return SingleChildScrollView(
         padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
   ```
2. New routine, `lib/features/routines/routines_screen.dart:346` (eight fields from :354)
   ```dart
   // lib/features/routines/routines_screen.dart:346-347 — current
       return SingleChildScrollView(
         padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
   ```
3. Ticket detail, `lib/features/board/board_screen.dart:581` (comment field at :670)
   ```dart
   // lib/features/board/board_screen.dart:580-582 — current
       final me = ref.watch(backendProvider).userId;
       return SingleChildScrollView(
         padding: const EdgeInsets.all(AppSpace.lg),
   ```
4. New password, `lib/features/auth/account_screen.dart:165` (two password fields in `_PasswordForm`)
   ```dart
   // lib/features/auth/account_screen.dart:165-166 — current
             child: SingleChildScrollView(
               padding: const EdgeInsets.all(AppSpace.lg),
   ```
5. Sign-in options sheet, `lib/features/auth/sign_in_screen.dart:417` (email and password fields at :528, :556)
   ```dart
   // lib/features/auth/sign_in_screen.dart:417-418 — current
       return SingleChildScrollView(
         padding: EdgeInsets.fromLTRB(
   ```
6. Two-step code, `lib/features/auth/two_step_screen.dart:329` (`OtpCodeField` at :374)
   ```dart
   // lib/features/auth/two_step_screen.dart:329-330 — current
               return SingleChildScrollView(
                 padding: const EdgeInsets.all(AppSpace.lg),
   ```
7. Name step, `lib/features/settings/name_step.dart:116` (name field at :187)
   ```dart
   // lib/features/settings/name_step.dart:116-117 — current
                 builder: (context, constraints) => SingleChildScrollView(
                   child: ConstrainedBox(
   ```
8. Workspace onboarding, `lib/features/workspaces/onboarding_screen.dart:182` (fields at :68, :105, and the embedded New bot form)
   ```dart
   // lib/features/workspaces/onboarding_screen.dart:182-183 — current
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.xl),
   ```
9. Connect an app sheet, `lib/features/integrations/connect_app_sheet.dart:205` (field at :382)
   ```dart
   // lib/features/integrations/connect_app_sheet.dart:205-206 — current
             child: SingleChildScrollView(
               padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
   ```

**Search results under a search field** (the article's "Search" case: you type, then scroll the results)

10. Model picker, `lib/features/bots/model_picker.dart:206` (search field `modelSearch` at :146, autofocused)
    ```dart
    // lib/features/bots/model_picker.dart:206-207 — current
                  return ListView.builder(
                    itemCount: rows.length,
    ```
11. Persona gallery, `lib/features/bots/template_picker.dart:285` (search field `personaSearch` at :234)
    ```dart
    // lib/features/bots/template_picker.dart:285-286 — current
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpace.lg),
    ```
12. Composio/Pipedream app picker, `lib/features/integrations/provider_setup.dart:225` (search field `providerAppSearch` at :207)
    ```dart
    // lib/features/integrations/provider_setup.dart:225-226 — current
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpace.lg),
    ```
13. Workspace search, `lib/features/search/search_view.dart:172` (search field at :151, autofocused)
    ```dart
    // lib/features/search/search_view.dart:172-173 — current
                          : ListView(
                              padding: const EdgeInsets.only(bottom: AppSpace.xl),
    ```
14. Wallpaper photo search, `lib/features/settings/photo_picker.dart:136` (search field `photoSearch` at :92)
    ```dart
    // lib/features/settings/photo_picker.dart:136-137 — current
                      builder: (context, c) => GridView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpace.lg),
    ```

**Chat: set to `onDrag` today, must be `manual`** (the article: "Skip it in chat")

15. The chat thread, `lib/features/chat/chat_screen.dart:495-497` (the composer below it stays focused while people scroll up to reread)
    ```dart
    // lib/features/chat/chat_screen.dart:495-497 — current
                      return ListView.builder(
                        controller: _scroll,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```
16. The empty chat with starter requests, `lib/features/chat/chat_screen.dart:1150-1151` (`_EmptyThread`)
    ```dart
    // lib/features/chat/chat_screen.dart:1150-1151 — current
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```

**Already right (leave alone):** `PageColumn` and `PageListView` in `lib/ui/page.dart` (every Settings-style page,
including those with search fields: Themes, Fonts, Gallery, Apps, Skill catalog, Quick ask, About you, Teach),
`FormSheet`'s scrolling fields (`lib/ui/form_sheet.dart:175`, every form sheet) and `showChoiceSheet`
(`lib/ui/form_sheet.dart:376`) already set `ScrollViewKeyboardDismissBehavior.onDrag`.

## The fix

The article's fix, scrollable by scrollable: set `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`
on every scrollable whose drag means "done typing" (forms and search results), and leave chats on
`ScrollViewKeyboardDismissBehavior.manual`, where people scroll while still typing.

```dart
// target, forms and search results
SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  padding: ...,
)
```

```dart
// target, chat
ListView.builder(
  controller: _scroll,
  // A chat keeps the keyboard up while you scroll back to reread; tap the thread to put it away.
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
  ...
)
```

In a chat, people can still put the keyboard away by tapping the thread (the app root's
`_DismissKeyboard` in `lib/app.dart` does that), so `manual` costs them nothing.

Each step only inserts the new line directly below the line that opens the scrollable (or swaps
`onDrag` for `manual` in the chat), so it works whether or not other fixes changed the padding lines.
Imitate `lib/ui/page.dart:58`, which already does it right.

## Steps

Edit files by hand. Never run `dart format` on an existing file or folder. Keep every existing `Key`.
Copy the indentation of the line below the one you match.

1. **New bot (Where 1).** In `lib/features/bots/bots_screen.dart` replace `    return SingleChildScrollView(` with:
   ```dart
       return SingleChildScrollView(
         keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
2. **New routine (Where 2).** In `lib/features/routines/routines_screen.dart` replace `    return SingleChildScrollView(` with:
   ```dart
       return SingleChildScrollView(
         keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
3. **Ticket detail (Where 3).** In `lib/features/board/board_screen.dart` replace the two lines
   `    final me = ref.watch(backendProvider).userId;` + `    return SingleChildScrollView(` (the pair at :580-581;
   the same first line also appears earlier in the file, the pair doesn't) with:
   ```dart
       final me = ref.watch(backendProvider).userId;
       return SingleChildScrollView(
         keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
4. **New password (Where 4).** In `lib/features/auth/account_screen.dart` replace `          child: SingleChildScrollView(` with:
   ```dart
             child: SingleChildScrollView(
               keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
5. **Sign-in options (Where 5).** In `lib/features/auth/sign_in_screen.dart` replace `    return SingleChildScrollView(` with:
   ```dart
       return SingleChildScrollView(
         keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
   (Only this one. The sign-in screen's own scroll view at :52 has no text field; leave it.)
6. **Two-step code (Where 6).** In `lib/features/auth/two_step_screen.dart` replace `            return SingleChildScrollView(` with:
   ```dart
               return SingleChildScrollView(
                 keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
7. **Name step (Where 7).** In `lib/features/settings/name_step.dart` replace
   `              builder: (context, constraints) => SingleChildScrollView(` with:
   ```dart
                 builder: (context, constraints) => SingleChildScrollView(
                   keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
8. **Workspace onboarding (Where 8).** In `lib/features/workspaces/onboarding_screen.dart` replace `              child: SingleChildScrollView(` with:
   ```dart
                 child: SingleChildScrollView(
                   keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
9. **Connect an app (Where 9).** In `lib/features/integrations/connect_app_sheet.dart` replace `          child: SingleChildScrollView(` with:
   ```dart
             child: SingleChildScrollView(
               keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
   ```
10. **Model picker (Where 10).** In `lib/features/bots/model_picker.dart` replace `              return ListView.builder(` with:
    ```dart
                  return ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```
11. **Persona gallery (Where 11).** In `lib/features/bots/template_picker.dart` replace `                return GridView.builder(` with:
    ```dart
                    return GridView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```
12. **App picker (Where 12).** In `lib/features/integrations/provider_setup.dart` replace `                return ListView.separated(` with:
    ```dart
                    return ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```
13. **Workspace search (Where 13).** In `lib/features/search/search_view.dart` replace `                      : ListView(` with:
    ```dart
                          : ListView(
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```
14. **Photo search (Where 14).** In `lib/features/settings/photo_picker.dart` replace
    `                  builder: (context, c) => GridView.builder(` with:
    ```dart
                      builder: (context, c) => GridView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    ```
15. **Chat thread (Where 15).** In `lib/features/chat/chat_screen.dart` replace the two lines
    `                    controller: _scroll,` + `                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,`
    (20 spaces of indentation each) with:
    ```dart
                        controller: _scroll,
                        // A chat keeps the keyboard up while you scroll back to reread; tap the thread to put it away.
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
    ```
16. **Empty chat (Where 16).** In `lib/features/chat/chat_screen.dart` replace the two lines
    `    return CustomScrollView(` + `      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,` with:
    ```dart
        return CustomScrollView(
          // Part of the chat: the keyboard stays up while you scroll (see the thread).
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
    ```

17. **Add a widget test.** Create `test/keyboard_dismiss_test.dart` with:
    ```dart
    // Scrolling a form or search results puts the keyboard away; in a chat it stays up while you scroll.
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/core/backend.dart';
    import 'package:casama_app/features/auth/account_screen.dart';
    import 'package:casama_app/features/bots/bots_screen.dart';
    import 'package:casama_app/features/chat/chat_screen.dart';
    import 'package:casama_app/features/chat/widgets/composer.dart';

    import 'app_test.dart' show harness, setSize;
    import 'fake_backend.dart';

    void main() {
      testWidgets('dragging the new-bot form puts the keyboard away', (tester) async {
        await setSize(tester, const Size(390, 420));
        await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: CreateBotSheet())));
        await tester.pumpAndSettle();
        final form = find.descendant(of: find.byType(CreateBotSheet), matching: find.byType(SingleChildScrollView)).first;
        expect(tester.widget<SingleChildScrollView>(form).keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);

        final instructions = find.descendant(of: find.byKey(const Key('botInstructions')), matching: find.byType(EditableText));
        await tester.showKeyboard(find.byKey(const Key('botInstructions')));
        expect(tester.widget<EditableText>(instructions).focusNode.hasFocus, isTrue);

        // Drag in the form's left margin, so the gesture starts on the scroll view itself.
        await tester.dragFrom(tester.getTopLeft(form) + const Offset(6, 300), const Offset(0, -150));
        await tester.pump();
        expect(tester.widget<EditableText>(instructions).focusNode.hasFocus, isFalse);
      });

      testWidgets('the new-password page puts the keyboard away on scroll', (tester) async {
        await setSize(tester, const Size(500, 1000));
        await tester.pumpWidget(harness(FakeBackend()..newPasswordNeeded = true, const NewPasswordScreen()));
        final page = find.descendant(of: find.byType(NewPasswordScreen), matching: find.byType(SingleChildScrollView)).first;
        expect(tester.widget<SingleChildScrollView>(page).keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);
      });

      testWidgets('a chat keeps the keyboard up while you scroll the thread', (tester) async {
        await setSize(tester, const Size(390, 844));
        final b = FakeBackend()
          ..storedMessages = [
            for (var i = 0; i < 30; i++)
              ChatMessageView(id: 'm$i', role: i.isEven ? 'user' : 'assistant', text: 'Message number $i', createdAt: DateTime(2026, 11, 1, 0, i)),
          ];
        await tester.pumpWidget(harness(b, const ChatScreen(botId: botId, conversationId: convId)));
        await tester.pumpAndSettle();
        final thread = find.byType(ListView).first;
        expect(tester.widget<ListView>(thread).keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.manual);

        final composer = find.descendant(of: find.byType(ChatComposer), matching: find.byType(EditableText));
        await tester.showKeyboard(find.descendant(of: find.byType(ChatComposer), matching: find.byType(TextField)));
        await tester.drag(thread, const Offset(0, 200));
        await tester.pump();
        expect(tester.widget<EditableText>(composer).focusNode.hasFocus, isTrue);
      });
    }
    ```
    Then run `dart format -l 200 test/keyboard_dismiss_test.dart` (this new file only).

18. **Run the tests** from `client/`:
    `flutter test test/keyboard_dismiss_test.dart test/chat_keyboard_test.dart test/simple_chat_test.dart test/autonomy_test.dart test/account_test.dart test/two_step_test.dart test/routine_editor_test.dart test/board_test.dart test/search_test.dart test/cloud_model_picker_test.dart test/phone_layout_test.dart test/app_test.dart`

## Check it

Run from `client/`:
`dart analyze lib/features/bots/bots_screen.dart lib/features/routines/routines_screen.dart lib/features/board/board_screen.dart lib/features/auth/account_screen.dart lib/features/auth/sign_in_screen.dart lib/features/auth/two_step_screen.dart lib/features/settings/name_step.dart lib/features/workspaces/onboarding_screen.dart lib/features/integrations/connect_app_sheet.dart lib/features/bots/model_picker.dart lib/features/bots/template_picker.dart lib/features/integrations/provider_setup.dart lib/features/search/search_view.dart lib/features/settings/photo_picker.dart lib/features/chat/chat_screen.dart test/keyboard_dismiss_test.dart`
reports no errors and no warnings. Existing `info` lines (for example `curly_braces_in_flow_control_structures`) were there before this change and are fine; the command exits with code 0.

- `grep -c "ScrollViewKeyboardDismissBehavior.onDrag" <file>` → 1 for each of:
  `lib/features/bots/bots_screen.dart`, `lib/features/routines/routines_screen.dart`, `lib/features/board/board_screen.dart`,
  `lib/features/auth/account_screen.dart`, `lib/features/auth/sign_in_screen.dart`, `lib/features/auth/two_step_screen.dart`,
  `lib/features/settings/name_step.dart`, `lib/features/workspaces/onboarding_screen.dart`,
  `lib/features/integrations/connect_app_sheet.dart`, `lib/features/bots/model_picker.dart`,
  `lib/features/bots/template_picker.dart`, `lib/features/integrations/provider_setup.dart`,
  `lib/features/search/search_view.dart`, `lib/features/settings/photo_picker.dart`
- `grep -c "ScrollViewKeyboardDismissBehavior.onDrag" lib/features/chat/chat_screen.dart` → 0
- `grep -c "ScrollViewKeyboardDismissBehavior.manual" lib/features/chat/chat_screen.dart` → 2
- The tests from step 18 pass.

## Don't touch

- The "Already right" scrollables at the end of "Where".
- The sign-in screen's own scroll view (`sign_in_screen.dart:52`), `EmptyState`, the join screens, the workspace list,
  Settings, Admin and the tab lists: no text field inside them.
- Horizontal rows (category chips, the chat's attachment strip, the computer's quick actions): leave them as they are.
- The chat composer (`lib/features/chat/widgets/composer.dart`) and `_DismissKeyboard` in `lib/app.dart`.
- Don't add an app-wide `ScrollBehavior` or `ScrollConfiguration` for this; the article sets it per scrollable,
  and an app-wide default would also close the keyboard in the chat and on the live computer view.
- Padding, scrollbars, `ScrollController`s and `PrimaryScrollController`s are other fixes. If one already landed and
  changed lines next to the line you match, keep it.
- No new dependencies. No refactors, renames or cleanups beyond the fix.
- No git commands (the tree is shared; others commit).

## STOP if

- The text you are told to match in a step isn't in the file (lines next to it may differ because another fix
  landed; that's fine as long as the exact text you match is there).
- A scrollable in "Where" already has a `keyboardDismissBehavior:` line (someone fixed it meanwhile): skip that
  step and mention it in your report, but STOP if the chat ones are no longer `onDrag` and not `manual` either.
- In the first test the drag doesn't move the form (the form fits on screen): lower the height in `setSize` from
  420 to 360 once; if it still doesn't scroll, stop.
- The fix seems to require touching something in "Don't touch".
- A test fails because of this change, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open
to see it. For example: on a phone, open New bot, type a name, then scroll the form; the keyboard now
slides away as soon as you scroll. In a chat it no longer does: you can scroll up to reread while the
message you're writing stays open (tap the thread to close the keyboard).
