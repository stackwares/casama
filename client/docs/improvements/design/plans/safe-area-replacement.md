# Fix: The ends of lists get cut off above the phone's home indicator or gesture bar

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/safe-area-replacement
- **Needs new dependency**: none

## Why

Scroll a sheet such as the model picker, search, chat history or the persona gallery, or a full
screen such as sign-in or the two-step code, and the rows are cut off along an invisible line about
one thumb's width above the bottom edge. That happens because a `SafeArea` is wrapped around the
scrolling content: it shrinks the scrolling area, so rows vanish at its edge instead of sliding under
the system bar. The fix leaves the scrolling area at full height and adds bottom padding as tall as
the system bar (the home indicator on iPhone, the gesture bar or buttons on Android) at the end of
the list. The last row then rests clear of the bar, and rows pass under the bar while scrolling, the
way native apps behave.

## Where

Line numbers are from when this plan was written and may have moved. Find every spot by the quoted
text. "Already right" spots are listed at the end of this section so you leave them alone.

**Shared pieces**

1. `lib/ui/adaptive_modal.dart:15-33`: `showAdaptiveSheet` wraps every phone sheet in a bottom `SafeArea`.
   ```dart
   // lib/ui/adaptive_modal.dart:19-20 — current
     double dialogMaxWidth = 560,
     double dialogMaxHeight = 720,
   ```
   ```dart
   // lib/ui/adaptive_modal.dart:32-33 — current
           // The home-indicator inset is under the keyboard while it is open.
           final content = SafeArea(top: false, bottom: view.viewInsets.bottom == 0, child: builder(context));
   ```
2. `lib/core/widgets.dart:139-143`: `EmptyState` (used by about 50 screens and by `AsyncView` errors) is a centered `SingleChildScrollView` with a fixed bottom padding of 24.
   ```dart
   // lib/core/widgets.dart:143 — current
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
   ```
3. `lib/ui/form_sheet.dart:371-377`: `showChoiceSheet`, a scrolling sheet.
   ```dart
   // lib/ui/form_sheet.dart:371-372 — current
     return showAdaptiveSheet<Choice<T>>(
       context: context,
   ```
   ```dart
   // lib/ui/form_sheet.dart:377 — current
           padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
   ```

**Fixed-height list sheets** (the list runs to the bottom of the screen)

4. Persona gallery, `lib/features/bots/template_picker.dart`
   ```dart
   // lib/features/bots/template_picker.dart:60 — current (in showPersonaGallery)
         heightFactor: 0.9,
   ```
   ```dart
   // lib/features/bots/template_picker.dart:286 — current (the gallery GridView.builder)
                     padding: const EdgeInsets.only(bottom: AppSpace.lg),
   ```
   ```dart
   // lib/features/bots/template_picker.dart:402 — current (the _Preview ListView)
               padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
   ```
5. Model picker, `lib/features/bots/model_picker.dart`
   ```dart
   // lib/features/bots/model_picker.dart:63 — current
                   heightFactor: 0.85,
   ```
   ```dart
   // lib/features/bots/model_picker.dart:206-209 — current (no padding at all)
                 return ListView.builder(
                   itemCount: rows.length,
                   itemBuilder: (_, i) => rows[i](),
                 );
   ```
6. Wallpaper photo picker, `lib/features/settings/background_screen.dart` and `lib/features/settings/photo_picker.dart`
   ```dart
   // lib/features/settings/background_screen.dart:275-276 — current
         heightFactor: 0.9,
         builder: (_) => const PhotoPicker(),
   ```
   ```dart
   // lib/features/settings/photo_picker.dart:137 — current
                       padding: const EdgeInsets.only(bottom: AppSpace.lg),
   ```
7. Select text sheet, `lib/features/chat/widgets/message_actions.dart:39-54`
   ```dart
   // lib/features/chat/widgets/message_actions.dart:41 — current
         heightFactor: 0.7,
   ```
   ```dart
   // lib/features/chat/widgets/message_actions.dart:43 — current
           padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
   ```
   ```dart
   // lib/features/chat/widgets/message_actions.dart:48 — current
               child: SingleChildScrollView(
   ```
8. Chat history sheet, `lib/features/chat/chat_screen.dart`
   ```dart
   // lib/features/chat/chat_screen.dart:941-942 — current (in _showConversations)
         heightFactor: 0.7,
         builder: (sheetContext) => _ConversationsSheet(
   ```
   ```dart
   // lib/features/chat/chat_screen.dart:1369 — current (in _ConversationsSheet)
                       padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.md),
   ```
9. Search sheet and the `/search` screen, `lib/features/search/search_view.dart`
   ```dart
   // lib/features/search/search_view.dart:22 — current (in showWorkspaceSearch)
         heightFactor: 0.9,
   ```
   ```dart
   // lib/features/search/search_view.dart:35 — current (SearchScreen: a SafeArea around the results list)
       body: const SafeArea(top: false, child: SearchView()),
   ```
   ```dart
   // lib/features/search/search_view.dart:173 — current (the results ListView)
                             padding: const EdgeInsets.only(bottom: AppSpace.xl),
   ```
10. Composio/Pipedream app picker, `lib/features/integrations/provider_setup.dart`
    ```dart
    // lib/features/integrations/provider_setup.dart:158 — current
        showAdaptiveSheet<void>(context: context, heightFactor: 0.88, builder: (_) => _ProviderAppPicker(integration: integration));
    ```
    ```dart
    // lib/features/integrations/provider_setup.dart:226 — current
                      padding: const EdgeInsets.only(bottom: AppSpace.lg),
    ```
11. File preview, `lib/features/files/file_preview.dart`
    ```dart
    // lib/features/files/file_preview.dart:164 — current (in showComputerFile)
        heightFactor: 0.85,
    ```
    ```dart
    // lib/features/files/file_preview.dart:330 — current (markdown preview)
              padding: const EdgeInsets.all(AppSpace.lg),
    ```
    ```dart
    // lib/features/files/file_preview.dart:335-336 — current (text preview)
            padding: const EdgeInsets.all(AppSpace.md),
            child: Container(
    ```

**Sheets whose whole content scrolls** (cut off once the content is taller than the screen: small phones, large text, landscape)

12. New bot, `lib/features/bots/bots_screen.dart` and `lib/core/mac_bridge.dart`
    ```dart
    // lib/features/bots/bots_screen.dart:334 — current
      await showAdaptiveSheet<void>(context: context, builder: (_) => const CreateBotSheet());
    ```
    ```dart
    // lib/core/mac_bridge.dart:51 — current
          if (context != null && context.mounted) await showAdaptiveSheet<void>(context: context, builder: (_) => const CreateBotSheet());
    ```
    ```dart
    // lib/features/bots/bots_screen.dart:434 — current
          padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
    ```
13. Move ticket and ticket detail, `lib/features/board/board_screen.dart`
    ```dart
    // lib/features/board/board_screen.dart:88 — current
        final to = await showAdaptiveSheet<TaskStatus>(context: context, builder: (_) => _MoveSheet(task: t));
    ```
    ```dart
    // lib/features/board/board_screen.dart:333-335 — current (_MoveSheet, no padding)
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
    ```
    ```dart
    // lib/features/board/board_screen.dart:428 — current
            onTap: () => showAdaptiveSheet<void>(context: context, builder: (_) => TicketSheet(taskId: task.id)),
    ```
    ```dart
    // lib/features/board/board_screen.dart:582-585 — current (TicketSheet)
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
    ```
14. Sign-in options, `lib/features/auth/sign_in_screen.dart`
    ```dart
    // lib/features/auth/sign_in_screen.dart:31-32 — current (in openOptions)
            context: context,
            dialogMaxWidth: 460,
    ```
    ```dart
    // lib/features/auth/sign_in_screen.dart:422 — current (SignInOptions)
            AppSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
    ```
15. Invite QR, `lib/features/workspaces/join_flow.dart:581-586`
    ```dart
    // lib/features/workspaces/join_flow.dart:582-583 — current
      context: context,
      builder: (c) {
    ```
    ```dart
    // lib/features/workspaces/join_flow.dart:585-586 — current
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
    ```
16. Workspace list, `lib/features/workspaces/spaces.dart:129-138`
    ```dart
    // lib/features/workspaces/spaces.dart:130-131 — current
      context: context,
      builder: (c) => Consumer(
    ```
    ```dart
    // lib/features/workspaces/spaces.dart:137-138 — current
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
    ```
17. Invites to send yourself, `lib/features/workspaces/people_screen.dart:297-300`
    ```dart
    // lib/features/workspaces/people_screen.dart:297-300 — current
        await showAdaptiveSheet<void>(
          context: context,
          builder: (c) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
    ```
18. Connect an app, `lib/features/integrations/connect_app_sheet.dart`
    ```dart
    // lib/features/integrations/connect_app_sheet.dart:22-23 — current (in showConnectApp)
          context: context,
          dialogMaxWidth: 520,
    ```
    ```dart
    // lib/features/integrations/connect_app_sheet.dart:206 — current
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
    ```
19. New routine, `lib/features/routines/routines_screen.dart`
    ```dart
    // lib/features/routines/routines_screen.dart:63-64 — current (in _create)
          context: context,
          builder: (_) => NewRoutineSheet(botId: botId),
    ```
    ```dart
    // lib/features/routines/routines_screen.dart:347 — current (NewRoutineSheet)
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
    ```
20. Install skill where, `lib/features/skills/skill_catalog_screen.dart` (a second `SafeArea` inside the sheet)
    ```dart
    // lib/features/skills/skill_catalog_screen.dart:244-245 — current (in installCatalogSkill)
          context: context,
          builder: (_) => _TargetPicker(skill: s, bots: bots, taken: taken),
    ```
    ```dart
    // lib/features/skills/skill_catalog_screen.dart:539-541 — current (_TargetPicker)
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
    ```

**Full screens with a `SafeArea` around the scrolling content**

21. Name step, `lib/features/settings/name_step.dart`
    ```dart
    // lib/features/settings/name_step.dart:110-111 — current
          body: SafeArea(
            child: Center(
    ```
    ```dart
    // lib/features/settings/name_step.dart:121-126 — current
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.xl,
                            0,
                            AppSpace.xl,
                            AppSpace.md,
                          ),
    ```
22. Two-step code, `lib/features/auth/two_step_screen.dart` (TwoStepPromptScreen)
    ```dart
    // lib/features/auth/two_step_screen.dart:325-326 — current
          body: SafeArea(
            child: LayoutBuilder(
    ```
    ```dart
    // lib/features/auth/two_step_screen.dart:328 — current
                final minHeight = constraints.maxHeight - AppSpace.lg * 2;
    ```
    ```dart
    // lib/features/auth/two_step_screen.dart:330-333 — current
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight < 0 ? 0 : minHeight,
    ```
23. New password, `lib/features/auth/account_screen.dart` (NewPasswordScreen)
    ```dart
    // lib/features/auth/account_screen.dart:163-164 — current
          body: SafeArea(
            child: Center(
    ```
    ```dart
    // lib/features/auth/account_screen.dart:166-168 — current
                padding: const EdgeInsets.all(AppSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
    ```
24. Sign-in screen, `lib/features/auth/sign_in_screen.dart` (SignInScreen)
    ```dart
    // lib/features/auth/sign_in_screen.dart:46-47 — current
              SafeArea(
                child: Center(
    ```
    ```dart
    // lib/features/auth/sign_in_screen.dart:57-62 — current
                              padding: const EdgeInsets.fromLTRB(
                                AppSpace.xl,
                                0,
                                AppSpace.xl,
                                AppSpace.lg,
                              ),
    ```
25. Workspace onboarding, `lib/features/workspaces/onboarding_screen.dart`
    ```dart
    // lib/features/workspaces/onboarding_screen.dart:158-159 — current
          body: SafeArea(
            child: Column(
    ```
    ```dart
    // lib/features/workspaces/onboarding_screen.dart:183 — current
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.xl),
    ```
26. Join screens, `lib/features/workspaces/join_flow.dart` (JoinScreen, JoinedScreen, JoinTeamScreen and the `_JoinCard` they share)
    ```dart
    // lib/features/workspaces/join_flow.dart:229 — current
        return Scaffold(body: SafeArea(child: body));
    ```
    ```dart
    // lib/features/workspaces/join_flow.dart:307-309 — current
          body: SafeArea(
            child: _JoinCard(
              key: const Key('joinedWelcome'),
    ```
    ```dart
    // lib/features/workspaces/join_flow.dart:354-356 — current
          body: SafeArea(
            child: _JoinCard(
              key: const Key('joinTeam'),
    ```
    ```dart
    // lib/features/workspaces/join_flow.dart:248 — current (in _JoinCard)
            padding: const EdgeInsets.all(AppSpace.gutter),
    ```

**Tablets: the Tasks board columns run under the home indicator**

27. `lib/features/board/board_screen.dart:184-186` (the horizontal list of status columns on tablets and desktops)
    ```dart
    // lib/features/board/board_screen.dart:186 — current
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
    ```
28. `lib/features/board/board_screen.dart:161-179`: two empty states padded by hand for the phone tab bar. Once `EmptyState` pads itself (item 2) this would pad twice.
    ```dart
    // lib/features/board/board_screen.dart:162-167 — current
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: barInset),
                        child: EmptyState(icon: LucideIcons.squareKanban, title: l10n.noTickets, message: l10n.noTicketsHelp),
                      ),
                    )
    ```
    ```dart
    // lib/features/board/board_screen.dart:169-179 — current
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: barInset),
                        child: EmptyState(
                          icon: LucideIcons.listFilter,
                          title: l10n.noMatchingTickets,
                          message: l10n.noMatchingTicketsHelp,
                          action: TextButton(key: const Key('clearFilters'), onPressed: _clearFilters, child: Text(l10n.clearFilters)),
                        ),
                      ),
                    )
    ```

**Already right (leave alone):** `PageColumn` and `PageListView` in `lib/ui/page.dart` (every Settings-style page),
the Chats list (`bots_screen.dart:106`), Inbox (`inbox_screen.dart:253`), Settings (`settings_screen.dart:316`),
Admin (`admin_screen.dart:142`), Routines (`routines_screen.dart:50`), the computer's files and checkpoints
(`computer_screen.dart:1020`, `:1206`), the run timeline (`timeline_screen.dart:200`) and the phone ticket list
(`board_screen.dart:181`). They already end with `MediaQuery.paddingOf(context).bottom` plus a gap. Sheets built
on `FormSheet` are also right: their buttons are pinned below the scrolling fields, so the bottom `SafeArea`
sits under buttons, not under a list. The chat thread ends at the composer, which keeps its own `SafeArea`.

## The fix

The article's fix: never put a `SafeArea` around a scrollable. Add a `BottomPadding` helper that
returns the system bar's height (or a minimum where there is no bar) and use it as the bottom padding
at the end of the scrollable.

One adaptation for this app: the helper reads `MediaQuery.paddingOf` where the article reads
`MediaQuery.viewPaddingOf`. On phones, `HomeShell` (`lib/features/home/home_shell.dart:171`) passes
the floating tab bar's height down as `padding.bottom` (not `viewPadding`), and the lists that are
already right read `paddingOf`. `paddingOf(context).bottom` equals the system bar's height on every
other screen, and it drops to 0 while the keyboard is open, so nothing pads twice above the keyboard.

New file `lib/ui/bottom_padding.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Room at the end of a scrolling list or page so its last item clears the system navigation bar
/// (the home indicator on iPhone, the gesture bar or buttons on Android) instead of sitting under it.
/// Use it instead of a SafeArea around a scrollable: a SafeArea shrinks the scrolling area, so items
/// get cut off at its edge instead of sliding under the bar.
///
/// It reads MediaQuery padding: the bar's height, 0 while the keyboard is open, and on the phone's tab
/// screens the floating tab bar too (HomeShell sets it). Without a bar it is the minimum (16 unless
/// given), so content never touches the bottom edge.
class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key});

  static double of(BuildContext context, {double minimum = 16}) {
    final double padding = MediaQuery.paddingOf(context).bottom;
    return padding > minimum ? padding : minimum;
  }

  @override
  Widget build(BuildContext context) => SizedBox(height: of(context));
}
```

`showAdaptiveSheet` gets one new parameter, `contentPadsBottom` (default `false`). When it is `true`,
the phone sheet no longer wraps the content in a bottom `SafeArea`, and the content ends its own
scrollable with `BottomPadding.of(...)`. Sheets that end in non-scrolling content (forms with pinned
buttons, short menus) keep the default and the `SafeArea`, which is right for them.

Everywhere else the change is mechanical: the fixed bottom value of the padding becomes
`BottomPadding.of(context, minimum: <the old value>)`, so a device with no bar looks exactly as
before, and a full-screen `SafeArea(` becomes `SafeArea(bottom: false,` so the top notch and the
sides stay protected. Pass the `BuildContext` that is in scope at that line (`context`, `c` or
`sheet`, exactly as written in the steps).

Imitate `lib/ui/page.dart:58`, which already ends its list with the bottom inset.

## Steps

For every file you change below, also add the import of the new file if the file doesn't have it
yet, as its own line directly below the file's `theme/app_tokens.dart` import:

- files in `lib/features/<feature>/`: `import '../../ui/bottom_padding.dart';`
- `lib/features/chat/widgets/message_actions.dart`: `import '../../../ui/bottom_padding.dart';`
- `lib/ui/form_sheet.dart`: `import 'bottom_padding.dart';`
- `lib/core/widgets.dart` (no app_tokens import there): `import '../ui/bottom_padding.dart';` directly below `import '../l10n/generated/app_localizations.dart';`
- `lib/features/bots/model_picker.dart` (no app_tokens import there): directly below `import '../../ui/adaptive_modal.dart';`

Do NOT add the import to `lib/ui/adaptive_modal.dart`, `lib/features/settings/background_screen.dart`
or `lib/core/mac_bridge.dart`; they only get the new flag.

Edit files by hand. Never run `dart format` on an existing file or folder. Keep every existing `Key`.

1. **Create `lib/ui/bottom_padding.dart`** with exactly the code under "The fix". Then run
   `dart format -l 200 lib/ui/bottom_padding.dart` (this new file only).

2. **`lib/ui/adaptive_modal.dart`, the parameter.** Replace the excerpt from Where 1 (lines 19-20) with:
   ```dart
     double dialogMaxWidth = 560,
     double dialogMaxHeight = 720,
     bool contentPadsBottom = false,
   ```
   and add this paragraph to the end of the doc comment above `Future<T?> showAdaptiveSheet<T>({`
   (after the line ending `leave it null for content that sizes itself.`):
   ```dart
   /// Set [contentPadsBottom] when the content ends in a list or scroll view that runs to the bottom
   /// edge and adds BottomPadding to its own end: the phone sheet then leaves out its bottom SafeArea,
   /// so the list scrolls under the home indicator instead of being cut off above it.
   ```

3. **`lib/ui/adaptive_modal.dart`, the SafeArea.** Replace the excerpt from Where 1 (lines 32-33) with:
   ```dart
           // The home-indicator inset is under the keyboard while it is open. Content that pads its own
           // bottom (contentPadsBottom) gets no bottom SafeArea, so its list runs to the edge.
           final content = SafeArea(top: false, bottom: !contentPadsBottom && view.viewInsets.bottom == 0, child: builder(context));
   ```
   Leave the dialog branch (`showDialog`) as it is.

4. **`lib/core/widgets.dart`, `EmptyState`.** Replace the line from Where 2 with:
   ```dart
               padding: EdgeInsets.fromLTRB(32, 24, 32, BottomPadding.of(context, minimum: 24)),
   ```

5. **`lib/ui/form_sheet.dart`, `showChoiceSheet`.** Replace `  return showAdaptiveSheet<Choice<T>>(\n    context: context,` (Where 3) with:
   ```dart
     return showAdaptiveSheet<Choice<T>>(
       context: context,
       contentPadsBottom: true,
   ```
   and replace the padding line from Where 3 (line 377) with:
   ```dart
           padding: EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, BottomPadding.of(context, minimum: AppSpace.lg)),
   ```

6. **Persona gallery (Where 4).** In `template_picker.dart` replace `      heightFactor: 0.9,` with:
   ```dart
         heightFactor: 0.9,
         contentPadsBottom: true,
   ```
   Replace the GridView padding line (line 286) with:
   ```dart
                     padding: EdgeInsets.only(bottom: BottomPadding.of(context, minimum: AppSpace.lg)),
   ```
   Replace the `_Preview` ListView padding line (line 402) with:
   ```dart
               padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
   ```

7. **Model picker (Where 5).** In `model_picker.dart` replace `                heightFactor: 0.85,` with:
   ```dart
                   heightFactor: 0.85,
                   contentPadsBottom: true,
   ```
   Replace `              return ListView.builder(` (line 206, only this one line) with:
   ```dart
                 return ListView.builder(
                   padding: EdgeInsets.only(bottom: BottomPadding.of(context)),
   ```

8. **Photo picker (Where 6).** In `background_screen.dart` replace the two lines from Where 6 with:
   ```dart
         heightFactor: 0.9,
         contentPadsBottom: true,
         builder: (_) => const PhotoPicker(),
   ```
   In `photo_picker.dart` replace the padding line (line 137) with:
   ```dart
                       padding: EdgeInsets.only(bottom: BottomPadding.of(context, minimum: AppSpace.lg)),
   ```

9. **Select text (Where 7).** In `message_actions.dart` replace `      heightFactor: 0.7,` with:
   ```dart
         heightFactor: 0.7,
         contentPadsBottom: true,
   ```
   Replace the padding line (line 43) with (the bottom moves from the outer padding into the scroll view):
   ```dart
           padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, 0),
   ```
   Replace `            child: SingleChildScrollView(` (line 48) with:
   ```dart
               child: SingleChildScrollView(
                 padding: EdgeInsets.only(bottom: BottomPadding.of(sheet, minimum: AppSpace.lg)),
   ```

10. **Chat history (Where 8).** In `chat_screen.dart` replace the two lines `      heightFactor: 0.7,\n      builder: (sheetContext) => _ConversationsSheet(` with:
    ```dart
          heightFactor: 0.7,
          contentPadsBottom: true,
          builder: (sheetContext) => _ConversationsSheet(
    ```
    Replace the padding line (line 1369) with:
    ```dart
                        padding: EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, BottomPadding.of(context, minimum: AppSpace.md)),
    ```

11. **Search (Where 9).** In `search_view.dart` replace `      heightFactor: 0.9,` with:
    ```dart
          heightFactor: 0.9,
          contentPadsBottom: true,
    ```
    Replace line 35 with:
    ```dart
        body: const SafeArea(top: false, bottom: false, child: SearchView()),
    ```
    Replace the results padding line (line 173) with:
    ```dart
                              padding: EdgeInsets.only(bottom: BottomPadding.of(context, minimum: AppSpace.xl)),
    ```

12. **App picker (Where 10).** In `provider_setup.dart` replace line 158 with:
    ```dart
        showAdaptiveSheet<void>(context: context, heightFactor: 0.88, contentPadsBottom: true, builder: (_) => _ProviderAppPicker(integration: integration));
    ```
    Replace the padding line (line 226) with:
    ```dart
                      padding: EdgeInsets.only(bottom: BottomPadding.of(context, minimum: AppSpace.lg)),
    ```

13. **File preview (Where 11).** In `file_preview.dart` replace `    heightFactor: 0.85,` with:
    ```dart
        heightFactor: 0.85,
        contentPadsBottom: true,
    ```
    Replace the markdown padding line (line 330) with:
    ```dart
              padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
    ```
    Replace the two text-preview lines (335-336) with:
    ```dart
            padding: EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, BottomPadding.of(context, minimum: AppSpace.md)),
            child: Container(
    ```
    (The image preview and the "can't preview" state need nothing: images may sit under the bar, and the
    state is an `EmptyState`, fixed in step 4.)

14. **New bot (Where 12).** In `bots_screen.dart` replace line 334 with:
    ```dart
      await showAdaptiveSheet<void>(context: context, contentPadsBottom: true, builder: (_) => const CreateBotSheet());
    ```
    In `mac_bridge.dart` replace line 51 with:
    ```dart
          if (context != null && context.mounted) await showAdaptiveSheet<void>(context: context, contentPadsBottom: true, builder: (_) => const CreateBotSheet());
    ```
    In `bots_screen.dart` replace line 434 with:
    ```dart
          padding: widget.embedded ? EdgeInsets.zero : EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.md)),
    ```

15. **Board sheets (Where 13).** In `board_screen.dart` replace line 88 with:
    ```dart
        final to = await showAdaptiveSheet<TaskStatus>(context: context, contentPadsBottom: true, builder: (_) => _MoveSheet(task: t));
    ```
    Replace the three `_MoveSheet` lines (333-335) with:
    ```dart
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: BottomPadding.of(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
    ```
    Replace line 428 with:
    ```dart
            onTap: () => showAdaptiveSheet<void>(context: context, contentPadsBottom: true, builder: (_) => TicketSheet(taskId: task.id)),
    ```
    Replace the four `TicketSheet` lines (582-585) with:
    ```dart
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
    ```

16. **Sign-in options (Where 14).** In `sign_in_screen.dart` replace `        context: context,\n        dialogMaxWidth: 460,` with:
    ```dart
            context: context,
            dialogMaxWidth: 460,
            contentPadsBottom: true,
    ```
    Replace line 422 with:
    ```dart
            BottomPadding.of(context, minimum: AppSpace.lg) + MediaQuery.viewInsetsOf(context).bottom,
    ```

17. **Invite QR (Where 15).** In `join_flow.dart` replace `  context: context,\n  builder: (c) {` with:
    ```dart
      context: context,
      contentPadsBottom: true,
      builder: (c) {
    ```
    Replace `    return SingleChildScrollView(\n      padding: const EdgeInsets.all(AppSpace.lg),` with:
    ```dart
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(c, minimum: AppSpace.lg)),
    ```

18. **Workspace list (Where 16).** In `spaces.dart` replace `  context: context,\n  builder: (c) => Consumer(` with:
    ```dart
      context: context,
      contentPadsBottom: true,
      builder: (c) => Consumer(
    ```
    Replace `      return SingleChildScrollView(\n        padding: const EdgeInsets.all(AppSpace.lg),` with:
    ```dart
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
    ```

19. **Invites to send yourself (Where 17).** In `people_screen.dart` replace the four lines from Where 17 with:
    ```dart
        await showAdaptiveSheet<void>(
          context: context,
          contentPadsBottom: true,
          builder: (c) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(c, minimum: AppSpace.lg)),
    ```

20. **Connect an app (Where 18).** In `connect_app_sheet.dart` replace `      context: context,\n      dialogMaxWidth: 520,` with:
    ```dart
          context: context,
          dialogMaxWidth: 520,
          contentPadsBottom: true,
    ```
    Replace line 206 with:
    ```dart
                padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
    ```

21. **New routine (Where 19).** In `routines_screen.dart` replace `      context: context,\n      builder: (_) => NewRoutineSheet(botId: botId),` with:
    ```dart
          context: context,
          contentPadsBottom: true,
          builder: (_) => NewRoutineSheet(botId: botId),
    ```
    Replace line 347 with:
    ```dart
          padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.md)),
    ```

22. **Install skill where (Where 20).** In `skill_catalog_screen.dart` replace `      context: context,\n      builder: (_) => _TargetPicker(skill: s, bots: bots, taken: taken),` with:
    ```dart
          context: context,
          contentPadsBottom: true,
          builder: (_) => _TargetPicker(skill: s, bots: bots, taken: taken),
    ```
    Replace the three `_TargetPicker` lines (539-541) with:
    ```dart
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
    ```

23. **Name step (Where 21).** In `name_step.dart` replace `      body: SafeArea(\n        child: Center(` with:
    ```dart
          body: SafeArea(
            bottom: false,
            child: Center(
    ```
    Replace the six padding lines (121-126) with:
    ```dart
                          padding: EdgeInsets.fromLTRB(
                            AppSpace.xl,
                            0,
                            AppSpace.xl,
                            BottomPadding.of(context, minimum: AppSpace.md),
                          ),
    ```

24. **Two-step code (Where 22).** In `two_step_screen.dart` replace `      body: SafeArea(\n        child: LayoutBuilder(` with:
    ```dart
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
    ```
    Replace line 328 with (the minimum height must subtract the new bottom padding, or the page always scrolls a little):
    ```dart
                final bottom = BottomPadding.of(context, minimum: AppSpace.lg);
                final minHeight = constraints.maxHeight - AppSpace.lg - bottom;
    ```
    Replace the four lines 330-333 with:
    ```dart
                  padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight < 0 ? 0 : minHeight,
    ```

25. **New password (Where 23).** In `account_screen.dart` replace `      body: SafeArea(\n        child: Center(` with:
    ```dart
          body: SafeArea(
            bottom: false,
            child: Center(
    ```
    Replace the three lines 166-168 with:
    ```dart
                padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
    ```

26. **Sign-in screen (Where 24).** In `sign_in_screen.dart` replace `          SafeArea(\n            child: Center(` with:
    ```dart
              SafeArea(
                bottom: false,
                child: Center(
    ```
    Replace the six padding lines (57-62) with:
    ```dart
                              padding: EdgeInsets.fromLTRB(
                                AppSpace.xl,
                                0,
                                AppSpace.xl,
                                BottomPadding.of(context, minimum: AppSpace.lg),
                              ),
    ```

27. **Workspace onboarding (Where 25).** In `onboarding_screen.dart` replace `      body: SafeArea(\n        child: Column(` with:
    ```dart
          body: SafeArea(
            bottom: false,
            child: Column(
    ```
    Replace line 183 with:
    ```dart
                    padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, BottomPadding.of(context, minimum: AppSpace.xl)),
    ```

28. **Join screens (Where 26).** In `join_flow.dart` replace line 229 with:
    ```dart
        return Scaffold(body: SafeArea(bottom: false, child: body));
    ```
    Replace the three `joinedWelcome` lines with:
    ```dart
          body: SafeArea(
            bottom: false,
            child: _JoinCard(
              key: const Key('joinedWelcome'),
    ```
    Replace the three `joinTeam` lines with:
    ```dart
          body: SafeArea(
            bottom: false,
            child: _JoinCard(
              key: const Key('joinTeam'),
    ```
    Replace the `_JoinCard` padding line (248) with:
    ```dart
            padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.gutter, AppSpace.gutter, BottomPadding.of(context, minimum: AppSpace.gutter)),
    ```

29. **Board columns on tablets (Where 27).** In `board_screen.dart` replace line 186 with:
    ```dart
                        padding: EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, BottomPadding.of(context, minimum: AppSpace.md)),
    ```

30. **Board empty states (Where 28).** In `board_screen.dart` replace the six lines 162-167 with:
    ```dart
                    Expanded(
                      child: EmptyState(icon: LucideIcons.squareKanban, title: l10n.noTickets, message: l10n.noTicketsHelp),
                    )
    ```
    and the eleven lines 169-179 with:
    ```dart
                    Expanded(
                      child: EmptyState(
                        icon: LucideIcons.listFilter,
                        title: l10n.noMatchingTickets,
                        message: l10n.noMatchingTicketsHelp,
                        action: TextButton(key: const Key('clearFilters'), onPressed: _clearFilters, child: Text(l10n.clearFilters)),
                      ),
                    )
    ```
    Keep `final barInset = ...` (line 114): the phone ticket list still uses it.

31. **Add a widget test.** Create `test/bottom_padding_test.dart` with:
    ```dart
    // The ends of lists and sheets clear the system navigation bar instead of being cut off above it
    // (BottomPadding at the end of the scrollable, not a SafeArea around it).
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/core/widgets.dart';
    import 'package:casama_app/ui/adaptive_modal.dart';
    import 'package:casama_app/ui/bottom_padding.dart';

    import 'app_test.dart' show harness, setSize;
    import 'fake_backend.dart';

    void main() {
      testWidgets('BottomPadding is the bar height, or the minimum where there is no bar', (tester) async {
        late double withBar, bigMinimum, withoutBar;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
            child: Builder(
              builder: (context) {
                withBar = BottomPadding.of(context);
                bigMinimum = BottomPadding.of(context, minimum: 40);
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Builder(
              builder: (context) {
                withoutBar = BottomPadding.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(withBar, 34);
        expect(bigMinimum, 40);
        expect(withoutBar, 16);
      });

      Future<void> openListSheet(WidgetTester tester, {required bool contentPadsBottom}) async {
        await setSize(tester, const Size(390, 844));
        tester.view.padding = const FakeViewPadding(bottom: 34);
        await tester.pumpWidget(
          harness(
            FakeBackend(),
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showAdaptiveSheet<void>(
                      context: context,
                      heightFactor: 0.7,
                      contentPadsBottom: contentPadsBottom,
                      builder: (sheet) => ListView(
                        key: const Key('sheetList'),
                        padding: EdgeInsets.only(bottom: BottomPadding.of(sheet)),
                        children: [for (var i = 0; i < 40; i++) SizedBox(height: 56, child: Text('row $i'))],
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      testWidgets('a list sheet runs to the bottom edge and ends with room for the bar', (tester) async {
        await openListSheet(tester, contentPadsBottom: true);
        expect(tester.getRect(find.byKey(const Key('sheetList'))).bottom, 844);
        final list = tester.widget<ListView>(find.byKey(const Key('sheetList')));
        expect((list.padding! as EdgeInsets).bottom, 34);
      });

      testWidgets('sheets that end in buttons keep the bar out with a SafeArea', (tester) async {
        await openListSheet(tester, contentPadsBottom: false);
        expect(tester.getRect(find.byKey(const Key('sheetList'))).bottom, 844 - 34);
      });

      testWidgets('an empty state keeps its content clear of the bar', (tester) async {
        await tester.pumpWidget(
          harness(
            FakeBackend(),
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(bottom: 120)),
                child: const Scaffold(body: EmptyState(icon: Icons.inbox, message: 'Nothing here')),
              ),
            ),
          ),
        );
        expect(find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.fromLTRB(32, 24, 32, 120)), findsOneWidget);
      });
    }
    ```
    Then run `dart format -l 200 test/bottom_padding_test.dart` (this new file only).

32. **Run the tests** from `client/`:
    `flutter test test/bottom_padding_test.dart test/phone_layout_test.dart test/tasks_phone_test.dart test/board_test.dart test/search_test.dart test/account_test.dart test/two_step_test.dart test/joining_test.dart test/create_menu_test.dart test/spaces_test.dart test/routine_editor_test.dart test/files_test.dart test/app_test.dart`

## Check it

Run from `client/` (only the files this plan touches, so other people's work in progress can't fail it):

```
dart analyze lib/ui/bottom_padding.dart lib/ui/adaptive_modal.dart lib/ui/form_sheet.dart lib/core/widgets.dart lib/core/mac_bridge.dart lib/features/bots/template_picker.dart lib/features/bots/model_picker.dart lib/features/settings/background_screen.dart lib/features/settings/photo_picker.dart lib/features/chat/widgets/message_actions.dart lib/features/chat/chat_screen.dart lib/features/search/search_view.dart lib/features/integrations/provider_setup.dart lib/features/files/file_preview.dart lib/features/bots/bots_screen.dart lib/features/board/board_screen.dart lib/features/auth/sign_in_screen.dart lib/features/workspaces/join_flow.dart lib/features/workspaces/spaces.dart lib/features/workspaces/people_screen.dart lib/features/integrations/connect_app_sheet.dart lib/features/routines/routines_screen.dart lib/features/skills/skill_catalog_screen.dart lib/features/settings/name_step.dart lib/features/auth/two_step_screen.dart lib/features/auth/account_screen.dart lib/features/workspaces/onboarding_screen.dart test/bottom_padding_test.dart
```

It reports no errors and no warnings. Existing `info` lines (for example `curly_braces_in_flow_control_structures`) were there before this change and are fine; the command exits with code 0.

Each grep below is run from `client/`:

- `grep -c "contentPadsBottom" lib/ui/adaptive_modal.dart` → 4 or more (parameter, doc comment, comment, use)
- `grep -c "bottom: !contentPadsBottom && view.viewInsets.bottom == 0" lib/ui/adaptive_modal.dart` → 1
- `grep -c "vertical: 24" lib/core/widgets.dart` → 0
- `grep -c "BottomPadding.of(context, minimum: 24)" lib/core/widgets.dart` → 1
- `grep -c "contentPadsBottom: true" <file>` → the number shown, for each file:
  `lib/ui/form_sheet.dart` 1, `lib/features/bots/template_picker.dart` 1, `lib/features/bots/model_picker.dart` 1,
  `lib/features/settings/background_screen.dart` 1, `lib/features/chat/widgets/message_actions.dart` 1,
  `lib/features/chat/chat_screen.dart` 1, `lib/features/search/search_view.dart` 1,
  `lib/features/integrations/provider_setup.dart` 1, `lib/features/files/file_preview.dart` 1,
  `lib/features/bots/bots_screen.dart` 1, `lib/core/mac_bridge.dart` 1, `lib/features/board/board_screen.dart` 2,
  `lib/features/auth/sign_in_screen.dart` 1, `lib/features/workspaces/join_flow.dart` 1, `lib/features/workspaces/spaces.dart` 1,
  `lib/features/workspaces/people_screen.dart` 1, `lib/features/integrations/connect_app_sheet.dart` 1,
  `lib/features/routines/routines_screen.dart` 1, `lib/features/skills/skill_catalog_screen.dart` 1
- `grep -c "BottomPadding.of(" <file>` → at least the number shown:
  `lib/ui/form_sheet.dart` 1, `lib/features/bots/template_picker.dart` 2, `lib/features/bots/model_picker.dart` 1,
  `lib/features/settings/photo_picker.dart` 1, `lib/features/chat/widgets/message_actions.dart` 1,
  `lib/features/chat/chat_screen.dart` 1, `lib/features/search/search_view.dart` 1, `lib/features/integrations/provider_setup.dart` 1,
  `lib/features/files/file_preview.dart` 2, `lib/features/bots/bots_screen.dart` 1, `lib/features/board/board_screen.dart` 3,
  `lib/features/auth/sign_in_screen.dart` 2, `lib/features/workspaces/join_flow.dart` 2, `lib/features/workspaces/spaces.dart` 1,
  `lib/features/workspaces/people_screen.dart` 1, `lib/features/integrations/connect_app_sheet.dart` 1,
  `lib/features/routines/routines_screen.dart` 1, `lib/features/skills/skill_catalog_screen.dart` 1,
  `lib/features/settings/name_step.dart` 1, `lib/features/auth/two_step_screen.dart` 1, `lib/features/auth/account_screen.dart` 1,
  `lib/features/workspaces/onboarding_screen.dart` 1
- `grep -c "bottom: false" <file>` → at least: `lib/features/settings/name_step.dart` 1, `lib/features/auth/two_step_screen.dart` 1,
  `lib/features/auth/account_screen.dart` 1, `lib/features/auth/sign_in_screen.dart` 1, `lib/features/workspaces/onboarding_screen.dart` 1,
  `lib/features/workspaces/join_flow.dart` 3, `lib/features/search/search_view.dart` 1, `lib/features/skills/skill_catalog_screen.dart` 1
- `grep -c "padding: EdgeInsets.only(bottom: barInset)" lib/features/board/board_screen.dart` → 0
- `grep -c "AppSpace.lg \* 2" lib/features/auth/two_step_screen.dart` → 0
- The tests from step 32 pass.

## Don't touch

- The lists listed as "Already right" at the end of "Where", `FormSheet` and every sheet built on it,
  the chat composer's `SafeArea` (`chat_screen.dart:598`), the floating tab bar's `SafeArea`
  (`lib/ui/floating_tab_chrome.dart:32`), the desktop sidebar (`home_shell.dart:365`), the call screen's
  controls (`call_screen.dart:326`, `:612`), the notifications primer and the companion overlay: they are
  non-scrolling content or already right.
- `lib/features/home/home_shell.dart` and `FloatingTabChrome.bottomInset`: the tab screens depend on the
  padding the shell sets; don't switch anything to `viewPadding`.
- Horizontal lists (chip rows, galleries): this fix is for vertical scrolling only.
- `keyboardDismissBehavior`, scrollbars, `ScrollController`s and `PrimaryScrollController`s: other fixes.
  If one of those already landed and added a line next to a line you replace, keep it.
- No new dependencies. No refactors, renames or cleanups beyond the fix.
- No git commands (the tree is shared; others commit).

## STOP if

- The text you are told to replace in a step isn't in the file. Lines right next to it may differ
  because another fix landed (for example an added `keyboardDismissBehavior:` line); that's fine as
  long as the exact text you replace is there.
- `lib/ui/glass/` exists and `showAdaptiveSheet` no longer builds the phone sheet itself (it hands off
  to a glass adapter): then the bottom `SafeArea` of step 3 lives in that adapter. Report instead of
  guessing where it went.
- A step would leave a sheet with `contentPadsBottom: true` but no `BottomPadding.of(...)` in its
  content, or the other way round (the steps always pair them).
- The fix seems to require touching something in "Don't touch".
- A test fails because of this change, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open
to see it. For example: on an iPhone, open the model picker in New bot and scroll; the models now slide
under the home indicator and the last one stops just above it, instead of disappearing along a line
above the indicator. Empty states on the tab screens also sit centered in the space above the tab bar.
