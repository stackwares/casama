import 'package:casama_app/core/dev_server.dart';
import 'package:casama_app/features/settings/me_avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

class _At extends FakeBackend {
  _At(this.url);
  final String url;
  @override
  String get apiUrl => url;
}

void main() {
  test('the local stack and api-dev are development servers; production and self-hosts are not', () {
    for (final url in [
      'http://localhost:8787',
      'http://127.0.0.1:8787',
      'http://10.0.2.2:8787',
      'http://192.168.1.20:8787',
      'http://172.20.0.5:8787',
      'http://macbook.local:8787',
      'https://api-dev.casama.ai',
    ]) {
      expect(isDevServer(url), isTrue, reason: url);
    }
    for (final url in [
      'https://api.casama.ai',
      'https://cloud.casama.ai',
      'https://casama.example.com',
      'http://172.40.0.5',
      '',
    ]) {
      expect(isDevServer(url), isFalse, reason: url);
    }
    expect(serverHost('https://api-dev.casama.ai'), 'api-dev.casama.ai');
  });

  testWidgets('the avatar carries an amber dot on a development server only', (
    tester,
  ) async {
    Future<void> pump(String url) async {
      await tester.pumpWidget(
        harness(_At(url), const Scaffold(body: Center(child: MeButton()))),
      );
      await tester.pump();
    }

    await pump('https://api-dev.casama.ai');
    expect(find.byKey(const Key('devServerDot')), findsOneWidget);
    expect(
      find.byTooltip('Settings · development server api-dev.casama.ai'),
      findsOneWidget,
    );
    await pump('https://api.casama.ai');
    expect(find.byKey(const Key('devServerDot')), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });
}
