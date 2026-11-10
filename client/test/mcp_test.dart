import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/mcp/mcp_screens.dart';
import 'package:kasama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('an AI app asking to connect is allowed for a chosen workspace', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const McpConsentScreen(requestId: 'r1')));
    await tester.pumpAndSettle();
    expect(find.text('Phone AI wants to use Kasama'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mcpAllow')));
    await tester.pumpAndSettle();
    expect(backend.mcpActions, ['allow:$orgId']);
  });

  testWidgets('workspace settings show the MCP address, keys and the approvals switch', (tester) async {
    await setSize(tester, const Size(900, 3000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const WorkspaceSettingsScreen()));
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
  });
}
