import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/bots/bot_email.dart';
import 'package:casama/features/billing/paywall.dart' show paywallFacts;
import 'package:casama/features/bots/mail_screen.dart';
import 'package:casama/l10n/generated/app_localizations_en.dart';

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

  MailMessage mailOf(String id, String subject, {DateTime? at}) => MailMessage(
        id: id,
        direction: MailMessageDirectionEnum.in_,
        fromAddr: 'friend@example.com',
        fromName: null,
        toTag: '',
        subject: subject,
        snippet: 'words',
        verdict: MailMessageVerdictEnum.allowed,
        senderCheck: MailMessageSenderCheckEnum.pass,
        hasFiles: false,
        fileCount: 0,
        size: 1024,
        conversationId: null,
        createdAt: at ?? DateTime.utc(2026, 11, 20, 10),
      );

  testWidgets('the inbox shows how full it is, and deletes selected threads', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await backend.claimMailAddress(botId, 'ada');
    backend.mailList.addAll([mailOf('a1', 'Bill'), mailOf('a2', 'Re: Bill'), mailOf('b1', 'Trip')]);
    await tester.pumpWidget(harness(backend, const Scaffold(body: MailScreen(botId: botId))));
    await tester.pumpAndSettle();
    expect(find.text('300 MB of 500 MB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mailMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailSelect')));
    await tester.pumpAndSettle();
    // Picking a thread picks all of its mail.
    await tester.tap(find.byKey(const Key('mail-a1')));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 mails'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mailDeleteSelected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailDeleteConfirm')));
    await tester.pumpAndSettle();
    expect(backend.mailActions.last, startsWith('delete:$botId:'));
    expect(backend.mailList.map((m) => m.id), ['b1']);
    expect(find.byKey(const Key('mail-a1')), findsNothing);
    expect(find.byKey(const Key('mail-b1')), findsOneWidget);
  });

  testWidgets('one mail deletes from its sheet, and old mail by age', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await backend.claimMailAddress(botId, 'ada');
    backend.mailList.addAll([
      mailOf('n1', 'New', at: DateTime.now().toUtc()),
      mailOf('o1', 'Old', at: DateTime.now().toUtc().subtract(const Duration(days: 400))),
    ]);
    backend.mailDetails['n1'] = MailMessageDetail.fromJson({
      ...backend.mailList.first.toJson(),
      'text': 'new words',
      'files': const [],
    });
    await tester.pumpWidget(harness(backend, const Scaffold(body: MailScreen(botId: botId))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailDeleteOlder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailOlder-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailDeleteConfirm')));
    await tester.pumpAndSettle();
    expect(backend.mailList.map((m) => m.id), ['n1']);
    await tester.tap(find.byKey(const Key('mail-n1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailDelete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mailDeleteConfirm')));
    await tester.pumpAndSettle();
    expect(backend.mailList, isEmpty);
    expect(find.text('No mail yet'), findsOneWidget);
  });

  test('the offer waits for a day-old bot or three chats', () {
    final now = DateTime(2026, 11, 20, 12);
    expect(emailOfferDue(now.subtract(const Duration(hours: 2)), 0, now: now), isFalse);
    expect(emailOfferDue(now.subtract(const Duration(hours: 2)), 3, now: now), isTrue);
    expect(emailOfferDue(now.subtract(const Duration(days: 1)), 0, now: now), isTrue);
    expect(emailOfferDue(null, null, now: now), isFalse);
  });

  test('plans list bot email when the server has it', () {
    final l10n = AppLocalizationsEn();
    final free = {'max_bots': 1, 'max_mail_addresses': 1, 'mail_new_day': 0};
    final plus = {'max_bots': 3, 'max_mail_addresses': 2, 'mail_new_day': 10};
    expect(paywallFacts(l10n, free), isNot(contains('1 bot email address')));
    expect(paywallFacts(l10n, free, email: true), containsAll(['1 bot email address', 'Bots reply to you by email']));
    expect(
      paywallFacts(l10n, plus, email: true),
      containsAll(['2 bot email addresses', 'Bots write to new people by email']),
    );
  });

  test('mailbox sizes read like the plans', () {
    expect(mailboxSize(512, 'en'), '1 KB');
    expect(mailboxSize(300 * 1024 * 1024, 'en'), '300 MB');
    expect(mailboxSize(2 * 1024 * 1024 * 1024, 'en'), '2 GB');
    expect(mailboxSize(1536 * 1024 * 1024, 'en'), '1.5 GB');
  });
}

