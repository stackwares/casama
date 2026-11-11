import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/core/voice.dart';
import 'package:casama_app/features/voice/call_screen.dart';
import 'package:casama_app/features/voice/phone_calls.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';

/// Phone-call voice (D-135).
PhoneCall _call(String id, String reason) => PhoneCall(
      id: id,
      botId: botId,
      botName: 'Max',
      reason: reason,
      status: PhoneCallStatusEnum.ringing,
      conversationId: convId,
      expiresAt: DateTime.now().add(const Duration(seconds: 40)),
      createdAt: DateTime.now(),
    );

Widget _app(FakeBackend backend, {FakeCallConnector? calls}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const IncomingCallBanner(child: Scaffold(body: Text('home')))),
    GoRoute(path: '/bots/:id/call', builder: (_, s) => CallScreen(botId: s.pathParameters['id']!, conversationId: s.uri.queryParameters['c'], callId: s.uri.queryParameters['call'])),
  ]);
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      callSurfaceProvider.overrideWithValue(NoCallSurface()),
      routerProvider.overrideWithValue(router),
      if (calls != null) voiceCallConnectorProvider.overrideWithValue(calls),
    ],
    child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
  );
}

void main() {
  CallScreen.motion = false;
  testWidgets('desktop: a ringing banner; answering opens the live call where the bot speaks first', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend()..ringing.add(_call('call-1', 'The deploy failed; roll back?'));
    final calls = FakeCallConnector();
    await tester.pumpWidget(_app(backend, calls: calls));
    await tester.pump();
    await tester.pump();
    expect(find.text('Max is calling'), findsOneWidget);
    expect(find.text('The deploy failed; roll back?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('answerCall')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.callActions, ['answer:call-1']);
    expect(backend.sessionCallId, 'call-1');
    expect(calls.session?.speakFirst, isTrue);
    expect(calls.session?.conversationId, convId);
  });

  testWidgets('declining clears the banner', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend()..ringing.add(_call('call-2', 'Lunch at noon?'));
    await tester.pumpWidget(_app(backend));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('declineCall')));
    await tester.pump();
    await tester.pump();
    expect(backend.callActions, ['decline:call-2']);
    expect(find.byKey(const Key('incomingCall')), findsNothing);
  });

  test('push payloads become calls', () {
    final c = IncomingCall.fromData({'call_id': 'c1', 'bot_id': 'b1', 'bot_name': 'Max', 'reason': 'hi', 'conversation_id': ''})!;
    expect(c.conversationId, isNull);
    expect(c.callPath, '/bots/b1/call?call=c1');
    expect(IncomingCall.fromData({'bot_id': 'b1'}), isNull);
  });
}
