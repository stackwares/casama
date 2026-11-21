// Fix 15: a photo or file shared into Casama arrives as the file itself, not its name.
import 'dart:typed_data';

import 'package:casama/core/mobile_extras.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/quick_ask/quick_ask_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

void main() {
  test('shared pictures and files become attachments; text stays text', () {
    final (text, files) = splitSharedMedia([
      SharedMediaFile(
        path: '/cache/IMG_0042.jpg',
        type: SharedMediaType.image,
        mimeType: 'image/jpeg',
      ),
      SharedMediaFile(
        path: '/cache/report.pdf',
        type: SharedMediaType.file,
        mimeType: 'application/pdf',
      ),
      SharedMediaFile(path: 'https://example.com/a', type: SharedMediaType.url),
    ]);
    expect(text, 'https://example.com/a');
    expect(files.map((f) => f.name), ['IMG_0042.jpg', 'report.pdf']);
    expect(files.first.mimeType, 'image/jpeg');
  });

  test('iOS: files the share extension copied to the App Group become attachments', () {
    final files = parseSharedFiles(
      '[{"path":"/group/shared/a/IMG_0042.heic","name":"IMG_0042.heic","mime":"image/heic"},'
      '{"path":"/group/shared/b/report.pdf"},{"name":"no path"}]',
    );
    expect(files.map((f) => f.name), ['IMG_0042.heic', 'report.pdf']);
    expect(files.first.mimeType, 'image/heic');
    expect(files.last.mimeType, isNull);
    expect(parseSharedFiles(null), isEmpty);
    expect(parseSharedFiles('not json'), isEmpty);
  });

  testWidgets(
    'quick ask uploads a shared photo to the bot computer and sends it',
    (tester) async {
      await setSize(tester, const Size(600, 900));
      final backend = FakeBackend();
      final container = ProviderContainer(
        overrides: [backendProvider.overrideWithValue(backend)],
      );
      addTearDown(container.dispose);
      final photo = Uint8List.fromList(List.filled(32, 7));
      container.read(pendingSharedFilesProvider.notifier).set([
        SharedAttachment(
          name: 'IMG_0042.jpg',
          mimeType: 'image/jpeg',
          read: () async => photo,
        ),
      ]);
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
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sharedFile-IMG_0042.jpg')), findsOneWidget);
      // Taken once: a later quick ask starts empty.
      expect(container.read(pendingSharedFilesProvider), isEmpty);
      // A photo alone can be sent.
      await tester.tap(find.byKey(const Key('quickAskSend')));
      await tester.pumpAndSettle();
      final uploaded = backend.uploads.entries.single;
      expect(uploaded.key, endsWith('-IMG_0042.jpg'));
      expect(uploaded.value, photo);
      final sent = backend.sentAttachments.single.single;
      expect(sent.name, 'IMG_0042.jpg');
      expect(sent.mimeType, 'image/jpeg');
      expect(sent.path, 'workspace/${uploaded.key}');
      expect(find.text('chat'), findsOneWidget);
    },
  );
}
