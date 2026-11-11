# casama_sdk

Dart SDK for [Casama](https://github.com/stackwares/casama), the open-source, self-hostable home for AI bots with their own computers.

- Typed client for the whole Casama API (generated from its OpenAPI document, `casama_api`)
- Sign in with email and password (Supabase Auth behind your Casama server)
- Live run events: `watchRun` streams a run's events in order, with catch-up after reconnects

```dart
import 'package:casama_sdk/casama_sdk.dart';

final client = await CasamaClient.connect('https://casama.example.com');
await client.signIn('you@example.com', 'password');
final sent = (await client.chat.sendMessage(
  id: conversationId,
  sendMessageRequest: SendMessageRequest(text: 'Summarize today'),
)).data!;
await for (final e in watchRun(client, sent.runId)) {
  if (e is MessageDeltaItem) print(e.event.payload.text);
}
```

See `example/example.dart`, `examples/sdk_sample` in the repository for a complete app, and the
[SDK guide](https://github.com/stackwares/casama/blob/main/docs-site/develop/sdk.md).
