// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_service_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminServiceListCWProxy {
  AdminServiceList items(List<AdminService> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminServiceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminServiceList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminServiceList call({List<AdminService> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminServiceList.copyWith(...)` or call `instanceOfAdminServiceList.copyWith.fieldName(value)` for a single field.
class _$AdminServiceListCWProxyImpl implements _$AdminServiceListCWProxy {
  const _$AdminServiceListCWProxyImpl(this._value);

  final AdminServiceList _value;

  @override
  AdminServiceList items(List<AdminService> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminServiceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminServiceList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminServiceList call({Object? items = const $CopyWithPlaceholder()}) {
    return AdminServiceList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminService>,
    );
  }
}

extension $AdminServiceListCopyWith on AdminServiceList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminServiceList.copyWith(...)` or `instanceOfAdminServiceList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminServiceListCWProxy get copyWith => _$AdminServiceListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminServiceList _$AdminServiceListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminServiceList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminServiceList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminService.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminServiceListToJson(AdminServiceList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
