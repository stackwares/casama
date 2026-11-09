import 'dart:io';

import 'package:kasama_computerd/computerd.dart';

Future<void> main() async {
  final config = ComputerdConfig.fromEnvironment(Platform.environment);
  final server = Computerd(config);
  await server.start();
  stdout.writeln('computerd listening on ${config.address}:${server.port}');
  for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
    signal.watch().listen((_) async {
      await server.stop();
      exit(0);
    });
  }
}
