import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'device_labels.dart';
import 'device_sync.dart';

class _DeviceState {
  const _DeviceState({required this.key, required this.sources, required this.grants});
  final String key;
  final List<DeviceSource> sources;
  final List<DeviceGrant> grants;
  DeviceSource? get mine => sources.where((s) => s.deviceKey == key).firstOrNull;
}

final _deviceStateProvider = FutureProvider.autoDispose<_DeviceState>((ref) async {
  final backend = ref.watch(backendProvider);
  final sync = ref.watch(deviceSyncProvider);
  final results = await Future.wait([sync.deviceKey(), backend.deviceSources(), backend.deviceGrants()]);
  return _DeviceState(key: results[0] as String, sources: results[1] as List<DeviceSource>, grants: results[2] as List<DeviceGrant>);
});

/// Settings → Device connections (D-149): what this device shares, for how long, and which bots
/// may read each kind.
class DeviceConnectionsScreen extends ConsumerStatefulWidget {
  const DeviceConnectionsScreen({super.key});
  @override
  ConsumerState<DeviceConnectionsScreen> createState() => _DeviceConnectionsScreenState();
}

class _DeviceConnectionsScreenState extends ConsumerState<DeviceConnectionsScreen> {
  final _busy = <DeviceKind>{};

  Future<void> _toggle(DeviceKind kind, bool on) async {
    setState(() => _busy.add(kind));
    final l10n = context.l10n;
    final ok = await runGuarded(context, () => ref.read(deviceSyncProvider).setKind(kind, on));
    if (!mounted) return;
    setState(() => _busy.remove(kind));
    if (ok == false) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.devicePermissionDenied)));
    ref.invalidate(_deviceStateProvider);
  }

  Future<void> _settings(DeviceKind kind, DeviceKindSettings settings) async {
    await runGuarded(context, () => ref.read(deviceSyncProvider).setKind(kind, true, settings: settings));
    ref.invalidate(_deviceStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final supported = ref.watch(deviceCollectorProvider).supported;
    return SubPage(
      title: l10n.deviceConnections,
      body: AsyncView(
        value: ref.watch(_deviceStateProvider),
        onRetry: () => ref.invalidate(_deviceStateProvider),
        data: (st) {
          final others = st.sources.where((s) => s.deviceKey != st.key).toList();
          return PageColumn(
            children: [
              FormNote(l10n.deviceConnectionsHelp, icon: LucideIcons.shieldCheck),
              const SizedBox(height: AppSpace.md),
              if (supported.isEmpty)
                EmptyState(icon: LucideIcons.smartphone, title: l10n.deviceConnections, message: l10n.deviceConnectionsNone)
              else
                for (final kind in DeviceKind.values.where(supported.contains)) ...[
                  _KindCard(
                    kind: kind,
                    settings: st.mine?.kinds[kind.value],
                    busy: _busy.contains(kind),
                    grants: st.grants.where((g) => g.kind == kind).toList(),
                    onToggle: (on) => _toggle(kind, on),
                    onSettings: (s) => _settings(kind, s),
                    onRevoke: (g) async {
                      await runGuarded(context, () => ref.read(backendProvider).setDeviceGrant(g.botId, g.kind, false));
                      ref.invalidate(_deviceStateProvider);
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              if (others.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                SectionHeader(title: l10n.deviceOtherDevices),
                GroupedCard(
                  children: [
                    for (final s in others)
                      GroupedTile(
                        key: Key('otherDevice-${s.deviceKey}'),
                        icon: LucideIcons.smartphone,
                        title: s.name,
                        subtitle: s.kinds.keys.map((k) => DeviceKind.values.where((v) => v.value == k).map((v) => deviceKindLabel(l10n, v)).firstOrNull ?? k).join(', '),
                        trailing: IconButton(
                          key: Key('forgetDevice-${s.deviceKey}'),
                          tooltip: l10n.deviceForget,
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          onPressed: () async {
                            await runGuarded(context, () => ref.read(backendProvider).deleteDeviceSource(s.deviceKey));
                            ref.invalidate(_deviceStateProvider);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({required this.kind, required this.settings, required this.busy, required this.grants, required this.onToggle, required this.onSettings, required this.onRevoke});
  final DeviceKind kind;
  final DeviceKindSettings? settings;
  final bool busy;
  final List<DeviceGrant> grants;
  final ValueChanged<bool> onToggle;
  final ValueChanged<DeviceKindSettings> onSettings;
  final ValueChanged<DeviceGrant> onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = settings != null;
    final label = deviceKindLabel(l10n, kind);
    final keep = settings?.retentionDays ?? defaultRetentionDays(kind);
    return AppCard(
      key: Key('deviceKind-${kind.value}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: Key('deviceSwitch-${kind.value}'),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(deviceKindIcon(kind)),
            title: Text(label[0].toUpperCase() + label.substring(1)),
            value: on,
            onChanged: busy ? null : onToggle,
          ),
          if (on) ...[
            Row(
              children: [
                Expanded(child: Text(l10n.deviceKeepFor, style: context.textTheme.bodyMedium)),
                DropdownButton<int>(
                  key: Key('deviceKeep-${kind.value}'),
                  value: const [0, 7, 30, 90, 365].contains(keep) ? keep : 365,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final d in const [0, 7, 30, 90, 365])
                      if (d <= defaultRetentionDays(kind)) DropdownMenuItem(value: d, child: Text(d == 0 ? l10n.deviceKeepLiveOnly : l10n.deviceKeepDays(d))),
                  ],
                  onChanged: (d) => d == null ? null : onSettings(DeviceKindSettings(retentionDays: d, privateModel: settings?.privateModel)),
                ),
              ],
            ),
            SwitchListTile(
              key: Key('devicePrivate-${kind.value}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.devicePrivateModel),
              subtitle: Text(l10n.devicePrivateModelHelp),
              value: settings?.privateModel ?? false,
              onChanged: (v) => onSettings(DeviceKindSettings(retentionDays: settings?.retentionDays, privateModel: v)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.sm),
              child: grants.isEmpty
                  ? Text(l10n.deviceNoBots, style: context.textTheme.bodySmall)
                  : Wrap(
                      spacing: AppSpace.xs,
                      runSpacing: AppSpace.xs,
                      children: [for (final g in grants) InputChip(key: Key('grant-${g.botId}-${kind.value}'), label: Text(g.botName), onDeleted: () => onRevoke(g))],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
