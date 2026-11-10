import 'package:kasama_sdk/kasama_sdk.dart';

/// Web: no loopback listener, so sign-in happens in the desktop app or the CLI.
bool get chatGptLoopbackSupported => false;

Future<Credential> connectChatGptLoopback(
  CredentialsApi api, {
  required String orgId,
  required Future<void> Function(Uri url) openBrowser,
  String? credentialId,
}) =>
    throw UnsupportedError('ChatGPT sign-in runs in the desktop app or the CLI.');
