import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/desktop/desktop_context.dart';
import 'package:casama_app/features/desktop/desktop_watch.dart';
import 'package:casama_app/features/quick_ask/quick_ask_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

class FakeReader extends DesktopContextReader {
  FakeReader(this.apps);
  final List<String> apps;
  var i = 0;
  @override
  Future<DesktopContext> captureWindow() async => DesktopContext(app: apps[i++ % apps.length], window: 'Quarterly plan.docx');
}

/// Desktop context (D-152).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reads the front app, window, selection and browser tab on a Mac', () async {
    final calls = <String>[];
    Future<ProcessResult> run(String exe, List<String> args) async {
      final script = args.join(' ');
      calls.add('$exe $script');
      final out = script.contains('AXSelectedText')
          ? 'The quarterly numbers look off'
          : script.contains('active tab')
          ? 'https://docs.example.com/q3\nQ3 report'
          : 'Google Chrome\nQ3 report - Google Chrome';
      return ProcessResult(1, 0, out, '');
    }

    final c = await DesktopContextReader(run: run, platform: 'macos').capture();
    expect(c.app, 'Google Chrome');
    expect(c.window, 'Q3 report - Google Chrome');
    expect(c.selection, 'The quarterly numbers look off');
    expect(c.url, 'https://docs.example.com/q3');
    expect(c.tabTitle, 'Q3 report');
    expect(calls.where((x) => x.contains('tell application "Google Chrome"')), hasLength(1));
    // Linux: xdotool and the primary selection.
    Future<ProcessResult> linux(String exe, List<String> args) async => ProcessResult(1, exe == 'xsel' ? 1 : 0, switch (exe) {
      'xdotool' => args.last == 'getwindowpid' ? '4242' : 'notes.md - Code',
      'cat' => 'code',
      'xclip' => 'selected bit',
      _ => '',
    }, '');
    final l = await DesktopContextReader(run: linux, platform: 'linux').capture();
    expect((l.app, l.window, l.selection), ('code', 'notes.md - Code', 'selected bit'));
    // Missing tools just mean less context.
    final none = await DesktopContextReader(run: (_, _) async => throw const ProcessException('x', []), platform: 'linux').capture();
    expect(none.isEmpty, isTrue);
  });

  test('the attached block keeps only the parts left on', () {
    const c = DesktopContext(app: 'Google Chrome', window: 'Q3 report', selection: 'numbers', url: 'https://x.test', tabTitle: 'Q3');
    expect(formatDesktopContext(c), 'From: Google Chrome — Q3 report\nBrowser tab: Q3 (https://x.test)\nSelected text:\nnumbers');
    expect(formatDesktopContext(c, window: false, tab: false), 'Selected text:\nnumbers');
  });

  test('folder watching skips partial downloads; activity becomes hourly summaries uploaded when the hour ends', () async {
    expect(reportableFile('Invoice.pdf'), isTrue);
    expect(reportableFile('Invoice.pdf.crdownload'), isFalse);
    expect(reportableFile('.DS_Store'), isFalse);
    expect(reportableFile('~\$report.docx'), isFalse);

    final backend = FakeBackend();
    var now = DateTime(2027, 1, 10, 9, 58);
    final t = ActivityTracker(backend, FakeReader(['Word', 'Word', 'Slack']), now: () => now, every: const Duration(minutes: 1));
    for (var i = 0; i < 3; i++) {
      await t.sample('dev-key');
    }
    expect(backend.uploadedReadings, isEmpty);
    now = DateTime(2027, 1, 10, 10, 1);
    await t.sample('dev-key');
    final r = backend.uploadedReadings.single.$2;
    expect(r.externalId, 'activity-2027-01-10T09');
    expect(r.summary['total_minutes'], 3);
    expect(r.summary['apps'], [
      {
        'app': 'Word',
        'minutes': 2,
        'titles': ['Quarterly plan.docx'],
      },
      {
        'app': 'Slack',
        'minutes': 1,
        'titles': ['Quarterly plan.docx'],
      },
    ]);
    // Only the current hour is still kept locally.
    final kept = jsonDecode((await SharedPreferences.getInstance()).getString(ActivityTracker.pref)!) as Map;
    expect(kept.keys, ['2027-01-10T10']);
  });

  testWidgets('quick ask from the hotkey: selected text and window come along, each can be left out', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend();
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    container.read(pendingDesktopContextProvider.notifier).set(const DesktopContext(app: 'Preview', window: 'Contract.pdf', selection: 'Termination: 30 days notice'));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const QuickAskScreen(initialBotId: botId),
        ),
        GoRoute(path: '/bots/:b/chat', builder: (_, _) => const Text('chat')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ctxSelection')), findsOneWidget);
    expect(find.text('Contract.pdf'), findsOneWidget);
    // The context is used once.
    expect(container.read(pendingDesktopContextProvider), isNull);
    await tester.enterText(find.byKey(const Key('quickAskText')), 'Is this normal?');
    await tester.tap(find.byKey(const Key('ctxWindow')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quickAskSend')));
    await tester.pumpAndSettle();
    expect(backend.sent.single, 'Is this normal?\n\nSelected text:\nTermination: 30 days notice');
    expect(find.text('chat'), findsOneWidget);
  });
}
