import 'package:flutter/services.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/date_format.dart';

final _campaigns = FutureProvider.autoDispose(
  (ref) async =>
      (await ref.watch(backendProvider).limitResets.adminLimitResetCampaigns())
          .data!,
);
final _settings = FutureProvider.autoDispose(
  (ref) async =>
      (await ref.watch(backendProvider).limitResets.adminLimitResetSettings())
          .data!,
);

class ResetsTab extends ConsumerWidget {
  const ResetsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(_settings).value;
    final campaigns = ref.watch(_campaigns);
    final words = context.l10n;
    Future<void> refresh(Future<void> Function() action) async {
      await runGuarded(context, action);
      ref.invalidate(_campaigns);
      ref.invalidate(_settings);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (settings != null) ...[
          SwitchListTile(
            title: Text(words.resetsEnabled),
            value: settings.enabled,
            onChanged: (value) => refresh(() async {
              await ref
                  .read(backendProvider)
                  .limitResets
                  .setAdminLimitResetSettings(
                    limitResetSettings: LimitResetSettings(
                      enabled: value,
                      perPeriod: settings.perPeriod,
                      maxHeld: settings.maxHeld,
                      notifyOwners: settings.notifyOwners,
                    ),
                  );
            }),
          ),
          for (final setting in [
            (words.resetsPerPeriod, settings.perPeriod.toInt(), true),
            (words.resetsMaxHeld, settings.maxHeld.toInt(), false),
          ])
            ListTile(
              title: Text(setting.$1),
              trailing: SizedBox(
                width: 120,
                child: TextFormField(
                  initialValue: '${setting.$2}',
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (text) => refresh(() async {
                    final value = int.parse(text);
                    await ref
                        .read(backendProvider)
                        .limitResets
                        .setAdminLimitResetSettings(
                          limitResetSettings: LimitResetSettings(
                            enabled: settings.enabled,
                            perPeriod: setting.$3 ? value : settings.perPeriod,
                            maxHeld: setting.$3 ? settings.maxHeld : value,
                            notifyOwners: settings.notifyOwners,
                          ),
                        );
                  }),
                ),
              ),
            ),
          SwitchListTile(
            title: Text(words.resetsNotifyOwners),
            value: settings.notifyOwners,
            onChanged: (value) => refresh(() async {
              await ref
                  .read(backendProvider)
                  .limitResets
                  .setAdminLimitResetSettings(
                    limitResetSettings: LimitResetSettings(
                      enabled: settings.enabled,
                      perPeriod: settings.perPeriod,
                      maxHeld: settings.maxHeld,
                      notifyOwners: value,
                    ),
                  );
            }),
          ),
        ],
        FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _Editor(),
          ).then((_) => ref.invalidate(_campaigns)),
          child: Text(words.resetsNewCampaign),
        ),
        const _WorkspaceResets(),
        if (campaigns.isLoading) const LinearProgressIndicator(),
        if (campaigns.hasError) Text('${campaigns.error}'),
        for (final campaign in campaigns.value ?? <LimitResetCampaign>[])
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${campaign.name} · ${campaign.state}'),
                  Text(campaign.message),
                  Text(
                    words.savedResetExpiry(
                      campaign.expiresAt.toLocal().formattedExact(context),
                    ),
                  ),
                  Text(
                    words.resetsCampaignCounts(
                      campaign.given.toInt(),
                      campaign.used.toInt(),
                      campaign.refilledUsd.toStringAsFixed(2),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if ([
                        'draft',
                        'scheduled',
                        'live',
                        'paused',
                      ].contains(campaign.state))
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => _Editor(campaign: campaign),
                          ).then((_) => ref.invalidate(_campaigns)),
                          child: Text(words.edit),
                        ),
                      for (final action in switch (campaign.state) {
                        'draft' => ['schedule', 'cancel', 'delete'],
                        'live' => ['pause', 'cancel'],
                        'paused' => ['resume', 'cancel'],
                        'scheduled' => ['cancel'],
                        _ => <String>[],
                      })
                        TextButton(
                          onPressed: () => refresh(() async {
                            await ref
                                .read(backendProvider)
                                .limitResets
                                .actionAdminLimitResetCampaign(
                                  id: campaign.id,
                                  actionAdminLimitResetCampaignRequest:
                                      ActionAdminLimitResetCampaignRequest(
                                        action:
                                            ActionAdminLimitResetCampaignRequestActionEnum
                                                .values
                                                .firstWhere(
                                                  (v) => v.value == action,
                                                ),
                                      ),
                                );
                          }),
                          child: Text(switch (action) {
                            'schedule' => words.resetsSchedule,
                            'pause' => words.resetsPause,
                            'resume' => words.resetsResume,
                            'cancel' => words.cancel,
                            _ => words.delete,
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({this.campaign, this.workspace});
  final LimitResetCampaign? campaign;
  final String? workspace;
  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final fields = <String, TextEditingController>{};
  bool daily = true,
      computer = false,
      arrival = true,
      reminder = true,
      busy = false;
  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    final values = <String, String>{
      'name': c?.name ?? '',
      'message': c?.message ?? '',
      'plans':
          widget.workspace != null ? '' : c?.audience.planCodes?.join(',') ??
          'plus,plus_yearly,pro,pro_yearly,max,max_yearly',
      'workspaces': widget.workspace ?? c?.audience.workspaceIds?.join(',') ?? '',
      'before': c?.audience.createdBefore?.toIso8601String() ?? '',
      'days': '${c?.audience.limitedWithinDays ?? ''}',
      'start': (c?.startsAt ?? DateTime.now()).toIso8601String(),
      'expiry': (c?.expiresAt ?? DateTime.now().add(const Duration(days: 14)))
          .toIso8601String(),
      'percent': '${c?.refillPercent ?? 100}',
      'cap': '${c?.maxPerUseUsd ?? ''}',
      'budget': '${c?.budgetUsd ?? ''}',
    };
    for (final e in values.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
    daily = c?.resetDaily ?? true;
    computer = c?.resetComputer ?? false;
    arrival = c?.notifyArrival ?? true;
    reminder = c?.notifyReminder ?? true;
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.l10n;
    final locked = ['live', 'paused'].contains(widget.campaign?.state);
    final labels = {
      'name': w.resetsName,
      'message': w.resetsMessage,
      'plans': w.resetsPlans,
      'workspaces': w.resetsWorkspaces,
      'before': w.resetsBefore,
      'days': w.resetsLimitedDays,
      'start': w.resetsStart,
      'expiry': w.resetsExpiry,
      'percent': w.resetsPercent,
      'cap': w.resetsCap,
      'budget': w.resetsBudget,
    };
    return AlertDialog(
      title: Text(w.resetsNewCampaign),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in fields.entries)
                TextField(
                  controller: e.value,
                  enabled:
                      !locked ||
                      ['message', 'expiry', 'budget'].contains(e.key),
                  decoration: InputDecoration(labelText: labels[e.key]),
                ),
              SwitchListTile(
                title: Text(w.resetsDaily),
                value: daily,
                onChanged: locked ? null : (v) => setState(() => daily = v),
              ),
              SwitchListTile(
                title: Text(w.resetsComputer),
                value: computer,
                onChanged: locked ? null : (v) => setState(() => computer = v),
              ),
              SwitchListTile(
                title: Text(w.resetsArrival),
                value: arrival,
                onChanged: locked ? null : (v) => setState(() => arrival = v),
              ),
              SwitchListTile(
                title: Text(w.resetsReminder),
                value: reminder,
                onChanged: (v) => setState(() => reminder = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(w.cancel),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  await runGuarded(context, () async {
                    String value(String key) => fields[key]!.text.trim();
                    List<String> list(String key) =>
                        value(key)
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                    final input = LimitResetCampaignInput(
                      name: value('name'),
                      message: value('message'),
                      audience: LimitResetAudience(
                        planCodes: widget.workspace == null ? list('plans') : [],
                        workspaceIds: widget.workspace == null ? list('workspaces') : [widget.workspace!],
                        createdBefore: value('before').isEmpty
                            ? null
                            : DateTime.parse(value('before')),
                        limitedWithinDays: int.tryParse(value('days')),
                      ),
                      startsAt: DateTime.parse(value('start')),
                      expiresAt: DateTime.parse(value('expiry')),
                      refillPercent: int.parse(value('percent')),
                      maxPerUseUsd: num.tryParse(value('cap')),
                      budgetUsd: num.tryParse(value('budget')),
                      resetDaily: daily,
                      resetComputer: computer,
                      notifyArrival: arrival,
                      notifyReminder: reminder,
                    );
                    final api = ref.read(backendProvider).limitResets;
                    final preview = (await api.previewAdminLimitResetCampaign(
                      limitResetCampaignInput: input,
                    )).data!;
                    if (!context.mounted) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(
                          w.resetsPreview(
                            preview.workspaces.toInt(),
                            preview.creditsUsd.toStringAsFixed(2),
                            preview.costUsd.toStringAsFixed(2),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(w.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(w.save),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    if (widget.campaign == null) {
                      if (widget.workspace == null) {
                        await api.createAdminLimitResetCampaign(
                          limitResetCampaignInput: input,
                        );
                      } else {
                        await api.giveAdminWorkspaceLimitReset(
                          id: widget.workspace!,
                          limitResetCampaignInput: input,
                        );
                      }
                    } else {
                      await api.updateAdminLimitResetCampaign(
                        id: widget.campaign!.id,
                        limitResetCampaignInput: input,
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  });
                  if (mounted) setState(() => busy = false);
                },
          child: Text(w.resetsPreviewSave),
        ),
      ],
    );
  }
}

class _WorkspaceResets extends ConsumerStatefulWidget {
  const _WorkspaceResets();
  @override
  ConsumerState<_WorkspaceResets> createState() => _WorkspaceResetsState();
}

class _WorkspaceResetsState extends ConsumerState<_WorkspaceResets> {
  final workspace = TextEditingController();
  List<LimitResetEvent> events = [];
  @override
  void dispose() {
    workspace.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final api = ref.read(backendProvider).limitResets;
    final data = (await api.adminLimitResetEvents(
      orgId: workspace.text.trim().isEmpty ? null : workspace.text.trim(),
      limit: 1000,
    )).data!;
    if (mounted) setState(() => events = data);
  }

  @override
  Widget build(BuildContext context) {
    final w = context.l10n;
    return Column(
      children: [
        TextField(
          controller: workspace,
          decoration: InputDecoration(labelText: w.resetsWorkspace),
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: () => runGuarded(context, load),
              child: Text(w.resetsHistory),
            ),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _Editor(workspace: workspace.text.trim()),
              ),
              child: Text(w.resetsGive),
            ),
            TextButton(
              onPressed: events.isEmpty
                  ? null
                  : () async {
                      final csv =
                          (await ref
                                  .read(backendProvider)
                                  .limitResets
                                  .exportAdminLimitResetEvents(
                                    orgId: workspace.text.trim().isEmpty
                                        ? null
                                        : workspace.text.trim(),
                                  ))
                              .data!;
                      await Clipboard.setData(ClipboardData(text: csv));
                    },
              child: Text(w.resetsCopyCsv),
            ),
          ],
        ),
        for (final e in events)
          ListTile(
            title: Text(e.action),
            subtitle: Text(
              '${e.createdAt.toLocal().formattedExact(context)} · ${e.orgId ?? ''}',
            ),
            trailing: e.resetId == null || !['given', 'used'].contains(e.action)
                ? null
                : TextButton(
                    onPressed: () => runGuarded(context, () async {
                      await ref
                          .read(backendProvider)
                          .limitResets
                          .actionAdminWorkspaceLimitReset(
                            id: e.resetId!,
                            actionAdminWorkspaceLimitResetRequest:
                                ActionAdminWorkspaceLimitResetRequest(
                                  action: e.action == 'given'
                                      ? ActionAdminWorkspaceLimitResetRequestActionEnum
                                            .revoke
                                      : ActionAdminWorkspaceLimitResetRequestActionEnum
                                            .undo,
                                ),
                          );
                      await load();
                    }),
                    child: Text(
                      e.action == 'given' ? w.resetsRevoke : w.resetsUndo,
                    ),
                  ),
          ),
      ],
    );
  }
}
