import 'dart:convert';
import 'dart:io';

import 'package:casama_app/core/desktop_sign_in_io.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(int, String)> _get(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    return (response.statusCode, await response.transform(utf8.decoder).join());
  } finally {
    client.close(force: true);
  }
}

void main() {
  test(
    'the browser coming back with a code signs in and the tab says so',
    () async {
      final loopback = await LoopbackSignIn.start();
      expect(
        loopback.redirectUrl,
        matches(RegExp(r'^http://127\.0\.0\.1:\d+/auth/callback$')),
      );
      Map<String, String>? seen;
      final done = loopback.wait((query) async {
        seen = query;
        return null;
      });
      final (missing, _) = await _get(
        loopback.redirectUrl.replaceFirst('/auth/callback', '/favicon.ico'),
      );
      expect(missing, 404);
      final (status, page) = await _get('${loopback.redirectUrl}?code=abc');
      await done;
      expect(status, 200);
      expect(seen, {'code': 'abc'});
      expect(page, contains('You are signed in'));
      // Finished: nothing listens any more.
      await expectLater(
        _get(loopback.redirectUrl),
        throwsA(isA<SocketException>()),
      );
    },
  );

  test('a failed sign-in shows the reason, escaped', () async {
    final loopback = await LoopbackSignIn.start();
    final done = loopback.wait((_) async => 'Bad <script>');
    final (_, page) = await _get('${loopback.redirectUrl}?error=access_denied');
    await done;
    expect(page, contains('Sign-in did not finish'));
    expect(page, contains('Bad &lt;script&gt;'));
    expect(page, isNot(contains('<script>')));
  });

  test('a second sign-in closes the first listener', () async {
    final first = await LoopbackSignIn.start();
    final second = await LoopbackSignIn.start();
    await expectLater(_get(first.redirectUrl), throwsA(isA<SocketException>()));
    await second.close();
  });

  test('an abandoned sign-in stops listening after the timeout', () async {
    final loopback = await LoopbackSignIn.start();
    await loopback.wait(
      (_) async => null,
      timeout: const Duration(milliseconds: 50),
    );
    await expectLater(
      _get(loopback.redirectUrl),
      throwsA(isA<SocketException>()),
    );
  });
}
