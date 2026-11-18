// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_history_conversations_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageHistoryConversationsInnerCWProxy {
  PageHistoryConversationsInner id(String id);

  PageHistoryConversationsInner botId(String botId);

  PageHistoryConversationsInner title(String? title);

  PageHistoryConversationsInner createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageHistoryConversationsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageHistoryConversationsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PageHistoryConversationsInner call({
    String id,
    String botId,
    String? title,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageHistoryConversationsInner.copyWith(...)` or call `instanceOfPageHistoryConversationsInner.copyWith.fieldName(value)` for a single field.
class _$PageHistoryConversationsInnerCWProxyImpl
    implements _$PageHistoryConversationsInnerCWProxy {
  const _$PageHistoryConversationsInnerCWProxyImpl(this._value);

  final PageHistoryConversationsInner _value;

  @override
  PageHistoryConversationsInner id(String id) => call(id: id);

  @override
  PageHistoryConversationsInner botId(String botId) => call(botId: botId);

  @override
  PageHistoryConversationsInner title(String? title) => call(title: title);

  @override
  PageHistoryConversationsInner createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageHistoryConversationsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageHistoryConversationsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageHistoryConversationsInner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return PageHistoryConversationsInner(
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
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $PageHistoryConversationsInnerCopyWith
    on PageHistoryConversationsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageHistoryConversationsInner.copyWith(...)` or `instanceOfPageHistoryConversationsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageHistoryConversationsInnerCWProxy get copyWith =>
      _$PageHistoryConversationsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageHistoryConversationsInner _$PageHistoryConversationsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PageHistoryConversationsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'bot_id', 'title', 'created_at']);
  final val = PageHistoryConversationsInner(
    id: $checkedConvert('id', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String?),
    createdAt: $checkedConvert(
      'created_at',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id', 'createdAt': 'created_at'});

Map<String, dynamic> _$PageHistoryConversationsInnerToJson(
  PageHistoryConversationsInner instance,
) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'title': instance.title,
  'created_at': instance.createdAt.toIso8601String(),
};
