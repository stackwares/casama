// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_starters.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChatStartersCWProxy {
  ChatStarters items(List<ChatStarter> items);

  ChatStarters source_(ChatStartersSource_Enum source_);

  ChatStarters refreshing(bool refreshing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatStarters(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatStarters(...).copyWith(id: 12, name: "My name")
  /// ```
  ChatStarters call({
    List<ChatStarter> items,
    ChatStartersSource_Enum source_,
    bool refreshing,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChatStarters.copyWith(...)` or call `instanceOfChatStarters.copyWith.fieldName(value)` for a single field.
class _$ChatStartersCWProxyImpl implements _$ChatStartersCWProxy {
  const _$ChatStartersCWProxyImpl(this._value);

  final ChatStarters _value;

  @override
  ChatStarters items(List<ChatStarter> items) => call(items: items);

  @override
  ChatStarters source_(ChatStartersSource_Enum source_) =>
      call(source_: source_);

  @override
  ChatStarters refreshing(bool refreshing) => call(refreshing: refreshing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatStarters(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatStarters(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChatStarters call({
    Object? items = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? refreshing = const $CopyWithPlaceholder(),
  }) {
    return ChatStarters(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ChatStarter>,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as ChatStartersSource_Enum,
      refreshing:
          refreshing == const $CopyWithPlaceholder() || refreshing == null
          ? _value.refreshing
          // ignore: cast_nullable_to_non_nullable
          : refreshing as bool,
    );
  }
}

extension $ChatStartersCopyWith on ChatStarters {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChatStarters.copyWith(...)` or `instanceOfChatStarters.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChatStartersCWProxy get copyWith => _$ChatStartersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatStarters _$ChatStartersFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChatStarters', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'source', 'refreshing']);
      final val = ChatStarters(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ChatStarter.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        source_: $checkedConvert(
          'source',
          (v) => $enumDecode(_$ChatStartersSource_EnumEnumMap, v),
        ),
        refreshing: $checkedConvert('refreshing', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$ChatStartersToJson(ChatStarters instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'source': _$ChatStartersSource_EnumEnumMap[instance.source_]!,
      'refreshing': instance.refreshing,
    };

const _$ChatStartersSource_EnumEnumMap = {
  ChatStartersSource_Enum.ai: 'ai',
  ChatStartersSource_Enum.rules: 'rules',
};
