// The island's on-device check on an iPhone (D-324, Phase 3), in the Simulator: a run the person
// started gets a Live Activity that follows its step, turns into Needs your OK, ends as Finished
// (kept on the Lock Screen), and a run stopped from the activity's Stop link ends it at once.
// Runs are written through the local stack's REST API with the service key (an iOS app can't
// start psql). It pauses at each state (ISLAND pause lines) so the Lock Screen and the Dynamic
// Island can be looked at from outside.
//
//   flutter test integration_test/island_ios_test.dart -d <simulator> \
//     --dart-define=CASAMA_API_URL=http://localhost:8787 \
//     --dart-define=ISLAND_REST_URL=http://127.0.0.1:54321 \
//     --dart-define=ISLAND_SERVICE_KEY=<local service role key> \
//     --dart-define=ISLAND_PAUSE=20
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:casama/core/config.dart';
import 'package:casama/core/router.dart';
import 'package:casama/main.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

const _rest = String.fromEnvironment('ISLAND_REST_URL', defaultValue: 'http://127.0.0.1:54321');
const _key = String.fromEnvironment('ISLAND_SERVICE_KEY');
const _pause = int.fromEnvironment('ISLAND_PAUSE', defaultValue: 0);
// Phase 4, by hand: hold a run's activity this long while a server push is delivered from
// outside (the app in the background), then check the activity shows what the push said.
const _pushWait = int.fromEnvironment('ISLAND_PUSH_WAIT', defaultValue: 0);
const _island = MethodChannel('casama/island');

final _http = HttpClient();

/// One call to the local stack as the service role.
Future<Object?> rest(String method, String path, [Object? body]) async {
  final req = await _http.openUrl(method, Uri.parse('$_rest$path'));
  req.headers
    ..set('apikey', _key)
    ..set('Authorization', 'Bearer $_key')
    ..set('Content-Type', 'application/json')
    ..set('Prefer', 'return=representation');
  if (body != null) req.write(jsonEncode(body));
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  if (res.statusCode >= 300) throw StateError('$method $path: ${res.statusCode} $text');
  return text.isEmpty ? null : jsonDecode(text);
}

Future<String> insert(String table, Map<String, Object?> row) async =>
    ((await rest('POST', '/rest/v1/$table', row) as List).single as Map)['id'] as String;

Future<void> patch(String table, String id, Map<String, Object?> fields) =>
    rest('PATCH', '/rest/v1/$table?id=eq.$id', fields);

Future<void> event(String run, String type, Map<String, Object?> payload) =>
    rest('POST', '/rest/v1/rpc/append_run_event', {'p_run_id': run, 'p_type': type, 'p_payload': payload});

Future<List<Map<String, Object?>>> activities() async => [
  for (final a in await _island.invokeMethod('debug') as List) Map<String, Object?>.from(a as Map),
];

Future<Map<String, Object?>> until(WidgetTester tester, String what, bool Function(Map<String, Object?>?) test, String run) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  Map<String, Object?>? last;
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    last = (await activities()).where((a) => a['run_id'] == run).firstOrNull;
    if (test(last)) {
      debugPrint('ISLAND ok: $what  $last');
      return last ?? const {};
    }
  }
  throw TestFailure('Timed out waiting for $what. Activity: $last');
}

Future<void> pause(WidgetTester tester, String name) async {
  if (_pause <= 0) return;
  debugPrint('ISLAND pause: $name');
  final end = DateTime.now().add(const Duration(seconds: _pause));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a run on the Lock Screen: working, needs your OK, finished; Stop ends it', (tester) async {
    expect(_key, isNotEmpty, reason: 'pass --dart-define=ISLAND_SERVICE_KEY');
    final (app, backend) = await bootstrap(AppConfig.fromEnvironment);
    if (backend.isSignedIn) await backend.signOut();
    final email = 'island-ios-${Random().nextInt(1 << 30)}@example.com';
    await rest('POST', '/auth/v1/admin/users', {'email': email, 'password': 'pw-123456', 'email_confirm': true});
    await backend.signIn(email, 'pw-123456');
    final org = await backend.createOrganization('Island iPhone');
    final key = await backend.addCredential(org.id, ProviderId.openrouter, 'Test key', apiKey: 'sk-or-v1-island-test');
    final bot = await backend.createBot(org.id, name: 'Ada', credentialId: key.id, model: 'fixture-main');
    final me = backend.userId!;
    await tester.pumpWidget(app);
    await tester.pump(const Duration(seconds: 3));
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    // A run the person started: an activity with its step.
    final run = await insert('runs', {
      'org_id': org.id, 'bot_id': bot.id, 'created_by': me, 'trigger': 'chat', 'status': 'running',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });
    await event(run, 'tool.started', {'call_id': 'c1', 'tool': 'web.search', 'args_redacted': {'query': 'repotting ferns'}});
    await patch('bots', bot.id, {'status': 'working'});
    var a = await until(tester, 'an activity for the run', (a) => a != null && a['phase'] == 'working' && a['step'] == 'Searching the web', run);
    expect(a['enabled'], isTrue);
    expect(a['stale_in'] as int, inInclusiveRange(60, 121), reason: 'goes stale two minutes after an update');
    expect(a['steps'], 1);
    expect(a['detail'], '', reason: 'what was searched stays off the Lock Screen (§10)');
    await pause(tester, 'working');

    // It asks for an OK.
    await patch('runs', run, {'status': 'waiting_approval'});
    final approval = await insert('approvals', {
      'org_id': org.id, 'bot_id': bot.id, 'run_id': run, 'call_id': 'c2', 'tool_name': 'shell.exec',
      'args_redacted': {'command': 'rm -rf ~/old-backups'}, 'summary': 'Delete the old backups', 'risk': 'high',
    });
    await patch('bots', bot.id, {'status': 'waiting'});
    a = await until(tester, 'Needs your OK', (a) => a?['phase'] == 'needsOk' && a?['approval_id'] == approval, run);
    expect(a['step'], 'Working on its computer', reason: "the request's own words stay in the app (§10)");
    await pause(tester, 'needs-ok');

    // Allowed (elsewhere) and finished: the activity ends as Finished and stays a while.
    await patch('approvals', approval, {'status': 'approved', 'decided_at': DateTime.now().toUtc().toIso8601String()});
    await patch('runs', run, {'status': 'completed', 'ended_at': DateTime.now().toUtc().toIso8601String()});
    await patch('bots', bot.id, {'status': 'idle'});
    a = await until(tester, 'Finished, kept on the Lock Screen', (a) => a?['phase'] == 'finished' && a?['state'] == 'ended', run);
    await pause(tester, 'finished');

    // Stop from the activity: the deep link stops the run, and its activity ends at once.
    final run2 = await insert('runs', {
      'org_id': org.id, 'bot_id': bot.id, 'created_by': me, 'trigger': 'chat', 'status': 'running',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });
    await patch('bots', bot.id, {'status': 'working'});
    await until(tester, 'an activity for run 2', (a) => a?['phase'] == 'working', run2);
    container.read(routerProvider).go('/runs/$run2/stop');
    final end = DateTime.now().add(const Duration(seconds: 20));
    var asked = false;
    while (!asked && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 300));
      final rows = await rest('GET', '/rest/v1/runs?id=eq.$run2&select=cancel_requested_at') as List;
      asked = (rows.single as Map)['cancel_requested_at'] != null;
    }
    expect(asked, isTrue, reason: 'Stop reached the server');
    debugPrint('ISLAND ok: Stop reached the server');
    await patch('runs', run2, {'status': 'cancelled', 'ended_at': DateTime.now().toUtc().toIso8601String()});
    await event(run2, 'run.cancelled', {});
    await patch('bots', bot.id, {'status': 'idle'});
    await until(tester, 'a stopped run\'s activity ends at once', (a) => a == null || a['state'] == 'dismissed' || (a['state'] == 'ended' && a['phase'] != 'finished'), run2);

    if (_pushWait > 0) {
      // A server push while the app sleeps (D-324, Phase 4): the activity registers its token,
      // a push is delivered from outside, and the activity shows the server's state.
      final run3 = await insert('runs', {
        'org_id': org.id, 'bot_id': bot.id, 'created_by': me, 'trigger': 'chat', 'status': 'running',
        'started_at': DateTime.now().toUtc().toIso8601String(),
      });
      await patch('bots', bot.id, {'status': 'working'});
      await until(tester, 'an activity for run 3 with its push token', (a) => a?['phase'] == 'working' && a?['token'] == true, run3);
      final end3 = DateTime.now().add(const Duration(seconds: 20));
      var registered = false;
      while (!registered && DateTime.now().isBefore(end3)) {
        await tester.pump(const Duration(milliseconds: 300));
        registered = (await rest('GET', '/rest/v1/run_live_tokens?run_id=eq.$run3&select=platform') as List).isNotEmpty;
      }
      expect(registered, isTrue, reason: 'the activity\'s push token reached the server');
      debugPrint('ISLAND push: $run3');
      final until3 = DateTime.now().add(const Duration(seconds: _pushWait));
      while (DateTime.now().isBefore(until3)) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      final a3 = (await activities()).where((a) => a['run_id'] == run3).firstOrNull;
      debugPrint('ISLAND after push: $a3');
      expect(a3?['phase'], 'needsOk', reason: 'the server\'s push reached the activity');
      expect(a3?['step'], 'Working on its computer');
      expect(a3?['steps'], 1);
      await patch('runs', run3, {'status': 'completed', 'ended_at': DateTime.now().toUtc().toIso8601String()});
      await patch('bots', bot.id, {'status': 'idle'});
    }
  });
}
