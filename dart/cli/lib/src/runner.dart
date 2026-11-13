import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:path/path.dart' as p;

import 'commands_bots.dart';
import 'commands_computers.dart';
import 'commands_files.dart';
import 'commands_selfhost.dart';
import 'store.dart';

const defaultApiUrl = 'https://api.casama.ai';

/// Runs the CLI and returns the process exit code.
Future<int> runCli(List<String> args, {StringSink? out, StringSink? err, Directory? configDir}) async {
  final ctx = CliContext(out ?? stdout, err ?? stderr, configDirOverride: configDir);
  final runner = CommandRunner<int>('casama', 'Command-line client for Casama.')
    ..argParser.addOption('api', help: 'API base URL (or CASAMA_API_URL).')
    ..argParser.addFlag('json', negatable: false, help: 'Print JSON output for scripting.')
    ..argParser.addFlag('version', negatable: false, help: 'Print the CLI version.')
    ..addCommand(ConfigCommand(ctx))
    ..addCommand(SignupCommand(ctx))
    ..addCommand(LoginCommand(ctx))
    ..addCommand(LogoutCommand(ctx))
    ..addCommand(WhoamiCommand(ctx))
    ..addCommand(OrgCommand(ctx))
    ..addCommand(InviteCommand(ctx))
    ..addCommand(CredentialCommand(ctx))
    ..addCommand(BotCommand(ctx))
    ..addCommand(ChatCommand(ctx))
    ..addCommand(RunsCommand(ctx))
    ..addCommand(MemoryCommand(ctx))
    ..addCommand(UsageCommand(ctx))
    ..addCommand(ComputerCommand(ctx))
    ..addCommand(FilesCommand(ctx))
    ..addCommand(AccountCommand(ctx))
    ..addCommand(SelfhostCommand(ctx));
  try {
    final top = runner.parse(args);
    if (top['version'] as bool) {
      ctx.out.writeln('casama $cliVersion');
      return 0;
    }
    ctx.json = top['json'] as bool;
    ctx.apiOverride = top['api'] as String?;
    return await runner.runCommand(top) ?? 0;
  } on UsageException catch (e) {
    ctx.err.writeln(e);
    return 64;
  } on AuthException catch (e) {
    return ctx.fail('auth_failed', e.message);
  } on DioException catch (e) {
    final problem = problemOf(e);
    if (problem != null) return ctx.fail(problem.code, problem.detail ?? problem.title);
    return ctx.fail('network_error', e.message ?? e.type.name);
  } on CliError catch (e) {
    return ctx.fail(e.code, e.message);
  }
}

/// Kept in step with pubspec.yaml by scripts/release-cli.sh.
const cliVersion = '0.8.0';

class CliError implements Exception {
  CliError(this.code, this.message);
  final String code;
  final String message;
}

class CliContext {
  CliContext(this.out, this.err, {this.configDirOverride});
  final StringSink out;
  final StringSink err;
  final Directory? configDirOverride;
  bool json = false;
  String? apiOverride;
  CasamaClient? _client;

  Directory get dir => configDirOverride ?? configDir();
  Settings get settings => Settings(File(p.join(dir.path, 'config.json')));
  FileSessionStore get sessions => FileSessionStore(File(p.join(dir.path, 'session.json')));

  String get apiUrl =>
      apiOverride ??
      Platform.environment['CASAMA_API_URL'] ??
      settings.get('api_url') ??
      defaultApiUrl;

  Future<CasamaClient> client() async =>
      _client ??= await CasamaClient.connect(apiUrl, sessions: sessions);

  Future<CasamaClient> authedClient() async {
    final c = await client();
    if (await c.currentSession() == null) {
      throw CliError('not_logged_in', 'Not logged in. Run `casama login` first.');
    }
    return c;
  }

  /// Prints a result: [data] as JSON with --json, otherwise [human].
  int emit(Object? data, String human) {
    out.writeln(json ? const JsonEncoder.withIndent('  ').convert(data) : human);
    return 0;
  }

  int fail(String code, String message) {
    if (json) {
      err.writeln(jsonEncode({'error': code, 'message': message}));
    } else {
      err.writeln('Error: $message ($code)');
    }
    return 1;
  }
}

String readSecret(String prompt, {String? env}) {
  final fromEnv = env == null ? null : Platform.environment[env];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  stderr.write(prompt);
  final hasTerminal = stdin.hasTerminal;
  if (hasTerminal) stdin.echoMode = false;
  final value = stdin.readLineSync() ?? '';
  if (hasTerminal) {
    stdin.echoMode = true;
    stderr.writeln();
  }
  return value;
}

abstract class KCommand extends Command<int> {
  KCommand(this.ctx);
  final CliContext ctx;
}

class ConfigCommand extends KCommand {
  ConfigCommand(super.ctx) {
    argParser.addOption('api-url', help: 'Save the default API base URL.');
  }
  @override
  String get name => 'config';
  @override
  String get description => 'Show or change CLI settings.';
  @override
  Future<int> run() async {
    final url = argResults!['api-url'] as String?;
    if (url != null) ctx.settings.set('api_url', url);
    return ctx.emit({'api_url': ctx.apiUrl, 'config_dir': ctx.dir.path},
        'API: ${ctx.apiUrl}\nConfig: ${ctx.dir.path}');
  }
}

abstract class _CredentialsCommand extends KCommand {
  _CredentialsCommand(super.ctx) {
    argParser
      ..addOption('email', abbr: 'e', help: 'Email address.')
      ..addOption('password', help: 'Password (or CASAMA_PASSWORD; prompted when omitted).');
  }
  String get email {
    final e = argResults!['email'] as String? ?? Platform.environment['CASAMA_EMAIL'];
    if (e == null || e.isEmpty) throw UsageException('--email is required', usage);
    return e;
  }

  String get password =>
      argResults!['password'] as String? ?? readSecret('Password: ', env: 'CASAMA_PASSWORD');
}

class SignupCommand extends _CredentialsCommand {
  SignupCommand(super.ctx);
  @override
  String get name => 'signup';
  @override
  String get description => 'Create an account with email and password.';
  @override
  Future<int> run() async {
    final c = await ctx.client();
    final session = await c.signUp(email, password);
    if (session == null) {
      return ctx.emit({'status': 'confirmation_sent'},
          'Check your email to confirm your account, then run `casama login`.');
    }
    return ctx.emit({'status': 'signed_in', 'user_id': session.userId},
        'Signed up and logged in as ${session.email}.');
  }
}

class LoginCommand extends _CredentialsCommand {
  LoginCommand(super.ctx) {
    argParser
      ..addFlag('magic-link', negatable: false, help: 'Email a one-time code instead.')
      ..addOption('code', help: 'Two-step sign-in code (or CASAMA_2FA_CODE; prompted when needed).');
  }
  @override
  String get name => 'login';
  @override
  String get description => 'Log in with email and password or a magic link code.';
  @override
  Future<int> run() async {
    final c = await ctx.client();
    final AuthSession session;
    if (argResults!['magic-link'] as bool) {
      await c.auth.sendMagicLink(email: email);
      stderr.write('We emailed you a code. Code: ');
      final code = stdin.readLineSync()?.trim() ?? '';
      session = await c.auth.verifyEmailOtp(email: email, token: code);
      await c.sessions.save(session);
    } else {
      session = await c.signIn(email, password);
    }
    // Two-step sign-in (D-093): pass the second step when the account has an authenticator app.
    final factors = await c.auth.verifiedTotpFactors(session.accessToken);
    if (factors.isNotEmpty) {
      final code = (argResults!['code'] as String?) ??
          Platform.environment['CASAMA_2FA_CODE'] ??
          (() {
            stderr.write('Two-step sign-in code: ');
            return stdin.readLineSync()?.trim() ?? '';
          })();
      AuthSession? upgraded;
      Object? lastError;
      for (final f in factors) {
        try {
          upgraded = await c.auth.verifyTotp(accessToken: session.accessToken, factorId: f, code: code);
          break;
        } catch (e) {
          lastError = e;
        }
      }
      if (upgraded == null) {
        await c.sessions.clear();
        throw CliError('two_step_failed', 'That code did not work. ${lastError ?? ''}'.trim());
      }
      await c.sessions.save(upgraded);
    }
    return ctx.emit({'user_id': session.userId, 'email': session.email},
        'Logged in as ${session.email}.');
  }
}

class LogoutCommand extends KCommand {
  LogoutCommand(super.ctx);
  @override
  String get name => 'logout';
  @override
  String get description => 'Forget the stored session.';
  @override
  Future<int> run() async {
    await ctx.sessions.clear();
    return ctx.emit({'status': 'logged_out'}, 'Logged out.');
  }
}

class WhoamiCommand extends KCommand {
  WhoamiCommand(super.ctx);
  @override
  String get name => 'whoami';
  @override
  String get description => 'Show the signed-in user and their organizations.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final me = (await c.workspaces.getMe()).data!;
    final orgs = me.organizations.map((o) => '  ${o.slug}  ${o.name}  (${o.role.value})').join('\n');
    return ctx.emit(me.toJson(),
        '${me.email ?? me.userId}\nOrganizations:\n${orgs.isEmpty ? '  (none)' : orgs}');
  }
}

class OrgCommand extends Command<int> {
  OrgCommand(CliContext ctx) {
    addSubcommand(OrgCreateCommand(ctx));
    addSubcommand(OrgListCommand(ctx));
    addSubcommand(OrgInviteCommand(ctx));
    addSubcommand(OrgUseCommand(ctx));
  }
  @override
  String get name => 'org';
  @override
  String get description => 'Manage organizations (workspaces).';
}

/// Resolves an organization by id or slug among the user's organizations.
Future<OrganizationWithRole> resolveOrg(CasamaClient c, String ref) async {
  final orgs = (await c.workspaces.listOrgs()).data!.items;
  for (final o in orgs) {
    if (o.id == ref || o.slug == ref) return o;
  }
  throw CliError('org_not_found', 'No organization "$ref" among yours.');
}

class OrgCreateCommand extends KCommand {
  OrgCreateCommand(super.ctx) {
    argParser.addOption('slug', help: 'URL-safe identifier (generated when omitted).');
  }
  @override
  String get name => 'create';
  @override
  String get description => 'Create an organization; you become its owner.';
  @override
  String get invocation => 'casama org create <name> [--slug <slug>]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Organization name is required.', usage);
    final c = await ctx.authedClient();
    final org = (await c.workspaces.createOrg(
      createOrganizationRequest: CreateOrganizationRequest(
        name: rest.join(' '),
        slug: argResults!['slug'] as String?,
      ),
    ))
        .data!;
    return ctx.emit(org.toJson(), 'Created ${org.name} (${org.slug}).');
  }
}

class OrgListCommand extends KCommand {
  OrgListCommand(super.ctx);
  @override
  String get name => 'list';
  @override
  String get description => 'List your organizations.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final list = (await c.workspaces.listOrgs()).data!;
    final lines = list.items.map((o) => '${o.slug}\t${o.name}\t${o.role.value}').join('\n');
    return ctx.emit(list.toJson(), lines.isEmpty ? 'No organizations yet.' : lines);
  }
}

class OrgInviteCommand extends KCommand {
  OrgInviteCommand(super.ctx) {
    argParser
      ..addOption('org', abbr: 'o', help: 'Organization slug or id.', mandatory: true)
      ..addOption('role', allowed: ['member', 'admin'], defaultsTo: 'member');
  }
  @override
  String get name => 'invite';
  @override
  String get description => 'Invite someone to an organization by email.';
  @override
  String get invocation => 'casama org invite <email> --org <slug> [--role member|admin]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('One email address is required.', usage);
    final c = await ctx.authedClient();
    final org = await resolveOrg(c, argResults!['org'] as String);
    final invite = (await c.workspaces.createInvite(
      id: org.id,
      createInviteRequest: CreateInviteRequest(
        email: rest.single,
        role: InviteRole.values.firstWhere((r) => r.value == argResults!['role']),
      ),
    ))
        .data!;
    final human = StringBuffer('Invited ${invite.email} to ${org.name} as ${invite.role.value}.');
    if (invite.acceptToken != null) {
      human.write('\nNo email provider is configured. Share this command with them:\n'
          '  casama invite accept ${invite.acceptToken}');
    }
    return ctx.emit(invite.toJson(), human.toString());
  }
}

class InviteCommand extends Command<int> {
  InviteCommand(CliContext ctx) {
    addSubcommand(InviteAcceptCommand(ctx));
  }
  @override
  String get name => 'invite';
  @override
  String get description => 'Work with invites you received.';
}

class InviteAcceptCommand extends KCommand {
  InviteAcceptCommand(super.ctx);
  @override
  String get name => 'accept';
  @override
  String get description => 'Join an organization with an invite token.';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('The invite token is required.', usage);
    final c = await ctx.authedClient();
    final m = (await c.workspaces.acceptInvite(token: rest.single)).data!;
    return ctx.emit(m.toJson(), 'Joined organization ${m.orgId} as ${m.role.value}.');
  }
}
