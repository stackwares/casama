import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'commands_bots.dart' show addOrgOption, botFrom, orgFrom, streamRun;
import 'runner.dart';

/// Routines: `casama routines list|show|create|edit|delete|run`.
class RoutinesCommand extends Command<int> {
  RoutinesCommand(CliContext ctx) {
    addSubcommand(RoutinesListCommand(ctx));
    addSubcommand(RoutinesShowCommand(ctx));
    addSubcommand(RoutinesCreateCommand(ctx));
    addSubcommand(RoutinesEditCommand(ctx));
    addSubcommand(RoutinesDeleteCommand(ctx));
    addSubcommand(RoutinesRunCommand(ctx));
  }
  @override
  String get name => 'routines';
  @override
  String get description => 'Routines: work a bot does on a schedule.';
}

/// Text from the option itself, or from a file when it starts with `@`.
String? textOrFile(String? v) {
  if (v == null || !v.startsWith('@')) return v;
  final f = File(v.substring(1));
  if (!f.existsSync()) {
    throw CliError('file_not_found', 'No file at ${v.substring(1)}.');
  }
  return f.readAsStringSync();
}

/// A date option as UTC-aware DateTime, or a usage error.
DateTime? parseWhen(String? v, String flag, String usage) {
  if (v == null) return null;
  final d = DateTime.tryParse(v);
  if (d == null) {
    throw UsageException(
      '--$flag needs a date like 2026-12-31 or 2026-12-31T09:00:00Z.',
      usage,
    );
  }
  return d;
}

/// A whole-number option, or a usage error.
int? parseCount(String? v, String flag, String usage) {
  if (v == null) return null;
  final n = int.tryParse(v);
  if (n == null || n < 1) {
    throw UsageException('--$flag needs a whole number of 1 or more.', usage);
  }
  return n;
}

String _short(DateTime? d) =>
    d == null ? '-' : d.toUtc().toIso8601String().substring(0, 16);

/// One list line: id first.
String routineLine(Routine r) =>
    '${r.id}  ${r.enabled ? 'on ' : 'off'}  ${r.name}  '
    '${r.scheduleCron ?? r.trigger.value}  next ${_short(r.nextRunAt)}';

String routineText(Routine r) => [
  '${r.name}  (${r.id})',
  'Bot: ${r.botId}',
  'State: ${r.enabled ? 'on' : 'off'}',
  'Trigger: ${r.trigger.value}${r.scheduleCron == null ? '' : '  ${r.scheduleCron}'}  ${r.timezone}',
  'Next run: ${_short(r.nextRunAt)}',
  'Last run: ${_short(r.lastRunAt)}',
  if (r.runCount != null)
    'Runs: ${r.runCount}${r.maxRuns == null ? '' : ' of ${r.maxRuns}'}',
  if (r.endsAt != null) 'Ends: ${_short(r.endsAt)}',
  'Instructions:\n${r.instructionsMd}',
].join('\n');

Future<List<Routine>> _allRoutines(
  CasamaClient c,
  OrganizationWithRole org,
) async {
  final bots = (await c.bots.listBots(orgId: org.id)).data!.items;
  final out = <Routine>[];
  for (final b in bots) {
    out.addAll((await c.routines.listRoutines(id: b.id)).data!.items);
  }
  return out;
}

class RoutinesListCommand extends KCommand {
  RoutinesListCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption('bot', abbr: 'b', help: 'Only this bot\'s routines.');
  }
  @override
  String get name => 'list';
  @override
  String get description => 'Routines in the workspace, or one bot\'s.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final botRef = argResults!['bot'] as String?;
    final List<Routine> items;
    if (botRef != null) {
      final bot = await botFrom(c, org, botRef);
      items = (await c.routines.listRoutines(id: bot.id)).data!.items;
    } else {
      items = await _allRoutines(c, org);
    }
    return ctx.emit(
      [for (final r in items) r.toJson()],
      items.isEmpty
          ? 'No routines yet. Make one with `casama routines create <bot> --name ... --schedule ... --instructions ...`.'
          : items.map(routineLine).join('\n'),
    );
  }
}

class RoutinesShowCommand extends KCommand {
  RoutinesShowCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'show';
  @override
  String get description => 'One routine: schedule, state and instructions.';
  @override
  String get invocation => 'casama routines show <routine id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which routine? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final r = (await _allRoutines(
      c,
      org,
    )).where((x) => x.id == rest.single).firstOrNull;
    if (r == null) {
      throw CliError(
        'routine_not_found',
        'No routine ${rest.single} in ${org.name}. See `casama routines list`.',
      );
    }
    return ctx.emit(r.toJson(), routineText(r));
  }
}

class RoutinesCreateCommand extends KCommand {
  RoutinesCreateCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('name', help: 'Routine name.')
      ..addOption(
        'schedule',
        help: 'Cron schedule, like "0 9 * * 1-5" (weekdays at 9).',
      )
      ..addOption(
        'at',
        help: 'Run once at this time instead, like 2026-12-31T09:00:00Z.',
      )
      ..addOption(
        'instructions',
        help: 'What the bot should do, or @file to read it from a file.',
      )
      ..addOption('timezone', help: 'IANA zone, like Europe/Berlin.')
      ..addOption('ends-at', help: 'Stop after this date.')
      ..addOption('max-runs', help: 'Stop after this many runs.')
      ..addFlag(
        'notify',
        help: 'Notify you when it finishes.',
        defaultsTo: null,
      );
  }
  @override
  String get name => 'create';
  @override
  String get description => 'Make a routine for a bot.';
  @override
  String get invocation =>
      'casama routines create <bot> --name <name> --schedule <cron> --instructions <text|@file>';
  @override
  Future<int> run() async {
    final a = argResults!;
    if (a.rest.length != 1) {
      throw UsageException('Which bot? Pass its name or id.', usage);
    }
    final name = a['name'] as String?;
    final instructions = textOrFile(a['instructions'] as String?);
    if (name == null || name.trim().isEmpty) {
      throw UsageException('--name is required.', usage);
    }
    if (instructions == null || instructions.trim().isEmpty) {
      throw UsageException('--instructions is required.', usage);
    }
    final cron = a['schedule'] as String?;
    final at = parseWhen(a['at'] as String?, 'at', usage);
    if ((cron == null) == (at == null)) {
      throw UsageException('Pass one of --schedule or --at.', usage);
    }
    final endsAt = parseWhen(a['ends-at'] as String?, 'ends-at', usage);
    final maxRuns = parseCount(a['max-runs'] as String?, 'max-runs', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, a['org'] as String?);
    final bot = await botFrom(c, org, a.rest.single);
    final r = (await c.routines.createRoutine(
      createRoutineRequest: CreateRoutineRequest(
        botId: bot.id,
        name: name,
        instructions: instructions,
        trigger: cron != null ? RoutineTrigger.schedule : RoutineTrigger.once,
        scheduleCron: cron,
        runAt: at,
        timezone: a['timezone'] as String?,
        notify: a['notify'] as bool?,
        endsAt: endsAt,
        maxRuns: maxRuns,
      ),
    )).data!;
    return ctx.emit(
      r.toJson(),
      'Created ${r.name} (${r.id}). Next run ${_short(r.nextRunAt)}.',
    );
  }
}

class RoutinesEditCommand extends KCommand {
  RoutinesEditCommand(super.ctx) {
    argParser
      ..addOption('name', help: 'New name.')
      ..addOption('schedule', help: 'New cron schedule.')
      ..addOption('at', help: 'New one-time run time.')
      ..addOption('instructions', help: 'New instructions, or @file.')
      ..addOption('timezone', help: 'New IANA zone.')
      ..addOption('ends-at', help: 'Stop after this date.')
      ..addOption('max-runs', help: 'Stop after this many runs.')
      ..addFlag(
        'notify',
        help: 'Notify you when it finishes.',
        defaultsTo: null,
      )
      ..addFlag('enable', negatable: false, help: 'Turn the routine on.')
      ..addFlag('disable', negatable: false, help: 'Turn the routine off.');
  }
  @override
  String get name => 'edit';
  @override
  String get description => 'Change a routine. Only the flags you pass change.';
  @override
  String get invocation => 'casama routines edit <routine id> [flags]';

  /// The PATCH body for the given flags; null when no flag was given.
  UpdateRoutineRequest? buildRequest() {
    final a = argResults!;
    if (a['enable'] as bool && a['disable'] as bool) {
      throw UsageException('Pass --enable or --disable, not both.', usage);
    }
    final enabled = a['enable'] as bool
        ? true
        : (a['disable'] as bool ? false : null);
    final req = UpdateRoutineRequest(
      name: a['name'] as String?,
      instructions: textOrFile(a['instructions'] as String?),
      scheduleCron: a['schedule'] as String?,
      runAt: parseWhen(a['at'] as String?, 'at', usage),
      timezone: a['timezone'] as String?,
      notify: a['notify'] as bool?,
      enabled: enabled,
      endsAt: parseWhen(a['ends-at'] as String?, 'ends-at', usage),
      maxRuns: parseCount(a['max-runs'] as String?, 'max-runs', usage),
    );
    return req.toJson().isEmpty ? null : req;
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.length != 1) {
      throw UsageException('Which routine? Pass its id.', usage);
    }
    final req = buildRequest();
    if (req == null) {
      throw UsageException('Nothing to change. Pass at least one flag.', usage);
    }
    final c = await ctx.authedClient();
    final r = (await c.routines.updateRoutine(
      id: argResults!.rest.single,
      updateRoutineRequest: req,
    )).data!;
    return ctx.emit(r.toJson(), 'Updated.\n${routineText(r)}');
  }
}

class RoutinesDeleteCommand extends KCommand {
  RoutinesDeleteCommand(super.ctx) {
    argParser.addFlag('yes', negatable: false, help: 'Delete without asking.');
  }
  @override
  String get name => 'delete';
  @override
  String get description => 'Delete a routine. Needs --yes.';
  @override
  String get invocation => 'casama routines delete <routine id> --yes';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which routine? Pass its id.', usage);
    }
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit(
        {'would': 'delete routine ${rest.single}', 'confirm': '--yes'},
        'This would delete routine ${rest.single}.\nRun again with --yes to delete it.',
      );
    }
    final c = await ctx.authedClient();
    await c.routines.deleteRoutine(id: rest.single);
    return ctx.emit({'deleted': rest.single}, 'Deleted.');
  }
}

class RoutinesRunCommand extends KCommand {
  RoutinesRunCommand(super.ctx) {
    argParser.addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Stream the run until it ends.',
    );
  }
  @override
  String get name => 'run';
  @override
  String get description => 'Run a routine now.';
  @override
  String get invocation => 'casama routines run <routine id> [--watch]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which routine? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final s = (await c.routines.runRoutine(id: rest.single)).data!;
    if (argResults!['watch'] as bool && !ctx.json) {
      ctx.err.writeln('Run ${s.runId}');
      return streamRun(ctx, c, s.runId);
    }
    return ctx.emit(s.toJson(), 'Started run ${s.runId}.');
  }
}

/// Approvals: `casama approvals list|approve|deny`.
class ApprovalsCommand extends Command<int> {
  ApprovalsCommand(CliContext ctx) {
    addSubcommand(ApprovalsListCommand(ctx));
    addSubcommand(ApprovalsApproveCommand(ctx));
    addSubcommand(ApprovalsDenyCommand(ctx));
  }
  @override
  String get name => 'approvals';
  @override
  String get description => 'What bots are waiting to be allowed to do.';
}

String approvalLine(Approval a) =>
    '${a.id}  ${a.status.value.padRight(8)}  ${a.risk.value.padRight(6)}  '
    '${a.toolName}  ${a.summary}  (bot ${a.botId}, run ${a.runId})';

class ApprovalsListCommand extends KCommand {
  ApprovalsListCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption(
      'status',
      help: 'Which approvals to list.',
      allowed: ['pending', 'approved', 'denied', 'expired'],
      defaultsTo: 'pending',
    );
  }
  @override
  String get name => 'list';
  @override
  String get description => 'Approvals bots are asking for.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final items = (await c.approvals.listApprovals(
      orgId: org.id,
      status: argResults!['status'] as String?,
    )).data!.items;
    return ctx.emit(
      [for (final a in items) a.toJson()],
      items.isEmpty
          ? 'Nothing is waiting.'
          : items.map(approvalLine).join('\n'),
    );
  }
}

class ApprovalsApproveCommand extends KCommand {
  ApprovalsApproveCommand(super.ctx) {
    argParser.addFlag(
      'always',
      negatable: false,
      help: 'Also allow this tool from now on.',
    );
  }
  @override
  String get name => 'approve';
  @override
  String get description => 'Allow what a bot is asking to do.';
  @override
  String get invocation => 'casama approvals approve <approval id> [--always]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which approval? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final a = (await c.approvals.decideApproval(
      id: rest.single,
      approvalDecisionRequest: ApprovalDecisionRequest(
        decision: ApprovalDecisionRequestDecisionEnum.approved,
        alwaysAllow: argResults!['always'] as bool ? true : null,
      ),
    )).data!;
    return ctx.emit(a.toJson(), 'Approved: ${a.toolName}  ${a.summary}');
  }
}

class ApprovalsDenyCommand extends KCommand {
  ApprovalsDenyCommand(super.ctx);
  @override
  String get name => 'deny';
  @override
  String get description => 'Refuse what a bot is asking to do.';
  @override
  String get invocation => 'casama approvals deny <approval id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which approval? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final a = (await c.approvals.decideApproval(
      id: rest.single,
      approvalDecisionRequest: ApprovalDecisionRequest(
        decision: ApprovalDecisionRequestDecisionEnum.denied,
      ),
    )).data!;
    return ctx.emit(a.toJson(), 'Denied: ${a.toolName}  ${a.summary}');
  }
}

String _dur(Run r) {
  if (r.startedAt == null) return '-';
  final end = r.endedAt ?? DateTime.now();
  return '${end.difference(r.startedAt!).inSeconds}s';
}

/// `casama runs show <id>`.
class RunsShowCommand extends KCommand {
  RunsShowCommand(super.ctx);
  @override
  String get name => 'show';
  @override
  String get description => 'One run: status, bot, timings and cost.';
  @override
  String get invocation => 'casama runs show <run id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which run? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final r = (await c.runs.getRun(id: rest.single)).data!;
    return ctx.emit(
      r.toJson(),
      [
        '${r.id}  ${r.status.value}',
        'Bot: ${r.botId}',
        'Trigger: ${r.trigger}',
        'Started: ${_short(r.startedAt)}  Ended: ${_short(r.endedAt)}  (${_dur(r)})',
        'Tokens: ${r.tokensIn} in, ${r.tokensOut} out',
        'Cost: \$${r.costUsd.toStringAsFixed(4)}',
        if (r.error != null) 'Error: ${r.error!.message} (${r.error!.code})',
      ].join('\n'),
    );
  }
}

/// `casama runs usage <id>`.
class RunsUsageCommand extends KCommand {
  RunsUsageCommand(super.ctx);
  @override
  String get name => 'usage';
  @override
  String get description => 'What a run used and what it cost.';
  @override
  String get invocation => 'casama runs usage <run id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which run? Pass its id.', usage);
    }
    final c = await ctx.authedClient();
    final u = (await c.runs.getRunUsage(id: rest.single)).data!;
    return ctx.emit(
      u.toJson(),
      [
        '${u.runId}  ${u.status.value}',
        'Charged: \$${u.chargedUsd.toStringAsFixed(4)}',
        'Tokens: ${u.tokensIn} in, ${u.tokensOut} out',
        if (u.durationMs != null) 'Duration: ${u.durationMs} ms',
        'Tool calls: ${u.toolCalls}  Sub-runs: ${u.subruns}',
        for (final i in u.items)
          '  ${i.kind}${i.model == null ? '' : ' ${i.model}'}  ${i.quantity}  \$${i.costUsd.toStringAsFixed(4)}',
      ].join('\n'),
    );
  }
}
