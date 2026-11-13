import 'package:casama_app/core/web_auth_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('casama/web_auth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('the code comes from the query, or after the #', () {
    expect(
      oauthCallbackResult(Uri.parse('casama://app/login-callback?code=abc')),
      (code: 'abc', error: null),
    );
    expect(
      oauthCallbackResult(Uri.parse('casama://app/login-callback#code=xyz')),
      (code: 'xyz', error: null),
    );
  });

  test('no code: the server says why, or a plain reason', () {
    expect(
      oauthCallbackResult(
        Uri.parse(
          'casama://app/login-callback?error=access_denied&error_description=Denied+by+user',
        ),
      ).error,
      'Denied by user',
    );
    expect(
      oauthCallbackResult(
        Uri.parse('casama://app/login-callback#error=server_error'),
      ).error,
      'server_error',
    );
    expect(
      oauthCallbackResult(Uri.parse('casama://app/login-callback')).error,
      'The sign-in page did not send a sign-in code.',
    );
  });

  test('the window hands back the link, null on cancel', () async {
    MethodCall? seen;
    messenger.setMockMethodCallHandler(channel, (call) async {
      seen = call;
      return 'casama://app/login-callback?code=abc';
    });
    final link = await openWebAuthSheet(
      Uri.parse('https://auth.example/authorize'),
      scheme: 'casama',
    );
    expect(link.toString(), 'casama://app/login-callback?code=abc');
    expect(seen!.method, 'authenticate');
    expect(seen!.arguments, {
      'url': 'https://auth.example/authorize',
      'scheme': 'casama',
    });

    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'canceled'),
    );
    expect(
      await openWebAuthSheet(
        Uri.parse('https://auth.example'),
        scheme: 'casama',
      ),
      isNull,
    );
  });

  test(
    'no window (no plugin, or it would not open) falls back to the browser',
    () async {
      await expectLater(
        openWebAuthSheet(Uri.parse('https://auth.example'), scheme: 'casama'),
        throwsA(isA<WebAuthUnavailable>()),
      );
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      await expectLater(
        openWebAuthSheet(Uri.parse('https://auth.example'), scheme: 'casama'),
        throwsA(isA<WebAuthUnavailable>()),
      );
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'failed', message: 'boom'),
      );
      await expectLater(
        openWebAuthSheet(Uri.parse('https://auth.example'), scheme: 'casama'),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
