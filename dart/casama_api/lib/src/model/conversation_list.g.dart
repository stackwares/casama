// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConversationListCWProxy {
  ConversationList items(List<Conversation> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConversationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConversationList(...).copyWith(id: 12, name: "My name")
  /// ```
  ConversationList call({List<Conversation> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConversationList.copyWith(...)` or call `instanceOfConversationList.copyWith.fieldName(value)` for a single field.
class _$ConversationListCWProxyImpl implements _$ConversationListCWProxy {
  const _$ConversationListCWProxyImpl(this._value);

  final ConversationList _value;

  @override
  ConversationList items(List<Conversation> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConversationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConversationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConversationList call({Object? items = const $CopyWithPlaceholder()}) {
    return ConversationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Conversation>,
    );
  }
}

extension $ConversationListCopyWith on ConversationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConversationList.copyWith(...)` or `instanceOfConversationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConversationListCWProxy get copyWith => _$ConversationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationList _$ConversationListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConversationList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ConversationList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ConversationListToJson(ConversationList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
