import 'dart:convert';
import 'dart:typed_data';

import 'package:casama/core/session_refresh.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers 401 to any token but [valid], and records the tokens it saw.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.valid);
  String valid;
  final seen = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    seen.add(auth);
    final ok = auth == 'Bearer $valid';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'ok': true} : {'code': 'unauthorized'}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Network implements Exception {}

void main() {
  late Dio dio;
  late _Adapter adapter;
  var refreshes = 0;
  var signOuts = 0;
  Future<String?> Function() refresh = () async => 'new';

  setUp(() {
    refreshes = 0;
    signOuts = 0;
    adapter = _Adapter('new');
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      SessionRefreshInterceptor(
        dio,
        refresh: () {
          refreshes++;
          return refresh();
        },
        signOut: () async => signOuts++,
        isNetworkError: (e) => e is _Network,
      ),
    );
  });

  Options bearer(String t) => Options(headers: {'Authorization': 'Bearer $t'});

  test(
    'a 401 refreshes once and sends the call again with the new token',
    () async {
      refresh = () async => 'new';
      final r = await dio.get<dynamic>('/v1/me', options: bearer('old'));
      expect(r.statusCode, 200);
      expect(adapter.seen, ['Bearer old', 'Bearer new']);
      expect(refreshes, 1);
      expect(signOuts, 0);
    },
  );

  test('concurrent 401s share one refresh', () async {
    refresh = () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return 'new';
    };
    await Future.wait([
      dio.get<dynamic>('/a', options: bearer('old')),
      dio.get<dynamic>('/b', options: bearer('old')),
    ]);
    expect(refreshes, 1);
  });

  test(
    'still 401 after the retry: the error reaches the caller, no loop',
    () async {
      adapter.valid = 'never';
      refresh = () async => 'new';
      await expectLater(
        dio.get<dynamic>('/v1/me', options: bearer('old')),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(adapter.seen, hasLength(2));
      expect(refreshes, 1);
    },
  );

  test(
    'a refused refresh signs out; an offline one keeps the session',
    () async {
      refresh = () async => throw StateError('refresh_token_not_found');
      await expectLater(
        dio.get<dynamic>('/v1/me', options: bearer('old')),
        throwsA(isA<DioException>()),
      );
      expect(signOuts, 1);

      refresh = () async => throw _Network();
      await expectLater(
        dio.get<dynamic>('/v1/me', options: bearer('old')),
        throwsA(isA<DioException>()),
      );
      expect(signOuts, 1);
    },
  );

  test('a call that sent no token is not refreshed', () async {
    await expectLater(
      dio.get<dynamic>('/v1/config'),
      throwsA(isA<DioException>()),
    );
    expect(refreshes, 0);
  });
}
