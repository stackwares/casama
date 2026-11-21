import 'dart:async';

// The bot profile (who it is, a row of four shortcuts, settings in short sections with Advanced folded
// away and Archive at the end) and the slim chat header (call, new chat, … with conversations and
// the profile).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/bot_profile_screen.dart';
import 'package:casama/features/bots/model_picker.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/ui/shell_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// A bot that's waiting for an answer.
class _WaitingBackend extends FakeBackend {
  @override
  Future<List<Bot>> bots(String orgId) async => [bot(status: BotStatusEnum.waiting)];
}

/// The profile at its real path, with the pages its tiles open stubbed out.
Widget _profileApp(FakeBackend backend, GoRouter router) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(const NoCache())],
  child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
);

GoRouter _router() => GoRouter(
  initialLocation: '/bots/$botId/settings',
  routes: [
    GoRoute(
      path: '/bots/:botId/settings',
      builder: (_, s) => BotProfileScreen(botId: s.pathParameters['botId']!),
    ),
    for (final page in const ['memory', 'routines', 'integrations', 'activity'])
      GoRoute(
        path: '/bots/:botId/$page',
        builder: (_, s) => Scaffold(body: Text('$page ${s.pathParameters['botId']}')),
      ),
    GoRoute(
      path: '/computer',
      builder: (_, s) => Scaffold(body: Text('computer ${s.uri.queryParameters['bot']}')),
    ),
  ],
);

void main() {
  testWidgets('on Casama Cloud the model fields never flash up while billing loads', (tester) async {
    await setSize(tester, const Size(800, 2400));
    final gate = Completer<void>();
    final backend = FakeBackend()
      ..billingEnabled = true
      ..billingGate = gate;
    await tester.pumpWidget(_profileApp(backend, _router()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ModelPickerField), findsNothing, reason: 'not before billing says who picks the model');
      expect(find.byKey(const Key('botProfileModel')), findsNothing);
    }
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ModelPickerField), findsNothing);
  });

  testWidgets('self-hosted, the model fields show once billing has loaded', (tester) async {
    await setSize(tester, const Size(800, 2400));
    await tester.pumpWidget(_profileApp(FakeBackend(), _router()));
    await tester.pumpAndSettle();
    expect(find.byType(ModelPickerField), findsOneWidget);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [Size(375, 667), Size(1200, 900)]) {
    testWidgets('the four tiles open the bot\'s computer, memory, routines and apps (${size.width.toInt()} wide)', (tester) async {
      await setSize(tester, size);
      final router = _router();
      await tester.pumpWidget(_profileApp(FakeBackend(), router));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final (tile, page) in const [('computer', 'computer $botId'), ('memory', 'memory $botId'), ('routines', 'routines $botId'), ('apps', 'integrations $botId')]) {
        await tester.tap(find.byKey(Key('botTile-$tile')));
        await tester.pumpAndSettle();
        expect(find.text(page), findsOneWidget, reason: tile);
        router.pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('the tiles sit in one row, on a phone too', (tester) async {
    double rowsOf(WidgetTester tester) => {
      for (final t in ['computer', 'memory', 'routines', 'apps']) tester.getTopLeft(find.byKey(Key('botTile-$t'))).dy,
    }.length.toDouble();

    await setSize(tester, const Size(375, 667));
    await tester.pumpWidget(_profileApp(FakeBackend(), _router()));
    await tester.pumpAndSettle();
    expect(rowsOf(tester), 1);

    await setSize(tester, const Size(1200, 900));
    await tester.pumpAndSettle();
    expect(rowsOf(tester), 1);
  });

  testWidgets('on Casama Cloud the profile has no key or model to choose, but still sets how much the bot does on its own', (tester) async {
    await setSize(tester, const Size(430, 4400));
    await tester.pumpWidget(harness(FakeBackend()..billingEnabled = true, const BotProfileScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Brain'), findsOneWidget);
    expect(find.text('Model key'), findsNothing);
    expect(find.byKey(const Key('modelPicker')), findsNothing);
    expect(find.byKey(const Key('autonomy-ask_risky')), findsOneWidget);
    // Casama chooses the model, so its name isn't shown under the bot's name either.
    expect(tester.widget<Text>(find.byKey(const Key('botProfileStatus'))).data, isNot(contains('·')));
  });

  testWidgets('on a self-hosted server the profile lets you choose the key and model', (tester) async {
    await setSize(tester, const Size(430, 4400));
    await tester.pumpWidget(harness(FakeBackend(), const BotProfileScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Model key'), findsOneWidget);
    expect(find.byKey(const Key('modelPicker')), findsOneWidget);
  });

  testWidgets('a connected ChatGPT plan can be picked as the bot\'s key', (tester) async {
    await setSize(tester, const Size(430, 4400));
    final backend = FakeBackend()..extraCredentials = [chatGptCredential(orgId)];
    await tester.pumpWidget(harness(backend, const BotProfileScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('botKey-2-false')));
    await tester.pumpAndSettle();
    expect(find.text('ChatGPT plan · ChatGPT'), findsWidgets);
  });

  testWidgets('the profile shows who the bot is and its settings in sections; Advanced opens in place', (tester) async {
    await setSize(tester, const Size(430, 4400)); // tall enough to build every row with Advanced open
    await tester.pumpWidget(harness(FakeBackend(), const BotProfileScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Bot profile'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('botProfileName'))).data, 'Ada');
    expect(find.byKey(const Key('botProfileStatus')), findsOneWidget);
    for (final section in ['Profile', 'Brain', 'Abilities', 'Schedule', 'Advanced']) {
      expect(find.text(section), findsOneWidget, reason: section);
    }
    // Every everyday control is in its section, and sharing and archiving need no digging.
    for (final key in ['loadPersona', 'botFolder', 'botSharing', 'autonomy-ask_risky', 'botComputer', 'botVoice', 'botKnowledge', 'botTile-library', 'botCheckins', 'botQuiet', 'archiveBot']) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    // Sharing sits with the profile; Archive is alone at the very end, after Advanced.
    expect(tester.getTopLeft(find.byKey(const Key('botSharing'))).dy, lessThan(tester.getTopLeft(find.text('Brain')).dy));
    expect(tester.getTopLeft(find.byKey(const Key('archiveBot'))).dy, greaterThan(tester.getTopLeft(find.byKey(const Key('advanced-bot.advanced'))).dy));
    // Memory, routines and apps are tiles now, not rows.
    expect(find.text('Integrations for this bot'), findsNothing);

    // Advanced starts folded, saying what's inside.
    const advanced = ['botRules', 'botWatchers', 'botPlugins', 'botChatApps', 'botLinks', 'botA2a', 'shareBot', 'botActivity', 'botReplays', 'botHistory', 'rerunSetup'];
    for (final key in advanced) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    expect(find.text('Chat apps, links, rules, watchers, plugins, activity'), findsOneWidget);
    await tester.tap(find.byKey(const Key('advanced-bot.advanced')));
    await tester.pumpAndSettle();
    for (final key in advanced) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    // Archive still comes last.
    expect(tester.getTopLeft(find.byKey(const Key('archiveBot'))).dy, greaterThan(tester.getTopLeft(find.byKey(const Key('rerunSetup'))).dy));

    await tester.tap(find.byKey(const Key('advanced-bot.advanced')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botActivity')), findsNothing);
    expect(find.byKey(const Key('archiveBot')), findsOneWidget);
  });

  testWidgets('Activity opens from the profile\'s Advanced section', (tester) async {
    await setSize(tester, const Size(430, 3200));
    final router = _router();
    await tester.pumpWidget(_profileApp(FakeBackend(), router));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('botActivity')), findsNothing);
    await tester.tap(find.byKey(const Key('advanced-bot.advanced')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('botActivity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botActivity')));
    await tester.pumpAndSettle();
    expect(find.text('activity $botId'), findsOneWidget);
  });

  testWidgets('a new name is saved with the same Save button', (tester) async {
    await setSize(tester, const Size(430, 3200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BotProfileScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Bot name'), 'Ada Lovelace');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('botProfileName'))).data, 'Ada Lovelace'); // the header follows the field
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(backend.botUpdate?.botId, botId);
    expect(backend.botUpdate?.name, 'Ada Lovelace');
    expect(find.text('Saved.'), findsOneWidget);
  });

  testWidgets('Back with unsaved edits asks first: Keep editing stays, Discard leaves', (tester) async {
    await setSize(tester, const Size(430, 3200));
    final router = GoRouter(
      initialLocation: '/bots',
      routes: [
        GoRoute(
          path: '/bots',
          builder: (_, _) => const Scaffold(body: Text('bots list')),
          routes: [GoRoute(path: ':botId/settings', builder: (_, s) => BotProfileScreen(botId: s.pathParameters['botId']!))],
        ),
      ],
    );
    await tester.pumpWidget(_profileApp(FakeBackend(), router));
    await tester.pumpAndSettle();
    unawaited(router.push('/bots/$botId/settings'));
    await tester.pumpAndSettle();
    // No edits: Back just leaves.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('bots list'), findsOneWidget);

    unawaited(router.push('/bots/$botId/settings'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Bot name'), 'Ada Lovelace');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(BotProfileScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ada Lovelace'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botProfileDiscard')));
    await tester.pumpAndSettle();
    expect(find.byType(BotProfileScreen), findsNothing);
    expect(find.text('bots list'), findsOneWidget);
  });

  testWidgets('the chat header has call, new chat and a … menu with conversations and the bot profile', (tester) async {
    await setSize(tester, const Size(430, 932));
    await tester.pumpWidget(harness(FakeBackend(), const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('callButton')), findsOneWidget);
    expect(find.byKey(const Key('newChatButton')), findsOneWidget);
    expect(find.byIcon(LucideIcons.history), findsNothing);
    expect(find.byTooltip('Conversations'), findsNothing);
    expect(find.byKey(const Key('chatComputerLive')), findsNothing);
    // Call comes before new chat, and the menu is last.
    expect(tester.getTopLeft(find.byKey(const Key('callButton'))).dx, lessThan(tester.getTopLeft(find.byKey(const Key('newChatButton'))).dx));
    expect(tester.getTopLeft(find.byKey(const Key('newChatButton'))).dx, lessThan(tester.getTopLeft(find.byKey(const Key('chatMoreMenu'))).dx));

    await tester.tap(find.byKey(const Key('chatMoreMenu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('openConversations')), findsOneWidget);
    expect(find.byKey(const Key('openComputer')), findsOneWidget);
    // Activity lives under the profile's Advanced now.
    expect(find.byKey(const Key('openActivity')), findsNothing);
    expect(find.text('Bot profile'), findsOneWidget);
    expect(find.text('Memory'), findsNothing);
    expect(find.text('Routines'), findsNothing);
    expect(find.text('Integrations for this bot'), findsNothing);

    // Topics (D-253): General and the topics under it, with New topic.
    await tester.tap(find.byKey(const Key('openConversations')));
    await tester.pumpAndSettle();
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('New topic'), findsWidgets);
  });

  testWidgets('an idle bot\'s chat header shows no subtitle, not its model', (tester) async {
    await setSize(tester, const Size(430, 932));
    await tester.pumpWidget(harness(FakeBackend(), const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(tester.widget<ShellHeader>(find.byType(ShellHeader)).subtitle, isNull);
    expect(find.text('fixture'), findsNothing); // the bot's model id
  });

  testWidgets('a bot waiting for you says so under its name', (tester) async {
    await setSize(tester, const Size(430, 932));
    final backend = _WaitingBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(tester.widget<ShellHeader>(find.byType(ShellHeader)).subtitle, 'Waiting for you');
  });

  testWidgets('on desktop the … menu leaves the computer to the panel toggle', (tester) async {
    await setSize(tester, const Size(1300, 900));
    await tester.pumpWidget(harness(FakeBackend(), const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('computerPanelToggle')), findsOneWidget);
    expect(find.byKey(const Key('newChatButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chatMoreMenu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('openConversations')), findsOneWidget);
    expect(find.byKey(const Key('openComputer')), findsNothing);
    expect(find.text('Bot profile'), findsOneWidget);
  });

  for (final (label, size) in const [('phone', Size(430, 932)), ('desktop', Size(1300, 900))]) {
    testWidgets('a live dot shows while the bot works on its computer ($label)', (tester) async {
      await setSize(tester, size);
      final backend = FakeBackend();
      await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('messageInput')), 'Tidy up my downloads folder');
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      backend.runEventsController.add(ev(1, 'run.started', {'trigger': 'chat', 'model': 'm', 'computer_id': null}));
      await tester.pump();
      expect(tester.widget<ShellHeader>(find.byType(ShellHeader)).subtitle, 'Working');
      // Working, but not on the computer yet.
      expect(find.byKey(const Key('chatComputerLive')), findsNothing);
      // New chat waits while the bot works.
      expect(tester.widget<IconButton>(find.descendant(of: find.byKey(const Key('newChatButton')), matching: find.byType(IconButton))).onPressed, isNull);

      backend.runEventsController.add(
        ev(2, 'tool.started', {
          'call_id': 'c1',
          'tool': 'shell.exec',
          'args_redacted': {'command': 'ls ~/Downloads'},
        }),
      );
      await tester.pump();
      expect(find.byKey(const Key('chatComputerLive')), findsOneWidget);
      if (label == 'phone') {
        expect(find.byTooltip('Working on its computer'), findsOneWidget);
        // It sits before Call.
        expect(tester.getTopLeft(find.byTooltip('Working on its computer')).dx, lessThan(tester.getTopLeft(find.byKey(const Key('callButton'))).dx));
      } else {
        expect(find.byTooltip('Working on its computer'), findsNothing);
        expect(find.descendant(of: find.byKey(const Key('computerPanelToggle')).hitTestable(), matching: find.byType(IconButton)), findsOneWidget);
      }

      backend.runEventsController
        ..add(ev(3, 'tool.completed', {'call_id': 'c1', 'result_preview': 'ok', 'artifact_path': null, 'duration_ms': 10}))
        ..add(ev(4, 'message.delta', {'message_id': 'a1', 'text': 'Done.'}))
        ..add(ev(5, 'run.completed', {'final_message_id': 'a1'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('chatComputerLive')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
