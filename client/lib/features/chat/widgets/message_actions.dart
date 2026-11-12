import 'package:flutter/foundation.dart';
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
/// Touch: long-press opens a menu. Mouse: text selects by dragging and right-click adds these to
/// the text menu.
class MessageActions extends StatelessWidget {
  const MessageActions({super.key, required this.text, required this.child, this.markdown = false, this.onSpeak, this.speakKey, this.onEdit});
  final String text;
  final Widget child;

  /// Edit and resend (your own messages; D-108).
  final VoidCallback? onEdit;

  /// Show the text as Markdown in "Select text".
  final bool markdown;
  final VoidCallback? onSpeak;
  final Key? speakKey;

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
      return SelectionArea(
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
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (d) => _menu(context, d.globalPosition),
      child: child,
    );
  }
}
