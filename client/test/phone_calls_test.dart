import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:casama/core/voice.dart';
import 'package:casama/features/voice/call_screen.dart';
import 'package:casama/features/voice/full_screen_calls.dart';
import 'package:casama/features/voice/phone_calls.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';

/// Phone-call voice (D-135).
PhoneCall _call(String id, String reason) => PhoneCall(
      id: id,
      botId: botId,
      botName: 'Max',
      reason: reason,
      status: PhoneCallStatusEnum.ringing,
      conversationId: convId,
      expiresAt: DateTime.now().add(const Duration(seconds: 40)),
      createdAt: DateTime.now(),
    );

/// The phone's own calling screen (Android's ring): Answer taps, and rings answered before the app
/// listened (D-424).
class _NativeSurface implements CallSurface {
  final taps = StreamController<(CallAction, IncomingCall)>.broadcast();
  var pending = <IncomingCall>[];
  final ended = <String>[];
  @override
  bool get native => true;
  @override
  Future<void> show(IncomingCall call) async {}
  @override
  Future<void> end(String id) async => ended.add(id);
  @override
  Stream<(CallAction, IncomingCall)> get actions => taps.stream;
  @override
  Future<List<IncomingCall>> answered() async => pending;
  @override
  Future<String?> voipToken() async => null;
}

IncomingCall _ring(String id) => IncomingCall(id: id, botId: botId, botName: 'Max', reason: 'hi', conversationId: convId);

class _FullScreen implements FullScreenCalls {
  _FullScreen(this.on);
  bool? on;
  var asked = 0;
  @override
  Future<bool?> allowed() async => on;
  @override
  Future<void> ask() async => asked++;
}

Widget _app(FakeBackend backend, {FakeCallConnector? calls, CallSurface? surface}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const IncomingCallBanner(child: Scaffold(body: Text('home')))),
    GoRoute(path: '/bots/:id/call', builder: (_, s) => CallScreen(botId: s.pathParameters['id']!, conversationId: s.uri.queryParameters['c'], callId: s.uri.queryParameters['call'])),
  ]);
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      callSurfaceProvider.overrideWithValue(surface ?? NoCallSurface()),
      if (surface != null) signedInProvider.overrideWith((ref) => Stream.value(true)),
      routerProvider.overrideWithValue(router),
      if (calls != null) voiceCallConnectorProvider.overrideWithValue(calls),
    ],
    child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
  );
}

void main() {
  CallScreen.motion = false;
  testWidgets('desktop: a ringing banner; answering opens the live call where the bot speaks first', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend()..ringing.add(_call('call-1', 'The deploy failed; roll back?'));
    final calls = FakeCallConnector();
    await tester.pumpWidget(_app(backend, calls: calls));
    await tester.pump();
    await tester.pump();
    expect(find.text('Max is calling'), findsOneWidget);
    expect(find.text('The deploy failed; roll back?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('answerCall')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.callActions, ['answer:call-1']);
    expect(backend.sessionCallId, 'call-1');
    expect(calls.session?.speakFirst, isTrue);
    expect(calls.session?.conversationId, convId);
  });

  testWidgets('declining clears the banner', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend()..ringing.add(_call('call-2', 'Lunch at noon?'));
    await tester.pumpWidget(_app(backend));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('declineCall')));
    await tester.pump();
    await tester.pump();
    expect(backend.callActions, ['decline:call-2']);
    expect(find.byKey(const Key('incomingCall')), findsNothing);
  });

  test('push payloads become calls', () {
    final c = IncomingCall.fromData({'call_id': 'c1', 'bot_id': 'b1', 'bot_name': 'Max', 'reason': 'hi', 'conversation_id': ''})!;
    expect(c.conversationId, isNull);
    expect(c.callPath, '/bots/b1/call?call=c1');
    expect(IncomingCall.fromData({'bot_id': 'b1'}), isNull);
  });

  // Android (D-424): Answer on the ring screen or its notification opens the live call.
  testWidgets("Answer on the phone's ring opens the call screen", (tester) async {
    await setSize(tester, const Size(400, 800));
    final backend = FakeBackend()..ringing.add(_call('call-3', 'hi'));
    final surface = _NativeSurface();
    await tester.pumpWidget(_app(backend, calls: FakeCallConnector(), surface: surface));
    await tester.pump();
    await tester.pump();
    expect(find.text('home'), findsOneWidget);

    surface.taps.add((CallAction.accept, _ring('call-3')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.callActions, ['answer:call-3']);
    expect(find.byType(CallScreen), findsOneWidget);
    expect(backend.sessionCallId, 'call-3');
  });

  testWidgets('opened by Answer with the app closed: the answered ring is picked up and its call screen opens', (tester) async {
    await setSize(tester, const Size(400, 800));
    final backend = FakeBackend()..ringing.add(_call('call-4', 'hi'));
    // The answer event fired before the app listened; the plugin still lists the ring as answered.
    final surface = _NativeSurface()..pending = [_ring('call-4')];
    await tester.pumpWidget(_app(backend, calls: FakeCallConnector(), surface: surface));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.callActions, ['answer:call-4']);
    expect(find.byType(CallScreen), findsOneWidget);
  });

  testWidgets('the answer event and the launch check report the same ring: answered once', (tester) async {
    await setSize(tester, const Size(400, 800));
    final backend = FakeBackend()..ringing.add(_call('call-5', 'hi'));
    final surface = _NativeSurface()..pending = [_ring('call-5')];
    await tester.pumpWidget(_app(backend, calls: FakeCallConnector(), surface: surface));
    surface.taps.add((CallAction.accept, _ring('call-5')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // A second answer would fail (no longer ringing) and send the person to the chat instead.
    expect(backend.callActions, ['answer:call-5']);
    expect(surface.ended, isEmpty);
    expect(find.byType(CallScreen), findsOneWidget);
  });

  testWidgets('full-screen ring off (Android 14+): a settings row asks for it; on: no row', (tester) async {
    final phone = _FullScreen(false);
    Widget tile() => ProviderScope(
          overrides: [fullScreenCallsProvider.overrideWithValue(phone)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: FullScreenCallsTile()),
          ),
        );
    await tester.pumpWidget(tile());
    await tester.pump();
    expect(find.text('Calls on the Lock Screen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settingsFullScreenCalls')));
    expect(phone.asked, 1);

    phone.on = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(tile());
    await tester.pump();
    expect(find.byKey(const Key('settingsFullScreenCalls')), findsNothing);
  });

  // Android, app closed (D-424): the isolate that rang hears Decline and declines with the ring's token.
  group('Decline with the app closed', () {
    CallKitParams params(String id) => CallKitParams(id: id);

    test('declining this ring: true; answering, ending or timing out: false; other calls are ignored', () async {
      Future<bool> after(List<CallEvent> events) {
        final c = StreamController<CallEvent?>();
        final r = ringDeclined(c.stream, 'c1');
        for (final e in events) {
          c.add(e);
        }
        return r;
      }

      expect(await after([CallEventActionCallDecline(params('other')), CallEventActionCallDecline(params('c1'))]), isTrue);
      expect(await after([CallEventActionCallAccept(params('c1'))]), isFalse);
      expect(await after([CallEventActionCallEnded(params('c1'))]), isFalse);
      expect(await after([const CallEventActionCallTimeout('c1')]), isFalse);
      // Nothing happens: it stops waiting.
      expect(await ringDeclined(const Stream<CallEvent?>.empty(), 'c1'), isFalse);
      expect(await ringDeclined(StreamController<CallEvent?>().stream, 'c1', limit: const Duration(milliseconds: 10)), isFalse);
    });

    test("sends the ring's token to the server, signed out; a failure is only logged", () async {
      final sent = <http.Request>[];
      final ok = MockClient((r) async {
        sent.add(r);
        return http.Response('{"declined":true}', 200);
      });
      await sendRingDecline('c1', 'tok', client: ok, apiUrl: () async => 'https://api.example.com');
      expect(sent.single.url.toString(), 'https://api.example.com/v1/calls/c1/decline-ring');
      expect(sent.single.headers.containsKey('authorization'), isFalse);
      expect(sent.single.body, '{"token":"tok"}');

      final down = MockClient((_) async => throw http.ClientException('offline'));
      await sendRingDecline('c1', 'tok', client: down, apiUrl: () async => 'https://api.example.com');
    });
  });

  // Another device answered, declined or missed the call (D-425): the ring stops here.
  group('ring stopped elsewhere', () {
    CallKitParams ring(String id, {bool accepted = false}) => CallKitParams(id: id, isAccepted: accepted);

    test('a call_cancel push names the call; other pushes are not cancels', () {
      expect(cancelledCallId({'kind': 'call_cancel', 'call_id': 'c9'}), 'c9');
      expect(cancelledCallId({'kind': 'call', 'call_id': 'c9'}), isNull);
      expect(cancelledCallId({'kind': 'call_cancel', 'call_id': ''}), isNull);
    });

    test('ends the ring showing here; never a call answered here or one not ringing here', () async {
      final ended = <String>[];
      Future<void> stop(String id, List<CallKitParams> active) => stopRing(id, active: () async => active, end: (i) async => ended.add(i));

      await stop('r1', [ring('r1')]);
      expect(ended, ['r1']);
      expect(cancelledRings, contains('r1'));

      // Answered on this phone: its own call goes on.
      answeredRings.add('r2');
      await stop('r2', [ring('r2')]);
      // Answered from the calling screen in another isolate (Android): the plugin knows.
      await stop('r3', [ring('r3', accepted: true)]);
      // Not ringing here (iOS would end its last ring whatever the id).
      await stop('r4', [ring('other')]);
      expect(ended, ['r1']);
    });

    testWidgets('the Decline event a stopped ring sends declines nothing on the server', (tester) async {
      await setSize(tester, const Size(400, 800));
      final backend = FakeBackend()..ringing.add(_call('call-6', 'hi'));
      final surface = _NativeSurface();
      await tester.pumpWidget(_app(backend, calls: FakeCallConnector(), surface: surface));
      await tester.pump();
      await stopRing('call-6', active: () async => [ring('call-6')], end: (_) async {});
      surface.taps.add((CallAction.decline, _ring('call-6')));
      await tester.pump();
      await tester.pump();
      expect(backend.callActions, isEmpty);
    });
  });
}
