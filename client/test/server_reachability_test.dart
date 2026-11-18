import 'package:casama/core/server_reachability.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException failure(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/v1/bots');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

/// Answers every request with [status], or fails to connect when it is null.
class _Adapter implements HttpClientAdapter {
  int? status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final s = status;
    if (s == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{}',
      s,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const home = 'https://abc123.oliverbytes.dev';
  const cloud = 'https://api.casama.ai';

  test('no answer at all means the server is unreachable', () {
    expect(
      reachabilityOf(failure(DioExceptionType.connectionError), home),
      Reachability.unreachable,
    );
    expect(
      reachabilityOf(failure(DioExceptionType.connectionTimeout), home),
      Reachability.unreachable,
    );
    expect(
      reachabilityOf(failure(DioExceptionType.unknown), home),
      Reachability.unreachable,
    );
  });

  test("a tunnel with nothing behind it means the person's server is offline, not on Casama Cloud", () {
    for (final status in [530, 502, 503, 504]) {
      expect(
        reachabilityOf(
          failure(DioExceptionType.badResponse, status: status),
          home,
        ),
        Reachability.serverOffline,
      );
      expect(
        reachabilityOf(
          failure(DioExceptionType.badResponse, status: status),
          cloud,
        ),
        Reachability.unreachable,
      );
    }
  });

  test(
    'any answer from the server itself, errors included, means it is there',
    () {
      for (final status in [400, 401, 404, 500]) {
        expect(
          reachabilityOf(
            failure(DioExceptionType.badResponse, status: status),
            home,
          ),
          Reachability.ok,
        );
      }
      // A slow answer or a cancelled request says nothing either way.
      expect(
        reachabilityOf(failure(DioExceptionType.receiveTimeout), home),
        isNull,
      );
      expect(reachabilityOf(failure(DioExceptionType.cancel), home), isNull);
    },
  );

  test(
    'every request reports, and the first answer after a failure clears it',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: home))..httpClientAdapter = adapter;
      watchReachability(dio, home);
      serverReachability.value = Reachability.ok;

      adapter.status = null;
      await expectLater(
        dio.get<Object?>('/v1/bots'),
        throwsA(isA<DioException>()),
      );
      expect(serverReachability.value, Reachability.unreachable);

      adapter.status = 530;
      await expectLater(
        dio.get<Object?>('/v1/bots'),
        throwsA(isA<DioException>()),
      );
      expect(serverReachability.value, Reachability.serverOffline);

      adapter.status = 404;
      await expectLater(
        dio.get<Object?>('/v1/bots'),
        throwsA(isA<DioException>()),
      );
      expect(serverReachability.value, Reachability.ok);

      adapter.status = null;
      await expectLater(
        dio.get<Object?>('/v1/bots'),
        throwsA(isA<DioException>()),
      );
      adapter.status = 200;
      await dio.get<Object?>('/v1/bots');
      expect(serverReachability.value, Reachability.ok);
    },
  );
}
