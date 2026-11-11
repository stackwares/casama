import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_loader.dart';

/// Opened by the "Run a routine" shortcut (D-111): starts the routine now, then opens the bot's
/// chat where its results arrive. [reference] is `"<routine id>:<bot id>"`.
class RunRoutineScreen extends ConsumerStatefulWidget {
  const RunRoutineScreen({super.key, required this.reference});
  final String reference;

  @override
  ConsumerState<RunRoutineScreen> createState() => _RunRoutineScreenState();
}

class _RunRoutineScreenState extends ConsumerState<RunRoutineScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final parts = widget.reference.split(':');
    try {
      await ref.read(backendProvider).runRoutine(parts.first);
      if (!mounted) return;
      showSuccess(context, context.l10n.routineStarted);
      GoRouter.maybeOf(context)?.go(parts.length > 1 ? '/bots/${parts[1]}/chat' : '/bots');
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: _error == null
              ? Column(mainAxisSize: MainAxisSize.min, spacing: AppSpace.md, children: [const BotLoader(), Text(l10n.startingRoutine)])
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.md,
                  children: [
                    const Icon(LucideIcons.triangleAlert),
                    Text(errorText(context, _error!), textAlign: TextAlign.center),
                    TextButton(onPressed: () => GoRouter.maybeOf(context)?.go('/bots'), child: Text(l10n.close)),
                  ],
                ),
        ),
      ),
    );
  }
}
