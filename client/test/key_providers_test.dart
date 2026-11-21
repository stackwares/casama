import 'package:casama/core/backend.dart';
import 'package:casama/features/admin/remote_settings_cards.dart';
import 'package:casama/features/settings/model_keys_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Model-key providers from the server (D-374) and Admin's JSON settings (D-373, D-374).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an older server without the list gets the fallback', () {
    final k = KeyProviders.from(null);
    expect(k.chat.first, ProviderId.openrouter);
    expect(k.runsChat, contains(ProviderId.openaiCompatible));
    expect(k.cloud, isNot(contains(ProviderId.openrouter)));
  });

  test(
    'the server\'s list wins; unknown ids are skipped, nothing goes missing',
    () {
      final k = KeyProviders.from(
        PublicConfigKeyProviders(
          chat: const ['anthropic', 'openrouter', 'future_ai'],
          more: const ['tavily', 'chatgpt'],
          cloud: const [],
          runsChat: const ['anthropic', 'openrouter', 'future_ai'],
          hints: const {'tavily': 'search the web', 'nobody': 'x'},
        ),
      );
      expect(k.chat, [ProviderId.anthropic, ProviderId.openrouter]);
      expect(k.more.first, ProviderId.tavily);
      // Every pasted-key provider is still in the form, once, and a ChatGPT plan never is.
      expect(k.all.toSet(), {
        for (final p in ProviderId.values)
          if (p != ProviderId.chatgpt) p,
      });
      expect(k.all.length, k.all.toSet().length);
      expect(k.cloud, isEmpty);
      // A ChatGPT plan always runs chat: it is signed in, so never in the add-key lists.
      expect(k.runsChat, {ProviderId.anthropic, ProviderId.openrouter, ProviderId.chatgpt});
      expect(k.hints, {ProviderId.tavily: 'search the web'});
    },
  );

  test('an empty part falls back instead of emptying the form', () {
    final k = KeyProviders.from(
      PublicConfigKeyProviders(
        chat: const ['nope'],
        more: const [],
        cloud: const ['brave_search'],
        runsChat: const [],
      ),
    );
    expect(k.chat, KeyProviders.fallback.chat);
    expect(k.runsChat, KeyProviders.fallback.runsChat);
    expect(k.cloud, [ProviderId.braveSearch]);
  });

  testWidgets('the add-key form follows the server\'s order and hints', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1400));
    final backend = FakeBackend()
      ..keyProviders = KeyProviders.from(
        PublicConfigKeyProviders(
          chat: const ['anthropic', 'openrouter'],
          more: const ['tavily'],
          cloud: const [],
          runsChat: const ['anthropic', 'openrouter'],
          hints: const {'anthropic': 'Claude models'},
        ),
      );
    await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
    await tester.pumpAndSettle();
    double x(Finder f) => tester.getTopLeft(f).dx;
    double y(Finder f) => tester.getTopLeft(f).dy;
    final anthropic = find.byKey(const Key('provider-anthropic'));
    final openRouter = find.byKey(const Key('provider-openrouter'));
    // The server's order: Anthropic's tile comes first (left of, or above, OpenRouter's).
    expect(y(anthropic) < y(openRouter) || (y(anthropic) == y(openRouter) && x(anthropic) < x(openRouter)), isTrue);
    expect(find.textContaining('Claude models'), findsWidgets);
  });

  testWidgets('Admin\'s JSON editor shows the saved value and saves an edit', (
    tester,
  ) async {
    await setSize(tester, const Size(800, 1200));
    final backend = FakeBackend()
      ..adminJsonSettings[AdminJsonSettingKind.browserGuard] = {
        'banking': ['mybank.example'],
      };
    await tester.pumpWidget(
      harness(
        backend,
        const Scaffold(
          body: AdminJsonSettingTile(kind: AdminJsonSettingKind.browserGuard),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminJson-browserGuard')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('adminJsonField-browserGuard'));
    expect(
      tester.widget<TextField>(field).controller!.text,
      contains('mybank.example'),
    );
    await tester.enterText(field, 'not json');
    await tester.tap(find.byKey(const Key('adminJsonSave-browserGuard')));
    await tester.pumpAndSettle();
    expect(find.textContaining("isn't valid JSON"), findsOneWidget);
    await tester.enterText(field, '{"health": ["clinic.example"]}');
    await tester.tap(find.byKey(const Key('adminJsonSave-browserGuard')));
    await tester.pumpAndSettle();
    expect(backend.adminJsonSettings[AdminJsonSettingKind.browserGuard], {
      'health': ['clinic.example'],
    });
  });
}
