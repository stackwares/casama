// The island's on-device check on Android (D-324, Phase 5), in the emulator: a run the person
// started gets a live notification (a Live Update on Android 16 and later) that follows its step,
// turns into Needs your OK, ends as Finished (cleared after 15 minutes), and a run stopped from its
// Stop button leaves at once. Phase 6: Stop and Deny pressed on the notification act without the
// app moving; a request that isn't high risk offers Allow and Deny, behind unlocking. The RemoteViews form (older Android, or Live Updates turned off) and a
// server push drawn by the native receiver are checked too. Runs are written through the local
// stack's REST API with the service key. It pauses at each state (ISLAND pause lines) so the shade
// and the lock screen can be looked at from outside.
//
//   adb reverse tcp:8787 tcp:8787 && adb reverse tcp:54321 tcp:54321
//   flutter test integration_test/island_android_test.dart -d <emulator> \
//     --dart-define=CASAMA_API_URL=http://127.0.0.1:8787 \
//     --dart-define=ISLAND_REST_URL=http://127.0.0.1:54321 \
//     --dart-define=ISLAND_SERVICE_KEY=<local service role key> \
//     --dart-define=ISLAND_PAUSE=20
//
// With --dart-define-from-file=config/firebase.json and ISLAND_PUSH_WAIT=<seconds>, it also
// registers the phone's Firebase token for a run and waits while a real push is sent from outside
// (packages/agent/scripts/live-push-local.ts with LIVE_SEND=1). Send Casama to the background
// before the push (pushes wait while the app is in front, its own feed being live), and bring it
// back after: the test only moves on while the app draws frames.
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
const _pushWait = int.fromEnvironment('ISLAND_PUSH_WAIT', defaultValue: 0);
const _island = MethodChannel('casama/island');

final _http = HttpClient();

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

Future<List<Map<String, Object?>>> shown() async => [
  for (final a in await _island.invokeMethod('debug') as List) Map<String, Object?>.from(a as Map),
];

Future<Map<String, Object?>> widget() async =>
    Map<String, Object?>.from(await _island.invokeMethod('debugWidget') as Map);

Future<Map<String, Object?>> until(
  WidgetTester tester,
  String what,
  bool Function(Map<String, Object?>?) test,
  String run,
) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  Map<String, Object?>? last;
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    last = (await shown()).where((a) => a['run_id'] == run).firstOrNull;
    if (test(last)) {
      debugPrint('ISLAND ok: $what  $last');
      return last ?? const {};
    }
  }
  throw TestFailure('Timed out waiting for $what. Notification: $last');
}

Future<void> pause(WidgetTester tester, String name) async {
  if (_pause <= 0) return;
  debugPrint('ISLAND pause: $name');
  final end = DateTime.now().add(const Duration(seconds: _pause));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

String _now() => DateTime.now().toUtc().toIso8601String();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a run as a live notification: working, needs your OK, finished; Stop ends it', (tester) async {
    expect(_key, isNotEmpty, reason: 'pass --dart-define=ISLAND_SERVICE_KEY');
    final (app, backend) = await bootstrap(AppConfig.fromEnvironment);
    if (backend.isSignedIn) await backend.signOut();
    final email = 'island-android-${Random().nextInt(1 << 30)}@example.com';
    await rest('POST', '/auth/v1/admin/users', {'email': email, 'password': 'pw-123456', 'email_confirm': true});
    await backend.signIn(email, 'pw-123456');
    final org = await backend.createOrganization('Island Android');
    final key = await backend.addCredential(org.id, ProviderId.openrouter, 'Test key', apiKey: 'sk-or-v1-island-test');
    final bot = await backend.createBot(org.id, name: 'Ada', credentialId: key.id, model: 'fixture-main');
    final me = backend.userId!;
    await tester.pumpWidget(app);
    await tester.pump(const Duration(seconds: 3));
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    // A fresh install has notifications off until they're allowed (from outside, in the emulator).
    debugPrint('ISLAND waiting for notifications to be allowed');
    final allowBy = DateTime.now().add(const Duration(seconds: 60));
    while ((await widget())['enabled'] != true && DateTime.now().isBefore(allowBy)) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect((await widget())['enabled'], isTrue, reason: 'notifications are allowed for the app');

    Future<String> startRun() async {
      final run = await insert('runs', {
        'org_id': org.id,
        'bot_id': bot.id,
        'created_by': me,
        'trigger': 'chat',
        'status': 'running',
        'started_at': _now(),
      });
      await patch('bots', bot.id, {'status': 'working'});
      return run;
    }

    // A run the person started: a live notification with its step.
    final run = await startRun();
    await event(run, 'tool.started', {
      'call_id': 'c1',
      'tool': 'web.search',
      'args_redacted': {'query': 'repotting ferns'},
    });
    var n = await until(
      tester,
      'a notification for the run',
      (n) => n != null && n['phase'] == 'working' && n['step'] == 'Searching the web',
      run,
    );
    expect(n['enabled'], isTrue, reason: 'notifications are allowed for the app');
    expect(n['ongoing'], isTrue);
    expect(n['bot'], 'Ada');
    expect(n['steps'], 1);
    expect(n['public'], 'A bot is working', reason: 'the lock screen says only that a bot is working');
    expect(n['actions'], ['Stop', 'Open']);
    if ((n['sdk'] as int) >= 36 && n['can_promote'] == true) {
      expect(n['form'], 'live');
      expect(n['promotable'], isTrue, reason: 'it meets every Live Update rule');
      expect(n['promoted'], isTrue, reason: 'Android promoted it to a Live Update');
      expect(n['chip'], isNull, reason: 'the chip shows the running time while it works');
    } else {
      expect(n['form'], 'custom');
    }
    expect((await widget())['run_id'], run, reason: 'the home-screen widget shows the running bot');
    await pause(tester, 'working');

    // It asks for an OK.
    await patch('runs', run, {'status': 'waiting_approval'});
    final approval = await insert('approvals', {
      'org_id': org.id,
      'bot_id': bot.id,
      'run_id': run,
      'call_id': 'c2',
      'tool_name': 'shell.exec',
      'args_redacted': {'command': 'rm -rf ~/old-backups'},
      'summary': 'Delete the old backups',
      'risk': 'high',
    });
    await patch('bots', bot.id, {'status': 'waiting'});
    n = await until(
      tester,
      'Needs your OK',
      (n) => n?['phase'] == 'needsOk' && (n?['actions'] as List?)?.contains('Review') == true,
      run,
    );
    expect(n['actions'], ['Review', 'Open']);
    expect(n['step'], 'Working on its computer', reason: "the request's own words stay in the app (§10)");
    expect(n['public'], 'Needs your OK');
    if (n['form'] == 'live') expect(n['chip'], 'Needs you');
    await pause(tester, 'needs-ok');

    // Allowed (elsewhere) and finished: Finished, no longer ongoing, cleared after 15 minutes.
    await patch('approvals', approval, {'status': 'approved', 'decided_at': _now()});
    await patch('runs', run, {'status': 'completed', 'ended_at': _now()});
    await patch('bots', bot.id, {'status': 'idle'});
    n = await until(tester, 'Finished, kept for 15 minutes', (n) => n?['phase'] == 'finished', run);
    expect(n['ongoing'], isFalse);
    expect(n['promoted'], isFalse);
    expect(n['timeout_ms'], 15 * 60 * 1000);
    expect(n['actions'], isEmpty);
    expect((await widget())['run_id'], isNull, reason: 'the widget goes back to today');
    await pause(tester, 'finished');

    // Stop from the notification, in place (Phase 6): the app stops the run without moving, and
    // the notification leaves at once.
    final run2 = await startRun();
    await until(tester, 'a notification for run 2', (n) => n?['phase'] == 'working', run2);
    final before = container.read(routerProvider).state.uri.toString();
    expect(await _island.invokeMethod('debugAction', {'run_id': run2, 'title': 'Stop'}), isTrue);
    final end = DateTime.now().add(const Duration(seconds: 20));
    var asked = false;
    while (!asked && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 300));
      final rows = await rest('GET', '/rest/v1/runs?id=eq.$run2&select=cancel_requested_at') as List;
      asked = (rows.single as Map)['cancel_requested_at'] != null;
    }
    expect(asked, isTrue, reason: 'Stop reached the server');
    expect(container.read(routerProvider).state.uri.toString(), before, reason: 'done in place, the app stays where it was');
    debugPrint('ISLAND ok: Stop reached the server, in place');
    await patch('runs', run2, {'status': 'cancelled', 'ended_at': _now()});
    await event(run2, 'run.cancelled', {});
    await patch('bots', bot.id, {'status': 'idle'});
    await until(tester, 'a stopped run leaves at once', (n) => n == null, run2);

    // A request that isn't high risk is answered from the notification, after unlocking (Phase 6).
    final run5 = await startRun();
    await until(tester, 'a notification for run 5', (n) => n?['phase'] == 'working', run5);
    await patch('runs', run5, {'status': 'waiting_approval'});
    final approval5 = await insert('approvals', {
      'org_id': org.id,
      'bot_id': bot.id,
      'run_id': run5,
      'call_id': 'c5',
      'tool_name': 'calendar.create_event',
      'args_redacted': {'title': 'Dentist'},
      'summary': 'Add the dentist to the calendar',
      'risk': 'medium',
    });
    n = await until(
      tester,
      'Allow, Deny and Review',
      (n) => n?['phase'] == 'needsOk' && (n?['actions'] as List?)?.contains('Allow') == true,
      run5,
    );
    expect(n['actions'], ['Allow', 'Deny', 'Review']);
    if ((n['sdk'] as int) >= 31) expect(n['unlock'], ['Allow', 'Deny'], reason: 'they ask to unlock first');
    await pause(tester, 'answer-in-place');
    expect(await _island.invokeMethod('debugAction', {'run_id': run5, 'title': 'Deny'}), isTrue);
    final denyEnd = DateTime.now().add(const Duration(seconds: 20));
    var denied = false;
    while (!denied && DateTime.now().isBefore(denyEnd)) {
      await tester.pump(const Duration(milliseconds: 300));
      final rows = await rest('GET', '/rest/v1/approvals?id=eq.$approval5&select=status') as List;
      denied = (rows.single as Map)['status'] == 'denied';
    }
    expect(denied, isTrue, reason: 'Deny reached the server from the notification');
    debugPrint('ISLAND ok: Deny answered in place');
    await patch('runs', run5, {'status': 'cancelled', 'ended_at': _now()});
    await event(run5, 'run.cancelled', {});
    await patch('bots', bot.id, {'status': 'idle'});
    await until(tester, 'run 5 leaves', (n) => n == null, run5);

    // The RemoteViews form: older Android, or Live Updates turned off for Casama.
    await _island.invokeMethod('debugForceCustom', true);
    final run3 = await startRun();
    n = await until(tester, 'the RemoteViews form', (n) => n?['phase'] == 'working', run3);
    expect(n['form'], 'custom');
    expect(n['promoted'], isFalse);
    expect(n['ongoing'], isTrue);
    await pause(tester, 'custom');
    await _island.invokeMethod('debugForceCustom', false);

    // A server push (what LiveRunReceiver hands over when the app isn't running): drawn, an older
    // one ignored, and a stopped run's end removes it.
    final stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 5;
    Map<String, String> push(String phase, String step, int at, {String event = 'update', int? dismiss}) => {
      'kind': 'live',
      'run_id': run3,
      'bot_id': bot.id,
      'bot_name': 'Ada',
      'started_at': '${at - 30}',
      'link': '/chat',
      'event': event,
      'phase': phase,
      'step': step,
      'steps': '1',
      'approval_id': phase == 'needsOk' ? '7d4c2f1e-8a3b-4c5d-9e6f-0a1b2c3d4e5f' : '',
      'risk': '',
      'updated_at': '$at',
      'ended_at': '',
      'stale_at': '${at + 120}',
      'dismiss_at': dismiss == null ? '' : '$dismiss',
    };
    await _island.invokeMethod('debugPush', push('needsOk', 'Working on its computer', stamp));
    n = await until(
      tester,
      "the server's push drawn",
      (n) => n?['phase'] == 'needsOk' && n?['step'] == 'Working on its computer',
      run3,
    );
    expect(n['actions'], ['Review', 'Open'], reason: 'no risk in the push: reviewed in the app, never answered blind');
    await _island.invokeMethod('debugPush', push('working', 'Reading files', stamp - 60));
    await tester.pump(const Duration(seconds: 1));
    n = (await shown()).firstWhere((n) => n['run_id'] == run3);
    expect(n['phase'], 'needsOk', reason: 'an older push changes nothing');
    await pause(tester, 'pushed');
    await _island.invokeMethod(
      'debugPush',
      push('problem', 'Stopped with a problem', stamp + 1, event: 'end', dismiss: stamp + 1),
    );
    await until(tester, "a stopped run's push removes it", (n) => n == null, run3);
    await patch('runs', run3, {'status': 'cancelled', 'ended_at': _now()});
    await patch('bots', bot.id, {'status': 'idle'});

    // Push-to-start (Phase 6): a run the person started on another device arrives as a `start`
    // and is drawn, though this phone never saw it start; its end removes it.
    const elsewhere = '5b0c9e2a-1f3d-4e6a-8b7c-2d9e0f1a3b4c';
    Map<String, String> started(Map<String, String> m) => {...m, 'run_id': elsewhere};
    await _island.invokeMethod('debugPush', started(push('working', 'Searching the web', stamp + 2, event: 'start')));
    n = await until(tester, 'a run started elsewhere', (n) => n?['phase'] == 'working', elsewhere);
    expect(n['step'], 'Searching the web');
    expect(n['actions'], ['Stop', 'Open']);
    await _island.invokeMethod(
      'debugPush',
      started(push('problem', 'Stopped with a problem', stamp + 3, event: 'end', dismiss: stamp + 3)),
    );
    await until(tester, 'and its end removes it', (n) => n == null, elsewhere);

    if (_pushWait > 0) {
      // A real push through Firebase (D-324, Phases 4 and 5): the phone registers its token for
      // the run, a push is sent from outside, and the receiver draws what it said.
      final run4 = await startRun();
      await until(tester, 'a notification for run 4', (n) => n?['phase'] == 'working', run4);
      final end4 = DateTime.now().add(const Duration(seconds: 30));
      var registered = false;
      while (!registered && DateTime.now().isBefore(end4)) {
        await tester.pump(const Duration(milliseconds: 300));
        registered = (await rest(
          'GET',
          '/rest/v1/run_live_tokens?run_id=eq.$run4&platform=eq.android&select=id',
        ) as List).isNotEmpty;
      }
      expect(registered, isTrue, reason: "the phone's Firebase token reached the server for the run");
      debugPrint('ISLAND push: $run4');
      final until4 = DateTime.now().add(const Duration(seconds: _pushWait));
      Map<String, Object?>? n4;
      while (DateTime.now().isBefore(until4)) {
        await tester.pump(const Duration(milliseconds: 500));
        n4 = (await shown()).where((n) => n['run_id'] == run4).firstOrNull;
        if (n4?['phase'] == 'needsOk') break;
      }
      debugPrint('ISLAND after push: $n4');
      expect(n4?['phase'], 'needsOk', reason: "the server's push reached the phone");
      expect(n4?['step'], 'Working on its computer');
      await patch('runs', run4, {'status': 'completed', 'ended_at': _now()});
      await patch('bots', bot.id, {'status': 'idle'});
    }
  });
}
