/// The Mac App Store build's auto_updater: the App Store updates the app, so every call does
/// nothing (the app never makes them there: `selfUpdating` is false). Keep the methods in step with
/// what lib/core/updater.dart calls.
library;

class AutoUpdater {
  AutoUpdater._();

  static final AutoUpdater instance = AutoUpdater._();

  Future<void> setFeedURL(String feedUrl) async {}

  Future<void> checkForUpdates({bool? inBackground}) async {}

  Future<void> setScheduledCheckInterval(int interval) async {}
}

final autoUpdater = AutoUpdater.instance;
