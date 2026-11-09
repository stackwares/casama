import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/mobile_extras.dart';
import 'core/push.dart';
import 'features/companion/companion_controller.dart';
import 'features/companion/companion_overlay.dart';
import 'features/companion/desktop_shell.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'l10n/generated/app_localizations.dart';

class KasamaApp extends ConsumerWidget {
  const KasamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushProvider);
    // Desktop: the companion resumes if this computer is paired and on; tray and global shortcut.
    ref.watch(companionControllerProvider);
    if (isDesktop) ref.watch(desktopShellProvider);
    // Mobile: home-screen widget data and share to bot.
    ref.watch(homeWidgetSyncProvider);
    ref.watch(shareToBotProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => CompanionOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
