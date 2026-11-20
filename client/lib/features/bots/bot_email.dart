import 'dart:async';
import 'dart:convert';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import 'channels_screen.dart';

/// A bot's hosted email address (BOT-EMAIL-PLAN), or null when it has none.
final mailAddressProvider = FutureProvider.autoDispose.family<MailAddress?, String>(
  (ref, botId) => ref.watch(backendProvider).mailAddress(botId),
);

Future<void> showBotEmailSheet(BuildContext context, String botId, {String surface = 'profile'}) =>
    showAdaptiveSheet<void>(
      context: context,
      builder: (_) => BotEmailSheet(botId: botId, surface: surface),
    );

class BotEmailSheet extends ConsumerWidget {
  const BotEmailSheet({super.key, required this.botId, this.surface = 'profile'});
  final String botId;
  final String surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final botName = ref.watch(botProvider(botId))?.name ?? l10n.theBot;
    return AsyncView(
      value: ref.watch(mailAddressProvider(botId)),
      onRetry: () => ref.invalidate(mailAddressProvider(botId)),
      data: (address) => address == null
          ? _ClaimForm(botId: botId, botName: botName, surface: surface)
          : _AddressView(botId: botId, botName: botName, address: address),
    );
  }
}

class _ClaimForm extends ConsumerStatefulWidget {
  const _ClaimForm({required this.botId, required this.botName, required this.surface});
  final String botId;
  final String botName;
  final String surface;

  @override
  ConsumerState<_ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends ConsumerState<_ClaimForm> {
  late final _name = TextEditingController();
  Timer? _timer;
  int _request = 0;
  MailNameAvailability? _check;
  bool _busy = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    // Prefill with a free name built from the bot's name. Silent: the field just starts empty.
    ref.read(backendProvider).checkMailName(widget.botId, widget.botName).then((c) {
      if (!mounted || _name.text.isNotEmpty) return;
      setState(() {
        _name.text = c.available ? c.name : (c.suggestions.firstOrNull ?? '');
        _check = c.available ? c : null;
        _prefilled = true;
      });
      if (!_checkAvailable) _schedule();
    }).catchError((_) => null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    super.dispose();
  }

  bool get _checkAvailable => _check?.available == true && _check?.name == _name.text.trim().toLowerCase();

  void _schedule() {
    _timer?.cancel();
    _check = null;
    if (_name.text.trim().isEmpty) {
      setState(() {});
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), () async {
      final n = ++_request;
      // Silent: a failed check just leaves the button off until the next keystroke.
      MailNameAvailability? c;
      try {
        c = await ref.read(backendProvider).checkMailName(widget.botId, _name.text.trim());
      } catch (_) {
        return;
      }
      if (!mounted || n != _request) return;
      setState(() => _check = c);
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final claimed = await runGuarded(
      context,
      () => ref.read(backendProvider).claimMailAddress(widget.botId, _name.text.trim(), surface: widget.surface),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (claimed != null) {
      HapticsHelper.success();
      ref.invalidate(mailAddressProvider(widget.botId));
      ref.invalidate(channelsProvider(widget.botId));
    } else {
      _schedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final issue = _check?.name == _name.text.trim().toLowerCase() ? _check?.issue : null;
    final suggestions = _check?.name == _name.text.trim().toLowerCase() ? (_check?.suggestions ?? const []) : const <String>[];
    return FormSheet(
      icon: LucideIcons.mail,
      title: l10n.botEmailClaimTitle(widget.botName),
      subtitle: l10n.botEmailClaimHelp,
      submitLabel: l10n.botEmailClaim,
      submitKey: const Key('claimMail'),
      onSubmit: !_checkAvailable || _busy ? null : _submit,
      children: [
        TextField(
          key: const Key('mailName'),
          controller: _name,
          autofocus: _prefilled,
          autocorrect: false,
          decoration: InputDecoration(labelText: l10n.botEmail, hintText: l10n.botEmailNameHint),
          onChanged: (_) => _schedule(),
        ),
        Text(l10n.botEmailNameFixed, style: Theme.of(context).textTheme.bodySmall),
        if (issue != null) Text(issue, key: const Key('mailNameIssue'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (suggestions.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [for (final s in suggestions) ActionChip(key: Key('mailSuggest-$s'), label: Text(s), onPressed: () => setState(() {
              _name.text = s;
              _schedule();
            }))],
          ),
      ],
    );
  }
}

class _AddressView extends ConsumerWidget {
  const _AddressView({required this.botId, required this.botName, required this.address});
  final String botId;
  final String botName;
  final MailAddress address;

  Future<void> _contacts(BuildContext context) async {
    final vcard = utf8.encode('BEGIN:VCARD\nVERSION:3.0\nFN:$botName\nEMAIL:${address.address}\nEND:VCARD\n');
    await shareFiles([XFile.fromData(vcard, name: '${address.localPart}.vcf', mimeType: 'text/vcard')], origin: shareOrigin(context));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    final paused = address.status == MailAddressStatusEnum.paused;
    final senders = ref.watch(channelsProvider(botId)).value?.where((c) => c.id == address.channelId).firstOrNull?.allowedSenders ?? const [];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(l10n.botEmailClaimed, style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l10n.botEmailClaimedHelp, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GroupedCard(
              children: [
                GroupedTile(
                  key: const Key('mailAddress'),
                  icon: LucideIcons.mail,
                  title: address.address,
                  subtitle: paused ? l10n.botEmailPaused : null,
                  onTap: null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('mailCopy'),
                  icon: const Icon(LucideIcons.copy, size: 18),
                  label: Text(l10n.botEmailCopy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: address.address)),
                ),
                OutlinedButton.icon(
                  key: const Key('mailContacts'),
                  icon: const Icon(LucideIcons.contactRound, size: 18),
                  label: Text(l10n.botEmailContacts),
                  onPressed: () => _contacts(context),
                ),
                OutlinedButton.icon(
                  key: const Key('mailWrite'),
                  icon: const Icon(LucideIcons.penLine, size: 18),
                  label: Text(l10n.botEmailWrite(botName)),
                  onPressed: () => launchUrl(Uri.parse('mailto:${address.address}')),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GroupedCard(
              children: [
                GroupedTile(
                  key: const Key('mailInbox'),
                  icon: LucideIcons.inbox,
                  title: l10n.botEmailInbox,
                  subtitle: l10n.botEmailInboxRow,
                  onTap: () {
                    Navigator.pop(context);
                    context.pushOnce('/bots/$botId/email');
                  },
                ),
                GroupedTile(
                  key: const Key('mailPause'),
                  icon: paused ? LucideIcons.play : LucideIcons.pause,
                  title: paused ? l10n.botEmailResume : l10n.botEmailPause,
                  onTap: () async {
                    await runGuarded(context, () => backend.updateMailAddress(botId, status: paused ? 'active' : 'paused'));
                    ref.invalidate(mailAddressProvider(botId));
                  },
                ),
                GroupedTile(
                  key: const Key('mailNewSenders'),
                  icon: LucideIcons.bellRing,
                  title: l10n.botEmailNewSenders,
                  subtitle: l10n.botEmailNewSendersHelp,
                  trailing: Switch(
                    value: address.notifyNewSenders,
                    onChanged: (v) async {
                      await runGuarded(context, () => backend.updateMailAddress(botId, notifyNewSenders: v));
                      ref.invalidate(mailAddressProvider(botId));
                    },
                  ),
                  onTap: () async {
                    await runGuarded(context, () => backend.updateMailAddress(botId, notifyNewSenders: !address.notifyNewSenders));
                    ref.invalidate(mailAddressProvider(botId));
                  },
                ),
                GroupedTile(
                  key: const Key('mailSenders'),
                  icon: LucideIcons.users,
                  title: l10n.botEmailSenders,
                  subtitle: senders.isEmpty ? l10n.botEmailSendersHelp : senders.join(', '),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushOnce('/bots/$botId/chat-apps');
                  },
                ),
                GroupedTile(
                  key: const Key('mailMove'),
                  icon: LucideIcons.arrowRightLeft,
                  title: l10n.botEmailMove,
                  subtitle: l10n.botEmailMoveHelp,
                  onTap: () async {
                    final to = await showAdaptiveSheet<String>(
                      context: context,
                      builder: (_) => _MoveSheet(botId: botId),
                    );
                    if (to != null && context.mounted) {
                      await runGuarded(context, () => backend.moveMailAddress(botId, to));
                      ref.invalidate(mailAddressProvider(botId));
                      ref.invalidate(mailAddressProvider(to));
                      ref.invalidate(channelsProvider(botId));
                      ref.invalidate(channelsProvider(to));
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l10n.botEmailTryTitle, style: Theme.of(context).textTheme.titleMedium),
          ),
          _TryCard(
            key: const Key('mailTryForward'),
            icon: LucideIcons.forward,
            title: l10n.botEmailTryForward,
            help: l10n.botEmailTryForwardHelp,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: address.address));
              if (context.mounted) showToast(context, l10n.botEmailTryCopied);
            },
          ),
          _TryCard(
            key: const Key('mailTryReceipts'),
            icon: LucideIcons.receipt,
            title: l10n.botEmailTryReceipts,
            help: l10n.botEmailTryReceiptsHelp('${address.localPart}+receipts@${address.address.split('@').last}'),
            onTap: () => _makeTaggedRoutine(
              context,
              ref,
              botId: botId,
              name: l10n.botEmailReceiptsName,
              instructions: l10n.botEmailReceiptsInstructions,
              tag: 'receipts',
              tagged: '${address.localPart}+receipts@${address.address.split('@').last}',
            ),
          ),
          _TryCard(
            key: const Key('mailTryDigest'),
            icon: LucideIcons.newspaper,
            title: l10n.botEmailTryDigest,
            help: l10n.botEmailTryDigestHelp('${address.localPart}+news@${address.address.split('@').last}'),
            onTap: () => _makeWeeklyDigestRoutine(
              context,
              ref,
              botId: botId,
              name: l10n.botEmailDigestName,
              instructions: l10n.botEmailDigestInstructions,
              tagged: '${address.localPart}+news@${address.address.split('@').last}',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextButton.icon(
              key: const Key('mailRelease'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: Text(l10n.botEmailRelease),
              onPressed: () async {
                final ok = await showConfirm(
                  context: context,
                  title: l10n.botEmailRelease,
                  message: l10n.botEmailReleaseConfirm(address.address),
                  confirmLabel: l10n.botEmailReleaseNow,
                  confirmKey: const Key('mailReleaseConfirm'),
                  destructive: true,
                );
                if (ok && context.mounted) {
                  await runGuarded(context, () => backend.releaseMailAddress(botId));
                  ref.invalidate(mailAddressProvider(botId));
                  ref.invalidate(channelsProvider(botId));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _routineExists(WidgetRef ref, String botId, String name) async {
  try {
    final existing = await ref.read(backendProvider).routines(botId);
    return existing.any((r) => r.name.trim().toLowerCase() == name.trim().toLowerCase());
  } catch (_) {
    return false;
  }
}

Future<void> _makeTaggedRoutine(
  BuildContext context,
  WidgetRef ref, {
  required String botId,
  required String name,
  required String instructions,
  required String tag,
  required String tagged,
}) async {
  final backend = ref.read(backendProvider);
  if (!await _routineExists(ref, botId, name)) {
    if (!context.mounted) return;
    final created = await runGuarded(
      context,
      () => backend.createRoutine(
        botId,
        name: name,
        instructions: instructions,
        trigger: 'message',
        message: MessageTriggerConfig(
          channelKind: MessageTriggerConfigChannelKindEnum.email,
          sender: '*',
          toTag: tag,
        ),
      ),
    );
    if (created == null || !context.mounted) return;
  }
  await Clipboard.setData(ClipboardData(text: tagged));
  if (context.mounted) showToast(context, context.l10n.botEmailTryMade);
}

Future<void> _makeWeeklyDigestRoutine(
  BuildContext context,
  WidgetRef ref, {
  required String botId,
  required String name,
  required String instructions,
  required String tagged,
}) async {
  final backend = ref.read(backendProvider);
  if (!await _routineExists(ref, botId, name)) {
    if (!context.mounted) return;
    final created = await runGuarded(
      context,
      () => backend.createRoutine(
        botId,
        name: name,
        instructions: '$instructions Search kept mail with tag "news" from the past 7 days.',
        trigger: 'schedule',
        cron: '0 9 * * 0',
      ),
    );
    if (created == null || !context.mounted) return;
  }
  await Clipboard.setData(ClipboardData(text: tagged));
  if (context.mounted) showToast(context, context.l10n.botEmailTryMade);
}

class _TryCard extends StatelessWidget {
  const _TryCard({super.key, required this.icon, required this.title, required this.help, required this.onTap});
  final IconData icon;
  final String title;
  final String help;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: AppCard(
          onTap: () => onTap(),
          radius: AppRadius.tile,
          padding: const EdgeInsets.fromLTRB(AppSpace.md, 12, AppSpace.sm, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(help, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// One optional row in an empty chat (BOT-EMAIL-PLAN §4.5): offer the bot an address until it
/// has one or the person dismisses it.
/// Whether the empty-chat offer is due (BOT-EMAIL-NEXT-PLAN §5): once the bot is a day old or the
/// person has had three chats with it, so it doesn't crowd a brand-new bot's first chat.
bool emailOfferDue(DateTime? botCreatedAt, int? chats, {DateTime? now}) {
  final age = botCreatedAt == null ? Duration.zero : (now ?? DateTime.now()).difference(botCreatedAt);
  return age >= const Duration(days: 1) || (chats ?? 0) >= 3;
}

class EmailOfferTile extends ConsumerStatefulWidget {
  const EmailOfferTile({super.key, required this.botId, required this.botName});
  final String botId;
  final String botName;

  @override
  ConsumerState<EmailOfferTile> createState() => _EmailOfferTileState();
}

class _EmailOfferTileState extends ConsumerState<EmailOfferTile> {
  bool _dismissed = false;

  String get _prefKey => 'emailOffer.dismissed.${widget.botId}';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted && (p.getBool(_prefKey) ?? false)) setState(() => _dismissed = true);
    }).catchError((_) => null);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_prefKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final l10n = context.l10n;
    final address = ref.watch(mailAddressProvider(widget.botId));
    if (address.value != null || address.isLoading) return const SizedBox.shrink();
    if (!emailOfferDue(
      ref.watch(botProvider(widget.botId))?.createdAt,
      ref.watch(conversationsProvider(widget.botId)).value?.length,
    )) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        key: const Key('emailOffer'),
        onTap: () => showBotEmailSheet(context, widget.botId),
        radius: AppRadius.tile,
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 10, 4, 10),
        child: Row(
          children: [
            Icon(LucideIcons.mail, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                l10n.botEmailNewBotRow(widget.botName),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
            IconButton(
              key: const Key('dismissEmailOffer'),
              icon: Icon(LucideIcons.x, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              visualDensity: VisualDensity.compact,
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveSheet extends ConsumerWidget {
  const _MoveSheet({required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = (ref.watch(botsProvider).value ?? const []).where((b) => b.id != botId).toList();
    return FormSheet(
      icon: LucideIcons.arrowRightLeft,
      title: l10n.botEmailMove,
      subtitle: l10n.botEmailMoveHelp,
      submitLabel: l10n.cancel,
      showCancel: false,
      onSubmit: () => Navigator.pop(context),
      children: [
        for (final b in bots)
          GroupedTile(
            key: Key('mailMove-${b.id}'),
            icon: LucideIcons.bot,
            title: b.name,
            onTap: () => Navigator.pop(context, b.id),
          ),
      ],
    );
  }
}
