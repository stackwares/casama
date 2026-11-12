import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/share.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/bottom_padding.dart';
import '../../../ui/adaptive_modal.dart';
import 'chat_markdown.dart';

bool get _pointerFirst =>
    kIsWeb || const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

/// Copy, read aloud, select and share for one message, without buttons under every bubble.
/// Touch: holding a bubble shrinks it a little as the long-press builds, then opens a menu.
/// Mouse: hovering shows a row of buttons under the message (its space is kept, so nothing moves),
/// text selects by dragging, and right-click adds the same actions to the text menu.
class MessageActions extends StatefulWidget {
  const MessageActions({super.key, required this.text, required this.child, this.markdown = false, this.onSpeak, this.speakKey, this.onEdit, this.alignEnd = false});
  final String text;
  final Widget child;

  /// Edit and resend (your own messages; D-108).
  final VoidCallback? onEdit;

  /// Show the text as Markdown in "Select text".
  final bool markdown;
  final VoidCallback? onSpeak;
  final Key? speakKey;

  /// Your messages sit on the right, so their hover buttons line up on the right too.
  final bool alignEnd;

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions> with SingleTickerProviderStateMixin {
  var _hover = false;

  /// 0 to 1 while a finger holds the bubble, reaching 1 as the long-press fires.
  late final _hold = AnimationController(vsync: this, duration: kLongPressTimeout);

  String get text => widget.text;
  bool get markdown => widget.markdown;
  VoidCallback? get onEdit => widget.onEdit;
  VoidCallback? get onSpeak => widget.onSpeak;
  Key? get speakKey => widget.speakKey;
  Widget get child => widget.child;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (context.mounted) showMessage(context, context.l10n.messageCopied);
  }

  void _select(BuildContext context) {
    showAdaptiveSheet<void>(
      context: context,
      heightFactor: 0.7,
      contentPadsBottom: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.l10n.selectText, style: sheet.textTheme.titleLarge),
          const SizedBox(height: AppSpace.md),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: BottomPadding.of(sheet, minimum: AppSpace.lg)),
              child: markdown ? ChatMarkdown(data: text) : SelectableText(text, style: sheet.textTheme.bodyLarge?.copyWith(height: 1.5)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _menu(BuildContext context, Offset at) async {
    unfocusBeforeModal();
    HapticFeedback.mediumImpact();
    final l10n = context.l10n;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final origin = shareOrigin(context);
    PopupMenuItem<String> item(String value, IconData icon, String label, {Key? key}) => PopupMenuItem(
          key: key,
          value: value,
          child: Row(children: [Icon(icon, size: 18), const SizedBox(width: AppSpace.sm), Text(label)]),
        );
    final picked = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      position: RelativeRect.fromRect(at & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        item('copy', LucideIcons.copy, l10n.copyMessage, key: const Key('msgCopy')),
        if (onEdit != null) item('edit', LucideIcons.pencil, l10n.editMessage, key: const Key('msgEdit')),
        if (onSpeak != null) item('speak', LucideIcons.volume2, l10n.readAloud, key: speakKey),
        item('select', LucideIcons.textCursorInput, l10n.selectText, key: const Key('msgSelect')),
        item('share', LucideIcons.share, l10n.shareMessage, key: const Key('msgShare')),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'copy':
        await _copy(context);
      case 'speak':
        onSpeak?.call();
      case 'edit':
        onEdit?.call();
      case 'select':
        _select(context);
      case 'share':
        await shareText(text, origin: origin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_pointerFirst) {
      final selectable = SelectionArea(
        contextMenuBuilder: (menuContext, state) => AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ...state.contextMenuButtonItems,
            ContextMenuButtonItem(
              label: l10n.copyMessage,
              onPressed: () {
                ContextMenuController.removeAny();
                _copy(context);
              },
            ),
            if (onEdit != null)
              ContextMenuButtonItem(
                label: l10n.editMessage,
                onPressed: () {
                  ContextMenuController.removeAny();
                  onEdit!();
                },
              ),
            if (onSpeak != null)
              ContextMenuButtonItem(
                label: l10n.readAloud,
                onPressed: () {
                  ContextMenuController.removeAny();
                  onSpeak!();
                },
              ),
            ContextMenuButtonItem(
              label: l10n.shareMessage,
              onPressed: () {
                ContextMenuController.removeAny();
                shareText(text, origin: shareOrigin(context));
              },
            ),
          ],
        ),
        child: child,
      );
      return MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [selectable, _hoverBar(context)],
        ),
      );
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // The bubble starts shrinking once a finger rests on it, and springs back if it lifts or
      // scrolls away before the menu opens.
      onLongPressDown: reduceMotion ? null : (_) => _hold.forward(from: 0),
      onLongPressCancel: () => _hold.reverse(),
      onLongPressStart: (d) {
        _hold.reverse();
        _menu(context, d.globalPosition);
      },
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, child) => Transform.scale(scale: 1 - 0.04 * Curves.easeOut.transform(_hold.value), child: child),
        child: child,
      ),
    );
  }

  /// Copy, Edit, Read aloud and Share under the message, shown while the mouse is over it. The row
  /// keeps its space when hidden, so messages never shift as the mouse moves.
  Widget _hoverBar(BuildContext context) {
    final l10n = context.l10n;
    final color = context.colorScheme.onSurfaceVariant;
    Widget button(IconData icon, String tooltip, VoidCallback onPressed, {Key? key}) => IconButton(
          key: key,
          tooltip: tooltip,
          iconSize: 16,
          // A 34 pt target each with a gap between, so neighbours aren't hit by mistake.
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          color: color,
          onPressed: onPressed,
          icon: Icon(icon),
        );
    return IgnorePointer(
      ignoring: !_hover,
      child: AnimatedOpacity(
        opacity: _hover ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            key: const Key('messageHoverBar'),
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.xxs,
            children: [
              button(LucideIcons.copy, l10n.copyMessage, () => _copy(context), key: const Key('hoverCopy')),
              if (onEdit != null) button(LucideIcons.pencil, l10n.editMessage, onEdit!, key: const Key('hoverEdit')),
              if (onSpeak != null) button(LucideIcons.volume2, l10n.readAloud, onSpeak!, key: const Key('hoverSpeak')),
              button(LucideIcons.share, l10n.shareMessage, () => shareText(text, origin: shareOrigin(context)), key: const Key('hoverShare')),
            ],
          ),
        ),
      ),
    );
  }
}
