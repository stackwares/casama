import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/config.dart';
import 'package:kasama_app/main.dart';

void main() {
  testWidgets('startup shows progress, then a retry when the server cannot be reached', (tester) async {
    var attempts = 0;
    Future<Widget> connect(AppConfig _) async {
      attempts++;
      if (attempts == 1) throw StateError('connection refused');
      return const MaterialApp(home: Text('app ready'));
    }

    await tester.pumpWidget(StartupGate(config: const AppConfig(apiUrl: 'http://kasama.invalid'), connect: connect));
    await tester.pumpAndSettle();
    expect(find.text("Can't reach your Kasama server"), findsOneWidget);
    expect(find.textContaining('http://kasama.invalid'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startupRetry')));
    await tester.pumpAndSettle();
    expect(find.text('app ready'), findsOneWidget);
    expect(attempts, 2);
  });
}
