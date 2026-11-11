import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/mascot.dart';

/// Welcome chat (D-129): a new person gets a personal space and bot, and lands in its chat. No
/// form; the old wizard is behind "Set up manually".
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final w = await ref.read(backendProvider).startWelcome();
      if (!mounted) return;
      ref.read(selectedOrgIdProvider.notifier).select(w.orgId);
      // Leave only once this page has finished coming in: navigating back into the app while the
      // previous page is still animating out would build the app shell twice.
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
      // Refresh the lists once the chat is on screen: invalidating them makes the router re-check
      // its redirects, and doing both in one frame built the shell twice (a duplicate navigator).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(organizationsProvider);
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
              const MascotImage(Mascot.winky, size: 96),
              if (_error == null) ...[
                Text(l10n.welcomeGettingReady, key: const Key('welcomeLoading'), style: Theme.of(context).textTheme.titleMedium),
                const CircularProgressIndicator(),
              ] else ...[
                Text(errorText(context, _error!), textAlign: TextAlign.center),
                FilledButton(onPressed: _start, child: Text(l10n.tryAgain)),
              ],
              TextButton.icon(
                key: const Key('setUpManually'),
                icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                label: Text(l10n.setUpManually),
                onPressed: () => GoRouter.maybeOf(context)?.go('/onboarding'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
