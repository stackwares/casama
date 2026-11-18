import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:path/path.dart' as p;

import 'commands_bots.dart' show addOrgOption, botFrom, orgFrom;
import 'commands_computers.dart' show computerFrom;
import 'runner.dart';

/// Long text from an option: `@path` reads the file.
String? textOption(String? v) {
  if (v == null) return null;
  if (v.startsWith('@')) {
    final f = File(v.substring(1));
    if (!f.existsSync()) {
      throw CliError('file_not_found', 'No file ${f.path}.');
    }
    return f.readAsStringSync();
  }
  return v;
}

/// Without --yes: say what would happen and stop (exit 0). Returns null when `--yes` is set.
int? confirmGate(
  CliContext ctx,
  Command<int> cmd,
  String would,
  String commandLine,
) {
  if (cmd.argResults!['yes'] as bool) return null;
  return ctx.emit({
    'would': would,
    'confirm': '--yes',
  }, 'Would $would.\nRun again with --yes: $commandLine --yes');
}

void _addYes(Command<int> cmd, String help) =>
    cmd.argParser.addFlag('yes', abbr: 'y', negatable: false, help: help);

String _one(Command<int> cmd, String what) {
  final rest = cmd.argResults!.rest;
  if (rest.length != 1) {
    throw UsageException('Which $what? Pass its id.', cmd.usage);
  }
  return rest.single;
}

String _day(DateTime d) => d.toLocal().toString().substring(0, 16);

String formatBytes(num b) {
  if (b < 1024) return '${b.toInt()} B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = b / 1024;
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}

// ---------------------------------------------------------------- projects

class ProjectsCommand extends Command<int> {
  ProjectsCommand(CliContext ctx) {
    addSubcommand(ProjectsListCommand(ctx));
    addSubcommand(ProjectsShowCommand(ctx));
    addSubcommand(ProjectsCreateCommand(ctx));
    addSubcommand(ProjectsEditCommand(ctx));
    addSubcommand(ProjectsApprovePlanCommand(ctx));
    addSubcommand(ProjectsSignoffCommand(ctx));
  }
  @override
  String get name => 'projects';
  @override
  String get description =>
      'Projects: goals, plans and milestones a bot works through.';
}

String projectLine(Project x) =>
    '${x.id}\t${x.status.value}\t${x.title}\tplan ${x.planStatus.value}\t\$${x.spentUsd.toStringAsFixed(2)} spent';

class ProjectsListCommand extends KCommand {
  ProjectsListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'The workspace\'s projects.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final items = (await c.projects.listProjects(orgId: org.id)).data!.items;
    return ctx.emit(
      [for (final x in items) x.toJson()],
      items.isEmpty
          ? 'No projects yet. Start one with `casama projects create <name> --bot <bot>`.'
          : items.map(projectLine).join('\n'),
    );
  }
}

class ProjectsShowCommand extends KCommand {
  ProjectsShowCommand(super.ctx);
  @override
  String get name => 'show';
  @override
  String get description => 'One project with its plan and milestones.';
  @override
  String get invocation => 'casama projects show <project id>';
  @override
  Future<int> run() async {
    final id = _one(this, 'project');
    final c = await ctx.authedClient();
    final x = (await c.projects.getProject(id: id)).data!;
    final lines = <String>[
      '${x.title}  (${x.id})',
      'Status: ${x.status.value}${x.statusReason == null ? '' : ' (${x.statusReason})'}   Plan: ${x.planStatus.value}',
      'Spent: \$${x.spentUsd.toStringAsFixed(2)}${x.budgetUsd == null ? '' : ' of \$${x.budgetUsd}'}${x.deadlineAt == null ? '' : '   Due: ${_day(x.deadlineAt!)}'}',
      if (x.goalMd.isNotEmpty) '\nGoal:\n${x.goalMd}',
      if (x.doneCriteriaMd.isNotEmpty) '\nDone when:\n${x.doneCriteriaMd}',
      if (x.planMd.isNotEmpty) '\nPlan:\n${x.planMd}',
      if (x.milestones.isNotEmpty) '\nMilestones:',
      for (final m in x.milestones)
        '  ${m.id}\t${m.status.value}\t${m.name}\t${m.ticketsDone}/${m.ticketsTotal} tickets${m.requiresSignoff ? '\tneeds sign-off' : ''}',
    ];
    return ctx.emit(x.toJson(), lines.join('\n'));
  }
}

class ProjectsCreateCommand extends KCommand {
  ProjectsCreateCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption(
        'bot',
        abbr: 'b',
        help: 'The lead bot, by name or id.',
        valueHelp: 'bot',
      )
      ..addOption('goal', help: 'What the project is for. @file reads a file.')
      ..addOption('done', help: 'When it counts as done. @file reads a file.')
      ..addOption('budget', help: 'Spending limit in USD.')
      ..addOption('deadline', help: 'Due date, like 2026-12-31.')
      ..addFlag(
        'autonomous',
        help: 'Let the bot keep working without asking.',
        defaultsTo: null,
      );
  }
  @override
  String get name => 'create';
  @override
  String get description => 'Start a project led by a bot.';
  @override
  String get invocation => 'casama projects create <name> --bot <bot>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw UsageException('What is the project called?', usage);
    }
    final botRef = argResults!['bot'] as String?;
    if (botRef == null) {
      throw UsageException('Pass the lead bot with --bot <name or id>.', usage);
    }
    final budget = argResults!['budget'] as String?;
    final deadline = argResults!['deadline'] as String?;
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, botRef);
    final x = (await c.projects.createProject(
      createProjectRequest: CreateProjectRequest(
        orgId: org.id,
        title: rest.join(' '),
        leadBotId: bot.id,
        goalMd: textOption(argResults!['goal'] as String?),
        doneCriteriaMd: textOption(argResults!['done'] as String?),
        budgetUsd: budget == null ? null : _num(budget, 'budget', usage),
        deadlineAt: deadline == null ? null : _date(deadline, usage),
        autonomous: argResults!['autonomous'] as bool?,
      ),
    )).data!;
    return ctx.emit(x.toJson(), 'Created project ${x.title} (${x.id}).');
  }
}

num _num(String v, String what, String usage) =>
    num.tryParse(v) ??
    (throw UsageException('--$what must be a number, got "$v".', usage));

DateTime _date(String v, String usage) =>
    DateTime.tryParse(v) ??
    (throw UsageException('Dates look like 2026-12-31, got "$v".', usage));

class ProjectsEditCommand extends KCommand {
  ProjectsEditCommand(super.ctx) {
    argParser
      ..addOption('title', help: 'New name.')
      ..addOption(
        'status',
        allowed: ['active', 'paused', 'cancelled', 'done'],
        help: 'Move the project to this status.',
      )
      ..addOption('budget', help: 'Spending limit in USD.')
      ..addOption('deadline', help: 'Due date, like 2026-12-31.')
      ..addOption('plan', help: 'The plan, in Markdown. @file reads a file.')
      ..addOption('goal', help: 'What the project is for. @file reads a file.')
      ..addOption('done', help: 'When it counts as done. @file reads a file.')
      ..addFlag(
        'autonomous',
        help: 'Let the bot keep working without asking.',
        defaultsTo: null,
      );
  }
  @override
  String get name => 'edit';
  @override
  String get description =>
      'Change a project. Only the options you pass change.';
  @override
  String get invocation => 'casama projects edit <project id> [--title ...]';
  @override
  Future<int> run() async {
    final id = _one(this, 'project');
    final a = argResults!;
    final status = a['status'] as String?;
    final budget = a['budget'] as String?;
    final deadline = a['deadline'] as String?;
    final req = UpdateProjectRequest(
      title: a['title'] as String?,
      status: status == null
          ? null
          : UpdateProjectRequestStatusEnum.values.firstWhere(
              (e) => e.value == status,
            ),
      budgetUsd: budget == null ? null : _num(budget, 'budget', usage),
      deadlineAt: deadline == null ? null : _date(deadline, usage),
      planMd: textOption(a['plan'] as String?),
      goalMd: textOption(a['goal'] as String?),
      doneCriteriaMd: textOption(a['done'] as String?),
      autonomous: a['autonomous'] as bool?,
    );
    if (req.toJson().values.every((v) => v == null)) {
      throw UsageException(
        'Nothing to change. Pass at least one option.',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final x = (await c.projects.updateProject(
      id: id,
      updateProjectRequest: req,
    )).data!;
    return ctx.emit(x.toJson(), 'Updated ${x.title}.\n${projectLine(x)}');
  }
}

class ProjectsApprovePlanCommand extends KCommand {
  ProjectsApprovePlanCommand(super.ctx);
  @override
  String get name => 'approve-plan';
  @override
  String get description => 'Approve the proposed plan so the bot starts work.';
  @override
  String get invocation => 'casama projects approve-plan <project id>';
  @override
  Future<int> run() async {
    final id = _one(this, 'project');
    final c = await ctx.authedClient();
    final x = (await c.projects.approveProjectPlan(id: id)).data!;
    return ctx.emit(x.toJson(), 'Plan approved for ${x.title}.');
  }
}

class ProjectsSignoffCommand extends KCommand {
  ProjectsSignoffCommand(super.ctx);
  @override
  String get name => 'signoff';
  @override
  String get description => 'Sign off a finished milestone.';
  @override
  String get invocation =>
      'casama projects signoff <project id> <milestone id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException('Pass the project id and the milestone id.', usage);
    }
    final c = await ctx.authedClient();
    final x = (await c.projects.signOffMilestone(
      id: rest[0],
      milestoneId: rest[1],
    )).data!;
    return ctx.emit(
      x.toJson(),
      'Signed off milestone ${rest[1]} in ${x.title}.',
    );
  }
}

// ----------------------------------------------------------------- library

class LibraryCommand extends Command<int> {
  LibraryCommand(CliContext ctx) {
    addSubcommand(LibraryListCommand(ctx));
    addSubcommand(LibraryShowCommand(ctx));
    addSubcommand(LibraryDownloadCommand(ctx));
    addSubcommand(LibraryRenameCommand(ctx));
    addSubcommand(LibraryDuplicateCommand(ctx));
    addSubcommand(LibraryRestoreCommand(ctx));
    addSubcommand(LibraryDeleteCommand(ctx));
  }
  @override
  String get name => 'library';
  @override
  String get description => 'Files and pages your bots made.';
}

String creationLine(Creation x) =>
    '${x.id}\t${x.kind.value}\t${x.title}\t${formatBytes(x.size)}\t${x.botName ?? '-'}\t${_day(x.createdAt)}';

const _mimeExt = {
  'text/html': 'html',
  'text/plain': 'txt',
  'text/markdown': 'md',
  'text/csv': 'csv',
  'application/json': 'json',
  'application/pdf': 'pdf',
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/gif': 'gif',
  'image/webp': 'webp',
  'image/svg+xml': 'svg',
  'video/mp4': 'mp4',
  'audio/mpeg': 'mp3',
  'audio/wav': 'wav',
  'application/zip': 'zip',
};

/// A safe local file name for a creation: its title, plus an extension from the mime type
/// when the title has none.
String creationFileName(String title, String? mime) {
  var n = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  if (n.isEmpty || n == '.' || n == '..') n = 'creation';
  final ext = mime == null ? null : _mimeExt[mime.split(';').first.trim()];
  if (ext != null && !n.contains('.')) n = '$n.$ext';
  return n;
}

class LibraryListCommand extends KCommand {
  LibraryListCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('project', help: 'Only this project (id).')
      ..addOption(
        'kind',
        allowed: ['page', 'image', 'video', 'audio', 'document', 'file'],
        help: 'Only this kind.',
      )
      ..addOption('search', abbr: 's', help: 'Search the titles.')
      ..addOption('bot', help: 'Only what this bot made (name or id).')
      ..addFlag(
        'deleted',
        negatable: false,
        help: 'Show what was deleted in the last 30 days.',
      )
      ..addOption('limit', help: 'How many (1 to 100).');
  }
  @override
  String get name => 'list';
  @override
  String get description => 'List files and pages bots made.';
  @override
  Future<int> run() async {
    final a = argResults!;
    final kind = a['kind'] as String?;
    final limit = a['limit'] as String?;
    final n = limit == null ? null : int.tryParse(limit);
    if (limit != null && (n == null || n < 1 || n > 100)) {
      throw UsageException('--limit is a number from 1 to 100.', usage);
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, a['org'] as String?);
    final botRef = a['bot'] as String?;
    final bot = botRef == null ? null : await botFrom(c, org, botRef);
    final r = (await c.creations.listCreations(
      orgId: org.id,
      kind: kind == null
          ? null
          : CreationKind.values.firstWhere((k) => k.value == kind),
      projectId: a['project'] as String?,
      botId: bot?.id,
      q: a['search'] as String?,
      deleted: (a['deleted'] as bool) ? 'true' : null,
      limit: n,
    )).data!;
    return ctx.emit(
      r.toJson(),
      r.items.isEmpty
          ? 'Nothing here yet.'
          : [
              ...r.items.map(creationLine),
              if (r.nextCursor != null)
                '(more: raise --limit or narrow with --search)',
            ].join('\n'),
    );
  }
}

class LibraryShowCommand extends KCommand {
  LibraryShowCommand(super.ctx);
  @override
  String get name => 'show';
  @override
  String get description => 'Details of one file or page.';
  @override
  String get invocation => 'casama library show <id>';
  @override
  Future<int> run() async {
    final id = _one(this, 'creation');
    final c = await ctx.authedClient();
    final x = (await c.creations.getCreation(id: id)).data!;
    final lines = [
      '${x.title}  (${x.id})',
      'Kind: ${x.kind.value}${x.mime == null ? '' : '   Type: ${x.mime}'}   Size: ${formatBytes(x.size)}   Version: ${x.version}',
      'Made by: ${x.botName ?? '-'}${x.projectTitle == null ? '' : '   Project: ${x.projectTitle}'}',
      'Created: ${_day(x.createdAt)}   Updated: ${_day(x.updatedAt)}',
      'Visibility: ${x.visibility.value}${x.publicUrl == null ? '' : '   ${x.publicUrl}'}',
      if (x.deletedAt != null)
        'Deleted: ${_day(x.deletedAt!)} (restore with `casama library restore ${x.id}`)',
      if (x.siblings.isNotEmpty) 'Other versions:',
      for (final s in x.siblings) '  ${creationLine(s)}',
    ];
    return ctx.emit(x.toJson(), lines.join('\n'));
  }
}

class LibraryDownloadCommand extends KCommand {
  LibraryDownloadCommand(super.ctx) {
    argParser.addOption(
      'out',
      abbr: 'O',
      help: 'File or folder to save to (default: the creation\'s name, here).',
    );
  }
  @override
  String get name => 'download';
  @override
  String get description => 'Save a file or page to this computer.';
  @override
  String get invocation => 'casama library download <id> [--out path]';
  @override
  Future<int> run() async {
    final id = _one(this, 'creation');
    final c = await ctx.authedClient();
    final x = (await c.creations.getCreation(id: id)).data!;
    final bytes = (await c.creations.getCreationContent(id: id)).data!;
    var out = argResults!['out'] as String?;
    final name = creationFileName(x.title, x.mime);
    if (out == null) {
      out = name;
    } else if (Directory(out).existsSync() ||
        out.endsWith('/') ||
        out.endsWith(Platform.pathSeparator)) {
      out = p.join(out, name);
    }
    File(out).parent.createSync(recursive: true);
    File(out).writeAsBytesSync(bytes);
    return ctx.emit({
      'id': id,
      'saved_to': out,
      'size': bytes.length,
    }, 'Saved ${bytes.length} bytes to $out.');
  }
}

class LibraryRenameCommand extends KCommand {
  LibraryRenameCommand(super.ctx);
  @override
  String get name => 'rename';
  @override
  String get description => 'Give a file or page a new title.';
  @override
  String get invocation => 'casama library rename <id> <new title>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      throw UsageException('Pass the id and the new title.', usage);
    }
    final c = await ctx.authedClient();
    final x = (await c.creations.updateCreation(
      id: rest.first,
      updateCreationRequest: UpdateCreationRequest(
        title: rest.skip(1).join(' '),
      ),
    )).data!;
    return ctx.emit(x.toJson(), 'Renamed to ${x.title}.');
  }
}

class LibraryDuplicateCommand extends KCommand {
  LibraryDuplicateCommand(super.ctx);
  @override
  String get name => 'duplicate';
  @override
  String get description => 'Make a copy of a file or page.';
  @override
  String get invocation => 'casama library duplicate <id>';
  @override
  Future<int> run() async {
    final id = _one(this, 'creation');
    final c = await ctx.authedClient();
    final x = (await c.creations.duplicateCreation(id: id)).data!;
    return ctx.emit(x.toJson(), 'Copied to ${x.title} (${x.id}).');
  }
}

class LibraryRestoreCommand extends KCommand {
  LibraryRestoreCommand(super.ctx);
  @override
  String get name => 'restore';
  @override
  String get description =>
      'Bring back a deleted file or page (deleted in the last 30 days; see `list --deleted`).';
  @override
  String get invocation => 'casama library restore <id>';
  @override
  Future<int> run() async {
    final id = _one(this, 'creation');
    final c = await ctx.authedClient();
    final x = (await c.creations.restoreCreation(id: id)).data!;
    return ctx.emit(x.toJson(), 'Restored ${x.title}.');
  }
}

class LibraryDeleteCommand extends KCommand {
  LibraryDeleteCommand(super.ctx) {
    _addYes(this, 'Delete it. Without this, only say what would happen.');
  }
  @override
  String get name => 'delete';
  @override
  String get description =>
      'Delete a file or page. It can be restored for 30 days, then it is gone.';
  @override
  String get invocation => 'casama library delete <id> --yes';
  @override
  Future<int> run() async {
    final id = _one(this, 'creation');
    final gate = confirmGate(
      ctx,
      this,
      'delete creation $id (restorable for 30 days)',
      'casama library delete $id',
    );
    if (gate != null) return gate;
    final c = await ctx.authedClient();
    final x = (await c.creations.deleteCreation(id: id)).data!;
    return ctx.emit(
      x.toJson(),
      'Deleted ${x.title}. Undo within 30 days: casama library restore ${x.id}',
    );
  }
}

// ---------------------------------------------- computer subcommands (extra)

/// Base for the extra `casama computer <action>` commands: --org and --computer like the others.
abstract class ComputerOpCommand extends KCommand {
  ComputerOpCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption(
      'computer',
      abbr: 'c',
      help: 'Computer id (default: the team computer).',
    );
  }
  Future<(CasamaClient, Computer)> target() async {
    final c = await ctx.authedClient();
    return (c, await computerFrom(ctx, c, argResults!));
  }
}

class ComputerRestartCommand extends ComputerOpCommand {
  ComputerRestartCommand(super.ctx);
  @override
  String get name => 'restart';
  @override
  String get description => 'Sleep and start again. Files are kept.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final r = (await c.computers.restartComputer(id: comp.id)).data!;
    return ctx.emit(r.toJson(), '${r.name}: ${r.state.value}');
  }
}

class ComputerResetCommand extends ComputerOpCommand {
  ComputerResetCommand(super.ctx) {
    argParser
      ..addFlag(
        'erase',
        negatable: false,
        help: 'Also empty the home folder, like a new computer. Default: fresh system, files kept.',
      )
      ..addFlag(
        'no-checkpoint',
        negatable: false,
        help: 'Skip the restore point that is normally saved first.',
      );
    _addYes(this, 'Go ahead. Without this, only say what would happen.');
  }
  @override
  String get name => 'reset';
  @override
  String get description =>
      'Reset the computer to a fresh system. This wipes the system; with --erase it wipes your files too.';
  @override
  Future<int> run() async {
    final erase = argResults!['erase'] as bool;
    final (c, comp) = await target();
    final gate = confirmGate(
      ctx,
      this,
      erase
          ? 'ERASE ${comp.name}: everything is removed, including files in ~/workspace'
          : 'reset ${comp.name} to a fresh system (the system is wiped, ~/workspace is kept)',
      'casama computer reset${erase ? ' --erase' : ''} -c ${comp.id}',
    );
    if (gate != null) return gate;
    final r = (await c.computers.resetComputer(
      id: comp.id,
      resetComputerRequest: ResetComputerRequest(
        mode: erase
            ? ResetComputerRequestModeEnum.erase
            : ResetComputerRequestModeEnum.system,
        checkpoint: !(argResults!['no-checkpoint'] as bool),
      ),
    )).data!;
    return ctx.emit(
      r.toJson(),
      'Resetting ${r.name} in the background (${erase ? 'erase' : 'fresh system'}). Check with `casama computer status`.',
    );
  }
}

String processLine(ComputerProcess x) =>
    '${x.pid.toString().padLeft(7)}  ${x.cpuPercent.toStringAsFixed(1).padLeft(5)}%  ${formatBytes(x.memoryBytes).padLeft(8)}  ${x.system ? 'system' : 'user  '}  ${x.name}  ${x.command}';

class ComputerProcessesCommand extends ComputerOpCommand {
  ComputerProcessesCommand(super.ctx);
  @override
  String get name => 'processes';
  @override
  String get description => 'Programs running on the computer.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final r = (await c.computers.listComputerProcesses(id: comp.id)).data!;
    return ctx.emit(
      r.toJson(),
      r.items.isEmpty
          ? 'Nothing is running.'
          : '    PID    CPU    Memory  Kind    Name\n${r.items.map(processLine).join('\n')}',
    );
  }
}

class ComputerKillCommand extends ComputerOpCommand {
  ComputerKillCommand(super.ctx);
  @override
  String get name => 'kill';
  @override
  String get description => 'Stop a program by its PID (see `processes`).';
  @override
  String get invocation => 'casama computer kill <pid>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final pid = rest.length == 1 ? int.tryParse(rest.single) : null;
    if (pid == null) throw UsageException('Pass one PID, a number.', usage);
    final (c, comp) = await target();
    final r = (await c.computers.stopComputerProcess(
      id: comp.id,
      pid: pid,
    )).data!;
    return ctx.emit(
      r.toJson(),
      'Stopped ${r.stopped} process(es) for PID $pid.',
    );
  }
}

class ComputerScreenshotCommand extends ComputerOpCommand {
  ComputerScreenshotCommand(super.ctx) {
    argParser.addOption(
      'out',
      abbr: 'O',
      help: 'Where to save the picture.',
      defaultsTo: 'screenshot.png',
    );
  }
  @override
  String get name => 'screenshot';
  @override
  String get description => 'Save a picture of the computer\'s screen.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final bytes = (await c.computers.computerScreenshot(id: comp.id)).data!;
    final out = argResults!['out'] as String;
    File(out).writeAsBytesSync(bytes);
    return ctx.emit({
      'saved_to': out,
      'size': bytes.length,
    }, 'Saved ${bytes.length} bytes to $out.');
  }
}

String vitalsText(ComputerVitals v) =>
    'CPU: ${v.cpuPercent.toStringAsFixed(1)}%\n'
    'Memory: ${formatBytes(v.memoryUsedBytes)} of ${formatBytes(v.memoryLimitBytes)}\n'
    'Disk: ${formatBytes(v.diskUsedBytes)} of ${formatBytes(v.diskLimitBytes)}';

class ComputerVitalsCommand extends ComputerOpCommand {
  ComputerVitalsCommand(super.ctx);
  @override
  String get name => 'vitals';
  @override
  String get description => 'CPU, memory and disk use right now.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final v = (await c.computers.computerVitals(id: comp.id)).data!;
    return ctx.emit(v.toJson(), vitalsText(v));
  }
}

String storageText(ComputerStorage s) => [
  'Used: ${formatBytes(s.usedBytes)} of ${formatBytes(s.limitBytes)}',
  for (final cat in s.categories)
    '  ${cat.id.value.padRight(12)} ${formatBytes(cat.bytes)}',
  'Can be cleaned: ${formatBytes(s.cleanableBytes)}${s.cleanableBytes > 0 ? ' (casama computer storage-clean --yes)' : ''}',
].join('\n');

class ComputerStorageCommand extends ComputerOpCommand {
  ComputerStorageCommand(super.ctx);
  @override
  String get name => 'storage';
  @override
  String get description => 'Disk space used, by category.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final s = (await c.computers.computerStorage(id: comp.id)).data!;
    return ctx.emit(s.toJson(), storageText(s));
  }
}

class ComputerStorageCleanCommand extends ComputerOpCommand {
  ComputerStorageCleanCommand(super.ctx) {
    _addYes(this, 'Clean now. Without this, only say what would happen.');
  }
  @override
  String get name => 'storage-clean';
  @override
  String get description =>
      'Free space: removes caches and temporary files (never ~/workspace).';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final gate = confirmGate(
      ctx,
      this,
      'remove caches and temporary files on ${comp.name} (files in ~/workspace stay)',
      'casama computer storage-clean -c ${comp.id}',
    );
    if (gate != null) return gate;
    final r = (await c.computers.cleanComputerStorage(id: comp.id)).data!;
    return ctx.emit(r.toJson(), 'Freed ${formatBytes(r.freedBytes)}.');
  }
}

class ComputerHistoryCommand extends ComputerOpCommand {
  ComputerHistoryCommand(super.ctx);
  @override
  String get name => 'history';
  @override
  String get description => 'What happened to the computer, newest first.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final r = (await c.computers.computerHistory(id: comp.id)).data!;
    return ctx.emit(
      r.toJson(),
      r.items.isEmpty
          ? 'No history yet.'
          : r.items
                .map(
                  (e) =>
                      '${_day(e.createdAt)}\t${e.action}\t${e.actorName ?? e.actorType.value}',
                )
                .join('\n'),
    );
  }
}

class ComputerUpdateCommand extends ComputerOpCommand {
  ComputerUpdateCommand(super.ctx) {
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Restart even while a command is running.',
    );
    _addYes(this, 'Update now. Without this, only say what would happen.');
  }
  @override
  String get name => 'update';
  @override
  String get description =>
      'Restart on the newer system now. Files are kept; open windows and programs close.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final gate = confirmGate(
      ctx,
      this,
      'restart ${comp.name} on the newer system (open windows and programs close, files are kept)',
      'casama computer update -c ${comp.id}',
    );
    if (gate != null) return gate;
    final r = (await c.computers.applyComputerUpdate(
      id: comp.id,
      applyComputerUpdateRequest: ApplyComputerUpdateRequest(
        force: (argResults!['force'] as bool) ? true : null,
      ),
    )).data!;
    return ctx.emit(r.toJson(), 'Updating ${r.name}: ${r.state.value}');
  }
}

class ComputerCheckpointCommand extends ComputerOpCommand {
  ComputerCheckpointCommand(super.ctx) {
    argParser.addOption(
      'label',
      abbr: 'l',
      help: 'A name for the undo point.',
      defaultsTo: 'Saved from the CLI',
    );
  }
  @override
  String get name => 'checkpoint';
  @override
  String get description =>
      'Make an undo point now (see `checkpoints`, `restore`).';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final cp = (await c.computers.createCheckpoint(
      id: comp.id,
      createCheckpointRequest: CreateCheckpointRequest(
        label: argResults!['label'] as String,
      ),
    )).data!;
    return ctx.emit(cp.toJson(), 'Saved undo point ${cp.id} (${cp.label}).');
  }
}

class ComputerUsageCommand extends ComputerOpCommand {
  ComputerUsageCommand(super.ctx);
  @override
  String get name => 'usage';
  @override
  String get description => 'Computer time and cost this month.';
  @override
  Future<int> run() async {
    final (c, comp) = await target();
    final u = (await c.computers.computerUsage(id: comp.id)).data!;
    final hours = (u.seconds / 3600).toStringAsFixed(1);
    return ctx.emit(
      u.toJson(),
      'Since ${u.monthStart}: $hours hours, \$${u.costUsd.toStringAsFixed(2)}\n'
      '${u.days.where((d) => d.seconds > 0).map((d) => '${d.date}\t${(d.seconds / 3600).toStringAsFixed(1)} h').join('\n')}',
    );
  }
}
