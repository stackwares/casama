// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_device_key_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDeviceKeyListCWProxy {
  AdminDeviceKeyList items(List<AdminDeviceKey> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDeviceKeyList call({List<AdminDeviceKey> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDeviceKeyList.copyWith(...)` or call `instanceOfAdminDeviceKeyList.copyWith.fieldName(value)` for a single field.
class _$AdminDeviceKeyListCWProxyImpl implements _$AdminDeviceKeyListCWProxy {
  const _$AdminDeviceKeyListCWProxyImpl(this._value);

  final AdminDeviceKeyList _value;

  @override
  AdminDeviceKeyList items(List<AdminDeviceKey> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDeviceKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDeviceKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDeviceKeyList call({Object? items = const $CopyWithPlaceholder()}) {
    return AdminDeviceKeyList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminDeviceKey>,
    );
  }
}

extension $AdminDeviceKeyListCopyWith on AdminDeviceKeyList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDeviceKeyList.copyWith(...)` or `instanceOfAdminDeviceKeyList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDeviceKeyListCWProxy get copyWith =>
      _$AdminDeviceKeyListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDeviceKeyList _$AdminDeviceKeyListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDeviceKeyList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminDeviceKeyList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminDeviceKey.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminDeviceKeyListToJson(AdminDeviceKeyList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
