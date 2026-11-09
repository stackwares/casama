import 'dart:io';

import 'package:kasama_cli/kasama_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
