// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reaction.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageReactionCWProxy {
  MessageReaction emoji(String emoji);

  MessageReaction userId(String? userId);

  MessageReaction botId(String? botId);

  MessageReaction name(String name);

  MessageReaction avatarUrl(String? avatarUrl);

  MessageReaction source_(MessageReactionSource_Enum source_);

  MessageReaction createdAt(String createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageReaction(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageReaction(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageReaction call({
    String emoji,
    String? userId,
    String? botId,
    String name,
    String? avatarUrl,
    MessageReactionSource_Enum source_,
    String createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageReaction.copyWith(...)` or call `instanceOfMessageReaction.copyWith.fieldName(value)` for a single field.
class _$MessageReactionCWProxyImpl implements _$MessageReactionCWProxy {
  const _$MessageReactionCWProxyImpl(this._value);

  final MessageReaction _value;

  @override
  MessageReaction emoji(String emoji) => call(emoji: emoji);

  @override
  MessageReaction userId(String? userId) => call(userId: userId);

  @override
  MessageReaction botId(String? botId) => call(botId: botId);

  @override
  MessageReaction name(String name) => call(name: name);

  @override
  MessageReaction avatarUrl(String? avatarUrl) => call(avatarUrl: avatarUrl);

  @override
  MessageReaction source_(MessageReactionSource_Enum source_) =>
      call(source_: source_);

  @override
  MessageReaction createdAt(String createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageReaction(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageReaction(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageReaction call({
    Object? emoji = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? avatarUrl = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return MessageReaction(
      emoji: emoji == const $CopyWithPlaceholder() || emoji == null
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String,
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String?,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      avatarUrl: avatarUrl == const $CopyWithPlaceholder()
          ? _value.avatarUrl
          // ignore: cast_nullable_to_non_nullable
          : avatarUrl as String?,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as MessageReactionSource_Enum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
    );
  }
}

extension $MessageReactionCopyWith on MessageReaction {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageReaction.copyWith(...)` or `instanceOfMessageReaction.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageReactionCWProxy get copyWith => _$MessageReactionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageReaction _$MessageReactionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MessageReaction',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'emoji',
            'user_id',
            'bot_id',
            'name',
            'avatar_url',
            'source',
            'created_at',
          ],
        );
        final val = MessageReaction(
          emoji: $checkedConvert('emoji', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String?),
          botId: $checkedConvert('bot_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String),
          avatarUrl: $checkedConvert('avatar_url', (v) => v as String?),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$MessageReactionSource_EnumEnumMap, v),
          ),
          createdAt: $checkedConvert('created_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'botId': 'bot_id',
        'avatarUrl': 'avatar_url',
        'source_': 'source',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$MessageReactionToJson(MessageReaction instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
      'user_id': instance.userId,
      'bot_id': instance.botId,
      'name': instance.name,
      'avatar_url': instance.avatarUrl,
      'source': _$MessageReactionSource_EnumEnumMap[instance.source_]!,
      'created_at': instance.createdAt,
    };

const _$MessageReactionSource_EnumEnumMap = {
  MessageReactionSource_Enum.app: 'app',
  MessageReactionSource_Enum.api: 'api',
  MessageReactionSource_Enum.channel: 'channel',
  MessageReactionSource_Enum.bot: 'bot',
};
