// Servers that aren't one of Casama's apps, connected from a bot's card in the chat (D-473).
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/local_actions.dart';
import 'package:casama/features/chat/widgets/bot_ui.dart';
import 'package:casama/features/companion/companion.dart';
import 'package:casama/features/companion/companion_controller.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_backend.dart';
import 'app_test.dart' show harness, setSize;
import 'companion_test.dart' show FakeCompanion, MemoryMcp, MemoryTokens;

/// A chat-like screen, and the context and ref a card's button is handled with.
Future<(BuildContext, WidgetRef)> _chat(
  WidgetTester tester,
  FakeBackend backend, {
  List<dynamic> overrides = const [],
}) async {
  await setSize(tester, const Size(700, 1400));
  late WidgetRef ref0;
  late BuildContext ctx0;
  await tester.pumpWidget(
    harness(
      backend,
      Consumer(
        builder: (context, ref, _) {
          ref.watch(currentOrgProvider);
          ref0 = ref;
          ctx0 = context;
          return const Scaffold(body: Text('chat'));
        },
      ),
      overrides: overrides,
    ),
  );
  await tester.pumpAndSettle();
  return (ctx0, ref0);
}

/// The button a bot's card sends for a server: a route, with the server beside it.
BotUiAction _card(
  Map<String, Object?> server, {
  String path = '/settings/integrations',
}) => BotUiAction(
  surfaceId: 's1',
  name: 'app:route',
  context: {'path': path, 'server': server, 'bot': 'bot-1'},
  sourceComponentId: 's_0',
);

void main() {
  testWidgets(
    'a server from a card connects in the chat, for that bot, with the tools the person left on',
    (tester) async {
      final backend = FakeBackend();
      final (ctx, ref) = await _chat(tester, backend);
      final sent = <BotUiAction>[];
      final done = handleLocalUiAction(
        ctx,
        ref,
        _card({'name': 'Acme CRM', 'url': 'https://mcp.acme.example/mcp'}),
        send: (a) async => sent.add(a),
      );
      await tester.pumpAndSettle();
      // Who it is and that nobody checked it, before anything connects.
      expect(find.text('mcp.example.com'), findsOneWidget);
      expect(find.byKey(const Key('serverNotChecked')), findsOneWidget);
      expect(find.byKey(const Key('serverKey')), findsNothing);
      await tester.tap(find.byKey(const Key('connectServerSubmit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('serverConnected')), findsOneWidget);
      final call = backend.serverConnects.single;
      expect(
        (call.url, call.name, call.method, call.botId, call.privateUrl),
        ('https://mcp.acme.example/mcp', 'Acme CRM', 'none', 'bot-1', false),
      );

      await tester.tap(find.byKey(const Key('serverTool-delete_things')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('connectServerDone')));
      await tester.pumpAndSettle();
      expect(await done, isTrue);
      expect(backend.toolLimits['srv-Acme CRM'], ['read_things']);
      // The bot hears it's connected, the way it does for an app.
      expect(sent.single.name, 'connected');
      expect(uiActionSummary(sent.single), 'Connected Acme CRM');
    },
  );

  testWidgets(
    'a server that signs in with the browser says where, and takes a key instead when asked',
    (tester) async {
      final backend = FakeBackend()
        ..serverProbe = ProbeServerResponse(
          auth: ProbeServerResponseAuthEnum.oauth,
          host: 'mcp.acme.example',
          signInHost: 'login.acme.example',
          oauthAvailable: true,
        );
      final (ctx, ref) = await _chat(tester, backend);
      final done = handleLocalUiAction(
        ctx,
        ref,
        _card({'name': 'Acme', 'url': 'https://mcp.acme.example/mcp'}),
        send: (_) async {},
      );
      await tester.pumpAndSettle();
      expect(
        find.text("You'll sign in on login.acme.example."),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('serverSwitchMethod')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('serverKey')), 'key-12345');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('connectServerSubmit')));
      await tester.pumpAndSettle();
      expect(backend.serverConnects.single.method, 'api_key');
      expect(backend.serverConnects.single.apiKey, 'key-12345');
      await tester.tap(find.byKey(const Key('connectServerDone')));
      await tester.pumpAndSettle();
      await done;
      // Every tool stayed on: nothing to narrow.
      expect(backend.toolLimits, isEmpty);
    },
  );

  testWidgets(
    'a server that can\'t take a browser sign-in here asks for a key and says why',
    (tester) async {
      final backend = FakeBackend()
        ..serverProbe = ProbeServerResponse(
          auth: ProbeServerResponseAuthEnum.oauth,
          host: 'mcp.acme.example',
          oauthAvailable: false,
        );
      final (ctx, ref) = await _chat(tester, backend);
      handleLocalUiAction(
        ctx,
        ref,
        _card({'name': 'Acme', 'url': 'https://mcp.acme.example/mcp'}),
        send: (_) async {},
      ).ignore();
      await tester.pumpAndSettle();
      expect(
        find.textContaining("can't take a browser sign-in"),
        findsOneWidget,
      );
      expect(find.byKey(const Key('serverKey')), findsOneWidget);
      expect(find.byKey(const Key('serverSwitchMethod')), findsNothing);
    },
  );

  testWidgets(
    'with no address on the card the person types it, and it is kept as a private address',
    (tester) async {
      final backend = FakeBackend();
      final (ctx, ref) = await _chat(tester, backend);
      final sent = <BotUiAction>[];
      handleLocalUiAction(
        ctx,
        ref,
        _card({'name': 'Zed'}),
        send: (a) async => sent.add(a),
      ).ignore();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('connectServerSubmit')), findsNothing);
      // Not an address yet: nowhere to go.
      await tester.enterText(find.byKey(const Key('serverAddress')), 'zed');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('serverAddressNext')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('serverAddress')), findsOneWidget);
      expect(find.byKey(const Key('connectServerSubmit')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('serverAddress')),
        'https://zed.example/mcp?key=abc',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('serverAddressNext')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('connectServerSubmit')));
      await tester.pumpAndSettle();
      final call = backend.serverConnects.single;
      expect(
        (call.url, call.method, call.privateUrl),
        ('https://zed.example/mcp?key=abc', 'none', true),
      );
      // Closing without Done still counts: it is connected.
      expect(find.byKey(const Key('serverConnected')), findsOneWidget);
      expect(sent, isEmpty);
    },
  );

  testWidgets(
    'a server for the person\'s own computer opens that computer\'s form, filled in; elsewhere it says where to add it',
    (tester) async {
      final backend = FakeBackend();
      final mcp = MemoryMcp();
      // Never the real companion: on a desktop test host it would read the real keychain.
      final (ctx, ref) = await _chat(
        tester,
        backend,
        overrides: [
          companionProvider.overrideWithValue(FakeCompanion()),
          deviceTokenStoreProvider.overrideWithValue(MemoryTokens()),
          localMcpStoreProvider.overrideWithValue(mcp),
        ],
      );
      final sent = <BotUiAction>[];
      final card = _card({
        'name': 'Files',
        'command': 'npx',
        'args': ['-y', 'files-mcp'],
      }, path: '/settings/companion');

      // This computer isn't set up to run servers yet: say where, connect nothing.
      var done = handleLocalUiAction(
        ctx,
        ref,
        card,
        send: (a) async => sent.add(a),
      );
      await tester.pumpAndSettle();
      expect(await done, isTrue);
      expect(
        find.textContaining('Files runs on your own computer'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();

      // Set up, with local servers allowed: the form opens with the bot's name and command.
      final controller = ref.read(companionControllerProvider.notifier);
      await controller.pair('This Mac');
      await controller.save(capabilities: {'mcp'});
      await tester.pumpAndSettle();
      done = handleLocalUiAction(
        ctx,
        ref,
        card,
        send: (a) async => sent.add(a),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('localMcpLabel')))
            .controller
            ?.text,
        'Files',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('localMcpCommand')))
            .controller
            ?.text,
        'npx -y files-mcp',
      );
      await tester.tap(find.byKey(const Key('saveLocalMcp')));
      await tester.pumpAndSettle();
      expect(await done, isTrue);
      final saved = mcp.m[orgId]!.single;
      expect((saved.label, saved.command), ('Files', 'npx'));
      expect(saved.args, ['-y', 'files-mcp']);
      expect(backend.serverConnects, isEmpty);
      expect(sent, isEmpty);
    },
  );
}
