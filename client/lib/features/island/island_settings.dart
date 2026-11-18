import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A switch kept on this device, on until turned off.
class _DeviceSwitch extends Notifier<bool> {
  _DeviceSwitch(this._key);
  final String _key;

  @override
  bool build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getBool(_key);
          if (saved != null && ref.mounted) state = saved;
        })
        .catchError((_) {});
    return true;
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, on);
    } catch (_) {}
  }
}

/// Settings → App → **Show bots in the notch** (D-324, §6 G). Off: the notch never shows and the
/// menu bar panel has everything; the window goes back to staying on top while a bot uses this
/// Mac (D-066, decision 10).
final islandNotchOnProvider = NotifierProvider<_DeviceSwitch, bool>(
  () => _DeviceSwitch('island.notch'),
);

/// Settings → App → **Open the notch on hover** (decision 4). Off: a click opens it.
final islandHoverOpensProvider = NotifierProvider<_DeviceSwitch, bool>(
  () => _DeviceSwitch('island.hover'),
);

/// Settings → **Bots you start elsewhere** on a phone (D-324, Phase 6; decision 11): a run you
/// start on another device, such as your Mac, shows on this phone's Lock Screen too.
final islandStartElsewhereProvider = NotifierProvider<_DeviceSwitch, bool>(
  () => _DeviceSwitch('island.startElsewhere'),
);

/// The bot the notch's ask field goes to: the one talked to last on this device (§6 B 6).
class IslandAskBot extends Notifier<String?> {
  static const _key = 'island.askBot';

  @override
  String? build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getString(_key);
          if (saved != null && ref.mounted && state == null) state = saved;
        })
        .catchError((_) {});
    return null;
  }

  Future<void> set(String botId) async {
    if (state == botId) return;
    state = botId;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, botId);
    } catch (_) {}
  }
}

final islandAskBotProvider = NotifierProvider<IslandAskBot, String?>(
  IslandAskBot.new,
);
