// The computer shows Screen, Files and Manage; the Terminal comes with Advanced (D-182), and
// restore points live in Manage (D-240). The desktop/headless switch lives only in Settings >
// Computers.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/computer/computer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<String> tabLabels(WidgetTester tester) => [
    for (final tab in tester.widgetList<Tab>(find.byType(Tab))) tester.widget<Text>(find.descendant(of: find.byWidget(tab), matching: find.byType(Text))).data!,
  ];
  int selectedTab(WidgetTester tester) => DefaultTabController.of(tester.element(find.byType(TabBar))).index;

  testWidgets('the Terminal shows once Advanced is on, and the open tab keeps its place', (tester) async {
    await setSize(tester, const Size(800, 1000));
    await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: ComputerScreen(embedded: true))));
    await tester.pumpAndSettle();
    expect(tabLabels(tester), ['Screen', 'Files', 'Manage']);
    expect(find.text('Terminal'), findsNothing);
    expect(find.text('Checkpoints'), findsNothing);

    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);

    await tester.tap(find.byKey(const Key('advanced-computer.tabs')));
    await tester.pumpAndSettle();
    expect(tabLabels(tester), ['Screen', 'Terminal', 'Files', 'Manage']);
    expect(selectedTab(tester), 2, reason: 'Files stays open');

    // Remembered on this device.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('advanced.open'), contains('computer.tabs'));

    // On the Terminal, turning Advanced off falls back to the first tab.
    await tester.tap(find.text('Terminal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('advanced-computer.tabs')));
    await tester.pumpAndSettle();
    expect(tabLabels(tester), ['Screen', 'Files', 'Manage']);
    expect(selectedTab(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a headless computer points to Settings > Computers instead of switching here', (tester) async {
    await setSize(tester, const Size(800, 1000));
    await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: ComputerScreen(embedded: true))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('switchToDesktop')), findsNothing);
    expect(find.text('Switch to Desktop'), findsNothing);
    expect(find.byKey(const Key('openComputerSettings')), findsOneWidget);
    expect(find.textContaining('switch it to a desktop in computer settings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
