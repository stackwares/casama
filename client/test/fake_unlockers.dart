import 'package:casama/features/app_lock/app_lock.dart';

/// The app lock's unlock methods without the platform (D-375). By default this device has no
/// system unlock and no PIN, so checks before risky actions go straight through.
class FakeUnlockers extends Unlockers {
  FakeUnlockers({
    this.deviceOn = false,
    this.deviceResult = UnlockResult.ok,
    this.pinValue,
    this.passkeyResult,
  });

  bool deviceOn;
  UnlockResult deviceResult;

  /// The PIN set on this device, or null for none.
  String? pinValue;

  /// What a passkey check answers instead of asking the backend; null asks it.
  UnlockResult? passkeyResult;

  final reasons = <String>[];
  var pinChecks = 0;

  @override
  Future<bool> deviceAvailable() async => deviceOn;

  @override
  Future<UnlockResult> device(String reason) async {
    reasons.add(reason);
    return deviceResult;
  }

  @override
  Future<bool> pinSet() async => pinValue != null;

  @override
  Future<UnlockResult> pin(String pin) async {
    pinChecks++;
    if (pinValue == null) return UnlockResult.unavailable;
    return pin == pinValue ? UnlockResult.ok : UnlockResult.failed;
  }

  @override
  Future<UnlockResult> passkey(Future<bool?> Function() confirm) async =>
      passkeyResult ?? await super.passkey(confirm);
}
