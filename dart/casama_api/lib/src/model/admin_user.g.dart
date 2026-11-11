// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserCWProxy {
  AdminUser id(String id);

  AdminUser email(String? email);

  AdminUser createdAt(DateTime createdAt);

  AdminUser lastSignInAt(DateTime? lastSignInAt);

  AdminUser orgs(int orgs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUser(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUser(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminUser call({
    String id,
    String? email,
    DateTime createdAt,
    DateTime? lastSignInAt,
    int orgs,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminUser.copyWith(...)` or call `instanceOfAdminUser.copyWith.fieldName(value)` for a single field.
class _$AdminUserCWProxyImpl implements _$AdminUserCWProxy {
  const _$AdminUserCWProxyImpl(this._value);

  final AdminUser _value;

  @override
  AdminUser id(String id) => call(id: id);

  @override
  AdminUser email(String? email) => call(email: email);

  @override
  AdminUser createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  AdminUser lastSignInAt(DateTime? lastSignInAt) =>
      call(lastSignInAt: lastSignInAt);

  @override
  AdminUser orgs(int orgs) => call(orgs: orgs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUser(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUser(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminUser call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? lastSignInAt = const $CopyWithPlaceholder(),
    Object? orgs = const $CopyWithPlaceholder(),
  }) {
    return AdminUser(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      lastSignInAt: lastSignInAt == const $CopyWithPlaceholder()
          ? _value.lastSignInAt
          // ignore: cast_nullable_to_non_nullable
          : lastSignInAt as DateTime?,
      orgs: orgs == const $CopyWithPlaceholder() || orgs == null
          ? _value.orgs
          // ignore: cast_nullable_to_non_nullable
          : orgs as int,
    );
  }
}

extension $AdminUserCopyWith on AdminUser {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminUser.copyWith(...)` or `instanceOfAdminUser.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserCWProxy get copyWith => _$AdminUserCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminUser',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'email',
        'created_at',
        'last_sign_in_at',
        'orgs',
      ],
    );
    final val = AdminUser(
      id: $checkedConvert('id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      lastSignInAt: $checkedConvert(
        'last_sign_in_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      orgs: $checkedConvert('orgs', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'lastSignInAt': 'last_sign_in_at',
  },
);

Map<String, dynamic> _$AdminUserToJson(AdminUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'created_at': instance.createdAt.toIso8601String(),
  'last_sign_in_at': instance.lastSignInAt?.toIso8601String(),
  'orgs': instance.orgs,
};
