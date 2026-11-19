import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/chat_widgets.dart';
import 'package:casama/features/chat/widgets/mentions.dart';
import 'package:casama/features/groups/group_chats.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

Integration _integration(
  String id,
  String name, {
  IntegrationKind kind = IntegrationKind.mcp,
  String? appId,
  IntegrationStatusEnum status = IntegrationStatusEnum.ok,
}) => Integration(
  id: id,
  orgId: orgId,
  kind: kind,
  name: name,
  appId: appId,
  status: status,
  error: null,
  tools: const [],
  toolsCachedAt: null,
  createdAt: DateTime(2026),
);

/// End-to-end widget tests for @mentioning connected apps (D-434).
void main() {
  test('groupAnswerers follows the server: named bots, else last speaker, else lead; null for everyone', () {
    final fake = FakeBackend();
    final ada = fake.bot(id: 'a', name: 'Ada');
    final writer = fake.bot(id: 'w', name: 'Writer');
    final bots = [ada, writer];
    expect(groupAnswerers(bots, '@Writer draft it @gma')?.map((b) => b.id), ['w']);
    expect(groupAnswerers(bots, 'hi @gma', lastSpeakerId: 'w', leadId: 'a')?.map((b) => b.id), ['w']);
    expect(groupAnswerers(bots, 'hi', leadId: 'a')?.map((b) => b.id), ['a']);
    expect(groupAnswerers(bots, 'mail me at x@writer.com', leadId: 'a')?.map((b) => b.id), ['a']);
    expect(groupAnswerers(bots, '@everyone go'), isNull);
  });

  testWidgets(
    'direct chat @ menu shows attached direct + hub apps, Add to this bot, and Connect after 2 chars',
    (tester) async {
      final backend = FakeBackend();
      backend.integrationList.addAll([
        _integration('int-linear', 'Linear', appId: 'linear'),
        _integration(
          'int-composio',
          'Composio',
          kind: IntegrationKind.composio,
        ),
        _integration('int-notion', 'Notion', appId: 'notion'),
      ]);
      backend.providerConnects.add('gmail');
      // Attach Linear and Composio to bot-1; leave Notion unattached in workspace.
      backend.attached.addAll(['int-linear', 'int-composio']);

      final input = TextEditingController();
      addTearDown(input.dispose);
      final mentions = MentionController(input);
      addTearDown(mentions.dispose);

      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: Column(
              children: [
                MentionPicker(
                  botIds: const [botId],
                  group: false,
                  controller: mentions,
                ),
                TextField(key: const Key('in'), controller: input),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Typing "@" shows attached apps (Linear + Composio's Gmail) and Add to this bot (Notion).
      // Connect section must NOT appear yet (< 2 typed letters).
      input.text = 'check @';
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mentionPicker')), findsOneWidget);
      expect(find.byKey(const Key('mention-app-int-linear')), findsOneWidget);
      expect(
        find.byKey(const Key('mention-app-int-composio:gmail')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mention-add-int-notion')), findsOneWidget);
      expect(find.byKey(const Key('mention-connect-stripe')), findsNothing);
      // Direct chat must NOT show @everyone or bots.
      expect(find.byKey(const Key('mention-everyone')), findsNothing);

      // 1 char after "@" still hides Connect.
      input.text = 'check @s';
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mention-connect-stripe')), findsNothing);

      // 2 chars after "@" reveals Connect (Stripe is in FakeBackend.catalog, unconnected).
      input.text = 'check @st';
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mention-connect-stripe')), findsOneWidget);

      // Tapping an "Add to this bot" row attaches the integration and inserts @Notion.
      input.text = 'check @no';
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mention-add-int-notion')));
      await tester.pumpAndSettle();
      expect(backend.attached, contains('int-notion'));
      expect(input.text, 'check @Notion ');
      expect(mentions.pickedApps.map((a) => a.integrationId), ['int-notion']);
    },
  );

  testWidgets(
    'picking apps caps at 3 per message and auto-prunes when deleted from draft text',
    (tester) async {
      final backend = FakeBackend();
      backend.integrationList.addAll([
        _integration('int-1', 'Linear'),
        _integration('int-2', 'Notion'),
        _integration('int-3', 'Stripe'),
        _integration('int-4', 'GitHub'),
      ]);
      backend.attached.addAll(['int-1', 'int-2', 'int-3', 'int-4']);

      final input = TextEditingController();
      addTearDown(input.dispose);
      final mentions = MentionController(input);
      addTearDown(mentions.dispose);

      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: Column(
              children: [
                MentionPicker(
                  botIds: const [botId],
                  group: false,
                  controller: mentions,
                ),
                TextField(key: const Key('in'), controller: input),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final (q, key) in [
        ('@Li', 'mention-app-int-1'),
        ('@No', 'mention-app-int-2'),
        ('@St', 'mention-app-int-3'),
      ]) {
        input.text = '${input.text}$q';
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }
      expect(mentions.pickedApps.length, 3);

      // Picking a 4th app hits the 3-app cap and does not add a 4th ref.
      input.text = '${input.text}@Gi';
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mention-app-int-4')));
      await tester.pumpAndSettle();
      expect(mentions.pickedApps.length, 3);
      expect(mentions.pickedApps.map((a) => a.integrationId), [
        'int-1',
        'int-2',
        'int-3',
      ]);

      // Deleting @Notion from the draft auto-prunes it and frees up a slot.
      input.text = '@Linear @Stripe @Gi';
      await tester.pumpAndSettle();
      expect(mentions.pickedApps.map((a) => a.integrationId), [
        'int-1',
        'int-3',
      ]);

      await tester.tap(find.byKey(const Key('mention-app-int-4')));
      await tester.pumpAndSettle();
      expect(mentions.pickedApps.map((a) => a.integrationId), [
        'int-1',
        'int-3',
        'int-4',
      ]);
    },
  );

  testWidgets(
    'direct chat shows @ app hint only when apps are connected and forwards picked apps on send',
    (tester) async {
      final backend = FakeBackend();
      await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
      await tester.pumpAndSettle();

      // 0 apps attached -> plain "Message Ada" placeholder.
      expect(find.text('Message Ada'), findsOneWidget);
      expect(find.textContaining('@ to mention an app'), findsNothing);

      // Attach an app and re-pump a fresh chat screen.
      backend.integrationList.add(
        _integration('int-stripe', 'Stripe', appId: 'stripe'),
      );
      backend.attached.add('int-stripe');

      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(key: ValueKey('with-apps'), botId: botId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Message Ada · @ to mention an app'), findsOneWidget);

      // Type "@St", pick Stripe, type the rest, and send.
      final composer = find.byKey(const Key('messageInput'));
      await tester.enterText(composer, 'check @St');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mention-app-int-stripe')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      await tester.pump();

      expect(backend.sentApps, isNotEmpty);
      expect(backend.sentApps.last.length, 1);
      expect(backend.sentApps.last.first.integrationId, 'int-stripe');
      expect(backend.sentApps.last.first.toolkit, isNull);
    },
  );

  testWidgets(
    'app pills render in UserBubble, open settings on tap, ignore emails, and grey out removed apps',
    (tester) async {
      final backend = FakeBackend();
      final openedApps = <String>[];
      const liveApp = AppMentionInfo(
        integrationId: 'int-stripe',
        label: 'Stripe',
        appId: 'stripe',
        color: '635BFF',
        kind: IntegrationKind.mcp,
      );

      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: MentionScope(
              apps: const [liveApp],
              knownIntegrationIds: const {'int-stripe'},
              onOpenApp: openedApps.add,
              child: const Column(
                children: [
                  UserBubble(
                    text: 'check @Stripe and mail user@stripe.com',
                    apps: [
                      MessageAppMention(
                        integrationId: 'int-stripe',
                        label: 'Stripe',
                        appId: 'stripe',
                        source: 'picker',
                      ),
                    ],
                  ),
                  UserBubble(
                    text: 'old @LegacyCRM lookup',
                    apps: [
                      MessageAppMention(
                        integrationId: 'int-deleted',
                        label: 'LegacyCRM',
                        source: 'picker',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Live Stripe pill renders and opens /settings/integrations/int-stripe on tap.
      expect(find.byKey(const Key('mention-app-int-stripe')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mention-app-int-stripe')));
      expect(openedApps, ['int-stripe']);

      // Removed integration renders as a non-tappable pill (tapping does not invoke onOpenApp).
      expect(find.byKey(const Key('mention-app-int-deleted')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mention-app-int-deleted')));
      expect(openedApps, ['int-stripe']);

      // Exactly 2 MentionChips total: Stripe + LegacyCRM (user@stripe.com stayed plain text).
      expect(find.byType(MentionChip), findsNWidgets(2));
    },
  );

  testWidgets(
    'group chat collision shows Bot and App badges in picker and respects explicit picker ref in bubble',
    (tester) async {
      final backend = FakeBackend();
      final linearBot = backend.bot(id: 'bot-linear', name: 'Linear');
      backend.extraBots.add(linearBot);
      backend.integrationList.add(
        _integration('int-linear', 'Linear', appId: 'linear'),
      );
      backend.attached.add('int-linear');

      final input = TextEditingController();
      addTearDown(input.dispose);
      final mentions = MentionController(input);
      addTearDown(mentions.dispose);

      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: Column(
              children: [
                MentionPicker(
                  botIds: const [botId, 'bot-linear'],
                  group: true,
                  controller: mentions,
                ),
                Focus(
                  onKeyEvent: (_, e) => mentions.handleKey(e),
                  child: TextField(key: const Key('in'), controller: input),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('in')));
      await tester.enterText(find.byKey(const Key('in')), 'ask @Lin');
      await tester.pumpAndSettle();

      // Both Bot "Linear" and App "Linear" show with clear Bot / App badges.
      expect(find.byKey(const Key('mention-Linear')), findsOneWidget);
      expect(find.byKey(const Key('mention-app-int-linear')), findsOneWidget);
      expect(find.text('Bot'), findsOneWidget);
      expect(find.text('App'), findsOneWidget);

      // Keyboard arrowDown moves from Bot Linear -> App Linear; Tab picks the app.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(input.text, 'ask @Linear ');
      expect(mentions.pickedApps.length, 1);
      expect(mentions.pickedApps.first.integrationId, 'int-linear');
      expect(mentions.pickedApps.first.source, 'picker');

      // In UserBubble: explicit picker app ref renders as App pill; plain text renders as Bot pill.
      final openedBots = <Bot>[];
      final openedApps = <String>[];
      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: MentionScope(
              bots: [linearBot],
              apps: const [
                AppMentionInfo(
                  integrationId: 'int-linear',
                  label: 'Linear',
                  appId: 'linear',
                  kind: IntegrationKind.mcp,
                ),
              ],
              onOpen: openedBots.add,
              onOpenApp: openedApps.add,
              child: const Column(
                children: [
                  UserBubble(text: 'plain @Linear'),
                  UserBubble(
                    text: 'picked @Linear',
                    apps: [
                      MessageAppMention(
                        integrationId: 'int-linear',
                        label: 'Linear',
                        appId: 'linear',
                        source: 'picker',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mention-bot-linear')));
      await tester.tap(find.byKey(const Key('mention-app-int-linear')));
      expect(openedBots, [linearBot]);
      expect(openedApps, ['int-linear']);
    },
  );
}
