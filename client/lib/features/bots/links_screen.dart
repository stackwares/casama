import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Linked agents (D-143): link this bot with a trusted contact's bot; see every exchange.
final botLinksProvider = FutureProvider.autoDispose.family<List<BotLink>, String>((ref, botId) => ref.watch(backendProvider).botLinks(botId));
final linkExchangesProvider = FutureProvider.autoDispose.family<List<LinkExchange>, String>((ref, id) => ref.watch(backendProvider).linkExchanges(id));

class LinksScreen extends ConsumerWidget {
  const LinksScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Future<void> invite() async {
      final name = await _ask(context, l10n.linksInvite, l10n.linksContactName, key: 'inviteName');
      if (name == null || !context.mounted) return;
      final created = await runGuarded(context, () => ref.read(backendProvider).createBotLink(botId, name));
      ref.invalidate(botLinksProvider(botId));
      if (created == null || !context.mounted) return;
      await showAdaptiveSheet<void>(
        context: context,
        builder: (_) => FormSheet(
          icon: LucideIcons.link,
          title: l10n.linksInviteReady,
          subtitle: l10n.linksInviteHelp,
          submitLabel: l10n.close,
          onSubmit: () => Navigator.pop(context),
          children: [
            Row(
              children: [
                Expanded(child: SelectableText(created.invite, key: const Key('inviteText'), maxLines: 3)),
                IconButton(
                  tooltip: l10n.copy,
                  icon: const Icon(LucideIcons.copy, size: 18),
                  onPressed: () => unawaited(Clipboard.setData(ClipboardData(text: created.invite))),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Future<void> accept() async {
      final r = await showAdaptiveSheet<(String, String)>(context: context, builder: (_) => const _AcceptSheet());
      if (r == null || !context.mounted) return;
      await runGuarded(context, () => ref.read(backendProvider).acceptBotLink(r.$1, botId, r.$2));
      ref.invalidate(botLinksProvider(botId));
    }

    return SubPage(
      title: l10n.links,
      subtitle: ref.watch(botProvider(botId))?.name,
      actions: [
        IconButton(key: const Key('acceptLink'), tooltip: l10n.linksAccept, icon: const Icon(LucideIcons.ticket), onPressed: accept),
        IconButton(key: const Key('inviteLink'), tooltip: l10n.linksInvite, icon: const Icon(LucideIcons.plus), onPressed: invite),
      ],
      body: AsyncView(
        value: ref.watch(botLinksProvider(botId)),
        onRetry: () => ref.invalidate(botLinksProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.link,
                title: l10n.linksEmpty,
                message: l10n.linksHelp,
                action: FilledButton(onPressed: invite, child: Text(l10n.linksInvite)),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.linksHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final link in items)
                        GroupedTile(
                          key: Key('link-${link.id}'),
                          icon: link.status == BotLinkStatusEnum.active ? LucideIcons.link : LucideIcons.unlink,
                          title: link.name,
                          subtitle: [
                            switch (link.status) {
                              BotLinkStatusEnum.active => l10n.linksActive(link.peerBotName.orPlaceholder()),
                              BotLinkStatusEnum.pending => l10n.linksPending,
                              _ => l10n.linksRevoked,
                            },
                            if (link.remoteUrl.isUsable) Uri.tryParse(link.remoteUrl!)?.host ?? '',
                          ].where((s) => s.isNotEmpty).join(' · '),
                          onTap: () => showAdaptiveSheet<void>(
                            context: context,
                            builder: (_) => _LinkSheet(botId: botId, link: link),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

Future<String?> _ask(BuildContext context, String title, String label, {required String key}) async {
  final c = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        key: Key(key),
        controller: c,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.cancel)),
        FilledButton(key: Key('$key-ok'), onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(context.l10n.save)),
      ],
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  return r == null || r.isEmpty ? null : r;
}

class _AcceptSheet extends StatefulWidget {
  const _AcceptSheet();
  @override
  State<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends State<_AcceptSheet> {
  final _invite = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _invite.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ok = _invite.text.trim().startsWith('casama-link:') && _name.text.trim().isNotEmpty;
    return FormSheet(
      icon: LucideIcons.ticket,
      title: l10n.linksAccept,
      subtitle: l10n.linksAcceptHelp,
      submitLabel: l10n.linksAccept,
      submitKey: const Key('saveAcceptLink'),
      onSubmit: ok ? () => Navigator.pop(context, (_invite.text.trim(), _name.text.trim())) : null,
      children: [
        TextField(
          key: const Key('acceptInvite'),
          controller: _invite,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.linksInviteText),
        ),
        TextField(
          key: const Key('acceptName'),
          controller: _name,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (ok) Navigator.pop(context, (_invite.text.trim(), _name.text.trim()));
          },
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.linksContactName),
        ),
      ],
    );
  }
}

class _LinkSheet extends ConsumerWidget {
  const _LinkSheet({required this.botId, required this.link});
  final String botId;
  final BotLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exchanges = ref.watch(linkExchangesProvider(link.id));
    final ex = exchanges.value ?? const <LinkExchange>[];
    return FormSheet(
      icon: LucideIcons.link,
      title: link.name,
      subtitle: link.peerBotName.isUsable ? l10n.linksActive(link.peerBotName!) : null,
      submitLabel: l10n.close,
      onSubmit: () => Navigator.pop(context),
      children: [
        SectionHeader(title: l10n.linksExchanges),
        if (exchanges.hasError)
          InlineError(error: exchanges.error!, onRetry: () => ref.invalidate(linkExchangesProvider(link.id)))
        else if (exchanges.hasValue && ex.isEmpty)
          FormNote(l10n.linksNoExchanges),
        for (final e in ex)
          ListTile(
            key: Key('exchange-${e.id}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(e.direction == LinkExchangeDirectionEnum.out_ ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft, size: 18),
            title: Text(e.request, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(e.response.orPlaceholder(e.status == LinkExchangeStatusEnum.failed ? l10n.linksNoAnswer : l10n.linksWorking), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        if (link.status != BotLinkStatusEnum.revoked)
          TextButton.icon(
            key: const Key('revokeLink'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(LucideIcons.unlink, size: 18),
            label: Text(l10n.linksRevoke),
            onPressed: () async {
              final ok = await showConfirm(
                context: context,
                title: l10n.unlinkTitle(link.name),
                message: l10n.unlinkBody,
                confirmLabel: l10n.linksRevoke,
                destructive: true,
                icon: LucideIcons.unlink,
                confirmKey: const Key('confirmUnlink'),
              );
              if (!ok || !context.mounted) return;
              await runGuarded(context, () => ref.read(backendProvider).revokeBotLink(link.id));
              ref.invalidate(botLinksProvider(botId));
              if (context.mounted) Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
