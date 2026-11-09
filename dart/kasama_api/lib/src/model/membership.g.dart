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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Membership(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Membership(...).copyWith(id: 12, name: "My name")
  /// ````
  Membership call({
    String id,
    String orgId,
    String userId,
    OrgRole role,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMembership.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMembership.copyWith.fieldName(...)`
class _$MembershipCWProxyImpl implements _$MembershipCWProxy {
  const _$MembershipCWProxyImpl(this._value);

  final Membership _value;

  @override
  Membership id(String id) => this(id: id);

  @override
  Membership orgId(String orgId) => this(orgId: orgId);

  @override
  Membership userId(String userId) => this(userId: userId);

  @override
  Membership role(OrgRole role) => this(role: role);

  @override
  Membership createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Membership(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Membership(...).copyWith(id: 12, name: "My name")
  /// ````
  Membership call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Membership(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OrgRole,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $MembershipCopyWith on Membership {
  /// Returns a callable class that can be used as follows: `instanceOfMembership.copyWith(...)` or like so:`instanceOfMembership.copyWith.fieldName(...)`.
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
