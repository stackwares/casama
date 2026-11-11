import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps until [finder] is on screen. A playing splash loop never goes idle, so this does not use
/// pumpAndSettle.
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('not found: $finder');
}

void main() {
  testWidgets('startup shows progress, then a retry when the server cannot be reached', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var attempts = 0;
    Future<Widget> connect(AppConfig _) async {
      attempts++;
      if (attempts == 1) throw StateError('connection refused');
      return const MaterialApp(home: Text('app ready'));
    }

    await tester.pumpWidget(StartupGate(config: const AppConfig(apiUrl: 'http://casama.invalid'), connect: connect));
    await pumpUntil(tester, find.text("Can't reach your Casama server"));
    expect(find.textContaining('http://casama.invalid'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startupRetry')));
    await pumpUntil(tester, find.text('app ready'));
    for (var i = 0; i < 20 && find.byKey(const Key('startupSplash')).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('app ready'), findsOneWidget);
    expect(find.byKey(const Key('startupSplash')), findsNothing);
    expect(attempts, 2);
  });
}
