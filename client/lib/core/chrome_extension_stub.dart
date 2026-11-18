/// Casama for Chrome only exists in a browser: elsewhere there is nothing to send to.
Future<Map<String, Object?>?> sendToChromeExtension(
  String id,
  Map<String, Object?> message,
) async => null;
