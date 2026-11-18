// A bot's message draft (D-335): the MessageDraft component shows the email with its own Send,
// Discard and Edit; Send sends exactly what's on screen, edits included.
import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const draft = <String, Object?>{
    'id': 'root',
    'component': 'MessageDraft',
    'kind': 'email',
    'from': 'cory@acme.com',
    'to': ['sarah@acme.com'],
    'subject': "Moving Friday's design review to 2 PM",
    'body': "Hi Sarah,\n\nCould we move Friday's design review to 2 PM?\n\nThanks,\nCory",
  };

  Future<FakeBackend> showDraft(WidgetTester tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'msg-1',
          role: 'assistant',
          text: "Here's the draft.",
          createdAt: DateTime(2026),
          ui: [
            UiPart(
              surfaceId: 'ui_d',
              messages: [
                {
                  'version': '1.0',
                  'createSurface': {
                    'surfaceId': 'ui_d',
                    'catalogId': 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json',
                  },
                },
                {
                  'version': '1.0',
                  'updateComponents': {
                    'surfaceId': 'ui_d',
                    'components': [draft],
                  },
                },
              ],
            ),
          ],
        ),
      ];
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    return backend;
  }

  // After a tap the bot starts replying (a looping shimmer), so pump frames instead of settling.
  Future<void> tapAndPump(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows the email and sends it as shown', (tester) async {
    final backend = await showDraft(tester);
    expect(find.text('New email'), findsOneWidget);
    expect(find.text('Ready to send'), findsOneWidget);
    expect(find.text('sarah@acme.com'), findsOneWidget);
    expect(find.text("Moving Friday's design review to 2 PM"), findsOneWidget);
    await tapAndPump(tester, const Key('draftSend'));
    final action = backend.sentUiActions.last;
    expect(action['name'], 'draft.send');
    final ctx = action['context']! as Map;
    expect(ctx['to'], ['sarah@acme.com']);
    expect(ctx['body'], draft['body']);
    expect(ctx['edited'], false);
    // The chat shows the button pressed, not the fields.
    expect(backend.sent.last, 'Send email');
  });

  testWidgets('Edit changes what Send sends', (tester) async {
    final backend = await showDraft(tester);
    await tester.tap(find.byKey(const Key('draftEdit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, draft['body']! as String),
      'Hi Sarah, can we do 3 PM instead?',
    );
    await tester.pump();
    expect(find.text('Edited'), findsOneWidget);
    await tapAndPump(tester, const Key('draftSend'));
    final ctx = backend.sentUiActions.last['context']! as Map;
    expect(ctx['body'], 'Hi Sarah, can we do 3 PM instead?');
    expect(ctx['edited'], true);
    // The answered card shows what was sent, not the bot's first draft.
    expect(find.text('Hi Sarah, can we do 3 PM instead?'), findsOneWidget);
    expect(find.text(draft['body']! as String), findsNothing);
  });

  testWidgets('Discard sends draft.discard', (tester) async {
    final backend = await showDraft(tester);
    await tapAndPump(tester, const Key('draftDiscard'));
    expect(backend.sentUiActions.last['name'], 'draft.discard');
    expect(backend.sent.last, 'Discard');
  });
}
