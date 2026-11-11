import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/companion/companion.dart';
import 'package:casama_app/features/companion/companion_overlay.dart';
import 'package:casama_app/features/companion/companion_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

class FakeCompanion implements Companion {
  final _status = ValueNotifier(CompanionStatus.off);
  final _activity = ValueNotifier<CompanionActivity?>(null);
  CompanionSettings? started;
  var stops = 0;
  @override
  ValueListenable<CompanionStatus> get status => _status;
  @override
  ValueListenable<CompanionActivity?> get activity => _activity;
  @override
  bool get supported => true;
  @override
  Future<void> start({required String apiUrl, required String deviceToken, required CompanionSettings settings}) async {
    started = settings;
    _status.value = CompanionStatus.online;
  }

  @override
  Future<void> stop() async {
    stops++;
    _status.value = CompanionStatus.off;
  }

  void act(CompanionActivity? a) => _activity.value = a;

  List<String> codingAgents = const [];
  @override
  Future<List<String>> detectCodingAgents() async => codingAgents;
}

class MemoryTokens implements DeviceTokenStore {
  final m = <String, (String, String)>{};
  @override
  Future<(String, String)?> read(String orgId) async => m[orgId];
  @override
  Future<void> write(String orgId, String deviceId, String token) async => m[orgId] = (deviceId, token);
  @override
  Future<void> delete(String orgId) async => m.remove(orgId);
}

class MemoryMcp implements LocalMcpStore {
  final m = <String, List<LocalMcpConfig>>{};
  @override
  Future<List<LocalMcpConfig>> read(String orgId) async => m[orgId] ?? const [];
  @override
  Future<void> write(String orgId, List<LocalMcpConfig> servers) async => m[orgId] = servers;
}

Widget companionHarness(FakeBackend backend, FakeCompanion companion, MemoryTokens tokens, Widget child, {LocalMcpStore? mcp}) => ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
        companionProvider.overrideWithValue(companion),
        deviceTokenStoreProvider.overrideWithValue(tokens),
        localMcpStoreProvider.overrideWithValue(mcp ?? MemoryMcp()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('pairing this computer, approving capabilities and allowing a bot', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend();
    final companion = FakeCompanion();
    final tokens = MemoryTokens();
    await tester.pumpWidget(companionHarness(backend, companion, tokens, const CompanionScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pairComputer')));
    await tester.pumpAndSettle();
    expect(tokens.m[orgId], ('dev1', 'kdev_test'));
    expect(companion.started?.capabilities, isEmpty, reason: 'nothing is allowed until approved');

    await tester.tap(find.byKey(const Key('cap-browser')));
    await tester.pumpAndSettle();
    expect(companion.started?.capabilities, {'browser'});
    await tester.scrollUntilVisible(find.byKey(const Key('allowBot-$botId')), 200);
    await tester.tap(find.byKey(const Key('allowBot-$botId')));
    await tester.pumpAndSettle();
    expect(backend.deviceUpdates.last, 'bots:$botId');
    expect(backend.defaultComputer, 'local-computer');

    await tester.scrollUntilVisible(find.byKey(const Key('companionEnabled')), -200);
    await tester.tap(find.byKey(const Key('companionEnabled')));
    await tester.pumpAndSettle();
    expect(companion.stops, greaterThan(0));
    expect(backend.deviceUpdates.last, 'enabled:false');
  });

  testWidgets('the overlay shows which bot is acting and stops its run', (tester) async {
    final backend = FakeBackend();
    final companion = FakeCompanion();
    await tester.pumpWidget(companionHarness(backend, companion, MemoryTokens(), const CompanionOverlay(child: Scaffold(body: Text('app')))));
    await tester.pump();
    expect(find.byKey(const Key('companionOverlay')), findsNothing);
    companion.act(const CompanionActivity(runId: runId, bot: 'Ada', tool: 'browser.open', summary: 'open example.com'));
    await tester.pump();
    expect(find.text('Ada is working on this computer: open example.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('companionStop')));
    await tester.pump();
    expect(backend.cancelled, isTrue);
    companion.act(null);
    await tester.pump();
    expect(find.byKey(const Key('companionOverlay')), findsNothing);
  });
}
