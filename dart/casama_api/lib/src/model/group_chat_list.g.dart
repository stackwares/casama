// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_chat_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GroupChatListCWProxy {
  GroupChatList items(List<Conversation> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GroupChatList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GroupChatList(...).copyWith(id: 12, name: "My name")
  /// ```
  GroupChatList call({List<Conversation> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGroupChatList.copyWith(...)` or call `instanceOfGroupChatList.copyWith.fieldName(value)` for a single field.
class _$GroupChatListCWProxyImpl implements _$GroupChatListCWProxy {
  const _$GroupChatListCWProxyImpl(this._value);

  final GroupChatList _value;

  @override
  GroupChatList items(List<Conversation> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GroupChatList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GroupChatList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GroupChatList call({Object? items = const $CopyWithPlaceholder()}) {
    return GroupChatList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Conversation>,
    );
  }
}

extension $GroupChatListCopyWith on GroupChatList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGroupChatList.copyWith(...)` or `instanceOfGroupChatList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GroupChatListCWProxy get copyWith => _$GroupChatListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupChatList _$GroupChatListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupChatList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GroupChatList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GroupChatListToJson(GroupChatList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
