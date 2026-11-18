import 'dart:io';

import 'package:casama_cli/casama_cli.dart';

Future<void> main(List<String> args) async {
  final code = await runCli(args);
  // Leave as soon as the command is done, like Dart's own tools: a timer or idle connection left
  // in a library (the run stream's receive timeout) kept `casama chat` open for two minutes after
  // the reply. Every command awaits its own work, child processes included, before returning.
  await Future.wait([stdout.flush(), stderr.flush()]);
  exit(code);
}
