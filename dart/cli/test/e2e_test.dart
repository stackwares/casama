// End-to-end Phase 0 gate through the real CLI. Runs only when KASAMA_E2E_API is set
// (see scripts/e2e-cli.sh, which starts a stack and sets it).
import 'dart:convert';
import 'dart:io';

import 'package:kasama_cli/kasama_cli.dart';
import 'package:test/test.dart';

void main() {
  final api = Platform.environment['KASAMA_E2E_API'];

  Future<(int, Map<String, dynamic>)> kasama(String configDir, List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runCli(['--api', api!, '--json', ...args],
        out: out, err: err, configDir: Directory(configDir));
    final text = (code == 0 ? out : err).toString().trim();
    return (code, text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>);
  }

  test('sign up, log in, create a workspace, invite and join', () async {
    final owner = Directory.systemTemp.createTempSync('kasama-owner').path;
    final friend = Directory.systemTemp.createTempSync('kasama-friend').path;

    // Each user gets their own config dir (session file).
    Future<(int, Map<String, dynamic>)> as(String dir, List<String> args) => kasama(dir, args);

    var (code, out) = await as(owner, ['signup', '--email', 'owner@example.com', '--password', 'pw-123456']);
    expect(code, 0, reason: '$out');
    (code, out) = await as(owner, ['logout']);
    (code, out) = await as(owner, ['whoami']);
    expect(code, 1);
    expect(out['error'], 'not_logged_in');
    (code, out) = await as(owner, ['login', '--email', 'owner@example.com', '--password', 'wrong']);
    expect(code, 1);
    expect(out['error'], 'auth_failed');
    (code, out) = await as(owner, ['login', '--email', 'owner@example.com', '--password', 'pw-123456']);
    expect(code, 0, reason: '$out');

    (code, out) = await as(owner, ['org', 'create', 'Acme', 'Team']);
    expect(code, 0, reason: '$out');
    expect(out['slug'], 'acme-team');

    (code, out) = await as(owner, ['org', 'invite', 'friend@example.com', '--org', 'acme-team']);
    expect(code, 0, reason: '$out');
    final token = out['accept_token'] as String;

    (code, out) = await as(friend, ['signup', '--email', 'friend@example.com', '--password', 'pw-654321']);
    expect(code, 0, reason: '$out');
    (code, out) = await as(friend, ['invite', 'accept', token]);
    expect(code, 0, reason: '$out');
    expect(out['role'], 'member');

    (code, out) = await as(friend, ['whoami']);
    expect(code, 0);
    final orgs = (out['organizations'] as List).cast<Map<String, dynamic>>();
    expect(orgs.single['slug'], 'acme-team');
    expect(orgs.single['role'], 'member');

    (code, out) = await as(friend, ['org', 'invite', 'x@example.com', '--org', 'acme-team']);
    expect(code, 1);
    expect(out['error'], 'forbidden');
  }, skip: api == null ? 'set KASAMA_E2E_API (run scripts/e2e-cli.sh)' : false);

  test('Phase 1 gate: chat streams, memory carries across chats, keys never come back', () async {
    final dir = Directory.systemTemp.createTempSync('kasama-p1').path;
    const key = 'sk-or-v1-E2E-SECRET-KEY-abcdef123456';
    final outputs = <String>[];

    Future<(int, String, String)> raw(List<String> args) async {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = await runCli(['--api', api!, ...args], out: out, err: err, configDir: Directory(dir));
      outputs..add(out.toString())..add(err.toString());
      return (code, out.toString(), err.toString());
    }

    expect((await raw(['signup', '--email', 'p1@example.com', '--password', 'pw-123456'])).$1, 0);
    expect((await raw(['org', 'create', 'Phase One', '--slug', 'phase-one'])).$1, 0);
    expect((await raw(['org', 'use', 'phase-one'])).$1, 0);

    var (code, out, err) = await raw(['--json', 'credential', 'add', '--provider', 'openrouter', '--label', 'Main', '--key', key]);
    expect(code, 0, reason: err);
    final cred = jsonDecode(out) as Map<String, dynamic>;
    expect(cred['key_hint'], '3456');

    (code, out, err) = await raw(['credential', 'test', cred['id'] as String]);
    expect(code, 0, reason: err);
    expect(out, contains('OK'));

    (code, out, err) = await raw(['bot', 'create', 'Ada', '--credential', cred['id'] as String, '--model', 'fixture-main', '--persona', 'Brief.']);
    expect(code, 0, reason: err);

    // Chat streams the reply and shows the tool step.
    (code, out, err) = await raw(['chat', 'ada', 'Remember this: my favorite color is teal.']);
    expect(code, 0, reason: err);
    String flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
    expect(flat(out), "Noted. Got it, I'll remember that.");
    expect(err, contains('→ memory.write'));
    expect(err, contains('remembered'));

    // A new conversation recalls the fact.
    (code, out, err) = await raw(['chat', 'Ada', 'What is my favorite color?']);
    expect(code, 0, reason: err);
    expect(flat(out), 'Your favorite color is teal.');

    // --json streams typed events.
    (code, out, err) = await raw(['--json', 'chat', 'Ada', 'hello']);
    expect(code, 0, reason: err);
    final events = const LineSplitter().convert(out).map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
    expect(events.first['type'], 'run.started');
    expect(events.last['type'], 'run.completed');
    final runId = events.first['run_id'] as String;

    // runs watch replays a finished run.
    (code, out, err) = await raw(['runs', 'watch', runId]);
    expect(code, 0, reason: err);
    expect(flat(out), 'Hello! How can I help?');

    (code, out, err) = await raw(['memory', 'list', 'Ada']);
    expect(code, 0, reason: err);
    expect(out, contains('teal'));

    (code, out, err) = await raw(['usage']);
    expect(code, 0, reason: err);
    expect(out, contains('Ada'));

    for (final o in outputs) {
      expect(o, isNot(contains(key)));
    }
  }, skip: api == null ? 'set KASAMA_E2E_API (run scripts/e2e-cli.sh)' : false);
}

