// Frame-time benchmark for the chat, the app's busiest screen. Runs against the in-memory fake
// backend, so it needs no server. Measure in profile mode on a real device or desktop:
//
//   flutter drive --profile -d macos --driver test_driver/integration_test.dart \
//     --target integration_test/perf_test.dart
//
// On Android (a phone, or an arm64 emulator) add --no-dds: the frame timings come from the VM
// service, which the debug proxy keeps the device from reaching. The iOS Simulator only runs
// debug builds, whose timings mean nothing; use an iPhone for iOS numbers.
//
// Results land in build/integration_response_data.json: build (UI thread) and raster times per
// scenario (average, 90th and 99th percentile, worst, missed frames).
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/wallpaper.dart';

import '../test/fake_backend.dart';

/// A reply with the shapes bots write: headings, lists, code, tables and long paragraphs.
String _reply(int n) =>
    '''
## Part $n: what I found

I went through the **quarterly report** and the [shared folder](https://example.com/folder) and pulled out what matters. The short version: revenue is up, costs are flat, and two vendors need a follow-up before Friday. Here is the detail, with the numbers I checked twice.

- Revenue grew *12%* on the quarter, mostly from the new plan.
- Support tickets fell to 214, the lowest this year.
- Two invoices are still open: `INV-2041` and `INV-2077`.

1. Email the vendors about the open invoices.
2. Move the review meeting to Thursday.
3. Share the summary with the team.

```python
def total(rows):
    return sum(r["amount"] for r in rows if r["status"] == "open")

print(total(load("invoices.csv")))
```

| Vendor | Amount | Due |
| --- | ---: | --- |
| Acme | \$1,240 | Nov 14 |
| Globex | \$860 | Nov 18 |

> Note: the March numbers were restated, so compare against the corrected sheet.

That covers it for part $n. Tell me if you want the full table or a chart.
''';

Future<String> _photoDataUri() async {
  // A busy 2400x1600 picture, like a phone photo, encoded as PNG.
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(2400, 1600);
  canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(colors: [Color(0xFF2E5E8C), Color(0xFFE8A15C)]).createShader(Offset.zero & size));
  for (var i = 0; i < 400; i++) {
    final x = (i * 7919) % 2400.0, y = (i * 104729) % 1600.0;
    canvas.drawCircle(Offset(x, y), 20 + (i % 9) * 12.0, Paint()..color = Color(0x55000000 | ((i * 2654435761) & 0xFFFFFF)));
  }
  final image = await recorder.endRecording().toImage(2400, 1600);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return 'data:image/png;base64,${base64Encode(png!.buffer.asUint8List())}';
}

Widget _app(FakeBackend backend, WallpaperSpec wallpaper) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(const NoCache())],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(Appearance(mode: ThemeMode.light, wallpaper: wallpaper)),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ChatScreen(botId: botId, conversationId: convId),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> streamReply(WidgetTester tester, String id, String text) async {
    // Typed through the controller, as the end-to-end tests do (no IME timing on desktop).
    tester.widget<TextField>(find.byKey(const Key('messageInput'))).controller!.text = 'Summarize the report';
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(_fake.sent, isNotEmpty, reason: 'the message was not sent, so nothing would stream');
    var seq = 1;
    _fake.runEventsController.add(ev(seq++, 'run.started', {'trigger': 'chat', 'model': 'm', 'computer_id': null}));
    // Models stream a few words at a time; one delta per frame.
    for (var i = 0; i < text.length; i += 14) {
      _fake.runEventsController.add(ev(seq++, 'message.delta', {'message_id': id, 'text': text.substring(i, i + 14 > text.length ? text.length : i + 14)}));
      await tester.pump();
    }
    _fake.runEventsController
      ..add(
        ev(seq++, 'message.completed', {
          'message_id': id,
          'content': [
            {'type': 'text', 'text': text},
          ],
        }),
      )
      ..add(ev(seq++, 'run.completed', {'final_message_id': id}));
    for (var i = 0; i < 30; i++) {
      await tester.pump();
    }
    expect(find.textContaining('That covers it for part 3', findRichText: true), findsWidgets, reason: 'the streamed reply is not on screen');
  }

  Future<void> scrollThread(WidgetTester tester) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 4; i++) {
      await tester.fling(list, const Offset(0, 900), 2500);
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 4; i++) {
      await tester.fling(list, const Offset(0, -900), 2500);
      await tester.pumpAndSettle();
    }
  }

  Future<void> run(WidgetTester tester, String key, WallpaperSpec wallpaper) async {
    final fake = FakeBackend()
      ..storedMessages = [
        for (var i = 0; i < 40; i++)
          ChatMessageView(
            id: 'h$i',
            role: i.isEven ? 'user' : 'assistant',
            text: i.isEven ? 'Question $i: can you go through the report and tell me what matters?' : _reply(i),
            createdAt: DateTime(2026, 11, 1, 9, i),
          ),
      ];
    _fake = fake;
    await tester.pumpWidget(_app(fake, wallpaper));
    for (var i = 0; i < 60; i++) {
      await tester.pump();
    }
    final long = List.generate(4, _reply).join('\n');
    await binding.watchPerformance(() => streamReply(tester, 'a-$key', long), reportKey: '${key}_streaming');
    await binding.watchPerformance(() => scrollThread(tester), reportKey: '${key}_scrolling');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('chat frame times', (tester) async {
    await run(tester, 'pattern', const WallpaperSpec());
    await run(tester, 'photo', WallpaperSpec(photo: await _photoDataUri()));
  });
}

late FakeBackend _fake;
