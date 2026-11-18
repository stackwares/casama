import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart';

import 'commands_bots.dart' show addOrgOption, botFrom, orgFrom, streamRun;
import 'runner.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Text of an option that may be `@path` (read from a file).
String textOrFile(String value) {
  if (!value.startsWith('@')) return value;
  final f = File(value.substring(1));
  if (!f.existsSync()) {
    throw CliError('file_not_found', 'No file ${f.path}.');
  }
  return f.readAsStringSync();
}

/// The text parts of a message's `content` joined, like the app shows it.
String messageText(Object? content) {
  if (content is String) return content;
  if (content is! List) return '';
  return content
      .whereType<Map>()
      .where((p) => p['type'] == 'text')
      .map((p) => '${p['text'] ?? ''}')
      .join();
}

/// A thread row as readable text: `who  time`, then the text indented, then its id.
String threadMessageText(Map<String, Object?> row) {
  final role = '${row['role'] ?? ''}';
  final who = switch (role) {
    'user' => 'you',
    'assistant' => 'bot',
    _ => role,
  };
  final at = '${row['created_at'] ?? ''}';
  final time = at.length >= 16
      ? '${at.substring(0, 10)} ${at.substring(11, 16)}'
      : at;
  final text = messageText(row['content']).trimRight();
  final body = text.isEmpty
      ? '  (no text)'
      : text.split('\n').map((l) => '  $l').join('\n');
  return '$who  $time  (${row['id']})\n$body';
}

/// Prints [dryRun] and returns 0 unless --yes was given (then returns null: go ahead).
int? needYes(CliContext ctx, Command<int> cmd, String would) {
  if (cmd.argResults!['yes'] as bool) return null;
  return ctx.emit({
    'would': would,
    'confirm': '--yes',
  }, 'Would $would.\nRun again with --yes to do it.');
}

void _addYes(Command<int> cmd) => cmd.argParser.addFlag(
  'yes',
  abbr: 'y',
  negatable: false,
  help: 'Do it. Without this, only say what would happen.',
);

String _one(Command<int> cmd, String what) {
  final rest = cmd.argResults!.rest;
  if (rest.length != 1) throw UsageException(what, cmd.usage);
  return rest.single;
}

/// Writes [text] to --out, or prints it. Returns the exit code.
int _writeOut(CliContext ctx, Command<int> cmd, String text, String what) {
  final out = cmd.argResults!['out'] as String?;
  if (out == null) {
    ctx.out.writeln(text);
    return 0;
  }
  File(out).writeAsStringSync(text.endsWith('\n') ? text : '$text\n');
  return ctx.emit({'file': out}, 'Wrote $what to $out.');
}

// ---------------------------------------------------------------------------
// casama chats
// ---------------------------------------------------------------------------

/// Chats: `casama chats list|show|export|rename|branch|share|delete|clear|message-delete|message-edit`.
class ChatsCommand extends Command<int> {
  ChatsCommand(CliContext ctx) {
    addSubcommand(ChatsListCommand(ctx));
    addSubcommand(ChatsShowCommand(ctx));
    addSubcommand(ChatsExportCommand(ctx));
    addSubcommand(ChatsRenameCommand(ctx));
    addSubcommand(ChatsBranchCommand(ctx));
    addSubcommand(ChatsShareCommand(ctx));
    addSubcommand(ChatsDeleteCommand(ctx));
    addSubcommand(ChatsClearCommand(ctx));
    addSubcommand(ChatsMessageDeleteCommand(ctx));
    addSubcommand(ChatsMessageEditCommand(ctx));
  }
  @override
  String get name => 'chats';
  @override
  String get description =>
      'Conversations with your bots: read, export, share, delete.';
}

String _conversationLine(Conversation c) {
  final when =
      c.lastMessageAt
          ?.toIso8601String()
          .substring(0, 16)
          .replaceFirst('T', ' ') ??
      '-';
  return '${c.id}  $when  ${c.pinned == true ? '*' : ' '} ${c.title ?? '(untitled)'}';
}

class ChatsListCommand extends KCommand {
  ChatsListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'A bot\'s conversations, newest first.';
  @override
  String get invocation => 'casama chats list <bot>';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    final items = (await c.chat.listConversations(id: bot.id)).data!.items;
    return ctx.emit(
      [for (final x in items) x.toJson()],
      items.isEmpty
          ? '${bot.name} has no conversations. Start one with `casama chat "${bot.name}"`.'
          : items.map(_conversationLine).join('\n'),
    );
  }
}

class ChatsShowCommand extends KCommand {
  ChatsShowCommand(super.ctx) {
    argParser.addOption(
      'limit',
      abbr: 'n',
      help: 'Only the latest N messages.',
    );
  }
  @override
  String get name => 'show';
  @override
  String get description =>
      'Print a conversation: who, when and what was said.';
  @override
  String get invocation => 'casama chats show <conversation id>';
  @override
  Future<int> run() async {
    final id = _one(
      this,
      'Which conversation? Pass its id (see `casama chats list`).',
    );
    final limitText = argResults!['limit'] as String?;
    final limit = limitText == null ? null : int.tryParse(limitText);
    if (limitText != null && (limit == null || limit < 1)) {
      throw UsageException('--limit must be a whole number above 0.', usage);
    }
    final c = await ctx.authedClient();
    final thread = (await c.chat.getConversationThread(
      id: id,
      limit: limit,
    )).data!;
    final rows = thread.items
        .where((r) => r['role'] == 'user' || r['role'] == 'assistant')
        .toList();
    return ctx.emit(
      thread.toJson(),
      rows.isEmpty
          ? 'No messages yet.'
          : rows.map(threadMessageText).join('\n\n'),
    );
  }
}

class ChatsExportCommand extends KCommand {
  ChatsExportCommand(super.ctx) {
    argParser
      ..addOption('out', help: 'Write to this file instead of printing.')
      ..addOption(
        'format',
        allowed: ['markdown', 'json'],
        defaultsTo: 'markdown',
      );
  }
  @override
  String get name => 'export';
  @override
  String get description => 'Download a conversation as Markdown or JSON.';
  @override
  String get invocation => 'casama chats export <conversation id> [--out file]';
  @override
  Future<int> run() async {
    final id = _one(this, 'Which conversation? Pass its id.');
    final c = await ctx.authedClient();
    final res = await c.api.dio.get<String>(
      '/v1/conversations/$id/export',
      queryParameters: {'format': argResults!['format']},
      options: Options(
        responseType: ResponseType.plain,
        extra: {
          'secure': [
            {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
          ],
        },
      ),
    );
    return _writeOut(ctx, this, res.data ?? '', 'the conversation');
  }
}

class ChatsRenameCommand extends KCommand {
  ChatsRenameCommand(super.ctx);
  @override
  String get name => 'rename';
  @override
  String get description => 'Give a conversation a new title.';
  @override
  String get invocation => 'casama chats rename <conversation id> <title>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      throw UsageException(
        'Pass the conversation id and the new title.',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final conv = (await c.chat.updateConversation(
      id: rest.first,
      updateConversationRequest: UpdateConversationRequest(
        title: rest.skip(1).join(' '),
      ),
    )).data!;
    return ctx.emit(conv.toJson(), 'Renamed to "${conv.title}".');
  }
}

class ChatsBranchCommand extends KCommand {
  ChatsBranchCommand(super.ctx) {
    argParser.addOption(
      'from',
      help: 'A message id on the branch to show (or pass it after the conversation id).',
    );
  }
  @override
  String get name => 'branch';
  @override
  String get description =>
      'Switch a conversation to the branch that holds a message (made by editing a message).';
  @override
  String get invocation =>
      'casama chats branch <conversation id> --from <message id>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final message =
        argResults!['from'] as String? ?? (rest.length == 2 ? rest[1] : null);
    if (rest.isEmpty || rest.length > 2 || message == null) {
      throw UsageException(
        'Pass the conversation id and a message id: casama chats branch <conversation id> --from <message id>',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final r = (await c.chat.switchBranch(
      id: rest.first,
      switchBranchRequest: SwitchBranchRequest(messageId: message),
    )).data!;
    return ctx.emit(
      r.toJson(),
      'Showing the branch that ends at ${r.headMessageId}.',
    );
  }
}

class ChatsShareCommand extends KCommand {
  ChatsShareCommand(super.ctx) {
    argParser.addFlag(
      'stop',
      negatable: false,
      help: 'Stop sharing: the link stops working.',
    );
  }
  @override
  String get name => 'share';
  @override
  String get description => 'Make a public read-only link to a conversation.';
  @override
  String get invocation => 'casama chats share <conversation id> [--stop]';
  @override
  Future<int> run() async {
    final id = _one(this, 'Which conversation? Pass its id.');
    final stop = argResults!['stop'] as bool;
    final c = await ctx.authedClient();
    final r = (await c.chat.shareConversation(
      id: id,
      shareConversationRequest: ShareConversationRequest(public: !stop),
    )).data!;
    return ctx.emit(
      r.toJson(),
      stop ? 'Sharing stopped.' : (r.url ?? 'No link was made.'),
    );
  }
}

class ChatsDeleteCommand extends KCommand {
  ChatsDeleteCommand(super.ctx) {
    _addYes(this);
  }
  @override
  String get name => 'delete';
  @override
  String get description => 'Delete a conversation.';
  @override
  String get invocation => 'casama chats delete <conversation id> --yes';
  @override
  Future<int> run() async {
    final id = _one(this, 'Which conversation? Pass its id.');
    final held = needYes(ctx, this, 'delete conversation $id and its messages');
    if (held != null) return held;
    final c = await ctx.authedClient();
    final r = (await c.chat.deleteConversation(id: id)).data!;
    return ctx.emit(r.toJson(), 'Deleted ${r.deleted}.');
  }
}

class ChatsClearCommand extends KCommand {
  ChatsClearCommand(super.ctx) {
    addOrgOption(this);
    _addYes(this);
  }
  @override
  String get name => 'clear';
  @override
  String get description => 'Delete all of a bot\'s conversations.';
  @override
  String get invocation => 'casama chats clear <bot> --yes';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    final held = needYes(
      ctx,
      this,
      'delete every conversation with ${bot.name}',
    );
    if (held != null) return held;
    final r = (await c.chat.deleteBotConversations(id: bot.id)).data!;
    return ctx.emit(
      r.toJson(),
      'Deleted ${r.deleted} conversation${r.deleted == 1 ? '' : 's'}${r.skipped == 0 ? '' : '; left ${r.skipped} the bot is still working in'}.',
    );
  }
}

class ChatsMessageDeleteCommand extends KCommand {
  ChatsMessageDeleteCommand(super.ctx) {
    _addYes(this);
  }
  @override
  String get name => 'message-delete';
  @override
  String get description => 'Delete one message from a conversation.';
  @override
  String get invocation =>
      'casama chats message-delete <conversation id> <message id> --yes';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      throw UsageException(
        'Pass the conversation id and the message id.',
        usage,
      );
    }
    final held = needYes(
      ctx,
      this,
      'delete message ${rest[1]} from conversation ${rest[0]}',
    );
    if (held != null) return held;
    final c = await ctx.authedClient();
    final r = (await c.chat.deleteMessage(
      id: rest[0],
      messageId: rest[1],
    )).data!;
    return ctx.emit(r.toJson(), 'Deleted ${r.deleted}.');
  }
}

class ChatsMessageEditCommand extends KCommand {
  ChatsMessageEditCommand(super.ctx);
  @override
  String get name => 'message-edit';
  @override
  String get description =>
      'Edit a sent message. The conversation forks there and the bot answers again.';
  @override
  String get invocation =>
      'casama chats message-edit <conversation id> <message id> <text | @file>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 3) {
      throw UsageException(
        'Pass the conversation id, the message id and the new text.',
        usage,
      );
    }
    final text = textOrFile(rest.skip(2).join(' '));
    final c = await ctx.authedClient();
    final r = (await c.chat.editMessage(
      id: rest[0],
      messageId: rest[1],
      editMessageRequest: EditMessageRequest(text: text),
    )).data!;
    if (r.runId.isEmpty) return ctx.emit(r.toJson(), 'Edited.');
    return streamRun(ctx, c, r.runId);
  }
}

// ---------------------------------------------------------------------------
// Extra `casama bot` subcommands (registered in BotCommand by the runner).
// The API has no bot get/update/delete route (the app writes the bots table
// directly), so show reads the bot list; edit and delete are not offered.
// ---------------------------------------------------------------------------

String botDetailsText(Bot b) {
  final p = b.modelPolicy;
  String model(ModelChoice? m) => m == null ? '-' : m.model;
  final budget = b.budget;
  String usd(num? v) => v == null ? 'no limit' : '\$${v.toStringAsFixed(2)}';
  final persona = b.personaMd.trim();
  return [
    '${b.name}  (${b.id})',
    'Status:      ${b.status.value}',
    'Visibility:  ${b.visibility.value}',
    'Autonomy:    ${b.autonomy.value}',
    'Model:       ${model(p.primary)}',
    if (p.fallbacks != null && p.fallbacks!.isNotEmpty)
      'Fallbacks:   ${p.fallbacks!.map(model).join(', ')}',
    if (p.cheap != null) 'Cheap model:  ${model(p.cheap)}',
    'Budget:      ${usd(budget.perRunUsd)} per run, ${usd(budget.dailyUsd)} per day',
    if (persona.isNotEmpty)
      'Persona:\n${persona.split('\n').map((l) => '  $l').join('\n')}',
  ].join('\n');
}

class BotShowCommand extends KCommand {
  BotShowCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'show';
  @override
  String get description =>
      'A bot\'s model, autonomy, budget, visibility and persona.';
  @override
  String get invocation => 'casama bot show <bot>';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    return ctx.emit(bot.toJson(), botDetailsText(bot));
  }
}

class BotExportCommand extends KCommand {
  BotExportCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('out', help: 'Write to this file instead of printing.')
      ..addFlag(
        'memories',
        negatable: false,
        help: 'Include what the bot remembers.',
      );
  }
  @override
  String get name => 'export';
  @override
  String get description =>
      'A bot as a shareable file (no keys; memories only with --memories).';
  @override
  String get invocation => 'casama bot export <bot> [--out file]';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    final t = (await c.bots.exportBot(
      id: bot.id,
      memories: (argResults!['memories'] as bool) ? 'true' : null,
    )).data!;
    return _writeOut(
      ctx,
      this,
      const JsonEncoder.withIndent('  ').convert(t.toJson()),
      bot.name,
    );
  }
}

class BotImportCommand extends KCommand {
  BotImportCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption(
        'credential',
        abbr: 'k',
        mandatory: true,
        help: 'Model key id for the new bot.',
      )
      ..addOption(
        'model',
        abbr: 'm',
        help: 'Model id (default: the server\'s default for the key\'s provider).',
      )
      ..addFlag('memories', defaultsTo: true, help: 'Bring its memories.')
      ..addFlag('routines', defaultsTo: true, help: 'Bring its routines.');
  }
  @override
  String get name => 'import';
  @override
  String get description =>
      'Create a bot from a file made by `casama bot export`.';
  @override
  String get invocation => 'casama bot import <file> --credential <id>';
  @override
  Future<int> run() async {
    final path = _one(this, 'Which file? Pass the path of a bot file.');
    final file = File(path);
    if (!file.existsSync()) throw CliError('file_not_found', 'No file $path.');
    final BotTemplateFile template;
    try {
      template = BotTemplateFile.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    } on Object {
      throw CliError('bad_bot_file', '$path is not a Casama bot file.');
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final cred = argResults!['credential'] as String;
    var model = argResults!['model'] as String?;
    if (model == null) {
      final keys = (await c.credentials.listCredentials(orgId: org.id))
          .data!
          .items;
      final key = keys.where((k) => k.id == cred).firstOrNull;
      if (key == null) {
        throw UsageException('No model key $cred in this workspace.', usage);
      }
      model = c.config.defaultModels[key.provider.value];
      if (model == null) {
        final listed =
            (await c.credentials.listCredentialModels(id: cred)).data?.items ??
            const [];
        model = listed.firstOrNull?.id;
      }
      if (model == null) {
        throw UsageException(
          'No default model for ${key.provider.value} keys; pass --model.',
          usage,
        );
      }
    }
    final r = (await c.bots.importBot(
      importBotRequest: ImportBotRequest(
        orgId: org.id,
        template: template,
        credentialId: cred,
        model: model,
        includeMemories: argResults!['memories'] as bool,
        includeRoutines: argResults!['routines'] as bool,
      ),
    )).data!;
    final todo = r.connectionsToAdd;
    return ctx.emit(
      r.toJson(),
      'Created bot ${r.botId}: ${r.skills} skills, ${r.routines} routines, ${r.memories} memories.'
      '${todo.isEmpty ? '' : '\nConnect these in the app: ${todo.map((t) => t.name).join(', ')}'}',
    );
  }
}

class BotShareCommand extends KCommand {
  BotShareCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addFlag(
        'memories',
        negatable: false,
        help: 'Include what the bot remembers.',
      )
      ..addOption(
        'expires-in-days',
        help: 'Days until the link stops working, 1 to 365 (default 30).',
      );
  }
  @override
  String get name => 'share';
  @override
  String get description =>
      'Make a link that lets someone else add a copy of this bot.';
  @override
  String get invocation =>
      'casama bot share <bot> [--memories] [--expires-in-days 30]';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final daysText = argResults!['expires-in-days'] as String?;
    final days = daysText == null ? null : int.tryParse(daysText);
    if (daysText != null && (days == null || days < 1 || days > 365)) {
      throw UsageException(
        '--expires-in-days must be a number from 1 to 365.',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    final r = (await c.bots.createBotShare(
      id: bot.id,
      createBotShareRequest: CreateBotShareRequest(
        includeMemories: argResults!['memories'] as bool,
        expiresInDays: days,
      ),
    )).data!;
    return ctx.emit(
      r.toJson(),
      '${r.url}${r.expiresAt == null ? '' : '\nExpires ${r.expiresAt!.toIso8601String().substring(0, 10)}.'}',
    );
  }
}

/// Check-ins text: `on`/`off`, the brief time, scan interval and daily cap.
String checkinsText(BotCheckins k) =>
    'Check-ins ${k.enabled ? 'on' : 'off'}: brief at ${k.briefTime}, scan every ${k.scanEveryHours} h, up to \$${k.dailyCapUsd.toStringAsFixed(2)} a day.';

final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

class BotCheckinsCommand extends KCommand {
  BotCheckinsCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addFlag('on', negatable: false, help: 'Turn check-ins on.')
      ..addFlag('off', negatable: false, help: 'Turn check-ins off.')
      ..addOption('brief-time', help: 'Local time for the daily brief, HH:MM.')
      ..addOption('every', help: 'Scan every N hours (1 to 24).')
      ..addOption(
        'daily-cap',
        help: 'Most USD to spend on check-ins per day (up to 100).',
      );
  }
  @override
  String get name => 'checkins';
  @override
  String get description =>
      'Show a bot\'s proactive check-ins; change them with flags.';
  @override
  String get invocation =>
      'casama bot checkins <bot> [--on|--off] [--brief-time 08:00] [--every 4] [--daily-cap 1]';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final on = argResults!['on'] as bool;
    final off = argResults!['off'] as bool;
    if (on && off) throw UsageException('Pass --on or --off, not both.', usage);
    final time = argResults!['brief-time'] as String?;
    if (time != null && !_hhmm.hasMatch(time)) {
      throw UsageException('--brief-time must look like 08:30.', usage);
    }
    final everyText = argResults!['every'] as String?;
    final every = everyText == null ? null : int.tryParse(everyText);
    if (everyText != null && (every == null || every < 1 || every > 24)) {
      throw UsageException(
        '--every must be a number of hours from 1 to 24.',
        usage,
      );
    }
    final capText = argResults!['daily-cap'] as String?;
    final cap = capText == null ? null : double.tryParse(capText);
    if (capText != null && (cap == null || cap <= 0 || cap > 100)) {
      throw UsageException(
        '--daily-cap must be dollars above 0, up to 100.',
        usage,
      );
    }
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    var k = (await c.checkins.getBotCheckins(id: bot.id)).data!;
    if (!on && !off && time == null && every == null && cap == null) {
      return ctx.emit(k.toJson(), checkinsText(k));
    }
    k = (await c.checkins.setBotCheckins(
      id: bot.id,
      botCheckins: BotCheckins(
        enabled: on ? true : (off ? false : k.enabled),
        briefTime: time ?? k.briefTime,
        scanEveryHours: every ?? k.scanEveryHours,
        dailyCapUsd: cap ?? k.dailyCapUsd,
      ),
    )).data!;
    return ctx.emit(k.toJson(), 'Saved. ${checkinsText(k)}');
  }
}

class BotStartersCommand extends KCommand {
  BotStartersCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'starters';
  @override
  String get description =>
      'The suggested first messages for a bot\'s empty chat.';
  @override
  String get invocation => 'casama bot starters <bot>';
  @override
  Future<int> run() async {
    final ref = _one(this, 'Which bot? Pass its name or id.');
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, ref);
    final r = (await c.bots.getBotStarters(id: bot.id)).data!;
    return ctx.emit(
      r.toJson(),
      r.items.isEmpty
          ? 'No starters yet.${r.refreshing ? ' New ones are being written; ask again in a few seconds.' : ''}'
          : r.items.map((s) => '${s.emoji} ${s.text}').join('\n'),
    );
  }
}
