import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_sdk/chatgpt_sign_in.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'runner.dart';

/// Resolves --org (slug or id), falling back to the default set with `casama org use`.
Future<OrganizationWithRole> orgFrom(CliContext ctx, CasamaClient c, String? flag) {
  final ref = flag ?? ctx.settings.get('org');
  if (ref == null) {
    throw CliError('org_required', 'Pass --org <slug> or set a default with `casama org use <slug>`.');
  }
  return resolveOrg(c, ref);
}

/// Resolves a bot by id or (case-insensitive) name within an organization.
Future<Bot> botFrom(CasamaClient c, OrganizationWithRole org, String ref) async {
  final bots = (await c.bots.listBots(orgId: org.id)).data!.items;
  for (final b in bots) {
    if (b.id == ref || b.name.toLowerCase() == ref.toLowerCase()) return b;
  }
  throw CliError('bot_not_found', 'No bot "$ref" in ${org.name}. See `casama bot list`.');
}

void addOrgOption(Command<int> cmd) =>
    cmd.argParser.addOption('org', abbr: 'o', help: 'Organization slug or id (default: `casama org use`).');

class OrgUseCommand extends KCommand {
  OrgUseCommand(super.ctx);
  @override
  String get name => 'use';
  @override
  String get description => 'Set the default organization for other commands.';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('One organization slug or id is required.', usage);
    final org = await resolveOrg(await ctx.authedClient(), rest.single);
    ctx.settings.set('org', org.slug);
    return ctx.emit({'org': org.slug}, 'Default organization: ${org.name} (${org.slug}).');
  }
}

// ---------------------------------------------------------------------------
// Model keys
// ---------------------------------------------------------------------------

class CredentialCommand extends Command<int> {
  CredentialCommand(CliContext ctx) {
    addSubcommand(CredentialAddCommand(ctx));
    addSubcommand(CredentialListCommand(ctx));
    addSubcommand(CredentialTestCommand(ctx));
    addSubcommand(CredentialChatGptCommand(ctx));
    addSubcommand(CredentialRemoveCommand(ctx));
  }
  @override
  String get name => 'credential';
  @override
  List<String> get aliases => ['key'];
  @override
  String get description => 'Manage model keys (stored in Vault, never shown again).';
}

class CredentialAddCommand extends KCommand {
  CredentialAddCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('provider', mandatory: true, allowed: ProviderId.values.map((p) => p.value).toList())
      ..addOption('label', defaultsTo: 'Default')
      ..addOption('base-url', help: 'Required for openai_compatible (for example http://localhost:11434/v1).')
      ..addOption('key', help: 'API key (or CASAMA_MODEL_KEY; prompted when omitted).');
  }
  @override
  String get name => 'add';
  @override
  String get description => 'Add a model key.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final provider = ProviderId.values.firstWhere((p) => p.value == argResults!['provider']);
    String? key = argResults!['key'] as String?;
    if (key == null && provider != ProviderId.openaiCompatible) {
      key = readSecret('API key: ', env: 'CASAMA_MODEL_KEY');
    }
    final cred = (await c.credentials.createCredential(
      createCredentialRequest: CreateCredentialRequest(
        orgId: org.id,
        provider: provider,
        label: argResults!['label'] as String,
        apiKey: (key == null || key.isEmpty) ? null : key,
        baseUrl: argResults!['base-url'] as String?,
      ),
    ))
        .data!;
    return ctx.emit(cred.toJson(),
        'Added ${cred.provider.value} key "${cred.label}" (${cred.id})${cred.keyHint == null ? '' : ', ending ${cred.keyHint}'}.');
  }
}

class CredentialListCommand extends KCommand {
  CredentialListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'List model keys (metadata only).';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final list = (await c.credentials.listCredentials(orgId: org.id)).data!;
    final lines = list.items.map((k) {
      final tested = k.lastTestOk == null ? 'untested' : (k.lastTestOk! ? 'ok' : 'failing');
      if (k.provider == ProviderId.chatgpt) {
        return '${k.id}\tchatgpt\t${k.label}\t${k.account ?? ''}\t${k.status.value}';
      }
      return '${k.id}\t${k.provider.value}\t${k.label}\t…${k.keyHint ?? ''}\t$tested';
    }).join('\n');
    return ctx.emit(list.toJson(), lines.isEmpty ? 'No model keys yet. Add one with `casama credential add`.' : lines);
  }
}

class CredentialTestCommand extends KCommand {
  CredentialTestCommand(super.ctx) {
    argParser.addOption('model', help: 'Model to try (a sensible default per provider).');
  }
  @override
  String get name => 'test';
  @override
  String get description => 'Check a key with a 1-token call.';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('The credential id is required.', usage);
    final c = await ctx.authedClient();
    final r = (await c.credentials.testCredential(
      id: rest.single,
      testCredentialRequest: TestCredentialRequest(model: argResults!['model'] as String?),
    ))
        .data!;
    final code = ctx.emit(r.toJson(),
        r.ok ? 'OK: ${r.model} answered in ${r.latencyMs} ms.' : 'Failed with ${r.model}: ${r.error ?? 'unknown error'}');
    return r.ok ? code : 1;
  }
}

/// Opens a URL in the default browser; false when no opener worked.
Future<bool> openInBrowser(Uri url) async {
  final (cmd, args) = Platform.isMacOS
      ? ('open', [url.toString()])
      : Platform.isWindows
          ? ('rundll32', ['url.dll,FileProtocolHandler', url.toString()])
          : ('xdg-open', [url.toString()]);
  try {
    final r = await Process.run(cmd, args);
    return r.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

class CredentialChatGptCommand extends KCommand {
  CredentialChatGptCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('reconnect', help: 'Sign in again for this ChatGPT credential id.')
      ..addFlag('browser', defaultsTo: true, help: 'Open the browser (otherwise only print the link).');
  }
  @override
  String get name => 'chatgpt';
  @override
  String get description =>
      'Connect your ChatGPT plan so your bots run on it instead of an API key (opens your browser).';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final Credential cred;
    try {
      cred = await signInWithChatGpt(
        c.credentials,
        orgId: org.id,
        credentialId: argResults!['reconnect'] as String?,
        openBrowser: (url) async {
          ctx.err.writeln('Continue with ChatGPT in your browser:\n  $url\nWaiting for you to finish…');
          if (argResults!['browser'] as bool) await openInBrowser(url);
        },
      );
    } on ChatGptSignInException catch (e) {
      return ctx.fail(e.code, e.message);
    }
    final note = switch (cred.status) {
      CredentialStatus.ok => 'Bots you start can now use it. Only you can use this plan.',
      CredentialStatus.planUsageOff =>
        'Signed in, but plan usage was not allowed. Run this again and allow it, or add an API key.',
      CredentialStatus.needsReconnect => 'Sign in again with --reconnect ${cred.id}.',
    };
    return ctx.emit(cred.toJson(), 'Connected ChatGPT plan${cred.account == null ? '' : ' (${cred.account})'} as ${cred.id}. $note');
  }
}

class CredentialRemoveCommand extends KCommand {
  CredentialRemoveCommand(super.ctx);
  @override
  String get name => 'remove';
  @override
  String get description => 'Delete a model key (a ChatGPT sign-in is revoked first).';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('The credential id is required.', usage);
    final c = await ctx.authedClient();
    await c.credentials.deleteCredential(id: rest.single);
    return ctx.emit({'deleted': rest.single}, 'Deleted ${rest.single}.');
  }
}

// ---------------------------------------------------------------------------
// Bots
// ---------------------------------------------------------------------------

class BotCommand extends Command<int> {
  BotCommand(CliContext ctx) {
    addSubcommand(BotCreateCommand(ctx));
    addSubcommand(BotListCommand(ctx));
  }
  @override
  String get name => 'bot';
  @override
  String get description => 'Create and list bots.';
}

class BotCreateCommand extends KCommand {
  BotCreateCommand(super.ctx) {
    addOrgOption(this);
    argParser
      ..addOption('credential', abbr: 'k', help: 'Model key id for the bot\'s models.', mandatory: true)
      ..addOption('model', abbr: 'm', help: "Primary model id (default: the server's default for the key's provider, GPT-6 Luna on OpenRouter and OpenAI).")
      ..addMultiOption('fallback', help: 'Fallback model ids, in order (same key).')
      ..addOption('cheap-model', help: 'Model for memory extraction and summaries (default: primary).')
      ..addOption('persona', help: 'Persona text, or @file to read it from a file.')
      ..addOption('autonomy', allowed: Autonomy.values.map((a) => a.value).toList(), defaultsTo: 'ask_risky')
      ..addFlag('private', negatable: false, help: 'Only you can see and use this bot.')
      ..addOption('run-budget', help: 'Max USD per run.')
      ..addOption('daily-budget', help: 'Max USD per day.');
  }
  @override
  String get name => 'create';
  @override
  String get description => 'Create a bot.';
  @override
  String get invocation => 'casama bot create <name> --credential <id> [--model <model>]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('The bot name is required.', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final cred = argResults!['credential'] as String;
    ModelChoice choice(String model) => ModelChoice(credentialId: cred, model: model);
    var persona = argResults!['persona'] as String?;
    if (persona != null && persona.startsWith('@')) persona = File(persona.substring(1)).readAsStringSync();
    final cheap = argResults!['cheap-model'] as String?;
    final fallbacks = argResults!['fallback'] as List<String>;
    double? money(String opt) {
      final v = argResults![opt] as String?;
      if (v == null) return null;
      final d = double.tryParse(v);
      if (d == null || d < 0) throw UsageException('--$opt must be a number of dollars.', usage);
      return d;
    }

    var model = argResults!['model'] as String?;
    if (model == null) {
      final keys = (await c.credentials.listCredentials(orgId: org.id)).data!.items;
      final key = keys.where((k) => k.id == cred).firstOrNull;
      if (key == null) throw UsageException('No model key $cred in this workspace.', usage);
      model = c.config.defaultModels[key.provider.value];
      if (model == null) throw UsageException('No default model for ${key.provider.value} keys; pass --model.', usage);
    }

    final runBudget = money('run-budget');
    final dailyBudget = money('daily-budget');
    final bot = (await c.bots.createBot(
      createBotRequest: CreateBotRequest(
        orgId: org.id,
        name: rest.join(' '),
        personaMd: persona,
        autonomy: Autonomy.values.firstWhere((a) => a.value == argResults!['autonomy']),
        visibility: argResults!['private'] as bool ? Visibility.private : Visibility.team,
        modelPolicy: ModelPolicy(
          primary: choice(model),
          fallbacks: fallbacks.isEmpty ? null : fallbacks.map(choice).toList(),
          cheap: cheap == null ? null : choice(cheap),
        ),
        budget: (runBudget == null && dailyBudget == null) ? null : BotBudget(perRunUsd: runBudget, dailyUsd: dailyBudget),
      ),
    ))
        .data!;
    return ctx.emit(bot.toJson(), 'Created ${bot.name} (${bot.id}). Chat with it: casama chat "${bot.name}"');
  }
}

class BotListCommand extends KCommand {
  BotListCommand(super.ctx) {
    addOrgOption(this);
  }
  @override
  String get name => 'list';
  @override
  String get description => 'List bots you can use.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final list = (await c.bots.listBots(orgId: org.id)).data!;
    final lines = list.items
        .map((b) => '${b.id}\t${b.name}\t${b.status.value}\t${b.modelPolicy.primary?.model ?? '(no model)'}\t${b.visibility.value}')
        .join('\n');
    return ctx.emit(list.toJson(), lines.isEmpty ? 'No bots yet. Create one with `casama bot create`.' : lines);
  }
}

// ---------------------------------------------------------------------------
// Chat and runs
// ---------------------------------------------------------------------------

/// Prints run events: text to stdout, tool steps and status to stderr; JSON lines with --json.
class EventPrinter {
  EventPrinter(this.ctx);
  final CliContext ctx;
  bool _midLine = false;
  double cost = 0;
  int tokens = 0;
  String? failure;
  bool cancelled = false;

  void _status(String s) {
    if (_midLine) {
      ctx.out.writeln();
      _midLine = false;
    }
    ctx.err.writeln(s);
  }

  void handle(RunEventItem e) {
    if (ctx.json) {
      ctx.out.writeln(jsonEncode(e.envelope.toJson()));
      _track(e);
      return;
    }
    switch (e) {
      case MessageDeltaItem(:final event):
        ctx.out.write(event.payload.text);
        _midLine = !event.payload.text.endsWith('\n');
      case ToolStartedItem(:final event):
        final args = jsonEncode(event.payload.argsRedacted);
        _status('  → ${event.payload.tool} ${args.length > 120 ? '${args.substring(0, 117)}...' : args}');
      case ToolCompletedItem(:final event):
        final preview = event.payload.resultPreview.replaceAll('\n', ' ');
        _status('  ✓ ${preview.length > 100 ? '${preview.substring(0, 97)}...' : preview} (${event.payload.durationMs} ms)');
      case ToolFailedItem(:final event):
        _status('  ✗ ${event.payload.errorCode}: ${event.payload.message}');
      case MemoryWrittenItem(:final event):
        _status('  · remembered (${event.payload.kind.value})');
      case SkillLoadedItem(:final event):
        _status('  · loaded skill ${event.payload.name}');
      case RunFailedItem(:final event):
        _status('Run failed: ${event.payload.message} (${event.payload.errorCode})');
      case RunCancelledItem():
        _status('Cancelled.');
      case RunCompletedItem():
        if (_midLine) {
          ctx.out.writeln();
          _midLine = false;
        }
      default:
        break;
    }
    _track(e);
  }

  void _track(RunEventItem e) {
    if (e is UsageItem) {
      cost = e.event.payload.costUsd.toDouble();
      tokens = (e.event.payload.tokensIn + e.event.payload.tokensOut).toInt();
    } else if (e is RunFailedItem) {
      failure = e.event.payload.errorCode;
    } else if (e is RunCancelledItem) {
      cancelled = true;
    }
  }

  void summary() {
    if (!ctx.json && tokens > 0) ctx.err.writeln('  \$${cost.toStringAsFixed(4)} · $tokens tokens');
  }
}

/// Streams a run to the terminal. Ctrl+C cancels the run; a second Ctrl+C exits.
Future<int> streamRun(CliContext ctx, CasamaClient c, String runId, {int afterSeq = 0}) async {
  final printer = EventPrinter(ctx);
  StreamSubscription<ProcessSignal>? sigint;
  var interrupts = 0;
  if (stdin.hasTerminal && !Platform.isWindows) {
    sigint = ProcessSignal.sigint.watch().listen((_) {
      interrupts++;
      if (interrupts == 1) {
        ctx.err.writeln('\nCancelling… (Ctrl+C again to quit)');
        c.runs.cancelRun(id: runId).ignore();
      } else {
        exit(130);
      }
    });
  }
  try {
    await for (final e in watchRun(c, runId, afterSeq: afterSeq)) {
      printer.handle(e);
    }
  } finally {
    await sigint?.cancel();
  }
  printer.summary();
  return printer.failure == null ? 0 : 1;
}

class ChatCommand extends KCommand {
  ChatCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption('conversation', abbr: 'c', help: 'Continue a conversation by id.');
  }
  @override
  String get name => 'chat';
  @override
  String get description => 'Chat with a bot. With a message, sends it and exits; without, starts an interactive chat.';
  @override
  String get invocation => 'casama chat <bot> [message]';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) throw UsageException('Which bot? Pass its name or id.', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest.first);
    var conversationId = argResults!['conversation'] as String?;
    if (conversationId == null) {
      final conv = (await c.chat.createConversation(createConversationRequest: CreateConversationRequest(botId: bot.id))).data!;
      conversationId = conv.id;
      if (!ctx.json) ctx.err.writeln('Conversation $conversationId (continue later with -c $conversationId)');
    }

    Future<int> send(String text) async {
      final sent = (await c.chat.sendMessage(id: conversationId!, sendMessageRequest: SendMessageRequest(text: text))).data!;
      return streamRun(ctx, c, sent.runId);
    }

    final message = rest.skip(1).join(' ').trim();
    if (message.isNotEmpty) return send(message);

    if (!ctx.json) ctx.err.writeln('Chatting with ${bot.name}. Empty line or /exit to quit.');
    var code = 0;
    while (true) {
      if (!ctx.json) stderr.write('you> ');
      final line = stdin.readLineSync()?.trim();
      if (line == null || line.isEmpty || line == '/exit' || line == '/quit') break;
      if (!ctx.json) stderr.write('${bot.name}> ');
      code = await send(line);
    }
    return code;
  }
}

class RunsCommand extends Command<int> {
  RunsCommand(CliContext ctx) {
    addSubcommand(RunsWatchCommand(ctx));
    addSubcommand(RunsCancelCommand(ctx));
  }
  @override
  String get name => 'runs';
  @override
  String get description => 'Watch or cancel runs.';
}

class RunsWatchCommand extends KCommand {
  RunsWatchCommand(super.ctx) {
    argParser.addOption('after', help: 'Only events after this seq.', defaultsTo: '0');
  }
  @override
  String get name => 'watch';
  @override
  String get description => 'Stream a run\'s events until it finishes.';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('The run id is required.', usage);
    final c = await ctx.authedClient();
    return streamRun(ctx, c, rest.single, afterSeq: int.tryParse(argResults!['after'] as String) ?? 0);
  }
}

class RunsCancelCommand extends KCommand {
  RunsCancelCommand(super.ctx);
  @override
  String get name => 'cancel';
  @override
  String get description => 'Cancel a run and its subruns.';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('The run id is required.', usage);
    final c = await ctx.authedClient();
    final run = (await c.runs.cancelRun(id: rest.single)).data!;
    return ctx.emit(run.toJson(), 'Cancellation requested for ${run.id}.');
  }
}

class MemoryCommand extends Command<int> {
  MemoryCommand(CliContext ctx) {
    addSubcommand(MemoryListCommand(ctx));
  }
  @override
  String get name => 'memory';
  @override
  String get description => 'See what a bot remembers.';
}

class MemoryListCommand extends KCommand {
  MemoryListCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption('search', abbr: 's', help: 'Only memories matching these words.');
  }
  @override
  String get name => 'list';
  @override
  String get description => 'List a bot\'s memories, pinned first.';
  @override
  String get invocation => 'casama memory list <bot>';
  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Which bot? Pass its name or id.', usage);
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final bot = await botFrom(c, org, rest.single);
    final list = (await c.memory.listMemories(id: bot.id, q: argResults!['search'] as String?)).data!;
    final lines = list.items.map((m) => '${m.pinned ? '*' : ' '} ${m.kind.value.padRight(10)} ${m.content}').join('\n');
    return ctx.emit(list.toJson(), lines.isEmpty ? '${bot.name} has no memories yet.' : lines);
  }
}

class UsageCommand extends KCommand {
  UsageCommand(super.ctx) {
    addOrgOption(this);
    argParser.addOption('period', allowed: ['day', 'month'], defaultsTo: 'month');
  }
  @override
  String get name => 'usage';
  @override
  String get description => 'Cost and tokens by bot.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final org = await orgFrom(ctx, c, argResults!['org'] as String?);
    final period = argResults!['period'] as String;
    final r = (await c.usage.getUsage(orgId: org.id, period: period)).data!;
    final lines = r.byBot
        .map((b) => '${(b.name ?? '(deleted bot)').padRight(24)} \$${b.costUsd.toStringAsFixed(4)}  ${b.tokensIn} in / ${b.tokensOut} out')
        .join('\n');
    return ctx.emit(r.toJson(), 'Since ${r.since.toIso8601String().substring(0, 10)}: \$${r.totalCostUsd.toStringAsFixed(4)}\n$lines');
  }
}
