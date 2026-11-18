import 'package:casama/core/chrome_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'casama_link_test.dart' show openPairSheet;
import 'fake_backend.dart';

void main() {
  group('Connect Chrome (D-323)', () {
    late ChromeSender original;
    setUp(() => original = chromeSender);
    tearDown(() => chromeSender = original);

    Future<ChromeHandoverResult> connectWith(Map<String, Object?>? reply) {
      chromeSender = (id, message) async {
        expect(chromeExtensionIds, contains(id));
        expect(message, {
          'type': 'casama.signIn',
          'link': 'https://casama.ai/pair#c=x',
        });
        return reply;
      };
      return connectChrome('https://casama.ai/pair#c=x');
    }

    test('reads what the extension answers', () async {
      expect(
        (await connectWith({'ok': true, 'email': 'a@b.co'})).outcome,
        ChromeHandover.signedIn,
      );
      expect(
        (await connectWith({'ok': true, 'pending': true})).outcome,
        ChromeHandover.finishInChrome,
      );
      final failed = await connectWith({'ok': false, 'error': 'Code used'});
      expect(failed.outcome, ChromeHandover.failed);
      expect(failed.error, 'Code used');
    });

    test('no answer means the extension is not installed', () async {
      expect((await connectWith(null)).outcome, ChromeHandover.notInstalled);
      expect(
        (await connectWith({'unexpected': 1})).outcome,
        ChromeHandover.notInstalled,
      );
    });
  });

  group('Sign In on Another Device: copy the link', () {
    late List<String> copied;
    setUp(() {
      copied = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          });
    });
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    testWidgets('copies the sign-in link to paste into Casama for Chrome', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      await openPairSheet(tester, backend);
      await tester.pumpAndSettle();
      // Connect Chrome is only offered in the web app.
      expect(find.byKey(const Key('pairConnectChrome')), findsNothing);
      await tester.tap(find.byKey(const Key('pairCopyLink')));
      await tester.pumpAndSettle();
      expect(copied, [
        'https://casama.ai/pair#v=1&s=${Uri.encodeComponent(backend.signInCodeServer)}&c=ksc_code-1',
      ]);
      expect(find.textContaining('Link copied'), findsOneWidget);
    });

    testWidgets(
      'offers the link even where a phone could not reach the server',
      (tester) async {
        await setSize(tester, const Size(500, 900));
        final backend = FakeBackend()
          ..signInCodeServer = 'http://localhost:8080'
          ..signInCodeReachable = false;
        await openPairSheet(tester, backend);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pairQr')), findsNothing);
        await tester.tap(find.byKey(const Key('pairCopyLink')));
        await tester.pumpAndSettle();
        expect(copied.single, contains('localhost%3A8080'));
      },
    );
  });
}
