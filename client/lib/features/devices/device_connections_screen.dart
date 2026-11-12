import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../desktop/desktop_watch.dart';
import 'device_labels.dart';
import 'device_sync.dart';
import '../../core/analytics.dart';

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

  /// Like [runGuarded], but a server without encryption at rest refusing health data gets its own message.
  Future<bool?> _guarded(Future<bool> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (!mounted) return null;
      if (problemOf(e)?.code != 'health_needs_encryption') return runGuarded(context, () => Future<bool>.error(e));
      showWarning(context, context.l10n.healthNeedsEncryption);
      return null;
    }
  }

  Future<void> _toggle(DeviceKind kind, bool on) async {
    setState(() => _busy.add(kind));
    final l10n = context.l10n;
    final ok = await _guarded(() => ref.read(deviceSyncProvider).setKind(kind, on));
    if (!mounted) return;
    setState(() => _busy.remove(kind));
    Analytics.log('device_data_toggled', {'kind': kind.name, 'result': !on ? 'off' : ok == false ? 'denied' : 'granted'});
    if (ok == false) showWarning(context, l10n.devicePermissionDenied);
    ref.invalidate(_deviceStateProvider);
  }

  Future<void> _settings(DeviceKind kind, DeviceKindSettings settings) async {
    await _guarded(() => ref.read(deviceSyncProvider).setKind(kind, true, settings: settings));
    if (!mounted) return;
    ref.invalidate(_deviceStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final supported = ref.watch(deviceSyncProvider).supported;
    return SubPage(
      title: l10n.deviceConnections,
      body: AsyncView(
        value: ref.watch(_deviceStateProvider),
        onRetry: () => ref.invalidate(_deviceStateProvider),
        data: (st) {
          final others = st.sources.where((s) => s.deviceKey != st.key).toList();
          final onKinds = [for (final k in DeviceKind.values.where(supported.contains)) if (st.mine?.kinds[k.value] != null) k];
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
                    onToggle: (on) => _toggle(kind, on),
                    // Places and watched apps stay with the switch: without them the kind shares nothing.
                    extra: kind == DeviceKind.places
                        ? const _PlacesEditor()
                        : kind == DeviceKind.notifications
                        ? _AppsEditor(apps: st.mine?.kinds['notifications']?.apps ?? const [], onChanged: (apps) => _settings(kind, DeviceKindSettings(retentionDays: st.mine?.kinds['notifications']?.retentionDays, privateModel: st.mine?.kinds['notifications']?.privateModel, apps: apps)))
                        : null,
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              // Desktop (D-152): folders whose new files can start routines.
              if (ref.watch(deviceSyncProvider).folders != null) ...[const SizedBox(height: AppSpace.md), const _WatchedFolders()],
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
              // How long each kind is kept, who may read it and the health extras (D-182).
              if (onKinds.isNotEmpty)
                AdvancedSection(
                  id: 'devices',
                  summary: l10n.devicesAdvancedSummary,
                  children: [
                    for (final kind in onKinds) ...[
                      _KindAdvanced(
                        kind: kind,
                        settings: st.mine!.kinds[kind.value]!,
                        grants: st.grants.where((g) => g.kind == kind).toList(),
                        onSettings: (s) => _settings(kind, s),
                        onRevoke: (g) async {
                          await runGuarded(context, () => ref.read(backendProvider).setDeviceGrant(g.botId, g.kind, false));
                          ref.invalidate(_deviceStateProvider);
                        },
                      ),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

String _kindTitle(AppLocalizations l10n, DeviceKind kind) {
  final label = deviceKindLabel(l10n, kind);
  return label[0].toUpperCase() + label.substring(1);
}

/// One kind's switch, plus what it can't work without (places, watched apps).
class _KindCard extends StatelessWidget {
  const _KindCard({required this.kind, required this.settings, required this.busy, required this.onToggle, this.extra});
  final Widget? extra;
  final DeviceKind kind;
  final DeviceKindSettings? settings;
  final bool busy;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = settings != null;
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
            title: Text(_kindTitle(l10n, kind)),
            value: on,
            onChanged: hapticOnChanged(busy ? null : onToggle),
          ),
          if (on && (kind == DeviceKind.health || extra != null))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kind == DeviceKind.health) Text(l10n.healthNotMedical, style: context.textTheme.bodySmall),
                  ?extra,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A shared kind's expert settings: how long it's kept, private models only, the health extras,
/// and the bots that may read it.
class _KindAdvanced extends StatelessWidget {
  const _KindAdvanced({required this.kind, required this.settings, required this.grants, required this.onSettings, required this.onRevoke});
  final DeviceKind kind;
  final DeviceKindSettings settings;
  final List<DeviceGrant> grants;
  final ValueChanged<DeviceKindSettings> onSettings;
  final ValueChanged<DeviceGrant> onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keep = settings.retentionDays ?? defaultRetentionDays(kind);
    return AppCard(
      key: Key('deviceAdvanced-${kind.value}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: Row(
              children: [
                Icon(deviceKindIcon(kind), size: 18, color: context.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(_kindTitle(l10n, kind), style: context.textTheme.titleSmall)),
              ],
            ),
          ),
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
                onChanged: hapticOnChanged((d) => d == null ? null : onSettings(DeviceKindSettings(retentionDays: d, privateModel: settings.privateModel, extras: settings.extras)), haptic: HapticsHelper.selection),
              ),
            ],
          ),
          SwitchListTile(
            key: Key('devicePrivate-${kind.value}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.devicePrivateModel),
            subtitle: Text(l10n.devicePrivateModelHelp),
            value: settings.privateModel ?? false,
            onChanged: hapticOnChanged((v) => onSettings(DeviceKindSettings(retentionDays: settings.retentionDays, privateModel: v, extras: settings.extras))),
          ),
          // Health (D-150): sensitive extras are separate switches, off by default.
          if (kind == DeviceKind.health)
            for (final x in DeviceKindSettingsExtrasEnum.values)
              SwitchListTile(
                key: Key('healthExtra-${x.value}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(switch (x) {
                  DeviceKindSettingsExtrasEnum.cycle => l10n.healthExtraCycle,
                  DeviceKindSettingsExtrasEnum.glucose => l10n.healthExtraGlucose,
                  DeviceKindSettingsExtrasEnum.bloodPressure => l10n.healthExtraBloodPressure,
                }),
                value: settings.extras?.contains(x) ?? false,
                onChanged: hapticOnChanged((v) => onSettings(
                  DeviceKindSettings(
                    retentionDays: settings.retentionDays,
                    privateModel: settings.privateModel,
                    extras: [...?settings.extras?.where((e) => e != x), if (v) x],
                  ),
                )),
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
      ),
    );
  }
}

/// Named places (D-151): up to 20, used for arrive and leave. Only their names leave the device in events.
class _PlacesEditor extends ConsumerStatefulWidget {
  const _PlacesEditor();
  @override
  ConsumerState<_PlacesEditor> createState() => _PlacesEditorState();
}

class _PlacesEditorState extends ConsumerState<_PlacesEditor> {
  List<DevicePlace>? _places;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(backendProvider).devicePlaces().catchError((_) => <DevicePlace>[]);
    if (mounted) setState(() => _places = p);
  }

  Future<void> _addHere() async {
    final l10n = context.l10n;
    final name = await showTextPrompt(context, title: l10n.placeAddHere, label: l10n.placeName, submitLabel: l10n.save, icon: LucideIcons.mapPin);
    if (name == null || name.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    await runGuarded(context, () async {
      final sync = ref.read(deviceSyncProvider);
      final at = await sync.triggers.currentLocation();
      if (at == null) throw StateError(l10n.placeNoLocation);
      await ref.read(backendProvider).saveDevicePlace(name: name.trim(), latitude: at.lat, longitude: at.lng);
      await sync.refreshPlaces();
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final places = _places ?? const <DevicePlace>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.placesHelp, style: context.textTheme.bodySmall),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final p in places)
              InputChip(
                key: Key('place-${p.name}'),
                avatar: const Icon(LucideIcons.mapPin, size: 16),
                label: Text(p.name),
                onDeleted: () async {
                  await runGuarded(context, () async {
                    await ref.read(backendProvider).deleteDevicePlace(p.id);
                    await ref.read(deviceSyncProvider).refreshPlaces();
                    return true;
                  });
                  await _load();
                },
              ),
            if (places.length < 20)
              ActionChip(key: const Key('placeAddHere'), avatar: const Icon(LucideIcons.locateFixed, size: 16), label: Text(l10n.placeAddHere), onPressed: _busy ? null : _addHere),
          ],
        ),
      ],
    );
  }
}

/// Watched apps (D-151, Android): only notifications from these apps are shared.
class _AppsEditor extends StatefulWidget {
  const _AppsEditor({required this.apps, required this.onChanged});
  final List<String> apps;
  final ValueChanged<List<String>> onChanged;
  @override
  State<_AppsEditor> createState() => _AppsEditorState();
}

class _AppsEditorState extends State<_AppsEditor> {
  final _app = TextEditingController();

  @override
  void dispose() {
    _app.dispose();
    super.dispose();
  }

  void _add() {
    final v = _app.text.trim();
    if (v.isEmpty || widget.apps.contains(v)) return;
    _app.clear();
    widget.onChanged([...widget.apps, v]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.watchedAppsHelp, style: context.textTheme.bodySmall),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [for (final a in widget.apps) InputChip(key: Key('app-$a'), label: Text(a), onDeleted: () => widget.onChanged([...widget.apps]..remove(a)))],
        ),
        TextField(
          key: const Key('watchedAppInput'),
          controller: _app,
          decoration: InputDecoration(labelText: l10n.watchedAppAdd, hintText: 'com.mybank.app', suffixIcon: IconButton(key: const Key('watchedAppSave'), icon: const Icon(LucideIcons.plus), onPressed: _add)),
          onSubmitted: (_) => _add(),
        ),
      ],
    );
  }
}

class _WatchedFolders extends ConsumerStatefulWidget {
  const _WatchedFolders();
  @override
  ConsumerState<_WatchedFolders> createState() => _WatchedFoldersState();
}

class _WatchedFoldersState extends ConsumerState<_WatchedFolders> {
  List<String> _folders = const [];

  @override
  void initState() {
    super.initState();
    FolderWatcher.folders().then((f) {
      if (mounted) setState(() => _folders = f);
    });
  }

  Future<void> _save(List<String> f) async {
    await FolderWatcher.setFolders(f);
    await ref.read(deviceSyncProvider).folders?.start();
    if (mounted) setState(() => _folders = f);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.watchedFolders,
          trailing: TextButton.icon(
            key: const Key('addWatchedFolder'),
            onPressed: () async {
              final dir = await FilePicker.getDirectoryPath();
              if (dir == null || _folders.contains(dir)) return;
              await _save([..._folders, dir]);
            },
            icon: const Icon(LucideIcons.folderPlus, size: 18),
            label: Text(l10n.add),
          ),
        ),
        FormNote(l10n.watchedFoldersHelp),
        for (final f in _folders)
          ListTile(
            key: Key('watched-$f'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.folderOpen),
            title: Text(f, overflow: TextOverflow.ellipsis),
            trailing: IconButton(tooltip: l10n.delete, icon: const Icon(LucideIcons.x, size: 18), onPressed: () => _save([..._folders]..remove(f))),
          ),
      ],
    );
  }
}
