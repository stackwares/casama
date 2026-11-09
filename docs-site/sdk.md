# Dart SDK

[`kasama_sdk`](https://pub.dev/packages/kasama_sdk) wraps the typed API client with auth and live
run event streams, for Dart and Flutter apps.

```dart
final kasama = await KasamaClient.connect('https://kasama.example.com');
await kasama.signIn('you@example.com', 'password');
final orgs = (await kasama.workspaces.listOrgs()).data!.items;
final bots = (await kasama.bots.listBots(orgId: orgs.first.id)).data!.items;
final conv = await kasama.chat.createConversation(...);
await for (final event in kasama.runEvents(runId)) {
  if (event is MessageDelta) stdout.write(event.text);
}
```

See `examples/sdk_sample` in the repository for a complete app.
