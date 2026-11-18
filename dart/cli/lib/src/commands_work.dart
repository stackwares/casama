import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'commands_bots.dart' show addOrgOption, botFrom, orgFrom;
import 'runner.dart';

/// Text from an option: the text itself, or `@path` to read it from a file.
String readTextArg(String value) {
  if (!value.startsWith('@')) return value;
  final f = File(value.substring(1));
  if (!f.existsSync()) {
    throw CliError('file_not_found', 'No file at ${f.path}.');
  }
  return f.readAsStringSync();
}

/// A due date from `2026-12-01` or a full ISO time, as UTC. A bare date means midday on that day
/// here, so it stays the same date in every time zone.
DateTime parseDue(String value, UsageException Function(String) bad) {
  final d = DateTime.tryParse(value);
  if (d == null) {
    throw bad('Use a date like 2026-12-01 or 2026-12-01T17:00:00Z for --due.');
  }
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
    return DateTime(d.year, d.month, d.day, 12).toUtc();
  }
  return d.toUtc();
}

TaskStatus? _status(String? v, UsageException Function(String) bad) {
  if (v == null) return null;
  final s = TaskStatus.values.where((x) => x.value == v).firstOrNull;
  if (s == null) {
    throw bad(
      'Status is one of: ${TaskStatus.values.map((x) => x.value).join(', ')}.',
    );
  }
  return s;
}

TaskPriority? _priority(String? v, UsageException Function(String) bad) {
  if (v == null) return null;
  final s = TaskPriority.values.where((x) => x.value == v).firstOrNull;
  if (s == null) {
    throw bad(
      'Priority is one of: ${TaskPriority.values.map((x) => x.value).join(', ')}.',
    );
  }
  return s;
}

String taskLine(Task t) {
  final due = t.dueAt == null
      ? ''
      : '  due ${t.dueAt!.toLocal().toIso8601String().substring(0, 10)}';
  return '${t.id}  ${t.status.value.padRight(11)} ${t.priority.value.padRight(6)} ${t.title}$due';
}

/// Tasks: `casama tasks list|add|edit|done|delete|comments|comment`.
class TasksCommand extends Command<int> {
  TasksCommand(CliContext ctx) {
    addSubcommand(TasksListCommand(ctx));
    addSubcommand(TasksAddCommand(ctx));
    addSubcommand(TasksEditCommand(ctx));
    addSubcommand(TasksDoneCommand(ctx));
    addSubcommand(TasksDeleteCommand(ctx));
    addSubcommand(TasksCommentsCommand(ctx));
    addSubcommand(TasksCommentCommand(ctx));
  }
  @override
  String get name => 'tasks';
  @override
  String get description => 'The workspace\'s tasks, for you and your bots.';
}

abstract class _TaskCommand extends KCommand {
  _TaskCommand(super.ctx);
  UsageException bad(String m) => UsageException(m, usage);
}

class TasksListCommand extends _TaskCommand {
  TasksListCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addMultiOption(
        'status',
        abbr: 's',
        help: 'Only these statuses (todo, in_progress, in_review, blocked, done).',
      )
      ..addFlag('all', negatable: false, help: 'Include done tasks.')
      ..addOption('bot', help: 'Only tasks given to this bot (name or id).');
  }
  @override
  String get name => 'list';
  @override
  String get description =>
      'List tasks. Done tasks are hidden unless asked for.';
  @override
  String get invocation => 'casama tasks list [--status todo] [--bot <bot>]';
  @override
  Future<int> run() async {
    final statuses = argResults!['status'] as List<String>;
    for (final s in statuses) {
      _status(s, bad);
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final botRef = argResults!['bot'] as String?;
    final botId = botRef == null ? null : (await botFrom(c, org, botRef)).id;
    final all = (await c.tasks.listTasks(orgId: org.id)).data!.items;
    final showDone = argResults!['all'] as bool;
    final items = all.where((t) {
      if (botId != null && t.assigneeBotId != botId) return false;
      if (statuses.isNotEmpty) return statuses.contains(t.status.value);
      return showDone || t.status != TaskStatus.done;
    }).toList();
    return ctx.emit(
      [for (final t in items) t.toJson()],
      items.isEmpty
          ? 'No tasks. Add one with `casama tasks add "<title>"`.'
          : items.map(taskLine).join('\n'),
    );
  }
}

class TasksAddCommand extends _TaskCommand {
  TasksAddCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('bot', help: 'Give the task to this bot (name or id).')
      ..addOption('due', help: 'Due date, like 2026-12-01.')
      ..addOption(
        'notes',
        help: 'Details text, or @file to read it from a file.',
      )
      ..addOption('status', help: 'Starting status. Default: todo.')
      ..addOption('priority', help: 'urgent, high, medium, low or none.')
      ..addMultiOption('label', help: 'A label. Repeat for more.');
  }
  @override
  String get name => 'add';
  @override
  String get description => 'Add a task.';
  @override
  String get invocation =>
      'casama tasks add <title> [--bot <bot>] [--due 2026-12-01]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw bad('What is the task? Pass a title.');
    final title = rest.join(' ');
    final due = argResults!['due'] as String?;
    final dueAt = due == null ? null : parseDue(due, bad);
    final status = _status(argResults!['status'] as String?, bad);
    final priority = _priority(argResults!['priority'] as String?, bad);
    final notes = argResults!['notes'] as String?;
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final botRef = argResults!['bot'] as String?;
    final botId = botRef == null ? null : (await botFrom(c, org, botRef)).id;
    final labels = argResults!['label'] as List<String>;
    final t = (await c.tasks.createTask(
      createTaskRequest: CreateTaskRequest(
        orgId: org.id,
        title: title,
        detailsMd: notes == null ? null : readTextArg(notes),
        status: status,
        priority: priority,
        assigneeBotId: botId,
        dueAt: dueAt,
        labels: labels.isEmpty ? null : labels,
      ),
    )).data!;
    return ctx.emit(t.toJson(), 'Added: ${taskLine(t)}');
  }
}

class TasksEditCommand extends _TaskCommand {
  TasksEditCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('title', help: 'New title.')
      ..addOption(
        'notes',
        help: 'New details text, or @file to read it from a file.',
      )
      ..addOption(
        'status',
        help: 'todo, in_progress, in_review, blocked or done.',
      )
      ..addOption('priority', help: 'urgent, high, medium, low or none.')
      ..addOption('bot', help: 'Give the task to this bot (name or id).')
      ..addOption('due', help: 'New due date, like 2026-12-01.')
      ..addFlag('done', negatable: false, help: 'Mark it done.');
  }
  @override
  String get name => 'edit';
  @override
  String get description => 'Change a task. Only the fields you pass change.';
  @override
  String get invocation =>
      'casama tasks edit <id> [--status done] [--title ...]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw bad('Which task? Pass its id.');
    final r = argResults!;
    final done = r['done'] as bool;
    if (done && r['status'] != null) {
      throw bad('Use --done or --status, not both.');
    }
    final status = done
        ? TaskStatus.done
        : _status(r['status'] as String?, bad);
    final priority = _priority(r['priority'] as String?, bad);
    final due = r['due'] as String?;
    final dueAt = due == null ? null : parseDue(due, bad);
    final notes = r['notes'] as String?;
    final title = r['title'] as String?;
    final botRef = r['bot'] as String?;
    if (status == null &&
        priority == null &&
        dueAt == null &&
        notes == null &&
        title == null &&
        botRef == null) {
      throw bad(
        'Nothing to change. Pass --title, --notes, --status, --priority, --bot, --due or --done.',
      );
    }
    final c = await ctx.authedClient();
    String? botId;
    if (botRef != null) {
      final org = await orgFrom(ctx, c, r['org'] as String?);
      botId = (await botFrom(c, org, botRef)).id;
    }
    final t = (await c.tasks.updateTask(
      id: rest.single,
      updateTaskRequest: UpdateTaskRequest(
        title: title,
        detailsMd: notes == null ? null : readTextArg(notes),
        status: status,
        priority: priority,
        assigneeBotId: botId,
        dueAt: dueAt,
      ),
    )).data!;
    return ctx.emit(t.toJson(), 'Updated: ${taskLine(t)}');
  }
}

class TasksDoneCommand extends _TaskCommand {
  TasksDoneCommand(super.ctx);
  @override
  String get name => 'done';
  @override
  String get description => 'Mark a task done.';
  @override
  String get invocation => 'casama tasks done <id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw bad('Which task? Pass its id.');
    final c = await ctx.authedClient();
    final t = (await c.tasks.updateTask(
      id: rest.single,
      updateTaskRequest: UpdateTaskRequest(status: TaskStatus.done),
    )).data!;
    return ctx.emit(t.toJson(), 'Done: ${taskLine(t)}');
  }
}

class TasksDeleteCommand extends _TaskCommand {
  TasksDeleteCommand(super.ctx) {
    argParser.addFlag(
      'yes',
      negatable: false,
      help: 'Delete without the dry run.',
    );
  }
  @override
  String get name => 'delete';
  @override
  String get description => 'Delete a task and its comments for good.';
  @override
  String get invocation => 'casama tasks delete <id> --yes';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw bad('Which task? Pass its id.');
    final id = rest.single;
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit(
        {'would': 'delete task $id', 'confirm': '--yes'},
        'This would delete task $id and its comments.\nRun again with --yes to delete it.',
      );
    }
    final c = await ctx.authedClient();
    await c.tasks.deleteTask(id: id);
    return ctx.emit({'id': id, 'deleted': true}, 'Deleted task $id.');
  }
}

class TasksCommentsCommand extends _TaskCommand {
  TasksCommentsCommand(super.ctx);
  @override
  String get name => 'comments';
  @override
  String get description => 'Show a task\'s comments.';
  @override
  String get invocation => 'casama tasks comments <id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw bad('Which task? Pass its id.');
    final c = await ctx.authedClient();
    final items = (await c.tasks.listTaskComments(id: rest.single)).data!.items;
    return ctx.emit(
      [for (final m in items) m.toJson()],
      items.isEmpty
          ? 'No comments. Add one with `casama tasks comment ${rest.single} "<text>"`.'
          : items
                .map(
                  (m) =>
                      '${m.createdAt.toIso8601String().substring(0, 16)}  ${m.authorType.value}  ${m.bodyMd}',
                )
                .join('\n'),
    );
  }
}

class TasksCommentCommand extends _TaskCommand {
  TasksCommentCommand(super.ctx);
  @override
  String get name => 'comment';
  @override
  String get description => 'Add a comment to a task.';
  @override
  String get invocation => 'casama tasks comment <id> <text>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) throw bad('Pass the task id and the comment text.');
    final c = await ctx.authedClient();
    final m = (await c.tasks.createTaskComment(
      id: rest.first,
      createTaskCommentRequest: CreateTaskCommentRequest(
        bodyMd: readTextArg(rest.skip(1).join(' ')),
      ),
    )).data!;
    return ctx.emit(m.toJson(), 'Commented on ${rest.first}.');
  }
}

/// Watchers: `casama watchers list|add|edit|delete`. A watcher wakes a bot when a page changes.
class WatchersCommand extends Command<int> {
  WatchersCommand(CliContext ctx) {
    addSubcommand(WatchersListCommand(ctx));
    addSubcommand(WatchersAddCommand(ctx));
    addSubcommand(WatchersEditCommand(ctx));
    addSubcommand(WatchersDeleteCommand(ctx));
  }
  @override
  String get name => 'watchers';
  @override
  String get description => 'Watch a page and wake a bot when it changes.';
}

String watcherLine(Watcher w) {
  final target = w.target['url'] ?? w.kind.value;
  final every = w.checkEverySeconds >= 60
      ? '${w.checkEverySeconds ~/ 60} min'
      : '${w.checkEverySeconds} s';
  return '${w.id}  ${w.status.value.padRight(7)} ${w.name}  $target  every $every  fired ${w.firedCount}x${w.lastError == null ? '' : '  (error: ${w.lastError})'}';
}

class WatchersListCommand extends KCommand {
  WatchersListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'A bot\'s watchers.';
  @override
  String get invocation => 'casama watchers list <bot>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which bot? Pass its name or id.', usage);
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest.single);
    final items = (await c.watchers.listWatchers(botId: bot.id)).data!.items;
    return ctx.emit(
      [for (final w in items) w.toJson()],
      items.isEmpty
          ? '${bot.name} watches nothing. Add one with `casama watchers add ${bot.name} <url>`.'
          : items.map(watcherLine).join('\n'),
    );
  }
}

class WatchersAddCommand extends KCommand {
  WatchersAddCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('name', help: 'A name for the watcher. Default: the address.')
      ..addOption(
        'anchor',
        help: 'Compare from this text on (a label just before the part that matters).',
      )
      ..addOption(
        'chars',
        help: 'How many characters after the anchor to compare.',
      )
      ..addOption(
        'condition',
        help: 'What counts as a change worth waking the bot for, in words.',
      )
      ..addOption('every', help: 'Check every this many minutes.')
      ..addOption(
        'where',
        allowed: ['server', 'mine'],
        help: 'server reads public pages; mine reads signed-in pages in your own browser.',
      );
  }
  @override
  String get name => 'add';
  @override
  String get description => 'Watch a page. The bot wakes when it changes.';
  @override
  String get invocation =>
      'casama watchers add <bot> <url> [--condition "price drops"]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException('Pass the bot and the page address.', usage);
    }
    final uri = Uri.tryParse(rest[1]);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw UsageException(
        'The page needs a full address, like https://example.com/page.',
        usage,
      );
    }
    int? intOpt(String key) {
      final v = argResults![key] as String?;
      if (v == null) return null;
      final n = int.tryParse(v);
      if (n == null || n <= 0) {
        throw UsageException('--$key must be a positive number.', usage);
      }
      return n;
    }

    final chars = intOpt('chars');
    final every = intOpt('every');
    final where = argResults!['where'] as String?;
    final cond = argResults!['condition'] as String?;
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest[0]);
    final w = (await c.watchers.createPageWatcher(
      createPageWatcherRequest: CreatePageWatcherRequest(
        botId: bot.id,
        name: argResults!['name'] as String? ?? uri.host,
        url: rest[1],
        anchor: argResults!['anchor'] as String?,
        chars: chars,
        condition: cond == null ? null : readTextArg(cond),
        checkEveryMinutes: every,
        where: where == null
            ? null
            : CreatePageWatcherRequestWhereEnum.values.firstWhere(
                (x) => x.value == where,
              ),
      ),
    )).data!;
    return ctx.emit(w.toJson(), 'Watching: ${watcherLine(w)}');
  }
}

class WatchersEditCommand extends KCommand {
  WatchersEditCommand(super.ctx) {
    argParser
      ..addFlag('pause', negatable: false, help: 'Stop checking for now.')
      ..addFlag('resume', negatable: false, help: 'Start checking again.');
  }
  @override
  String get name => 'edit';
  @override
  String get description => 'Pause or resume a watcher.';
  @override
  String get invocation => 'casama watchers edit <id> --pause|--resume';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which watcher? Pass its id.', usage);
    }
    final pause = argResults!['pause'] as bool;
    final resume = argResults!['resume'] as bool;
    if (pause == resume) {
      throw UsageException('Pass --pause or --resume (one of them).', usage);
    }
    final c = await ctx.authedClient();
    final w = (await c.watchers.updateWatcher(
      id: rest.single,
      updateWatcherRequest: UpdateWatcherRequest(
        status: pause
            ? UpdateWatcherRequestStatusEnum.paused
            : UpdateWatcherRequestStatusEnum.active,
      ),
    )).data!;
    return ctx.emit(
      w.toJson(),
      '${pause ? 'Paused' : 'Resumed'}: ${watcherLine(w)}',
    );
  }
}

class WatchersDeleteCommand extends KCommand {
  WatchersDeleteCommand(super.ctx) {
    argParser.addFlag(
      'yes',
      negatable: false,
      help: 'Delete without the dry run.',
    );
  }
  @override
  String get name => 'delete';
  @override
  String get description => 'Stop and delete a watcher.';
  @override
  String get invocation => 'casama watchers delete <id> --yes';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Which watcher? Pass its id.', usage);
    }
    final id = rest.single;
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit({
        'would': 'delete watcher $id',
        'confirm': '--yes',
      }, 'This would delete watcher $id.\nRun again with --yes to delete it.');
    }
    final c = await ctx.authedClient();
    await c.watchers.deleteWatcher(id: id);
    return ctx.emit({'id': id, 'deleted': true}, 'Deleted watcher $id.');
  }
}

// Subcommands for the existing `memory` command.

class MemoryEditCommand extends KCommand {
  MemoryEditCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('content', help: 'New text, or @file to read it from a file.')
      ..addFlag(
        'pin',
        negatable: false,
        help: 'Pin it so it is always remembered.',
      )
      ..addFlag('unpin', negatable: false, help: 'Unpin it.');
  }
  @override
  String get name => 'edit';
  @override
  String get description => 'Change a memory\'s text or pin it.';
  @override
  String get invocation =>
      'casama memory edit <bot> <memory id> [--content @file] [--pin|--unpin]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException('Pass the bot and the memory id.', usage);
    }
    final pin = argResults!['pin'] as bool;
    final unpin = argResults!['unpin'] as bool;
    if (pin && unpin) {
      throw UsageException('Use --pin or --unpin, not both.', usage);
    }
    final content = argResults!['content'] as String?;
    if (content == null && !pin && !unpin) {
      throw UsageException(
        'Nothing to change. Pass --content, --pin or --unpin.',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest[0]);
    final m = (await c.memory.updateMemory(
      id: bot.id,
      memoryId: rest[1],
      updateMemoryRequest: UpdateMemoryRequest(
        content: content == null ? null : readTextArg(content),
        pinned: pin ? true : (unpin ? false : null),
      ),
    )).data!;
    return ctx.emit(m.toJson(), 'Updated: ${m.pinned ? '* ' : ''}${m.content}');
  }
}

class MemoryDeleteCommand extends KCommand {
  MemoryDeleteCommand(super.ctx) {
    addOrgOption(this);
    argParser.addFlag(
      'yes',
      negatable: false,
      help: 'Delete without the dry run.',
    );
  }
  @override
  String get name => 'delete';
  @override
  String get description => 'Make a bot forget one memory.';
  @override
  String get invocation => 'casama memory delete <bot> <memory id> --yes';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException('Pass the bot and the memory id.', usage);
    }
    if (!(argResults!['yes'] as bool)) {
      return ctx.emit(
        {'would': 'delete memory ${rest[1]} of ${rest[0]}', 'confirm': '--yes'},
        'This would delete memory ${rest[1]} of ${rest[0]}.\nRun again with --yes to delete it.',
      );
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest[0]);
    await c.memory.deleteMemory(id: bot.id, memoryId: rest[1]);
    return ctx.emit({
      'id': rest[1],
      'deleted': true,
    }, 'Forgot memory ${rest[1]}.');
  }
}

class MemoryImportPromptCommand extends KCommand {
  MemoryImportPromptCommand(super.ctx);
  @override
  String get name => 'import-prompt';
  @override
  String get description =>
      'Print the prompt to paste into another assistant (ChatGPT, Claude) so it lists what it knows about you.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final p = (await c.imports.getMemoryImportPrompt()).data!;
    return ctx.emit(p.toJson(), p.prompt);
  }
}

class MemoryImportCommand extends KCommand {
  MemoryImportCommand(super.ctx) {
    addOrgOption(this);
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Show what would be saved, and save nothing.',
    );
  }
  @override
  String get name => 'import';
  @override
  String get description =>
      'Save memories from the answer another assistant gave to `memory import-prompt`.';
  @override
  String get invocation => 'casama memory import <bot> <file or -> [--dry-run]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException(
        'Pass the bot and a file with the pasted answer (or - for stdin).',
        usage,
      );
    }
    final String text;
    if (rest[1] == '-') {
      final buf = StringBuffer();
      String? line;
      while ((line = stdin.readLineSync()) != null) {
        buf.writeln(line);
      }
      text = buf.toString();
    } else {
      text = readTextArg('@${rest[1]}');
    }
    if (text.trim().isEmpty) {
      throw UsageException('The file is empty.', usage);
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest[0]);
    final parsed = (await c.imports.parseMemoryImport(
      parseMemoryImportRequest: ParseMemoryImportRequest(text: text),
    )).data!;
    final lines = parsed.memories
        .map((m) => '${m.kind.value.padRight(10)} ${m.content}')
        .join('\n');
    if (parsed.memories.isEmpty) {
      return ctx.emit(parsed.toJson(), 'No memories found in that text.');
    }
    if (argResults!['dry-run'] as bool) {
      return ctx.emit(
        parsed.toJson(),
        '${parsed.memories.length} memories found, none saved:\n$lines',
      );
    }
    final saved = (await c.imports.saveImportedMemories(
      id: bot.id,
      saveImportedMemoriesRequest: SaveImportedMemoriesRequest(
        memories: parsed.memories,
      ),
    )).data!;
    return ctx.emit(
      saved.toJson(),
      'Saved ${saved.saved} memories to ${bot.name}.',
    );
  }
}
