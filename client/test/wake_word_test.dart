import 'dart:async';

import 'package:flutter/material.dart';
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
}
