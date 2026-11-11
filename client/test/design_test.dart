import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/chat/chat_detail.dart';
import 'package:casama_app/theme/fonts.dart';
import 'package:casama_app/features/settings/background_screen.dart';
import 'package:casama_app/features/settings/gallery_screen.dart';
import 'package:casama_app/features/settings/photo_picker.dart';
import 'package:casama_app/features/settings/fonts_screen.dart';
import 'package:casama_app/features/settings/themes_screen.dart';
import 'package:casama_app/features/usage/usage_screen.dart';
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:casama_app/features/settings/theme_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/presets.dart';
import 'package:casama_app/theme/schemes.dart';
import 'package:casama_app/theme/wallpaper.dart';

import 'app_test.dart' show StepsShown;
import 'fake_backend.dart';

Widget _app(
  FakeBackend backend,
  Widget child, {
  List<dynamic> overrides = const [],
}) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend), ...overrides],
  child: Consumer(
    builder: (context, ref, _) {
      final a = ref.watch(appearanceProvider);
      return MaterialApp(
        theme: AppTheme.light(a),
        darkTheme: AppTheme.dark(a),
        themeMode: a.mode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
    },
  ),
);

void main() {
  testWidgets(
    'consecutive tool steps share one card, even across the computer starting',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final backend = FakeBackend();
      await tester.pumpWidget(
        _app(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
          overrides: [showBotStepsProvider.overrideWith(StepsShown.new)],
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'make a todo file',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      backend.runEventsController
        ..add(
          ev(1, 'run.started', {
            'trigger': 'chat',
            'model': 'm',
            'computer_id': null,
          }),
        )
        ..add(
          ev(2, 'tool.started', {
            'call_id': 'c1',
            'tool': 'files.write',
            'args_redacted': {'path': 'launch/todo.md'},
          }),
        )
        ..add(
          ev(3, 'tool.completed', {
            'call_id': 'c1',
            'result_preview': 'ok',
            'artifact_path': null,
            'duration_ms': 480,
          }),
        )
        ..add(
          ev(4, 'computer.state', {
            'computer_id': '00000000-0000-0000-0000-000000000009',
            'state': 'running',
          }),
        )
        ..add(
          ev(5, 'tool.started', {
            'call_id': 'c2',
            'tool': 'files.read',
            'args_redacted': {'path': 'launch/todo.md'},
          }),
        )
        ..add(
          ev(6, 'tool.completed', {
            'call_id': 'c2',
            'result_preview': 'ok',
            'artifact_path': null,
            'duration_ms': 20,
          }),
        );
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
    },
  );

  testWidgets(
    'appearance: mode, color scheme and background apply right away',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(FakeBackend(), const SettingsScreen()));
      await tester.pumpAndSettle();
      ThemeData theme() =>
          Theme.of(tester.element(find.byType(SettingsScreen)));
      final lightSurface = theme().colorScheme.surface;
      // Casama's own scheme is the default: orchid primary from the app icon.
      expect(theme().colorScheme.primary, casamaScheme.light.primary);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(theme().colorScheme.surface, isNot(lightSurface));
      expect(theme().colorScheme.surface.computeLuminance(), lessThan(0.05));

      // Picking another scheme recolors the app.
      await tester.pumpWidget(_app(FakeBackend(), const ThemeScreen()));
      await tester.pumpAndSettle();
      final casamaPrimary = Theme.of(tester.element(find.byType(ThemeScreen)))
          .colorScheme
          .primary;
      await tester.enterText(find.byKey(const Key('themeSearch')), 'mandy');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scheme-mandyRed')));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ThemeScreen))).colorScheme.primary,
        isNot(casamaPrimary),
      );

      // The background pattern and its reach are carried by the theme.
      await tester.pumpWidget(_app(FakeBackend(), const BackgroundScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pattern-doodles')));
      await tester.pumpAndSettle();
      WallpaperTheme wallpaper() =>
          Theme.of(tester.element(find.byType(BackgroundScreen)))
              .extension<WallpaperTheme>()!;
      expect(wallpaper().spec.pattern, WallpaperPattern.doodles);
      await tester.ensureVisible(find.byKey(const Key('wallpaperEverywhere')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wallpaperEverywhere')));
      await tester.pumpAndSettle();
      expect(wallpaper().spec.everywhere, isFalse);

      // With "Show in the whole app" off, chats still force their own wallpaper; with it on,
      // the route's outer wallpaper already covers the chat so it doesn't paint a second copy.
      await tester.pumpWidget(
        _app(
          FakeBackend(),
          const ChatScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();
      final chatContainer = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      expect(
        find
            .descendant(
              of: find.byType(ChatScreen),
              matching: find.byWidgetPredicate(
                (w) => w is Wallpaper && w.force,
              ),
            ),
        findsOneWidget,
      );
      unawaited(
        chatContainer
            .read(appearanceProvider.notifier)
            .setWallpaper(
              chatContainer
                  .read(appearanceProvider)
                  .wallpaper
                  .copyWith(everywhere: false),
            ),
      );
      await tester.pumpAndSettle();
      expect(
        find
            .descendant(
              of: find.byType(ChatScreen),
              matching: find.byType(RepaintBoundary),
            ),
        findsWidgets,
      );
    },
  );

  testWidgets('themes: a preset sets scheme, fonts and wallpaper together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(FakeBackend(), const ThemesScreen()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ThemesScreen)),
    );
    await tester.ensureVisible(find.byKey(const Key('preset-editorial')));
    await tester.tap(find.byKey(const Key('preset-editorial')));
    await tester.pumpAndSettle();
    final a = container.read(appearanceProvider);
    expect(a.schemeId, 'sepia');
    expect(a.headingFont, 'Fraunces');
    expect(a.wallpaper.palette, WallpaperPalette.peach);
    // The theme's text styles follow the preset's fonts.
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(ThemesScreen)))
          .textTheme
          .headlineSmall
          ?.fontFamily,
      'Fraunces',
    );
  });

  test('a theme survives a share code round trip, without local photos', () {
    const preset = ThemePreset(
      id: 'x',
      name: 'Night swim',
      schemeId: 'blueWhale',
      headingFont: 'Lora',
      bodyFont: 'Inter',
      wallpaper: WallpaperSpec(
        pattern: WallpaperPattern.sea,
        palette: WallpaperPalette.ocean,
        photo: '/private/photo.jpg',
        photoBlur: 0.6,
      ),
    );
    final code = preset.toCode();
    expect(code, startsWith('casama-theme:'));
    final back = ThemePreset.fromCode(code)!;
    expect(back.name, 'Night swim');
    expect(back.schemeId, 'blueWhale');
    expect(back.headingFont, 'Lora');
    expect(back.wallpaper.pattern, WallpaperPattern.sea);
    expect(back.wallpaper.photoBlur, 0.6);
    expect(back.wallpaper.photo, isNull);
    expect(ThemePreset.fromCode('hello'), isNull);
    expect(ThemePreset.fromCode('casama-theme:!!!'), isNull);
  });

  testWidgets(
    'fonts: picking a heading font applies it; reset goes back to the defaults',
    (tester) async {
      tester.view.physicalSize = const Size(700, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(FakeBackend(), const FontsScreen()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FontsScreen)),
      );
      await tester.ensureVisible(find.byKey(const Key('font-Fraunces')));
      await tester.tap(find.byKey(const Key('font-Fraunces')));
      await tester.pumpAndSettle();
      expect(container.read(appearanceProvider).headingFont, 'Fraunces');
      await tester.ensureVisible(find.byKey(const Key('resetFonts')));
      await tester.tap(find.byKey(const Key('resetFonts')));
      await tester.pumpAndSettle();
      expect(
        container.read(appearanceProvider).headingFont,
        defaultHeadingFont,
      );
      expect(container.read(appearanceProvider).bodyFont, defaultBodyFont);
    },
  );

  testWidgets('usage shows totals, breakdowns and exports', (tester) async {
    tester.view.physicalSize = const Size(700, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(FakeBackend(), const UsageScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('usageSpend')), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.byKey(const Key('askAboutUsage')), findsOneWidget);
  });

  test('usage CSV escapes and lists every section', () {
    final csv = usageCsv(
      UsageReport(
        period: UsageReportPeriodEnum.month,
        since: DateTime.utc(2026, 11),
        totalCostUsd: 1.5,
        byBot: [
          UsageReportByBotInner(
            botId: null,
            name: 'Ada, the bot',
            costUsd: 1.5,
            tokensIn: 10,
            tokensOut: 2,
          ),
        ],
        byDay: [
          UsageReportByDayInner(
            day: '2026-11-02',
            costUsd: 1.5,
            tokensIn: 10,
            tokensOut: 2,
          ),
        ],
      ),
    );
    expect(csv.split('\n').first, 'section,key,cost_usd,tokens_in,tokens_out');
    expect(csv, contains('bot,"Ada, the bot",1.5,10,2'));
    expect(csv, contains('day,2026-11-02,1.5,10,2'));
    expect(csv, contains('total,month,1.5'));
  });

  testWidgets('asking a bot about usage sends the numbers into a new chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const UsageScreen()),
        GoRoute(
          path: '/bots/:id/chat',
          builder: (_, s) => Text('chat ${s.uri.queryParameters['c']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('askAboutUsage')));
    await tester.tap(find.byKey(const Key('askAboutUsage')));
    await tester.pumpAndSettle();
    expect(
      backend.sent.single,
      contains('Here is my Casama usage for This month'),
    );
    expect(backend.sent.single, contains('Ada: \$0.0123'));
    expect(find.text('chat $convId'), findsOneWidget);
  });

  testWidgets(
    'browsing photos and the gallery reloads without a setState future',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(FakeBackend(), const Scaffold(body: PhotoPicker())),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('photoSearch')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('photoSearch')), 'fern');
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_app(FakeBackend(), const GalleryScreen()));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('galleryType-theme')));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
