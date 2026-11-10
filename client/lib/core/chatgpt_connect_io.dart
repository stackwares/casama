import 'dart:io';

import 'package:kasama_sdk/chatgpt_sign_in.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

/// Desktop apps listen on 127.0.0.1 for OpenAI's redirect; phones can't keep a listener alive
/// while the browser is in front, so they use the desktop app or the CLI.
bool get chatGptLoopbackSupported => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<Credential> connectChatGptLoopback(
  CredentialsApi api, {
  required String orgId,
  required Future<void> Function(Uri url) openBrowser,
  String? credentialId,
}) =>
    signInWithChatGpt(api, orgId: orgId, credentialId: credentialId, openBrowser: openBrowser);
