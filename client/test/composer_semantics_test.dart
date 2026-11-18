import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/chat/widgets/composer.dart';
import 'package:casama/l10n/generated/app_localizations.dart';

void main() {
  // macOS gives a text field no children, so anything under the message box's semantics node
  // (the chat, its header, the Send button) was hidden from VoiceOver and automation.
  testWidgets('the message box is a leaf in the semantics tree, not the page', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Like the chat screen: Cmd+F lives in a CallbackShortcuts around the page.
        home: CallbackShortcuts(
          bindings: const {},
          child: Scaffold(
            body: Column(
              children: [
                // Like the chat: a scrolling list (its own node) beside the box, nothing to stop a merge.
                Expanded(
                  child: ListView(
                    children: const [Text('A message from the bot')],
                  ),
                ),
                ChatComposer(
                  controller: controller,
                  focusNode: focus,
                  hint: 'Message Ada',
                  running: false,
                  onSend: () {},
                  onStop: () {},
                  recording: false,
                  transcribing: false,
                  onDictate: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    bool underTextField(SemanticsNode? node) {
      for (var n = node?.parent; n != null; n = n.parent) {
        if (n.getSemanticsData().flagsCollection.isTextField) return true;
      }
      return false;
    }

    expect(
      underTextField(tester.getSemantics(find.text('A message from the bot'))),
      isFalse,
    );
    expect(
      underTextField(tester.getSemantics(find.byTooltip('Send'))),
      isFalse,
    );
    final field = tester.getSemantics(find.byKey(const Key('messageInput')));
    expect(field.getSemanticsData().flagsCollection.isTextField, isTrue);
    handle.dispose();
  });
}
