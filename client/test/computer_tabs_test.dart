// The computer shows Screen, Terminal, Files and Manage, always; restore points live in Manage
// (D-240). A headless computer's Screen offers the switch to the desktop right there.
import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/computer/computer_screen.dart';
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

  testWidgets('an asleep headless computer offers Wake and switches to the desktop without a restart warning', (tester) async {
    await setSize(tester, const Size(800, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: ComputerScreen(embedded: true))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('openComputerSettings')), findsNothing);
    expect(find.byKey(const Key('headlessAsleep')), findsOneWidget);
    expect(find.byKey(const Key('headlessWake')), findsOneWidget);

    await tester.tap(find.byKey(const Key('switchToDesktop')));
    await tester.pumpAndSettle();
    // Asleep, nothing is running to stop, so no confirm.
    expect(find.text('Switch'), findsNothing);
    expect(backend.computerUpdates, ['desktop']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a running headless computer with a blank screen offers the desktop, asks first, and has no Refresh', (tester) async {
    await setSize(tester, const Size(800, 1000));
    final backend = FakeBackend()
      ..teamComputerState = ComputerState.running
      ..screen = Uint8List(0);
    await tester.pumpWidget(harness(backend, const Scaffold(body: ComputerScreen(embedded: true))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('headlessEmpty')), findsOneWidget);
    expect(find.text('Watch your bot work live'), findsOneWidget);
    expect(find.text('Refresh'), findsNothing);

    await tester.tap(find.byKey(const Key('switchToDesktop')));
    await tester.pumpAndSettle();
    expect(find.textContaining('The computer restarts to switch'), findsOneWidget);
    expect(backend.computerUpdates, isEmpty);
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();
    expect(backend.computerUpdates, ['desktop']);
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
    // Over the picture, one thin line: it's only the browser, and the desktop is a tap away.
    expect(find.text('Browser only'), findsOneWidget);
    expect(find.byKey(const Key('switchToDesktop')), findsOneWidget);

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
    expect(find.byKey(const Key('headlessEmpty')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('a computer that is not in the list offers Refresh and a way to pick one, not a dead end', (tester) async {
    await setSize(tester, const Size(800, 1000));
    await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: ComputerScreen(computerId: 'gone', embedded: true))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('noComputer')), findsOneWidget);
    expect(find.text('Computer not found'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byKey(const Key('noComputerChoose')), findsOneWidget);

    await tester.tap(find.byKey(const Key('noComputerRefresh')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('noComputer')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
