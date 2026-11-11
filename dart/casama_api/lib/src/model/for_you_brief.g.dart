// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'for_you_brief.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ForYouBriefCWProxy {
  ForYouBrief botId(String botId);

  ForYouBrief conversationId(String conversationId);

  ForYouBrief text(String text);

  ForYouBrief createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ForYouBrief(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ForYouBrief(...).copyWith(id: 12, name: "My name")
  /// ```
  ForYouBrief call({
    String botId,
    String conversationId,
    String text,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfForYouBrief.copyWith(...)` or call `instanceOfForYouBrief.copyWith.fieldName(value)` for a single field.
class _$ForYouBriefCWProxyImpl implements _$ForYouBriefCWProxy {
  const _$ForYouBriefCWProxyImpl(this._value);

  final ForYouBrief _value;

  @override
  ForYouBrief botId(String botId) => call(botId: botId);

  @override
  ForYouBrief conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  ForYouBrief text(String text) => call(text: text);

  @override
  ForYouBrief createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ForYouBrief(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ForYouBrief(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ForYouBrief call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ForYouBrief(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ForYouBriefCopyWith on ForYouBrief {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfForYouBrief.copyWith(...)` or `instanceOfForYouBrief.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ForYouBriefCWProxy get copyWith => _$ForYouBriefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForYouBrief _$ForYouBriefFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ForYouBrief',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['bot_id', 'conversation_id', 'text', 'created_at'],
    );
    final val = ForYouBrief(
      botId: $checkedConvert('bot_id', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String),
      text: $checkedConvert('text', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'conversationId': 'conversation_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ForYouBriefToJson(ForYouBrief instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'conversation_id': instance.conversationId,
      'text': instance.text,
      'created_at': instance.createdAt.toIso8601String(),
    };
