import 'dart:io';

import 'package:casama_sdk/casama_sdk.dart';

/// Sends one message to a bot and prints the reply as it streams.
/// `dart run example/example.dart <api-url> <email> <password> <conversation-id> "message"`
Future<void> main(List<String> args) async {
  if (args.length < 5) {
    stderr.writeln('usage: example.dart <api-url> <email> <password> <conversation-id> <message>');
    exit(64);
  }
  final client = await CasamaClient.connect(args[0]);
  await client.signIn(args[1], args[2]);
  final sent = (await client.chat.sendMessage(id: args[3], sendMessageRequest: SendMessageRequest(text: args[4]))).data!;
  await for (final e in watchRun(client, sent.runId)) {
    if (e is MessageDeltaItem) stdout.write(e.event.payload.text);
    if (e is RunCompletedItem || e is RunFailedItem) break;
  }
  stdout.writeln();
}
