import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/mcp/mcp_screens.dart';
import 'package:casama_app/features/workspaces/spaces.dart';
import 'package:casama_sdk/casama_sdk.dart' show McpKey;
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
}
