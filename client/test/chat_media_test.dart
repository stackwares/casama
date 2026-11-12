import 'dart:convert';
import 'dart:typed_data';

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/media/attachment_view.dart';
import 'package:casama_app/features/chat/media/chat_audio.dart';
import 'package:casama_app/features/chat/media/chat_pdf.dart';
import 'package:casama_app/features/chat/media/chat_picture.dart';
import 'package:casama_app/features/chat/media/chat_video.dart';
import 'package:casama_app/features/chat/media/media_kind.dart';
import 'package:casama_app/features/chat/media/preview_body.dart';
import 'package:casama_app/features/chat/widgets/chat_markdown.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:casama_app/features/files/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

// One transparent pixel.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

AttachmentRef _media(String id, String mime, {int? w, int? h}) => AttachmentRef(
  path: 'media:$id',
  name: 'file.${mime.split('/').last}',
  mimeType: mime,
  size: 1000,
  width: w,
  height: h,
);

Widget _inChat(Widget child, {String? computerId}) => Scaffold(
  body: FileLinkScope(
    computerId: computerId,
    open: (_) {},
    child: Center(child: child),
  ),
);

void main() {
  test('media file parts read from message content, sizes included', () {
    final files = attachmentsOf([
      {'type': 'text', 'text': 'Here it is'},
      {
        'type': 'file',
        'path': 'media:abc',
        'name': 'image.png',
        'mime_type': 'image/png',
        'size': 2048,
        'width': 1024,
        'height': 768,
      },
      {
        'type': 'file',
        'path': 'media:vid',
        'name': 'video.mp4',
        'mime_type': 'video/mp4',
        'size': 9000,
        'duration_s': 5.5,
      },
    ]);
    expect(files.map((f) => f.mediaId), ['abc', 'vid']);
    expect((files.first.width, files.first.height), (1024, 768));
    expect(files.last.durationS, 5.5);
    expect(attachmentKind(files.last), MediaKind.video);
  });

  test('a live finished reply carries its media, even with no text', () {
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(FakeBackend())],
    );
    addTearDown(container.dispose);
    final c = container.read(chatControllerProvider('bot-1').notifier);
    c.apply(
      ev(1, 'message.completed', {
        'message_id': 'm1',
        'content': [
          {
            'type': 'file',
            'path': 'media:img1',
            'name': 'image.png',
            'mime_type': 'image/png',
            'size': 10,
          },
        ],
      }),
    );
    final m = container
        .read(chatControllerProvider('bot-1'))
        .entries
        .whereType<MessageEntry>()
        .single;
    expect(m.text, isEmpty);
    expect(m.attachments.single.path, 'media:img1');
  });

  test('pictures keep their shape within 280 × 360', () {
    expect(chatImageBox(1024, 768, 600), const Size(280, 210));
    expect(chatImageBox(800, 1600, 600), const Size(180, 360));
    // Small pictures aren't blown up; narrow chats shrink them.
    expect(chatImageBox(120, 90, 600), const Size(120, 90));
    expect(chatImageBox(1000, 500, 200), const Size(200, 100));
    expect(chatImageBox(null, null, 600), const Size(280, 210));
  });

  testWidgets('a generated image reserves its own shape before it loads', (
    tester,
  ) async {
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(
        backend,
        _inChat(
          AttachmentView(
            attachment: _media('img', 'image/png', w: 800, h: 1600),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChatPicture), findsOneWidget);
    expect(
      tester.getSize(find.byKey(attachmentKey('media:img'))),
      const Size(180, 360),
    );
  });

  testWidgets(
    'each kind gets its own view; computer files without a computer are cards',
    (tester) async {
      final backend = FakeBackend()..chatMediaFiles['img'] = _png;
      await tester.pumpWidget(
        harness(
          backend,
          _inChat(
            SingleChildScrollView(
              child: Column(
                children: [
                  AttachmentView(attachment: _media('img', 'image/png')),
                  AttachmentView(attachment: _media('v', 'video/mp4')),
                  AttachmentView(attachment: _media('a', 'audio/mpeg')),
                  AttachmentView(attachment: _media('p', 'application/pdf')),
                  AttachmentView(attachment: _media('s', 'image/svg+xml')),
                  AttachmentView(attachment: _media('z', 'application/zip')),
                  const AttachmentView(
                    attachment: AttachmentRef(
                      path: 'workspace/photo.png',
                      name: 'photo.png',
                      mimeType: 'image/png',
                      size: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ChatPicture), findsNWidgets(2)); // png + svg
      expect(find.byType(ChatVideo), findsOneWidget);
      expect(find.byType(ChatAudio), findsOneWidget);
      expect(find.byType(ChatPdfCard), findsOneWidget);
      expect(
        find.byType(FileCard),
        findsNWidgets(2),
      ); // zip + computer photo without a computer
      // Generic names show as their kind.
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
    },
  );

  testWidgets('a reply that is only media shows the media', (tester) async {
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        _inChat(
          AssistantMessage(
            entry: MessageEntry(
              id: 'm',
              role: 'assistant',
              text: '',
              attachments: [_media('v', 'video/mp4')],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MediaGroup), findsOneWidget);
    expect(find.byType(ChatVideo), findsOneWidget);
  });

  testWidgets('several pictures sit in a two-column grid', (tester) async {
    final backend = FakeBackend();
    for (final id in ['1', '2', '3', '4', '5']) {
      backend.chatMediaFiles[id] = _png;
    }
    await tester.pumpWidget(
      harness(
        backend,
        _inChat(
          MediaGroup(
            files: [
              for (final id in ['1', '2', '3', '4', '5'])
                _media(id, 'image/png'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChatPicture), findsNWidgets(4));
    expect(find.text('+1'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(attachmentKey('media:1'))),
      const Size(168, 168),
    );
  });

  test('CSV cells may hold quotes, commas and newlines', () {
    expect(
      parseCsv('name,note\n"Lee, Ann","said ""hi""\nthen left"\nBo,ok\n'),
      [
        ['name', 'note'],
        ['Lee, Ann', 'said "hi"\nthen left'],
        ['Bo', 'ok'],
      ],
    );
    expect(parseCsv('a\tb\r\n1\t2', separator: '\t'), [
      ['a', 'b'],
      ['1', '2'],
    ]);
  });

  testWidgets('a CSV file previews as a table and code is colored', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    backend.uploads['data.csv'] = Uint8List.fromList(
      utf8.encode('city,people\nManila,"1,846,513"\nCebu,964169\n'),
    );
    backend.uploads['main.dart'] = Uint8List.fromList(
      utf8.encode('void main() {\n  print("hi");\n}\n'),
    );
    await tester.pumpWidget(
      harness(
        backend,
        const Scaffold(
          body: FilePreview(computerId: 'c1', path: 'data.csv'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('csvTable')), findsOneWidget);
    expect(find.text('1,846,513'), findsOneWidget);

    await tester.pumpWidget(
      harness(
        backend,
        const Scaffold(
          body: FilePreview(computerId: 'c1', path: 'main.dart'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('codeHighlighted')), findsOneWidget);
  });

  testWidgets('chat media opens in the preview by its kind, not its id', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend()..chatMediaFiles['img'] = _png;
    await tester.pumpWidget(
      harness(
        backend,
        const Scaffold(
          body: FilePreview(
            computerId: '',
            path: 'media:img',
            name: 'image.png',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('image.png'), findsOneWidget);
    expect(find.textContaining('media:'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets(
    'markdown images from the computer show as pictures, others as chips',
    (tester) async {
      final backend = FakeBackend()..uploads['media/chart.png'] = _png;
      await tester.pumpWidget(
        harness(
          backend,
          _inChat(
            const ChatMarkdown(data: 'Look:\n\n![the chart](media/chart.png)'),
            computerId: 'c1',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PictureAttachment), findsOneWidget);

      await tester.pumpWidget(
        harness(
          backend,
          _inChat(const ChatMarkdown(data: '![the chart](media/chart.png)')),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('markdownImageChip')), findsOneWidget);
      expect(find.text('the chart'), findsOneWidget);
    },
  );
}
