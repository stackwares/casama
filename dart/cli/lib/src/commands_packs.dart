import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:path/path.dart' as p;

import 'commands_bots.dart' show addOrgOption, orgFrom;
import 'runner.dart';

/// Packs (docs/PLUGINS-AND-PACKS-PLAN.md): `casama packs preview|install|list|update|remove|export`.
class PacksCommand extends Command<int> {
  PacksCommand(CliContext ctx) {
    addSubcommand(PacksPreviewCommand(ctx));
    addSubcommand(PacksInstallCommand(ctx));
    addSubcommand(PacksListCommand(ctx));
    addSubcommand(PacksUpdateCommand(ctx));
    addSubcommand(PacksRemoveCommand(ctx));
    addSubcommand(PacksExportCommand(ctx));
  }
  @override
  String get name => 'packs';
  @override
  String get description =>
      'Packs: plugins that bring bots, skills, routines, apps and looks to a workspace.';
}

/// Most files a pack folder may hold, as the server allows.
const _maxFiles = 400;

/// A pack folder's files for the API: every file except dot folders like .git.
List<PackFileInput> packFolderFiles(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) {
    throw CliError('not_found', 'No folder at $dir.');
  }
  final out = <PackFileInput>[];
  for (final e in root.listSync(recursive: true, followLinks: false)) {
    if (e is! File) continue;
    final rel = p.split(p.relative(e.path, from: dir));
    if (rel.any((part) => part.startsWith('.') && part != '.claude-plugin')) {
      continue;
    }
    final mode = e.statSync().modeString();
    out.add(
      PackFileInput(
        path: rel.join('/'),
        base64: base64Encode(e.readAsBytesSync()),
        executable: mode.length >= 3 && mode[2] == 'x',
      ),
    );
    if (out.length > _maxFiles) {
      throw CliError('too_large', 'A pack holds at most $_maxFiles files.');
    }
  }
  out.sort((a, b) => a.path.compareTo(b.path));
  return out;
}

/// `KEY=value` pairs from repeated options.
Map<String, String> _pairs(List<String> given, String what) {
  final out = <String, String>{};
  for (final g in given) {
    final i = g.indexOf('=');
    if (i <= 0) {
      throw CliError(
        'bad_option',
        '$what must look like NAME=value, not "$g".',
      );
    }
    out[g.substring(0, i)] = g.substring(i + 1);
  }
  return out;
}

bool _isLink(String s) => s.startsWith('https://') || s.startsWith('http://');

String _previewText(PackPreview v) {
  final b = StringBuffer()
    ..writeln('${v.name} ${v.version ?? ''}'.trim())
    ..writeln(v.summary)
    ..writeln(v.reviewed ? 'Reviewed by Casama' : 'Not reviewed by Casama');
  void list(String title, Iterable<String> items) {
    final all = items.toList();
    if (all.isEmpty) return;
    b.writeln('$title:');
    for (final i in all) {
      b.writeln('  - $i');
    }
  }

  list('Bots', v.bots.map((x) => '${x.name} (${x.id})'));
  list(
    'Skills',
    v.skills.map(
      (x) =>
          '${x.name}${x.scope.name == 'workspace' ? ' (whole workspace)' : ''}',
    ),
  );
  list(
    'Routines',
    v.routines.map(
      (x) => '${x.name}: ${x.scheduleCron} (${x.runsPerWeek}/week)',
    ),
  );
  list('Apps', v.apps.map((x) => '${x.name} (${x.host})'));
  list('Looks', v.looks.map((x) => '${x.name} (${x.type.name})'));
  list('Tools', v.servers.map((x) => '${x.key} (${x.type})'));
  list('Questions', v.inputs.map((x) => '${x.key}: ${x.label}'));
  list('Secrets it asks for', v.secrets.map((x) => x.name));
  list(
    'Settings',
    v.settings.map((x) => '${x.name} (default ${x.default_ ?? '-'})'),
  );
  final r = v.reach;
  b.writeln(
    'Reach: ${r.runsCode ? 'runs code' : 'no code'}${r.computer ? ', uses a computer' : ''}'
    '${r.hosts.isEmpty ? '' : ', reaches ${r.hosts.join(', ')}'}'
    ', ${r.runsPerWeek} scheduled runs a week',
  );
  list('Warnings', v.warnings);
  if (v.installed != null) b.writeln('Already installed (${v.installed!.id}).');
  return b.toString().trimRight();
}

abstract class _PackSourceCommand extends KCommand {
  _PackSourceCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('commit', help: 'Pin a commit (GitHub links).')
      ..addOption(
        'gallery',
        help: 'A reviewed pack from the directory, by id.',
      );
  }

  /// One of: a GitHub link, a folder on this computer, or --gallery.
  ({String? url, String? galleryId, List<PackFileInput>? files}) source() {
    final rest = argResults!.rest;
    final gallery = argResults!['gallery'] as String?;
    if (gallery != null && rest.isEmpty) {
      return (url: null, galleryId: gallery, files: null);
    }
    if (rest.length != 1) {
      throw UsageException(
        'Pass a GitHub link, a folder, or --gallery <id>.',
        usage,
      );
    }
    final s = rest.single;
    return _isLink(s)
        ? (url: s, galleryId: null, files: null)
        : (url: null, galleryId: null, files: packFolderFiles(s));
  }
}

class PacksPreviewCommand extends _PackSourceCommand {
  PacksPreviewCommand(super.ctx);
  @override
  String get name => 'preview';
  @override
  String get description => 'Show what a pack brings before installing it.';
  @override
  String get invocation =>
      'casama packs preview <github link | folder> [--gallery <id>]';
  @override
  Future<int> run() async {
    final s = source();
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final v = (await c.packs.previewPack(
      previewPackRequest: PreviewPackRequest(
        orgId: org.id,
        url: s.url,
        commit: argResults!['commit'] as String?,
        galleryId: s.galleryId,
        files: s.files,
      ),
    )).data!;
    return ctx.emit(v.toJson(), _previewText(v));
  }
}

class PacksInstallCommand extends _PackSourceCommand {
  PacksInstallCommand(super.ctx) {
    argParser
      ..addMultiOption('input', help: 'An answer: key=value (repeatable).')
      ..addMultiOption('secret', help: 'A secret: NAME=value (repeatable).')
      ..addMultiOption('setting', help: 'A setting: NAME=value (repeatable).')
      ..addMultiOption(
        'skip',
        help: 'Leave an item out: kind:id, e.g. routine:monday-recap.',
      )
      ..addOption(
        'bot',
        help: 'Where tools and routines go when the pack brings no bot.',
      )
      ..addFlag(
        'routines',
        defaultsTo: true,
        help: 'Start routines on (reviewed packs only; others start off).',
      );
  }
  @override
  String get name => 'install';
  @override
  String get description => 'Install a pack in a workspace.';
  @override
  String get invocation =>
      'casama packs install <github link | folder> [--input k=v] [--secret K=v] [--skip kind:id]';
  @override
  Future<int> run() async {
    final s = source();
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    var commit = argResults!['commit'] as String?;
    // A link installs the commit the preview would show, so what's installed is what was checked.
    if (s.url != null && commit == null) {
      commit = (await c.packs.previewPack(
        previewPackRequest: PreviewPackRequest(orgId: org.id, url: s.url),
      )).data!.commit;
    }
    final skip = [
      for (final k in argResults!['skip'] as List<String>)
        PackItemRef.fromJson({
          'kind': k.split(':').first,
          'id': k.contains(':') ? k.substring(k.indexOf(':') + 1) : k,
        }),
    ];
    final res = await c.packs.installPack(
      installPackRequest: InstallPackRequest(
        orgId: org.id,
        url: s.url,
        commit: commit,
        galleryId: s.galleryId,
        files: s.files,
        skip: skip.isEmpty ? null : skip,
        inputs: _pairs(argResults!['input'] as List<String>, '--input'),
        secrets: _pairs(argResults!['secret'] as List<String>, '--secret'),
        settings: _pairs(argResults!['setting'] as List<String>, '--setting'),
        botId: argResults!['bot'] as String?,
        routinesOn: argResults!['routines'] as bool,
      ),
    );
    final r = res.data!;
    if (r.status.name == 'approvalPending' || res.statusCode == 202) {
      return ctx.emit(
        r.toJson(),
        'An admin approves packs here. We\'ve asked them.',
      );
    }
    final lines = [
      'Installed ${r.pack?.name ?? 'the pack'}.',
      for (final i in r.items)
        '  ${i.status.value.padRight(9)} ${i.kind.value} ${i.name}${i.error == null ? '' : ' (${i.error})'}',
      if (r.missing.apps.isNotEmpty)
        'Connect in the app: ${r.missing.apps.map((a) => a.name).join(', ')}',
      if (r.looks.isNotEmpty)
        'Looks to apply in the app: ${r.looks.map((l) => l.name).join(', ')}',
    ];
    return ctx.emit(r.toJson(), lines.join('\n'));
  }
}

class PacksListCommand extends KCommand {
  PacksListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'Packs installed in the workspace.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final items = (await c.packs.listPacks(orgId: org.id)).data!.items;
    return ctx.emit(
      [for (final x in items) x.toJson()],
      items.isEmpty
          ? 'No packs yet.'
          : items
                .map(
                  (x) =>
                      '${x.name} ${x.version ?? ''}  ${x.items.length} items  '
                      '${x.reviewed ? 'reviewed' : 'not reviewed'}  (${x.id})',
                )
                .join('\n'),
    );
  }
}

class PacksUpdateCommand extends KCommand {
  PacksUpdateCommand(super.ctx) {
    argParser
      ..addFlag(
        'yes',
        negatable: false,
        help: 'Update without asking, even when it reaches further.',
      )
      ..addMultiOption(
        'take',
        help: 'Replace an item you edited anyway: kind:id.',
      );
  }
  @override
  String get name => 'update';
  @override
  String get description => 'Show a pack\'s update, then apply it with --yes.';
  @override
  String get invocation =>
      'casama packs update <pack id> [--yes] [--take kind:id]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which pack? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final u = (await c.packs.getPackUpdate(id: rest.single)).data!;
    if (!u.canCheck) {
      return ctx.emit(
        u.toJson(),
        'This pack came from a file or a link: it can\'t check for updates.',
      );
    }
    if (u.upToDate) return ctx.emit(u.toJson(), 'Up to date.');
    String kinds(String title, PackKindDiff d) => [
      if (d.added.isNotEmpty) '$title added: ${d.added.join(', ')}',
      if (d.removed.isNotEmpty) '$title removed: ${d.removed.join(', ')}',
      if (d.changed.isNotEmpty)
        '$title changed: ${d.changed.map((x) => x.id).join(', ')}',
    ].join('\n');
    final summary = [
      '${u.fromVersion ?? u.fromCommit} → ${u.toVersion ?? u.toCommit}',
      kinds('Bots', u.bots),
      kinds('Skills', u.skills),
      kinds('Routines', u.routines),
      kinds('Apps', u.apps),
      kinds('Tools', u.servers),
      if (u.hostsAdded.isNotEmpty) 'New hosts: ${u.hostsAdded.join(', ')}',
      if (u.secretsAdded.isNotEmpty)
        'New secrets: ${u.secretsAdded.join(', ')}',
      if (u.edited.isNotEmpty)
        'You edited (kept unless --take): ${u.edited.map((e) => '${e.kind.value}:${e.id}').join(', ')}',
      if (u.reachGrew) 'It can reach more than before.',
    ].where((l) => l.isNotEmpty).join('\n');
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit(
        u.toJson(),
        '$summary\n\nRun again with --yes to update.',
      );
    }
    final take = [
      for (final k in argResults!['take'] as List<String>)
        PackItemRef.fromJson({
          'kind': k.split(':').first,
          'id': k.substring(k.indexOf(':') + 1),
        }),
    ];
    final r = (await c.packs.updatePack(
      id: rest.single,
      updatePackRequest: UpdatePackRequest(
        commit: u.toCommit!,
        takeTheirs: take.isEmpty ? null : take,
        confirmReach: true,
      ),
    )).data!;
    return ctx.emit(r.toJson(), 'Updated to ${r.pack?.version ?? u.toCommit}.');
  }
}

class PacksRemoveCommand extends KCommand {
  PacksRemoveCommand(super.ctx) {
    argParser.addFlag(
      'delete-bots',
      negatable: false,
      help: 'Also delete the bots it made (kept by default).',
    );
  }
  @override
  String get name => 'remove';
  @override
  String get description =>
      'Remove a pack: its tools and untouched items go; what you edited stays.';
  @override
  String get invocation => 'casama packs remove <pack id> [--delete-bots]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which pack? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final r = (await c.packs.removePack(
      id: rest.single,
      bots: (argResults!['delete-bots'] as bool) ? 'delete' : 'keep',
    )).data!;
    return ctx.emit(
      r.toJson(),
      'Removed. Kept ${r.kept} item(s) you made your own.',
    );
  }
}

class PacksExportCommand extends KCommand {
  PacksExportCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addMultiOption('bot', help: 'A bot to include, by id (up to 5).')
      ..addMultiOption('skill', help: 'A workspace skill to include, by id.')
      ..addOption('name', help: 'The pack\'s name.')
      ..addOption('summary', help: 'One line: what it does.')
      ..addOption('out', help: 'Write the files to this folder.')
      ..addFlag(
        'share',
        negatable: false,
        help: 'Make a share link (30 days) instead.',
      )
      ..addFlag(
        'ignore-findings',
        negatable: false,
        help: 'Share even though lines look like keys (after checking them).',
      );
  }
  @override
  String get name => 'export';
  @override
  String get description =>
      'Save bots as a pack folder, or share them behind a link.';
  @override
  String get invocation =>
      'casama packs export --bot <id> --name "My kit" --summary "..." (--out <folder> | --share)';
  @override
  Future<int> run() async {
    final name = argResults!['name'] as String?;
    final summary = argResults!['summary'] as String?;
    final bots = argResults!['bot'] as List<String>;
    if (name == null || summary == null || bots.isEmpty) {
      throw UsageException('Pass --bot, --name and --summary.', usage);
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final skills = argResults!['skill'] as List<String>;
    if (argResults!['share'] as bool) {
      final s = (await c.packs.sharePack(
        id: org.id,
        sharePackRequest: SharePackRequest(
          name: name,
          summary: summary,
          botIds: bots,
          workspaceSkillIds: skills.isEmpty ? null : skills,
          ignoreFindings: argResults!['ignore-findings'] as bool,
        ),
      )).data!;
      return ctx.emit(s.toJson(), 'Shared until ${s.expiresAt}: ${s.url}');
    }
    final out = argResults!['out'] as String?;
    if (out == null) {
      throw UsageException('Pass --out <folder> or --share.', usage);
    }
    final e = (await c.packs.exportPack(
      id: org.id,
      exportPackRequest: ExportPackRequest(
        name: name,
        summary: summary,
        botIds: bots,
        workspaceSkillIds: skills.isEmpty ? null : skills,
      ),
    )).data!;
    final dir = Directory(out);
    if (dir.existsSync() && dir.listSync().isNotEmpty) {
      throw CliError('exists', '$out isn\'t empty.');
    }
    for (final f in e.files) {
      final file = File(p.joinAll([out, ...f.path.split('/')]));
      file.parent.createSync(recursive: true);
      if (f.text != null) {
        file.writeAsStringSync(f.text!);
      } else {
        file.writeAsBytesSync(base64Decode(f.base64 ?? ''));
      }
      if (f.executable && !Platform.isWindows) {
        Process.runSync('chmod', ['+x', file.path]);
      }
    }
    final warn = e.findings.isEmpty
        ? ''
        : '\nThese lines look like keys. Remove them before sharing:\n${e.findings.map((x) => '  ${x.path}:${x.line} (${x.what})').join('\n')}';
    return ctx.emit(e.toJson(), 'Wrote ${e.files.length} files to $out.$warn');
  }
}
