import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await tester.pumpAndSettle();
    expect(find.text("Can't reach your Casama server"), findsOneWidget);
    expect(find.textContaining('http://casama.invalid'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startupRetry')));
    await tester.pumpAndSettle();
    expect(find.text('app ready'), findsOneWidget);
    expect(attempts, 2);
  });
}
