// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_vendor_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminVendorListCWProxy {
  AdminVendorList items(List<AdminVendor> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminVendorList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminVendorList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminVendorList call({List<AdminVendor> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminVendorList.copyWith(...)` or call `instanceOfAdminVendorList.copyWith.fieldName(value)` for a single field.
class _$AdminVendorListCWProxyImpl implements _$AdminVendorListCWProxy {
  const _$AdminVendorListCWProxyImpl(this._value);

  final AdminVendorList _value;

  @override
  AdminVendorList items(List<AdminVendor> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminVendorList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminVendorList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminVendorList call({Object? items = const $CopyWithPlaceholder()}) {
    return AdminVendorList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminVendor>,
    );
  }
}

extension $AdminVendorListCopyWith on AdminVendorList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminVendorList.copyWith(...)` or `instanceOfAdminVendorList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminVendorListCWProxy get copyWith => _$AdminVendorListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminVendorList _$AdminVendorListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminVendorList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminVendorList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminVendor.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminVendorListToJson(AdminVendorList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
