import 'dart:convert';
import 'dart:typed_data';

import 'package:casama/core/apple_token_handoff.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements HttpClientAdapter {
  _Recorder(this.status);
  final int status;
  final requests = <RequestOptions>[];
  final bodies = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      bodies.add(utf8.decode(await requestStream.expand((c) => c).toList()));
    }
    return ResponseBody.fromString(
      status == 200 ? '{"stored":true}' : '{"code":"x"}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('body: the sheet sends its code, the browser its refresh token', () {
    expect(AppleTokenHandoff.body(authorizationCode: 'c1'), {
      'authorization_code': 'c1',
    });
    expect(AppleTokenHandoff.body(refreshToken: 'r1'), {'refresh_token': 'r1'});
    expect(
      AppleTokenHandoff.body(authorizationCode: ' ', refreshToken: null),
      isNull,
    );
    expect(AppleTokenHandoff.body(), isNull);
  });

  test('a browser sign-in counts once, and only while recent', () async {
    final t0 = DateTime(2026, 11, 19, 12);
    expect(await AppleTokenHandoff.takeBrowserSignIn(now: t0), isFalse);

    await AppleTokenHandoff.markBrowserSignInStarted(now: t0);
    expect(
      await AppleTokenHandoff.takeBrowserSignIn(
        now: t0.add(const Duration(minutes: 2)),
      ),
      isTrue,
    );
    expect(
      await AppleTokenHandoff.takeBrowserSignIn(
        now: t0.add(const Duration(minutes: 3)),
      ),
      isFalse,
    );

    await AppleTokenHandoff.markBrowserSignInStarted(now: t0);
    expect(
      await AppleTokenHandoff.takeBrowserSignIn(
        now: t0.add(const Duration(minutes: 16)),
      ),
      isFalse,
    );

    // Starting another provider's sign-in clears it.
    await AppleTokenHandoff.markBrowserSignInStarted(now: t0);
    await AppleTokenHandoff.clearBrowserSignIn();
    expect(await AppleTokenHandoff.takeBrowserSignIn(now: t0), isFalse);
  });

  test('send posts to the server with the session', () async {
    final rec = _Recorder(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = rec;
    await AppleTokenHandoff.send(dio, {
      'Authorization': 'Bearer t',
    }, authorizationCode: 'code-1');
    expect(rec.requests.single.path, '/v1/me/apple-sign-in');
    expect(rec.requests.single.method, 'POST');
    expect(rec.requests.single.headers['Authorization'], 'Bearer t');
    expect(jsonDecode(rec.bodies.single), {'authorization_code': 'code-1'});
  });

  test(
    'send never throws: errors, old servers and missing sessions are ignored',
    () async {
      final rec = _Recorder(404);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = rec;
      await AppleTokenHandoff.send(dio, {
        'Authorization': 'Bearer t',
      }, refreshToken: 'r');
      expect(rec.requests, hasLength(1));
      // Signed out, or nothing to send: no request at all.
      await AppleTokenHandoff.send(dio, const {}, refreshToken: 'r');
      await AppleTokenHandoff.send(dio, {'Authorization': 'Bearer t'});
      expect(rec.requests, hasLength(1));
    },
  );
}
