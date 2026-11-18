// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_link_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotLinkListCWProxy {
  BotLinkList items(List<BotLink> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotLinkList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotLinkList(...).copyWith(id: 12, name: "My name")
  /// ```
  BotLinkList call({List<BotLink> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotLinkList.copyWith(...)` or call `instanceOfBotLinkList.copyWith.fieldName(value)` for a single field.
class _$BotLinkListCWProxyImpl implements _$BotLinkListCWProxy {
  const _$BotLinkListCWProxyImpl(this._value);

  final BotLinkList _value;

  @override
  BotLinkList items(List<BotLink> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotLinkList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotLinkList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotLinkList call({Object? items = const $CopyWithPlaceholder()}) {
    return BotLinkList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BotLink>,
    );
  }
}

extension $BotLinkListCopyWith on BotLinkList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotLinkList.copyWith(...)` or `instanceOfBotLinkList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotLinkListCWProxy get copyWith => _$BotLinkListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotLinkList _$BotLinkListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotLinkList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = BotLinkList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BotLink.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BotLinkListToJson(BotLinkList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
