// A file that fails to upload (say the computer has no hours left) never drops out of a message
// silently: the message stays in the box with the failed chip and a reason, and goes without the
// file only when the person picks Send without it.
import 'dart:typed_data';

import 'package:casama/features/chat/chat_screen.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

final class _File extends PlatformFile {
  _File(this.name, this.bytes);
  @override
  final String name;
  final Uint8List bytes;
  @override
  Uri get uri => Uri.parse('memory:$name');
  @override
  XFile get xFile => XFile.fromData(bytes, name: name);
  @override
  int? lengthSync() => bytes.length;
  @override
  Future<int?> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

final class _Picker extends FilePickerPlatform {
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => [
    _File('report.pdf', Uint8List.fromList([1, 2, 3])),
  ];
}

/// The computer can't start: every upload is refused the way the server refuses it.
class _NoHoursBackend extends FakeBackend {
  @override
  Future<void> uploadFile(
    String computerId,
    String path,
    Uint8List bytes,
  ) async {
    final req = RequestOptions(path: '/v1/computers/$computerId/files');
    throw DioException(
      requestOptions: req,
      response: Response(
        requestOptions: req,
        statusCode: 402,
        data: {
          'type': 'about:blank',
          'title': 'Payment Required',
          'status': 402,
          'code': 'computer_hours_exceeded',
          'detail': 'The workspace used its computer hours for this month.',
        },
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FilePickerPlatform.instance = _Picker();
  });

  testWidgets(
    'a failed file keeps the message in the box until Send without it',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = _NoHoursBackend();
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attachFiles')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Couldn't attach report.pdf: The workspace used its computer hours for this month.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('retry-report.pdf')), findsOneWidget);
      // Let the toast go, so it doesn't cover the composer.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'Summarize this',
      );
      await tester.pump();
      final sentBefore = backend.sent.length;
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pumpAndSettle();
      // Not sent: it asks, and Cancel leaves the words and the failed chip where they were.
      expect(find.text("Couldn't attach report.pdf"), findsOneWidget);
      expect(backend.sent.length, sentBefore);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.sent.length, sentBefore);
      expect(find.text('Summarize this'), findsOneWidget);
      expect(find.byKey(const Key('pending-report.pdf')), findsOneWidget);

      // Send without it: the words go, the file doesn't.
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sendWithoutFailed')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(backend.sent.last, 'Summarize this');
      expect(backend.sentAttachments.last, isEmpty);
      expect(find.byKey(const Key('pending-report.pdf')), findsNothing);
    },
  );
}
