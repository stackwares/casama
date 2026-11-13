import 'dart:convert';

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/media_cache.dart';
import 'package:casama_app/features/chat/media/chat_pdf.dart';
import 'package:casama_app/features/chat/media/chat_video.dart';
import 'package:casama_app/features/chat/media/computer_thumbnail.dart';
import 'package:casama_app/features/files/file_preview.dart';
import 'package:casama_app/features/chat/media/media_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

// One transparent pixel.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

AttachmentRef _file(String path, String mime) => AttachmentRef(
  path: path,
  name: path.split('/').last,
  mimeType: mime,
  size: 1000,
);

Widget _inChat(Widget child) => Scaffold(
  body: FileLinkScope(
    computerId: 'computer-1',
    open: (_) {},
    child: Center(child: child),
  ),
);

/// Thumbnails of videos and PDFs on a bot's computer (D-226).
void main() {
  setUp(() async {
    ComputerThumbnails.reset();
    await MediaCache.clear();
  });

  testWidgets('a card built again shows its thumbnail on its first frame', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..thumbnails['clips/trip.mp4'] = ComputerThumbnail(
        bytes: _png,
        duration: const Duration(seconds: 75),
      );
    Widget card() => harness(
      backend,
      _inChat(
        ChatVideo(
          attachment: _file('workspace/clips/trip.mp4', 'video/mp4'),
          computerId: 'computer-1',
        ),
      ),
    );
    await tester.pumpWidget(card());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(const Key('videoThumbnail')), findsOneWidget);

    // Scrolled away and back: no wait, no second request, no loading sweep.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(card());
    expect(find.byKey(const Key('videoThumbnail')), findsOneWidget);
    expect(find.byKey(const Key('videoPosterLoading')), findsNothing);
    expect(find.text('1:15'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(backend.thumbnailRequests, ['clips/trip.mp4']);
  });

  testWidgets('a video kept with the chat shows the server\'s poster, not a player', (
    tester,
  ) async {
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(
        backend,
        _inChat(
          ChatVideo(
            attachment: const AttachmentRef(
              path: 'media:0f8fad5b-d9cb-469f-a165-70867728950e',
              name: 'clip.mp4',
              mimeType: 'video/mp4',
              size: 1000,
              width: 1280,
              height: 720,
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byKey(const Key('videoThumbnail')));
    expect(
      (image.image as NetworkImage).url,
      'http://localhost:8787/v1/media/0f8fad5b-d9cb-469f-a165-70867728950e/poster',
    );
    // A soft sweep while it loads.
    expect(find.byKey(const Key('videoPosterLoading')), findsOneWidget);
  });

  testWidgets(
    'a video on the computer shows its thumbnail and length as the poster',
    (tester) async {
      final backend = FakeBackend()
        ..thumbnails['clips/trip.mp4'] = ComputerThumbnail(
          bytes: _png,
          duration: const Duration(seconds: 75),
        );
      await tester.pumpWidget(
        harness(
          backend,
          _inChat(
            ChatVideo(
              attachment: _file('workspace/clips/trip.mp4', 'video/mp4'),
              computerId: 'computer-1',
            ),
          ),
        ),
      );
      // Nothing is asked for until the card has stayed on screen a moment.
      expect(backend.thumbnailRequests, isEmpty);
      expect(find.byKey(const Key('videoThumbnail')), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(backend.thumbnailRequests, ['clips/trip.mp4']);
      expect(find.byKey(const Key('videoThumbnail')), findsOneWidget);
      expect(find.text('1:15'), findsOneWidget);
    },
  );

  testWidgets(
    'no thumbnail (asleep, offline, unsupported) keeps the dark tile, quietly',
    (tester) async {
      final backend = FakeBackend();
      Widget card() => harness(
        backend,
        _inChat(
          ChatVideo(
            attachment: _file('/Users/me/Desktop/Passports/x.mp4', 'video/mp4'),
            computerId: 'computer-1',
          ),
        ),
      );
      await tester.pumpWidget(card());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(backend.thumbnailRequests, ['/Users/me/Desktop/Passports/x.mp4']);
      expect(find.byKey(const Key('videoThumbnail')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      // Where the system player plays videos (Linux, Windows) the card says so instead of the name.
      expect(find.text(inlineVideoSupported ? 'x.mp4' : 'Open in your video player'), findsOneWidget);

      // Opening the chat again right away doesn't ask again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(card());
      await tester.pump(const Duration(milliseconds: 300));
      expect(backend.thumbnailRequests, hasLength(1));
    },
  );

  testWidgets(
    'cards scrolled past quickly ask for nothing; the same file is asked for once',
    (tester) async {
      final backend = FakeBackend()
        ..thumbnails['a.mp4'] = ComputerThumbnail(bytes: _png);
      final video = _file('workspace/a.mp4', 'video/mp4');
      await tester.pumpWidget(
        harness(
          backend,
          _inChat(ChatVideo(attachment: video, computerId: 'computer-1')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(harness(backend, _inChat(const SizedBox())));
      await tester.pump(const Duration(seconds: 1));
      expect(backend.thumbnailRequests, isEmpty);

      await tester.pumpWidget(
        harness(
          backend,
          _inChat(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatVideo(
                  attachment: video,
                  computerId: 'computer-1',
                  maxWidth: 160,
                ),
                ChatVideo(
                  attachment: video,
                  computerId: 'computer-1',
                  maxWidth: 160,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(backend.thumbnailRequests, ['a.mp4']);
      expect(find.byKey(const Key('videoThumbnail')), findsNWidgets(2));
    },
  );

  testWidgets('a PDF on the computer shows its first page from a thumbnail', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..thumbnails['report.pdf'] = ComputerThumbnail(bytes: _png);
    await tester.pumpWidget(
      harness(
        backend,
        _inChat(
          ChatPdfCard(
            attachment: _file('workspace/report.pdf', 'application/pdf'),
            computerId: 'computer-1',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(backend.thumbnailRequests, ['report.pdf']);
    expect(find.byKey(const Key('pdfThumbnail')), findsOneWidget);
  });
}
