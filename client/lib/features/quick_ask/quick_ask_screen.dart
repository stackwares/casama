import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/mobile_extras.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';
import '../../ui/glow_button.dart';

/// Quick ask (global shortcut, share-to-bot target): pick a bot, type, send; opens the chat.
class QuickAskScreen extends ConsumerStatefulWidget {
  const QuickAskScreen({super.key, this.initialText = '', this.fromShareExtension = false, this.initialBotId});
  final String initialText;

  /// Picked by a shortcut ("Ask a bot", D-111).
  final String? initialBotId;

  /// Opened by the iOS share extension: the shared text waits in the App Group.
  final bool fromShareExtension;

  @override
  ConsumerState<QuickAskScreen> createState() => _QuickAskScreenState();
}

class _QuickAskScreenState extends ConsumerState<QuickAskScreen> {
  late final _text = TextEditingController(text: widget.initialText);
  late String? _botId = widget.initialBotId;
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
    final scheme = context.colorScheme;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    if (_botId != null && bots.isNotEmpty && !bots.any((b) => b.id == _botId)) _botId = null;
    _botId ??= bots.isEmpty ? null : bots.first.id;
    final ready = _botId != null && _text.text.trim().isNotEmpty;
    return SubPage(
      title: l10n.quickAsk,
      children: [
        Text(l10n.quickAskIntro, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
        const SizedBox(height: AppSpace.lg),
        if (bots.length > 1) ...[
          SizedBox(
            height: 44,
            child: ListView.separated(
              key: const Key('quickAskBot'),
              scrollDirection: Axis.horizontal,
              itemCount: bots.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
              itemBuilder: (context, i) {
                final b = bots[i];
                return ChoiceChip(
                  selected: b.id == _botId,
                  showCheckmark: false,
                  avatar: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 22),
                  label: Text(b.name),
                  onSelected: (_) => setState(() => _botId = b.id),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        TextField(
          key: const Key('quickAskText'),
          controller: _text,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: bots.length == 1 ? l10n.quickAskHintBot(bots.single.name) : l10n.quickAskHint, alignLabelWithHint: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.lg),
        SizedBox(
          height: 50,
          child: GlowButton.icon(
            key: const Key('quickAskSend'),
            onPressed: _busy || !ready ? null : _send,
            icon: _busy
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.onPrimary))
                : const Icon(LucideIcons.arrowUp, size: 20),
            label: Text(l10n.send),
          ),
        ),
      ],
    );
  }
}
