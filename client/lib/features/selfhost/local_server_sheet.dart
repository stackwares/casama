import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/server_address.dart';
import '../../core/widgets.dart';
import '../../ui/form_sheet.dart';
import 'local_server.dart';

final localServerManagerProvider = Provider<LocalServerManager>((ref) => LocalServerManager());

/// "Run Casama on this computer" (D-147).
class LocalServerSheet extends ConsumerStatefulWidget {
  const LocalServerSheet({super.key});
  @override
  ConsumerState<LocalServerSheet> createState() => _LocalServerSheetState();
}

class _LocalServerSheetState extends ConsumerState<LocalServerSheet> {
  LocalServerProgress? _p;
  final _log = <String>[];
  StreamSubscription<LocalServerProgress>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _start() {
    setState(() {
      _log.clear();
      _p = const LocalServerProgress(LocalServerStep.checking);
    });
    _sub = ref.read(localServerManagerProvider).start().listen((p) async {
      if (!mounted) return;
      setState(() {
        _p = p;
        if (p.step == LocalServerStep.installing && p.detail != null) {
          _log.add(p.detail!);
          if (_log.length > 6) _log.removeAt(0);
        }
      });
      if (p.step == LocalServerStep.ready && p.detail != null) {
        await ServerAddress.save(p.detail!);
        if (mounted) Navigator.pop(context);
        await onChangeServer?.call(p.detail!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = _p;
    final busy = p != null && p.step != LocalServerStep.failed && p.step != LocalServerStep.ready;
    final status = switch (p?.step) {
      null => l10n.localServerIntro,
      LocalServerStep.checking => l10n.localServerChecking,
      LocalServerStep.downloading => l10n.localServerDownloading,
      LocalServerStep.installing => l10n.localServerInstalling,
      LocalServerStep.starting => l10n.localServerStarting,
      LocalServerStep.ready => l10n.localServerReady,
      LocalServerStep.failed => p?.detail ?? l10n.localServerFailed,
    };
    return FormSheet(
      icon: LucideIcons.serverCog,
      title: l10n.localServer,
      subtitle: l10n.localServerHelp,
      submitLabel: p?.step == LocalServerStep.failed ? l10n.tryAgain : l10n.localServerStart,
      submitKey: const Key('startLocalServer'),
      busy: busy,
      onSubmit: busy ? null : _start,
      children: [
        Text(status, key: const Key('localServerStatus')),
        if (busy) LinearProgressIndicator(value: p.step == LocalServerStep.downloading ? p.fraction : null),
        if (_log.isNotEmpty) Text(_log.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      ],
    );
  }
}
