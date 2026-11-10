import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/settings/background_screen.dart';
import 'package:kasama_app/features/settings/settings_screen.dart';
import 'package:kasama_app/features/settings/theme_screen.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';
import 'package:kasama_app/theme/app_theme.dart';
import 'package:kasama_app/theme/appearance.dart';
import 'package:kasama_app/theme/schemes.dart';
import 'package:kasama_app/theme/wallpaper.dart';

import 'fake_backend.dart';

Widget _app(FakeBackend backend, Widget child) => ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: Consumer(builder: (context, ref, _) {
        final a = ref.watch(appearanceProvider);
        return MaterialApp(
          theme: AppTheme.light(a),
          darkTheme: AppTheme.dark(a),
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

  testWidgets('appearance: mode, color scheme and background apply right away', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(FakeBackend(), const SettingsScreen()));
    await tester.pumpAndSettle();
    ThemeData theme() => Theme.of(tester.element(find.byType(SettingsScreen)));
    final lightSurface = theme().colorScheme.surface;
    // Kasama's own scheme is the default: plum primary from the app icon.
    expect(theme().colorScheme.primary, kasamaScheme.light.primary);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme().colorScheme.surface, isNot(lightSurface));
    expect(theme().colorScheme.surface.computeLuminance(), lessThan(0.05));

    // Picking another scheme recolors the app.
    await tester.pumpWidget(_app(FakeBackend(), const ThemeScreen()));
    await tester.pumpAndSettle();
    final kasamaPrimary = Theme.of(tester.element(find.byType(ThemeScreen))).colorScheme.primary;
    await tester.enterText(find.byKey(const Key('themeSearch')), 'mandy');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scheme-mandyRed')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(ThemeScreen))).colorScheme.primary, isNot(kasamaPrimary));

    // The background pattern and its reach are carried by the theme.
    await tester.pumpWidget(_app(FakeBackend(), const BackgroundScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pattern-doodles')));
    await tester.pumpAndSettle();
    WallpaperTheme wallpaper() => Theme.of(tester.element(find.byType(BackgroundScreen))).extension<WallpaperTheme>()!;
    expect(wallpaper().spec.pattern, WallpaperPattern.doodles);
    await tester.ensureVisible(find.byKey(const Key('wallpaperEverywhere')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallpaperEverywhere')));
    await tester.pumpAndSettle();
    expect(wallpaper().spec.everywhere, isFalse);
  });
}
