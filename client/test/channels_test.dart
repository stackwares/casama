import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/bots/channels_screen.dart';
import 'package:kasama_app/features/routines/routines_screen.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Chat apps (D-134).
void main() {
  testWidgets('connect WhatsApp, see the webhook and verify token, edit senders, read activity, disconnect', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChannelsScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('No chat apps yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addChannel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('channelKind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('channelField-phone_number_id')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('channelField-phone_number_id')), '1234');
    await tester.enterText(find.byKey(const Key('channelField-access_token')), 'EAAtoken');
    await tester.enterText(find.byKey(const Key('channelField-app_secret')), 'shh');
    await tester.enterText(find.byKey(const Key('channelSenders')), '+15550001, +15550002');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveChannel')));
    await tester.pumpAndSettle();

    final req = backend.createdChannel!;
    expect(req.kind, ChannelKind.whatsapp);
    expect(req.name, 'WhatsApp');
    expect(req.config, {'phone_number_id': '1234'});
    expect(req.secrets, {'access_token': 'EAAtoken', 'app_secret': 'shh'});
    expect(req.allowedSenders, ['+15550001', '+15550002']);
    expect(find.text('https://api.example.com/hooks/channels/ch-1'), findsOneWidget);
    expect(find.text('verify-123'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 allowed senders'), findsOneWidget);

    await tester.tap(find.byKey(const Key('channelEnabled-ch-1')));
    await tester.pumpAndSettle();
    expect(backend.channelActions.last, 'update:ch-1 enabled:false');

    await tester.tap(find.text('WhatsApp').first);
    await tester.pumpAndSettle();
    expect(find.text('Ignored: not on the allowed list'), findsOneWidget);
    expect(find.textContaining('stranger@example.com'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('editSenders')), '+15550001');
    await tester.tap(find.byKey(const Key('saveSenders')));
    await tester.pumpAndSettle();
    expect(backend.channelActions.last, 'update:ch-1 senders:+15550001');
    expect(find.textContaining('1 allowed sender'), findsOneWidget);

    await tester.tap(find.text('WhatsApp').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('deleteChannel')));
    await tester.tap(find.byKey(const Key('deleteChannel')));
    await tester.pumpAndSettle();
    expect(backend.channelActions.last, 'delete:ch-1');
    expect(find.text('No chat apps yet'), findsOneWidget);
  });

  testWidgets('a routine that starts on emails from a domain with a subject', (tester) async {
    await setSize(tester, const Size(700, 1600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineName')), 'Invoices');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'File the invoice');
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageSender')), '*@vendor.com');
    await tester.enterText(find.byKey(const Key('messageSubject')), 'invoice');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('createRoutine')));
    await tester.tap(find.byKey(const Key('createRoutine')));
    await tester.pumpAndSettle();
    final m = backend.createdMessageTrigger!;
    expect(m.channelKind, MessageTriggerConfigChannelKindEnum.email);
    expect(m.sender, '*@vendor.com');
    expect(m.subjectMatch, 'invoice');
    expect(backend.routineList.single.trigger, RoutineTrigger.message);
  });
}
