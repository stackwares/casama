import 'package:flutter/foundation.dart';

/// How this build is distributed: `direct` (a signed, notarized download, every feature) or
/// `appstore` (the Mac App Store: sandboxed, so features that reach outside the app are off).
/// Set with `--dart-define=CASAMA_DISTRIBUTION=appstore` (scripts/package-macos-appstore.sh).
const kDistribution = String.fromEnvironment('CASAMA_DISTRIBUTION', defaultValue: 'direct');

/// The Mac App Store build. In its sandbox it can't control this Mac for bots, run a local server
/// (Docker), read other apps' windows or selection, or watch folders; purchases go through StoreKit.
bool get isMacAppStoreBuild => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS && kDistribution == 'appstore';
