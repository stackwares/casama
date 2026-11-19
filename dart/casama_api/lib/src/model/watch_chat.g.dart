// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_chat.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchChatCWProxy {
  WatchChat bot(WatchBotHeader bot);

  WatchChat conversationId(String? conversationId);

  WatchChat messages(List<WatchMessage> messages);

  WatchChat runId(String? runId);

  WatchChat link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchChat(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchChat(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchChat call({
    WatchBotHeader bot,
    String? conversationId,
    List<WatchMessage> messages,
    String? runId,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchChat.copyWith(...)` or call `instanceOfWatchChat.copyWith.fieldName(value)` for a single field.
class _$WatchChatCWProxyImpl implements _$WatchChatCWProxy {
  const _$WatchChatCWProxyImpl(this._value);

  final WatchChat _value;

  @override
  WatchChat bot(WatchBotHeader bot) => call(bot: bot);

  @override
  WatchChat conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  WatchChat messages(List<WatchMessage> messages) => call(messages: messages);

  @override
  WatchChat runId(String? runId) => call(runId: runId);

  @override
  WatchChat link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchChat(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchChat(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchChat call({
    Object? bot = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? messages = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return WatchChat(
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as WatchBotHeader,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      messages: messages == const $CopyWithPlaceholder() || messages == null
          ? _value.messages
          // ignore: cast_nullable_to_non_nullable
          : messages as List<WatchMessage>,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $WatchChatCopyWith on WatchChat {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchChat.copyWith(...)` or `instanceOfWatchChat.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchChatCWProxy get copyWith => _$WatchChatCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchChat _$WatchChatFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchChat',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'bot',
        'conversation_id',
        'messages',
        'run_id',
        'link',
      ],
    );
    final val = WatchChat(
      bot: $checkedConvert(
        'bot',
        (v) => WatchBotHeader.fromJson(v as Map<String, dynamic>),
      ),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      messages: $checkedConvert(
        'messages',
        (v) => (v as List<dynamic>)
            .map((e) => WatchMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      runId: $checkedConvert('run_id', (v) => v as String?),
      link: $checkedConvert('link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'conversationId': 'conversation_id', 'runId': 'run_id'},
);

Map<String, dynamic> _$WatchChatToJson(WatchChat instance) => <String, dynamic>{
  'bot': instance.bot.toJson(),
  'conversation_id': instance.conversationId,
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'run_id': instance.runId,
  'link': instance.link,
};
