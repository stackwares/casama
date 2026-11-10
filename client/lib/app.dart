import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/local_cache.dart';
import 'core/providers.dart';
import 'core/shortcuts.dart';
import 'core/widgets.dart';
import 'features/billing/billing_screen.dart';

import 'core/mobile_extras.dart';
import 'core/push.dart';
import 'features/companion/companion_controller.dart';
import 'features/companion/companion_overlay.dart';
import 'features/companion/desktop_shell.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'theme/appearance.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/devices/device_sync.dart';

class KasamaApp extends ConsumerWidget {
  const KasamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 402 from the server (plan limit, out of credits) opens the paywall (Kasama Cloud only).
    onPaymentRequired ??= showPaywall;
    ref.watch(pushProvider);
    // Device connections (D-149): shared device data stays fresh and runs' requests get answers.
    ref.watch(deviceSyncProvider);
    // Desktop: the companion resumes if this computer is paired and on; tray and global shortcut.
    ref.watch(companionControllerProvider);
    if (isDesktop) ref.watch(desktopShellProvider);
    // Mobile: home-screen widget data and share to bot.
    ref.watch(homeWidgetSyncProvider);
    ref.watch(shareToBotProvider);
    // Siri, Spotlight and Shortcuts (iOS, macOS) and Android app shortcuts (D-111).
    ref.watch(shortcutsProvider);
    // Signing out (or a session ending) wipes the offline cache on this device (D-112).
    ref.listen(signedInProvider, (prev, next) {
      if (prev?.value == true && next.value == false) unawaited(cacheClear(ref.read(localCacheProvider)));
    });
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: AppTheme.light(appearance),
      darkTheme: AppTheme.dark(appearance),
      themeMode: appearance.mode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => CompanionOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
