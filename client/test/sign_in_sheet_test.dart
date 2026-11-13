import 'package:casama_app/core/sign_in_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('casama/sign_in_sheet');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<SignInSheetResult> answer(Future<Object?> Function(MethodCall) handler) async {
    MethodCall? seen;
    messenger.setMockMethodCallHandler(channel, (call) {
      seen = call;
      return handler(call);
    });
    final r = await openSignIn('https://composio.example/signin/1');
    expect(seen?.arguments, {'url': 'https://composio.example/signin/1', 'scheme': 'casama-auth'});
    return r;
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('phones use the sign-in sheet', () {
    expect(signInSheetAvailable, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(signInSheetAvailable, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(signInSheetAvailable, isFalse);
  });

  test('reads how the sheet ended', () async {
    expect(await answer((_) async => 'casama-auth://done?status=ok'), SignInSheetResult.finished);
    expect(await answer((_) async => 'casama-auth://done?status=error'), SignInSheetResult.failed);
    expect(await answer((_) async => null), SignInSheetResult.closed);
  });

  test("falls back to the browser when the sheet can't open", () async {
    final opened = <Uri>[];
    openInBrowser = (url) async => opened.add(url);
    expect(await answer((_) async => throw PlatformException(code: 'failed')), SignInSheetResult.browser);
    expect(opened, [Uri.parse('https://composio.example/signin/1')]);
  });
}
