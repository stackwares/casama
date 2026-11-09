// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MembershipCWProxy {
  Membership id(String id);

  Membership orgId(String orgId);

  Membership userId(String userId);

  Membership role(OrgRole role);

  Membership createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Membership(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Membership(...).copyWith(id: 12, name: "My name")
  /// ```
  Membership call({
    String id,
    String orgId,
    String userId,
    OrgRole role,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMembership.copyWith(...)` or call `instanceOfMembership.copyWith.fieldName(value)` for a single field.
class _$MembershipCWProxyImpl implements _$MembershipCWProxy {
  const _$MembershipCWProxyImpl(this._value);

  final Membership _value;

  @override
  Membership id(String id) => call(id: id);

  @override
  Membership orgId(String orgId) => call(orgId: orgId);

  @override
  Membership userId(String userId) => call(userId: userId);

  @override
  Membership role(OrgRole role) => call(role: role);

  @override
  Membership createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Membership(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Membership(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Membership call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Membership(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OrgRole,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $MembershipCopyWith on Membership {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMembership.copyWith(...)` or `instanceOfMembership.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MembershipCWProxy get copyWith => _$MembershipCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Membership _$MembershipFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Membership',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['id', 'org_id', 'user_id', 'role', 'created_at'],
    );
    final val = Membership(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      userId: $checkedConvert('user_id', (v) => v as String),
      role: $checkedConvert('role', (v) => $enumDecode(_$OrgRoleEnumMap, v)),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'userId': 'user_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$MembershipToJson(Membership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'user_id': instance.userId,
      'role': _$OrgRoleEnumMap[instance.role]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$OrgRoleEnumMap = {
  OrgRole.owner: 'owner',
  OrgRole.admin: 'admin',
  OrgRole.member: 'member',
};
