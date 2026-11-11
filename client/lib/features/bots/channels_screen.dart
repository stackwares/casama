import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/revealable.dart';

/// Chat apps (D-134): Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu and iMessage. Only
/// allowed senders get answers; everyone else is logged in the activity list.
final channelsProvider = FutureProvider.autoDispose.family<List<Channel>, String>((ref, botId) => ref.watch(backendProvider).channels(botId));

/// The workspace's paired devices, for picking the Mac that runs iMessage; held here so the form does not refetch on every keystroke.
final _localDevicesProvider = FutureProvider.autoDispose<List<LocalDevice>>((ref) {
  final org = ref.watch(currentOrgProvider);
  return org == null ? Future.value(const <LocalDevice>[]) : ref.watch(backendProvider).localDevices(org.id);
});
final channelEventsProvider = FutureProvider.autoDispose.family<List<ChannelEvent>, String>((ref, id) => ref.watch(backendProvider).channelEvents(id));

String channelKindName(ChannelKind k) => switch (k) {
  ChannelKind.telegram => 'Telegram',
  ChannelKind.email => 'Email',
  ChannelKind.sms => 'SMS',
  ChannelKind.slack => 'Slack',
  ChannelKind.whatsapp => 'WhatsApp',
  ChannelKind.messenger => 'Messenger',
  ChannelKind.feishu => 'Feishu',
  ChannelKind.imessage => 'iMessage',
};

IconData channelIcon(ChannelKind k) => switch (k) {
  ChannelKind.email => LucideIcons.mail,
  ChannelKind.sms || ChannelKind.imessage => LucideIcons.messageCircle,
  ChannelKind.slack => LucideIcons.hash,
  _ => LucideIcons.send,
};

/// One setup field: its key, whether it's a secret, and its label.
typedef _Field = (String key, bool secret, String Function(AppLocalizations) label);

final Map<ChannelKind, List<_Field>> _fields = {
  ChannelKind.telegram: [('bot_token', true, (l) => l.chBotToken)],
  ChannelKind.email: [('address', false, (l) => l.chAddress), ('api_key', true, (l) => l.chApiKey), ('signing_secret', true, (l) => l.chSigningSecret)],
  ChannelKind.sms: [('phone_number', false, (l) => l.chPhoneNumber), ('account_sid', true, (l) => l.chAccountSid), ('auth_token', true, (l) => l.chAuthToken)],
  ChannelKind.slack: [('bot_token', true, (l) => l.chBotToken), ('signing_secret', true, (l) => l.chSigningSecret)],
  ChannelKind.whatsapp: [('phone_number_id', false, (l) => l.chPhoneNumberId), ('access_token', true, (l) => l.chAccessToken), ('app_secret', true, (l) => l.chAppSecret)],
  ChannelKind.messenger: [('page_token', true, (l) => l.chPageToken), ('app_secret', true, (l) => l.chAppSecret)],
  ChannelKind.feishu: [
    ('app_id', false, (l) => l.chAppId),
    ('app_secret', true, (l) => l.chAppSecret),
    ('encrypt_key', true, (l) => l.chEncryptKey),
    ('verification_token', true, (l) => l.chVerificationToken),
  ],
  ChannelKind.imessage: const [],
};

List<String> _splitSenders(String text) => text.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Future<void> add() async {
      final created = await showAdaptiveSheet<Channel>(
        context: context,
        builder: (_) => _AddChannel(botId: botId),
      );
      ref.invalidate(channelsProvider(botId));
      if (created != null && context.mounted && (created.webhookUrl != null || created.verifyToken != null)) {
        await showAdaptiveSheet<void>(
          context: context,
          builder: (_) => _SetupDone(channel: created),
        );
      }
    }

    return SubPage(
      title: l10n.chatApps,
      subtitle: ref.watch(botProvider(botId))?.name,
      actions: [IconButton(key: const Key('addChannel'), tooltip: l10n.chatAppsAdd, icon: const Icon(LucideIcons.plus), onPressed: add)],
      body: AsyncView(
        value: ref.watch(channelsProvider(botId)),
        onRetry: () => ref.invalidate(channelsProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.messagesSquare,
                title: l10n.chatAppsEmpty,
                message: l10n.chatAppsHelp,
                action: FilledButton(onPressed: add, child: Text(l10n.chatAppsAdd)),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.chatAppsHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final c in items)
                        GroupedTile(
                          key: Key('channel-${c.id}'),
                          icon: channelIcon(c.kind),
                          title: c.name,
                          subtitle: [channelKindName(c.kind), l10n.chatAppsAllowed(c.allowedSenders.length), if (c.lastError != null) c.lastError!].join(' · '),
                          onTap: () => showAdaptiveSheet<void>(
                            context: context,
                            builder: (_) => _ChannelDetail(botId: botId, channel: c),
                          ),
                          trailing: Switch(
                            key: Key('channelEnabled-${c.id}'),
                            value: c.enabled,
                            onChanged: (v) async {
                              await runGuarded(context, () => ref.read(backendProvider).updateChannel(c.id, enabled: v));
                              ref.invalidate(channelsProvider(botId));
                            },
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

class _AddChannel extends ConsumerStatefulWidget {
  const _AddChannel({required this.botId});
  final String botId;

  @override
  ConsumerState<_AddChannel> createState() => _AddChannelState();
}

class _AddChannelState extends ConsumerState<_AddChannel> {
  var _kind = ChannelKind.telegram;
  final _name = TextEditingController();
  final _senders = TextEditingController();
  final _values = <String, TextEditingController>{};
  String? _mac;
  var _busy = false;

  TextEditingController _c(String key) => _values.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    _name.dispose();
    _senders.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _senders.text.trim().isNotEmpty && _fields[_kind]!.every((f) => _c(f.$1).text.trim().isNotEmpty) && (_kind != ChannelKind.imessage || _mac != null);

  Future<void> _submit() async {
    setState(() => _busy = true);
    final fields = _fields[_kind]!;
    final r = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .createChannel(
            CreateChannelRequest(
              botId: widget.botId,
              kind: _kind,
              name: _name.text.trim(),
              config: {for (final f in fields.where((f) => !f.$2)) f.$1: _c(f.$1).text.trim(), if (_kind == ChannelKind.imessage) 'computer_id': _mac},
              secrets: {for (final f in fields.where((f) => f.$2)) f.$1: _c(f.$1).text.trim()},
              allowedSenders: _splitSenders(_senders.text),
            ),
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.messagesSquare,
      title: l10n.chatAppsAdd,
      subtitle: l10n.chatAppsAddHelp,
      submitLabel: l10n.add,
      submitKey: const Key('saveChannel'),
      onSubmit: !_valid || _busy ? null : _submit,
      children: [
        DropdownButtonFormField<ChannelKind>(
          isExpanded: true,
          key: const Key('channelKind'),
          initialValue: _kind,
          decoration: InputDecoration(labelText: l10n.chatAppsKind),
          items: [for (final k in ChannelKind.values) DropdownMenuItem(value: k, child: Text(channelKindName(k)))],
          onChanged: (k) => setState(() {
            _kind = k ?? _kind;
            if (_name.text.isEmpty || ChannelKind.values.any((x) => channelKindName(x) == _name.text)) _name.text = channelKindName(_kind);
          }),
        ),
        TextField(
          key: const Key('channelName'),
          controller: _name,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.botNameLabel),
        ),
        for (final f in _fields[_kind]!)
          Revealable(builder: (context, hidden, toggle) => TextField(
            key: Key('channelField-${f.$1}'),
            controller: _c(f.$1),
            obscureText: hidden && (f.$2),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: f.$3(l10n), suffixIcon: (f.$2) ? toggle : null),
          )),
        if (_kind == ChannelKind.imessage)
          Builder(
            builder: (context) {
              final devices = ref.watch(_localDevicesProvider);
              if (devices.hasError) return FormNote(errorText(context, devices.error!), icon: LucideIcons.cloudOff, color: Theme.of(context).colorScheme.error);
              final macs = (devices.value ?? const <LocalDevice>[]).where((d) => d.platform == LocalDevicePlatformEnum.macos && d.computerId != null).toList();
              if (devices.hasValue && macs.isEmpty) return FormNote(l10n.chatAppsNoMac);
              return DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('channelMac'),
                initialValue: _mac,
                decoration: InputDecoration(labelText: l10n.chatAppsMac),
                items: [for (final d in macs) DropdownMenuItem(value: d.computerId, child: Text(d.name))],
                onChanged: (v) => setState(() => _mac = v),
              );
            },
          ),
        TextField(
          key: const Key('channelSenders'),
          controller: _senders,
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.chatAppsSenders, helperText: l10n.chatAppsSendersHelp, helperMaxLines: 3),
        ),
      ],
    );
  }
}

/// After connecting: the address to paste into the provider, and Meta's verify token.
class _SetupDone extends StatelessWidget {
  const _SetupDone({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.circleCheck,
      title: l10n.chatAppsConnected(channel.name),
      subtitle: channel.kind == ChannelKind.telegram ? l10n.chatAppsTelegramDone : l10n.chatAppsPasteUrl,
      submitLabel: l10n.close,
      onSubmit: () => Navigator.pop(context),
      children: [
        if (channel.webhookUrl != null) _Copyable(label: l10n.chatAppsWebhookUrl, value: channel.webhookUrl!, keyName: 'webhookUrl'),
        if (channel.verifyToken != null) _Copyable(label: l10n.chatAppsVerifyToken, value: channel.verifyToken!, keyName: 'verifyToken'),
      ],
    );
  }
}

class _Copyable extends StatelessWidget {
  const _Copyable({required this.label, required this.value, required this.keyName});
  final String label;
  final String value;
  final String keyName;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: Row(
      children: [
        Expanded(child: SelectableText(value, key: Key(keyName))),
        IconButton(
          tooltip: context.l10n.copy,
          icon: const Icon(LucideIcons.copy, size: 18),
          onPressed: () => unawaited(Clipboard.setData(ClipboardData(text: value))),
        ),
      ],
    ),
  );
}

class _ChannelDetail extends ConsumerStatefulWidget {
  const _ChannelDetail({required this.botId, required this.channel});
  final String botId;
  final Channel channel;

  @override
  ConsumerState<_ChannelDetail> createState() => _ChannelDetailState();
}

class _ChannelDetailState extends ConsumerState<_ChannelDetail> {
  late final _senders = TextEditingController(text: widget.channel.allowedSenders.join('\n'));

  @override
  void dispose() {
    _senders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.channel;
    final backend = ref.read(backendProvider);
    return FormSheet(
      icon: channelIcon(c.kind),
      title: c.name,
      subtitle: channelKindName(c.kind),
      submitLabel: l10n.save,
      submitKey: const Key('saveSenders'),
      onSubmit: () async {
        final r = await runGuarded(context, () => backend.updateChannel(c.id, allowedSenders: _splitSenders(_senders.text)));
        ref.invalidate(channelsProvider(widget.botId));
        if (r != null && context.mounted) Navigator.pop(context);
      },
      children: [
        if (c.webhookUrl != null) _Copyable(label: l10n.chatAppsWebhookUrl, value: c.webhookUrl!, keyName: 'webhookUrl'),
        TextField(
          key: const Key('editSenders'),
          controller: _senders,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(labelText: l10n.chatAppsSenders, helperText: l10n.chatAppsSendersHelp, helperMaxLines: 3),
        ),
        SectionHeader(title: l10n.chatAppsActivity),
        ref
            .watch(channelEventsProvider(c.id))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (events) => events.isEmpty
                  ? FormNote(l10n.chatAppsNoActivity)
                  : Column(
                      children: [
                        for (final e in events)
                          ListTile(
                            key: Key('event-${e.id}'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(e.direction == ChannelEventDirectionEnum.in_ ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, size: 18),
                            title: Text([e.sender ?? '', e.preview ?? ''].where((s) => s.isNotEmpty).join(': '), maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(switch (e.status) {
                              ChannelEventStatusEnum.ignored => l10n.chatAppsIgnored,
                              ChannelEventStatusEnum.routine => l10n.chatAppsRoutine,
                              ChannelEventStatusEnum.failed => e.detail ?? l10n.chatAppsFailed,
                              ChannelEventStatusEnum.sent => l10n.chatAppsSent,
                              _ => l10n.chatAppsAnswered,
                            }),
                          ),
                      ],
                    ),
            ),
        TextButton.icon(
          key: const Key('deleteChannel'),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          icon: const Icon(LucideIcons.trash2, size: 18),
          label: Text(l10n.chatAppsRemove),
          onPressed: () async {
            await runGuarded(context, () => backend.deleteChannel(c.id));
            ref.invalidate(channelsProvider(widget.botId));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
