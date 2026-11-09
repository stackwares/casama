import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Which Kasama server the app talks to (D-076): the build's default, a self-hosted address the
/// user entered, or (for the web app served by a self-hosted stack) the page's own origin.
class ServerAddress {
  static const _key = 'kasama.server_url';

  static Future<AppConfig> load({AppConfig fallback = AppConfig.fromEnvironment}) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      final saved = prefs.getString(_key);
      if (saved != null && saved.isNotEmpty) return AppConfig(apiUrl: saved);
    } catch (_) {}
    if (kIsWeb && fallback.apiUrl.isEmpty) return AppConfig(apiUrl: Uri.base.origin);
    return fallback;
  }

  static Future<void> save(String url) async =>
      (await SharedPreferences.getInstance()).setString(_key, normalize(url));

  static Future<void> clear() async => (await SharedPreferences.getInstance()).remove(_key);

  /// "kasama.example.com" -> "https://kasama.example.com"; strips trailing slashes.
  static String normalize(String input) {
    var s = input.trim().replaceAll(RegExp(r'/+$'), '');
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      final local = s.startsWith('localhost') || s.startsWith('127.') || s.startsWith('10.') || s.startsWith('192.168.');
      s = '${local ? 'http' : 'https'}://$s';
    }
    return s;
  }
}

/// Set by the startup gate: reconnects the app to another server.
Future<void> Function(String url)? onChangeServer;

/// Asks for a server address and switches to it.
Future<void> changeServerDialog(
  BuildContext context,
  String current, {
  required String title,
  required String label,
  required String cancel,
  required String connect,
}) async {
  final url = await showDialog<String>(
    context: context,
    builder: (_) => _ServerDialog(current: current, title: title, label: label, cancel: cancel, connect: connect),
  );
  if (url == null || url.trim().isEmpty) return;
  await onChangeServer?.call(ServerAddress.normalize(url));
}

class _ServerDialog extends StatefulWidget {
  const _ServerDialog({required this.current, required this.title, required this.label, required this.cancel, required this.connect});
  final String current, title, label, cancel, connect;
  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  late final _c = TextEditingController(text: widget.current);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          key: const Key('serverUrl'),
          controller: _c,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: widget.label, hintText: 'https://kasama.example.com'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.cancel)),
          FilledButton(key: const Key('serverConnect'), onPressed: () => Navigator.pop(context, _c.text), child: Text(widget.connect)),
        ],
      );
}
