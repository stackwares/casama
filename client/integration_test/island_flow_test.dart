// The island's on-device check on a Mac (D-324, Phases 1 and 2): a run shows in the notch, stays
// there when another app is in front, opens on hover, stops; a request that needs an OK opens the
// notch by itself and is allowed from it; the window closes without quitting and comes back from
// the Dock. Phase 2: asking from the notch (and picking the bot), dropping a file, the two
// switches, a display without a notch, screenshots, VoiceOver labels, and Open at Login. Phase 6:
// a voice call with its level meter, Mute and Hang up. Runs are written straight into the local database (no model needed); the notch's
// buttons are pressed through the same handlers they call (debug builds only), since a test can't
// move the real pointer.
//
//   flutter test integration_test/island_flow_test.dart -d macos \
//     --dart-define=CASAMA_API_URL=http://localhost:8787 \
//     --dart-define=ISLAND_DB_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres \
//     --dart-define=ISLAND_SNAPSHOTS=/tmp/island
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:casama/core/config.dart';
import 'package:casama/features/island/island_bridge.dart';
import 'package:casama/features/island/island_call.dart';
import 'package:casama/features/island/island_settings.dart';
import 'package:casama/features/quick_ask/quick_ask_screen.dart';
import 'package:casama/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _db = String.fromEnvironment('ISLAND_DB_URL');
const _psql = String.fromEnvironment('ISLAND_PSQL', defaultValue: '/opt/homebrew/opt/postgresql@17/bin/psql');
const _snapshots = String.fromEnvironment('ISLAND_SNAPSHOTS');
const _island = MethodChannel('casama/island');

Future<String> sql(String query) async {
  final r = await Process.run(_psql, [_db, '-qAt', '-v', 'ON_ERROR_STOP=1', '-c', query]);
  if (r.exitCode != 0) throw StateError('psql: ${r.stderr}');
  return (r.stdout as String).trim();
}

Future<Map<String, Object?>> notch() async =>
    Map<String, Object?>.from(await _island.invokeMethod('debug', {'op': 'state'}) as Map);

Future<void> debug(String op, [Map<String, Object?> args = const {}]) => _island.invokeMethod('debug', {'op': op, ...args});

Future<void> snapshot(String name) async {
  if (_snapshots.isEmpty) return;
  await Directory(_snapshots).create(recursive: true);
  final files = await _island.invokeMethod('debug', {'op': 'snapshot', 'path': '$_snapshots/$name'});
  debugPrint('ISLAND snapshot $name: $files');
}

/// Pumps until [test] holds for the notch's state (or fails after [timeout]).
Future<Map<String, Object?>> until(WidgetTester tester, String what, bool Function(Map<String, Object?>) test, {Duration timeout = const Duration(seconds: 25)}) async {
  final end = DateTime.now().add(timeout);
  Map<String, Object?> last = const {};
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    last = await notch();
    if (test(last)) {
      debugPrint('ISLAND ok: $what  $last');
      return last;
    }
  }
  throw TestFailure('Timed out waiting for $what. Notch: $last');
}

Future<void> untilDb(WidgetTester tester, String what, String query, String expected) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  var last = '';
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    last = await sql(query);
    if (last == expected) {
      debugPrint('ISLAND ok: $what ($last)');
      return;
    }
  }
  throw TestFailure('Timed out waiting for $what: got "$last"');
}

List<String> items(Map<String, Object?> s) => [for (final i in s['items'] as List) '$i'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the notch follows a run, stops it, answers a request; the window closes and comes back', (tester) async {
    expect(_db, isNotEmpty, reason: 'pass --dart-define=ISLAND_DB_URL');
    final (app, backend) = await bootstrap(AppConfig.fromEnvironment);
    if (backend.isSignedIn) await backend.signOut();
    final email = 'island-${Random().nextInt(1 << 30)}@example.com';
    if (!await backend.signUp(email, 'pw-123456')) {
      // The local stack asks new accounts to confirm their email: confirm it here.
      await sql("update auth.users set email_confirmed_at = now() where email = '$email'");
      await backend.signIn(email, 'pw-123456');
    }
    final org = await backend.createOrganization('Island Test');
    final key = await backend.addCredential(org.id, ProviderId.openrouter, 'Test key', apiKey: 'sk-or-v1-island-test');
    final bot = await backend.createBot(org.id, name: 'Ada', credentialId: key.id, model: 'fixture-main');
    final me = backend.userId!;
    await tester.pumpWidget(app);
    await tester.pump(const Duration(seconds: 3));

    // Nothing runs: the menu bar item is there; the panel waits behind a real notch, the size of
    // the notch (black on black), and is off screen on a display without one.
    var s = await until(
      tester,
      'resting',
      (s) => s['statusItem'] == true && s['mode'] == 'hidden' && s['panelVisible'] == s['hasNotch'] && (s['hasNotch'] != true || s['panelSize'] == s['shape']),
    );
    expect(s['panelSharing'], 'none', reason: 'left out of screenshots, a bot\'s included');
    expect(s['labels'], greaterThan(5));
    debugPrint('ISLAND geometry: notch ${s['notch']} hasNotch ${s['hasNotch']}');

    // A run starts (as the person, from a chat) and searches the web.
    final run1 = await sql(
      "insert into public.runs (org_id, bot_id, created_by, trigger, status, started_at) "
      "values ('${org.id}', '${bot.id}', '$me', 'chat', 'running', now()) returning id",
    );
    final search = jsonEncode({'call_id': 'c1', 'tool': 'web.search', 'args_redacted': {'query': 'repotting ferns'}});
    await sql("select public.append_run_event('$run1', 'tool.started', '$search'::jsonb)");
    await sql("update public.bots set status = 'working' where id = '${bot.id}'");
    s = await until(tester, 'run in the notch', (s) => items(s).contains(run1) && s['mode'] == 'compact' && s['panelVisible'] == true);
    expect(s['panelLevel'], greaterThan(24), reason: 'above the menu bar');
    expect(s['panelSpaces'], isTrue);
    expect(s['panelFullScreen'], isTrue);
    expect(s['panelCanBecomeKey'], isFalse);
    expect(s['appNap'], isTrue, reason: 'no App Nap while a bot works');
    await snapshot('1-compact');

    // Another app comes to the front: the notch stays.
    await debug('deactivate');
    s = await until(tester, 'still shown with another app in front', (s) => s['appActive'] == false && s['panelVisible'] == true && items(s).contains(run1));

    // Hover opens the list after a short pause; leaving closes it.
    await debug('hover', {'inside': true});
    s = await until(tester, 'open on hover', (s) => s['mode'] == 'open');
    await snapshot('2-open');
    await debug('hover', {'inside': false});
    s = await until(tester, 'closed after the pointer leaves', (s) => s['mode'] == 'compact');

    // Stop from the notch: the server is asked to cancel; when the run is cancelled it leaves.
    await debug('press', {'id': run1, 'action': 'stop'});
    await untilDb(tester, 'Stop reached the server', "select cancel_requested_at is not null from public.runs where id = '$run1'", 't');
    await sql("update public.runs set status = 'cancelled', ended_at = now() where id = '$run1'");
    await sql("select public.append_run_event('$run1', 'run.cancelled', '{}'::jsonb)");
    await sql("update public.bots set status = 'idle' where id = '${bot.id}'");
    s = await until(tester, 'a stopped run leaves at once', (s) => !items(s).contains(run1) && s['mode'] == 'hidden');

    // A request that needs an OK, while another app is in front: the notch opens by itself.
    await debug('deactivate');
    final run2 = await sql(
      "insert into public.runs (org_id, bot_id, created_by, trigger, status, started_at) "
      "values ('${org.id}', '${bot.id}', '$me', 'chat', 'waiting_approval', now()) returning id",
    );
    final approval = await sql(
      "insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk) "
      "values ('${org.id}', '${bot.id}', '$run2', 'c2', 'shell.exec', '{\"command\": \"rm -rf ~/old-backups\"}', 'Delete the old backups', 'high') returning id",
    );
    await sql("update public.bots set status = 'waiting' where id = '${bot.id}'");
    s = await until(tester, 'the notch opens by itself for the request', (s) => items(s).contains(run2) && s['mode'] == 'open' && s['statusDot'] == true);
    // Allow needs the request itself, which can arrive a moment after the run says it waits.
    s = await until(tester, 'the request is in the notch', (s) => (s['approvals'] as List? ?? const []).contains(approval));
    await snapshot('3-needs-ok');

    // Allow from the notch.
    await debug('press', {'id': run2, 'action': 'allow'});
    await untilDb(tester, 'Allow reached the server', "select status from public.approvals where id = '$approval'", 'approved');
    // The worker would carry on and finish; here the run is finished by hand.
    await sql("update public.runs set status = 'completed', ended_at = now() where id = '$run2'");
    await sql("update public.bots set status = 'idle' where id = '${bot.id}'");
    s = await until(tester, 'Finished, as a short peek', (s) => items(s).contains(run2) && '${s['mode']}'.startsWith('peek:'));
    await snapshot('4-finished');
    s = await until(tester, 'Finished leaves after a few seconds', (s) => s['mode'] == 'hidden', timeout: const Duration(seconds: 30));

    // The menu bar panel.
    await debug('togglePopover');
    s = await until(tester, 'menu bar panel open', (s) => s['popoverShown'] == true);
    await snapshot('5-menubar');
    await debug('togglePopover');
    s = await until(tester, 'menu bar panel closed', (s) => s['popoverShown'] == false);
    await debug('togglePopover');
    s = await until(tester, 'menu bar panel opens again', (s) => s['popoverShown'] == true);
    await debug('togglePopover');
    s = await until(tester, 'and closes again', (s) => s['popoverShown'] == false);

    // Closing the window keeps Casama running; the Dock icon brings it back.
    await debug('closeWindow');
    s = await until(tester, 'window closed, app still running', (s) => s['windowVisible'] == false && s['statusItem'] == true);
    await debug('dockClick');
    s = await until(tester, 'window back from the Dock', (s) => s['windowVisible'] == true);

    // ---- Phase 2 ----
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final bea = await backend.createBot(org.id, name: 'Bea', credentialId: key.id, model: 'fixture-main');
    s = await until(tester, 'both bots reach the ask field', (s) => s['bots'] == 2 && s['askBot'] != '');

    // Hovering the resting notch opens a small home: the ask field.
    await debug('deactivate');
    await debug('hover', {'inside': true});
    s = await until(tester, 'home opens on hover', (s) => s['mode'] == 'open' && items(s).isEmpty);
    expect(s['panelKey'], isFalse, reason: 'hovering never takes the keyboard');
    await snapshot('6-home');
    final ax = [for (final l in await _island.invokeMethod('debug', {'op': 'ax'}) as List) '$l'];
    debugPrint('ISLAND ax home: $ax');
    expect(ax.any((l) => l.contains('Ask a bot')), isTrue, reason: 'the ask field has a VoiceOver label');

    // Typing takes the keyboard; Enter sends to the picked bot without opening the window.
    await debug('closeWindow');
    await debug('pickBot', {'id': bea.id});
    await debug('beginTyping');
    // The panel asks for the keyboard. (macOS hands it over only on a real click, which a test
    // can't make: this test app is never in front.)
    s = await until(tester, 'the panel asks for the keyboard while the field is in use', (s) => s['panelCanBecomeKey'] == true && s['typing'] == true);
    await debug('send', {'text': 'Say hi to the ferns'});
    await debug('hover', {'inside': false});
    await untilDb(tester, 'the ask reached Bea', "select count(*) from public.messages m join public.conversations c on c.id = m.conversation_id where c.bot_id = '${bea.id}' and m.role = 'user'", '1');
    final asked = await sql("select id from public.runs where bot_id = '${bea.id}' order by created_at desc limit 1");
    s = await until(tester, 'the asked run shows in the notch at once', (s) => items(s).contains(asked));
    expect(s['panelCanBecomeKey'], isFalse, reason: 'the keyboard goes back after Enter');
    expect(s['typing'], isFalse);
    expect(s['windowVisible'], isFalse, reason: 'asking from the notch leaves the window closed');
    await sql("update public.runs set status = 'cancelled', ended_at = now() where id = '$asked' and ended_at is null");
    s = await until(tester, 'the asked run leaves', (s) => !items(s).contains(asked) && s['mode'] == 'hidden', timeout: const Duration(seconds: 40));

    // VoiceOver reads a working run in the compact notch.
    final run3 = await sql(
      "insert into public.runs (org_id, bot_id, created_by, trigger, status, started_at) "
      "values ('${org.id}', '${bot.id}', '$me', 'chat', 'running', now()) returning id",
    );
    await sql("select public.append_run_event('$run3', 'tool.started', '$search'::jsonb)");
    await sql("update public.bots set status = 'working' where id = '${bot.id}'");
    s = await until(tester, 'run 3 in the notch', (s) => items(s).contains(run3) && s['mode'] == 'compact');
    final axCompact = [for (final l in await _island.invokeMethod('debug', {'op': 'ax'}) as List) '$l'];
    debugPrint('ISLAND ax compact: $axCompact');
    expect(axCompact.any((l) => l.contains('Ada') && l.contains('Searching the web')), isTrue);

    // Open the notch on hover, off: hovering does nothing, a click opens it with the keyboard.
    await container.read(islandHoverOpensProvider.notifier).set(false);
    s = await until(tester, 'hover switch off reached the notch', (s) => s['hoverOpens'] == false);
    await debug('hover', {'inside': true});
    await tester.pump(const Duration(seconds: 1));
    expect((await notch())['mode'], 'compact', reason: 'no hover opening with the switch off');
    await debug('hover', {'inside': false});
    await debug('click');
    s = await until(tester, 'a click opens it, asking for the keyboard', (s) => s['mode'] == 'open' && s['panelCanBecomeKey'] == true);
    await snapshot('9-open-with-ask');
    final axOpen = [for (final l in await _island.invokeMethod('debug', {'op': 'ax'}) as List) '$l'];
    debugPrint('ISLAND ax open: $axOpen');
    expect(axOpen.any((l) => l.contains('Stop')), isTrue);
    await debug('deactivate');
    await container.read(islandHoverOpensProvider.notifier).set(true);

    // Show bots in the notch, off: the notch leaves (the menu bar keeps it) and the window may
    // stay on top again while a bot uses this Mac (decision 10).
    await container.read(islandNotchOnProvider.notifier).set(false);
    s = await until(tester, 'notch off', (s) => s['notchOn'] == false && s['panelVisible'] == false && s['statusItem'] == true);
    expect(container.read(islandOnScreenProvider), isFalse);
    await container.read(islandNotchOnProvider.notifier).set(true);
    s = await until(tester, 'notch on again', (s) => s['notchOn'] == true && s['mode'] == 'compact' && s['panelVisible'] == true);
    expect(container.read(islandOnScreenProvider), isTrue);

    // A display without a notch: the same shape hangs from the top centre, only while there's
    // something to show.
    await debug('noNotch', {'on': true});
    s = await until(tester, 'no-notch compact', (s) => s['hasNotch'] == false && s['mode'] == 'compact' && s['panelVisible'] == true);
    debugPrint('ISLAND no-notch compact frame ${s['panelFrame']}');
    await snapshot('7-no-notch');
    await sql("update public.runs set status = 'cancelled', ended_at = now() where id = '$run3'");
    await sql("update public.bots set status = 'idle' where id = '${bot.id}'");
    s = await until(tester, 'no-notch rest leaves the screen', (s) => s['mode'] == 'hidden' && s['panelVisible'] == false);
    await debug('noNotch', {'on': false});
    s = await until(tester, 'back on the notch: resting behind it', (s) => s['hasNotch'] == true && s['panelVisible'] == true);

    // Dropping a file on the notch opens Quick ask with it.
    final file = File('${Directory.systemTemp.path}/island-drop.txt')..writeAsStringSync('ferns');
    await debug('drag', {'inside': true});
    s = await until(tester, 'a drop target while files are dragged over', (s) => s['mode'] == 'drop');
    await snapshot('8-drop');
    await debug('drag', {'inside': false});
    s = await until(tester, 'back to rest when the drag leaves', (s) => s['mode'] == 'hidden');
    await debug('closeWindow');
    await debug('drop', {'paths': [file.path]});
    s = await until(tester, 'the window comes forward for the drop', (s) => s['windowVisible'] == true);
    final end = DateTime.now().add(const Duration(seconds: 10));
    while (find.byType(QuickAskScreen).evaluate().isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(QuickAskScreen), findsOneWidget, reason: 'the dropped file opens Quick ask');
    debugPrint('ISLAND ok: drop opened Quick ask');

    // Open at Login starts in the menu bar, without the window.
    await debug('loginLaunch');
    s = await until(tester, 'started at login: window hidden, menu bar there', (s) => s['windowVisible'] == false && s['statusItem'] == true);
    await debug('dockClick');
    s = await until(tester, 'and back from the Dock', (s) => s['windowVisible'] == true);

    // Phase 6: a voice call in the notch, with its level meter, Mute and Hang up. The call screen
    // reports the call (its own test covers that); here a stand-in does, so no voice model is needed.
    final calls = container.read(islandCallProvider.notifier);
    final call = _Call()..notifier = calls;
    calls.live(IslandCall(botId: bot.id, startedAt: DateTime.now()), call);
    s = await until(
      tester,
      'a call in the notch',
      (s) => (s['call'] as Map?)?['bot'] == 'Ada' && s['mode'] == 'compact' && s['panelVisible'] == true,
    );
    call.level = 0.8;
    s = await until(tester, 'the level meter moves', (s) => (s['level'] as num) > 0.5);
    await snapshot('10-call');
    await debug('hover', {'inside': true});
    s = await until(tester, 'the call row on hover', (s) => s['mode'] == 'open');
    await snapshot('11-call-open');
    await debug('press', {'id': 'call', 'action': 'mute'});
    s = await until(tester, 'muted from the notch', (s) => (s['call'] as Map?)?['muted'] == true);
    expect(call.done, ['mute']);
    await snapshot('12-call-muted');
    await debug('press', {'id': 'call', 'action': 'end'});
    await tester.pump(const Duration(milliseconds: 300));
    expect(call.done, ['mute', 'end']);
    await debug('hover', {'inside': false});
    s = await until(tester, 'the call leaves with the call', (s) => (s['call'] as Map?)?.isEmpty != false && s['mode'] == 'hidden');
  });
}

/// Stands in for the call screen: Mute flips the call's state, as the screen does.
class _Call implements IslandCallControls {
  final done = <String>[];
  late final IslandCallNotifier notifier;
  bool muted = false;
  @override
  double level = 0;
  @override
  void toggleMute() {
    done.add('mute');
    muted = !muted;
    notifier.muted(muted);
  }

  @override
  void hangUp() {
    done.add('end');
    notifier.ended(this);
  }
}
