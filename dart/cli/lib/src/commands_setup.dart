import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'commands_bots.dart' show addOrgOption, botFrom, openInBrowser, orgFrom;
import 'runner.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

typedef Json = Map<String, dynamic>;

/// One call to the API with the signed-in session, returning the decoded JSON body.
Future<dynamic> _api(
  CasamaClient c,
  String method,
  String path, {
  Map<String, dynamic>? query,
  Object? body,
}) async {
  final r = await c.api.dio.request<Object>(
    path,
    data: body,
    queryParameters: query,
    options: Options(
      method: method,
      extra: {
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
      },
    ),
  );
  return r.data;
}

List<Json> _items(dynamic body) => [
  for (final i in (body as Json)['items'] as List) i as Json,
];

String _pad(Object? v, int n) => (v?.toString() ?? '-').padRight(n);

/// Parses `key=value` words. A bare `key` maps to null (the caller may prompt for it).
Map<String, String?> parsePairs(List<String> items, String usage) {
  final out = <String, String?>{};
  for (final raw in items) {
    final i = raw.indexOf('=');
    final key = (i < 0 ? raw : raw.substring(0, i)).trim();
    if (key.isEmpty) {
      throw UsageException('Expected key=value, got "$raw".', usage);
    }
    out[key] = i < 0 ? null : textArg(raw.substring(i + 1));
  }
  return out;
}

/// `@path` reads the text from a file; anything else is used as is.
String textArg(String v) {
  if (!v.startsWith('@') || v.length == 1) return v;
  final f = File(v.substring(1));
  if (!f.existsSync()) {
    throw CliError('file_not_found', 'No file at ${f.path}.');
  }
  return f.readAsStringSync().trimRight();
}

/// Without --yes: prints what would happen (exit 0). Returns null when --yes was given.
int? confirmGate(CliContext ctx, bool yes, String would) {
  if (yes) return null;
  return ctx.emit({
    'would': would,
    'confirm': '--yes',
  }, 'Would $would.\nRun again with --yes to do it.');
}

void _addYes(Command<int> cmd, [String help = 'Do it without asking.']) =>
    cmd.argParser.addFlag('yes', abbr: 'y', negatable: false, help: help);

void _addBotOption(Command<int> cmd, {String? help}) => cmd.argParser.addOption(
  'bot',
  abbr: 'b',
  help: help ?? 'The bot, by name or id.',
);

/// The bot from --bot (required when [required]), in the --org workspace.
Future<Json?> _botOpt(
  CliContext ctx,
  CasamaClient c,
  ArgResults args,
  String usage, {
  bool required = true,
}) async {
  final ref = args['bot'] as String?;
  if (ref == null) {
    if (required) throw UsageException('Which bot? Pass --bot <name>.', usage);
    return null;
  }
  final org = await orgFrom(ctx, c, args['org'] as String?);
  final b = await botFrom(c, org, ref);
  return {'id': b.id, 'org_id': org.id, 'name': b.name};
}

void _needBot(ArgResults args, String usage) {
  if (args['bot'] == null) {
    throw UsageException('Which bot? Pass --bot <name>.', usage);
  }
}

String _one(List<String> rest, String what, String usage) {
  if (rest.length != 1) throw UsageException('$what?', usage);
  return rest.single;
}

// ---------------------------------------------------------------------------
// skills
// ---------------------------------------------------------------------------

/// `casama skills catalog|install|update|stats`. There is no endpoint that lists installed
/// skills or removes one, so those stay in the app.
class SkillsCommand extends Command<int> {
  SkillsCommand(CliContext ctx) {
    addSubcommand(SkillsCatalogCommand(ctx));
    addSubcommand(SkillsInstallCommand(ctx));
    addSubcommand(SkillsUpdateCommand(ctx));
    addSubcommand(SkillsStatsCommand(ctx));
  }
  @override
  String get name => 'skills';
  @override
  String get description =>
      'Skills bots can use: the catalog, installing, updating.';
}

/// Catalog items matching [query] in id, name, description or category.
List<Json> filterCatalog(List<Json> items, String? query) {
  if (query == null || query.trim().isEmpty) return items;
  final q = query.toLowerCase();
  return [
    for (final i in items)
      if ([
        'id',
        'name',
        'description',
        'category',
      ].any((k) => (i[k]?.toString().toLowerCase() ?? '').contains(q)))
        i,
  ];
}

class SkillsCatalogCommand extends KCommand {
  SkillsCatalogCommand(super.ctx);
  @override
  String get name => 'catalog';
  @override
  String get description => 'Skills you can install. Add words to search.';
  @override
  String get invocation => 'casama skills catalog [query]';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final body = await _api(c, 'GET', '/v1/skills/catalog') as Json;
    final items = filterCatalog([
      for (final i in body['items'] as List) i as Json,
    ], argResults!.rest.join(' '));
    return ctx.emit(
      [
        for (final i in items)
          {
            for (final k in ['id', 'name', 'description', 'category']) k: i[k],
          },
      ],
      items.isEmpty
          ? 'No skills match. Run `casama skills catalog` for the whole list.'
          : items
                .map(
                  (i) =>
                      '${_pad(i['id'], 28)} ${_pad(i['category'], 14)} ${i['description']}',
                )
                .join('\n'),
    );
  }
}

bool _isGitHubUrl(String s) =>
    s.startsWith('https://github.com/') || s.startsWith('http://github.com/');

class SkillsInstallCommand extends KCommand {
  SkillsInstallCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this, help: 'Install for one bot only (name or id).');
    argParser
      ..addFlag(
        'gallery',
        negatable: false,
        help: 'The id is a gallery id, not a catalog id.',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Install a GitHub skill after the preview.',
      );
  }
  @override
  String get name => 'install';
  @override
  String get description =>
      'Install a catalog skill, or a skill from a GitHub URL.';
  @override
  String get invocation =>
      'casama skills install <catalog id | github url> [--bot name] [--yes]';
  @override
  Future<int> run() async {
    final ref = _one(
      argResults!.rest,
      'Which skill? Pass a catalog id or a GitHub URL',
      usage,
    );
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await _botOpt(ctx, c, argResults!, usage, required: false);
    if (!_isGitHubUrl(ref)) {
      final r = await _api(
        c,
        'POST',
        '/v1/skills/install',
        body: {
          'org_id': org.id,
          'bot_id': ?bot?['id'],
          (argResults!['gallery'] as bool ? 'gallery_id' : 'catalog_id'): ref,
        },
      ) as Json;
      return ctx.emit(r, 'Installed ${r['name']} (${r['id']}).');
    }
    final pre = await _api(
      c,
      'POST',
      '/v1/skills/github/preview',
      body: {'org_id': org.id, 'url': ref},
    ) as Json;
    final files = (pre['files'] as List).cast<Json>();
    final text = [
      '${pre['name']}  (${pre['repo']}/${pre['path']} @ ${(pre['commit'] as String).substring(0, 8)})',
      '${pre['description']}',
      'Files:',
      for (final f in files)
        '  ${f['path']}  ${f['size']} bytes${f['executable'] == true ? '  (runs code)' : ''}',
    ].join('\n');
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit(
        {'preview': pre, 'confirm': '--yes'},
        '$text\nThis is not installed yet. Run again with --yes to install this exact version.',
      );
    }
    final r = await _api(
      c,
      'POST',
      '/v1/skills/github/install',
      body: {
        'org_id': org.id,
        'bot_id': ?bot?['id'],
        'url': ref,
        'commit': pre['commit'],
      },
    ) as Json;
    return ctx.emit(r, 'Installed ${r['name']} (${r['id']}).');
  }
}

class SkillsUpdateCommand extends KCommand {
  SkillsUpdateCommand(super.ctx) {
    _addYes(this, 'Apply the update.');
  }
  @override
  String get name => 'update';
  @override
  String get description =>
      'Show a skill\'s pending update; apply it with --yes.';
  @override
  String get invocation => 'casama skills update <skill id> [--yes]';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which skill? Pass its id', usage);
    final c = await ctx.authedClient();
    final chk = await _api(c, 'GET', '/v1/skills/$id/update') as Json;
    if (chk['has_update'] != true) {
      return ctx.emit(chk, 'Already up to date.');
    }
    List<String> l(String k) => [for (final x in chk[k] as List) '$x'];
    final text = [
      'Update ${chk['current_commit'].toString().substring(0, 8)} -> ${chk['latest_commit'].toString().substring(0, 8)}',
      for (final f in l('files_added')) '  + $f',
      for (final f in l('files_removed')) '  - $f',
      for (final f in l('files_changed')) '  ~ $f',
    ].join('\n');
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit({
        'update': chk,
        'confirm': '--yes',
      }, '$text\nRun again with --yes to apply it.');
    }
    final r = await _api(
      c,
      'POST',
      '/v1/skills/$id/update',
      body: {'commit': chk['latest_commit']},
    ) as Json;
    return ctx.emit(r, 'Updated ${r['name']}.');
  }
}

class SkillsStatsCommand extends KCommand {
  SkillsStatsCommand(super.ctx);
  @override
  String get name => 'stats';
  @override
  String get description => 'How often a skill is used and how often it works.';
  @override
  String get invocation => 'casama skills stats <skill id>';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which skill? Pass its id', usage);
    final c = await ctx.authedClient();
    final s = await _api(c, 'GET', '/v1/skills/$id/stats') as Json;
    final rate = s['success_rate'];
    final text = [
      'Uses: ${s['uses']}  worked: ${s['successes']}  failed: ${s['failures']}  corrected: ${s['corrections']}',
      if (rate is num) 'Success rate: ${(rate * 100).round()}%',
      if (s['last_failure_at'] != null)
        'Last failure: ${s['last_failure_at']} (run ${s['last_failure_run_id']})',
      'Revisions: ${(s['revisions'] as List).length}',
    ].join('\n');
    return ctx.emit(s, text);
  }
}

// ---------------------------------------------------------------------------
// plugins
// ---------------------------------------------------------------------------

/// `casama plugins list|preview|install|settings|update|remove`.
class PluginsCommand extends Command<int> {
  PluginsCommand(CliContext ctx) {
    addSubcommand(PluginsListCommand(ctx));
    addSubcommand(PluginsPreviewCommand(ctx));
    addSubcommand(PluginsInstallCommand(ctx));
    addSubcommand(PluginsSettingsCommand(ctx));
    addSubcommand(PluginsUpdateCommand(ctx));
    addSubcommand(PluginsRemoveCommand(ctx));
  }
  @override
  String get name => 'plugins';
  @override
  String get description =>
      'Plugins on a bot: skills and tools from a Git repository.';
}

String _short(Object? commit) {
  final s = commit?.toString() ?? '';
  return s.length > 8 ? s.substring(0, 8) : s;
}

String pluginPreviewText(Json pre) {
  List<Json> l(String k) => [
    for (final x in (pre[k] as List? ?? [])) x as Json,
  ];
  return [
    '${pre['name']}${pre['version'] == null ? '' : ' ${pre['version']}'}  (${pre['repo']} @ ${_short(pre['commit'])})',
    '${pre['description']}',
    if (l('skills').isNotEmpty)
      'Skills: ${l('skills').map((s) => s['name']).join(', ')}',
    if (l('servers').isNotEmpty)
      'Tools it runs: ${l('servers').map((s) => s['command'] != null ? '${s['key']} (${s['command']} ${(s['args'] as List).join(' ')})' : '${s['key']} (${s['url']})').join(', ')}',
    if ((pre['hosts'] as List).isNotEmpty)
      'Can reach: ${(pre['hosts'] as List).join(', ')}',
    if (l('secrets').isNotEmpty)
      'Needs secrets: ${l('secrets').map((s) => s['name']).join(', ')}',
    if (l('settings').isNotEmpty)
      'Settings: ${l('settings').map((s) => s['name']).join(', ')}',
    for (final w in pre['warnings'] as List) 'Warning: $w',
  ].join('\n');
}

class PluginsListCommand extends KCommand {
  PluginsListCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'The plugins installed on a bot.';
  @override
  String get invocation => 'casama plugins list --bot <name>';
  @override
  Future<int> run() async {
    _needBot(argResults!, usage);
    final c = await ctx.authedClient();
    final bot = (await _botOpt(ctx, c, argResults!, usage))!;
    final items = _items(
      await _api(c, 'GET', '/v1/plugins', query: {'bot_id': bot['id']}),
    );
    return ctx.emit(
      items,
      items.isEmpty
          ? 'No plugins on ${bot['name']}. Try `casama plugins preview <git url>`.'
          : items
                .map(
                  (i) =>
                      '${i['id']}  ${_pad(i['name'], 24)} ${_pad(i['version'], 8)} ${_short(i['commit'])}  ${i['repo']}',
                )
                .join('\n'),
    );
  }
}

class PluginsPreviewCommand extends KCommand {
  PluginsPreviewCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption(
      'commit',
      help: 'A commit to look at (default: the latest).',
    );
  }
  @override
  String get name => 'preview';
  @override
  String get description =>
      'Show what a plugin would install and what it can reach.';
  @override
  String get invocation => 'casama plugins preview <git url>';
  @override
  Future<int> run() async {
    final src = _one(argResults!.rest, 'Which plugin? Pass a Git URL', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final pre = await _api(
      c,
      'POST',
      '/v1/plugins/preview',
      body: {'org_id': org.id, 'url': src, 'commit': ?argResults!['commit']},
    ) as Json;
    return ctx.emit(pre, pluginPreviewText(pre));
  }
}

class PluginsInstallCommand extends KCommand {
  PluginsInstallCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this);
    argParser
      ..addOption('commit', help: 'Install this commit (default: the latest).')
      ..addMultiOption(
        'secret',
        help:
            'NAME=VALUE for a secret it needs. A bare NAME asks for the value.',
      )
      ..addMultiOption('setting', help: 'NAME=VALUE for a setting.')
      ..addOption(
        'device',
        help: 'Run it on this device id (your own computer).',
      );
    _addYes(this, 'Install after the preview.');
  }
  @override
  String get name => 'install';
  @override
  String get description =>
      'Install a plugin on a bot. Shows the preview first; --yes installs.';
  @override
  String get invocation =>
      'casama plugins install <git url> --bot <name> [--yes]';
  @override
  Future<int> run() async {
    final src = _one(argResults!.rest, 'Which plugin? Pass a Git URL', usage);
    _needBot(argResults!, usage);
    final c = await ctx.authedClient();
    final bot = (await _botOpt(ctx, c, argResults!, usage))!;
    final pre = await _api(
      c,
      'POST',
      '/v1/plugins/preview',
      body: {
        'org_id': bot['org_id'],
        'url': src,
        'commit': ?argResults!['commit'],
      },
    ) as Json;
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit(
        {'preview': pre, 'confirm': '--yes'},
        '${pluginPreviewText(pre)}\nNot installed yet. Run again with --yes to install this exact version on ${bot['name']}.',
      );
    }
    final secrets = <String, String>{};
    final given = parsePairs(argResults!['secret'] as List<String>, usage);
    for (final s in (pre['secrets'] as List).cast<Json>()) {
      final n = s['name'] as String;
      if (!given.containsKey(n)) {
        throw UsageException(
          'The plugin needs the secret $n. Pass --secret $n=... (or --secret $n to be asked).',
          usage,
        );
      }
    }
    for (final e in given.entries) {
      secrets[e.key] = e.value ?? readSecret('${e.key}: ');
    }
    final settings = parsePairs(argResults!['setting'] as List<String>, usage);
    final r = await _api(
      c,
      'POST',
      '/v1/plugins',
      body: {
        'org_id': bot['org_id'],
        'bot_id': bot['id'],
        'url': src,
        'commit': pre['commit'],
        if (secrets.isNotEmpty) 'secrets': secrets,
        if (settings.isNotEmpty) 'settings': settings,
        'device_id': ?argResults!['device'],
      },
    ) as Json;
    return ctx.emit(
      r,
      'Installed ${r['name']} on ${bot['name']} (${r['id']}).',
    );
  }
}

class PluginsSettingsCommand extends KCommand {
  PluginsSettingsCommand(super.ctx);
  @override
  String get name => 'settings';
  @override
  String get description => 'Change a plugin\'s settings.';
  @override
  String get invocation => 'casama plugins settings <plugin id> key=value...';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      throw UsageException(
        'Pass a plugin id and at least one key=value.',
        usage,
      );
    }
    final pairs = parsePairs(rest.skip(1).toList(), usage);
    if (pairs.values.any((v) => v == null)) {
      throw UsageException('Each setting needs a value: key=value.', usage);
    }
    final c = await ctx.authedClient();
    final r = await _api(
      c,
      'PATCH',
      '/v1/plugins/${rest.first}/settings',
      body: {'settings': pairs},
    ) as Json;
    final shown = [
      for (final s in (r['settings'] as List? ?? []).cast<Json>())
        '  ${s['name']} = ${s['value']}',
    ];
    return ctx.emit(
      r,
      'Updated ${r['name']}.${shown.isEmpty ? '' : '\n${shown.join('\n')}'}',
    );
  }
}

class PluginsUpdateCommand extends KCommand {
  PluginsUpdateCommand(super.ctx) {
    argParser
      ..addMultiOption(
        'secret',
        help: 'NAME=VALUE for a new secret the update needs.',
      )
      ..addMultiOption('setting', help: 'NAME=VALUE for a new setting.');
    _addYes(this, 'Apply the update.');
  }
  @override
  String get name => 'update';
  @override
  String get description =>
      'Show what a plugin update changes; apply it with --yes.';
  @override
  String get invocation => 'casama plugins update <plugin id> [--yes]';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which plugin? Pass its id', usage);
    final c = await ctx.authedClient();
    final u = await _api(c, 'GET', '/v1/plugins/$id/update') as Json;
    if (u['up_to_date'] == true) return ctx.emit(u, 'Already up to date.');
    List<String> l(String k) => [for (final x in u[k] as List) '$x'];
    String line(String label, String k) =>
        l(k).isEmpty ? '' : '$label: ${l(k).join(', ')}';
    final text = [
      'Update ${_short(u['from_commit'])} -> ${_short(u['to_commit'])}${u['to_version'] == null ? '' : ' (${u['to_version']})'}',
      line('Skills added', 'skills_added'),
      line('Skills removed', 'skills_removed'),
      line('Skills changed', 'skills_changed'),
      line('Tools added', 'servers_added'),
      line('Tools removed', 'servers_removed'),
      line('Tools changed', 'servers_changed'),
      line('New hosts', 'hosts_added'),
      line('New secrets needed', 'secrets_added'),
    ].where((s) => s.isNotEmpty).join('\n');
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit({
        'update': u,
        'confirm': '--yes',
      }, '$text\nRun again with --yes to apply it.');
    }
    final secrets = <String, String>{};
    for (final e in parsePairs(
      argResults!['secret'] as List<String>,
      usage,
    ).entries) {
      secrets[e.key] = e.value ?? readSecret('${e.key}: ');
    }
    final settings = parsePairs(argResults!['setting'] as List<String>, usage);
    final r = await _api(
      c,
      'POST',
      '/v1/plugins/$id/update',
      body: {
        'commit': u['to_commit'],
        if (secrets.isNotEmpty) 'secrets': secrets,
        if (settings.isNotEmpty) 'settings': settings,
      },
    ) as Json;
    return ctx.emit(r, 'Updated ${r['name']} to ${_short(r['commit'])}.');
  }
}

class PluginsRemoveCommand extends KCommand {
  PluginsRemoveCommand(super.ctx) {
    _addYes(this, 'Remove it.');
  }
  @override
  String get name => 'remove';
  @override
  String get description => 'Remove a plugin from its bot.';
  @override
  String get invocation => 'casama plugins remove <plugin id> --yes';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which plugin? Pass its id', usage);
    final gate = confirmGate(
      ctx,
      argResults!['yes'] as bool,
      'remove plugin $id',
    );
    if (gate != null) return gate;
    final c = await ctx.authedClient();
    final r = await _api(c, 'DELETE', '/v1/plugins/$id');
    return ctx.emit(r, 'Removed plugin $id.');
  }
}

// ---------------------------------------------------------------------------
// apps (and integrations: the same thing for users)
// ---------------------------------------------------------------------------

/// `casama apps list|connect|test|edit|remove`. An integration is an app once it is connected,
/// so there is no separate `integrations` command: `list --connected` shows the connections.
class AppsCommand extends Command<int> {
  AppsCommand(CliContext ctx) {
    addSubcommand(AppsListCommand(ctx));
    addSubcommand(AppsConnectCommand(ctx));
    addSubcommand(AppsTestCommand(ctx));
    addSubcommand(AppsEditCommand(ctx));
    addSubcommand(AppsRemoveCommand(ctx));
  }
  @override
  String get name => 'apps';
  @override
  String get description =>
      'Apps you can connect (Slack, GitHub, ...) and your connections.';
}

/// The sign-in method to use for [app] (a catalog entry JSON), or null when [wanted] is not offered.
String? pickMethod(Json app, String? wanted) {
  final auth = [for (final a in (app['auth'] as List? ?? [])) '$a'];
  if (wanted != null) return auth.contains(wanted) ? wanted : null;
  if (auth.contains('oauth') && app['oauth_available'] != false) return 'oauth';
  for (final m in ['managed', 'api_key', 'none']) {
    if (auth.contains(m)) return m;
  }
  return auth.isEmpty ? null : auth.first;
}

Future<List<Json>> _integrations(CasamaClient c, String orgId) async =>
    _items(await _api(c, 'GET', '/v1/integrations', query: {'org_id': orgId}));

/// An integration by id, name or app id.
Future<Json> _integration(
  CliContext ctx,
  CasamaClient c,
  String? orgFlag,
  String ref,
) async {
  final org = await orgFrom(ctx, c, orgFlag);
  final all = await _integrations(c, org.id);
  final lower = ref.toLowerCase();
  final hit = all
      .where(
        (i) =>
            i['id'] == ref ||
            (i['name'] as String).toLowerCase() == lower ||
            i['app_id'] == ref,
      )
      .firstOrNull;
  if (hit == null) {
    throw CliError(
      'connection_not_found',
      'No connection "$ref" in ${org.name}. See `casama apps list --connected`.',
    );
  }
  return hit;
}

String _integrationLine(Json i) =>
    '${i['id']}  ${_pad(i['status'], 7)} ${_pad(i['name'], 24)} ${_pad(i['kind'], 9)} ${(i['tools'] as List).length} tools${i['error'] == null ? '' : '  (${i['error']})'}';

class AppsListCommand extends KCommand {
  AppsListCommand(super.ctx) {
    addOrgOption(this);
    argParser.addFlag(
      'connected',
      negatable: false,
      help: 'Only your connections, with their ids.',
    );
  }
  @override
  String get name => 'list';
  @override
  String get description => 'Apps you can connect, and which are connected.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final conns = await _integrations(c, org.id);
    if (argResults!['connected'] as bool) {
      return ctx.emit(
        conns,
        conns.isEmpty
            ? 'Nothing connected. Run `casama apps list` to see what you can connect.'
            : conns.map(_integrationLine).join('\n'),
      );
    }
    final cat =
        await _api(c, 'GET', '/v1/apps', query: {'org_id': org.id}) as Json;
    final byApp = {
      for (final i in conns)
        if (i['app_id'] != null) i['app_id'] as String: i,
    };
    final apps = [
      for (final a in (cat['apps'] as List).cast<Json>())
        {
          'id': a['id'],
          'name': a['name'],
          'category': a['category'],
          'auth': a['auth'],
          'connected': byApp.containsKey(a['id']),
          'integration_id': byApp[a['id']]?['id'],
        },
    ];
    return ctx.emit(
      apps,
      apps
          .map(
            (a) =>
                '${a['connected'] == true ? 'connected' : '         '}  ${_pad(a['id'], 22)} ${_pad(a['name'], 22)} ${a['category']}',
          )
          .join('\n'),
    );
  }
}

class AppsConnectCommand extends KCommand {
  AppsConnectCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption(
        'method',
        help: 'oauth, api_key, none or managed (default: the best one the app offers).',
      )
      ..addOption(
        'api-key',
        help: 'The API key, for apps that use one. Otherwise you are asked.',
      )
      ..addFlag(
        'wait',
        defaultsTo: true,
        help: 'Wait for the browser sign-in to finish (3 minutes).',
      )
      ..addFlag(
        'browser',
        defaultsTo: true,
        help: 'Open the sign-in link in the browser.',
      );
  }
  @override
  String get name => 'connect';
  @override
  String get description => 'Connect an app. Sign-in opens in your browser.';
  @override
  String get invocation => 'casama apps connect <app id> [--no-wait]';

  /// How often to poll the sign-in; tests shorten it.
  static Duration pollEvery = const Duration(seconds: 2);
  static Duration giveUpAfter = const Duration(minutes: 3);

  @override
  Future<int> run() async {
    final appId = _one(
      argResults!.rest,
      'Which app? Pass its id (see `casama apps list`)',
      usage,
    );
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final cat =
        await _api(c, 'GET', '/v1/apps', query: {'org_id': org.id}) as Json;
    final app = (cat['apps'] as List)
        .cast<Json>()
        .where(
          (a) =>
              a['id'] == appId.toLowerCase() ||
              (a['name'] as String).toLowerCase() == appId.toLowerCase(),
        )
        .firstOrNull;
    if (app == null) {
      throw CliError(
        'app_not_found',
        'No app "$appId". See `casama apps list`.',
      );
    }
    final method = pickMethod(app, argResults!['method'] as String?);
    if (method == null) {
      throw UsageException(
        '${app['name']} does not support that sign-in. It offers: ${(app['auth'] as List).join(', ')}.',
        usage,
      );
    }
    String? key;
    if (method == 'api_key') {
      key =
          argResults!['api-key'] as String? ??
          readSecret('${app['name']} API key: ', env: 'CASAMA_APP_KEY');
      if (key.isEmpty) throw UsageException('An API key is needed.', usage);
    }
    final r = await _api(
      c,
      'POST',
      '/v1/apps/connect',
      body: {
        'org_id': org.id,
        'app_id': app['id'],
        'method': method,
        'api_key': ?key,
      },
    ) as Json;
    switch (r['status']) {
      case 'connected':
        final i = r['integration'] as Json;
        return ctx.emit(
          r,
          'Connected ${app['name']} (${i['id']}, ${(i['tools'] as List).length} tools).',
        );
      case 'error':
        throw CliError(
          'connect_failed',
          '${r['error'] ?? 'The connection failed.'}',
        );
    }
    final url = r['authorize_url'] as String?;
    final flow = r['flow_id'] as String?;
    if (url == null) {
      throw CliError('connect_failed', 'The API gave no sign-in link.');
    }
    final wait = argResults!['wait'] as bool && flow != null;
    if (!wait) {
      if (argResults!['browser'] as bool) await openInBrowser(Uri.parse(url));
      return ctx.emit({
        'status': 'authorize',
        'authorize_url': url,
        'flow_id': flow,
      }, 'Sign in to ${app['name']}: $url');
    }
    ctx.err.writeln('Sign in to ${app['name']}: $url');
    if (argResults!['browser'] as bool &&
        !await openInBrowser(Uri.parse(url))) {
      ctx.err.writeln('Could not open a browser. Open the link yourself.');
    }
    final deadline = DateTime.now().add(giveUpAfter);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollEvery);
      final s = await _api(c, 'GET', '/v1/apps/connect/$flow') as Json;
      switch (s['status']) {
        case 'connected':
          final i = s['integration'] as Json?;
          return ctx.emit(
            s,
            'Connected ${app['name']}${i == null ? '' : ' (${i['id']})'}.',
          );
        case 'error':
          throw CliError(
            'connect_failed',
            '${s['error'] ?? 'The sign-in failed.'}',
          );
        case 'expired':
          throw CliError(
            'connect_expired',
            'The sign-in link expired. Run the command again.',
          );
      }
    }
    throw CliError(
      'connect_timeout',
      'Still waiting after 3 minutes. Run `casama apps list --connected` later to check.',
    );
  }
}

class AppsTestCommand extends KCommand {
  AppsTestCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'test';
  @override
  String get description => 'Check that a connection works and list its tools.';
  @override
  String get invocation => 'casama apps test <connection id | app id | name>';
  @override
  Future<int> run() async {
    final ref = _one(argResults!.rest, 'Which connection?', usage);
    final c = await ctx.authedClient();
    final i = await _integration(ctx, c, argResults!['org'] as String?, ref);
    final r = await _api(c, 'POST', '/v1/integrations/${i['id']}/test') as Json;
    final ok = r['ok'] == true;
    final code = ctx.emit(
      r,
      ok
          ? 'OK: ${i['name']} works (${(r['tools'] as List).length} tools).'
          : 'Failed: ${r['error'] ?? 'unknown error'}',
    );
    return ok ? code : 1;
  }
}

class AppsEditCommand extends KCommand {
  AppsEditCommand(super.ctx) {
    addOrgOption(this);
    argParser.addMultiOption(
      'risk',
      help: 'tool=low|medium|high. How risky a tool is, so bots ask first. Repeat for more.',
    );
  }
  @override
  String get name => 'edit';
  @override
  String get description => 'Change how risky a connection\'s tools are.';
  @override
  String get invocation => 'casama apps edit <connection> --risk tool=high';
  @override
  Future<int> run() async {
    final ref = _one(argResults!.rest, 'Which connection?', usage);
    final pairs = parsePairs(argResults!['risk'] as List<String>, usage);
    if (pairs.isEmpty) {
      throw UsageException(
        'Nothing to change. Pass --risk tool=low|medium|high.',
        usage,
      );
    }
    for (final e in pairs.entries) {
      if (!['low', 'medium', 'high'].contains(e.value)) {
        throw UsageException(
          'Risk for ${e.key} must be low, medium or high.',
          usage,
        );
      }
    }
    final c = await ctx.authedClient();
    final i = await _integration(ctx, c, argResults!['org'] as String?, ref);
    final r = await _api(
      c,
      'PATCH',
      '/v1/integrations/${i['id']}',
      body: {
        'risk_overrides': {
          ...?(i['risk_overrides'] as Map?)?.cast<String, dynamic>(),
          ...pairs,
        },
      },
    ) as Json;
    return ctx.emit(r, 'Updated ${r['name']}.');
  }
}

class AppsRemoveCommand extends KCommand {
  AppsRemoveCommand(super.ctx) {
    addOrgOption(this);
    _addYes(this, 'Disconnect it.');
  }
  @override
  String get name => 'remove';
  @override
  String get description => 'Disconnect an app.';
  @override
  String get invocation => 'casama apps remove <connection> --yes';
  @override
  Future<int> run() async {
    final ref = _one(argResults!.rest, 'Which connection?', usage);
    final gate = confirmGate(
      ctx,
      argResults!['yes'] as bool,
      'disconnect $ref',
    );
    if (gate != null) return gate;
    final c = await ctx.authedClient();
    final i = await _integration(ctx, c, argResults!['org'] as String?, ref);
    await _api(c, 'DELETE', '/v1/integrations/${i['id']}');
    return ctx.emit({
      'id': i['id'],
      'removed': true,
    }, 'Disconnected ${i['name']}.');
  }
}

// ---------------------------------------------------------------------------
// secrets
// ---------------------------------------------------------------------------

/// `casama secrets list|add|remove|requests|fulfill|decline`. Values are never printed.
class SecretsCommand extends Command<int> {
  SecretsCommand(CliContext ctx) {
    addSubcommand(SecretsListCommand(ctx));
    addSubcommand(SecretsAddCommand(ctx));
    addSubcommand(SecretsRemoveCommand(ctx));
    addSubcommand(SecretsRequestsCommand(ctx));
    addSubcommand(SecretsFulfillCommand(ctx));
    addSubcommand(SecretsDeclineCommand(ctx));
  }
  @override
  String get name => 'secrets';
  @override
  String get description =>
      'Secrets bots can use (API keys, passwords) and bot requests for them.';
}

String _secretLine(Json s) =>
    '${s['id']}  ${_pad(s['name'], 24)} ${_pad(s['kind'], 6)} ${(s['allowed_hosts'] as List).isEmpty ? 'any host' : (s['allowed_hosts'] as List).join(',')}';

class SecretsListCommand extends KCommand {
  SecretsListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description =>
      'Secret names and where they may be used. Never the values.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final items = _items(
      await _api(c, 'GET', '/v1/secrets', query: {'org_id': org.id}),
    );
    return ctx.emit(
      items,
      items.isEmpty
          ? 'No secrets yet. Add one with `casama secrets add <name>`.'
          : items.map(_secretLine).join('\n'),
    );
  }
}

class SecretsAddCommand extends KCommand {
  SecretsAddCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption(
        'value',
        help: 'The secret. Safer to leave out: you are asked, and nothing is echoed.',
      )
      ..addMultiOption(
        'host',
        help: 'A host the secret may be sent to. Repeat for more.',
      )
      ..addMultiOption(
        'bot',
        help: 'Only these bots (name or id) may use it. Default: all.',
      )
      ..addOption(
        'kind',
        allowed: ['value', 'totp'],
        defaultsTo: 'value',
        help: 'totp: a two-step seed.',
      );
  }
  @override
  String get name => 'add';
  @override
  String get description => 'Save a secret.';
  @override
  String get invocation => 'casama secrets add <name> --host api.example.com';
  @override
  Future<int> run() async {
    final n = _one(argResults!.rest, 'What is the secret\'s name?', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final value = argResults!['value'] != null
        ? textArg(argResults!['value'] as String)
        : readSecret('Value for $n: ', env: 'CASAMA_SECRET_VALUE');
    if (value.isEmpty) throw UsageException('The value is empty.', usage);
    final bots = <String>[];
    for (final b in argResults!['bot'] as List<String>) {
      bots.add((await botFrom(c, org, b)).id);
    }
    final s = await _api(
      c,
      'POST',
      '/v1/secrets',
      body: {
        'org_id': org.id,
        'name': n,
        'value': value,
        'allowed_hosts': argResults!['host'],
        if (bots.isNotEmpty) 'allowed_bot_ids': bots,
        'kind': argResults!['kind'],
      },
    ) as Json;
    return ctx.emit(s, 'Saved ${s['name']} (${s['id']}).');
  }
}

class SecretsRemoveCommand extends KCommand {
  SecretsRemoveCommand(super.ctx) {
    addOrgOption(this);
    _addYes(this, 'Delete it.');
  }
  @override
  String get name => 'remove';
  @override
  String get description => 'Delete a secret.';
  @override
  String get invocation => 'casama secrets remove <id | name> --yes';
  @override
  Future<int> run() async {
    final ref = _one(
      argResults!.rest,
      'Which secret? Pass its id or name',
      usage,
    );
    final gate = confirmGate(
      ctx,
      argResults!['yes'] as bool,
      'delete secret $ref',
    );
    if (gate != null) return gate;
    final c = await ctx.authedClient();
    var id = ref;
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(ref)) {
      final org = await orgFrom(ctx, c, argResults!['org'] as String?);
      final all = _items(
        await _api(c, 'GET', '/v1/secrets', query: {'org_id': org.id}),
      );
      final hit = all.where((s) => s['name'] == ref).firstOrNull;
      if (hit == null) {
        throw CliError(
          'secret_not_found',
          'No secret "$ref". See `casama secrets list`.',
        );
      }
      id = hit['id'] as String;
    }
    await _api(c, 'DELETE', '/v1/secrets/$id');
    return ctx.emit({'deleted': id}, 'Deleted secret $id.');
  }
}

class SecretsRequestsCommand extends KCommand {
  SecretsRequestsCommand(super.ctx) {
    addOrgOption(this);
    argParser.addFlag(
      'all',
      negatable: false,
      help: 'Include answered and expired requests.',
    );
  }
  @override
  String get name => 'requests';
  @override
  String get description => 'Secrets that bots are asking you for.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    var items = _items(
      await _api(c, 'GET', '/v1/secrets/requests', query: {'org_id': org.id}),
    );
    if (!(argResults!['all'] as bool)) {
      items = items.where((r) => r['status'] == 'pending').toList();
    }
    return ctx.emit(
      items,
      items.isEmpty
          ? 'No bot is asking for a secret.'
          : items
                .map(
                  (r) =>
                      '${r['id']}  ${_pad(r['status'], 9)} ${_pad(r['name'], 20)} ${r['service']}: ${r['reason']}',
                )
                .join('\n'),
    );
  }
}

class SecretsFulfillCommand extends KCommand {
  SecretsFulfillCommand(super.ctx) {
    argParser.addOption(
      'value',
      help: 'The secret. Safer to leave out: you are asked.',
    );
  }
  @override
  String get name => 'fulfill';
  @override
  String get description => 'Give a bot the secret it asked for.';
  @override
  String get invocation => 'casama secrets fulfill <request id>';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which request? Pass its id', usage);
    final value = argResults!['value'] != null
        ? textArg(argResults!['value'] as String)
        : readSecret('Secret value: ', env: 'CASAMA_SECRET_VALUE');
    if (value.isEmpty) throw UsageException('The value is empty.', usage);
    final c = await ctx.authedClient();
    final r = await _api(
      c,
      'POST',
      '/v1/secrets/requests/$id/fulfill',
      body: {'value': value},
    ) as Json;
    return ctx.emit(r, 'Saved ${r['name']}; the bot can go on.');
  }
}

class SecretsDeclineCommand extends KCommand {
  SecretsDeclineCommand(super.ctx);
  @override
  String get name => 'decline';
  @override
  String get description => 'Tell a bot no.';
  @override
  String get invocation => 'casama secrets decline <request id>';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which request? Pass its id', usage);
    final c = await ctx.authedClient();
    final r = await _api(c, 'POST', '/v1/secrets/requests/$id/decline') as Json;
    return ctx.emit(r, 'Declined the request for ${r['name']}.');
  }
}

// ---------------------------------------------------------------------------
// knowledge
// ---------------------------------------------------------------------------

/// `casama knowledge list|add|sync|remove`.
class KnowledgeCommand extends Command<int> {
  KnowledgeCommand(CliContext ctx) {
    addSubcommand(KnowledgeListCommand(ctx));
    addSubcommand(KnowledgeAddCommand(ctx));
    addSubcommand(KnowledgeSyncCommand(ctx));
    addSubcommand(KnowledgeRemoveCommand(ctx));
  }
  @override
  String get name => 'knowledge';
  @override
  String get description =>
      'Knowledge sources bots can search: websites, repos, files.';
}

String _knowledgeLine(Json k) =>
    '${k['id']}  ${_pad(k['status'], 8)} ${_pad(k['kind'], 10)} ${_pad(k['name'], 24)} ${k['documents']} docs${k['error'] == null ? '' : '  (${k['error']})'}';

class KnowledgeListCommand extends KCommand {
  KnowledgeListCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this, help: 'Only this bot\'s sources.');
  }
  @override
  String get name => 'list';
  @override
  String get description => 'The workspace\'s knowledge sources.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await _botOpt(ctx, c, argResults!, usage, required: false);
    final items = _items(
      await _api(
        c,
        'GET',
        '/v1/knowledge-sources',
        query: {'org_id': org.id, 'bot_id': ?bot?['id']},
      ),
    );
    return ctx.emit(
      items,
      items.isEmpty
          ? 'No knowledge sources. Add one with `casama knowledge add <name> --url https://...`.'
          : items.map(_knowledgeLine).join('\n'),
    );
  }
}

/// Builds the create body for `knowledge add` from the options; throws [UsageException]
/// unless exactly one of url, repo, file or integration is given.
Json knowledgeBody({
  required String orgId,
  String? botId,
  required String name,
  String? url,
  int? maxPages,
  String? repo,
  int? syncEveryHours,
  List<String> files = const [],
  String? integration,
  String? documents,
  required String usage,
}) {
  final kinds = [
    if (url != null) 'website',
    if (repo != null) 'github',
    if (files.isNotEmpty) 'upload',
    if (integration != null) 'connection',
  ];
  if (kinds.length != 1) {
    throw UsageException(
      'Pass exactly one source: --url (website), --repo (GitHub), --file (upload) or --integration with --documents.',
      usage,
    );
  }
  final kind = kinds.single;
  final body = <String, dynamic>{
    'org_id': orgId,
    'bot_id': ?botId,
    'kind': kind,
    'name': name,
  };
  switch (kind) {
    case 'website':
      body['url'] = url;
      if (maxPages != null) body['max_pages'] = maxPages;
    case 'github':
      body['repo_url'] = repo;
      if (syncEveryHours != null) body['sync_every_hours'] = syncEveryHours;
    case 'upload':
      body['files'] = [
        for (final f in files)
          {
            'name': p.basename(f),
            'content_base64': base64.encode(
              File(f).existsSync()
                  ? File(f).readAsBytesSync()
                  : throw CliError('file_not_found', 'No file at $f.'),
            ),
          },
      ];
    case 'connection':
      if (documents == null) {
        throw UsageException(
          '--integration needs --documents <json or @file>: a list of {tool, args, title}.',
          usage,
        );
      }
      body['integration_id'] = integration;
      body['documents'] = jsonDecode(textArg(documents));
  }
  return body;
}

class KnowledgeAddCommand extends KCommand {
  KnowledgeAddCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(
      this,
      help: 'Give the source to one bot only (default: the whole workspace).',
    );
    argParser
      ..addOption('url', help: 'A website to read.')
      ..addOption('max-pages', help: 'Pages to read from the website.')
      ..addOption('repo', help: 'A GitHub repository URL.')
      ..addOption(
        'sync-every-hours',
        help: 'Re-read the repository this often.',
      )
      ..addMultiOption(
        'file',
        abbr: 'f',
        help: 'A file to upload. Repeat for more.',
      )
      ..addOption(
        'integration',
        help: 'A connection id to read from (use with --documents).',
      )
      ..addOption(
        'documents',
        help: 'JSON list of {tool, args, title}, or @file.',
      );
  }
  @override
  String get name => 'add';
  @override
  String get description =>
      'Add a website, GitHub repository, files or connection as knowledge.';
  @override
  String get invocation =>
      'casama knowledge add <name> (--url u | --repo u | --file f | --integration id --documents j)';
  @override
  Future<int> run() async {
    final n = _one(argResults!.rest, 'What should it be called?', usage);
    if ([
              'url',
              'repo',
              'integration',
            ].where((k) => argResults![k] != null).length +
            (argResults!['file'] as List).length.clamp(0, 1) !=
        1) {
      throw UsageException(
        'Pass exactly one source: --url (website), --repo (GitHub), --file (upload) or --integration with --documents.',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await _botOpt(ctx, c, argResults!, usage, required: false);
    int? num_(String k) {
      final v = argResults![k] as String?;
      if (v == null) return null;
      return int.tryParse(v) ??
          (throw UsageException('--$k must be a number.', usage));
    }

    final body = knowledgeBody(
      orgId: org.id,
      botId: bot?['id'] as String?,
      name: n,
      url: argResults!['url'] as String?,
      maxPages: num_('max-pages'),
      repo: argResults!['repo'] as String?,
      syncEveryHours: num_('sync-every-hours'),
      files: argResults!['file'] as List<String>,
      integration: argResults!['integration'] as String?,
      documents: argResults!['documents'] as String?,
      usage: usage,
    );
    final k =
        await _api(c, 'POST', '/v1/knowledge-sources', body: body) as Json;
    return ctx.emit(k, 'Added ${k['name']} (${k['id']}), ${k['status']}.');
  }
}

class KnowledgeSyncCommand extends KCommand {
  KnowledgeSyncCommand(super.ctx);
  @override
  String get name => 'sync';
  @override
  String get description => 'Read a knowledge source again now.';
  @override
  String get invocation => 'casama knowledge sync <id>';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which source? Pass its id', usage);
    final c = await ctx.authedClient();
    final k = await _api(c, 'POST', '/v1/knowledge-sources/$id/sync') as Json;
    return ctx.emit(k, 'Syncing ${k['name']} (${k['status']}).');
  }
}

class KnowledgeRemoveCommand extends KCommand {
  KnowledgeRemoveCommand(super.ctx) {
    _addYes(this, 'Delete it.');
  }
  @override
  String get name => 'remove';
  @override
  String get description =>
      'Delete a knowledge source and what was read from it.';
  @override
  String get invocation => 'casama knowledge remove <id> --yes';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which source? Pass its id', usage);
    final gate = confirmGate(
      ctx,
      argResults!['yes'] as bool,
      'delete knowledge source $id',
    );
    if (gate != null) return gate;
    final c = await ctx.authedClient();
    final r = await _api(c, 'DELETE', '/v1/knowledge-sources/$id');
    return ctx.emit(r, 'Deleted $id.');
  }
}

// ---------------------------------------------------------------------------
// channels
// ---------------------------------------------------------------------------

/// `casama channels list|add|slack|edit|remove|events`.
class ChannelsCommand extends Command<int> {
  ChannelsCommand(CliContext ctx) {
    addSubcommand(ChannelsListCommand(ctx));
    addSubcommand(ChannelsAddCommand(ctx));
    addSubcommand(ChannelsSlackCommand(ctx));
    addSubcommand(ChannelsEditCommand(ctx));
    addSubcommand(ChannelsRemoveCommand(ctx));
    addSubcommand(ChannelsEventsCommand(ctx));
  }
  @override
  String get name => 'channels';
  @override
  String get description =>
      'Where a bot can be reached: Telegram, email, Slack, and more.';
}

const channelKinds = [
  'telegram', 'email', 'sms', 'slack', 'whatsapp', 'messenger',
  'feishu', 'imessage', 'teams', 'discord', 'linear', 'jira', //
];

String _channelLine(Json ch) =>
    '${ch['id']}  ${ch['enabled'] == true ? 'on ' : 'off'} ${_pad(ch['kind'], 10)} ${_pad(ch['name'], 22)}${ch['last_error'] == null ? '' : '  (${ch['last_error']})'}';

class ChannelsListCommand extends KCommand {
  ChannelsListCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'A bot\'s channels.';
  @override
  String get invocation => 'casama channels list --bot <name>';
  @override
  Future<int> run() async {
    _needBot(argResults!, usage);
    final c = await ctx.authedClient();
    final bot = (await _botOpt(ctx, c, argResults!, usage))!;
    final items = _items(
      await _api(c, 'GET', '/v1/channels', query: {'bot_id': bot['id']}),
    );
    return ctx.emit(
      items,
      items.isEmpty
          ? '${bot['name']} has no channels. Add one with `casama channels add`.'
          : items.map(_channelLine).join('\n'),
    );
  }
}

class ChannelsAddCommand extends KCommand {
  ChannelsAddCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this);
    argParser
      ..addMultiOption(
        'config',
        help: 'key=value setting for the channel. Repeat for more.',
      )
      ..addMultiOption(
        'secret',
        help: 'key=value secret (a token). A bare key asks for the value.',
      )
      ..addMultiOption(
        'allow',
        help: 'A sender who may write to the bot. Repeat for more.',
      );
  }
  @override
  String get name => 'add';
  @override
  String get description =>
      'Add a channel to a bot. Kinds: ${channelKinds.join(', ')}. For Slack use `channels slack`.';
  @override
  String get invocation =>
      'casama channels add <kind> <name> --bot <name> [--secret token=...] [--allow sender]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException(
        'Pass a kind and a name, for example: casama channels add telegram support --bot Ava',
        usage,
      );
    }
    if (!channelKinds.contains(rest[0])) {
      throw UsageException(
        'Unknown kind "${rest[0]}". Use one of: ${channelKinds.join(', ')}.',
        usage,
      );
    }
    if (rest[0] == 'slack') {
      throw UsageException(
        'Slack is added from the browser: run `casama channels slack --bot <name>`.',
        usage,
      );
    }
    final config = parsePairs(argResults!['config'] as List<String>, usage);
    final secrets = <String, String>{};
    for (final e in parsePairs(
      argResults!['secret'] as List<String>,
      usage,
    ).entries) {
      secrets[e.key] = e.value ?? readSecret('${e.key}: ');
    }
    _needBot(argResults!, usage);
    final c = await ctx.authedClient();
    final bot = (await _botOpt(ctx, c, argResults!, usage))!;
    final ch = await _api(
      c,
      'POST',
      '/v1/channels',
      body: {
        'bot_id': bot['id'],
        'kind': rest[0],
        'name': rest[1],
        if (config.isNotEmpty) 'config': config,
        if (secrets.isNotEmpty) 'secrets': secrets,
        'allowed_senders': argResults!['allow'],
      },
    ) as Json;
    final extra = [
      if (ch['webhook_url'] != null) 'Webhook URL: ${ch['webhook_url']}',
      if (ch['verify_token'] != null) 'Verify token: ${ch['verify_token']}',
    ];
    return ctx.emit(
      ch,
      ['Added ${ch['name']} (${ch['id']}).', ...extra].join('\n'),
    );
  }
}

class ChannelsSlackCommand extends KCommand {
  ChannelsSlackCommand(super.ctx) {
    addOrgOption(this);
    _addBotOption(this);
    argParser.addFlag(
      'browser',
      defaultsTo: true,
      help: 'Open the link in the browser.',
    );
  }
  @override
  String get name => 'slack';
  @override
  String get description =>
      'Connect a bot to Slack. Opens the Slack install page.';
  @override
  String get invocation => 'casama channels slack --bot <name>';
  @override
  Future<int> run() async {
    _needBot(argResults!, usage);
    final c = await ctx.authedClient();
    final bot = (await _botOpt(ctx, c, argResults!, usage))!;
    final r = await _api(
      c,
      'GET',
      '/v1/channels/slack/install',
      query: {'bot_id': bot['id']},
    ) as Json;
    final url = r['url'] as String;
    if (argResults!['browser'] as bool) await openInBrowser(Uri.parse(url));
    return ctx.emit(r, 'Add ${bot['name']} to Slack: $url');
  }
}

class ChannelsEditCommand extends KCommand {
  ChannelsEditCommand(super.ctx) {
    argParser
      ..addOption('name', help: 'A new name.')
      ..addMultiOption(
        'allow',
        help: 'Replace the allowed senders. Repeat for more.',
      )
      ..addFlag(
        'enabled',
        defaultsTo: null,
        help: 'Turn the channel on (--enabled) or off (--no-enabled).',
      );
  }
  @override
  String get name => 'edit';
  @override
  String get description =>
      'Rename a channel, change who may write, or turn it on or off.';
  @override
  String get invocation =>
      'casama channels edit <id> [--name n] [--allow sender] [--no-enabled]';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which channel? Pass its id', usage);
    final allow = argResults!['allow'] as List<String>;
    final body = <String, dynamic>{
      'name': ?argResults!['name'],
      if (allow.isNotEmpty) 'allowed_senders': allow,
      'enabled': ?argResults!['enabled'],
    };
    if (body.isEmpty) throw UsageException('Nothing to change.', usage);
    final c = await ctx.authedClient();
    final ch = await _api(c, 'PATCH', '/v1/channels/$id', body: body) as Json;
    return ctx.emit(ch, 'Updated.\n${_channelLine(ch)}');
  }
}

class ChannelsRemoveCommand extends KCommand {
  ChannelsRemoveCommand(super.ctx) {
    _addYes(this, 'Delete it.');
  }
  @override
  String get name => 'remove';
  @override
  String get description => 'Delete a channel.';
  @override
  String get invocation => 'casama channels remove <id> --yes';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which channel? Pass its id', usage);
    final gate = confirmGate(
      ctx,
      argResults!['yes'] as bool,
      'delete channel $id',
    );
    if (gate != null) return gate;
    final c = await ctx.authedClient();
    final r = await _api(c, 'DELETE', '/v1/channels/$id');
    return ctx.emit(r, 'Deleted $id.');
  }
}

class ChannelsEventsCommand extends KCommand {
  ChannelsEventsCommand(super.ctx);
  @override
  String get name => 'events';
  @override
  String get description => 'Recent messages in and out of a channel.';
  @override
  String get invocation => 'casama channels events <id>';
  @override
  Future<int> run() async {
    final id = _one(argResults!.rest, 'Which channel? Pass its id', usage);
    final c = await ctx.authedClient();
    final items = _items(await _api(c, 'GET', '/v1/channels/$id/events'));
    return ctx.emit(
      items,
      items.isEmpty
          ? 'No events yet.'
          : items
                .map(
                  (e) =>
                      '${_pad(e['created_at'], 25)} ${e['direction'] == 'in' ? '<-' : '->'} ${_pad(e['status'], 8)} ${_pad(e['sender'], 20)} ${e['preview'] ?? e['detail'] ?? ''}',
                )
                .join('\n'),
    );
  }
}
