import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:path/path.dart' as p;

import 'commands_bots.dart' show addOrgOption, orgFrom;
import 'runner.dart';

/// Routines and skills as files (D-124): `casama files export <dir>` and `casama files import <dir>`.
class FilesCommand extends Command<int> {
  FilesCommand(CliContext ctx) {
    addSubcommand(FilesExportCommand(ctx));
    addSubcommand(FilesImportCommand(ctx));
  }
  @override
  String get name => 'files';
  @override
  String get description => 'Routines and skills as Markdown files.';
}

class FilesExportCommand extends KCommand {
  FilesExportCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'export';
  @override
  String get description => 'Write the workspace\'s routines and skills to a folder.';
  @override
  String get invocation => 'casama files export <folder>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Which folder?', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final out = (await c.files.exportWorkspaceFiles(id: org.id)).data!;
    final root = Directory(rest.single);
    for (final f in out.files) {
      final rel = p.normalize(f.path);
      if (p.isAbsolute(rel) || rel.startsWith('..')) continue;
      final file = File(p.join(root.path, rel));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(base64Decode(f.contentBase64));
    }
    return ctx.emit({
      'folder': root.path,
      'files': out.files.length,
    }, 'Wrote ${out.files.length} files to ${root.path}');
  }
}

class FilesImportCommand extends KCommand {
  FilesImportCommand(super.ctx) {
    addOrgOption(this);
    argParser.addFlag('dry-run', help: 'Show what would change without changing anything.');
  }
  @override
  String get name => 'import';
  @override
  String get description => 'Create and update routines and skills from a folder of files.';
  @override
  String get invocation => 'casama files import <folder> [--dry-run]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Which folder?', usage);
    final root = Directory(rest.single);
    if (!root.existsSync()) throw UsageException('No folder at ${root.path}', usage);
    final files = <StartAgentImportRequestFilesInner>[];
    await for (final e in root.list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final rel = p.relative(e.path, from: root.path).replaceAll(r'\', '/');
      if (rel.split('/').any((s) => s.startsWith('.'))) continue;
      files.add(StartAgentImportRequestFilesInner(path: rel, contentBase64: base64Encode(await e.readAsBytes())));
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final dry = argResults!['dry-run'] as bool;
    final r = (await c.files.importWorkspaceFiles(
      id: org.id,
      importWorkspaceFilesRequest: ImportWorkspaceFilesRequest(files: files, dryRun: dry),
    )).data!;
    final lines = [
      if (dry) 'Dry run: nothing was changed.',
      for (final x in r.created) '+ $x',
      for (final x in r.updated) '~ $x',
      '${r.unchanged} unchanged',
      for (final e in r.errors) '! $e',
    ].join('\n');
    ctx.emit(r.toJson(), lines);
    return r.errors.isEmpty ? 0 : 1;
  }
}
