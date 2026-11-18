// The call outside the app's window (D-327 Phase 4): the glance that the iPhone's Live Activity,
// the Mac's menu bar and (after D-324's merge) the notch show, and their buttons.
import 'dart:async';
import 'dart:ui' show Locale;

import 'package:casama/features/voice/active_call.dart';
import 'package:casama/features/voice/call_glance.dart';
import 'package:casama/features/voice/call_system.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'active_call_test.dart' show CallsConnector;
import 'fake_backend.dart';

class FakeSurface implements CallGlanceSurface {
  final shown = <CallGlance>[];
  var hidden = 0;
  final _actions = StreamController<CallSystemAction>.broadcast();
  void press(CallSystemAction a) => _actions.add(a);

  @override
  Future<void> show(CallGlance glance) async => shown.add(glance);
  @override
  Future<void> hide() async => hidden++;
  @override
  Stream<CallSystemAction> get actions => _actions.stream;
  @override
  void dispose() {}
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('the glance follows the call: name, timer start, mute, the job; buttons mute, open and end it', () async {
    final backend = FakeBackend()
      ..voiceToolResults['start_task'] = VoiceToolResult(
        status: VoiceToolResultStatusEnum.completed,
        runId: 'run-job',
        output: 'Started in the background.',
        approvalId: null,
      );
    final calls = CallsConnector();
    final opened = <String>[];
    final active = ActiveCall(
      () => backend,
      () => calls,
      botNameOf: (_) => 'Ava',
      openPath: (path, {swap = false}) => opened.add(path),
    );
    expect(callGlanceOf(active.live), isNull);

    final c = active.begin(botId, conversationId: convId)!;
    await settle();
    final g = callGlanceOf(c)!;
    expect(g.id, 'live-1');
    expect(g.botName, 'Ava');
    expect(g.since, isNotNull);
    expect(g.link, '/bots/$botId/call?c=$convId');
    expect(g.status(l10n), 'On a call');

    active.act(CallSystemAction.mute);
    expect(c.muted, isTrue);
    expect(callGlanceOf(c)!.status(l10n), 'Muted');
    active.act(CallSystemAction.unmute);
    expect(c.muted, isFalse);

    calls.last.askTool('t1', 'start_task', const {'task': 'Book the flight'});
    await settle();
    final working = callGlanceOf(c)!;
    expect(working.doing, 'Book the flight');
    expect(working.needsYou, isFalse);
    expect(working.status(l10n), 'Working on: Book the flight');
    expect(working.toJson(l10n)['status'], 'Working on: Book the flight');

    calls.last.reconnectingNow.value = true;
    expect(callGlanceOf(c)!.status(l10n), 'Reconnecting…');
    calls.last.reconnectingNow.value = false;

    active.act(CallSystemAction.open);
    expect(opened, ['/bots/$botId/call?c=$convId']);

    active.act(CallSystemAction.end);
    await settle();
    expect(c.over, isTrue);
    expect(callGlanceOf(active.live), isNull);
    active.dispose();
  });

  test('the surfaces get the call once per change (not per word), their buttons drive it, and it goes when the call ends', () async {
    final calls = CallsConnector();
    final active = ActiveCall(
      () => FakeBackend(),
      () => calls,
      botNameOf: (_) => 'Ava',
    );
    final surface = FakeSurface();
    final container = ProviderContainer(
      overrides: [
        activeCallProvider.overrideWithValue(active),
        callGlanceSurfaceProvider.overrideWithValue(surface),
      ],
    );
    container.listen(callGlanceSyncProvider, (_, _) {});
    await settle();
    // No call: hidden, nothing shown.
    expect(surface.shown, isEmpty);

    final c = active.begin(botId, conversationId: convId)!;
    await settle();
    expect(surface.shown, isNotEmpty);
    expect(surface.shown.last.id, 'live-1');
    final count = surface.shown.length;

    // Words said on the call don't redraw the lock screen.
    calls.last.say('user', 'hello');
    calls.last.say('model', 'hi there');
    await settle();
    expect(surface.shown.length, count);

    // Mute on the lock screen mutes the call, and the surface shows it muted.
    surface.press(CallSystemAction.mute);
    await settle();
    expect(c.muted, isTrue);
    expect(surface.shown.last.muted, isTrue);

    final hiddenBefore = surface.hidden;
    surface.press(CallSystemAction.end);
    await settle();
    expect(c.over, isTrue);
    expect(surface.hidden, greaterThan(hiddenBefore));
    container.dispose();
    active.dispose();
  });

  test('iPhone: one Live Activity per call, updated in place, ended with the call; its buttons come back', () async {
    final log = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const plugin = MethodChannel('live_activities');
    const glance = MethodChannel('casama/call_glance');
    messenger.setMockMethodCallHandler(plugin, (m) async {
      log.add(m);
      return switch (m.method) {
        'areActivitiesEnabled' => true,
        'createActivity' => 'activity-1',
        _ => null,
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(plugin, null));

    final s = LiveActivityCallGlance();
    final since = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final connecting = CallGlance(
      id: botId,
      botId: botId,
      botName: 'Ava',
      link: '/bots/$botId/call',
    );
    final live = CallGlance(
      id: 'live-1',
      botId: botId,
      botName: 'Ava',
      botAvatar: 'mascot:winky',
      link: '/bots/$botId/call',
      since: since,
    );
    await s.show(connecting);
    await s.show(live);
    await s.show(
      CallGlance(
        id: 'live-1',
        botId: botId,
        botName: 'Ava',
        link: '/bots/$botId/call',
        since: since,
        muted: true,
      ),
    );
    await s.hide();

    final methods = [for (final m in log) m.method];
    expect(methods, [
      'init',
      'areActivitiesEnabled',
      'createActivity',
      // The call got its server record: the connecting activity gives way to the call's own.
      'endActivity',
      'createActivity',
      'updateActivity',
      'endActivity',
    ]);
    final create = log[4].arguments as Map;
    expect(create['activityId'], 'live-1');
    expect(create['removeWhenAppIsKilled'], isTrue);
    expect(create['enableRemoteUpdates'], isFalse);
    final data = Map<String, Object?>.from(create['data'] as Map);
    expect(data['kind'], 'call');
    expect(data['bot'], 'Ava');
    // The widget draws the bot's own mascot (CasamaWidgets.swift, BotArt).
    expect(data['avatar'], 'mascot:winky');
    expect(data['since'], '1700000000');
    expect(data['muted'], '0');
    expect(data['link'], 'casama://app/bots/$botId/call');
    expect(data['end'], 'End Call');
    expect((log[5].arguments as Map)['data']['muted'], '1');
    expect((log[6].arguments as Map)['activityId'], 'live-1');

    // Mute pressed on the lock screen (AppDelegate passes the widget's notification on).
    final pressed = s.actions.first;
    await messenger.handlePlatformMessage(
      glance.name,
      glance.codec.encodeMethodCall(
        const MethodCall('action', {'action': 'mute'}),
      ),
      (_) {},
    );
    expect(await pressed, CallSystemAction.mute);
    s.dispose();
  });

  test('Live Activities turned off: nothing is shown, nothing fails', () async {
    final log = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const plugin = MethodChannel('live_activities');
    messenger.setMockMethodCallHandler(plugin, (m) async {
      log.add(m.method);
      return m.method == 'areActivitiesEnabled' ? false : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(plugin, null));
    final s = LiveActivityCallGlance();
    await s.show(
      const CallGlance(id: 'live-1', botId: botId, botName: 'Ava', link: '/'),
    );
    await s.hide();
    expect(log, ['init', 'areActivitiesEnabled']);
    s.dispose();
  });

  test("the Mac's menu bar: the call's line, Mute or Unmute, End Call, Show Call; the title counts", () {
    final since = DateTime(2026, 11, 16, 10);
    final g = CallGlance(
      id: 'live-1',
      botId: botId,
      botName: 'Ava',
      link: '/',
      since: since,
      doing: 'Book the flight',
    );
    final menu = callMenu(g, l10n);
    expect(menu.status, 'Ava · Working on: Book the flight');
    expect(menu.items.map((i) => i.$1), ['Mute', 'End Call', 'Show Call']);
    expect(menu.items.map((i) => i.$2), [
      CallSystemAction.mute,
      CallSystemAction.end,
      CallSystemAction.open,
    ]);
    final muted = callMenu(
      CallGlance(
        id: 'live-1',
        botId: botId,
        botName: 'Ava',
        link: '/',
        since: since,
        muted: true,
      ),
      l10n,
    );
    expect(muted.status, 'Ava · Muted');
    expect(muted.items.first, ('Unmute', CallSystemAction.unmute));

    expect(
      callMenuTitle(g, since.add(const Duration(minutes: 3, seconds: 12))),
      '● Ava 3:12',
    );
    expect(
      callMenuTitle(
        g,
        since.add(const Duration(hours: 1, minutes: 2, seconds: 5)),
      ),
      '● Ava 1:02:05',
    );
    expect(
      callMenuTitle(
        const CallGlance(id: botId, botId: botId, botName: 'Ava', link: '/'),
        since,
      ),
      '● Ava',
    );
    expect(
      callMenu(
        const CallGlance(id: botId, botId: botId, botName: 'Ava', link: '/'),
        l10n,
      ).status,
      'Ava · Connecting…',
    );
  });
}
