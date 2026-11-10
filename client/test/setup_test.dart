import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a new bot offers its setup interview, which can be started or skipped', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend()..setupStatus = BotSetupStatusEnum.pending;
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Set up Ada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startSetup')));
    await tester.pumpAndSettle();
    expect(backend.setupStarted, 1);
    await tester.tap(find.byKey(const Key('skipSetup')));
    await tester.pumpAndSettle();
    expect(backend.setupStatus, BotSetupStatusEnum.skipped);
    expect(find.byKey(const Key('setupCard')), findsNothing);
  });
}
