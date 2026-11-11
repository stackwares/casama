// Expert options on the connection screens sit in one folded "Advanced" section (D-182): folded
// by default, one tap opens it, and nothing is unreachable.
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/companion/companion_screen.dart';
import 'package:casama_app/features/devices/device_connections_screen.dart';
import 'package:casama_app/features/devices/device_sync.dart';
import 'package:casama_app/features/integrations/integration_detail_screen.dart';
import 'package:casama_app/features/integrations/integrations_screen.dart';
import 'package:casama_app/features/settings/model_keys_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'companion_test.dart' show FakeCompanion, MemoryTokens, companionHarness;
import 'device_connections_test.dart' show FakeCollector, FakeTriggers;
import 'fake_backend.dart';

/// The page's own (vertical) scroll view, not the horizontal app rows inside it.
final _page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

Future<void> _open(WidgetTester tester, String id) async {
  await tester.scrollUntilVisible(find.byKey(Key('advanced-$id')), 300, scrollable: _page);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('advanced-$id')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the add-key form lists chat-model providers first, and every pasted-key provider', () {
    expect(keyProviders.take(5), [ProviderId.openrouter, ProviderId.openai, ProviderId.anthropic, ProviderId.google, ProviderId.xai]);
    expect(keyProviders.toSet(), {
      for (final p in ProviderId.values)
        if (p != ProviderId.chatgpt) p,
    });
    expect(keyProviders.length, keyProviders.toSet().length);
    expect(moreKeyProviders.last, ProviderId.openaiCompatible);
  });

  testWidgets('add key: chat providers, then a "More providers" heading over the rest', (tester) async {
    await setSize(tester, const Size(500, 1400));
    await tester.pumpWidget(harness(FakeBackend(), const ModelKeysScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ProviderId>));
    await tester.pumpAndSettle();
    double y(Finder f) => tester.getTopLeft(f.last).dy;
    final openRouter = y(find.textContaining('OpenRouter'));
    final xai = y(find.text('xAI'));
    final more = y(find.byKey(const Key('moreProviders')));
    final deepgram = y(find.textContaining('Deepgram'));
    final compatible = y(find.textContaining('OpenAI-compatible server'));
    expect(openRouter < xai && xai < more && more < deepgram && deepgram < compatible, isTrue, reason: '$openRouter $xai $more $deepgram $compatible');
    expect(find.text('More providers'), findsOneWidget);

    // The heading isn't a choice; a provider under it still works as before.
    await tester.tap(find.byKey(const Key('moreProviders')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moreProviders')), findsOneWidget);
    await tester.tap(find.textContaining('OpenAI-compatible server').last);
    await tester.pumpAndSettle();
    expect(find.text('Base URL'), findsOneWidget);
  });

  testWidgets('apps: hubs and custom servers are folded at the end, with no header shortcut', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Custom server'), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('advanced-integrations')), 300, scrollable: _page);
    expect(find.text('Composio, Pipedream, custom servers'), findsOneWidget);
    for (final k in ['setupComposio', 'setupPipedream', 'addIntegration']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
    await tester.tap(find.byKey(const Key('advanced-integrations')));
    await tester.pumpAndSettle();
    for (final k in ['setupComposio', 'setupPipedream', 'addIntegration']) {
      await tester.scrollUntilVisible(find.byKey(Key(k)), 300, scrollable: _page);
      expect(find.byKey(Key(k)), findsOneWidget);
    }
  });

  testWidgets('apps: apps signed in through Composio are listed one by one, and marked in Browse', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    backend.catalog.add(FakeBackend.catalogApp('gmail', 'Gmail', [CatalogAppAuthEnum.managed], popular: false).copyWith(composio: 'gmail'));
    final hub = await backend.createIntegration(orgId, kind: 'composio', name: 'apps', config: {'toolkits': <String>[]});
    backend.providerConnects.addAll(['gmail', 'linear_app']);
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    // Each app gets its own row; the hub's own card is replaced by them.
    expect(find.text('Connected · 2'), findsOneWidget);
    expect(find.byKey(Key('hubApp-${hub.id}-gmail')), findsOneWidget);
    expect(find.byKey(Key('hubApp-${hub.id}-linear_app')), findsOneWidget);
    expect(find.text('Linear App'), findsOneWidget);
    expect(find.byKey(Key('integration-${hub.id}')), findsNothing);
    expect(find.textContaining('Through Composio'), findsNWidgets(2));
    // Browse shows Gmail as connected.
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    final gmail = find.ancestor(of: find.text('Gmail'), matching: find.byType(InkWell)).first;
    await tester.scrollUntilVisible(gmail, 300, scrollable: _page);
    expect(find.descendant(of: gmail, matching: find.text('Connected')), findsOneWidget);
  });

  testWidgets('apps: a Composio connection with no apps yet still shows its own card', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    final hub = await backend.createIntegration(orgId, kind: 'composio', name: 'apps', config: {'toolkits': <String>[]});
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('integration-${hub.id}')), findsOneWidget);
    expect(find.text('Connected · 1'), findsOneWidget);
  });

  testWidgets("apps: a bot's list doesn't label connections MCP or OpenAPI", (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await backend.createIntegration(orgId, kind: 'mcp', name: 'calc', config: {'url': 'https://mcp.example.com/mcp'});
    await backend.createIntegration(orgId, kind: 'openapi', name: 'shop', config: {'spec': 'https://shop.example.com/openapi.json'});
    await tester.pumpWidget(harness(backend, const BotIntegrationsScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attach-i1')), findsOneWidget);
    expect(find.byKey(const Key('attach-i2')), findsOneWidget);
    expect(find.textContaining('MCP server'), findsNothing);
    expect(find.textContaining('OpenAPI'), findsNothing);
  });

  testWidgets('a connection: per-tool permissions are folded under "Tool permissions"', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend();
    await backend.connectApp(orgId, appId: 'stripe', method: 'api_key', apiKey: 'k');
    await tester.pumpWidget(harness(backend, const IntegrationDetailScreen(integrationId: 'app-stripe')));
    await tester.pumpAndSettle();
    expect(find.text('Tool permissions'), findsOneWidget);
    expect(find.byKey(const Key('toolRisk-list_customers')), findsNothing);
    expect(find.byKey(const Key('disconnectIntegration')), findsOneWidget);
    await _open(tester, 'integration.tools');
    expect(find.byKey(const Key('toolRisk-list_customers')), findsOneWidget);
  });

  testWidgets('device connections: one switch per kind; keep, private and bots are folded', (tester) async {
    await setSize(tester, const Size(500, 1200));
    final backend = FakeBackend();
    backend.grants.add(DeviceGrant(botId: botId, botName: 'Pal', kind: DeviceKind.calendar, createdAt: DateTime(2026)));
    await tester.pumpWidget(
      harness(backend, const DeviceConnectionsScreen(), overrides: [deviceCollectorProvider.overrideWithValue(FakeCollector()), deviceTriggerPlatformProvider.overrideWithValue(FakeTriggers())]),
    );
    await tester.pumpAndSettle();
    // Nothing shared yet: nothing to set.
    expect(find.byKey(const Key('advanced-devices')), findsNothing);
    await tester.tap(find.byKey(const Key('deviceSwitch-calendar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deviceSwitch-calendar')), findsOneWidget);
    expect(find.byKey(const Key('advanced-devices')), findsOneWidget);
    for (final k in ['deviceKeep-calendar', 'devicePrivate-calendar', 'grant-$botId-calendar']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
    await _open(tester, 'devices');
    for (final k in ['deviceKeep-calendar', 'devicePrivate-calendar', 'grant-$botId-calendar']) {
      expect(find.byKey(Key(k)), findsOneWidget);
    }
    // Only kinds that are on have settings.
    expect(find.byKey(const Key('deviceKeep-contacts')), findsNothing);
  });

  testWidgets('use this computer: commands, local MCP and coding agents are folded', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final companion = FakeCompanion()..codingAgents = ['codex'];
    await tester.pumpWidget(companionHarness(FakeBackend(), companion, MemoryTokens(), const CompanionScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pairComputer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('companionEnabled')), findsOneWidget);
    expect(find.byKey(const Key('cap-files')), findsOneWidget);
    expect(find.byKey(const Key('cap-browser')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('advanced-companion')), 200, scrollable: _page);
    for (final k in ['cap-shell', 'cap-mcp', 'addLocalMcp', 'codingAgent-codex']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
    await _open(tester, 'companion');
    for (final k in ['cap-shell', 'cap-mcp', 'addLocalMcp', 'codingAgent-codex']) {
      await tester.scrollUntilVisible(find.byKey(Key(k)), 200, scrollable: _page);
      expect(find.byKey(Key(k)), findsOneWidget);
    }
  });

  group('every opened section fits a 375x667 phone:', () {
    late FakeBackend backend;
    setUp(() async {
      backend = FakeBackend();
      await backend.connectApp(orgId, appId: 'stripe', method: 'api_key', apiKey: 'k');
      backend.grants.add(DeviceGrant(botId: botId, botName: 'Pal', kind: DeviceKind.calendar, createdAt: DateTime(2026)));
    });

    testWidgets('apps', (tester) async {
      await setSize(tester, const Size(375, 667));
      await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
      await tester.pumpAndSettle();
      await _open(tester, 'integrations');
      await tester.scrollUntilVisible(find.byKey(const Key('addIntegration')), 300, scrollable: _page);
    });

    testWidgets('a connection', (tester) async {
      await setSize(tester, const Size(375, 667));
      await tester.pumpWidget(harness(backend, const IntegrationDetailScreen(integrationId: 'app-stripe')));
      await tester.pumpAndSettle();
      await _open(tester, 'integration.tools');
      await tester.scrollUntilVisible(find.byKey(const Key('disconnectIntegration')), 300, scrollable: _page);
    });

    testWidgets('device connections', (tester) async {
      await setSize(tester, const Size(375, 667));
      await tester.pumpWidget(
        harness(backend, const DeviceConnectionsScreen(), overrides: [deviceCollectorProvider.overrideWithValue(FakeCollector()), deviceTriggerPlatformProvider.overrideWithValue(FakeTriggers())]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deviceSwitch-calendar')));
      await tester.pumpAndSettle();
      await _open(tester, 'devices');
      await tester.scrollUntilVisible(find.byKey(const Key('grant-$botId-calendar')), 300, scrollable: _page);
    });

    testWidgets('use this computer', (tester) async {
      await setSize(tester, const Size(375, 667));
      final companion = FakeCompanion()..codingAgents = ['claude', 'codex'];
      await tester.pumpWidget(companionHarness(backend, companion, MemoryTokens(), const CompanionScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pairComputer')));
      await tester.pumpAndSettle();
      await _open(tester, 'companion');
      await tester.scrollUntilVisible(find.byKey(const Key('allowCodingAgents')), 300, scrollable: _page);
      await tester.scrollUntilVisible(find.byKey(const Key('addLocalMcp')), 300, scrollable: _page);
    });

    testWidgets('add key', (tester) async {
      await setSize(tester, const Size(375, 667));
      await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<ProviderId>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<ProviderId>));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('moreProviders')), findsOneWidget);
    });
  });
}
