import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/bots/bot_email.dart';
import 'package:casama/features/bots/mail_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// A bot's hosted email address (BOT-EMAIL-PLAN Phase 1).
void main() {
  testWidgets('claiming a name shows the address with copy, contacts and write', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: BotEmailSheet(botId: botId))));
    await tester.pumpAndSettle();
    // Prefilled with a free name from the bot's name.
    expect(find.text('Give Ada an email address'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('mailName'))).controller?.text,
      'ada',
    );
    final claim = find.byKey(const Key('claimMail'));
    expect(tester.widget<FilledButton>(claim).onPressed, isNotNull);
    await tester.tap(claim);
    await tester.pumpAndSettle();
    expect(find.text('ada@mail.test'), findsOneWidget);
    expect(find.byKey(const Key('mailCopy')), findsOneWidget);
    expect(find.byKey(const Key('mailContacts')), findsOneWidget);
    expect(find.byKey(const Key('mailWrite')), findsOneWidget);
    expect(backend.mailActions, contains('claim:$botId:ada:profile'));
  });

  testWidgets('pausing, resuming and releasing from the sheet', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: BotEmailSheet(botId: botId))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('claimMail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailPause')));
    await tester.pumpAndSettle();
    expect(backend.mailActions, contains('update:$botId:paused:null'));
    await tester.tap(find.byKey(const Key('mailPause')));
    await tester.pumpAndSettle();
    expect(backend.mailActions, contains('update:$botId:active:null'));
    await tester.tap(find.byKey(const Key('mailRelease')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailReleaseConfirm')));
    await tester.pumpAndSettle();
    expect(backend.mailActions, contains('release:$botId'));
    // Released: back to the claim form, ready for a new name.
    expect(find.byKey(const Key('mailName')), findsOneWidget);
  });

  testWidgets('the empty-chat offer shows until the bot has an address', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const Scaffold(body: EmailOfferTile(botId: botId, botName: 'Ada'))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emailOffer')), findsOneWidget);
    await backend.claimMailAddress(botId, 'ada');
    ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    ).invalidate(mailAddressProvider(botId));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emailOffer')), findsNothing);
  });

  testWidgets('the inbox lists mail, flags the unconfirmed, allows and blocks', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await backend.claimMailAddress(botId, 'ada');
    backend.mailList.add(MailMessage(
      id: 'm1',
      direction: MailMessageDirectionEnum.in_,
      fromAddr: 'stranger@evil.test',
      fromName: null,
      toTag: '',
      subject: 'Hello',
      snippet: 'hi there',
      verdict: MailMessageVerdictEnum.stranger,
      senderCheck: MailMessageSenderCheckEnum.fail,
      hasFiles: false,
      fileCount: 0,
      size: 100,
      conversationId: null,
      createdAt: DateTime.utc(2026, 11, 20, 10),
    ));
    backend.mailDetails['m1'] = MailMessageDetail(
      id: 'm1',
      direction: MailMessageDetailDirectionEnum.in_,
      fromAddr: 'stranger@evil.test',
      fromName: null,
      toTag: '',
      subject: 'Hello',
      snippet: 'hi there',
      verdict: MailMessageDetailVerdictEnum.stranger,
      senderCheck: MailMessageDetailSenderCheckEnum.fail,
      hasFiles: false,
      fileCount: 0,
      size: 100,
      conversationId: null,
      createdAt: DateTime.utc(2026, 11, 20, 10),
      text: 'hi there, stranger words',
      files: const [],
    );
    await tester.pumpWidget(harness(backend, const Scaffold(body: MailScreen(botId: botId))));
    await tester.pumpAndSettle();
    expect(find.text('stranger@evil.test'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mailFilterStrangers')));
    await tester.pumpAndSettle();
    expect(find.text('stranger@evil.test'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mail-m1')));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't confirm this sender"), findsOneWidget);
    expect(find.text('hi there, stranger words'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mailBlock')));
    await tester.pumpAndSettle();
    expect(backend.mailActions, contains('block:$botId:stranger@evil.test'));
    expect(find.text('Blocked. New mail from here is refused.'), findsOneWidget);
  });

  testWidgets('keeping receipts makes a tagged routine', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: BotEmailSheet(botId: botId))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('claimMail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailTryReceipts')));
    await tester.pumpAndSettle();
    expect(backend.createdMessageTrigger?.toTag, 'receipts');
    expect(backend.createdMessageTrigger?.sender, '*');
  });
}
