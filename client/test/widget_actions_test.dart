// Widgets' buttons carried out by the app (D-405 §8.4): Run now and Do it, Allow and Deny for
// low-risk requests only, nothing in place while widgets are private, and the Mac ignoring them.
import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/push.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/companion/desktop_shell.dart';
import 'package:casama/features/island/island_bridge.dart';
import 'package:casama/features/island/island_feed.dart';
import 'package:casama/features/island/run_tracker.dart';
import 'package:casama/features/widgets/widget_settings.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

class _Bots extends BotsNotifier {
  _Bots(this.initial);
  final List<Bot> initial;
  @override
  Future<List<Bot>> build() async => initial;
}

class _QuietShell extends DesktopShell {
  _QuietShell(super.ref);
  @override
  void showWindow() {}
  @override
  void openQuickAsk() {}
}

class _NoPush extends PushRegistrar {
  _NoPush(Backend backend) : super(backend, (_) {});
  @override
  Future<String?> silentToken() async => null;
}

Approval _approval(String id, Risk risk) => Approval(
  id: id,
  botId: botId,
  runId: runId,
  toolName: 'email.send',
  argsRedacted: const {},
  summary: 'Send it',
  risk: risk,
  status: ApprovalStatusEnum.pending,
  decidedAt: null,
  expiresAt: DateTime(2026, 11, 19),
  createdAt: DateTime(2026, 11, 18),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(islandChannelName);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => null);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  ({ProviderContainer c, FakeBackend backend, IslandBridge bridge}) setUpBridge(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    final backend = FakeBackend()..pendingApprovals = [_approval('low1', Risk.low), _approval('mid1', Risk.medium), _approval('high1', Risk.high)];
    final c = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(backend),
        pushProvider.overrideWithValue(_NoPush(backend)),
        desktopShellProvider.overrideWith(_QuietShell.new),
        islandSupportedProvider.overrideWithValue(true),
        currentOrgIdProvider.overrideWithValue(orgId),
        botsProvider.overrideWith(() => _Bots([backend.bot()])),
        islandLocalActivityProvider.overrideWithBuild((ref, notifier) => null),
      ],
    );
    addTearDown(c.dispose);
    return (c: c, backend: backend, bridge: c.read(islandBridgeProvider)!);
  }

  Future<bool> act(IslandBridge bridge, Map<String, Object?> args) async =>
      await bridge.handle(MethodCall('action', {...args, 'from': 'widget'})) == true;

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('$platform: Run now and Do it are carried out in place', () async {
      final s = setUpBridge(platform);
      expect(await act(s.bridge, {'kind': 'run_routine', 'routine_id': 'r1', 'bot_id': botId}), isTrue);
      expect(s.backend.routinesRun, ['r1']);
      // The run is followed, so it shows on the Lock Screen.
      expect(s.c.read(runTrackerProvider).map((r) => r.runId), contains(runId));
      expect(await act(s.bridge, {'kind': 'accept', 'suggestion_id': 's1', 'bot_id': botId}), isTrue);
      expect(s.backend.suggestionActions, ['accept:s1']);
      expect(await act(s.bridge, {'kind': 'run_routine'}), isFalse, reason: 'no routine');
    });

    test('$platform: Allow and Deny answer only a low-risk request still waiting', () async {
      final s = setUpBridge(platform);
      expect(await act(s.bridge, {'kind': 'allow', 'approval_id': 'mid1'}), isFalse, reason: 'medium is reviewed in the app');
      expect(await act(s.bridge, {'kind': 'allow', 'approval_id': 'high1'}), isFalse);
      expect(await act(s.bridge, {'kind': 'deny', 'approval_id': 'mid1'}), isFalse);
      expect(await act(s.bridge, {'kind': 'allow', 'approval_id': 'gone'}), isFalse);
      expect(s.backend.decisions, isEmpty);
      expect(await act(s.bridge, {'kind': 'allow', 'approval_id': 'low1'}), isTrue);
      expect(s.backend.decisions['low1'], 'approved');
      // Answered: no longer waiting, so a second press does nothing.
      expect(await act(s.bridge, {'kind': 'deny', 'approval_id': 'low1'}), isFalse);
    });

    test('$platform: with the app lock on, buttons open the app instead, until Show details', () async {
      final s = setUpBridge(platform);
      await s.c.read(appLockSettingsProvider.notifier).save(const AppLockSettings(enabled: true, userId: 'me'));
      expect(await act(s.bridge, {'kind': 'run_routine', 'routine_id': 'r1', 'bot_id': botId}), isFalse);
      expect(await act(s.bridge, {'kind': 'accept', 'suggestion_id': 's1'}), isFalse);
      expect(await act(s.bridge, {'kind': 'allow', 'approval_id': 'low1'}), isFalse);
      expect(s.backend.routinesRun, isEmpty);
      expect(s.backend.suggestionActions, isEmpty);
      expect(s.backend.decisions, isEmpty);
      await s.c.read(widgetDetailsProvider.notifier).set(true);
      expect(await act(s.bridge, {'kind': 'run_routine', 'routine_id': 'r1', 'bot_id': botId}), isTrue);
      // Stop always works, as from the Live Activity.
      expect(await act(s.bridge, {'kind': 'stop', 'run_id': 'r'}), isTrue);
      expect(s.backend.cancelled, isTrue);
    });
  }

  test('the Mac ignores widget actions: its widgets only open links', () async {
    final s = setUpBridge(TargetPlatform.macOS);
    expect(await act(s.bridge, {'kind': 'run_routine', 'routine_id': 'r1', 'bot_id': botId}), isFalse);
    expect(await act(s.bridge, {'kind': 'accept', 'suggestion_id': 's1'}), isFalse);
    expect(await act(s.bridge, {'kind': 'allow', 'approval_id': 'low1'}), isFalse);
    expect(s.backend.routinesRun, isEmpty);
    expect(s.backend.decisions, isEmpty);
  });

  test('native Run now and Do it without `from` (as Android sends them) still count as widget actions', () async {
    final s = setUpBridge(TargetPlatform.android);
    expect(await s.bridge.handle(const MethodCall('action', {'kind': 'run_routine', 'routine_id': 'r1', 'bot_id': botId, 'unlocked': true})), isTrue);
    expect(await s.bridge.handle(const MethodCall('action', {'kind': 'accept', 'suggestion_id': 's1', 'bot_id': botId, 'unlocked': true})), isTrue);
    expect(s.backend.routinesRun, ['r1']);
    expect(s.backend.suggestionActions, ['accept:s1']);
  });

  test('a Live Activity\'s Allow still follows its own rules', () async {
    final s = setUpBridge(TargetPlatform.iOS);
    // Not from a widget and not in the feed: refused as before.
    expect(await s.bridge.handle(const MethodCall('action', {'kind': 'allow', 'approval_id': 'low1', 'unlocked': true})), isFalse);
    expect(s.backend.decisions, isEmpty);
  });
}
