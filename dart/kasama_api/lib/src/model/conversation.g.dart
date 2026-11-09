// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConversationCWProxy {
  Conversation id(String id);

  Conversation botId(String botId);

  Conversation title(String? title);

  Conversation lastMessageAt(DateTime? lastMessageAt);

  Conversation createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Conversation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Conversation(...).copyWith(id: 12, name: "My name")
  /// ```
  Conversation call({
    String id,
    String botId,
    String? title,
    DateTime? lastMessageAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConversation.copyWith(...)` or call `instanceOfConversation.copyWith.fieldName(value)` for a single field.
class _$ConversationCWProxyImpl implements _$ConversationCWProxy {
  const _$ConversationCWProxyImpl(this._value);

  final Conversation _value;

  @override
  Conversation id(String id) => call(id: id);

  @override
  Conversation botId(String botId) => call(botId: botId);

  @override
  Conversation title(String? title) => call(title: title);

  @override
  Conversation lastMessageAt(DateTime? lastMessageAt) =>
      call(lastMessageAt: lastMessageAt);

  @override
  Conversation createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Conversation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Conversation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Conversation call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? lastMessageAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Conversation(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      lastMessageAt: lastMessageAt == const $CopyWithPlaceholder()
          ? _value.lastMessageAt
          // ignore: cast_nullable_to_non_nullable
          : lastMessageAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ConversationCopyWith on Conversation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConversation.copyWith(...)` or `instanceOfConversation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConversationCWProxy get copyWith => _$ConversationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Conversation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'bot_id',
            'title',
            'last_message_at',
            'created_at',
          ],
        );
        final val = Conversation(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String?),
          lastMessageAt: $checkedConvert(
            'last_message_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'botId': 'bot_id',
        'lastMessageAt': 'last_message_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'title': instance.title,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
