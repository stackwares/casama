import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/backend.dart';
import '../../core/mobile_extras.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/edge_fade.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/page.dart';
import '../../ui/glow_button.dart';
import '../chat/chat_screen.dart' show computerForBot;
import '../desktop/desktop_context.dart';
import '../../core/analytics.dart';

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
  // Desktop context from the hotkey (D-152): each part can be left out before sending.
  DesktopContext? _ctx;
  var _withSelection = true, _withWindow = true, _withTab = true;
  Uint8List? _shot;

  @override
  void initState() {
    super.initState();
    _ctx = ref.read(pendingDesktopContextProvider);
    if (_ctx != null) WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(pendingDesktopContextProvider.notifier).set(null));
    if (widget.fromShareExtension) {
      Analytics.feature('share_extension');
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
    if (bot == null || (_text.text.trim().isEmpty && !(_ctx?.selection != null && _withSelection))) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final ctx = _ctx;
    final block = ctx == null ? '' : formatDesktopContext(ctx, selection: _withSelection, window: _withWindow, tab: _withTab);
    final text = block.isEmpty ? _text.text.trim() : '${_text.text.trim()}\n\n$block';
    final conv = await runGuarded(context, () async {
      final c = await backend.createConversation(bot);
      final attachments = <AttachmentRef>[];
      final shot = _shot;
      if (shot != null) {
        // The screenshot goes to the bot's computer, like a file attached in chat.
        final b = ref.read(botsProvider).value?.where((x) => x.id == bot).firstOrNull;
        final computer = computerForBot(ref.read(computersProvider).value ?? const [], bot, defaultComputerId: b?.defaultComputerId);
        if (computer != null) {
          final path = 'uploads/screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
          await backend.uploadFile(computer.id, path, shot);
          attachments.add(AttachmentRef(path: 'workspace/$path', name: 'screenshot.png', mimeType: 'image/png', size: shot.length));
        }
      }
      await backend.send(c.id, text, attachments: attachments);
      return c;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (conv != null) context.go('/bots/$bot/chat?c=${conv.id}');
  }

  /// Takes a screenshot of the screen (only when asked): Casama's window steps aside first.
  Future<void> _screenshot() async {
    setState(() => _busy = true);
    final w = desktopContextSupported ? WindowManager.instance.getCurrent() : null;
    w?.hide();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final shot = await ref.read(desktopContextReaderProvider).screenshot().catchError((_) => null);
    w?.show();
    w?.focus();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _shot = shot;
    });
    if (shot == null) showFailure(context, context.l10n.ctxScreenshotFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    if (_botId != null && bots.isNotEmpty && !bots.any((b) => b.id == _botId)) _botId = null;
    _botId ??= bots.isEmpty ? null : bots.first.id;
    final ready = _botId != null && (_text.text.trim().isNotEmpty || (_ctx?.selection != null && _withSelection));
    return SubPage(
      title: l10n.quickAsk,
      children: [
        Text(l10n.quickAskIntro, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
        const SizedBox(height: AppSpace.lg),
        if (bots.length > 1) ...[
          PageBleed(child: SizedBox(
            height: 44,
            child: EdgeFade(child: ListView.separated(
              key: const Key('quickAskBot'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              itemCount: bots.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
              itemBuilder: (context, i) {
                final b = bots[i];
                return RevealWhenSelected(selected: b.id == _botId, child: ChoiceChip(
                  selected: b.id == _botId,
                  showCheckmark: false,
                  avatar: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 22),
                  label: Text(b.name),
                  onSelected: (_) => setState(() => _botId = b.id),
                ));
              },
            )),
          )),
          const SizedBox(height: AppSpace.md),
        ],
        if (_ctx != null || desktopContextSupported) ...[
          Wrap(
            key: const Key('quickAskContext'),
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              if (_ctx?.selection != null)
                FilterChip(key: const Key('ctxSelection'), selected: _withSelection, avatar: const Icon(LucideIcons.textSelect, size: 16), label: Text(l10n.ctxSelection), onSelected: (v) => setState(() => _withSelection = v)),
              if (_ctx?.app != null || _ctx?.window != null)
                FilterChip(
                  key: const Key('ctxWindow'),
                  selected: _withWindow,
                  avatar: const Icon(LucideIcons.appWindow, size: 16),
                  label: Text(_ctx!.window ?? _ctx!.app!, overflow: TextOverflow.ellipsis),
                  onSelected: (v) => setState(() => _withWindow = v),
                ),
              if (_ctx?.url != null)
                FilterChip(key: const Key('ctxTab'), selected: _withTab, avatar: const Icon(LucideIcons.globe, size: 16), label: Text(_ctx!.tabTitle ?? _ctx!.url!, overflow: TextOverflow.ellipsis), onSelected: (v) => setState(() => _withTab = v)),
              if (desktopContextSupported)
                _shot == null
                    ? ActionChip(key: const Key('ctxScreenshot'), avatar: const Icon(LucideIcons.screenShare, size: 16), label: Text(l10n.ctxAddScreenshot), onPressed: _busy ? null : _screenshot)
                    : InputChip(key: const Key('ctxScreenshotTaken'), avatar: const Icon(LucideIcons.image, size: 16), label: Text(l10n.ctxScreenshotAdded), onDeleted: () => setState(() => _shot = null)),
            ],
          ),
          if (_ctx?.selection != null && _withSelection)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(_ctx!.selection!, maxLines: 4, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
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
