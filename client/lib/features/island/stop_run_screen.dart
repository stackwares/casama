import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import 'run_tracker.dart';

/// **Stop** on a Live Activity (D-324, §8.5): casama://app/runs/{id}/stop. Stops the run, then
/// lands on its chat (or the bots, if the run can't be read), as `/suggestions/:id/accept` does
/// for suggestions.
class StopRunScreen extends ConsumerStatefulWidget {
  const StopRunScreen({super.key, required this.runId});

  final String runId;

  @override
  ConsumerState<StopRunScreen> createState() => _StopRunScreenState();
}

class _StopRunScreenState extends ConsumerState<StopRunScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_stop());
  }

  Future<void> _stop() async {
    final backend = ref.read(backendProvider);
    var target = '/bots';
    try {
      await backend.cancelRun(widget.runId);
    } on RunAlreadyFinished {
      // It ended a moment ago; its chat says how.
    } catch (_) {
      // Offline or not allowed: the chat still opens, with its own Stop.
    }
    try {
      final run = await backend.run(widget.runId);
      final conversation = run.conversationId;
      target = conversation == null
          ? '/bots/${run.botId}/chat'
          : '/bots/${run.botId}/chat?c=$conversation';
    } catch (_) {}
    if (!mounted) return;
    unawaited(ref.read(runTrackerProvider.notifier).check());
    context.go(target);
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
