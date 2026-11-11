import 'dart:io';

import 'package:casama_cli/casama_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
