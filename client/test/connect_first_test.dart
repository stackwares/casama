// Connecting apps first (D-204): a connection made from a welcome card reports back to the chat,
// and an empty chat offers one-tap tiles for the apps most people connect first.
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/local_actions.dart';
import 'package:casama_app/features/chat/widgets/app_tiles.dart';
import 'package:casama_app/features/chat/widgets/bot_ui.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('connecting from a welcome card sends the card\'s next step to the chat', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend();
    late WidgetRef ref0;
    late BuildContext ctx0;
    await tester.pumpWidget(
      harness(
        backend,
        Consumer(
          builder: (context, ref, _) {
            // The connect sheet connects to the current workspace.
            ref.watch(currentOrgProvider);
            ref0 = ref;
            ctx0 = context;
            return const Scaffold(body: Text('chat'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final sent = <BotUiAction>[];
    const card = BotUiAction(
      surfaceId: 's1',
      name: 'app:connect',
      context: {'app': 'cloudflare', 'after': 'welcome.connected'},
      sourceComponentId: 'cal',
    );
    final done = handleLocalUiAction(ctx0, ref0, card, send: (a) async => sent.add(a));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('connectAppSubmit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('connectDone')));
    await tester.pumpAndSettle();
    expect(await done, isTrue);
    expect(sent.single.name, 'welcome.connected');
    expect(sent.single.surfaceId, 's1');
    expect(sent.single.context, {'app': 'cloudflare'});
    expect(uiActionSummary(sent.single), 'Connected Cloudflare Docs');
  });

  testWidgets('closing the connect sheet without connecting sends nothing', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend();
    late WidgetRef ref0;
    late BuildContext ctx0;
    await tester.pumpWidget(
      harness(
        backend,
        Consumer(
          builder: (context, ref, _) {
            // The connect sheet connects to the current workspace.
            ref.watch(currentOrgProvider);
            ref0 = ref;
            ctx0 = context;
            return const Scaffold(body: Text('chat'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final sent = <BotUiAction>[];
    final done = handleLocalUiAction(
      ctx0,
      ref0,
      const BotUiAction(
        surfaceId: 's1',
        name: 'app:connect',
        context: {'app': 'cloudflare', 'after': 'welcome.connected'},
        sourceComponentId: 'cal',
      ),
      send: (a) async => sent.add(a),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(const Key('connectAppSubmit')))).pop();
    await tester.pumpAndSettle();
    expect(await done, isTrue);
    expect(sent, isEmpty);
  });

  testWidgets('an empty chat offers one-click apps until two are connected', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend();
    backend.catalog.addAll([
      FakeBackend.catalogApp('gmail', 'Gmail', [CatalogAppAuthEnum.managed], color: 'EA4335'),
      FakeBackend.catalogApp('google_calendar', 'Google Calendar', [CatalogAppAuthEnum.managed], color: '4285F4'),
      // Needs a key here, so it isn't one tap and isn't offered.
      FakeBackend.catalogApp('github', 'GitHub', [CatalogAppAuthEnum.apiKey], color: '181717'),
      // Its own sign-in isn't set up on this server.
      FakeBackend.catalogApp('slack', 'Slack', [CatalogAppAuthEnum.oauth], color: '4A154B', oauthAvailable: false),
    ]);
    await tester.pumpWidget(harness(backend, const Scaffold(body: ConnectAppTiles())));
    await tester.pumpAndSettle();
    expect(find.text('Connect your apps'), findsOneWidget);
    for (final id in ['gmail', 'google_calendar', 'notion']) {
      expect(find.byKey(Key('connectTile-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('connectTile-github')), findsNothing);
    expect(find.byKey(const Key('connectTile-slack')), findsNothing);
    // Tiles follow the starter order: Gmail first.
    expect(
      tester.getTopLeft(find.byKey(const Key('connectTile-gmail'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const Key('connectTile-notion'))).dx),
    );

    // One connected: it drops out, the rest stay.
    await backend.connectApp(orgId, appId: 'notion', method: 'none');
    await tester.pumpWidget(harness(backend, const Scaffold(body: ConnectAppTiles(key: ValueKey(2)))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('connectTile-notion')), findsNothing);
    expect(find.byKey(const Key('connectTile-gmail')), findsOneWidget);

    // Two connected: the tiles step aside.
    await backend.connectApp(orgId, appId: 'gmail', method: 'none');
    await tester.pumpWidget(harness(backend, const Scaffold(body: ConnectAppTiles(key: ValueKey(3)))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('connectAppTiles')), findsNothing);
  });

  testWidgets('tapping a tile opens that app\'s connect sheet', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: ConnectAppTiles())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('connectTile-notion')));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Notion'), findsOneWidget);
  });
}
