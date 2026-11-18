import 'package:casama/core/providers.dart';
import 'package:casama/core/review_prompt.dart';
import 'package:casama/features/admin/reports_tab.dart';
import 'package:casama/features/moderation/report_sheet.dart';
import 'package:casama/features/notifications/email_tips.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Widget _app(FakeBackend backend, Widget home) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (c) => Scaffold(
    body: Center(child: TextButton(onPressed: () => open(c), child: const Text('open'))),
  ),
);

void main() {
  testWidgets('reporting a bot reply needs a reason and sends it (D-301)', (tester) async {
    await setSize(tester, const Size(800, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(
      _app(
        backend,
        _opener((c) => showReportSheet(c, kind: ReportTarget.message, targetId: 'm-1')),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Report reply'), findsWidgets);
    expect(tester.widget<FilledButton>(find.byKey(const Key('reportSend'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('reportReason-violence')));
    await tester.enterText(find.byKey(const Key('reportNote')), 'it threatened me');
    await tester.pump();
    await tester.tap(find.byKey(const Key('reportSend')));
    await tester.pumpAndSettle();
    expect(backend.reports.single, (ReportTarget.message, 'm-1', ReportReason.violence, 'it threatened me'));
    expect(find.text('Thanks. Your report was sent for review.'), findsOneWidget);
  });

  testWidgets('a person can be blocked, shows in Blocked people, and can be unblocked', (tester) async {
    await setSize(tester, const Size(800, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(
      _app(backend, _opener((c) => showPersonActions(c, userId: 'u-ben', name: 'Ben'))),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personBlock')));
    await tester.pumpAndSettle();
    expect(backend.blocked.keys, ['u-ben']);
    expect(find.text('Ben is blocked'), findsOneWidget);

    await tester.pumpWidget(_app(backend, const BlockedPeopleScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blocked-u-ben')), findsOneWidget);
    await tester.tap(find.byKey(const Key('unblock-u-ben')));
    await tester.pumpAndSettle();
    expect(backend.blocked, isEmpty);
    expect(find.text('No one is blocked'), findsOneWidget);
  });

  testWidgets('the admin Reports tab acts on a report and takes down a public link', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..contentReports = [
        ContentReport(
          id: 'r-1',
          targetKind: ReportTargetKind.message,
          targetId: 'm-1',
          targetOrgId: 'o-1',
          targetOrgName: 'Acme',
          reason: ReportReason.spam,
          note: 'scam link',
          snapshot: 'Helper: buy cheap pills',
          reporterEmail: 'ana@example.com',
          sameTarget: 3,
          status: ContentReportStatusEnum.open,
          createdAt: DateTime.utc(2026, 11, 15),
        ),
      ]
      ..reportedLinks = [
        ReportedCreation(
          id: 'c-1',
          orgId: 'o-1',
          orgName: 'Acme',
          title: 'Landing page',
          kind: 'page',
          reports: 2,
          reporters: 2,
          lastReason: 'phishing',
          takenDown: false,
          lastReportedAt: DateTime.utc(2026, 11, 15),
        ),
      ];
    await tester.pumpWidget(_app(backend, const Scaffold(body: ReportsTab())));
    await tester.pumpAndSettle();
    expect(find.textContaining('buy cheap pills'), findsOneWidget);
    expect(find.textContaining('3 reports'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contentReport-r-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reviewSuspend')));
    await tester.pumpAndSettle();
    expect(backend.reviewed.single, ('r-1', true, true));
    await tester.tap(find.text('Take down'));
    await tester.pumpAndSettle();
    expect(backend.takenDown, ['c-1']);
  });

  testWidgets('the admin Support tab closes a ticket (D-303)', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend()
      ..tickets = [
        SupportTicketRow(
          reference: 'C-ABC234',
          topic: 'billing',
          subject: 'Charged twice',
          status: SupportTicketRowStatusEnum.open,
          userEmail: 'ana@example.com',
          orgId: null,
          orgName: null,
          createdAt: DateTime.utc(2026, 11, 15),
          closedAt: null,
        ),
      ];
    await tester.pumpWidget(_app(backend, const Scaffold(body: SupportTicketsTab())));
    await tester.pumpAndSettle();
    expect(find.textContaining('C-ABC234 · Charged twice'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ticketToggle-C-ABC234')));
    await tester.pumpAndSettle();
    expect(backend.closedTickets, ['C-ABC234']);
  });

  testWidgets('tips and news emails can be turned off (D-302)', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(_app(backend, const Scaffold(body: EmailTipsTile())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('emailTipsSwitch')));
    await tester.pumpAndSettle();
    expect(backend.tipsEmails, isFalse);
  });

  group('rating prompt (D-305)', () {
    late ProviderContainer container;
    late int asked;
    late DateTime now;
    ReviewPrompt prompt({bool supported = true}) => ReviewPrompt(
      container.read(Provider((ref) => ref)),
      request: () async {
        asked++;
        return true;
      },
      now: () => now,
      supported: supported,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      asked = 0;
      now = DateTime(2026, 11, 1);
      ReviewPrompt.errorThisSession = false;
    });
    tearDown(() => container.dispose());

    Future<void> useOnDays(ReviewPrompt p, int days) async {
      for (var i = 0; i < days; i++) {
        await p.recordUse();
        now = now.add(const Duration(days: 1));
      }
    }

    test('asks after a purchase once the app was used on 5 days over a week, then not for 120 days', () async {
      final p = prompt();
      await useOnDays(p, 4);
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      await useOnDays(p, 4);
      expect(await p.moment(ReviewMoment.purchase), isTrue);
      expect(asked, 1);
      now = now.add(const Duration(days: 30));
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      now = now.add(const Duration(days: 100));
      expect(await p.moment(ReviewMoment.purchase), isTrue);
    });

    test('never after an error this session, and never where it isn\'t supported', () async {
      var p = prompt();
      await useOnDays(p, 8);
      ReviewPrompt.errorThisSession = true;
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      ReviewPrompt.errorThisSession = false;
      p = prompt(supported: false);
      expect(await p.moment(ReviewMoment.purchase), isFalse);
      expect(asked, 0);
    });

    test('replies count as a moment on the 10th and every 40th after', () async {
      expect([for (var n = 1; n <= 100; n++) if (ReviewPrompt.replyMilestone(n)) n], [10, 50, 90]);
      final p = prompt();
      await useOnDays(p, 8);
      for (var i = 0; i < 9; i++) {
        expect(await p.moment(ReviewMoment.replyFinished), isFalse);
      }
      expect(await p.moment(ReviewMoment.replyFinished), isTrue);
    });
  });
}
