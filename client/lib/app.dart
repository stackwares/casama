import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'core/local_cache.dart';
import 'core/media_cache.dart';
import 'core/providers.dart';
import 'core/shortcuts.dart';
import 'core/widgets.dart';
import 'core/analytics.dart';
import 'core/billing.dart';
import 'features/voice/call_glance.dart';
import 'features/billing/billing_screen.dart';
import 'features/billing/out_of_credits.dart';

import 'core/mobile_extras.dart';
import 'core/mac_bridge.dart';
import 'core/open_links.dart';
import 'core/push.dart';
import 'core/updater.dart';
import 'features/notifications/notifications_primer.dart';
import 'features/settings/name_step.dart';
import 'features/welcome/gallery_picks_step.dart';
import 'features/companion/companion_controller.dart';
import 'features/companion/companion_overlay.dart';
import 'features/companion/desktop_shell.dart';
import 'core/router.dart';
import 'core/remote_config.dart';
import 'core/route_title.dart';
import 'core/theme.dart';
import 'ui/app_scroll_behavior.dart';
import 'ui/server_reachability_bar.dart';
import 'theme/appearance.dart';
import 'theme/wallpaper.dart';
import 'ui/text_scale.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/devices/device_sync.dart';
import 'features/voice/call_bubble.dart';
import 'features/selfhost/guided_setup.dart';
import 'ui/effects.dart';
import 'features/island/island_bridge.dart';
import 'features/app_lock/lock_screen.dart';
import 'features/permissions/permissions_reporter.dart';

class CasamaApp extends ConsumerWidget {
  const CasamaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 402 from the server (plan limit, out of credits) opens the paywall (Casama Cloud only).
    onPaymentRequired ??= showPaywall;
    onOutOfCredits ??= openOutOfCredits;
    // Services kept running for the app's lifetime. Listened to rather than watched: none of them
    // changes what this widget builds, so a change in one mustn't rebuild the whole app.
    void keep(ProviderListenable<Object?> provider) => ref.listen(provider, (_, _) {});
    keep(pushProvider);
    // Store purchases (Ask to Buy approvals, redelivered ones) are verified from launch, not only
    // once Billing or the paywall opens.
    keep(purchaseVerifierProvider);
    keep(macBridgeProvider);
    // casama:// and casama.ai links on macOS (D-326).
    keep(macOpenLinksProvider);
    keep(updaterProvider);
    // Device connections (D-149): shared device data stays fresh and runs' requests get answers.
    keep(deviceSyncProvider);
    // System permissions (D-376): this device reports them and answers cards tapped elsewhere.
    keep(permissionsReporterProvider);
    // Desktop: the companion resumes if this computer is paired and on; tray and global shortcut.
    keep(companionControllerProvider);
    if (isDesktop) keep(desktopShellProvider);
    // The island (D-324): the feed flows to the Mac's notch and menu bar panel.
    keep(islandBridgeProvider);
    // Mobile: home-screen widget data and share to bot.
    keep(homeWidgetSyncProvider);
    // A live call on the iPhone's lock screen and Dynamic Island (D-327 §9).
    keep(callGlanceSyncProvider);
    keep(shareToBotProvider);
    // Siri, Spotlight and Shortcuts (iOS, macOS) and Android app shortcuts (D-111).
    keep(shortcutsProvider);
    // Signing out (or a session ending) wipes the offline cache on this device (D-112).
    ref.listen(signedInProvider, (prev, next) {
      if (prev?.value == true && next.value == false) {
        unawaited(cacheClear(ref.read(localCacheProvider)));
        unawaited(MediaCache.clear());
        // Signed out (or the session ended): say so, then start a new anonymous identity.
        unawaited(() async {
          await Analytics.capture('signed_out');
          await Analytics.reset();
        }());
      } else if (next.value == true) {
        // Signed out, then in (not a cold start with a saved session): the sign-in funnel's end (F1).
        if (prev?.value == false) unawaited(Analytics.capture('sign_in_completed'));
        final userId = ref.read(backendProvider).userId;
        if (userId != null) {
          unawaited(Analytics.identify(userId));
          unawaited(Analytics.syncOptOut(ref.read(backendProvider).setAnalyticsOptOut));
          Analytics.relaySend = ref.read(backendProvider).relayAnalytics;
        }
      }
    });
    final appearance = ref.watch(appearanceProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: AppTheme.light(appearance),
      darkTheme: AppTheme.dark(appearance),
      themeMode: appearance.mode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      // Scrollbars on vertical lists on every platform, phones included.
      scrollBehavior: const AppScrollBehavior(),
      // The wallpaper, painted once behind every navigator: pages are see-through over it, so it
      // stays still while they change and never blacks out or reloads between them.
      builder: (context, child) => Effects(
        fewer: appearance.fewerEffects,
        child: Wallpaper(
        child: RouteTitle(
        router: router,
        child: limitTextScale(
          context,
          // The app lock (D-375) covers everything under it: the lock screen, the setup a
          // workspace requires, and a cover while the app isn't in front.
          AppLockGate(
          child: _DismissKeyboard(
            // A bar while the server doesn't answer, once the app is open (D-296).
            child: ServerReachabilityBar(
            child: CompanionOverlay(
              // The server owner's remote settings sit over everything (D-241).
              child: RemoteConfigGate(
                // A minimised call floats over every screen (D-327).
                child: CallBubbleOverlay(
                  child: _FirstRunSteps(push: ref.read(pushProvider), child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
            ),
          ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}

/// The one-time pages over the app after sign-in: "What should bots call you?" first (see
/// [nameStepNeededProvider]), then "Picks for you" on first run (see [galleryPicksNeededProvider]),
/// then "Turn on notifications" (see [PushRegistrar.needsAsk]).
class _FirstRunSteps extends ConsumerWidget {
  const _FirstRunSteps({required this.push, required this.child});
  final PushRegistrar push;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sign-in finishes first: the two-step code and a new password come before these pages.
    final signInDone = ref.watch(signInFinishedProvider);
    final name = ref.watch(nameStepNeededProvider) ?? false;
    // "Picks for you" (D-315) follows the name step on first run, when the gallery has sets.
    final picks = ref.watch(galleryPicksNeededProvider);
    // The guided setup (D-309) asks for the name itself and is a page of its own: these wait.
    return ListenableBuilder(
      listenable: Listenable.merge([push.needsAsk, GuidedSetup.active]),
      builder: (context, _) {
        final ask = push.needsAsk.value;
        if (GuidedSetup.active.value) return child;
        return Stack(
        children: [
          child,
          if (name)
            const Positioned.fill(child: NameStep())
          else if (picks)
            const Positioned.fill(child: GalleryPicksStep())
          else if (ask && signInDone)
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: push.webBlocked,
                builder: (context, blocked, _) => NotificationsPrimer(onEnable: push.enable, onLater: push.snooze, blocked: blocked),
              ),
            ),
        ],
      );
      },
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
