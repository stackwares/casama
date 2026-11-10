import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/calls/outbound_call_screen.dart';
import 'package:kasama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Calls for you (D-141).
void main() {
  testWidgets('the live transcript, taking over to your phone', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const OutboundCallScreen(callId: 'call-9', pollEvery: Duration(hours: 1))));
    await tester.pump();
    await tester.pump();
    expect(find.text("Hi, I'm Max, an AI assistant calling for Ana."), findsOneWidget);
    expect(find.text('Sure, what time?'), findsOneWidget);
    expect(find.text('On the call'), findsOneWidget);
    await tester.tap(find.byKey(const Key('takeOverCall')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('takeOverPhone')), '+14155557777');
    await tester.tap(find.byKey(const Key('confirmTakeOver')));
    await tester.pumpAndSettle();
    expect(backend.callLog, ['takeover:call-9:+14155557777']);
    expect(find.text('You took over the call'), findsOneWidget);
    expect(find.byKey(const Key('endCall')), findsNothing);
  });

  testWidgets('ending a call', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const OutboundCallScreen(callId: 'call-9', pollEvery: Duration(hours: 1))));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('endCall')));
    await tester.pump();
    await tester.pump();
    expect(backend.callLog, ['end:call-9']);
    expect(find.text('You ended the call'), findsOneWidget);
  });

  testWidgets('admins connect Twilio', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: PhoneCallsSection(orgId: orgId))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('phoneCalls')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('twilioSid')), 'AC${'a' * 32}');
    await tester.enterText(find.byKey(const Key('twilioToken')), 'secret-token-123456');
    await tester.enterText(find.byKey(const Key('twilioFrom')), '+14155550000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('savePhoneCalls')));
    await tester.pumpAndSettle();
    expect(backend.setTel!.fromNumber, '+14155550000');
    expect(backend.setTel!.allowPersonalNumbers, isFalse);
    expect(find.textContaining('+14155550000'), findsOneWidget);
  });
}
