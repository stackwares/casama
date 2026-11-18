// Stands in for the Neko streamer in tests: answers /health on NEKO_SERVER_BIND and appends one
// line to the file named in its first argument, with its process id and the relays it was given.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = int.parse(
    (Platform.environment['NEKO_SERVER_BIND'] ?? ':0').split(':').last,
  );
  final server = await HttpServer.bind('127.0.0.1', port);
  final started = {
    'pid': pid,
    'ice': jsonDecode(
      Platform.environment['NEKO_WEBRTC_ICESERVERS_BACKEND'] ?? '[]',
    ),
  };
  File(args.first).writeAsStringSync(
    '${jsonEncode(started)}\n',
    mode: FileMode.append,
    flush: true,
  );
  await for (final req in server) {
    req.response.statusCode = 200;
    await req.response.close();
  }
}
