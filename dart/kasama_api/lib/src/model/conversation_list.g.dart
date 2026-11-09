// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConversationListCWProxy {
  ConversationList items(List<Conversation> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConversationList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConversationList(...).copyWith(id: 12, name: "My name")
  /// ````
  ConversationList call({List<Conversation> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfConversationList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfConversationList.copyWith.fieldName(...)`
class _$ConversationListCWProxyImpl implements _$ConversationListCWProxy {
  const _$ConversationListCWProxyImpl(this._value);

  final ConversationList _value;

  @override
  ConversationList items(List<Conversation> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConversationList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConversationList(...).copyWith(id: 12, name: "My name")
  /// ````
  ConversationList call({Object? items = const $CopyWithPlaceholder()}) {
    return ConversationList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Conversation>,
    );
  }
}

extension $ConversationListCopyWith on ConversationList {
  /// Returns a callable class that can be used as follows: `instanceOfConversationList.copyWith(...)` or like so:`instanceOfConversationList.copyWith.fieldName(...)`.
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
