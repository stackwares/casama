import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../groups/group_chats.dart';

/// How many things were made in a chat (the Library, D-274); 0 when unknown.
Future<int> _madeIn(WidgetRef ref, String botId, String conversationId) async {
  final orgId = ref.read(botProvider(botId))?.orgId ?? ref.read(currentOrgIdProvider);
  if (orgId == null) return 0;
  try {
    return (await ref.read(backendProvider).creations(orgId, conversationId: conversationId, limit: 100)).items.length;
  } catch (_) {
    return 0;
  }
}

/// Asks, then deletes one chat with its messages. The confirmation says what stays: what was made
/// there (the Library, D-274), usage records, and whatever the bot remembered from it. When things
/// were made there, a switch (off by default) deletes them too. True when it was deleted.
Future<bool> confirmDeleteChat(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
  required String botId,
  required String botName,
}) async {
  final l10n = context.l10n;
  final made = await _madeIn(ref, botId, conversationId);
  if (!context.mounted) return false;
  var alsoMade = false;
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    dialogMaxWidth: 460,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => FormSheet(
        icon: LucideIcons.trash2,
        title: l10n.deleteChatTitle,
        subtitle: l10n.deleteChatBody(botName),
        submitLabel: l10n.deleteChat,
        submitKey: const Key('confirmDeleteChat'),
        destructive: true,
        onSubmit: () {
          HapticsHelper.heavy();
          Navigator.pop(c, true);
        },
        children: [
          if (made > 0)
            CheckboxListTile(
              key: const Key('deleteChatCreations'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: alsoMade,
              title: Text(l10n.deleteChatAlsoCreations(made)),
              subtitle: Text(l10n.deleteChatAlsoCreationsHelp),
              onChanged: (v) => setState(() => alsoMade = v ?? false),
            ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return false;
  final done = await runGuarded(context, () async {
    await ref.read(backendProvider).deleteConversation(conversationId, withCreations: alsoMade);
    return true;
  });
  if (done != true) return false;
  ref
    ..invalidate(conversationsProvider(botId))
    ..invalidate(groupChatsProvider);
  if (context.mounted) showSuccess(context, l10n.chatDeleted);
  return true;
}

/// Asks, then deletes every chat with a bot this person may delete (all of them for a manager).
/// Chats the bot is still working in are kept, and the message says so.
Future<bool> confirmDeleteAllChats(
  BuildContext context,
  WidgetRef ref, {
  required String botId,
  required String botName,
}) async {
  final l10n = context.l10n;
  final ok = await showConfirm(
    context: context,
    title: l10n.deleteAllChatsTitle(botName),
    message: l10n.deleteAllChatsBody(botName),
    confirmLabel: l10n.deleteAllChats,
    destructive: true,
    icon: LucideIcons.trash2,
    confirmKey: const Key('confirmDeleteAllChats'),
  );
  if (!ok || !context.mounted) return false;
  final r = await runGuarded(
    context,
    () => ref.read(backendProvider).deleteBotConversations(botId),
  );
  if (r == null) return false;
  ref.invalidate(conversationsProvider(botId));
  if (!context.mounted) return true;
  final (deleted, skipped) = r;
  if (skipped > 0) {
    showWarning(context, '${l10n.chatsDeleted(deleted)} ${l10n.chatsKeptBusy(skipped)}');
  } else {
    showSuccess(context, l10n.chatsDeleted(deleted));
  }
  return true;
}
