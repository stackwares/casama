import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/mcp/mcp_screens.dart';
import 'package:casama/features/workspaces/spaces.dart';
import 'package:casama_sdk/casama_sdk.dart' show McpConnection, McpKey;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('an AI app asking to connect is allowed for a chosen workspace', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const McpConsentScreen(requestId: 'r1')));
    await tester.pumpAndSettle();
    expect(find.text('Phone AI wants to use Casama'), findsOneWidget);
    // Opened from a link with nothing behind it: it can still be left.
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mcpAllow')));
    await tester.pumpAndSettle();
    expect(backend.mcpActions, ['allow:$orgId']);
  });

  testWidgets('workspace settings show the MCP address, keys and the approvals switch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 3000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const WorkspaceSettingsScreen()));
    await tester.pumpAndSettle();
    // MCP lives under the workspace's Advanced fold (D-182).
    await tester.ensureVisible(find.byKey(const Key('advanced-workspace.settings')));
    await tester.tap(find.byKey(const Key('advanced-workspace.settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mcpUrl')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mcpApprovals')));
    await tester.pumpAndSettle();
    expect(backend.mcpApprovals, isTrue);
    await tester.tap(find.byKey(const Key('mcpCreateKey')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mcpKeyName')), 'Laptop');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('ksk_secret_abcd'), findsOneWidget);
    // Copy is the main action; Done puts the key away.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await tester.tap(find.byKey(const Key('oneTimeSecretCopy')));
    await tester.pumpAndSettle();
    expect(copied, 'ksk_secret_abcd');
    expect(find.text('Key copied'), findsWidgets);
    await tester.tap(find.byKey(const Key('oneTimeSecretDone')));
    await tester.pumpAndSettle();
    expect(find.text('ksk_secret_abcd'), findsNothing);
  });

  testWidgets('revoking an MCP key asks first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 3000));
    final backend = FakeBackend()..storedMcpKeys = [McpKey(id: 'k9', name: 'Laptop', hint: 'wxyz', lastUsedAt: null, createdAt: DateTime(2026))];
    await tester.pumpWidget(harness(backend, const WorkspaceSettingsScreen()));
    await tester.pumpAndSettle();
    // MCP lives under the workspace's Advanced fold (D-182).
    await tester.ensureVisible(find.byKey(const Key('advanced-workspace.settings')));
    await tester.tap(find.byKey(const Key('advanced-workspace.settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('revokeMcpKey-k9')));
    await tester.pumpAndSettle();
    expect(find.text('Revoke “Laptop”?'), findsOneWidget);
    expect(backend.mcpActions, isNot(contains('revoke:k9')));
    await tester.tap(find.byKey(const Key('confirmRevokeMcpKey')));
    await tester.pumpAndSettle();
    expect(backend.mcpActions, contains('revoke:k9'));
  });
  McpConnection conn(String client, String name, {bool mine = true, String user = 'u1'}) => McpConnection(
        clientId: client,
        clientName: name,
        userId: user,
        userName: mine ? 'Me' : 'Sam Lee',
        mine: mine,
        connectedAt: DateTime.now().subtract(const Duration(days: 2)),
        lastUsedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

  testWidgets('admins see connected AI apps and disconnect one after confirming', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 3000));
    final backend = FakeBackend()
      ..storedMcpConnections = [conn('kcl_a', 'Claude'), conn('kcl_b', 'Gemini CLI', mine: false, user: 'u2')];
    await tester.pumpWidget(harness(backend, const WorkspaceSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('advanced-workspace.settings')));
    await tester.tap(find.byKey(const Key('advanced-workspace.settings')));
    await tester.pumpAndSettle();
    expect(find.text('Connected AI Apps'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('Sam Lee · Used 3 hours ago'), findsOneWidget);
    final disconnect = find.byKey(const Key('disconnectMcp-kcl_b-u2'));
    await tester.ensureVisible(disconnect);
    await tester.tap(disconnect);
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Gemini CLI?'), findsOneWidget);
    expect(backend.mcpActions, isEmpty);
    await tester.tap(find.byKey(const Key('confirmDisconnectMcp')));
    await tester.pumpAndSettle();
    // Someone else's connection is named by its person, so the server cuts off the right one.
    expect(backend.mcpActions, ['disconnect:kcl_b:u2']);
    expect(find.text('Gemini CLI'), findsNothing);
    expect(find.text('Claude'), findsOneWidget);
  });

  testWidgets("members see only their own connected apps, and nothing when they have none", (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SingleChildScrollView(child: McpConnectionsSection(orgId: 'o1'))));
    await tester.pumpAndSettle();
    expect(find.text('Connected AI Apps'), findsNothing);
    backend.storedMcpConnections = [conn('kcl_a', 'ChatGPT')];
    await tester.pumpWidget(harness(backend, const SingleChildScrollView(child: McpConnectionsSection(key: Key('again'), orgId: 'o2'))));
    await tester.pumpAndSettle();
    expect(find.text('ChatGPT'), findsOneWidget);
    await tester.tap(find.byKey(const Key('disconnectMcp-kcl_a-u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDisconnectMcp')));
    await tester.pumpAndSettle();
    expect(backend.mcpActions, ['disconnect:kcl_a']);
  });
}
