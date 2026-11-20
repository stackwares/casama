// Settings → Widgets → From your bots (docs/BOT-WIDGET-PLAN.md §11.2): each canvas with Hide on a
// locked phone, Pause or Resume and Clear; each allowed bot with its switch; Canvas in the list of
// widgets.
import 'dart:convert';
import 'dart:io';

import 'package:casama/core/providers.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/widgets/widgets_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Canvas;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class _Bots extends BotsNotifier {
  _Bots(this.initial);
  final List<Bot> initial;
  @override
  Future<List<Bot>> build() async => initial;
}

class _Pinner implements WidgetPinner {
  final pinned = <String>[];
  @override
  Future<bool> pin(WidgetKind kind) async {
    pinned.add(kind.androidProvider);
    return true;
  }

  @override
  Future<bool> pinBot(Bot bot) async => true;
}

const verse = 'aaaaaaaa-0000-4000-8000-000000000001';
const verseBot = '33333333-3333-4333-8333-333333333333';

void main() {
  late FakeBackend backend;
  late _Pinner pinner;
  late CanvasList all;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    backend = FakeBackend();
    pinner = _Pinner();
    all = CanvasList.fromJson(jsonDecode(File('../packages/contracts/fixtures/canvases/canvases.json').readAsStringSync()) as Map<String, dynamic>);
    backend.canvasList = all;
  });

  Future<void> open(WidgetTester tester, TargetPlatform platform) async {
    debugDefaultTargetPlatformOverride = platform;
    await setSize(tester, const Size(800, 5000));
    await tester.pumpWidget(
      harness(
        backend,
        const WidgetsScreen(),
        overrides: [
          botsProvider.overrideWith(() => _Bots([backend.bot()])),
          currentOrgIdProvider.overrideWithValue(orgId),
          pinWidgetSupportedProvider.overrideWith((ref) async => true),
          widgetPinnerProvider.overrideWithValue(pinner),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each canvas with its bot, where it shows, and Canvas among the widgets', (tester) async {
    final paused = all.items[1].copyWith(status: CanvasStatusEnum.paused);
    final waiting = all.items[2].copyWith(status: CanvasStatusEnum.waiting);
    backend.canvasList = all.copyWith(items: [all.items[0], paused, waiting, ...all.items.skip(3)]);
    await open(tester, TargetPlatform.android);
    expect(find.text('From your bots'), findsOneWidget);
    for (final c in all.items) {
      expect(find.byKey(Key('canvas-${c.id}')), findsOneWidget, reason: c.name);
    }
    expect(tester.widget<Text>(find.byKey(const Key('canvasStatus-$verse'))).data, "Showing on Oliver's iPhone");
    expect(tester.widget<Text>(find.byKey(Key('canvasStatus-${paused.id}'))).data, 'Paused');
    expect(tester.widget<Text>(find.byKey(Key('canvasStatus-${waiting.id}'))).data, 'Waiting for your yes');
    expect(find.descendant(of: find.byKey(Key('canvasPause-${paused.id}')), matching: find.text('Resume')), findsOneWidget);
    expect(find.byKey(Key('canvasAllow-${waiting.id}')), findsOneWidget);
    // Canvas is one of the widgets, with Add to Home screen on Android.
    expect(find.byKey(const Key('widget-canvas')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('addWidget-canvas')));
    await tester.tap(find.byKey(const Key('addWidget-canvas')));
    await tester.pump();
    expect(pinner.pinned, ['CanvasWidget']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Hide on a locked phone, Pause and Resume, Show on my widgets', (tester) async {
    final waiting = all.items[2].copyWith(status: CanvasStatusEnum.waiting);
    backend.canvasList = all.copyWith(items: [all.items[0], all.items[1], waiting]);
    await open(tester, TargetPlatform.iOS);
    await tester.tap(find.byKey(const Key('canvasHide-$verse')));
    await tester.pumpAndSettle();
    expect(backend.canvasActions.last, 'update:$verse:null:true');
    expect(tester.widget<Switch>(find.byKey(const Key('canvasHide-$verse'))).value, isTrue);
    await tester.tap(find.byKey(const Key('canvasPause-$verse')));
    await tester.pumpAndSettle();
    expect(backend.canvasActions.last, 'update:$verse:paused:null');
    expect(find.descendant(of: find.byKey(const Key('canvasPause-$verse')), matching: find.text('Resume')), findsOneWidget);
    await tester.tap(find.byKey(const Key('canvasPause-$verse')));
    await tester.pumpAndSettle();
    expect(backend.canvasActions.last, 'update:$verse:shown:null');
    await tester.tap(find.byKey(Key('canvasAllow-${waiting.id}')));
    await tester.pumpAndSettle();
    expect(backend.canvasActions.last, 'grant:${waiting.botId}:true');
    expect(find.byKey(Key('canvasAllow-${waiting.id}')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Clear asks first, then clears', (tester) async {
    await open(tester, TargetPlatform.iOS);
    await tester.tap(find.byKey(const Key('canvasClear-$verse')));
    await tester.pumpAndSettle();
    expect(find.text('Clear Daily verse?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('canvasClearConfirm')));
    await tester.pumpAndSettle();
    expect(backend.canvasActions, ['clear:$verse']);
    expect(find.byKey(const Key('canvas-$verse')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('turning a bot off asks first and clears what it showed', (tester) async {
    await open(tester, TargetPlatform.iOS);
    expect(find.byKey(const Key('canvasGrant-$verseBot')), findsOneWidget);
    expect(find.text('May show things on your widgets'), findsOneWidget);
    await tester.tap(find.byKey(const Key('canvasGrantSwitch-$verseBot')));
    await tester.pumpAndSettle();
    expect(find.text('Stop Verse?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('canvasStopConfirm')));
    await tester.pumpAndSettle();
    expect(backend.canvasActions, ['grant:$verseBot:false']);
    expect(find.byKey(const Key('canvasGrant-$verseBot')), findsNothing);
    expect(find.byKey(const Key('canvas-$verse')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('nothing yet: an example to ask for', (tester) async {
    backend.canvasList = all.copyWith(items: const [], grants: const []);
    await open(tester, TargetPlatform.iOS);
    expect(find.textContaining('Put a daily verse on my Lock Screen'), findsOneWidget);
    expect(find.text('Bots on your widgets'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
