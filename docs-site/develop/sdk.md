# Dart SDK

`casama_sdk` is the Dart and Flutter library for Casama. It gives you a typed client for the whole
[HTTP API](/develop/api), sign-in with automatic token refresh, and `watchRun`, which streams a
bot's run live and recovers from dropped connections. The [CLI](/develop/cli) is built on it.

The typed client comes from a separate package, `casama_api`, generated from the API's OpenAPI
document. `casama_sdk` re-exports it, so one import gives you everything.

## Install

```yaml
# pubspec.yaml
dependencies:
  casama_sdk: ^0.8.0
```

```sh
dart pub get
```

It needs Dart 3.13 or later. Keep the SDK's version in step with your server's `api_version`
(from `GET /v1/config`): the client is generated from that server version's routes.

::: details Using a clone of the repository instead
To build against unreleased changes, point both packages at a clone with
`dependency_overrides`, as the sample app does:

```yaml
dependency_overrides:
  casama_sdk:
    path: ../casama/dart/casama_sdk
  casama_api:
    path: ../casama/dart/casama_api
```
:::

## Connect and sign in

```dart
import 'package:casama_sdk/casama_sdk.dart';

Future<void> main() async {
  final casama = await CasamaClient.connect('https://casama.example.com');
  await casama.signIn('ana@example.com', 'correct-horse-battery');
  final me = (await casama.workspaces.getMe()).data!;
  print('Signed in as ${me.email}');
}
```

`CasamaClient.connect` loads the server's [public configuration](/develop/api#public-configuration)
(`casama.config`), which says where to sign in. After that, every API call carries your access
token, and the client refreshes it a minute before it expires.

| Member | What it does |
| --- | --- |
| `CasamaClient.connect(url, {sessions, config})` | Connect to a server. Pass `config` if you already have it to save a request. |
| `signIn(email, password)` | Sign in with email and password; returns an `AuthSession` |
| `signUp(email, password)` | Create an account. Returns `null` when the server sends a confirmation email first. Adds a sign-up proof when the server asks for one. |
| `signOut()` | Forget the session |
| `currentSession()` | The session, refreshed if it's about to expire, or `null` |
| `config` | The server's `PublicConfig`: `productName`, `apiVersion`, `defaultModels`, `billingEnabled`, ... |
| `auth` | The lower-level `AuthClient`: magic-link codes (`sendMagicLink`, `verifyEmailOtp`), two-step sign-in (`verifiedTotpFactors`, `verifyTotp`), `refresh` |
| `api` | The generated `CasamaApi`, and `api.dio` for raw requests |

### Keep the session

By default the session lives in memory, so your program signs in each time it starts. Pass a
`SessionStore` to keep it:

```dart
class FileStore implements SessionStore {
  FileStore(this.file);
  final File file;

  @override
  Future<AuthSession?> load() async => file.existsSync()
      ? AuthSession.fromAuthResponse(jsonDecode(file.readAsStringSync()))
      : null;

  @override
  Future<void> save(AuthSession s) async => file.writeAsStringSync(jsonEncode(s.toJson()));

  @override
  Future<void> clear() async {
    if (file.existsSync()) file.deleteSync();
  }
}

final casama = await CasamaClient.connect(url, sessions: FileStore(File('session.json')));
```

The SDK also has `MemorySessionStore` (the default) and `CallbackSessionStore`, which reads the
session from another auth library. A Flutter app that already uses `supabase_flutter` can hand its
session over this way and let that library refresh it.

## Workspaces and bots

The client has one property per API area, named after the reference's tags: `workspaces`, `bots`,
`chat`, `runs`, `credentials`, `approvals`, `memory`, `routines`, `skills`, `computers`,
`integrations`, `usage` and more. Each method returns a Dio `Response`; the parsed body is in
`.data`.

```dart
final orgs = (await casama.workspaces.listOrgs()).data!.items;
final org = orgs.firstWhere((o) => o.slug == 'acme');

final bots = (await casama.bots.listBots(orgId: org.id)).data!.items;
for (final b in bots) {
  print('${b.name}: ${b.status.value}');
}
```

Create a bot with a model key:

```dart
final key = (await casama.credentials.createCredential(
  createCredentialRequest: CreateCredentialRequest(
    orgId: org.id,
    provider: ProviderId.openrouter,
    label: 'Main',
    apiKey: openRouterKey,
  ),
)).data!;

final bot = (await casama.bots.createBot(
  createBotRequest: CreateBotRequest(
    orgId: org.id,
    name: 'Invoicer',
    personaMd: 'You chase unpaid invoices politely.',
    modelPolicy: ModelPolicy(
      primary: ModelChoice(
        credentialId: key.id,
        model: casama.config.defaultModels['openrouter']!,
      ),
    ),
  ),
)).data!;
```

## Send a message and stream the run

```dart
final conversation = (await casama.chat.createConversation(
  createConversationRequest: CreateConversationRequest(botId: bot.id),
)).data!;

final sent = (await casama.chat.sendMessage(
  id: conversation.id,
  sendMessageRequest: SendMessageRequest(text: 'Which invoices are overdue?'),
)).data!;

await for (final e in watchRun(casama, sent.runId)) {
  switch (e) {
    case MessageDeltaItem(:final event):
      stdout.write(event.payload.text);
    case ToolStartedItem(:final event):
      print('\n[tool] ${event.payload.tool}');
    case RunFailedItem(:final event):
      print('\nFailed: ${event.payload.message} (${event.payload.errorCode})');
    case RunCompletedItem():
      print('');
    default:
      break;
  }
}
```

### `watchRun`

```dart
Stream<RunEventItem> watchRun(CasamaClient client, String runId, {int afterSeq = 0, int maxRetries = 8})
```

- **Catch-up first.** It asks for events after `afterSeq`, so you get everything that already
  happened, then live events as they come.
- **In order, once.** Events arrive strictly by `seq`, with duplicates dropped.
- **Reconnects.** If the connection drops, it reconnects with backoff (250 ms, doubling up to 8
  seconds) and resumes after the last event it delivered. After `maxRetries` failures in a row, the
  stream ends with the error. Client errors (4xx, apart from 408 and 429) end it at once.
- **Ends with the run.** The stream closes after `run.completed`, `run.failed` or `run.cancelled`.

To resume watching later, for example after your program restarts, pass the last `seq` you
processed as `afterSeq`.

### Run event types

Each event is a `RunEventItem`, a sealed class with one subclass per event type, so `switch` can
check you've handled them. Every item has `seq`, `type`, `runId`, the raw `envelope` and, for known
types, a typed `event` whose `payload` has the fields.

| Class | Event type |
| --- | --- |
| `RunStartedItem` | `run.started` |
| `MessageDeltaItem`, `MessageCompletedItem` | `message.delta`, `message.completed` |
| `ToolStartedItem`, `ToolOutputItem`, `ToolCompletedItem`, `ToolFailedItem` | `tool.*` |
| `ApprovalRequestedItem`, `ApprovalResolvedItem` | `approval.*` |
| `UsageItem` | `usage` |
| `NoticeItem` | `notice` |
| `RunCompletedItem`, `RunFailedItem`, `RunCancelledItem` | `run.completed`, `run.failed`, `run.cancelled` |
| `UnknownRunEventItem` | A type this SDK version doesn't know |

There are classes for the other types too (`SecretRequestedItem`, `SubrunStartedItem`,
`MemoryWrittenItem`, `UiShownItem`, ...). A newer server can send types an older SDK doesn't know;
they arrive as `UnknownRunEventItem` instead of breaking your app. The
[HTTP API page](/develop/api#event-types) describes each type.

### Your own event source

`RunEventBuffer` is the ordering logic behind `watchRun`: feed it events from any source (a
Realtime subscription, a page from `GET /v1/runs/{id}/events`) and it releases them in `seq` order
with duplicates dropped. `hasGap` tells you when an event is missing and you should fetch the gap.

```dart
final buffer = RunEventBuffer(lastSeq: 0);
for (final e in buffer.add(incoming)) {
  render(e);
}
```

## Approvals

When the bot needs a person to approve a step, you get an `ApprovalRequestedItem`. Approve or deny
it, and the run carries on:

```dart
await for (final e in watchRun(casama, runId)) {
  if (e is ApprovalRequestedItem) {
    final p = e.event.payload;
    final ok = await askUser('Allow ${p.tool} (${p.risk.value} risk)?');
    await casama.approvals.decideApproval(
      id: p.approvalId,
      approvalDecisionRequest: ApprovalDecisionRequest(
        decision: ok
            ? ApprovalDecisionRequestDecisionEnum.approved
            : ApprovalDecisionRequestDecisionEnum.denied,
      ),
    );
  }
}
```

Set `alwaysAllow: true` to stop asking about that tool for that bot. Denying fails only that step.
`casama.approvals.listApprovals(orgId: org.id, status: 'pending')` lists everything waiting. See
[Autonomy and approvals](/guide/autonomy).

## Cancel a run

```dart
await casama.runs.cancelRun(id: runId);
```

The run stops within about two seconds and `watchRun` ends with a `RunCancelledItem`.

## Errors

API calls throw Dio's `DioException`. `problemOf` turns it into the API's
[problem details](/develop/api#errors), with a stable `code`:

```dart
try {
  await casama.runs.cancelRun(id: runId);
} on DioException catch (e) {
  final problem = problemOf(e);
  if (problem?.code == 'run_finished') {
    print('Already done.');
  } else if (problem != null) {
    print('${problem.code}: ${problem.detail ?? problem.title}');
    for (final field in problem.errors ?? const []) {
      print('  ${field.path}: ${field.message}');
    }
  } else {
    rethrow; // a network error, not an API answer
  }
}
```

Sign-in failures throw `AuthException`, with the auth server's `message` and `statusCode`.

## Other helpers

| Method | What it does |
| --- | --- |
| `uploadComputerFile(computerId, path, bytes)` | Upload a file to a bot's computer |
| `downloadComputerFile(computerId, path)` | Download a file as bytes |
| `terminalEndpoint(computerId, {cols, rows})` | The WebSocket URL and headers for an interactive terminal |
| `transcribe(botId, audio, {mime, language})` | Turn a voice recording into text with the workspace's speech-to-text key |

The `package:casama_sdk/chatgpt_sign_in.dart` library has `signInWithChatGpt`, which connects a
ChatGPT plan through the browser, as `casama credential chatgpt` does.

## The sample app

[`examples/sdk_sample`](https://github.com/stackwares/casama/tree/main/examples/sdk_sample) is a
small external program that depends on `casama_sdk` the way your app would. It signs up (or in),
creates a workspace, adds an OpenRouter key, creates a bot, sends one message and streams the run:

```sh
cd examples/sdk_sample
dart pub get
dart run bin/sample.dart --api https://casama.example.com \
  --email ana@example.com --password correct-horse-battery \
  --key "$OPENROUTER_API_KEY" --message "Say hello"
```

The package also has a shorter example in `dart/casama_sdk/example/example.dart`: send a message to
an existing conversation and print the reply.

## Related

- [HTTP API](/develop/api): authentication, errors and the event protocol
- [API reference](/api/): every endpoint, which maps one to one to the client's methods
- [CLI](/develop/cli): built on this SDK
- [Autonomy and approvals](/guide/autonomy)
