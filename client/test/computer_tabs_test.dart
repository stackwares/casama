// The computer shows Screen, Terminal, Files and Manage, always; restore points live in Manage
// (D-240). The desktop/headless switch lives only in Settings >
// Computers.
import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/computer/computer_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<String> tabLabels(WidgetTester tester) => [
    for (final tab in tester.widgetList<Tab>(find.byType(Tab))) tester.widget<Text>(find.descendant(of: find.byWidget(tab), matching: find.byType(Text))).data!,
  ];
  int selectedTab(WidgetTester tester) => DefaultTabController.of(tester.element(find.byType(TabBar))).index;

  testWidgets('the Terminal always shows, with no toggle', (tester) async {
    await setSize(tester, const Size(800, 1000));
    await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: ComputerScreen(embedded: true))));
    await tester.pumpAndSettle();
    expect(tabLabels(tester), ['Screen', 'Terminal', 'Files', 'Manage']);
    expect(find.byKey(const Key('advanced-computer.tabs')), findsNothing);
    expect(find.text('Checkpoints'), findsNothing);

    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);

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

  testWidgets('a headless screen clears when the page goes blank, and keeps its picture when a request fails', (tester) async {
    await setSize(tester, const Size(800, 1000));
    // A 1x1 PNG.
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    final backend = FakeBackend()
      ..teamComputerState = ComputerState.running
      ..screen = png;
    await tester.pumpWidget(harness(backend, const Scaffold(body: ComputerScreen(embedded: true))));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // A failed request keeps the last picture.
    backend.screen = null;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Nothing on screen any more (the bot went back to a blank tab): the placeholder returns.
    backend.screen = Uint8List(0);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.textContaining('Nothing on screen yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
