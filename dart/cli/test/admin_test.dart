import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_cli/src/commands_admin.dart';
import 'package:casama_cli/src/runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late StringBuffer out;
  late StringBuffer err;
  late CommandRunner<int> runner;
  late CliContext ctx;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('casama_admin_test');
    out = StringBuffer();
    err = StringBuffer();
    ctx = CliContext(out, err, configDirOverride: tmp);
    runner = CommandRunner<int>('casama', 'test')
      ..argParser.addFlag('json', negatable: false)
      ..addCommand(BillingCommand(ctx))
      ..addCommand(_Org(ctx));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<int> run(List<String> args) async {
    try {
      final top = runner.parse(args);
      ctx.json = top['json'] as bool;
      return await runner.runCommand(top) ?? 0;
    } on UsageException {
      return 64;
    } on CliError catch (e) {
      return ctx.fail(e.code, e.message);
    }
  }

  test('commands need a login', () async {
    for (final args in [
      ['org', 'members'],
      ['org', 'invites'],
      ['org', 'settings'],
      ['org', 'mcp-keys'],
      ['org', 'encryption'],
      ['billing', 'show'],
      ['billing', 'portal'],
    ]) {
      expect(await run(args), 1, reason: args.join(' '));
      expect(err.toString(), contains('not_logged_in'));
    }
  });

  test('usage errors exit 64', () async {
    expect(await run(['org', 'invite-resend']), 64);
    expect(await run(['org', 'request', 'abc']), 64);
    expect(await run(['org', 'request', 'abc', 'maybe']), 64);
    expect(await run(['org', 'mcp-key-create']), 64);
    expect(await run(['org', 'settings', 'nope=1']), 64);
    expect(await run(['billing', 'upgrade']), 64);
    expect(await run(['billing', 'upgrade', '--plan', 'gold']), 64);
  });

  test('revokes and deletes print what would happen without --yes', () async {
    for (final args in [
      ['org', 'invite-revoke', 'i1'],
      ['org', 'invite-link-delete', 'l1'],
      ['org', 'mcp-key-delete', 'k1'],
      ['org', 'git-sync-off'],
      ['billing', 'upgrade', '--plan', 'pro'],
    ]) {
      out.clear();
      expect(await run(args), 0, reason: args.join(' '));
      expect(out.toString(), contains('--yes'));
    }
  });

  test('--json gate output', () async {
    expect(await run(['--json', 'org', 'invite-revoke', 'i1']), 0);
    expect(out.toString(), contains('"would"'));
    expect(out.toString(), contains('"confirm": "--yes"'));
  });

  test('parseEmails', () {
    expect(parseEmails('a@x.com, b@x.com\n# note\nc@x.com # hi\na@x.com\n\n'), [
      'a@x.com',
      'b@x.com',
      'c@x.com',
    ]);
  });

  test('parseSettingsArgs', () {
    expect(
      parseSettingsArgs([
        'require-mfa=true',
        'run_event_retention_days=30',
        'chrome_blocked_sites=a.com, b.com',
      ]),
      {
        'require_mfa': true,
        'run_event_retention_days': 30,
        'chrome_blocked_sites': ['a.com', 'b.com'],
      },
    );
    expect(
      () => parseSettingsArgs(['require_mfa=yes']),
      throwsA(isA<UsageException>()),
    );
    expect(
      () => parseSettingsArgs(['bogus=1']),
      throwsA(isA<UsageException>()),
    );
    expect(
      () => parseSettingsArgs(['novalue']),
      throwsA(isA<UsageException>()),
    );
  });

  test('planCodeFor', () {
    expect(planCodeFor('plus', 'monthly'), 'plus');
    expect(planCodeFor('max', 'yearly'), 'max_yearly');
  });
}

class _Org extends Command<int> {
  _Org(CliContext ctx) {
    addSubcommand(OrgMembersCommand(ctx));
    addSubcommand(OrgInvitesCommand(ctx));
    addSubcommand(OrgInviteResendCommand(ctx));
    addSubcommand(OrgInviteRevokeCommand(ctx));
    addSubcommand(OrgInviteLinkDeleteCommand(ctx));
    addSubcommand(OrgRequestCommand(ctx));
    addSubcommand(OrgSettingsCommand(ctx));
    addSubcommand(OrgMcpKeysCommand(ctx));
    addSubcommand(OrgMcpKeyCreateCommand(ctx));
    addSubcommand(OrgMcpKeyDeleteCommand(ctx));
    addSubcommand(OrgGitSyncOffCommand(ctx));
    addSubcommand(OrgEncryptionCommand(ctx));
  }
  @override
  String get name => 'org';
  @override
  String get description => 'org';
}
