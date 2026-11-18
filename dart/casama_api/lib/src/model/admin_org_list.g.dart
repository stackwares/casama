// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_org_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminOrgListCWProxy {
  AdminOrgList items(List<AdminOrg> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminOrgList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminOrgList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminOrgList call({List<AdminOrg> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminOrgList.copyWith(...)` or call `instanceOfAdminOrgList.copyWith.fieldName(value)` for a single field.
class _$AdminOrgListCWProxyImpl implements _$AdminOrgListCWProxy {
  const _$AdminOrgListCWProxyImpl(this._value);

  final AdminOrgList _value;

  @override
  AdminOrgList items(List<AdminOrg> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminOrgList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminOrgList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminOrgList call({Object? items = const $CopyWithPlaceholder()}) {
    return AdminOrgList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminOrg>,
    );
  }
}

extension $AdminOrgListCopyWith on AdminOrgList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminOrgList.copyWith(...)` or `instanceOfAdminOrgList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminOrgListCWProxy get copyWith => _$AdminOrgListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOrgList _$AdminOrgListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminOrgList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminOrgList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminOrg.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminOrgListToJson(AdminOrgList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
