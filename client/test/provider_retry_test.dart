import 'package:casama/core/provider_retry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _status(int code) {
  final options = RequestOptions(path: '/v1/x');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('a client error the server meant shows at once', () {
    for (final code in [400, 401, 403, 404, 409, 422]) {
      expect(appProviderRetry(0, _status(code)), isNull, reason: '$code');
    }
  });

  test('timeouts, rate limits, server errors and no answer still retry', () {
    for (final code in [408, 429, 500, 502, 503]) {
      expect(appProviderRetry(0, _status(code)), isNotNull, reason: '$code');
    }
    final offline = DioException(
      requestOptions: RequestOptions(path: '/v1/x'),
      type: DioExceptionType.connectionError,
    );
    expect(appProviderRetry(0, offline), isNotNull);
    expect(appProviderRetry(0, Exception('x')), isNotNull);
  });

  test('gives up after the default number of tries', () {
    expect(appProviderRetry(10, _status(500)), isNull);
  });
}
