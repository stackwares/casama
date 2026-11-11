import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'core/local_cache.dart';
import 'core/providers.dart';
import 'core/shortcuts.dart';
import 'core/widgets.dart';
import 'features/billing/billing_screen.dart';

import 'core/mobile_extras.dart';
import 'core/mac_bridge.dart';
import 'core/push.dart';
import 'core/updater.dart';
import 'features/notifications/notifications_primer.dart';
import 'features/settings/name_step.dart';
import 'features/companion/companion_controller.dart';
import 'features/companion/companion_overlay.dart';
import 'features/companion/desktop_shell.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'theme/appearance.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/devices/device_sync.dart';

class CasamaApp extends ConsumerWidget {
  const CasamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 402 from the server (plan limit, out of credits) opens the paywall (Casama Cloud only).
    onPaymentRequired ??= showPaywall;
    // Services kept running for the app's lifetime. Listened to rather than watched: none of them
    // changes what this widget builds, so a change in one mustn't rebuild the whole app.
    void keep(ProviderListenable<Object?> provider) => ref.listen(provider, (_, _) {});
    keep(pushProvider);
    keep(macBridgeProvider);
    keep(updaterProvider);
    // Device connections (D-149): shared device data stays fresh and runs' requests get answers.
    keep(deviceSyncProvider);
    // Desktop: the companion resumes if this computer is paired and on; tray and global shortcut.
    keep(companionControllerProvider);
    if (isDesktop) keep(desktopShellProvider);
    // Mobile: home-screen widget data and share to bot.
    keep(homeWidgetSyncProvider);
    keep(shareToBotProvider);
    // Siri, Spotlight and Shortcuts (iOS, macOS) and Android app shortcuts (D-111).
    keep(shortcutsProvider);
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
      builder: (context, child) => _DismissKeyboard(
        child: CompanionOverlay(
          child: _FirstRunSteps(push: ref.read(pushProvider), child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// The one-time pages over the app after sign-in: "What should bots call you?" first (see
/// [nameStepNeededProvider]), then "Turn on notifications" (see [PushRegistrar.needsAsk]).
class _FirstRunSteps extends ConsumerWidget {
  const _FirstRunSteps({required this.push, required this.child});
  final PushRegistrar push;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(nameStepNeededProvider) ?? false;
    return ValueListenableBuilder<bool>(
      valueListenable: push.needsAsk,
      builder: (context, ask, _) => Stack(
        children: [
          child,
          if (name)
            const Positioned.fill(child: NameStep())
          else if (ask)
            Positioned.fill(child: NotificationsPrimer(onEnable: push.enable, onLater: push.snooze)),
        ],
      ),
    );
  }
}

/// Phones: a tap outside the text field being typed in puts the keyboard away, as people expect
/// (Flutter keeps it open on touch). Buttons and other fields still get their taps first, so this
/// only fires on empty space and plain content. Mouse clicks are left alone: desktop fields
/// already handle that, and moving focus there would break shortcuts.
class _DismissKeyboard extends StatelessWidget {
  const _DismissKeyboard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTapUp: (details) {
      if (details.kind != PointerDeviceKind.touch) return;
      final focus = FocusManager.instance.primaryFocus;
      if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) focus!.unfocus();
    },
    child: child,
  );
}
