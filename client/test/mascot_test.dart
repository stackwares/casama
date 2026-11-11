import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/features/bots/bots_screen.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';
import 'package:kasama_app/ui/bot_avatar.dart';
import 'package:kasama_app/ui/kasama_mark.dart';
import 'package:kasama_app/ui/mascot.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

void main() {
  test('a bot avatar_url maps to a mascot, anything else to initials', () {
    for (final m in Mascot.values) {
      expect(Mascot.fromAvatar(m.avatarValue), m);
    }
    expect(Mascot.fromAvatar(null), isNull);
    expect(Mascot.fromAvatar('mascot:nope'), isNull);
    expect(Mascot.fromAvatar('https://example.com/a.png'), isNull);
  });

  testWidgets('every mascot ships an animated loop Flutter can decode, plus a still', (tester) async {
    await tester.runAsync(() async {
      for (final m in Mascot.values) {
        final codec = await ui.instantiateImageCodec((await rootBundle.load(m.animatedAsset)).buffer.asUint8List());
        expect(codec.frameCount, greaterThan(60), reason: m.name);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, MascotImage.assetPx);
        expect(frame.duration.inMilliseconds, inInclusiveRange(60, 100));
        expect((await rootBundle.load(m.stillAsset)).lengthInBytes, greaterThan(1000));
      }
    });
  });

  Widget app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('a mascot avatar draws the cloud without the colored tile', (tester) async {
    await tester.pumpWidget(app(const BotAvatar(name: 'Chief', avatar: 'mascot:giggly', size: 64)));
    expect(find.byType(MascotImage), findsOneWidget);
    expect(find.text('C'), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as ResizeImage).imageProvider, isA<AssetImage>().having((a) => a.assetName, 'asset', 'assets/mascots/giggly.webp'));
  });

  testWidgets('small mascot avatars stay still; no mascot shows initials', (tester) async {
    await tester.pumpWidget(app(const Column(children: [
      BotAvatar(name: 'Chief', avatar: 'mascot:wow', size: 30),
      BotAvatar(name: 'Chief', size: 30),
    ])));
    final image = tester.widget<Image>(find.byType(Image));
    expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName, 'assets/mascots/wow.png');
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('the Kasama mark is one of the brand mascots', (tester) async {
    await tester.pumpWidget(app(const KasamaMark(size: 64)));
    final mascot = tester.widget<MascotImage>(find.byType(MascotImage)).mascot;
    expect(Mascot.brand, contains(mascot));
  });

  testWidgets('a new bot gets the icon picked in the sheet', (tester) async {
    await setSize(tester, const Size(600, 1100));
    final backend = FakeBackend();
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Consumer(builder: (context, ref, _) => TextButton(onPressed: () => showCreateBot(context, ref), child: const Text('open'))),
        ),
      ),
      GoRoute(path: '/bots/:id/chat', builder: (_, _) => const Text('chat opened')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Starry'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    expect(backend.createdBotAvatar, 'mascot:starry');
  });
}
