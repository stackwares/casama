// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_key_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkKeyListCWProxy {
  LinkKeyList items(List<LinkKey> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkKeyList call({List<LinkKey> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkKeyList.copyWith(...)` or call `instanceOfLinkKeyList.copyWith.fieldName(value)` for a single field.
class _$LinkKeyListCWProxyImpl implements _$LinkKeyListCWProxy {
  const _$LinkKeyListCWProxyImpl(this._value);

  final LinkKeyList _value;

  @override
  LinkKeyList items(List<LinkKey> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkKeyList call({Object? items = const $CopyWithPlaceholder()}) {
    return LinkKeyList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LinkKey>,
    );
  }
}

extension $LinkKeyListCopyWith on LinkKeyList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkKeyList.copyWith(...)` or `instanceOfLinkKeyList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkKeyListCWProxy get copyWith => _$LinkKeyListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkKeyList _$LinkKeyListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LinkKeyList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = LinkKeyList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LinkKey.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LinkKeyListToJson(LinkKeyList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
