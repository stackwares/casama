import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ui/adaptive_modal.dart';
import '../ui/form_sheet.dart';

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

  static Future<void> save(String url) async => (await SharedPreferences.getInstance()).setString(_key, normalize(url));

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
  String? help,
}) async {
  final url = await showAdaptiveSheet<String>(
    context: context,
    builder: (_) => _ServerForm(current: current, title: title, label: label, cancel: cancel, connect: connect, help: help),
  );
  if (url == null || url.trim().isEmpty) return;
  await onChangeServer?.call(ServerAddress.normalize(url));
}

class _ServerForm extends StatefulWidget {
  const _ServerForm({required this.current, required this.title, required this.label, required this.cancel, required this.connect, this.help});
  final String current, title, label, cancel, connect;
  final String? help;
  @override
  State<_ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<_ServerForm> {
  late final _c = TextEditingController(text: widget.current);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    icon: Icons.dns_outlined,
    title: widget.title,
    subtitle: widget.help,
    submitLabel: widget.connect,
    submitIcon: Icons.link_rounded,
    submitKey: const Key('serverConnect'),
    cancelLabel: widget.cancel,
    onSubmit: () => Navigator.pop(context, _c.text),
    children: [
      TextField(
        key: const Key('serverUrl'),
        controller: _c,
        autofocus: true,
        autocorrect: false,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(labelText: widget.label, hintText: 'https://kasama.example.com', prefixIcon: const Icon(Icons.public_rounded, size: 20)),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
    ],
  );
}
