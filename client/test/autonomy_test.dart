import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';
import 'package:casama_app/features/integrations/integration_detail_screen.dart';
import 'package:casama_app/features/integrations/integrations_screen.dart';
import 'package:casama_app/features/routines/routines_screen.dart';
import 'package:casama_app/features/settings/secrets_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('approvals inbox approves, denies and always-allows', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen(initialTab: 0)));
    await tester.pumpAndSettle();
    expect(find.text('Approvals (1)'), findsOneWidget);
    expect(find.textContaining('Run a destructive shell command'), findsOneWidget);
    expect(find.text('High risk'), findsOneWidget);

    await tester.tap(find.byKey(const Key('alwaysAllow')));
    await tester.pumpAndSettle();
    expect(backend.decisions, {'appr1': 'always'});
    expect(find.text('Nothing needs your approval right now.'), findsOneWidget);
  });

  testWidgets('the approval deep link shows one request and handles already-decided ones', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ApprovalScreen(approvalId: 'appr1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deny')));
    await tester.pumpAndSettle();
    expect(backend.decisions, {'appr1': 'denied'});
    expect(find.text('This request was already decided or has expired.'), findsOneWidget);
  });

  testWidgets('notifications arrive live and can be marked read', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen(initialTab: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Ada needs approval'), findsOneWidget);

    backend.notificationsController.add(
      NotificationView(id: 'n2', kind: 'routine', title: 'Morning summary is ready', body: 'Three things changed', createdAt: DateTime.now()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Morning summary is ready'), findsOneWidget);

    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(backend.notificationsRead, isTrue);
    expect(find.text('Mark all as read'), findsNothing);
  });

  testWidgets('opening a notification marks it read and lowers the inbox badge', (tester) async {
    final backend = FakeBackend()
      ..storedNotifications = [
        NotificationView(id: 'n3', kind: 'routine', title: 'Morning summary is ready', body: 'Three things changed', createdAt: DateTime.now()),
        NotificationView(id: 'n4', kind: 'budget', title: 'Budget at 80%', body: 'Ada used most of today', createdAt: DateTime.now()),
      ];
    late WidgetRef refOut;
    await tester.pumpWidget(harness(
      backend,
      Consumer(builder: (context, ref, _) {
        refOut = ref;
        return const InboxScreen(initialTab: 1);
      }),
    ));
    await tester.pumpAndSettle();
    final before = refOut.read(inboxBadgeProvider);
    await tester.tap(find.byKey(const Key('notification-n3')));
    await tester.pumpAndSettle();
    expect(backend.readNotifications, ['n3']);
    expect(refOut.read(inboxBadgeProvider), before - 1);
    // Already read: tapping again doesn't call the server.
    await tester.tap(find.byKey(const Key('notification-n3')));
    await tester.pumpAndSettle();
    expect(backend.readNotifications, ['n3']);
  });

  testWidgets('routines: a one-time routine is the default, and routines can be deleted', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineName')), 'Water');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'Remind me to drink water');
    await tester.tap(find.text('In 15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createRoutine')));
    await tester.pumpAndSettle();
    final r = backend.routineList.single;
    expect(r.trigger, RoutineTrigger.once);
    expect(r.scheduleCron, isNull);
    expect(r.nextRunAt!.difference(DateTime.now()).inMinutes, inInclusiveRange(13, 15));

    await tester.tap(find.byKey(Key('routineMenu-${r.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('deleteRoutine-${r.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(backend.deletedRoutines, [r.id]);
  });

  testWidgets('routines: create a schedule in a timezone, run now, and webhook secrets show once', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.textContaining('No routines yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineName')), 'Morning summary');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'Prepare the morning summary');
    await tester.tap(find.text('Repeats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekdays at 9:00'));
    await tester.enterText(find.byKey(const Key('routineTimezone')), 'America/Chicago');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createRoutine')));
    await tester.pumpAndSettle();
    expect(backend.routineList.single.scheduleCron, '0 9 * * 1-5');
    expect(backend.routineList.single.timezone, 'America/Chicago');
    expect(find.textContaining('0 9 * * 1-5 (America/Chicago)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('routineMenu-r1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('runRoutine-r1')));
    await tester.pump();
    expect(backend.routinesRun, ['r1']);
    await tester.pumpAndSettle();

    // Webhook trigger: the signing secret is shown once.
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineName')), 'Deploy hook');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'Check the deploy');
    await tester.tap(find.text('Webhook'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createRoutine')));
    await tester.pumpAndSettle();
    expect(find.text('Webhook created'), findsOneWidget);
    expect(find.textContaining('whsec_test'), findsOneWidget);
  });

  testWidgets('integrations: add an MCP server, test it and attach it to a bot', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addIntegration')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('integrationName')), 'calc');
    await tester.enterText(find.byKey(const Key('integrationPrimary')), 'https://mcp.example.com/mcp');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveIntegration')));
    await tester.pumpAndSettle();
    expect(backend.integrationList.single.name, 'calc');
    expect(find.text('calc'), findsOneWidget);

    await tester.pumpWidget(harness(backend, const IntegrationDetailScreen(integrationId: 'i1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('testIntegration-i1')));
    await tester.pumpAndSettle();
    expect(find.text('Connected, 2 tools'), findsOneWidget);

    await tester.pumpWidget(harness(backend, const BotIntegrationsScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attach-i1')));
    await tester.pumpAndSettle();
    expect(backend.attached, {'i1'});
  });

  testWidgets('apps: connect Stripe with an API key and give it to a bot', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    // No connections yet, so the catalog shows first.
    expect(find.byKey(const Key('featured-stripe')), findsOneWidget);
    await tester.tap(find.byKey(const Key('app-stripe')));
    await tester.pumpAndSettle();
    expect(find.text('What your bots can do'), findsOneWidget);
    await tester.tap(find.text('API key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('appApiKey')), 'rk_test_1234567890');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('connectAppSubmit')));
    await tester.pumpAndSettle();
    expect(backend.connectCalls.single, ('stripe', 'api_key', 'rk_test_1234567890'));
    expect(find.byKey(const Key('appConnected')), findsOneWidget);
    expect(find.text('2 tools are ready for your bots.'), findsOneWidget);
    // Every bot is offered it; Done gives it to the chosen ones.
    await tester.tap(find.byKey(const Key('connectDone')));
    await tester.pumpAndSettle();
    expect(backend.attached, contains('app-stripe'));
    expect(find.text('Stripe'), findsWidgets);
  });

  testWidgets('apps: one-click sign-in waits for the browser, then finishes by itself', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('featured-notion')));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Notion'), findsOneWidget);
    await tester.tap(find.byKey(const Key('connectAppSubmit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Finish signing in to Notion'), findsOneWidget);
    expect(backend.connectCalls.single.$2, 'oauth');
    // First poll: still signing in. Second: connected.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('appConnected')), findsOneWidget);
  });

  testWidgets('apps: an app that needs setup offers a hub like Composio instead', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend();
    backend.catalog
      ..add(FakeBackend.catalogApp('slack', 'Slack', [CatalogAppAuthEnum.oauth], oauthAvailable: false))
      ..add(FakeBackend.catalogApp('composio', 'Composio', [CatalogAppAuthEnum.oauth], popular: false));
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('featured-slack')));
    await tester.pumpAndSettle();
    expect(find.textContaining('needs a one-time setup'), findsOneWidget);
    expect(find.textContaining('Or connect Slack through one of these'), findsOneWidget);
    await tester.tap(find.byKey(const Key('connectVia_composio')));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Composio'), findsOneWidget);
    await tester.tap(find.byKey(const Key('connectAppSubmit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(backend.connectCalls.single, ('composio', 'oauth', null));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('apps: on a plain-http server address, sign-in says it needs https', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend()..catalogRedirectUri = 'http://192.168.1.20:8787/oauth/callback';
    backend.catalog.add(FakeBackend.catalogApp('slack', 'Slack', [CatalogAppAuthEnum.oauth], oauthAvailable: false));
    await tester.pumpWidget(harness(backend, const IntegrationsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('featured-slack')));
    await tester.pumpAndSettle();
    expect(find.textContaining('only signs in on a secure (https) address'), findsOneWidget);
    expect(find.textContaining('http://192.168.1.20:8787'), findsOneWidget);
    expect(find.textContaining('needs a one-time setup'), findsNothing);
  });

  testWidgets('apps: a connection tools can be set to always ask, and it can be disconnected', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend();
    await backend.connectApp(orgId, appId: 'stripe', method: 'api_key', apiKey: 'k');
    await tester.pumpWidget(harness(backend, const IntegrationDetailScreen(integrationId: 'app-stripe')));
    await tester.pumpAndSettle();
    expect(find.text('List customers'), findsOneWidget);
    expect(find.text('Read-only'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toolRisk-list_customers')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Always asks').last);
    await tester.pumpAndSettle();
    expect(backend.toolRisks['app-stripe'], {'list_customers': 'high'});
    await tester.ensureVisible(find.byKey(const Key('disconnectIntegration')));
    await tester.tap(find.byKey(const Key('disconnectIntegration')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDisconnect')));
    await tester.pumpAndSettle();
    expect(backend.deleted, ['app-stripe']);
  });

  testWidgets('secrets are added with allowed hosts and never shown', (tester) async {
    await setSize(tester, const Size(700, 1100));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SecretsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addSecret')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('secretName')), 'GITHUB_TOKEN');
    await tester.enterText(find.byKey(const Key('secretValue')), 'ghp_supersecret');
    await tester.enterText(find.byKey(const Key('secretHosts')), 'api.github.com');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveSecret')));
    await tester.pumpAndSettle();
    expect(find.text('GITHUB_TOKEN'), findsOneWidget);
    expect(find.text('Only sent to api.github.com'), findsOneWidget);
    expect(find.textContaining('ghp_supersecret'), findsNothing);
  });

  testWidgets('sign-in code secrets are added as totp (D-102)', (tester) async {
    await setSize(tester, const Size(700, 1100));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SecretsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addSecret')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign-in code'));
    await tester.pumpAndSettle();
    expect(find.text('Two-step key or otpauth:// link'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('secretName')), 'ACME_2FA');
    await tester.enterText(find.byKey(const Key('secretValue')), 'otpauth://totp/Acme?secret=JBSWY3DPEHPK3PXP');
    await tester.enterText(find.byKey(const Key('secretHosts')), 'acme.example');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveSecret')));
    await tester.pumpAndSettle();
    expect(backend.secretList.single.kind.value, 'totp');
    expect(find.text('Sign-in code · Only sent to acme.example'), findsOneWidget);
  });

  testWidgets('creating a bot from a template sends the template id', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Consumer(builder: (context, ref, _) => TextButton(onPressed: () => showCreateBot(context, ref), child: const Text('open'))),
        ),
      ),
      GoRoute(path: '/bots/:id/chat', builder: (_, _) => const Text('chat opened')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personaPicker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('template-daily-briefing')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Includes routines: Morning summary.'), findsOneWidget);
    // The persona's instructions fill in, ready to edit.
    expect(tester.widget<TextField>(find.byKey(const Key('botInstructions'))).controller!.text, 'You prepare short briefings.');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    expect(backend.createdBotTemplate, 'daily-briefing');
    expect(find.text('chat opened'), findsOneWidget);
  });

  testWidgets('a paused run shows an approval card in the chat', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'clean the system folder');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController
      ..add(ev(1, 'tool.started', {'call_id': 'c1', 'tool': 'shell.exec', 'args_redacted': {'cmd': 'rm -rf /data/old'}}))
      ..add(ev(2, 'approval.requested', {
        'approval_id': 'appr1',
        'tool': 'shell.exec',
        'args_redacted': {'cmd': 'rm -rf /data/old'},
        'risk': 'high',
        'expires_at': '2026-11-11T09:00:00.000Z',
      }));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ada needs your approval to use shell.exec'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chatApprove')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.decisions, {'appr1': 'approved'});
    backend.runEventsController.add(ev(3, 'approval.resolved', {'approval_id': 'appr1', 'decision': 'approved', 'decided_by': null}));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Approved'), findsWidgets);
  });

  testWidgets('blank bots start unnamed (Chief if left empty) and default to Muse Ember; the model comes from a searchable picker', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Consumer(builder: (context, ref, _) => TextButton(onPressed: () => showCreateBot(context, ref), child: const Text('open'))),
        ),
      ),
      GoRoute(path: '/bots/:id/chat', builder: (_, _) => const Text('chat opened')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Blank starts empty, with Chief as the placeholder.
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Bot name')).controller!.text, '');
    expect(find.text('Chief'), findsOneWidget);
    // The picker shows the model's name with its id underneath.
    expect(find.text('Meta: Muse Ember'), findsOneWidget);
    expect(find.text('meta/muse-ember'), findsOneWidget);

    // A template fills in its name; going back to Blank empties the field again.
    await tester.tap(find.byKey(const Key('personaPicker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('template-daily-briefing')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Bot name')).controller!.text, isNotEmpty);
    await tester.tap(find.byKey(const Key('personaPicker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('template-blank')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Bot name')).controller!.text, '');

    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('All models'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('modelSearch')), 'sonnet');
    await tester.pumpAndSettle();
    expect(find.text('Acme: Other'), findsNothing);
    await tester.tap(find.byKey(const Key('model-anthropic/claude-sonnet-5.5')));
    await tester.pumpAndSettle();
    expect(find.text('Anthropic: Claude Sonnet 5.5'), findsOneWidget);

    // Any model id can still be typed in.
    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('modelSearch')), 'acme/brand-new');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customModel')));
    await tester.pumpAndSettle();
    expect(find.text('acme/brand-new'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    expect(backend.createdBot, (name: 'Chief', model: 'acme/brand-new'));
    expect(find.text('chat opened'), findsOneWidget);
  });

  testWidgets('without a model key the new-bot sheet offers to add one', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend()..noKeys = true;
    await tester.pumpWidget(harness(backend, const Scaffold(body: CreateBotSheet())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Add a model key first'), findsOneWidget);
    expect(find.byKey(const Key('apiKey')), findsOneWidget);
    expect(find.byKey(const Key('modelPicker')), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create')).onPressed, isNull);
  });
}
