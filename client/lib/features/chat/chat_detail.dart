import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether chats show the bot's steps (D-162). Off by default: the chat shows what the bot is
/// doing in a few words and what it found, like a consumer assistant. On: each step with its
/// command or query, skill and checkpoint notices, and errors in full. Kept on this device.
class ShowBotSteps extends Notifier<bool> {
  static const _key = 'chat.showSteps';

  @override
  bool build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getBool(_key);
          if (saved != null && ref.mounted) state = saved;
        })
        .catchError((_) {});
    return false;
  }

  Future<void> set(bool show) async {
    state = show;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, show);
    } catch (_) {}
  }
}

final showBotStepsProvider = NotifierProvider<ShowBotSteps, bool>(ShowBotSteps.new);
