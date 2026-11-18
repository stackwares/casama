import 'dart:io';

import 'package:args/args.dart';
import 'package:casama_sdk/casama_sdk.dart';

/// A minimal external app: signs up (or in), makes a workspace, adds a model key, creates a bot
/// and streams one run live from the Casama API.
///   dart run bin/sample.dart --api http://localhost:8787 --email you@example.com --password ... \
///     --key "$OPENROUTER_API_KEY" --message "Say hello"
Future<void> main(List<String> argv) async {
  final p = ArgParser()
    ..addOption('api', defaultsTo: 'http://localhost:8787')
    ..addOption('email', mandatory: true)
    ..addOption('password', mandatory: true)
    ..addOption('key', help: 'An OpenRouter key (any value works against a fixture worker)', mandatory: true)
    ..addOption('model', help: "Default: the server's default for OpenRouter keys")
    ..addOption('message', defaultsTo: 'Hello from an external app!');
  final a = p.parse(argv);

  final client = await CasamaClient.connect(a['api'] as String);
  final email = a['email'] as String;
  final password = a['password'] as String;
  try {
    await client.signIn(email, password);
  } on AuthException {
    await client.signUp(email, password);
    await client.signIn(email, password);
  }

  final org = (await client.workspaces.createOrg(createOrganizationRequest: CreateOrganizationRequest(name: 'SDK sample'))).data!;
  final key = (await client.credentials.createCredential(
    createCredentialRequest: CreateCredentialRequest(orgId: org.id, provider: ProviderId.openrouter, label: 'sample', apiKey: a['key'] as String),
  ))
      .data!;
  final model = (a['model'] as String?) ?? client.config.defaultModels['openrouter']!;
  final bot = (await client.bots.createBot(
    createBotRequest: CreateBotRequest(
      orgId: org.id,
      name: 'Sample bot',
      modelPolicy: ModelPolicy(primary: ModelChoice(credentialId: key.id, model: model)),
    ),
  ))
      .data!;
  final conv = (await client.chat.createConversation(createConversationRequest: CreateConversationRequest(botId: bot.id))).data!;
  final sent = (await client.chat.sendMessage(id: conv.id, sendMessageRequest: SendMessageRequest(text: a['message'] as String))).data!;
  stdout.writeln('run ${sent.runId} (model $model)');

  final started = DateTime.now();
  await for (final e in watchRun(client, sent.runId)) {
    switch (e) {
      case MessageDeltaItem(:final event):
        stdout.write(event.payload.text);
      case ToolStartedItem(:final event):
        stdout.writeln('\n[tool] ${event.payload.tool}');
      case RunCompletedItem():
        stdout.writeln('\nrun completed in ${DateTime.now().difference(started).inMilliseconds} ms');
        exit(0);
      case RunFailedItem(:final event):
        stderr.writeln('\nrun failed: ${event.payload.message}');
        exit(1);
      default:
    }
  }
}
