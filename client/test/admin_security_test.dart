import 'dart:convert';
import 'dart:typed_data';

import 'package:casama/core/admin_security.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Server implements HttpClientAdapter {
  int requests = 0;
  int status = 200;
  bool alwaysReject = false;
  String code = '';
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    authorization = options.headers['Authorization'] as String?;
    final answer = (requests == 1 || alwaysReject) ? status : 200;
    return ResponseBody.fromString(
      jsonEncode({'code': code}),
      answer,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _Server server;
  late int confirmations;
  late String identity;
  late String token;

  setUp(() {
    server = _Server();
    confirmations = 0;
    identity = 'owner';
    token = 'initial';
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = server;
    dio.interceptors.add(
      AdminSecurityInterceptor(dio, token: () => token, userId: () => identity),
    );
    AdminSecurity.isUnlocked = () => true;
    AdminSecurity.authenticate = (_) async {
      confirmations++;
      token = 'verified';
      return true;
    };
  });

  tearDown(() {
    AdminSecurity.authenticate = null;
    AdminSecurity.isUnlocked = null;
    AdminSecurity.lock = null;
    AdminSecurity.confirmAnywhere = null;
    AdminSecurity.forgetVerification();
    dio.close();
  });

  test(
    'locked console cancels even a read before it reaches the server',
    () async {
      AdminSecurity.isUnlocked = () => false;
      await expectLater(
        dio.get<dynamic>('/v1/admin/users'),
        throwsA(isA<DioException>()),
      );
      expect(server.requests, 0);
    },
  );

  test('owner discovery is available without an unlocked console', () async {
    AdminSecurity.isUnlocked = null;
    await dio.get<dynamic>('/v1/admin/overview');
    expect(server.requests, 1);
    expect(confirmations, 0);
  });

  test('every mutation requires confirmation and uses the new token', () async {
    await dio.patch<dynamic>('/v1/admin/test', data: {'enabled': true});
    expect(confirmations, 1);
    expect(server.authorization, 'Bearer verified');
  });

  test('a cancelled confirmation cannot send the mutation', () async {
    AdminSecurity.authenticate = (_) async => false;
    await expectLater(
      dio.post<dynamic>('/v1/admin/test'),
      throwsA(isA<DioException>()),
    );
    expect(server.requests, 0);
  });

  test(
    'an identity change during confirmation cannot send the mutation',
    () async {
      AdminSecurity.authenticate = (_) async {
        identity = 'someone-else';
        return true;
      };
      await expectLater(
        dio.delete<dynamic>('/v1/admin/test'),
        throwsA(isA<DioException>()),
      );
      expect(server.requests, 0);
    },
  );

  test('only an explicit freshness rejection can be retried', () async {
    server.status = 403;
    server.code = 'admin_reauthentication_required';
    await dio.get<dynamic>('/v1/admin/users');
    expect(server.requests, 2);
    expect(confirmations, 1);
    expect(server.authorization, 'Bearer verified');
  });

  test(
    'a failed mutation is never replayed for generic server failures',
    () async {
      server.status = 500;
      await expectLater(
        dio.post<dynamic>('/v1/admin/test'),
        throwsA(isA<DioException>()),
      );
      expect(server.requests, 1);
      expect(confirmations, 1);
    },
  );

  test('locking during confirmation prevents a pending mutation', () async {
    var unlocked = true;
    AdminSecurity.isUnlocked = () => unlocked;
    AdminSecurity.authenticate = (_) async {
      unlocked = false;
      return true;
    };
    await expectLater(
      dio.post<dynamic>('/v1/admin/test'),
      throwsA(isA<DioException>()),
    );
    expect(server.requests, 0);
  });

  test('a second freshness rejection is never retried again', () async {
    server.status = 403;
    server.code = 'admin_reauthentication_required';
    server.alwaysReject = true;
    await expectLater(
      dio.get<dynamic>('/v1/admin/users'),
      throwsA(isA<DioException>()),
    );
    expect(server.requests, 2);
    expect(confirmations, 1);
  });

  test('Casama Link works with the console locked; a change is confirmed over any screen (D-463)', () async {
    AdminSecurity.isUnlocked = () => false;
    var anywhere = 0;
    AdminSecurity.confirmAnywhere = () async {
      anywhere++;
      return true;
    };
    await dio.get<dynamic>('/v1/admin/remote-access');
    await dio.post<dynamic>('/v1/admin/remote-access/check');
    expect(server.requests, 2, reason: 'the reads reach the server');
    // The server asks for a fresh sign-in to change it: the dialog over the current screen.
    server
      ..requests = 0
      ..status = 403
      ..code = 'admin_confirmation_required';
    await dio.put<dynamic>('/v1/admin/remote-access/settings', data: {'enabled': true});
    expect(anywhere, 1);
    expect(confirmations, 0, reason: 'not the console lock form');
    expect(server.requests, 2, reason: 'retried once after the yes');
  });

  test('ordinary requests are not affected by the console lock', () async {
    AdminSecurity.isUnlocked = null;
    await dio.post<dynamic>('/v1/conversations/test');
    expect(confirmations, 0);
    expect(server.requests, 1);
  });

  test('a change right after a fresh sign-in is not asked again', () async {
    AdminSecurity.verified('owner');
    await dio.patch<dynamic>('/v1/admin/test', data: {'enabled': true});
    expect(confirmations, 0);
    expect(server.requests, 1);
    // Someone else's recent sign-in doesn't count.
    AdminSecurity.verified('someone-else');
    await dio.patch<dynamic>('/v1/admin/test', data: {'enabled': true});
    expect(confirmations, 1);
  });

  test(
    'owner actions outside the console confirm once the server asks',
    () async {
      var asked = 0;
      AdminSecurity.isUnlocked = null;
      AdminSecurity.authenticate = null;
      AdminSecurity.confirmAnywhere = () async {
        asked++;
        token = 'verified';
        return true;
      };
      server.status = 403;
      server.code = 'admin_confirmation_required';
      await dio.post<dynamic>('/v1/approvals/a/decision');
      expect(asked, 1);
      expect(server.requests, 2);
      expect(server.authorization, 'Bearer verified');
    },
  );

  test('other refusals outside the console are never retried', () async {
    var asked = 0;
    AdminSecurity.confirmAnywhere = () async {
      asked++;
      return true;
    };
    server.status = 403;
    server.code = 'forbidden';
    await expectLater(
      dio.post<dynamic>('/v1/approvals/a/decision'),
      throwsA(isA<DioException>()),
    );
    expect(asked, 0);
    expect(server.requests, 1);
  });

  test(
    'a declined confirmation outside the console sends nothing more',
    () async {
      AdminSecurity.confirmAnywhere = () async => false;
      server.status = 403;
      server.code = 'admin_confirmation_required';
      await expectLater(
        dio.post<dynamic>('/v1/sign-in-codes'),
        throwsA(isA<DioException>()),
      );
      expect(server.requests, 1);
    },
  );
}
