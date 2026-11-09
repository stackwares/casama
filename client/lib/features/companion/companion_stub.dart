import 'package:flutter/foundation.dart';

import 'companion.dart';

Companion createCompanion() => _Unsupported();
DeviceTokenStore createTokenStore() => _NoStore();

class _NoStore implements DeviceTokenStore {
  @override
  Future<(String, String)?> read(String orgId) async => null;
  @override
  Future<void> write(String orgId, String deviceId, String token) async {}
  @override
  Future<void> delete(String orgId) async {}
}

/// Web and mobile: a phone or browser cannot act as a bot's computer.
class _Unsupported implements Companion {
  final _status = ValueNotifier(CompanionStatus.off);
  final _activity = ValueNotifier<CompanionActivity?>(null);
  @override
  ValueListenable<CompanionStatus> get status => _status;
  @override
  ValueListenable<CompanionActivity?> get activity => _activity;
  @override
  bool get supported => false;
  @override
  Future<void> start({required String apiUrl, required String deviceToken, required CompanionSettings settings}) async {}
  @override
  Future<void> stop() async {}
}
