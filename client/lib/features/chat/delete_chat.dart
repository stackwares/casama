import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../groups/group_chats.dart';

/// Asks, then deletes one chat with its messages, photos and files. The confirmation says what
/// stays: usage records, and whatever the bot remembered from it. True when it was deleted.
Future<bool> confirmDeleteChat(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
  required String botId,
  required String botName,
}) async {
  final l10n = context.l10n;
  final ok = await showConfirm(
    context: context,
    title: l10n.deleteChatTitle,
    message: l10n.deleteChatBody(botName),
    confirmLabel: l10n.deleteChat,
    destructive: true,
    icon: LucideIcons.trash2,
    confirmKey: const Key('confirmDeleteChat'),
  );
  if (!ok || !context.mounted) return false;
  final done = await runGuarded(context, () async {
    await ref.read(backendProvider).deleteConversation(conversationId);
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
