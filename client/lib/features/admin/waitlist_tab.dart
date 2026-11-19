import 'package:casama_sdk/casama_sdk.dart'
    show
        CreateInviteCampaignRequest,
        InviteCampaign,
        SignupGateModeEnum,
        UpdateInviteCampaignRequest,
        WaitlistEntry,
        WaitlistEntryStatusEnum;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// One page of the list: the search text and how many rows to load.
typedef AdminWaitlistQuery = ({String query, int limit});

final adminWaitlistProvider = FutureProvider.autoDispose
    .family<AdminWaitlist, AdminWaitlistQuery>(
      (r, q) => r
          .watch(backendProvider)
          .adminWaitlist(query: q.query, limit: q.limit),
    );

final adminInviteCampaignsProvider =
    FutureProvider.autoDispose<List<InviteCampaign>>(
      (r) => r.watch(backendProvider).adminInviteCampaigns(),
    );

/// Admin console > Waitlist (D-427, WAITLIST-PLAN §11 Phase 2): the gate switch and its settings,
/// the numbers that decide an admit, **Admit** the next in line, add addresses by hand, campaign
/// codes, and the list with search and paging. Switching the gate and admitting ask first.
class AdminWaitlistTab extends ConsumerStatefulWidget {
  const AdminWaitlistTab({super.key});

  @override
  ConsumerState<AdminWaitlistTab> createState() => _AdminWaitlistTabState();
}

class _AdminWaitlistTabState extends ConsumerState<AdminWaitlistTab> {
  static const _page = 50;
  final _search = TextEditingController();
  var _query = '';
  var _limit = _page;

  AdminWaitlistQuery get _key => (query: _query, limit: _limit);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminWaitlistProvider(_key));
    ref.invalidate(adminInviteCampaignsProvider);
  }

  // --- the gate --------------------------------------------------------------------------------

  Future<void> _setGate(Map<String, Object?> changes) async {
    final done = await runGuarded(
      context,
      () => ref.read(backendProvider).adminSetSignupGate(changes),
    );
    if (done == null || !mounted) return;
    showSuccess(context, context.l10n.saved);
    ref.invalidate(adminWaitlistProvider(_key));
  }

  Future<void> _switchGate(bool inviteOnly) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      icon: inviteOnly ? LucideIcons.lock : LucideIcons.lockOpen,
      title: inviteOnly ? l10n.adminGateCloseTitle : l10n.adminGateOpenTitle,
      message: inviteOnly ? l10n.adminGateCloseBody : l10n.adminGateOpenBody,
      confirmLabel: inviteOnly
          ? l10n.adminGateCloseConfirm
          : l10n.adminGateOpenConfirm,
      confirmKey: const Key('confirmSignupGate'),
    );
    if (!ok || !mounted) return;
    await _setGate({'mode': inviteOnly ? 'invite_only' : 'open'});
  }

  Future<void> _editNumber(
    String title,
    String field,
    int current, {
    int max = 100000,
  }) async {
    final l10n = context.l10n;
    final text = await showTextPrompt(
      context,
      title: title,
      label: title,
      submitLabel: l10n.save,
      initial: '$current',
      keyboardType: TextInputType.number,
      fieldKey: Key('gateField-$field'),
    );
    if (text == null || !mounted) return;
    final value = int.tryParse(text.trim());
    if (value == null || value < 0 || value > max) {
      showWarning(context, l10n.adminGateNumberInvalid);
      return;
    }
    if (value == current) return;
    await _setGate({field: value});
  }

  Future<void> _pickOpensAt(DateTime? current) async {
    final now = DateTime.now();
    final start = current?.toLocal() ?? now.add(const Duration(days: 1));
    final day = await showDatePicker(
      context: context,
      initialDate: start.isBefore(now) ? now : start,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null || !mounted) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    await _setGate({'opens_at': at.toUtc().toIso8601String()});
  }

  // --- letting people in -----------------------------------------------------------------------

  Future<void> _admit() async {
    final l10n = context.l10n;
    final text = await showTextPrompt(
      context,
      title: l10n.adminWaitlistAdmitPrompt,
      label: l10n.adminWaitlistAdmitCount,
      submitLabel: l10n.continueLabel,
      initial: '10',
      icon: LucideIcons.userCheck,
      keyboardType: TextInputType.number,
      fieldKey: const Key('admitCount'),
    );
    if (text == null || !mounted) return;
    final count = int.tryParse(text.trim());
    if (count == null || count < 1 || count > 5000) {
      showWarning(context, l10n.adminGateNumberInvalid);
      return;
    }
    final ok = await showConfirm(
      context: context,
      icon: LucideIcons.userCheck,
      title: l10n.adminWaitlistAdmitTitle(count),
      message: l10n.adminWaitlistAdmitBody,
      confirmLabel: l10n.adminWaitlistAdmit,
      confirmKey: const Key('confirmAdmit'),
    );
    if (!ok || !mounted) return;
    final admitted = await runGuarded(
      context,
      () => ref.read(backendProvider).adminAdmitWaitlist(count: count),
    );
    if (admitted == null || !mounted) return;
    showSuccess(context, l10n.adminWaitlistAdmitted(admitted));
    ref.invalidate(adminWaitlistProvider(_key));
  }

  Future<void> _add() async {
    final result = await showAdaptiveSheet<(List<String>, bool)>(
      context: context,
      builder: (_) => const _AddAddresses(),
    );
    if (result == null || !mounted) return;
    final changed = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .adminAddWaitlistEntries(result.$1, notify: result.$2),
    );
    if (changed == null || !mounted) return;
    final l10n = context.l10n;
    final skipped = changed.skipped ?? const [];
    showSuccess(
      context,
      [
        l10n.adminWaitlistAdded(changed.count),
        if (skipped.isNotEmpty) l10n.adminWaitlistSkipped(skipped.join(', ')),
      ].join(' '),
    );
    ref.invalidate(adminWaitlistProvider(_key));
  }

  Future<void> _remove(WaitlistEntry e) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.adminWaitlistRemoveTitle(e.email),
      message: l10n.adminWaitlistRemoveBody,
      confirmLabel: l10n.remove,
      destructive: true,
      confirmKey: const Key('confirmWaitlistRemove'),
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).adminRemoveWaitlistEntry(e.id);
      return true;
    });
    if (done == true) ref.invalidate(adminWaitlistProvider(_key));
  }

  // --- campaign codes --------------------------------------------------------------------------

  Future<void> _newCampaign() async {
    final request = await showAdaptiveSheet<CreateInviteCampaignRequest>(
      context: context,
      builder: (_) => const _NewCampaign(),
    );
    if (request == null || !mounted) return;
    final made = await runGuarded(
      context,
      () => ref.read(backendProvider).adminCreateInviteCampaign(request),
    );
    if (made != null) ref.invalidate(adminInviteCampaignsProvider);
  }

  Future<void> _toggleCampaign(InviteCampaign c) async {
    final done = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .adminUpdateInviteCampaign(
            c.code,
            UpdateInviteCampaignRequest(disabled: !c.disabled),
          ),
    );
    if (done != null) ref.invalidate(adminInviteCampaignsProvider);
  }

  Future<void> _copy(String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
    } catch (_) {
      return;
    }
    if (mounted) showMessage(context, context.l10n.adminCampaignCopied);
  }

  // --- the page --------------------------------------------------------------------------------

  String _status(WaitlistEntryStatusEnum s) {
    final l10n = context.l10n;
    return switch (s) {
      WaitlistEntryStatusEnum.waiting => l10n.adminWaitlistStatusWaiting,
      WaitlistEntryStatusEnum.queued => l10n.adminWaitlistStatusQueued,
      WaitlistEntryStatusEnum.admitted => l10n.adminWaitlistStatusAdmitted,
      WaitlistEntryStatusEnum.joined => l10n.adminWaitlistStatusJoined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AsyncView<AdminWaitlist>(
      value: ref.watch(adminWaitlistProvider(_key)),
      onRetry: _refresh,
      data: (w) {
        final s = w.stats;
        final gate = w.gate.gate;
        final muted = context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        );
        final campaigns = ref.watch(adminInviteCampaignsProvider);
        final lastBatch = w.lastBatch;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: PageColumn(
            children: [
              // The numbers that decide an admit, with the button beside them.
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  _Count(
                    key: const Key('waitlistWaiting'),
                    label: l10n.adminWaitlistWaiting,
                    value: '${s.waiting}',
                  ),
                  _Count(
                    label: l10n.adminWaitlistListedToday,
                    value: '${s.listedToday}',
                  ),
                  _Count(
                    key: const Key('waitlistAdmittedToday'),
                    label: l10n.adminWaitlistAdmittedToday,
                    value: '${s.admittedToday}',
                  ),
                  _Count(
                    label: l10n.adminWaitlistAdmittedTotal,
                    value: '${s.admitted}',
                  ),
                  _Count(label: l10n.adminWaitlistJoined, value: '${s.joined}'),
                  _Count(
                    label: l10n.adminWaitlistFirstChat,
                    value: '${s.firstChat}',
                  ),
                  _Count(
                    key: const Key('waitlistEmailsToday'),
                    label: l10n.adminWaitlistEmailsToday,
                    value: l10n.adminWaitlistEmailsOf(
                      s.emailsToday,
                      gate.dailyEmailsMax,
                    ),
                  ),
                  if (lastBatch != null)
                    _Count(
                      key: const Key('waitlistLastBatch'),
                      label: [
                        l10n.adminWaitlistLastBatch,
                        if (lastBatch.at != null)
                          lastBatch.at!.toLocal().formattedDate(context),
                      ].join(' · '),
                      value: lastBatch.skippedDetail != null
                          ? l10n.adminWaitlistLastBatchSkipped(lastBatch.skippedDetail!)
                          : lastBatch.count == null
                          ? '—'
                          : l10n.adminWaitlistLastBatchValue(lastBatch.count!),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  FilledButton.icon(
                    key: const Key('waitlistAdmit'),
                    onPressed: _admit,
                    icon: const Icon(LucideIcons.userCheck, size: 18),
                    label: Text(l10n.adminWaitlistAdmit),
                  ),
                  OutlinedButton.icon(
                    key: const Key('waitlistAdd'),
                    onPressed: _add,
                    icon: const Icon(LucideIcons.userPlus, size: 18),
                    label: Text(l10n.adminWaitlistAdd),
                  ),
                ],
              ),
              SectionHeader(title: l10n.adminGate),
              GroupedCard(
                children: [
                  GroupedTile(
                    key: const Key('signupGateTile'),
                    icon: w.gate.closed
                        ? LucideIcons.lock
                        : LucideIcons.lockOpen,
                    title: l10n.adminGateInviteOnly,
                    subtitle: [
                      w.gate.closed
                          ? l10n.adminGateClosedNow
                          : l10n.adminGateOpenNow,
                      l10n.adminGateInviteOnlyHelp,
                    ].join(' · '),
                    showChevron: false,
                    trailing: Switch(
                      key: const Key('signupGateSwitch'),
                      value: gate.mode == SignupGateModeEnum.inviteOnly,
                      onChanged: _switchGate,
                    ),
                  ),
                  GroupedTile(
                    key: const Key('gateOpensAt'),
                    icon: LucideIcons.calendarClock,
                    title: l10n.adminGateOpensAt,
                    subtitle: gate.opensAt == null
                        ? l10n.adminGateOpensAtNone
                        : '${gate.opensAt!.toLocal().formattedDate(context)} ${TimeOfDay.fromDateTime(gate.opensAt!.toLocal()).format(context)}',
                    onTap: () => _pickOpensAt(gate.opensAt),
                    trailing: gate.opensAt == null
                        ? null
                        : TextButton(
                            key: const Key('gateClearOpensAt'),
                            onPressed: () => _setGate({'opens_at': null}),
                            child: Text(l10n.adminGateClearOpensAt),
                          ),
                  ),
                  _NumberTile(
                    key: const Key('gateInvites'),
                    icon: LucideIcons.ticket,
                    title: l10n.adminGateInvites,
                    value: '${gate.invitesPerPerson}',
                    onTap: () => _editNumber(
                      l10n.adminGateInvites,
                      'invites_per_person',
                      gate.invitesPerPerson,
                      max: 100,
                    ),
                  ),
                  _NumberTile(
                    key: const Key('gateDailyAdmit'),
                    icon: LucideIcons.calendarCheck,
                    title: l10n.adminGateDailyAdmit,
                    value: gate.dailyAdmit == 0
                        ? l10n.adminGateDailyAdmitOff
                        : '${gate.dailyAdmit}',
                    onTap: () => _editNumber(
                      l10n.adminGateDailyAdmit,
                      'daily_admit',
                      gate.dailyAdmit,
                      max: 10000,
                    ),
                  ),
                  _NumberTile(
                    key: const Key('gateDailyEmails'),
                    icon: LucideIcons.mail,
                    title: l10n.adminGateDailyEmails,
                    value: '${gate.dailyEmailsMax}',
                    onTap: () => _editNumber(
                      l10n.adminGateDailyEmails,
                      'daily_emails_max',
                      gate.dailyEmailsMax,
                    ),
                  ),
                  // Newer servers only: the hour the daily batch runs.
                  if (w.gate.batchHourUtc case final hour?)
                    _NumberTile(
                      key: const Key('gateBatchHour'),
                      icon: LucideIcons.clock,
                      title: l10n.adminGateBatchHour,
                      value: l10n.adminGateBatchHourValue(
                        hour.toString().padLeft(2, '0'),
                      ),
                      onTap: () => _editNumber(
                        l10n.adminGateBatchHour,
                        'batch_hour_utc',
                        hour,
                        max: 23,
                      ),
                    ),
                ],
              ),
              if (s.bySource.isNotEmpty) ...[
                SectionHeader(title: l10n.adminWaitlistBySource),
                GroupedCard(
                  children: [
                    for (final f in s.bySource)
                      GroupedTile(
                        key: Key('waitlistSource-${f.key}'),
                        icon: LucideIcons.signpost,
                        title: f.key,
                        subtitle: l10n.adminWaitlistSourceRow(
                          f.listed,
                          f.admitted,
                          f.joined,
                          f.firstChat,
                        ),
                        showChevron: false,
                      ),
                  ],
                ),
              ],
              SectionHeader(
                title: l10n.adminCampaigns,
                trailing: TextButton.icon(
                  key: const Key('campaignNew'),
                  onPressed: _newCampaign,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(l10n.adminCampaignNew),
                ),
              ),
              switch (campaigns) {
                AsyncData(:final value) when value.isEmpty => Text(
                  l10n.adminCampaignNone,
                  style: muted,
                ),
                AsyncData(:final value) => GroupedCard(
                  children: [for (final c in value) _campaignTile(context, c)],
                ),
                AsyncError(:final error) => Text(
                  errorText(context, error),
                  style: muted,
                ),
                _ => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpace.md),
                    child: CircularProgressIndicator(),
                  ),
                ),
              },
              SectionHeader(title: l10n.adminWaitlistPeople),
              TextField(
                key: const Key('waitlistSearch'),
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.adminWaitlistSearch,
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  isDense: true,
                ),
                onSubmitted: (v) => setState(() {
                  _query = v.trim();
                  _limit = _page;
                }),
              ),
              const SizedBox(height: AppSpace.sm),
              if (w.items.isEmpty)
                Text(l10n.adminWaitlistNone, style: muted)
              else
                GroupedCard(
                  children: [
                    for (final e in w.items)
                      GroupedTile(
                        key: Key('waitlistEntry-${e.id}'),
                        icon: e.status == WaitlistEntryStatusEnum.waiting
                            ? LucideIcons.hourglass
                            : LucideIcons.userCheck,
                        iconColor: e.status == WaitlistEntryStatusEnum.waiting
                            ? null
                            : context.appColors.positive,
                        title: e.email,
                        subtitle: [
                          _status(e.status),
                          ?e.source_,
                          ?e.admittedVia,
                          if (e.selfHosting) l10n.adminWaitlistSelfHosts,
                          e.createdAt.toLocal().formattedDate(context),
                          if (e.note != null && e.note!.trim().isNotEmpty)
                            '"${e.note!.trim()}"',
                        ].join(' · '),
                        showChevron: false,
                        trailing: IconButton(
                          key: Key('waitlistRemove-${e.id}'),
                          tooltip: l10n.remove,
                          onPressed: () => _remove(e),
                          icon: const Icon(LucideIcons.trash2, size: 18),
                        ),
                      ),
                  ],
                ),
              if (w.items.length >= _limit)
                Center(
                  child: TextButton(
                    key: const Key('waitlistMore'),
                    onPressed: () => setState(() => _limit += _page),
                    child: Text(l10n.adminWaitlistShowMore),
                  ),
                ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _campaignTile(BuildContext context, InviteCampaign c) {
    final l10n = context.l10n;
    return GroupedTile(
      key: Key('campaign-${c.code}'),
      icon: c.disabled ? LucideIcons.ban : LucideIcons.ticket,
      iconColor: c.disabled ? context.colorScheme.onSurfaceVariant : null,
      title: '${c.code} · ${c.label}',
      subtitle: [
        l10n.adminCampaignUsed(c.used, c.maxUses),
        if (c.perDay != null) l10n.adminCampaignPerDayShort(c.perDay!),
        if (c.startsAt != null)
          l10n.adminCampaignStartsOn(
            c.startsAt!.toLocal().formattedDate(context),
          ),
        if (c.expiresAt != null)
          l10n.adminCampaignEndsOn(
            c.expiresAt!.toLocal().formattedDate(context),
          ),
        if (c.disabled) l10n.adminCampaignOff,
      ].join(' · '),
      showChevron: false,
      onTap: () => _copy(c.link),
      trailing: TextButton(
        key: Key('campaignToggle-${c.code}'),
        onPressed: () => _toggleCampaign(c),
        child: Text(
          c.disabled ? l10n.adminCampaignTurnOn : l10n.adminCampaignTurnOff,
        ),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GroupedTile(
      icon: icon,
      title: title,
      onTap: onTap,
      showChevron: true,
      trailing: Text(
        value,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontFeatures: AppText.tabular,
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: AppText.tabular,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Addresses typed or pasted by hand, and whether they get the "You're in" email.
class _AddAddresses extends StatefulWidget {
  const _AddAddresses();

  @override
  State<_AddAddresses> createState() => _AddAddressesState();
}

class _AddAddressesState extends State<_AddAddresses> {
  final _emails = TextEditingController();
  var _notify = false;

  @override
  void dispose() {
    _emails.dispose();
    super.dispose();
  }

  List<String> get _list => _emails.text
      .split(RegExp(r'[\s,;]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.userPlus,
      title: l10n.adminWaitlistAdd,
      subtitle: l10n.adminWaitlistAddHelp,
      submitLabel: l10n.adminWaitlistAdd,
      submitKey: const Key('waitlistAddSubmit'),
      onSubmit: () {
        final list = _list;
        if (list.isEmpty) return;
        Navigator.pop(context, (list, _notify));
      },
      children: [
        TextField(
          key: const Key('waitlistAddEmails'),
          controller: _emails,
          autofocus: true,
          autocorrect: false,
          keyboardType: TextInputType.multiline,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: l10n.adminWaitlistAddLabel,
            hintText: 'ana@example.com\nben@example.com',
            alignLabelWithHint: true,
          ),
        ),
        FormSwitch(
          key: const Key('waitlistAddNotify'),
          icon: LucideIcons.mail,
          title: l10n.adminWaitlistAddNotify,
          value: _notify,
          onChanged: (v) => setState(() => _notify = v),
        ),
      ],
    );
  }
}

/// A new campaign code: code, label, total, an optional number a day, start and end.
class _NewCampaign extends StatefulWidget {
  const _NewCampaign();

  @override
  State<_NewCampaign> createState() => _NewCampaignState();
}

class _NewCampaignState extends State<_NewCampaign> {
  final _code = TextEditingController();
  final _label = TextEditingController();
  final _total = TextEditingController(text: '100');
  final _perDay = TextEditingController();
  DateTime? _starts;
  DateTime? _ends;
  String? _codeError;

  /// The server's rule (§7.2): letters, digits and hyphens; 9 or more characters or a hyphen, so it
  /// never looks like a 6-character personal code or an 8-character workspace code.
  static bool _validCode(String c) =>
      RegExp(r'^[A-Za-z0-9-]{4,32}$').hasMatch(c) &&
      (c.length >= 9 || c.contains('-'));

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    _total.dispose();
    _perDay.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final now = DateTime.now();
    final current = start ? _starts : _ends;
    final day = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (day == null || !mounted) return;
    setState(() => start ? _starts = day : _ends = day);
  }

  void _submit() {
    final code = _code.text.trim().toUpperCase();
    final total = int.tryParse(_total.text.trim());
    final perDay = _perDay.text.trim().isEmpty
        ? null
        : int.tryParse(_perDay.text.trim());
    if (!_validCode(code)) {
      setState(() => _codeError = context.l10n.adminCampaignCodeHelp);
      return;
    }
    if (_label.text.trim().isEmpty ||
        total == null ||
        total < 0 ||
        (_perDay.text.trim().isNotEmpty && (perDay == null || perDay < 1))) {
      showWarning(context, context.l10n.adminGateNumberInvalid);
      return;
    }
    Navigator.pop(
      context,
      CreateInviteCampaignRequest(
        code: code,
        label: _label.text.trim(),
        maxUses: total,
        perDay: perDay,
        // Whole days in this device's time: from the start of the first, to the end of the last.
        startsAt: _starts?.toUtc(),
        expiresAt: _ends
            ?.add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1))
            .toUtc(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String day(DateTime? d) =>
        d == null ? l10n.adminCampaignAnyTime : d.formattedDate(context);
    return FormSheet(
      icon: LucideIcons.ticket,
      title: l10n.adminCampaignNew,
      submitLabel: l10n.adminCampaignCreate,
      submitKey: const Key('campaignCreate'),
      onSubmit: _submit,
      children: [
        TextField(
          key: const Key('campaignCode'),
          controller: _code,
          autofocus: true,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: l10n.adminCampaignCode,
            hintText: 'SHOWHN-DEC8',
            helperText: _codeError == null ? l10n.adminCampaignCodeHelp : null,
            helperMaxLines: 3,
            errorText: _codeError,
            errorMaxLines: 3,
          ),
          onChanged: (_) {
            if (_codeError != null) setState(() => _codeError = null);
          },
        ),
        TextField(
          key: const Key('campaignLabel'),
          controller: _label,
          decoration: InputDecoration(labelText: l10n.adminCampaignLabel),
        ),
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: TextField(
                key: const Key('campaignTotal'),
                controller: _total,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.adminCampaignTotal),
              ),
            ),
            Expanded(
              child: TextField(
                key: const Key('campaignPerDay'),
                controller: _perDay,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.adminCampaignPerDay,
                ),
              ),
            ),
          ],
        ),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('campaignStarts'),
              icon: LucideIcons.calendarPlus,
              title: l10n.adminCampaignStarts,
              trailing: Text(day(_starts)),
              onTap: () => _pick(true),
            ),
            GroupedTile(
              key: const Key('campaignEnds'),
              icon: LucideIcons.calendarX,
              title: l10n.adminCampaignEnds,
              trailing: Text(day(_ends)),
              onTap: () => _pick(false),
            ),
          ],
        ),
      ],
    );
  }
}
