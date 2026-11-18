// Workspace settings, People and Usage keep their expert options under one folded "Advanced" row
// at the end (D-182): folded at first, there with one tap.
import 'package:casama/features/usage/usage_screen.dart';
import 'package:casama/features/workspaces/people_screen.dart';
import 'package:casama/features/workspaces/spaces.dart';
import 'package:casama/core/backend.dart' show UsageFilter;
import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/ui/bot_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<void> _openAdvanced(WidgetTester tester, String id) async {
  final row = find.byKey(Key('advanced-$id'));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

/// Email that can't be sent from this server: the invites come back with their links.
class _NoEmailBackend extends FakeBackend {
  @override
  Future<List<Invite>> inviteMany(String orgId, List<String> emails, {bool admin = false}) async => [
    for (final (i, e) in emails.indexed) Invite(id: 'inv$i', orgId: orgId, email: e, role: OrgRole.member, expiresAt: DateTime(2026, 2), emailSent: false, acceptToken: 'kinv_secret$i'),
  ];
}

/// Usage with spend on a model the bots' key names and on one it doesn't.
class _ModelUsageBackend extends FakeBackend {
  @override
  Future<UsageReport> usage(String orgId, {String period = 'day', UsageFilter filter = UsageFilter.none}) async => UsageReport(
    period: UsageReportPeriodEnum.month,
    since: DateTime(2026),
    totalCostUsd: 1.5,
    runs: 3,
    byBot: [
      UsageReportByBotInner(botId: botId, name: 'Ada', costUsd: 1.5, tokensIn: 1000, tokensOut: 200),
      UsageReportByBotInner(botId: null, name: null, costUsd: 0.02, tokensIn: 0, tokensOut: 0),
    ],
    byModel: [
      UsageReportByModelInner(model: 'anthropic/claude-sonnet-5.5', costUsd: 1, tokensIn: 800, tokensOut: 100),
      UsageReportByModelInner(model: 'acme/unlisted-7', costUsd: 0.5, tokensIn: 200, tokensOut: 100),
    ],
  );
}

/// Remembers each filter the usage screen asks for and answers with sources and people (D-353).
class _FilteredUsageBackend extends _ModelUsageBackend {
  final asked = <UsageFilter>[];

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day', UsageFilter filter = UsageFilter.none}) async {
    asked.add(filter);
    final r = await super.usage(orgId, period: period, filter: filter);
    return r.copyWith(
      bySource: [
        UsageReportBySourceInner(source_: UsageSource.chat, costUsd: 1, runs: 2),
        UsageReportBySourceInner(source_: UsageSource.routine, costUsd: 0.5, runs: 1),
      ],
      byPerson: [UsageReportByPersonInner(userId: null, name: null, costUsd: 0.5, runs: 1)],
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('usage: tapping a model or source narrows the report; Clear shows everything again', (tester) async {
    await setSize(tester, const Size(430, 2400));
    final backend = _FilteredUsageBackend();
    await tester.pumpWidget(harness(backend, const UsageScreen()));
    await tester.pumpAndSettle();
    expect(find.text('By Source'), findsOneWidget);
    expect(find.text('Routines'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.byKey(const Key('usageFilter-source')), findsOneWidget);
    expect(find.byKey(const Key('usageFilter-clear')), findsNothing);

    await tester.tap(find.byKey(const Key('usageSource-routine')));
    await tester.pumpAndSettle();
    expect(backend.asked.last, const UsageFilter(source: UsageSource.routine));
    // The source breakdown would be one row now, so it's gone; the chip says what's picked.
    expect(find.text('By Source'), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('usageFilter-source')), matching: find.text('Routines')), findsOneWidget);

    await tester.tap(find.byKey(const Key('usageModel-acme/unlisted-7')));
    await tester.pumpAndSettle();
    expect(backend.asked.last, const UsageFilter(source: UsageSource.routine, model: 'acme/unlisted-7'));
    expect(find.byKey(const Key('usageModel-acme/unlisted-7')), findsNothing);

    await tester.tap(find.byKey(const Key('usageFilter-clear')));
    await tester.pumpAndSettle();
    // The whole period is already loaded (it feeds the filter choices), so nothing is asked again.
    expect(backend.asked.last, const UsageFilter(source: UsageSource.routine, model: 'acme/unlisted-7'));
    expect(find.byKey(const Key('usageFilter-clear')), findsNothing);
    expect(find.text('By Source'), findsOneWidget);
  });

  testWidgets('usage: the source chip picks a source from a sheet', (tester) async {
    await setSize(tester, const Size(430, 2400));
    final backend = _FilteredUsageBackend();
    await tester.pumpWidget(harness(backend, const UsageScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usageFilter-source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usageFilterSource-chat_app')));
    await tester.pumpAndSettle();
    expect(backend.asked.last, const UsageFilter(source: UsageSource.chatApp));
  });

  testWidgets('workspace settings: name, look and People up top; the technical setup under Advanced', (tester) async {
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(harness(FakeBackend(), const WorkspaceSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspaceRename')), findsOneWidget);
    expect(find.byKey(const Key('workspacePeople')), findsOneWidget);
    expect(find.text('Secrets, memory, encryption, payments, MCP'), findsOneWidget);
    const moved = ['passwordManagers', 'botToBot', 'secretStore', 'memoryBackend', 'mcpUrl'];
    for (final key in moved) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }

    await _openAdvanced(tester, 'workspace.settings');
    for (final key in moved) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect((await SharedPreferences.getInstance()).getStringList('advanced.open'), ['workspace.settings']);
  });

  testWidgets('People: link, email invites and members up top; code, domain and custom links under Advanced', (tester) async {
    await setSize(tester, const Size(430, 2600));
    await tester.pumpWidget(harness(FakeBackend(), const PeopleScreen()));
    await tester.pumpAndSettle();
    for (final key in ['copyInvite', 'inviteEmails', 'sendInvites']) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(const Key('member-u-ana')), findsOneWidget);
    expect(find.text('Invite code, email domain, custom links'), findsOneWidget);
    const moved = ['makeInviteCode', 'joinDomain', 'customLinks'];
    for (final key in moved) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }

    await _openAdvanced(tester, 'workspace.people');
    for (final key in moved) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('custom links are listed by what they are, not by their token', (tester) async {
    await setSize(tester, const Size(430, 2600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const PeopleScreen()));
    await tester.pumpAndSettle();
    await _openAdvanced(tester, 'workspace.people');
    await tester.ensureVisible(find.byKey(const Key('customLinks')));
    await tester.tap(find.byKey(const Key('customLinks')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('createInviteLink')));
    await tester.tap(find.byKey(const Key('createInviteLink')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('link-l1')), findsOneWidget);
    expect(find.text('Invite link · Member'), findsOneWidget);
    // The new link itself is shown to share above; the list row names it without its token.
    expect(find.descendant(of: find.byKey(const Key('link-l1')), matching: find.textContaining('kjoin_abcd')), findsNothing);
  });

  testWidgets('invites with no email to send them show a label and copy the link, not the raw token', (tester) async {
    await setSize(tester, const Size(430, 2600));
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await tester.pumpWidget(harness(_NoEmailBackend(), const PeopleScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('inviteEmails')), 'ana@acme.dev');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendInvites')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unsentInvites')), findsOneWidget);
    expect(find.text('Invite link, ready to copy'), findsOneWidget);
    expect(find.textContaining('kinv_secret0'), findsNothing);
    await tester.tap(find.byKey(const Key('unsent-ana@acme.dev')));
    await tester.pump();
    expect(clipboard, 'https://app.example.com/join/kinv_secret0');
  });

  testWidgets('usage: spend and runs up top with model names; tokens and JSON export under Advanced', (tester) async {
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(harness(_ModelUsageBackend(), const UsageScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('usageSpend')), findsOneWidget);
    expect(find.byKey(const Key('exportUsageCsv')), findsOneWidget);
    // By Bot: each bot's avatar beside its bar; spend with no bot gets a plain mark.
    expect(find.descendant(of: find.byKey(const Key('usageBot-$botId')), matching: find.byType(BotAvatar)), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('usageBot-none')), matching: find.byType(BotAvatar)), findsNothing);
    expect(find.text('Not tied to a bot'), findsOneWidget);
    // The name the bots' key gives the model; an id it doesn't name stays as it is.
    expect(find.text('Claude Sonnet 5.5'), findsOneWidget);
    expect(find.text('anthropic/claude-sonnet-5.5'), findsNothing);
    expect(find.text('acme/unlisted-7'), findsOneWidget);
    expect(find.text('Token counts, JSON export'), findsOneWidget);
    const moved = ['usageTokensIn', 'usageTokensOut', 'exportUsageJson'];
    for (final key in moved) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }

    await _openAdvanced(tester, 'usage');
    for (final key in moved) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.text('1K'), findsOneWidget);
  });
}
