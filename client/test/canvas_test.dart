// Bot widgets (docs/BOT-WIDGET-PLAN.md): the contract's sample canvases decode into the generated
// models and draw in Flutter for every template, the carrier hands them to the widgets, and the
// chat's preview card answers through the backend by its state.
import 'dart:convert';
import 'dart:io';

import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/widgets/canvas_preview_card.dart';
import 'package:casama/features/widgets/canvas_sync.dart';
import 'package:casama/features/widgets/canvas_view.dart';
import 'package:casama/features/widgets/widgets_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casama/core/providers.dart';
import 'package:material_ui/material_ui.dart' hide Canvas;

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

CanvasList fixture(String name) =>
    CanvasList.fromJson(jsonDecode(File('../packages/contracts/fixtures/canvases/$name').readAsStringSync()) as Map<String, dynamic>);

/// A clock inside the fixtures' day, so the countdown is in days.
DateTime fixtureNow() => DateTime.utc(2027, 3, 10, 9);

class _Pinner implements WidgetPinner {
  final pinned = <String>[];
  var ok = true;
  @override
  Future<bool> pin(WidgetKind kind) async {
    pinned.add(kind.androidProvider);
    return ok;
  }

  @override
  Future<bool> pinBot(Bot bot) async => ok;
}

class _Surface implements CanvasSurface {
  _Surface({this.takesPictures = false});
  @override
  final bool takesPictures;
  final written = <(String?, Map<String, Uint8List>)>[];
  @override
  Future<void> publish(String? canvases, Map<String, Uint8List> pictures) async => written.add((canvases, pictures));
}

void main() {
  late FakeBackend backend;
  late CanvasList all;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    all = fixture('canvases.json');
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('the sample canvases', () {
    test('decode, with every template', () {
      expect(all.items.map((c) => c.entries.first.template).toSet(), CanvasEntryTemplateEnum.values.toSet());
      expect(all.items.first.entries, hasLength(14));
      final private = fixture('private.json');
      expect(private.private, isTrue);
      expect(private.items.every((c) => c.entries.isEmpty), isTrue);
    });

    for (final brightness in Brightness.values) {
      testWidgets('draw at both sizes and on the Lock Screen (${brightness.name})', (tester) async {
        await setSize(tester, const Size(800, 2400));
        final private = fixture('private.json');
        await tester.pumpWidget(
          harness(
            backend,
            Theme(
              data: ThemeData(brightness: brightness),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final c in [...all.items, ...private.items]) ...[
                        CanvasView(canvas: c, now: fixtureNow),
                        CanvasView(canvas: c, size: CanvasSize.medium, now: fixtureNow),
                        CanvasView(canvas: c, locked: true, now: fixtureNow),
                        CanvasLockLine(canvas: c),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Be still, and know that I am God.'), findsWidgets);
        // The streak hides on a locked phone: its name only.
        expect(find.text('Streak'), findsWidgets);
        expect(find.byType(CanvasView), findsNWidgets((all.items.length + private.items.length) * 3));
      });
    }

    testWidgets('a countdown under a day ticks as a clock', (tester) async {
      final trip = all.items.firstWhere((c) => c.entries.first.template == CanvasEntryTemplateEnum.countdown);
      final target = trip.entries.first.target!;
      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: CanvasView(canvas: trip, now: () => target.subtract(const Duration(hours: 2, minutes: 3, seconds: 4))),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('2:03:04'), findsOneWidget);
      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: CanvasView(canvas: trip, now: () => target.subtract(const Duration(days: 12, hours: 1))),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('12'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
    });
  });

  group('the carrier', () {
    Future<CanvasSync> carrier(CanvasSurface surface) async {
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          currentOrgIdProvider.overrideWithValue(orgId),
          canvasSurfaceProvider.overrideWithValue(surface),
        ],
      );
      addTearDown(c.dispose);
      c.listen(signedInProvider, (_, _) {});
      await c.read(signedInProvider.future);
      final sync = c.read(Provider<CanvasSync>((ref) => CanvasSync(ref, surface)));
      addTearDown(sync.dispose);
      return sync;
    }

    test('the Mac gets the shown canvases with their pictures, once per version', () async {
      final waiting = all.items[1].copyWith(id: 'bbbbbbbb-0000-4000-8000-000000000009', status: CanvasStatusEnum.waiting);
      backend.canvasList = all.copyWith(items: [...all.items, waiting]);
      final surface = _Surface(takesPictures: true);
      final sync = await carrier(surface);
      await sync.sync();
      expect(surface.written, hasLength(1));
      final (json, pictures) = surface.written.single;
      final sent = CanvasList.fromJson(jsonDecode(json!) as Map<String, dynamic>);
      expect(sent.items.map((i) => i.id), all.items.map((i) => i.id));
      expect(pictures.keys, contains('painting-night_sky'));
      expect(backend.canvasActions.where((a) => a.startsWith('picture:')), hasLength(pictures.length));
      // Unchanged: asked with its version, nothing written again.
      await sync.sync();
      expect(backend.canvasCalls.last, backend.canvasList.version);
      expect(surface.written, hasLength(1));
    });

    test('phones get the list without pictures; signed out forgets it', () async {
      backend.canvasList = all;
      final surface = _Surface();
      final sync = await carrier(surface);
      await sync.sync();
      expect(surface.written.single.$2, isEmpty);
      expect(backend.canvasActions, isEmpty);
      await sync.signedOut();
      expect(surface.written.last.$1, isNull);
    });
  });

  test('/canvases/:id opens the bot chat of the canvas, or Settings → Widgets', () async {
    backend.canvasList = all;
    final verse = all.items.first;
    expect(await canvasLocation(backend, orgId, verse.id), verse.link);
    expect(await canvasLocation(backend, orgId, 'ffffffff-0000-4000-8000-000000000000'), '/settings/widgets');
    expect(await canvasLocation(backend, null, verse.id), '/settings/widgets');
  });

  group('the preview card', () {
    late _Pinner pinner;
    setUp(() => pinner = _Pinner());

    Future<void> pumpCard(
      WidgetTester tester,
      CanvasPreviewEventPayloadStateEnum state, {
      TargetPlatform platform = TargetPlatform.iOS,
      bool canPin = true,
    }) async {
      debugDefaultTargetPlatformOverride = platform;
      await setSize(tester, const Size(500, 1200));
      final canvas = all.items.first.copyWith(status: state == CanvasPreviewEventPayloadStateEnum.waiting ? CanvasStatusEnum.waiting : CanvasStatusEnum.shown);
      backend.canvasList = all.copyWith(items: [canvas, ...all.items.skip(1)]);
      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: SingleChildScrollView(
              child: CanvasPreviewCard(
                preview: CanvasPreviewEventPayload(canvasId: canvas.id, botId: canvas.botId, state: state, canvas: canvas),
                now: fixtureNow,
              ),
            ),
          ),
          overrides: [widgetPinnerProvider.overrideWithValue(pinner), pinWidgetSupportedProvider.overrideWith((ref) async => canPin)],
        ),
      );
      await tester.pumpAndSettle();
    }

    final verse = 'aaaaaaaa-0000-4000-8000-000000000001';
    final verseBot = '33333333-3333-4333-8333-333333333333';

    testWidgets('waiting: Show on my widgets lets the bot write', (tester) async {
      await pumpCard(tester, CanvasPreviewEventPayloadStateEnum.waiting);
      expect(find.text('Verse wants to show this on your widgets'), findsOneWidget);
      await tester.tap(find.byKey(const Key('canvasShow')));
      await tester.pumpAndSettle();
      expect(backend.canvasActions, ['grant:$verseBot:true']);
      expect(find.text('Showing on your widgets'), findsOneWidget);
      expect(find.byKey(const Key('canvasShow')), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('waiting: Not now clears the canvas', (tester) async {
      await pumpCard(tester, CanvasPreviewEventPayloadStateEnum.waiting);
      await tester.tap(find.byKey(const Key('canvasNotNow')));
      await tester.pumpAndSettle();
      expect(backend.canvasActions, ['clear:$verse']);
      expect(find.text('Not shown. Verse can ask again another day.'), findsOneWidget);
      expect(find.byType(CanvasView), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('not placed on Android: Add to Home screen places the Canvas widget', (tester) async {
      await pumpCard(tester, CanvasPreviewEventPayloadStateEnum.notPlaced, platform: TargetPlatform.android);
      await tester.tap(find.byKey(const Key('canvasAdd')));
      await tester.pumpAndSettle();
      expect(pinner.pinned, ['CanvasWidget']);
      expect(find.text('Canvas widget added'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('not placed on iPhone and the Mac: the steps', (tester) async {
      await pumpCard(tester, CanvasPreviewEventPayloadStateEnum.notPlaced);
      expect(find.byKey(const Key('canvasAdd')), findsNothing);
      expect(find.textContaining('Add Widget'), findsOneWidget);
      await pumpCard(tester, CanvasPreviewEventPayloadStateEnum.notPlaced, platform: TargetPlatform.macOS);
      expect(find.textContaining('Edit Widgets'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shown: no buttons', (tester) async {
      await pumpCard(tester, CanvasPreviewEventPayloadStateEnum.shown);
      expect(find.text('Verse put this on your widgets'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a canvas cleared since says so', (tester) async {
      backend.canvasList = all.copyWith(items: all.items.skip(1).toList());
      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: CanvasPreviewCard(
              preview: CanvasPreviewEventPayload(canvasId: verse, botId: verseBot, state: CanvasPreviewEventPayloadStateEnum.shown, canvas: all.items.first),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No longer on your widgets'), findsOneWidget);
    });

    testWidgets('a canvas.preview run event puts the card in the chat', (tester) async {
      backend.canvasList = all.copyWith(
        items: [
          all.items.first.copyWith(status: CanvasStatusEnum.waiting),
          ...all.items.skip(1),
        ],
      );
      await setSize(tester, const Size(500, 1400));
      await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('messageInput')), 'put a verse on my widgets');
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      final canvas = backend.canvasList.items.first;
      backend.runEventsController.add(ev(1, 'canvas.preview', {'canvas_id': canvas.id, 'bot_id': canvas.botId, 'state': 'waiting', 'canvas': canvas.toJson()}));
      backend.runEventsController.add(ev(2, 'run.completed', {'final_message_id': null}));
      await tester.pumpAndSettle();
      expect(find.byType(CanvasPreviewCard), findsOneWidget);
      expect(find.byKey(const Key('canvasShow')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
