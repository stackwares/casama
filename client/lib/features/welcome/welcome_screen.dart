import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/mascot.dart';
import '../settings/name_step.dart';
import '../../ui/bot_loader.dart';
import '../../core/analytics.dart';

/// Welcome chat (D-129): a new person gets a personal space and bot, and lands in its chat. No
/// form; the old wizard is behind "Set up manually".
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Object? _error;
  var _started = false;

  @override
  void initState() {
    super.initState();
    // The name step comes first (it shows over this page): the chat is made once it's answered,
    // so the welcome chat can greet them by name instead of asking again.
    ref.listenManual<bool?>(nameStepNeededProvider, (_, needed) {
      if (needed == false && !_started) {
        _started = true;
        _start();
      }
    }, fireImmediately: true);
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final w = await ref.read(backendProvider).startWelcome();
      if (!mounted) return;
      ref.read(selectedOrgIdProvider.notifier).select(w.orgId);
      // The redirect still has the empty workspace list from before this space existed. Opening
      // the chat first sends the route straight back here, and this page then stays on the spinner.
      // Reload the list before leaving. Doing it in the same frame as the navigation built the
      // shell twice, so the bot list waits until the chat is on screen.
      ref.invalidate(organizationsProvider);
      await ref.read(organizationsProvider.future);
      if (!mounted) return;
      final entering = ModalRoute.of(context)?.animation;
      if (entering != null && entering.status != AnimationStatus.completed) {
        final done = Completer<void>();
        void settled(AnimationStatus status) {
          if (status == AnimationStatus.completed && !done.isCompleted) done.complete();
        }
        entering.addStatusListener(settled);
        await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
        entering.removeStatusListener(settled);
        if (!mounted) return;
      }
      final router = GoRouter.maybeOf(context);
      router?.go('/bots/${w.botId}/chat?c=${w.conversationId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(botsProvider);
      });
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.md,
            children: [
              // Bobbing while the space gets ready; shy if it didn't work.
              if (_error == null) const BotLoader(mascot: Mascot.winky) else const MascotImage(Mascot.shy, size: 96),
              if (_error == null) ...[
                Text(l10n.welcomeGettingReady, key: const Key('welcomeLoading'), style: Theme.of(context).textTheme.titleMedium),
              ] else ...[
                Text(errorText(context, _error!), textAlign: TextAlign.center),
                FilledButton(onPressed: _start, child: Text(l10n.tryAgain)),
              ],
              TextButton.icon(
                key: const Key('setUpManually'),
                icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                label: Text(l10n.setUpManually),
                onPressed: () {
                  Analytics.log('onboarding_begin', {'path': 'manual'});
                  GoRouter.maybeOf(context)?.go('/onboarding');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
