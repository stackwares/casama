import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';

/// A bought domain's DNS records, read live from the registrar.
final domainRecordsProvider = FutureProvider.autoDispose
    .family<List<DnsRecordItem>, String>(
      (ref, domainId) => ref.watch(backendProvider).domainRecords(domainId),
    );

/// The record types people can add (SITES-AND-DOMAINS-PLAN §7.9).
const dnsRecordTypes = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV'];

/// DNS Records (`/settings/domains/:id/records`): list, add, change and delete a bought domain's
/// records. The ones the Casama site uses are shown locked.
class DomainRecordsScreen extends ConsumerWidget {
  const DomainRecordsScreen({
    super.key,
    required this.domainId,
    this.domainName,
  });
  final String domainId;

  /// The domain's name, for the host field's help (bakery.com).
  final String? domainName;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    DnsRecordItem? record,
  ]) async {
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      builder: (_) => _RecordForm(
        domainId: domainId,
        domainName: domainName,
        record: record,
      ),
    );
    if (saved == true) ref.invalidate(domainRecordsProvider(domainId));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DnsRecordItem r,
  ) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.dnsRecordDeleteTitle,
      message: l10n.dnsRecordDeleteBody(r.type, _hostLabel(r.host), r.answer),
      confirmLabel: l10n.delete,
      destructive: true,
      confirmKey: const Key('confirmDeleteRecord'),
    );
    if (!ok || !context.mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).deleteDomainRecord(domainId, r.id);
      return true;
    });
    if (done == true) ref.invalidate(domainRecordsProvider(domainId));
  }

  String _hostLabel(String host) => host.isEmpty ? (domainName ?? '@') : host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    void add() => _edit(context, ref);
    return SubPage(
      title: l10n.domainDnsRecords,
      actions: [
        HeaderIconButton(
          icon: LucideIcons.plus,
          tooltip: l10n.dnsRecordAdd,
          onPressed: add,
        ),
      ],
      body: AsyncView(
        value: ref.watch(domainRecordsProvider(domainId)),
        onRetry: () => ref.invalidate(domainRecordsProvider(domainId)),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(domainRecordsProvider(domainId).future),
          child: PageColumn(
            children: [
              if (items.isEmpty)
                Text(
                  l10n.dnsRecordsEmpty,
                  key: const Key('dnsRecordsEmpty'),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                GroupedCard(
                  children: [
                    for (final r in items)
                      GroupedTile(
                        key: Key('dnsRecord-${r.id}'),
                        icon: r.managed ? LucideIcons.lock : LucideIcons.server,
                        title: '${r.type}  ${_hostLabel(r.host)}',
                        subtitle: [
                          r.priority == null
                              ? r.answer
                              : '${r.priority} ${r.answer}',
                          if (r.managed) l10n.dnsRecordManaged,
                        ].join('\n'),
                        showChevron: false,
                        onTap: r.managed ? null : () => _edit(context, ref, r),
                        trailing: r.managed
                            ? null
                            : IconButton(
                                key: Key('dnsRecordDelete-${r.id}'),
                                tooltip: l10n.delete,
                                icon: Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                                onPressed: () => _delete(context, ref, r),
                              ),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpace.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: GlowButton.icon(
                  key: const Key('dnsRecordAdd'),
                  onPressed: add,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(l10n.dnsRecordAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adds a record, or changes [record]. It saves itself, so the server's words about a record it
/// refuses (`invalid_record`) show under the fields and the sheet stays open.
class _RecordForm extends ConsumerStatefulWidget {
  const _RecordForm({
    required this.domainId,
    required this.domainName,
    this.record,
  });
  final String domainId;
  final String? domainName;
  final DnsRecordItem? record;

  @override
  ConsumerState<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends ConsumerState<_RecordForm> {
  late String _type = dnsRecordTypes.contains(widget.record?.type)
      ? widget.record!.type
      : 'A';
  late final _host = TextEditingController(text: widget.record?.host ?? '');
  late final _answer = TextEditingController(text: widget.record?.answer ?? '');
  late final _ttl = TextEditingController(text: '${widget.record?.ttl ?? 300}');
  late final _priority = TextEditingController(
    text: widget.record?.priority?.toString() ?? '10',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _host.dispose();
    _answer.dispose();
    _ttl.dispose();
    _priority.dispose();
    super.dispose();
  }

  bool get _hasPriority => _type == 'MX' || _type == 'SRV';

  Future<void> _save() async {
    final l10n = context.l10n;
    final ttl = int.tryParse(_ttl.text.trim());
    if (_answer.text.trim().isEmpty) {
      setState(() => _error = l10n.dnsRecordAnswerRequired);
      return;
    }
    if (ttl == null || ttl < 300) {
      setState(() => _error = l10n.dnsRecordTtlInvalid);
      return;
    }
    final priority = _hasPriority ? int.tryParse(_priority.text.trim()) : null;
    setState(() {
      _busy = true;
      _error = null;
    });
    final backend = ref.read(backendProvider);
    final host = _host.text.trim();
    final answer = _answer.text.trim();
    try {
      final old = widget.record;
      if (old == null) {
        await backend.addDomainRecord(
          widget.domainId,
          DnsRecordInput(
            host: host,
            type: _type,
            answer: answer,
            ttl: ttl,
            priority: priority,
          ),
        );
      } else {
        await backend.updateDomainRecord(
          widget.domainId,
          old.id,
          DnsRecordPatch(
            host: host,
            type: _type,
            answer: answer,
            ttl: ttl,
            priority: priority,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.server,
      title: widget.record == null ? l10n.dnsRecordAdd : l10n.dnsRecordEdit,
      submitLabel: l10n.dnsRecordSave,
      submitKey: const Key('dnsRecordSave'),
      busy: _busy,
      onSubmit: _save,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('dnsRecordType'),
          initialValue: _type,
          decoration: InputDecoration(labelText: l10n.dnsRecordType),
          items: [
            for (final t in dnsRecordTypes)
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => _type = v ?? _type),
        ),
        TextField(
          key: const Key('dnsRecordHost'),
          controller: _host,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l10n.dnsRecordHost,
            helperText: l10n.dnsRecordHostHelp(widget.domainName ?? '@'),
            helperMaxLines: 2,
          ),
        ),
        TextField(
          key: const Key('dnsRecordAnswer'),
          controller: _answer,
          autocorrect: false,
          enableSuggestions: false,
          minLines: 1,
          maxLines: _type == 'TXT' ? 4 : 1,
          decoration: InputDecoration(labelText: l10n.dnsRecordAnswer),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('dnsRecordTtl'),
                controller: _ttl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.dnsRecordTtl),
              ),
            ),
            if (_hasPriority) ...[
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: TextField(
                  key: const Key('dnsRecordPriority'),
                  controller: _priority,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.dnsRecordPriority,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_error != null)
          Text(
            _error!,
            key: const Key('dnsRecordError'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
