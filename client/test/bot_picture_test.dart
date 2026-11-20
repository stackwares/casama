// Bot pictures in the app (docs/BOT-PICTURES-PLAN.md): the avatar_url value, BotAvatar drawing a
// picture, the Picture tile, the picture sheet on the bot's profile, and the upload with Undo and
// Try again.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/bot_picture.dart';
import 'package:casama/features/bots/bot_profile_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/ui/bot_avatar.dart';
import 'package:casama/ui/mascot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

const _pic = 'image:6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f:7a90ff7de9f4';

Future<Uint8List> _png(int side) async {
  final r = ui.PictureRecorder();
  ui.Canvas(r).drawRect(
    Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
    Paint()..color = const Color(0xFF22AA66),
  );
  final img = await r.endRecording().toImage(side, side);
  final d = await img.toByteData(format: ui.ImageByteFormat.png);
  return d!.buffer.asUint8List();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

Widget _profile(FakeBackend backend) => ProviderScope(
  overrides: [
    backendProvider.overrideWithValue(backend),
    localCacheProvider.overrideWithValue(const NoCache()),
  ],
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: '/bots/$botId/settings',
      routes: [
        GoRoute(
          path: '/bots/:botId/settings',
          builder: (_, s) =>
              BotProfileScreen(botId: s.pathParameters['botId']!),
        ),
      ],
    ),
  ),
);

/// A button that puts [bytes] through the cropper and onto the bot, as a drop or a paste would.
class _Uploader extends ConsumerWidget {
  const _Uploader(this.bytes);
  final Uint8List bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bot = ref.watch(botProvider(botId));
    return Scaffold(
      body: Column(
        children: [
          if (bot != null)
            BotAvatar(
              key: const Key('shown'),
              name: bot.name,
              avatar: bot.avatarUrl,
              preview: botPicturePreviewOf(ref, bot),
            ),
          TextButton(
            onPressed: bot == null
                ? null
                : () => cropAndSetBotPicture(
                    context,
                    ref,
                    bot,
                    bytes,
                    source: 'paste',
                  ),
            child: const Text('use'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('the avatar_url value', () {
    final vectors =
        (jsonDecode(
              File('../packages/domain/test/fixtures/bot-avatar-vectors.json')
                  .readAsStringSync(),
            ) as Map)['vectors']
            as List;
    for (final v in vectors.cast<Map>()) {
      test('${v['value']} is ${v['kind']}', () {
        final value = v['value'] as String?;
        final picture = BotPictureRef.parse(value);
        final mascot = Mascot.fromAvatar(value);
        final kind = picture != null
            ? 'image'
            : (mascot != null ? 'mascot' : 'initials');
        expect(kind, v['kind']);
        if (picture != null) {
          expect(picture.id, v['id']);
          String hex(Color c) =>
              '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
          expect(picture.colors.map(hex).toList(), v['colors']);
        }
      });
    }

    test("a picture's colours are the bot's colours", () {
      expect(botColors('Ada', _pic), const [
        Color(0xFF7A90FF),
        Color(0xFF7DE9F4),
      ]);
      expect(botColors('Ada', null), botPalette('Ada'));
    });
  });

  group('BotAvatar', () {
    tearDown(() => BotAvatar.imageUrl = null);
    Widget app(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

    testWidgets(
      "without a server it shows the initials on the picture's colours",
      (tester) async {
        await tester.pumpWidget(
          app(const BotAvatar(name: 'Ada Lovelace', avatar: _pic)),
        );
        expect(find.text('AL'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      },
    );

    testWidgets(
      'with a server it loads the small picture for small avatars and the big one for big',
      (tester) async {
        final asked = <(String, bool)>[];
        BotAvatar.imageUrl = (id, {bool small = false}) {
          asked.add((id, small));
          return 'http://localhost/v1/bot-images/$id';
        };
        await tester.pumpWidget(
          app(
            const Column(
              children: [
                BotAvatar(name: 'Ada', avatar: _pic, size: 40),
                BotAvatar(name: 'Ada', avatar: _pic, size: 112),
              ],
            ),
          ),
        );
        expect(find.byType(Image), findsNWidgets(2));
        expect(asked, [
          ('6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f', true),
          ('6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f', false),
        ]);
      },
    );

    testWidgets('a picture just cropped shows at once from memory', (
      tester,
    ) async {
      final bytes = (await tester.runAsync(() => _png(64)))!;
      await tester.pumpWidget(app(BotAvatar(name: 'Ada', preview: bytes)));
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).imageProvider, isA<MemoryImage>());
    });
  });

  group('on the bot profile', () {
    testWidgets(
      'the Picture tile, the sheet and removing back to the earlier mascot',
      (tester) async {
        await setSize(tester, const Size(800, 2400));
        readClipboardPicture = () async => null;
        final backend = FakeBackend()..botAvatar = 'mascot:wow';
        final bytes = (await tester.runAsync(() => _png(300)))!;
        await backend.setBotPicture(botId, bytes, source: 'upload');
        await tester.pumpWidget(_profile(backend));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mascotPicker-picture')), findsOneWidget);

        await tester.tap(find.byKey(const Key('botPictureEdit')));
        await tester.pumpAndSettle();
        expect(find.text("Ada's Picture"), findsOneWidget);
        expect(find.byKey(const Key('botPictureLibrary')), findsOneWidget);
        expect(find.byKey(const Key('botPictureDraw')), findsOneWidget);
        expect(find.byKey(const Key('botPicturePaste')), findsNothing);
        await tester.tap(find.byKey(const Key('botPictureRemove')));
        await tester.pumpAndSettle();
        expect(backend.botAvatar, 'mascot:wow');
        expect(find.text('Picture removed'), findsOneWidget);
        // Undo brings the picture back.
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(backend.botAvatar, startsWith('image:'));
        // And Save has nothing to put back: the screen kept up.
        expect(find.byKey(const Key('botProfileSave')), findsNothing);
      },
    );

    testWidgets('a recent picture is one tap away', (tester) async {
      await setSize(tester, const Size(800, 2400));
      readClipboardPicture = () async => null;
      final backend = FakeBackend();
      final bytes = (await tester.runAsync(() => _png(300)))!;
      await backend.setBotPicture(botId, bytes);
      final first = backend.botAvatar!;
      await backend.setBotPicture(botId, bytes);
      await tester.pumpWidget(_profile(backend));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('botPictureEdit')));
      await tester.pumpAndSettle();
      final id = BotPictureRef.parse(first)!.id;
      await tester.tap(find.byKey(Key('botPictureRecent-$id')));
      await tester.pumpAndSettle();
      expect(backend.botAvatar, first);
    });
  });

  group('the upload', () {
    testWidgets(
      'crops, shows the picture at once, saves the original, and Undo goes back',
      (tester) async {
        await setSize(tester, const Size(390, 844));
        final backend = FakeBackend()..botAvatar = 'mascot:cool';
        final bytes = (await tester.runAsync(() => _png(600)))!;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              backendProvider.overrideWithValue(backend),
              localCacheProvider.overrideWithValue(const NoCache()),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: _Uploader(bytes),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('use'));
        await _settle(tester);
        expect(find.text('Move and Scale'), findsOneWidget);
        await tester.tap(find.byKey(const Key('avatarCropDone')));
        await _settle(tester);
        expect(backend.botPictureUploads, hasLength(1));
        final up = backend.botPictureUploads.single;
        expect(up.original, bytes);
        expect(up.crop?.x, closeTo(0.5, 0.001));
        expect(backend.botAvatar, startsWith('image:'));
        expect(find.text('Picture updated'), findsOneWidget);
        // Shown from memory, so it never flickers while the server's copy loads.
        final shown = tester.widget<BotAvatar>(find.byKey(const Key('shown')));
        expect(shown.preview, isNotNull);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(backend.botAvatar, 'mascot:cool');
      },
    );

    testWidgets('a failed upload keeps the crop for Try again', (tester) async {
      await setSize(tester, const Size(390, 844));
      final backend = FakeBackend()..botPictureError = Exception('offline');
      final bytes = (await tester.runAsync(() => _png(600)))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            localCacheProvider.overrideWithValue(const NoCache()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _Uploader(bytes),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('use'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('avatarCropDone')));
      await _settle(tester);
      expect(find.textContaining("Couldn't save the picture"), findsOneWidget);
      expect(backend.botAvatar, isNull);
      backend.botPictureError = null;
      await tester.tap(find.text('Try Again'));
      await _settle(tester);
      // No second crop: the same picture went up.
      expect(find.text('Move and Scale'), findsNothing);
      expect(backend.botPictureUploads, hasLength(1));
      expect(backend.botAvatar, startsWith('image:'));
    });
  });
}
