import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../chat/widgets/chat_time.dart';
import 'bot_email.dart';
import '../../core/number_format.dart';
import 'channels_screen.dart';

/// Kept mail, newest first; [verdict] narrows to strangers when set.
final mailMessagesProvider =
    FutureProvider.autoDispose.family<MailMessageList, ({String botId, String? verdict})>(
  (ref, q) => ref.watch(backendProvider).mailMessages(q.botId, verdict: q.verdict),
);

final _mailDetailProvider =
    FutureProvider.autoDispose.family<MailMessageDetail, ({String botId, String id})>(
  (ref, q) => ref.watch(backendProvider).mailMessage(q.botId, q.id),
);

/// A bot's kept inbox (BOT-EMAIL-PLAN Phase 2): threads, strangers with Allow and Block, the
/// sender check flag, and files.
class MailScreen extends ConsumerStatefulWidget {
  const MailScreen({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends ConsumerState<MailScreen> {
  String? _verdict;
  final List<MailMessage> _extra = [];
  String? _nextCursor;
  bool _loadingMore = false;
  bool _cursorLoaded = false;

  /// Selecting several threads to delete (BOT-EMAIL-NEXT-PLAN §3.3): null when not selecting.
  Set<String>? _selected;

  void _reset() {
    _extra.clear();
    _nextCursor = null;
    _cursorLoaded = false;
  }

  void _switchVerdict(String? v) {
    if (_verdict == v) return;
    setState(() {
      _verdict = v;
      _selected = null;
      _reset();
    });
  }

  Future<void> _loadMore(String cursor) async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(backendProvider).mailMessages(
            widget.botId,
            verdict: _verdict,
            cursor: cursor,
          );
      if (!mounted) return;
      setState(() {
        _extra.addAll(page.items);
        _nextCursor = page.nextCursor;
        _cursorLoaded = true;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Reloads the list and the storage figure after mail went.
  void _refreshAll() {
    setState(_reset);
    ref.invalidate(mailMessagesProvider((botId: widget.botId, verdict: _verdict)));
    ref.invalidate(mailMessagesProvider((botId: widget.botId, verdict: null)));
    ref.invalidate(mailAddressProvider(widget.botId));
  }

  Future<void> _deleteIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.botEmailDeleteTitle(ids.length),
      message: l10n.botEmailDeleteBody,
      confirmLabel: l10n.botEmailDelete,
      destructive: true,
      confirmKey: const Key('mailDeleteConfirm'),
    );
    if (!ok || !mounted) return;
    final res = await runGuarded(
      context,
      () => ref.read(backendProvider).deleteMail(widget.botId, ids: ids),
    );
    if (res == null || !mounted) return;
    setState(() => _selected = null);
    _refreshAll();
    showSuccess(context, l10n.botEmailDeleted(res.deleted));
  }

  Future<void> _deleteOlder() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final choices = <(String, DateTime)>[
      (l10n.botEmailOlder30Days, now.subtract(const Duration(days: 30))),
      (l10n.botEmailOlder6Months, DateTime(now.year, now.month - 6, now.day)),
      (l10n.botEmailOlderYear, DateTime(now.year - 1, now.month, now.day)),
    ];
    final picked = await showAdaptiveSheet<(String, DateTime)>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(l10n.botEmailDeleteOlder, style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final (i, c) in choices.indexed)
              ListTile(
                key: Key('mailOlder-$i'),
                leading: const Icon(LucideIcons.calendarClock),
                title: Text(c.$1),
                onTap: () => Navigator.pop(ctx, c),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final ok = await showConfirm(
      context: context,
      title: l10n.botEmailDeleteOlderTitle(picked.$1.toLowerCase()),
      message: l10n.botEmailDeleteBody,
      confirmLabel: l10n.botEmailDelete,
      destructive: true,
      confirmKey: const Key('mailDeleteConfirm'),
    );
    if (!ok || !mounted) return;
    final res = await runGuarded(
      context,
      () => ref.read(backendProvider).deleteMail(widget.botId, before: picked.$2),
    );
    if (res == null || !mounted) return;
    _refreshAll();
    showSuccess(context, l10n.botEmailDeleted(res.deleted));
  }

  static String _threadSubject(String subject) =>
      subject.replaceFirst(RegExp(r'^((re|fwd?):\s*)+', caseSensitive: false), '').trim().toLowerCase();

  /// Groups kept mail into threads by normalized subject, keeping newest-first order.
  static List<List<MailMessage>> _groupThreads(List<MailMessage> all) {
    final byKey = <String, List<MailMessage>>{};
    final order = <String>[];
    for (final m in all) {
      final norm = _threadSubject(m.subject);
      final key = norm.isEmpty ? 'id:${m.id}' : 'subj:$norm';
      if (!byKey.containsKey(key)) order.add(key);
      byKey.putIfAbsent(key, () => []).add(m);
    }
    return [for (final k in order) byKey[k]!];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = ref.watch(mailAddressProvider(widget.botId)).value;
    final messages = ref.watch(mailMessagesProvider((botId: widget.botId, verdict: _verdict)));
    final noAddress = messages.hasError &&
        (problemOf(messages.error!)?.code == 'address_not_found' ||
            (messages.error is DioException &&
                (messages.error! as DioException).response?.statusCode == 404));
    final botName = ref.watch(botProvider(widget.botId))?.name ?? l10n.theBot;
    final selecting = _selected != null;
    return SubPage(
      title: l10n.botEmailInbox,
      subtitle: address?.address,
      actions: [
        if (!selecting) ...[
          ChoiceChip(
            key: const Key('mailFilterAll'),
            label: Text(l10n.botEmailAll),
            selected: _verdict == null,
            onSelected: (_) => _switchVerdict(null),
          ),
          ChoiceChip(
            key: const Key('mailFilterStrangers'),
            label: Text(l10n.botEmailStrangers),
            selected: _verdict == 'stranger',
            onSelected: (_) => _switchVerdict('stranger'),
          ),
          PopupMenuButton<String>(
            key: const Key('mailMenu'),
            tooltip: l10n.moreActions,
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (v) {
              if (v == 'select') setState(() => _selected = {});
              if (v == 'older') _deleteOlder();
            },
            itemBuilder: (_) => [
              PopupMenuItem(key: const Key('mailSelect'), value: 'select', child: Text(l10n.botEmailSelect)),
              PopupMenuItem(key: const Key('mailDeleteOlder'), value: 'older', child: Text(l10n.botEmailDeleteOlder)),
            ],
          ),
        ] else
          TextButton(
            key: const Key('mailSelectDone'),
            onPressed: () => setState(() => _selected = null),
            child: Text(l10n.botEmailSelectDone),
          ),
      ],
      body: Column(
        children: [
          if (address != null) _StorageLine(address: address),
          Expanded(
            child: noAddress
                ? EmptyState(
                    key: const Key('mailNoAddress'),
                    icon: LucideIcons.mail,
                    title: l10n.botEmailClaimTitle(botName),
                    message: l10n.botEmailClaimHelp,
                    action: FilledButton.icon(
                      key: const Key('mailClaimAddress'),
                      onPressed: () async {
                        await showBotEmailSheet(context, widget.botId);
                        if (mounted) _refreshAll();
                      },
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(l10n.botEmailClaim),
                    ),
                  )
                : AsyncView(
              value: messages,
              onRetry: () {
                setState(_reset);
                ref.invalidate(mailMessagesProvider((botId: widget.botId, verdict: _verdict)));
              },
              data: (list) {
                final seen = <String>{};
                final combined = <MailMessage>[
                  for (final m in [...list.items, ..._extra])
                    if (seen.add(m.id)) m,
                ];
                final cursor = _cursorLoaded ? _nextCursor : list.nextCursor;
                if (combined.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(l10n.botEmailEmpty, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  );
                }
                final threads = _groupThreads(combined);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: threads.length + (cursor != null ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == threads.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Center(
                          child: OutlinedButton(
                            key: const Key('mailLoadMore'),
                            onPressed: _loadingMore ? null : () => _loadMore(cursor!),
                            child: _loadingMore
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(l10n.moreActions),
                          ),
                        ),
                      );
                    }
                    final thread = threads[i];
                    final ids = [for (final m in thread) m.id];
                    final picked = selecting && ids.every(_selected!.contains);
                    void toggle() => setState(() {
                          final sel = _selected ??= {};
                          if (ids.every(sel.contains)) {
                            sel.removeAll(ids);
                          } else {
                            sel.addAll(ids);
                          }
                        });
                    return _MailRow(
                      key: Key('mail-${thread.first.id}'),
                      botId: widget.botId,
                      mail: thread.first,
                      threadCount: thread.length,
                      selecting: selecting,
                      picked: picked,
                      onToggle: toggle,
                      onDeleted: _refreshAll,
                    );
                  },
                );
              },
            ),
          ),
          if (selecting)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('mailDeleteSelected'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: Text(l10n.botEmailDeleteCount(_selected!.length)),
                    onPressed: _selected!.isEmpty ? null : () => _deleteIds(_selected!.toList()),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A mailbox size the way plans state it: whole KB or MB, GB with at most one decimal.
String mailboxSize(int n, String locale) {
  const mb = 1024 * 1024;
  if (n < mb) return '${(n / 1024).ceil().humanizedCount(locale)} KB';
  if (n < 1024 * mb) return '${(n / mb).round().humanizedCount(locale)} MB';
  final gb = n / (1024 * mb);
  final whole = gb.roundToDouble() == gb;
  return '${gb.humanizedCount(locale, decimalDigits: whole ? 0 : 1)} GB';
}

/// How full the mailbox is: "312 MB of 500 MB", with a bar (BOT-EMAIL-NEXT-PLAN §3.3).
class _StorageLine extends StatelessWidget {
  const _StorageLine({required this.address});
  final MailAddress address;

  @override
  Widget build(BuildContext context) {
    final used = address.storageUsed;
    if (used == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final limit = address.storageLimit;
    final share = limit != null && limit > 0 ? (used / limit).clamp(0.0, 1.0) : null;
    final full = share != null && share >= 1;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const Key('mailStorage'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            limit != null && limit > 0
                ? l10n.botEmailStorage(mailboxSize(used, locale), mailboxSize(limit, locale))
                : l10n.botEmailStorageUsed(mailboxSize(used, locale)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (share != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: share,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              color: share >= 0.9 ? scheme.error : null,
            ),
          ],
          if (full) ...[
            const SizedBox(height: 4),
            Text(
              l10n.botEmailStorageFull,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _MailRow extends ConsumerWidget {
  const _MailRow({
    super.key,
    required this.botId,
    required this.mail,
    this.threadCount = 1,
    this.selecting = false,
    this.picked = false,
    required this.onToggle,
    required this.onDeleted,
  });
  final String botId;
  final MailMessage mail;
  final int threadCount;
  final bool selecting;
  final bool picked;
  final VoidCallback onToggle;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unconfirmed = mail.senderCheck != MailMessageSenderCheckEnum.pass && mail.direction == MailMessageDirectionEnum.in_;
    final who = mail.fromName ?? mail.fromAddr;
    return GestureDetector(
      // A long press starts selecting with this thread picked.
      onLongPress: selecting ? null : onToggle,
      child: GroupedTile(
        icon: selecting
            ? (picked ? LucideIcons.circleCheck : LucideIcons.circle)
            : mail.direction == MailMessageDirectionEnum.out_
                ? LucideIcons.send
                : LucideIcons.mailOpen,
        selected: picked,
        title: threadCount > 1 ? '$who ($threadCount)' : who,
        subtitle: '${mail.subject.isEmpty ? l10n.botEmailEmpty : mail.subject}\n${mail.snippet}',
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              messageSentLabel(context, mail.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (mail.hasFiles) const Icon(LucideIcons.paperclip, size: 14),
            if (unconfirmed)
              Tooltip(
                message: l10n.botEmailUnconfirmed,
                child: Icon(LucideIcons.shieldAlert, size: 14, color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        onTap: selecting
            ? onToggle
            : () async {
                final deleted = await showAdaptiveSheet<bool>(
                  context: context,
                  builder: (_) => _MailDetailSheet(botId: botId, id: mail.id),
                );
                if (deleted == true) onDeleted();
              },
      ),
    );
  }
}

class _MailDetailSheet extends ConsumerWidget {
  const _MailDetailSheet({required this.botId, required this.id});
  final String botId;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    return AsyncView(
      value: ref.watch(_mailDetailProvider((botId: botId, id: id))),
      onRetry: () => ref.invalidate(_mailDetailProvider((botId: botId, id: id))),
      data: (m) {
        final address = ref.watch(mailAddressProvider(botId)).value;
        final channel = ref.watch(channelsProvider(botId)).value?.where((c) => c.id == address?.channelId).firstOrNull;
        final allowed = channel?.allowedSenders.contains(m.fromAddr) ?? false;
        final blocked = address?.blockedSenders.contains(m.fromAddr) ?? false;
        final unconfirmed = m.senderCheck != MailMessageDetailSenderCheckEnum.pass;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  m.subject.isEmpty ? l10n.botEmailEmpty : m.subject,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  '${m.fromName ?? m.fromAddr} · ${messageSentLabel(context, m.createdAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (unconfirmed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldAlert, size: 16, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text(l10n.botEmailUnconfirmed)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SelectableText(m.text.isEmpty ? l10n.botEmailEmpty : m.text),
              ),
              if (m.files.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GroupedCard(
                    children: [
                      for (final f in m.files)
                        GroupedTile(
                          key: Key('mailFile-${f.index}'),
                          icon: LucideIcons.paperclip,
                          title: f.name,
                          subtitle: '${(f.size / 1024).toStringAsFixed(0)} KB',
                          onTap: () async {
                            final bytes = await runGuarded(context, () => backend.downloadMailFile(botId, id, f.index));
                            if (bytes == null || !context.mounted) return;
                            await shareFiles(
                              [XFile.fromData(bytes, name: f.name, mimeType: f.mime)],
                              origin: shareOrigin(context),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              if (m.verdict == MailMessageDetailVerdictEnum.stranger && !allowed && !blocked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          key: const Key('mailAllow'),
                          icon: const Icon(LucideIcons.check, size: 18),
                          label: Text(l10n.botEmailAllow),
                          onPressed: channel == null
                              ? null
                              : () async {
                                  await runGuarded(
                                    context,
                                    () => backend.updateChannel(
                                      channel.id,
                                      allowedSenders: [...channel.allowedSenders, m.fromAddr],
                                    ),
                                  );
                                  ref.invalidate(channelsProvider(botId));
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('mailBlock'),
                          icon: const Icon(LucideIcons.ban, size: 18),
                          label: Text(l10n.botEmailBlock),
                          onPressed: () async {
                            await runGuarded(context, () => backend.blockMailSender(botId, m.fromAddr));
                            ref.invalidate(mailAddressProvider(botId));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (blocked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.botEmailBlocked)),
                      TextButton(
                        key: const Key('mailUnblock'),
                        onPressed: () async {
                          await runGuarded(context, () => backend.unblockMailSender(botId, m.fromAddr));
                          ref.invalidate(mailAddressProvider(botId));
                        },
                        child: Text(l10n.botEmailUnblock),
                      ),
                    ],
                  ),
                ),
              if (m.conversationId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: OutlinedButton.icon(
                    key: const Key('mailOpenChat'),
                    icon: const Icon(LucideIcons.messageCircle, size: 18),
                    label: Text(l10n.botEmailOpenChat),
                    onPressed: () {
                      Navigator.pop(context);
                      context.pushOnce('/bots/$botId/chat?c=${m.conversationId}');
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextButton.icon(
                  key: const Key('mailDelete'),
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: Text(l10n.botEmailDelete),
                  onPressed: () async {
                    final ok = await showConfirm(
                      context: context,
                      title: l10n.botEmailDeleteTitle(1),
                      message: l10n.botEmailDeleteBody,
                      confirmLabel: l10n.botEmailDelete,
                      destructive: true,
                      confirmKey: const Key('mailDeleteConfirm'),
                    );
                    if (!ok || !context.mounted) return;
                    final res = await runGuarded(context, () => backend.deleteMail(botId, ids: [id]));
                    if (res == null || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
