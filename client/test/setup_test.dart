import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a new bot goes straight to chat: no setup card', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend()..setupStatus = BotSetupStatusEnum.pending;
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setupCard')), findsNothing);
    expect(find.text('Set up Ada'), findsNothing);
    expect(backend.setupStarted, 0);
  });
}
