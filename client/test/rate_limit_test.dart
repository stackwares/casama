import 'package:casama/core/rate_limit.dart';
import 'package:casama/core/widgets.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

DioException _limited(int seconds, {RequestOptions? options}) {
  final o = options ?? RequestOptions(path: '/v1/glance', method: 'GET');
  return DioException(
    requestOptions: o,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: o,
      statusCode: 429,
      headers: Headers.fromMap({
        'retry-after': ['$seconds'],
      }),
    ),
  );
}

/// Answers 429 (retry-after [wait]) the first [failures] times, then 200.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.failures, this.wait);
  int failures;
  final int wait;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (failures > 0) {
      failures--;
      return ResponseBody.fromString(
        '{"code":"rate_limited"}',
        429,
        headers: {
          'retry-after': ['$wait'],
          'content-type': ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  dio.interceptors.add(RateLimitRetryInterceptor(dio));
  return dio;
}

void main() {
  test('reads the wait from a 429 only', () {
    expect(retryAfterOf(_limited(12)), const Duration(seconds: 12));
    final o = RequestOptions(path: '/v1/glance');
    expect(
      retryAfterOf(
        DioException(
          requestOptions: o,
          response: Response(requestOptions: o, statusCode: 500),
        ),
      ),
      isNull,
    );
    expect(retryAfterOf(StateError('x')), isNull);
  });

  test('a short wait is waited out and the call sent once more', () async {
    final adapter = _Adapter(1, 0);
    final res = await _dio(adapter)
        .post<dynamic>('https://x.test/v1/approvals/a/decision');
    expect(res.statusCode, 200);
    expect(adapter.calls, 2);
  });

  test('only one retry, and long waits reach the caller', () async {
    final twice = _Adapter(5, 0);
    await expectLater(
      _dio(twice).get<dynamic>('https://x.test/v1/glance'),
      throwsA(isA<DioException>()),
    );
    expect(twice.calls, 2);

    final long = _Adapter(1, 30);
    await expectLater(
      _dio(long).get<dynamic>('https://x.test/v1/glance'),
      throwsA(
        isA<DioException>().having(
          retryAfterOf,
          'wait',
          const Duration(seconds: 30),
        ),
      ),
    );
    expect(long.calls, 1);
  });

  testWidgets('the error says when to try again and counts down', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showError(c, _limited(3)),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.text('go'));
    expect(
      errorText(ctx, _limited(12)),
      'Too many requests at once. Try again in 12 seconds.',
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Too many requests at once. Try again in 3 seconds.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Too many requests at once. Try again in 2 seconds.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('You can try again now.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });
}
