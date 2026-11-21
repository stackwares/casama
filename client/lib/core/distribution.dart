import 'package:flutter/foundation.dart';

/// How this build is distributed:
/// - Desktop / web: `direct` (default; signed download, every feature) or `appstore` (Mac App Store).
/// - Android: `play` (or `direct` default on Android -> Google Play), `apk` (direct APK: GitHub
///   Releases, Obtainium, Aptoide, APKPure, Uptodown; Dodo web checkout), or `galaxy` (Samsung
///   Galaxy Store; web checkout).
/// Set with `--dart-define=CASAMA_DISTRIBUTION=...` (scripts/package-macos-appstore.sh,
/// scripts/package-android.sh).
const kDistribution = String.fromEnvironment('CASAMA_DISTRIBUTION', defaultValue: 'direct');

/// The Mac App Store build. In its sandbox it can't control this Mac for bots, run a local server
/// (Docker), read other apps' windows or selection, or watch folders; purchases go through StoreKit.
bool get isMacAppStoreBuild => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS && kDistribution == 'appstore';

/// Normalizes [distribution] for Android: unset (`direct`) and `play` both mean Google Play so
/// local `flutter test` / `flutter run` keep Play behavior without extra flags.
String androidDistribution([String distribution = kDistribution]) =>
    distribution == 'direct' || distribution == 'play' ? 'play' : distribution;

/// Whether this is a Google Play Android build.
bool get isGooglePlayBuild =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android && androidDistribution() == 'play';

/// Android distributions that use Dodo web checkout instead of an in-app store SDK.
bool androidUsesWebBilling([String distribution = kDistribution]) =>
    const {'apk', 'galaxy', 'foss'}.contains(androidDistribution(distribution));
