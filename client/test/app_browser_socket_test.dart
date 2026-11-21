import 'dart:async';

import 'package:casama/features/app_browser/app_browser_socket.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_browser_fakes.dart';

/// The phone browser's device socket (PROTOCOL.md §1): hello, ready, request → response, chunk,
/// end, cancel, health, and closing.
void main() {
  late FakeTransport transport;
  late AppBrowserSocket socket;
  final calls = <AppBrowserCall>[];
  Completer<Map<String, Object?>>? hold;

  setUp(() {
    calls.clear();
    hold = null;
    transport = FakeTransport();
    socket = AppBrowserSocket(
      transport: transport,
      apiUrl: 'https://api.example',
      token: 'kdev_phone',
      os: 'iOS 26.1',
      version: '1.2.3',
      helloEvery: const Duration(milliseconds: 50),
      firstBackoff: const Duration(milliseconds: 10),
      maxBackoff: const Duration(milliseconds: 20),
      onCall: (call) async {
        calls.add(call);
        if (hold != null) return hold!.future;
        return {'ok': true, 'text': 'did ${call.action}'};
      },
    );
  });

  tearDown(() => socket.stop());

  Future<FakeConnection> connected() async {
    socket.start();
    for (var i = 0; i < 50 && socket.link.value != AppBrowserLink.online; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    return transport.connections.last;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  test(
    'connects with the device token and says hello, then every so often',
    () async {
      final c = await connected();
      expect(
        transport.urls.single.toString(),
        'wss://api.example/v1/local-computer/connect',
      );
      expect(transport.headers.single, {
        'authorization': 'Device kdev_phone',
        'x-casama-os': 'iOS 26.1',
      });
      expect(c.sent.first, {
        'type': 'hello',
        'platform': 'app',
        'version': '1.2.3',
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.sent.where((m) => m['type'] == 'hello').length, greaterThan(1));
      c.push({'type': 'ready', 'device_id': 'phone1', 'computer_id': null});
      await settle();
      expect(socket.deviceId, 'phone1');
    },
  );

  test('a request is answered with a response, one chunk and an end', () async {
    final c = await connected();
    c.request('r1', 'snapshot', {
      'action': 'snapshot',
      'args': {'interactive_only': true},
      'run': {
        'id': 'run1',
        'bot_id': 'b1',
        'bot_name': 'Ada',
        'conversation_id': 'conv1',
      },
      'policy': {
        'blocked_sites': ['ads.example'],
        'allowed_sites': ['shop.example'],
        'allowed_kinds': <String>[],
        'own_urls': ['https://api.example'],
      },
      'expect': 'fp1',
    });
    await settle();
    final call = calls.single;
    expect(call.action, 'snapshot');
    expect(call.args, {'interactive_only': true});
    expect(call.run.botName, 'Ada');
    expect(call.run.conversationId, 'conv1');
    expect(call.policy.blockedSites, ['ads.example']);
    expect(call.policy.ownUrls, ['https://api.example']);
    expect(call.expect, 'fp1');
    final frames = c.framesFor('r1');
    expect([for (final f in frames) f['type']], ['response', 'chunk', 'end']);
    expect(frames.first['status'], 200);
    expect(c.resultFor('r1'), {'ok': true, 'text': 'did snapshot'});
  });

  test('health answers ok; anything else is not found', () async {
    final c = await connected();
    c.push({'type': 'request', 'id': 'h', 'method': 'GET', 'path': '/health'});
    c.push({
      'type': 'request',
      'id': 'x',
      'method': 'GET',
      'path': '/files/list',
    });
    await settle();
    expect(c.resultFor('h'), {'ok': true});
    expect(c.framesFor('x').first['status'], 404);
    expect(c.resultFor('x'), {'ok': false, 'code': 'not_found'});
    expect(calls, isEmpty);
  });

  test('a cancel stops the call and sends nothing back', () async {
    final c = await connected();
    hold = Completer();
    c.request('r2', 'ask', {
      'action': 'ask',
      'run': {
        'id': 'run1',
        'bot_id': 'b1',
        'bot_name': 'Ada',
        'conversation_id': 'conv1',
      },
    });
    await settle();
    final call = calls.single;
    c.push({'type': 'cancel', 'id': 'r2'});
    await settle();
    expect(call.isCancelled, isTrue);
    hold!.complete({'ok': true, 'text': 'allow'});
    await settle();
    expect(c.framesFor('r2'), isEmpty);
  });

  test('a closed socket aborts what was in flight and dials again', () async {
    final c = await connected();
    hold = Completer();
    c.request('r3', 'wait', {
      'action': 'wait',
      'run': {
        'id': 'run1',
        'bot_id': 'b1',
        'bot_name': 'Ada',
        'conversation_id': 'conv1',
      },
    });
    await settle();
    final call = calls.single;
    await c.close();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(call.isCancelled, isTrue);
    expect(transport.connections.length, greaterThan(1));
    expect(socket.link.value, AppBrowserLink.online);
  });

  test('stop closes the socket and says off', () async {
    final c = await connected();
    await socket.stop();
    expect(c.closed, isTrue);
    expect(socket.link.value, AppBrowserLink.off);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(transport.connections.length, 1);
  });
}
