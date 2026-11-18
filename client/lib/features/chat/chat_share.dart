import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

/// Overridable in tests: hands an exported chat to the platform (share sheet, save dialog,
/// download).
final saveChatExportProvider =
    Provider<
      Future<void> Function(
        Uint8List bytes,
        String name,
        String mimeType, {
        Rect? origin,
      })
    >(
      (ref) =>
          (bytes, name, mimeType, {origin}) => shareFiles(
            [XFile.fromData(bytes, name: name, mimeType: mimeType)],
            names: [name],
            origin: origin,
          ),
    );

/// What the Share or Export sheet can do.
enum ChatShareAction { markdown, json, link, stop }

/// A file name for an exported chat: its title without characters file systems refuse.
String chatExportFileName(String? title, String ext) {
  final base = (title ?? '')
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final name = base.isEmpty
      ? 'chat'
      : base.substring(0, base.length.clamp(0, 80));
  return '$name.$ext';
}

/// Share or Export (D-282): the chat as a Markdown or JSON file through the platform's share or
/// save flow, or a public read-only link (made, copied and shown; or stopped). [canShare] is false
/// when this person can't make links (only the chat's starter or the bot's managers can), which
/// leaves the export only. The server refuses a link for a private chat (personal device data)
/// and says why.
Future<void> showChatShareSheet(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
  String? title,
  bool canShare = true,
}) async {
  final l10n = context.l10n;
  final origin = shareOrigin(context);
  final picked = await showChoiceSheet<ChatShareAction>(
    context,
    title: l10n.chatShareExport,
    subtitle: l10n.chatShareExportHelp,
    icon: LucideIcons.share2,
    choices: [
      Choice(
        key: const Key('chatExportMarkdown'),
        value: ChatShareAction.markdown,
        label: l10n.chatExportMarkdown,
        subtitle: l10n.chatExportMarkdownHelp,
        icon: LucideIcons.fileText,
      ),
      Choice(
        key: const Key('chatExportJson'),
        value: ChatShareAction.json,
        label: l10n.chatExportJson,
        subtitle: l10n.chatExportJsonHelp,
        icon: LucideIcons.fileCode,
      ),
      if (canShare) ...[
        Choice(
          key: const Key('chatShareLink'),
          value: ChatShareAction.link,
          label: l10n.chatShareLink,
          subtitle: l10n.chatShareLinkHelp,
          icon: LucideIcons.link,
        ),
        Choice(
          key: const Key('chatStopSharing'),
          value: ChatShareAction.stop,
          label: l10n.chatStopSharing,
          subtitle: l10n.chatStopSharingHelp,
          icon: LucideIcons.unlink,
          destructive: true,
        ),
      ],
    ],
  );
  if (picked == null || !context.mounted) return;
  switch (picked.value) {
    case ChatShareAction.markdown || ChatShareAction.json:
      final json = picked.value == ChatShareAction.json;
      final format = json ? 'json' : 'markdown';
      final bytes = await runGuarded(
        context,
        () => ref
            .read(backendProvider)
            .exportConversation(conversationId, format: format),
      );
      if (bytes == null || !context.mounted) return;
      await runGuarded(
        context,
        () => ref.read(saveChatExportProvider)(
          bytes,
          chatExportFileName(title, json ? 'json' : 'md'),
          json ? 'application/json' : 'text/markdown',
          origin: origin,
        ),
      );
    case ChatShareAction.link:
      final ok = await showConfirm(
        context: context,
        title: l10n.chatMakePublicTitle,
        message: l10n.chatMakePublicBody,
        confirmLabel: l10n.chatMakePublic,
        icon: LucideIcons.globe,
        confirmKey: const Key('confirmChatLink'),
      );
      if (!ok || !context.mounted) return;
      final url = await runGuarded(
        context,
        () => ref
            .read(backendProvider)
            .shareConversation(conversationId, public: true),
      );
      if (url == null || !context.mounted) return;
      unawaited(
        Clipboard.setData(ClipboardData(text: url)).catchError((Object _) {}),
      );
      await showAdaptiveSheet<void>(
        context: context,
        builder: (sheet) => FormSheet(
          icon: LucideIcons.globe,
          title: l10n.chatLinkTitle,
          subtitle: l10n.chatLinkBody,
          submitLabel: l10n.close,
          showCancel: false,
          onSubmit: () => Navigator.pop(sheet),
          children: [
            SelectableText(url, key: const Key('chatPublicUrl')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('copyChatLink'),
                  icon: const Icon(LucideIcons.copy, size: 18),
                  label: Text(l10n.copyLink),
                  onPressed: () {
                    unawaited(
                      Clipboard.setData(ClipboardData(text: url))
                          .catchError((Object _) {}),
                    );
                    showSuccess(sheet, l10n.copied);
                  },
                ),
                Builder(
                  builder: (b) => OutlinedButton.icon(
                    key: const Key('shareChatLink'),
                    icon: const Icon(LucideIcons.share, size: 18),
                    label: Text(l10n.shareLinkLabel),
                    onPressed: () => shareText(url, origin: shareOrigin(b)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    case ChatShareAction.stop:
      final done = await runGuarded(context, () async {
        await ref
            .read(backendProvider)
            .shareConversation(conversationId, public: false);
        return true;
      });
      if (done == true && context.mounted) {
        showSuccess(context, l10n.chatSharingStopped);
      }
  }
}
