import 'dart:async';

import 'package:casama_app/core/timeout_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('passes a quick answer through', () async {
    final c = TimeoutHttpClient(inner: MockClient((_) async => http.Response('ok', 200)));
    final res = await c.get(Uri.parse('https://example.test/'));
    expect(res.body, 'ok');
  });

  test('gives up on a server that never answers', () async {
    final never = Completer<http.Response>();
    final c = TimeoutHttpClient(inner: MockClient((_) => never.future), headers: const Duration(milliseconds: 20));
    await expectLater(c.get(Uri.parse('https://example.test/')), throwsA(isA<TimeoutException>()));
  });

  test('gives up on a body that stops arriving', () async {
    final body = StreamController<List<int>>();
    final c = TimeoutHttpClient(
      inner: MockClient.streaming((req, _) async {
        body.add([104, 105]);
        return http.StreamedResponse(body.stream, 200);
      }),
      idle: const Duration(milliseconds: 20),
    );
    await expectLater(c.get(Uri.parse('https://example.test/')), throwsA(isA<TimeoutException>()));
  });
}
