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

/// Off by default (D-307): what each reply cost, in a small line under it, for people who want
/// to watch their usage. Kept on this device.
class ShowReplyUsage extends Notifier<bool> {
  static const _key = 'chat.showUsage';

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

final showReplyUsageProvider = NotifierProvider<ShowReplyUsage, bool>(ShowReplyUsage.new);

/// On by default (SCREEN-CARD-PLAN §6): while a bot works on its computer's screen, a small card
/// in its chat shows that screen. Kept on this device.
class ShowScreenCard extends Notifier<bool> {
  static const _key = 'chat.showScreenCard';

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

  Future<void> set(bool show) async {
    state = show;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, show);
    } catch (_) {}
  }
}

final showScreenCardProvider = NotifierProvider<ShowScreenCard, bool>(ShowScreenCard.new);
