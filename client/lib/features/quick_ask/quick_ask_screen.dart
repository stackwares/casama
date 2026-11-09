import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/mobile_extras.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Quick ask (global shortcut, share-to-bot target): pick a bot, type, send; opens the chat.
class QuickAskScreen extends ConsumerStatefulWidget {
  const QuickAskScreen({super.key, this.initialText = '', this.fromShareExtension = false});
  final String initialText;
  /// Opened by the iOS share extension: the shared text waits in the App Group.
  final bool fromShareExtension;

  @override
  ConsumerState<QuickAskScreen> createState() => _QuickAskScreenState();
}

class _QuickAskScreenState extends ConsumerState<QuickAskScreen> {
  late final _text = TextEditingController(text: widget.initialText);
  String? _botId;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.fromShareExtension) {
      takeSharedText().then((t) {
        if (mounted && t.isNotEmpty) _text.text = t;
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final bot = _botId;
    if (bot == null || _text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final conv = await runGuarded(context, () async {
      final c = await backend.createConversation(bot);
      await backend.send(c.id, _text.text.trim());
      return c;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (conv != null) context.go('/bots/$bot/chat?c=${conv.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    _botId ??= bots.isEmpty ? null : bots.first.id;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickAsk)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            key: const Key('quickAskBot'),
            initialValue: _botId,
            decoration: InputDecoration(labelText: l10n.bot),
            items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
            onChanged: (v) => setState(() => _botId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('quickAskText'),
            controller: _text,
            autofocus: true,
            minLines: 3,
            maxLines: 10,
            decoration: InputDecoration(hintText: l10n.quickAskHint),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('quickAskSend'),
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.send),
            label: Text(l10n.send),
          ),
        ]),
      ),
    );
  }
}
