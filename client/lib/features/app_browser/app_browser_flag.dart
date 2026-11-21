import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone browser's build switch (docs/PHONE-BROWSER-PLAN.md §8.7, PROTOCOL.md §4): on only in
/// builds made with `--dart-define=CASAMA_APP_BROWSER=true`.
const kAppBrowser = bool.fromEnvironment('CASAMA_APP_BROWSER');

/// Whether the phone browser's code is in this build at all. Every entry point checks this first,
/// as a constant, so a release build without [kAppBrowser] drops the whole folder. Debug builds
/// (and so tests) keep the code; [appBrowserBuildProvider] still says no unless a test overrides it.
const kAppBrowserCode = kAppBrowser || kDebugMode;

/// iPhone, iPad and Android: the only places the phone browser exists (plan §7).
bool get appBrowserPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// "ios" or "android", as the server names this phone's system; null elsewhere.
String? get appBrowserSystem => kIsWeb
    ? null
    : switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => null,
      };

/// Whether this build has the phone browser ([kAppBrowser]); tests override it.
final appBrowserBuildProvider = Provider<bool>((ref) => kAppBrowser);

/// Whether the phone browser can exist here: a build with it, on a phone or tablet. The workspace
/// switch and the owner's panel need only [appBrowserBuildProvider]; everything on the phone itself
/// needs this.
final appBrowserOnProvider = Provider<bool>(
  (ref) => ref.watch(appBrowserBuildProvider) && appBrowserPlatform,
);
