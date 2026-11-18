import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The chat a wide window opens with (D-383): the one last open on this device, kept per
/// workspace. A bot's chat or a group chat; which conversation of a bot is the chat's own business
/// (it reopens the bot's latest).
abstract final class LastChat {
  static final _chat = RegExp(r'^/(bots/[^/]+/chat|groups/[^/]+)$');
  static String _key(String orgId) => 'lastChat:$orgId';

  /// Remembers [path] when it is a chat. Called on every build of the shell, so it only writes
  /// when the chat changed.
  static void remember(String? orgId, String path) {
    if (orgId == null || !_chat.hasMatch(path)) return;
    final key = _key(orgId);
    SharedPreferences.getInstance()
        .then((p) async {
          if (p.getString(key) != path) await p.setString(key, path);
        })
        .catchError((_) {});
  }

  static Future<String?> saved(String orgId) async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key(orgId));
    } catch (_) {
      return null;
    }
  }
}

/// Where the bare Chats page goes on a wide window: [saved] while its bot or group still exists,
/// else the bot that spoke or was spoken to most recently, else the first bot in the list. Null
/// when there is nothing to open.
String? chatToOpen({
  required String? saved,
  required List<Bot> bots,
  required List<Conversation> groups,
}) {
  if (saved != null) {
    final botId = RegExp(r'^/bots/([^/]+)/chat$').firstMatch(saved)?.group(1);
    if (botId != null && bots.any((b) => b.id == botId)) return saved;
    final groupId = RegExp(r'^/groups/([^/]+)$').firstMatch(saved)?.group(1);
    if (groupId != null && groups.any((g) => g.id == groupId)) return saved;
  }
  if (bots.isEmpty) return null;
  Bot? latest;
  for (final b in bots) {
    final at = b.lastMessage?.at;
    if (at != null && (latest == null || at.isAfter(latest.lastMessage!.at))) {
      latest = b;
    }
  }
  return '/bots/${(latest ?? bots.first).id}/chat';
}
