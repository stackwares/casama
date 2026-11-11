// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_exchange_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkExchangeListCWProxy {
  LinkExchangeList items(List<LinkExchange> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkExchangeList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkExchangeList(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkExchangeList call({List<LinkExchange> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkExchangeList.copyWith(...)` or call `instanceOfLinkExchangeList.copyWith.fieldName(value)` for a single field.
class _$LinkExchangeListCWProxyImpl implements _$LinkExchangeListCWProxy {
  const _$LinkExchangeListCWProxyImpl(this._value);

  final LinkExchangeList _value;

  @override
  LinkExchangeList items(List<LinkExchange> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkExchangeList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkExchangeList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkExchangeList call({Object? items = const $CopyWithPlaceholder()}) {
    return LinkExchangeList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LinkExchange>,
    );
  }
}

extension $LinkExchangeListCopyWith on LinkExchangeList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkExchangeList.copyWith(...)` or `instanceOfLinkExchangeList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkExchangeListCWProxy get copyWith => _$LinkExchangeListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkExchangeList _$LinkExchangeListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LinkExchangeList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = LinkExchangeList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LinkExchange.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LinkExchangeListToJson(LinkExchangeList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
