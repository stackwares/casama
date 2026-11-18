// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reaction_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageReactionListCWProxy {
  MessageReactionList messageId(String messageId);

  MessageReactionList items(List<MessageReaction> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageReactionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageReactionList(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageReactionList call({String messageId, List<MessageReaction> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageReactionList.copyWith(...)` or call `instanceOfMessageReactionList.copyWith.fieldName(value)` for a single field.
class _$MessageReactionListCWProxyImpl implements _$MessageReactionListCWProxy {
  const _$MessageReactionListCWProxyImpl(this._value);

  final MessageReactionList _value;

  @override
  MessageReactionList messageId(String messageId) => call(messageId: messageId);

  @override
  MessageReactionList items(List<MessageReaction> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageReactionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageReactionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageReactionList call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return MessageReactionList(
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MessageReaction>,
    );
  }
}

extension $MessageReactionListCopyWith on MessageReactionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageReactionList.copyWith(...)` or `instanceOfMessageReactionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageReactionListCWProxy get copyWith =>
      _$MessageReactionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageReactionList _$MessageReactionListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MessageReactionList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['message_id', 'items']);
      final val = MessageReactionList(
        messageId: $checkedConvert('message_id', (v) => v as String),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'messageId': 'message_id'});

Map<String, dynamic> _$MessageReactionListToJson(
  MessageReactionList instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
