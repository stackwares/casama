import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'app_browser_sites.dart';
import 'app_browser_ws_stub.dart'
    if (dart.library.io) 'app_browser_ws_io.dart'
    as ws;

/// One WebSocket to the API (PROTOCOL.md §1), the framing `companion_io.dart` speaks.
abstract interface class AppBrowserTransport {
  Future<AppBrowserConnection> connect(Uri url, Map<String, String> headers);
}

abstract interface class AppBrowserConnection {
  /// Text frames from the server; the stream ends when the socket closes.
  Stream<String> get messages;
  void send(String message);
  Future<void> close();
}

/// The transport on this platform (dart:io on phones; none on the web).
AppBrowserTransport defaultAppBrowserTransport() =>
    ws.createAppBrowserTransport();

/// The run a call belongs to.
class AppBrowserRun {
  const AppBrowserRun({
    required this.id,
    required this.botId,
    required this.botName,
    required this.conversationId,
  });

  factory AppBrowserRun.fromJson(Map<String, dynamic>? j) => AppBrowserRun(
    id: '${j?['id'] ?? ''}',
    botId: '${j?['bot_id'] ?? ''}',
    botName: '${j?['bot_name'] ?? ''}',
    conversationId: j?['conversation_id'] as String?,
  );

  final String id;
  final String botId;
  final String botName;
  final String? conversationId;
}

/// One `POST /browser/<action>` from the server (`BrowserCall` plus what the server adds).
class AppBrowserCall {
  AppBrowserCall({
    required this.action,
    this.args = const {},
    required this.run,
    this.policy = const AppSitePolicy(),
    this.expect,
  });

  factory AppBrowserCall.fromBody(String action, Map<String, dynamic> body) =>
      AppBrowserCall(
        action: (body['action'] as String?) ?? action,
        args: (body['args'] as Map?)?.cast<String, dynamic>() ?? const {},
        run: AppBrowserRun.fromJson(
          (body['run'] as Map?)?.cast<String, dynamic>(),
        ),
        policy: AppSitePolicy.fromJson(
          (body['policy'] as Map?)?.cast<String, dynamic>(),
        ),
        expect: body['expect'] as String?,
      );

  final String action;
  final Map<String, dynamic> args;
  final AppBrowserRun run;
  final AppSitePolicy policy;

  /// The element's fingerprint the server decided on; the page refuses when it changed.
  final String? expect;

  final _cancelled = Completer<void>();

  /// Completes when the server cancels the call or the socket closes.
  Future<void> get cancelled => _cancelled.future;
  bool get isCancelled => _cancelled.isCompleted;
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

/// Answers one call with a `BrowserResult` map.
typedef AppBrowserCallHandler = Future<Map<String, Object?>> Function(
  AppBrowserCall call,
);

enum AppBrowserLink { off, connecting, online }

/// The phone browser's device socket. The owner starts it only while the feature is on for this
/// phone, a device is paired and the app is in front, and stops it when any of that ends.
class AppBrowserSocket {
  AppBrowserSocket({
    required this.transport,
    required this.apiUrl,
    required this.token,
    required this.onCall,
    this.os,
    this.version = '',
    this.helloEvery = const Duration(seconds: 20),
    this.firstBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 5),
  });

  final AppBrowserTransport transport;
  final String apiUrl;
  final String token;
  final AppBrowserCallHandler onCall;

  /// "iOS 26.1" or "Android 16", sent as `x-casama-os`.
  final String? os;
  final String version;
  final Duration helloEvery;
  final Duration firstBackoff;
  final Duration maxBackoff;

  final link = ValueNotifier(AppBrowserLink.off);

  /// From the server's `ready`.
  String? deviceId;

  var _running = false;
  var _generation = 0;
  AppBrowserConnection? _conn;
  Timer? _hello;
  final _inflight = <String, AppBrowserCall>{};

  Uri get url => Uri.parse(
    '${apiUrl.replaceFirst(RegExp('^http'), 'ws')}/v1/local-computer/connect',
  );

  void start() {
    if (_running) return;
    _running = true;
    final generation = ++_generation;
    link.value = AppBrowserLink.connecting;
    unawaited(_loop(generation));
  }

  Future<void> stop() async {
    _running = false;
    _generation++;
    _hello?.cancel();
    _hello = null;
    _abortAll();
    final c = _conn;
    _conn = null;
    await c?.close().catchError((_) {});
    link.value = AppBrowserLink.off;
  }

  Future<void> _loop(int generation) async {
    bool current() => _running && generation == _generation;
    var backoff = firstBackoff;
    while (current()) {
      AppBrowserConnection? conn;
      try {
        conn = await transport.connect(url, {
          'authorization': 'Device $token',
          'x-casama-os': ?os,
        });
        if (!current()) {
          await conn.close();
          break;
        }
        _conn = conn;
        backoff = firstBackoff;
        link.value = AppBrowserLink.online;
        _sendHello(conn);
        _hello?.cancel();
        _hello = Timer.periodic(helloEvery, (_) => _sendHello(conn!));
        await for (final raw in conn.messages) {
          if (!current()) break;
          _onMessage(conn, raw);
        }
      } catch (e) {
        debugPrint('phone browser socket: $e');
      }
      _hello?.cancel();
      _hello = null;
      // Whatever was in flight on that socket can't be answered any more.
      _abortAll();
      if (identical(_conn, conn)) _conn = null;
      if (!current()) break;
      link.value = AppBrowserLink.connecting;
      await Future<void>.delayed(backoff);
      backoff = Duration(
        milliseconds: min(
          backoff.inMilliseconds * 2,
          maxBackoff.inMilliseconds,
        ),
      );
    }
  }

  void _abortAll() {
    for (final c in _inflight.values) {
      c.cancel();
    }
    _inflight.clear();
  }

  void _sendHello(AppBrowserConnection conn) => conn.send(
    jsonEncode({'type': 'hello', 'platform': 'app', 'version': version}),
  );

  void _onMessage(AppBrowserConnection conn, String raw) {
    Map<String, dynamic> m;
    try {
      m = (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return;
    }
    final id = m['id'] as String?;
    switch (m['type']) {
      case 'ready':
        deviceId = m['device_id'] as String?;
      case 'cancel' when id != null:
        _inflight.remove(id)?.cancel();
      case 'request' when id != null:
        unawaited(_onRequest(conn, id, m));
    }
  }

  Future<void> _onRequest(
    AppBrowserConnection conn,
    String id,
    Map<String, dynamic> m,
  ) async {
    final method = '${m['method'] ?? 'GET'}'.toUpperCase();
    final path = '${m['path'] ?? ''}'.split('?').first;
    if (method == 'GET' && path == '/health') {
      return _reply(conn, id, 200, {'ok': true});
    }
    if (method != 'POST' || !path.startsWith('/browser/')) {
      return _reply(conn, id, 404, {'ok': false, 'code': 'not_found'});
    }
    Map<String, dynamic> body;
    try {
      final b = m['body'] as String?;
      body = b == null || b.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(utf8.decode(base64Decode(b))) as Map)
                .cast<String, dynamic>();
    } catch (_) {
      return _reply(conn, id, 200, {
        'ok': false,
        'code': 'error',
        'message': "The phone couldn't read that step",
      });
    }
    final call = AppBrowserCall.fromBody(
      path.substring('/browser/'.length),
      body,
    );
    _inflight[id] = call;
    Map<String, Object?> result;
    try {
      result = await onCall(call);
    } catch (e) {
      result = {'ok': false, 'code': 'error', 'message': '$e'};
    }
    final stillOurs = identical(_inflight.remove(id), call);
    // A cancelled call, or one whose socket closed, gets no answer.
    if (!stillOurs || call.isCancelled || !identical(_conn, conn)) return;
    _reply(conn, id, 200, result);
  }

  void _reply(
    AppBrowserConnection conn,
    String id,
    int status,
    Map<String, Object?> json,
  ) {
    conn.send(
      jsonEncode({
        'type': 'response',
        'id': id,
        'status': status,
        'headers': const {'content-type': 'application/json'},
      }),
    );
    conn.send(
      jsonEncode({
        'type': 'chunk',
        'id': id,
        'data': base64Encode(utf8.encode(jsonEncode(json))),
      }),
    );
    conn.send(jsonEncode({'type': 'end', 'id': id}));
  }
}
