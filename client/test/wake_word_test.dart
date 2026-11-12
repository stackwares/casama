import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/voice/wake_word.dart';
import 'package:casama_app/features/voice/wake_word_sheet.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

class FakeWakeEngine implements WakeWordEngine {
  final heard = StreamController<void>.broadcast();
  var prepared = 0;
  String? phrase;
  var stopped = 0;
  @override
  Future<void> prepare({void Function(double)? onProgress}) async {
    prepared++;
    onProgress?.call(1);
  }

  @override
  Stream<void> listen(String p) {
    phrase = p;
    return heard.stream;
  }

  @override
  Future<void> stop() async => stopped++;
}

/// Wake word (D-144).
void main() {
  test('the phrase as keyword-model tokens, every shortest spelling', () {
    final vocab = {'▁HE', 'Y', '▁S', 'I', 'RI', 'IR', '▁C', 'AS', 'A', 'MA', '▁', 'C'};
    expect(keywordLines('Hey Siri', vocab), ['▁HE Y ▁S I RI @WAKE', '▁HE Y ▁S IR I @WAKE']);
    expect(keywordLines('hey casama', vocab), ['▁HE Y ▁C AS A MA @WAKE']);
    expect(keywordLines('hey zed', vocab), isEmpty);
  });

  testWidgets('turning it on listens for the phrase; hearing it opens a live call with the chosen bot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    WakeWordController.testing = true;
    await setSize(tester, const Size(900, 1200));
    final engine = FakeWakeEngine();
    final router = GoRouter(initialLocation: '/wake', routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')), routes: [GoRoute(path: 'wake', builder: (_, _) => const Scaffold(body: WakeWordSheet()))]),
      GoRoute(path: '/bots/:id/call', builder: (_, s) => Text('call ${s.pathParameters['id']}')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(FakeBackend()), wakeWordEngineProvider.overrideWithValue(engine), routerProvider.overrideWithValue(router)],
      child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wakeWordOn')));
    await tester.enterText(find.byKey(const Key('wakePhrase')), 'Hey Casama');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveWakeWord')));
    await tester.pumpAndSettle();
    expect(engine.prepared, 1);
    expect(engine.phrase, 'hey casama');
    expect((await SharedPreferences.getInstance()).getBool('wake.enabled'), isTrue);

    engine.heard.add(null);
    await tester.pumpAndSettle();
    expect(find.text('call $botId'), findsOneWidget);
    WakeWordController.testing = false;
  });

  test('microphone audio decodes at odd offsets and across chunk edges', () {
    // Samples 1, -1, 32767, -32768 as little-endian bytes, behind one junk byte so the view
    // starts at an odd offset (what crashed asInt16List).
    final bytes = Uint8List.fromList([0xAA, 0x01, 0x00, 0xFF, 0xFF, 0xFF, 0x7F, 0x00, 0x80]);
    final view = Uint8List.sublistView(bytes, 1);
    final whole = Pcm16Decoder().decode(view);
    expect(whole, [1 / 32768, -1 / 32768, 32767 / 32768, -1.0]);

    // The same bytes split mid-sample: the half sample waits for the next chunk.
    final d = Pcm16Decoder();
    final a = d.decode(Uint8List.sublistView(bytes, 1, 4));
    final b = d.decode(Uint8List.sublistView(bytes, 4, 4));
    final c = d.decode(Uint8List.sublistView(bytes, 4));
    expect([...a, ...b, ...c], whole);
  });
}
