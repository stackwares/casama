import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/page.dart';

/// Calls for you (D-141): a call a bot placed, with its live transcript; end it or take it over.
class OutboundCallScreen extends ConsumerStatefulWidget {
  const OutboundCallScreen({super.key, required this.callId, this.pollEvery = const Duration(seconds: 1)});
  final String callId;
  final Duration pollEvery;

  @override
  ConsumerState<OutboundCallScreen> createState() => _OutboundCallScreenState();
}

class _OutboundCallScreenState extends ConsumerState<OutboundCallScreen> {
  OutboundCall? _call;
  Object? _error;
  Timer? _timer;
  final _phone = TextEditingController();

  static const _live = {OutboundCallStatusEnum.queued, OutboundCallStatusEnum.ringing, OutboundCallStatusEnum.inProgress};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(widget.pollEvery, (_) {
      if (_call == null || _live.contains(_call!.status)) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await ref.read(backendProvider).outboundCall(widget.callId);
      if (mounted) setState(() => _call = c);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _takeOver() async {
    final l10n = context.l10n;
    final phone = _phone..clear();
    final number = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.outCallTakeOver),
        content: TextField(
          key: const Key('takeOverPhone'),
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l10n.outCallYourPhone, helperText: l10n.outCallYourPhoneHelp),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l10n.cancel)),
          FilledButton(key: const Key('confirmTakeOver'), onPressed: () => Navigator.pop(d, phone.text.trim()), child: Text(l10n.outCallTakeOver)),
        ],
      ),
    );
    if (number == null || !mounted) return;
    final c = await runGuarded(context, () => ref.read(backendProvider).takeOverOutboundCall(widget.callId, phone: number.isEmpty ? null : number));
    if (c != null && mounted) setState(() => _call = c);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = _call;
    final live = c != null && _live.contains(c.status);
    final status = c == null
        ? ''
        : switch (c.status) {
            OutboundCallStatusEnum.queued || OutboundCallStatusEnum.ringing => l10n.outCallRinging,
            OutboundCallStatusEnum.inProgress => l10n.outCallLive,
            OutboundCallStatusEnum.completed => l10n.outCallEnded(c.seconds ?? 0),
            OutboundCallStatusEnum.endedByUser => l10n.outCallEndedByYou,
            OutboundCallStatusEnum.takenOver => l10n.outCallTakenOver,
            _ => l10n.outCallFailed,
          };
    return SubPage(
      title: c?.number ?? l10n.outCall,
      subtitle: status,
      body: c == null
          ? (_error != null ? EmptyState(icon: LucideIcons.phoneOff, title: l10n.outCall, message: '$_error') : const Center(child: CircularProgressIndicator()))
          : PageColumn(
              children: [
                Text(c.purpose, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpace.md),
                for (final t in c.transcript)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: Align(
                      alignment: t.role == OutboundCallTranscriptInnerRoleEnum.bot ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.all(AppSpace.sm),
                        decoration: BoxDecoration(
                          color: t.role == OutboundCallTranscriptInnerRoleEnum.bot ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(t.text),
                      ),
                    ),
                  ),
                if (c.transcript.isEmpty) Text(l10n.outCallNothingYet),
                if (live) ...[
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(key: const Key('takeOverCall'), icon: const Icon(LucideIcons.phoneForwarded, size: 18), label: Text(l10n.outCallTakeOver), onPressed: _takeOver),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('endCall'),
                          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                          icon: const Icon(LucideIcons.phoneOff, size: 18),
                          label: Text(l10n.outCallEnd),
                          onPressed: () async {
                            final r = await runGuarded(context, () => ref.read(backendProvider).endOutboundCall(widget.callId));
                            if (r != null && mounted) setState(() => _call = r);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
