import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/settings/settings_screen.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';
import 'package:kasama_app/theme/app_theme.dart';
import 'package:kasama_app/theme/appearance.dart';

import 'fake_backend.dart';

Widget _app(FakeBackend backend, Widget child) => ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: Consumer(builder: (context, ref, _) {
        final a = ref.watch(appearanceProvider);
        return MaterialApp(
          theme: AppTheme.light(a.accent),
          darkTheme: AppTheme.dark(a.accent),
          themeMode: a.mode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      }),
    );

void main() {
  testWidgets('consecutive tool steps share one card, even across the computer starting', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    await tester.pumpWidget(_app(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'make a todo file');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController
      ..add(ev(1, 'run.started', {'trigger': 'chat', 'model': 'm', 'computer_id': null}))
      ..add(ev(2, 'tool.started', {'call_id': 'c1', 'tool': 'files.write', 'args_redacted': {'path': 'launch/todo.md'}}))
      ..add(ev(3, 'tool.completed', {'call_id': 'c1', 'result_preview': 'ok', 'artifact_path': null, 'duration_ms': 480}))
      ..add(ev(4, 'computer.state', {'computer_id': '00000000-0000-0000-0000-000000000009', 'state': 'running'}))
      ..add(ev(5, 'tool.started', {'call_id': 'c2', 'tool': 'files.read', 'args_redacted': {'path': 'launch/todo.md'}}))
      ..add(ev(6, 'tool.completed', {'call_id': 'c2', 'result_preview': 'ok', 'artifact_path': null, 'duration_ms': 20}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Wrote a file'), findsOneWidget);
    expect(find.text('Read a file'), findsOneWidget);
    // One card holds both steps; the "computer running" note doesn't split it.
    expect(find.byKey(const ValueKey('tools-c1')), findsOneWidget);
    expect(find.byKey(const ValueKey('tools-c2')), findsNothing);
    expect(find.textContaining('Computer'), findsNothing);
    // While the bot thinks between steps, the working indicator shows.
    expect(find.text('Thinking…'), findsOneWidget);
  });

  testWidgets('appearance: theme mode and accent apply right away', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(FakeBackend(), const SettingsScreen()));
    await tester.pumpAndSettle();
    final scaffoldColor = () => Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.surface;
    final primary = () => Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.primary;
    final lightSurface = scaffoldColor();
    final tealPrimary = primary();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(scaffoldColor(), isNot(lightSurface));
    expect(scaffoldColor().computeLuminance(), lessThan(0.05));

    await tester.tap(find.byKey(const Key('accent-indigo')));
    await tester.pumpAndSettle();
    expect(primary(), isNot(tealPrimary));
    // Surfaces stay neutral whatever the accent.
    expect(scaffoldColor(), const Color(0xFF0D0E10));
  });
}
