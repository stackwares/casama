import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'commands_bots.dart';
import 'runner.dart';

/// Resolves --computer (id), else the organization's team computer.
Future<Computer> computerFrom(CliContext ctx, CasamaClient c, ArgResults args) async {
  final id = args['computer'] as String?;
  if (id != null) return (await c.computers.getComputer(id: id)).data!;
  final org = await orgFrom(ctx, c, args['org'] as String?);
  final list = (await c.computers.listComputers(orgId: org.id)).data!.items;
  return list.firstWhere((x) => x.kind.name == 'team', orElse: () {
    if (list.isEmpty) throw CliError('no_computer', 'No computers in ${org.name}.');
    return list.first;
  });
}

abstract class _ComputerCommand extends KCommand {
  _ComputerCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption('computer', abbr: 'c', help: 'Computer id (default: the team computer).');
  }
}

class ComputerCommand extends Command<int> {
  ComputerCommand(CliContext ctx) {
    addSubcommand(ComputerStatusCommand(ctx));
    addSubcommand(ComputerLifecycleCommand(ctx, 'start', 'Start or restore the computer.'));
    addSubcommand(ComputerLifecycleCommand(ctx, 'stop', 'Save files to storage and stop (sleep).'));
    addSubcommand(ComputerShellCommand(ctx));
    addSubcommand(ComputerFilesCommand(ctx));
    addSubcommand(ComputerCheckpointsCommand(ctx));
    addSubcommand(ComputerRestoreCommand(ctx));
  }
  @override
  String get name => 'computer';
  @override
  String get description => 'Work with bot computers: status, shell, files and checkpoints.';
}

class ComputerStatusCommand extends KCommand {
  ComputerStatusCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'status';
  @override
  String get description => 'List computers and their state.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final list = (await c.computers.listComputers(orgId: org.id)).data!;
    final lines = list.items.map((x) {
      final active = x.lastActiveAt == null ? 'never used' : 'active ${x.lastActiveAt!.toLocal().toString().substring(0, 16)}';
      return '${x.id}\t${x.name}\t${x.state.value}\t${x.profile.name}\t$active';
    }).join('\n');
    return ctx.emit(list.toJson(), lines.isEmpty ? 'No computers.' : lines);
  }
}

class ComputerLifecycleCommand extends _ComputerCommand {
  ComputerLifecycleCommand(super.ctx, this.action, this.help);
  final String action;
  final String help;
  @override
  String get name => action;
  @override
  String get description => help;
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final comp = await computerFrom(ctx, c, argResults!);
    final r = action == 'start'
        ? (await c.computers.startComputer(id: comp.id)).data!
        : (await c.computers.stopComputer(id: comp.id)).data!;
    return ctx.emit(r.toJson(), '${r.name}: ${r.state.value}');
  }
}

class ComputerShellCommand extends _ComputerCommand {
  ComputerShellCommand(super.ctx);
  @override
  String get name => 'shell';
  @override
  String get description => 'Open an interactive terminal in the computer. Type `exit` to leave.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final comp = await computerFrom(ctx, c, argResults!);
    final cols = stdout.hasTerminal ? stdout.terminalColumns : 120;
    final rows = stdout.hasTerminal ? stdout.terminalLines : 32;
    final (uri, headers) = await c.terminalEndpoint(comp.id, cols: cols, rows: rows);
    ctx.err.writeln('Connecting to ${comp.name}…');
    final ws = await WebSocket.connect(uri.toString(), headers: headers);
    final interactive = stdin.hasTerminal;
    if (interactive) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
    final input = stdin.listen((bytes) => ws.add(bytes));
    try {
      await for (final msg in ws) {
        if (msg is List<int>) {
          stdout.add(msg);
        } else {
          stdout.write(msg);
        }
      }
    } finally {
      await input.cancel();
      if (interactive) {
        stdin.lineMode = true;
        stdin.echoMode = true;
      }
    }
    ctx.err.writeln('\nDisconnected.');
    return 0;
  }
}

class ComputerFilesCommand extends _ComputerCommand {
  ComputerFilesCommand(super.ctx) {
    argParser.addOption('output', abbr: 'O', help: 'Local file for `get` (default: print to stdout).');
  }
  @override
  String get name => 'files';
  @override
  String get description => 'Files in the computer: ls [path], get <path>, put <local> <path>, rm <path>.';
  @override
  String get invocation => 'casama computer files <ls|get|put|rm> ...';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Pass ls, get, put or rm.', usage);
    final c = await ctx.authedClient();
    final comp = await computerFrom(ctx, c, argResults!);
    switch (rest.first) {
      case 'ls':
        final r = (await c.computers.listComputerFiles(id: comp.id, path: rest.length > 1 ? rest[1] : null)).data!;
        final lines = r.entries
            .map((e) => '${e.type.name == 'dir' ? 'd' : '-'} ${e.size.toString().padLeft(10)}  ${e.name}${e.type.name == 'dir' ? '/' : ''}')
            .join('\n');
        return ctx.emit(r.toJson(), lines.isEmpty ? '(empty)' : lines);
      case 'get':
        if (rest.length != 2) throw UsageException('get <path>', usage);
        final bytes = await c.downloadComputerFile(comp.id, rest[1]);
        final out = argResults!['output'] as String?;
        if (out != null) {
          File(out).writeAsBytesSync(bytes);
          return ctx.emit({'path': rest[1], 'saved_to': out, 'size': bytes.length}, 'Saved ${bytes.length} bytes to $out.');
        }
        if (identical(ctx.out, stdout)) {
          stdout.add(bytes);
          await stdout.flush();
        } else {
          ctx.out.write(utf8.decode(bytes, allowMalformed: true));
        }
        return 0;
      case 'put':
        if (rest.length != 3) throw UsageException('put <local file> <path>', usage);
        final bytes = File(rest[1]).readAsBytesSync();
        final r = await c.uploadComputerFile(comp.id, rest[2], bytes);
        return ctx.emit(r.toJson(), 'Uploaded ${r.size} bytes to ${r.path}.');
      case 'rm':
        if (rest.length != 2) throw UsageException('rm <path>', usage);
        await c.computers.deleteComputerFile(id: comp.id, path: rest[1]);
        return ctx.emit({'deleted': rest[1]}, 'Deleted ${rest[1]}.');
      default:
        throw UsageException('Unknown files action "${rest.first}".', usage);
    }
  }
}

class ComputerCheckpointsCommand extends _ComputerCommand {
  ComputerCheckpointsCommand(super.ctx);
  @override
  String get name => 'checkpoints';
  @override
  String get description => 'List undo points, newest first.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final comp = await computerFrom(ctx, c, argResults!);
    final list = (await c.computers.listCheckpoints(id: comp.id)).data!;
    final lines = list.items.map((cp) => '${cp.id}\t${cp.createdAt.toLocal().toString().substring(0, 16)}\t${cp.label}').join('\n');
    return ctx.emit(list.toJson(), lines.isEmpty ? 'No checkpoints yet.' : lines);
  }
}

class ComputerRestoreCommand extends _ComputerCommand {
  ComputerRestoreCommand(super.ctx);
  @override
  String get name => 'restore';
  @override
  String get description => 'Undo to a checkpoint (replaces the computer\'s files).';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('The checkpoint id is required.', usage);
    final c = await ctx.authedClient();
    final comp = await computerFrom(ctx, c, argResults!);
    await c.computers.restoreCheckpoint(id: comp.id, cid: rest.single);
    return ctx.emit({'restored': rest.single}, 'Restored checkpoint ${rest.single}.');
  }
}
