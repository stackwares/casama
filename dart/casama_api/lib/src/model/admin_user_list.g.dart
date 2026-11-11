// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserListCWProxy {
  AdminUserList items(List<AdminUser> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminUserList call({List<AdminUser> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminUserList.copyWith(...)` or call `instanceOfAdminUserList.copyWith.fieldName(value)` for a single field.
class _$AdminUserListCWProxyImpl implements _$AdminUserListCWProxy {
  const _$AdminUserListCWProxyImpl(this._value);

  final AdminUserList _value;

  @override
  AdminUserList items(List<AdminUser> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminUserList call({Object? items = const $CopyWithPlaceholder()}) {
    return AdminUserList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminUser>,
    );
  }
}

extension $AdminUserListCopyWith on AdminUserList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminUserList.copyWith(...)` or `instanceOfAdminUserList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserListCWProxy get copyWith => _$AdminUserListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserList _$AdminUserListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminUserList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminUserList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminUserListToJson(AdminUserList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
