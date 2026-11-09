# kasama_sdk

Dart SDK for [Kasama](https://github.com/stackwares/kasama), the open-source, self-hostable home for AI bots with their own computers.

- Typed client for the whole Kasama API (generated from its OpenAPI document, `kasama_api`)
- Sign in with email and password (Supabase Auth behind your Kasama server)
- Live run events: `watchRun` streams a run's events in order, with catch-up after reconnects

```dart
import 'package:kasama_sdk/kasama_sdk.dart';

final client = await KasamaClient.connect('https://kasama.example.com');
await client.signIn('you@example.com', 'password');
final sent = (await client.chat.sendMessage(
  id: conversationId,
  sendMessageRequest: SendMessageRequest(text: 'Summarize today'),
)).data!;
await for (final e in watchRun(client, sent.runId)) {
  if (e is MessageDeltaItem) print(e.event.payload.text);
}
```

See `example/example.dart`, and `examples/sdk_sample` in the repository for a complete app.
