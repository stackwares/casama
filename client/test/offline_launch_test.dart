// Offline launch (D-158): the app starts from the server settings and workspaces it saved, and a
// failed workspace load never starts the welcome flow.
import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/core/server_config_cache.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/main.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'fake_backend.dart';

/// Workspaces on demand: slow (a pending future) or failing (offline).
class _Backend extends FakeBackend {
  Completer<List<OrganizationWithRole>>? pending;
  Object? failure;

  @override
  Future<List<OrganizationWithRole>> organizations() async {
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return super.organizations();
  }
}

PublicConfig _config({String supabaseUrl = 'https://db.example.com'}) => PublicConfig.fromJson({
  'product_name': 'Casama',
  'api_version': '1',
  'supabase_url': supabaseUrl,
  'supabase_anon_key': 'anon',
  'billing_enabled': false,
  'default_models': {'openrouter': 'meta/muse-ember'},
  'default_reasoning_effort': 'medium',
});

Future<OrganizationWithRole> _org(String name) async {
  final org = (await FakeBackend().organizations()).first;
  return OrganizationWithRole.fromJson({...org.toJson(), 'name': name});
}

void main() {
  test('server settings are saved per server and read back', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ServerConfigCache.read('https://a.example.com'), isNull);
    await ServerConfigCache.write('https://a.example.com', _config());
    expect((await ServerConfigCache.read('https://a.example.com'))?.supabaseUrl, 'https://db.example.com');
    expect(await ServerConfigCache.read('https://b.example.com'), isNull);
    expect(ServerConfigCache.moved(_config(), _config()), isFalse);
    expect(ServerConfigCache.moved(_config(), _config(supabaseUrl: 'https://other.example.com')), isTrue);
  });

  test('launch starts from the saved settings without reaching the server', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // bootstrap opens the offline cache, which asks path_provider where to keep it.
    final dir = Directory.systemTemp.createTempSync('casama_cache');
    addTearDown(() => dir.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => dir.path);
    const url = 'http://casama.invalid';
    // Never reached and nothing saved: it fails, and the startup gate offers Retry.
    await expectLater(bootstrap(const AppConfig(apiUrl: url)), throwsA(anything));
    await ServerConfigCache.write(url, _config(supabaseUrl: 'http://db.casama.invalid'));
    final (_, backend) = await bootstrap(const AppConfig(apiUrl: url));
    expect(backend.config?.supabaseUrl, 'http://db.casama.invalid');
    await Supabase.instance.dispose();
  });

  test('unreadable saved settings mean none', () async {
    SharedPreferences.setMockInitialValues({'casama.server_config.https://a.example.com': '{"broken": true}'});
    expect(await ServerConfigCache.read('https://a.example.com'), isNull);
  });

  group('workspaces', () {
    late _Backend backend;
    late MemoryCache cache;
    late ProviderContainer container;

    setUp(() async {
      backend = _Backend();
      cache = MemoryCache();
      // No automatic retries: a failure should show at once here.
      container = ProviderContainer(retry: (_, _) => null, overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(cache)]);
      addTearDown(container.dispose);
      // Kept alive as the app would (Riverpod disposes what nothing listens to).
      container.listen(signedInProvider, (_, _) {});
      container.listen(organizationsProvider, (_, _) {}, onError: (_, _) {});
      await container.read(signedInProvider.future);
    });

    Future<void> save(List<String> names) async => cache.write('orgs:${backend.userId}', [for (final n in names) (await _org(n)).toJson()]);

    test('show the saved ones at launch, then the server\'s', () async {
      await save(['Saved']);
      backend.pending = Completer();
      final first = await container.read(organizationsProvider.future);
      expect(first.map((o) => o.name), ['Saved']);
      backend.pending!.complete([await _org('Fresh')]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(organizationsProvider).value?.map((o) => o.name), ['Fresh']);
      // And they're saved for next time.
      expect((cache.data['orgs:${backend.userId}'] ?? '').contains('Fresh'), isTrue);
    });

    test('offline, the saved ones stay; with none saved, it fails', () async {
      backend.failure = Exception('offline');
      await expectLater(container.read(organizationsProvider.future), throwsException);
      await save(['Saved']);
      container.invalidate(organizationsProvider);
      expect((await container.read(organizationsProvider.future)).map((o) => o.name), ['Saved']);
    });

    test('after a change the server is awaited, never the saved list', () async {
      await save(['Old']);
      await container.read(organizationsProvider.future);
      backend.pending = Completer();
      container.invalidate(organizationsProvider);
      final next = container.read(organizationsProvider.future);
      var done = false;
      unawaited(next.then((_) => done = true));
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse, reason: 'the saved list was shown after a change');
      backend.pending!.complete([await _org('Old'), await _org('Just created')]);
      expect((await next).map((o) => o.name), ['Old', 'Just created']);
    });
  });

  testWidgets('a failed workspace load doesn\'t start the welcome flow', (tester) async {
    final backend = _Backend()..failure = Exception('offline');
    final container = ProviderContainer(retry: (_, _) => null, overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(const NoCache())]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(container.read(organizationsProvider).hasError, isTrue);
    expect(router.routerDelegate.currentConfiguration.uri.path, isNot('/welcome'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
