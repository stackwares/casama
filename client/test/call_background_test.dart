// Calls in the background (D-327 Phase 3): the phone's call controls (CallKit, Android's call
// notification) follow the call and drive it; interruptions put it on hold and back; unplugged
// headphones switch to the speaker; the web tab's title.
import 'dart:async';

import 'package:casama/core/call_audio.dart';
import 'package:casama/features/voice/active_call.dart';
import 'package:casama/features/voice/call_bubble.dart';
import 'package:casama/features/voice/call_system.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'active_call_test.dart' show CallsConnector;
import 'fake_backend.dart';
import 'fake_voice.dart' show FakeCallConnector;

class FakeCallSystem implements CallSystem {
  final log = <String>[];
  CallSystemCall? started;
  final _actions = StreamController<CallSystemAction>.broadcast();
  void press(CallSystemAction a) => _actions.add(a);

  @override
  Stream<CallSystemAction> get actions => _actions.stream;
  @override
  Future<void> start(CallSystemCall call) async {
    started = call;
    log.add('start');
  }

  @override
  Future<void> connected() async => log.add('connected');
  @override
  Future<void> update({
    required bool muted,
    required bool reconnecting,
  }) async => log.add('update muted=$muted reconnecting=$reconnecting');
  @override
  Future<void> end() async => log.add('end');
}

class FakeInterruptions implements CallInterruptions {
  final taken = StreamController<bool>.broadcast();
  final noisy = StreamController<void>.broadcast();
  final log = <String>[];
  @override
  Future<void> begin() async => log.add('begin');
  @override
  Stream<bool> get interrupted => taken.stream;
  @override
  Stream<void> get unplugged => noisy.stream;
  @override
  Future<void> reclaim() async => log.add('reclaim');
  @override
  Future<void> finish() async => log.add('finish');
}

class FakeRoutes implements CallAudioRoutes {
  CallRoute? selected;
  @override
  Future<List<CallRoute>> available() async => const [
    CallRoute(CallRouteKind.speaker),
    CallRoute(CallRouteKind.earpiece),
    CallRoute(CallRouteKind.headphones),
  ];
  @override
  Future<CallRoute?> current() async =>
      const CallRoute(CallRouteKind.headphones);
  @override
  Future<void> select(CallRoute route) async => selected = route;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(CallController, CallsConnector, FakeCallSystem, FakeInterruptions)>
  connected({String? phoneCallId}) async {
    final calls = CallsConnector();
    final system = FakeCallSystem();
    final interruptions = FakeInterruptions();
    final c = CallController(
      backend: FakeBackend(),
      connector: calls,
      botId: botId,
      requestedConversationId: convId,
      phoneCallId: phoneCallId,
      system: system,
      interruptions: interruptions,
      botName: 'Ava',
    );
    await c.connect();
    return (c, calls, system, interruptions);
  }

  test('the phone hears of the call before it connects, then follows it; its buttons mute and end it', () async {
    final (c, calls, system, interruptions) = await connected();
    expect(system.started?.id, 'live-1');
    expect(system.started?.botName, 'Ava');
    expect(system.started?.phoneCallId, isNull);
    // Reported first, then connected (the fake call is live as soon as it connects).
    expect(system.log.take(2), ['start', 'connected']);
    expect(interruptions.log, ['begin']);

    // Mute from the lock screen, then from the app: both ways agree.
    system.press(CallSystemAction.mute);
    await Future<void>.delayed(Duration.zero);
    expect(c.muted, isTrue);
    expect(calls.last.muted, isTrue);
    c.setMuted(false);
    expect(system.log.last, 'update muted=false reconnecting=false');

    // Reconnecting shows on the notification.
    calls.last.reconnectingNow.value = true;
    expect(system.log.last, 'update muted=false reconnecting=true');
    calls.last.reconnectingNow.value = false;

    // End Call on the notification ends the call (saved as usual) and the system's call.
    system.press(CallSystemAction.end);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.over, isTrue);
    expect(c.endedBy, CallEnd.hungUp);
    expect(calls.last.hungUp, isTrue);
    expect(system.log.where((l) => l == 'end'), hasLength(1));
    expect(interruptions.log.last, 'finish');
    c.dispose();
    expect(system.log.where((l) => l == 'end'), hasLength(1));
  });

  test('a denied microphone starts no session on the server and no phone call', () async {
    final backend = FakeBackend();
    final system = FakeCallSystem();
    final c = CallController(
      backend: backend,
      connector: FakeCallConnector()..mic = false,
      botId: botId,
      requestedConversationId: convId,
      system: system,
    );
    await c.connect();
    expect(backend.voiceSessions, 0);
    expect(c.error, isA<StateError>());
    expect(c.liveCallId, isNull);
  });

  test('an answered ring tells the phone which call it is', () async {
    final (c, _, system, _) = await connected(
      phoneCallId: '77777777-7777-4777-8777-777777777777',
    );
    expect(system.started?.phoneCallId, '77777777-7777-4777-8777-777777777777');
    await c.end(CallEnd.hungUp);
    c.dispose();
  });

  test('another call takes the audio: on hold, the bot waits, the idle check waits; back: audio and route restored', () async {
    final (c, calls, system, interruptions) = await connected();
    final call = calls.last;
    final routes = FakeRoutes();
    call.routes = routes;
    await c.selectRoute(const CallRoute(CallRouteKind.headphones));

    interruptions.taken.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(c.held, isTrue);
    expect(call.held, isTrue);
    expect(call.notes.last, contains("can't hear you"));

    interruptions.taken.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.held, isFalse);
    expect(call.held, isFalse);
    expect(interruptions.log, contains('reclaim'));
    expect(routes.selected?.kind, CallRouteKind.headphones);
    expect(call.notes.last, contains('back on the call'));

    // CallKit's hold does the same.
    system.press(CallSystemAction.hold);
    await Future<void>.delayed(Duration.zero);
    expect(c.held, isTrue);
    system.press(CallSystemAction.resume);
    await Future<void>.delayed(Duration.zero);
    expect(c.held, isFalse);

    // Headphones out: the speaker, and the call goes on.
    interruptions.noisy.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(routes.selected?.kind, CallRouteKind.speaker);
    expect(c.route?.kind, CallRouteKind.speaker);
    expect(c.over, isFalse);

    await c.end(CallEnd.hungUp);
    c.dispose();
  });

  testWidgets('a call on hold stays up past the idle limit', (tester) async {
    final calls = CallsConnector();
    final interruptions = FakeInterruptions();
    final c = CallController(
      backend: FakeBackend(),
      connector: calls,
      botId: botId,
      requestedConversationId: convId,
      interruptions: interruptions,
      idleLimit: const Duration(seconds: 10),
    );
    await c.connect();
    interruptions.taken.add(true);
    await tester.pump(const Duration(seconds: 30));
    expect(c.over, isFalse);
    interruptions.taken.add(false);
    await tester.pump(const Duration(seconds: 12));
    expect(c.over, isTrue);
    expect(c.endedBy, CallEnd.idle);
    c.dispose();
  });

  test('Android: the call service gets the words, sends its buttons back, and starts again once live if it could not at first', () async {
    const channel = MethodChannel('casama/call_service');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    var refuse = true;
    messenger.setMockMethodCallHandler(channel, (m) async {
      calls.add(m);
      // The first start fails: no mic permission yet.
      if (m.method == 'start' && refuse) {
        refuse = false;
        throw PlatformException(code: 'failed');
      }
      return null;
    });
    final s = AndroidCallService();
    final got = <CallSystemAction>[];
    s.actions.listen(got.add);
    await s.start(const CallSystemCall(id: 'live-1', botName: 'Ava'));
    final start = calls.single.arguments as Map;
    expect(start['bot'], 'Ava');
    expect(start['end'], 'End Call');
    expect(start['live'], 'On a call');

    await s.update(muted: true, reconnecting: false);
    expect(calls, hasLength(1)); // Not running: nothing to update.
    await s.connected();
    expect(calls.map((c) => c.method), ['start', 'start', 'connected']);
    await s.update(muted: true, reconnecting: false);
    expect(calls.last.arguments, {'muted': true, 'reconnecting': false});

    // The notification's buttons.
    for (final a in ['mute', 'end', 'open']) {
      await messenger.handlePlatformMessage(
        'casama/call_service',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('action', {'action': a}),
        ),
        (_) {},
      );
    }
    await Future<void>.delayed(Duration.zero);
    expect(got, [
      CallSystemAction.mute,
      CallSystemAction.end,
      CallSystemAction.open,
    ]);

    await s.end();
    await s.end();
    expect(calls.where((c) => c.method == 'stop'), hasLength(1));
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets("the web tab's title counts the call", (tester) async {
    final titles = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (m) async {
        if (m.method == 'SystemChrome.setApplicationSwitcherDescription') {
          titles.add((m.arguments as Map)['label'] as String);
        }
        return null;
      },
    );
    final calls = CallsConnector();
    final c = CallController(
      backend: FakeBackend(),
      connector: calls,
      botId: botId,
      requestedConversationId: convId,
    );
    await tester.runAsync(c.connect);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CallTabTitle(call: c),
      ),
    );
    await tester.pump();
    expect(titles.last, startsWith('On a call · 0:0'));
    await tester.pumpWidget(const SizedBox());
    expect(titles.last, 'Casama');
    await tester.runAsync(() => c.end(CallEnd.hungUp));
    c.dispose();
  });

  test('iPhone: an outgoing CallKit call; the mic waits for its audio session; its buttons drive the call', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const methods = MethodChannel('flutter_callkit_incoming');
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(methods, (m) async {
      calls.add(m);
      return null;
    });
    final events = StreamController<Object?>();
    messenger.setMockStreamHandler(
      const EventChannel('flutter_callkit_incoming_events'),
      MockStreamHandler.inline(
        onListen: (_, sink) => events.stream.listen(sink.success),
      ),
    );
    const id = '88888888-8888-4888-8888-888888888888';
    const prefix = 'com.hiennv.flutter_callkit_incoming.';
    final s = CallKitCallSystem(audioWait: const Duration(seconds: 5));
    final got = <CallSystemAction>[];
    s.actions.listen(got.add);
    var ready = false;
    final starting = s
        .start(const CallSystemCall(id: id, botName: 'Ava'))
        .then((_) => ready = true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls.single.method, 'startCall');
    expect((calls.single.arguments as Map)['nameCaller'], 'Ava');
    // Not until CallKit activates the audio session.
    expect(ready, isFalse);
    events.add({
      'event': '${prefix}ACTION_CALL_TOGGLE_AUDIO_SESSION',
      'body': {'isActive': true},
    });
    await starting;
    expect(ready, isTrue);

    await s.connected();
    expect(calls.last.method, 'callConnected');
    events
      ..add({
        'event': '${prefix}ACTION_CALL_TOGGLE_MUTE',
        'body': {'id': id, 'isMuted': true},
      })
      ..add({
        'event': '${prefix}ACTION_CALL_TOGGLE_HOLD',
        'body': {'id': id, 'isOnHold': true},
      })
      ..add({
        'event': '${prefix}ACTION_CALL_ENDED',
        'body': {'id': id},
      });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(got, [
      CallSystemAction.mute,
      CallSystemAction.hold,
      CallSystemAction.end,
    ]);
    // CallKit already shows it muted: no echo back.
    await s.update(muted: true, reconnecting: false);
    expect(calls.where((c) => c.method == 'muteCall'), isEmpty);

    await s.end();
    expect(calls.last.method, 'endCall');
    messenger.setMockMethodCallHandler(methods, null);
    await events.close();
  });
}
