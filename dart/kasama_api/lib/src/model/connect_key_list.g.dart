// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_key_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectKeyListCWProxy {
  ConnectKeyList items(List<ConnectKey> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectKeyList call({List<ConnectKey> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectKeyList.copyWith(...)` or call `instanceOfConnectKeyList.copyWith.fieldName(value)` for a single field.
class _$ConnectKeyListCWProxyImpl implements _$ConnectKeyListCWProxy {
  const _$ConnectKeyListCWProxyImpl(this._value);

  final ConnectKeyList _value;

  @override
  ConnectKeyList items(List<ConnectKey> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectKeyList call({Object? items = const $CopyWithPlaceholder()}) {
    return ConnectKeyList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ConnectKey>,
    );
  }
}

extension $ConnectKeyListCopyWith on ConnectKeyList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectKeyList.copyWith(...)` or `instanceOfConnectKeyList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectKeyListCWProxy get copyWith => _$ConnectKeyListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectKeyList _$ConnectKeyListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConnectKeyList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ConnectKeyList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ConnectKey.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ConnectKeyListToJson(ConnectKeyList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
