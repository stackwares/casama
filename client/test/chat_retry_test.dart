// Retry after a failed run sends the same message again, whole (Fix 12): its files, the skills
// picked for it and a card's answer, not only the words.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _file = AttachmentRef(path: 'uploads/a.pdf', name: 'a.pdf', mimeType: 'application/pdf', size: 3);
final _failed = ev(1, 'run.failed', {'error_code': 'provider_error', 'message': 'The model is not answering', 'retryable': true});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  (ProviderContainer, FakeBackend, ChatController) setUpChat() {
    final backend = FakeBackend();
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    container.listen(chatControllerProvider(botId), (_, _) {});
    return (container, backend, container.read(chatControllerProvider(botId).notifier));
  }

  test('Retry resends the files and the picked skills', () async {
    final (_, backend, c) = setUpChat();
    await c.open(convId);
    await c.send('Summarise this', attachments: [_file], skills: ['research']);
    c.apply(_failed);
    await c.retry();
    expect(backend.sent, ['Summarise this', 'Summarise this']);
    expect(backend.sentAttachments.last.single.path, 'uploads/a.pdf');
    expect(backend.sentSkills.last, ['research']);
  });

  test('a message that is only files can be retried', () async {
    final (container, backend, c) = setUpChat();
    await c.open(convId);
    await c.send('', attachments: [_file]);
    c.apply(_failed);
    expect(container.read(chatControllerProvider(botId)).canRetry, isTrue);
    await c.retry();
    expect(backend.sentAttachments, hasLength(2));
    expect(backend.sentAttachments.last.single.name, 'a.pdf');
  });

  test('Retry resends a card answer as the answer it was', () async {
    final (_, backend, c) = setUpChat();
    await c.open(convId);
    final answer = {'surface_id': 's1', 'name': 'pick', 'context': {'choice': 'B'}};
    await c.send('Picked B', uiAction: answer);
    c.apply(_failed);
    await c.retry();
    expect(backend.sentUiActions, [answer, answer]);
  });

  testWidgets('the Try Again under a failed run resends the files', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(ChatScreen)));
    final c = container.read(chatControllerProvider(botId).notifier);
    await c.send('', attachments: [_file]);
    c.apply(_failed);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Try Again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.sentAttachments, hasLength(2));
    c.apply(ev(2, 'run.completed', {'final_message_id': 'x'}));
    await tester.pumpAndSettle();
  });
}
