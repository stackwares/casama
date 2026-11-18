import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'os_permissions.dart';
import 'permissions_card.dart';
import 'permissions_reporter.dart';
import 'permissions_view.dart';

/// Settings → Permissions (D-376): this device's system permissions, with the same buttons as
/// the chat card, so they can be turned on before a bot ever asks.
///
/// A phone's notification from a card tapped elsewhere opens it as
/// `/permissions?device=<ref>&ask=<permission>&do=<action>`: on the device it names, the ask runs
/// right away (the system prompt needs the app in front, which the tap just did).
class DevicePermissionsScreen extends ConsumerStatefulWidget {
  const DevicePermissionsScreen({super.key, this.device, this.ask, this.action});
  final String? device;
  final String? ask;
  final String? action;

  @override
  ConsumerState<DevicePermissionsScreen> createState() => _DevicePermissionsScreenState();
}

class _DevicePermissionsScreenState extends ConsumerState<DevicePermissionsScreen> with PermissionActions<DevicePermissionsScreen> {
  @override
  late final PermissionsLive live;
  late final List<String> _ids;

  /// The link named another device: its name, to say so.
  String? _elsewhere;
  var _asked = false;

  @override
  String get fallbackPlatform => ref.read(permissionsReporterProvider).platform.platform;
  @override
  String get deviceName => '';
  @override
  String? get botId => null;

  @override
  void initState() {
    super.initState();
    final reporter = ref.read(permissionsReporterProvider);
    _ids = permissionIdsFor(reporter.platform.platform);
    live = PermissionsLive(backend: ref.read(backendProvider), reporter: reporter, ids: _ids)..addListener(_changed);
    unawaited(live.start());
  }

  void _changed() {
    if (!mounted) return;
    trackRestarts(_ids);
    setState(() {});
    _runLinkAsk();
  }

  /// The link's ask, once, when the list says whose device it's for.
  void _runLinkAsk() {
    final device = widget.device;
    final ask = widget.ask;
    if (_asked || device == null || ask == null || !live.loaded) return;
    _asked = true;
    if (!live.mine.contains(device)) {
      setState(() => _elsewhere = live.devices.where((d) => d.deviceRef == device).firstOrNull?.name ?? '');
      return;
    }
    unawaited(turnOn(ask, relaunch: widget.action == 'relaunch'));
  }

  @override
  void dispose() {
    live.removeListener(_changed);
    live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final elsewhere = _elsewhere;
    return SubPage(
      title: l10n.permissionsScreenTitle,
      body: PageColumn(
        children: [
          FormNote(l10n.permissionsScreenHelp, icon: LucideIcons.shieldCheck),
          if (elsewhere != null) ...[
            const SizedBox(height: AppSpace.sm),
            FormNote(l10n.permOtherDevice(elsewhere.isEmpty ? l10n.permAnotherDevice : elsewhere), key: const Key('permElsewhere'), icon: LucideIcons.info),
          ],
          const SizedBox(height: AppSpace.md),
          if (_ids.isEmpty)
            EmptyState(icon: LucideIcons.shieldCheck, title: l10n.permissionsScreenTitle, message: l10n.permissionsNone)
          else
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final id in _ids) rowFor(id, enabled: true)]),
            ),
        ],
      ),
    );
  }
}
