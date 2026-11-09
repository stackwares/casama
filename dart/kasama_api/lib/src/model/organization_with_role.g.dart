// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_with_role.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrganizationWithRoleCWProxy {
  OrganizationWithRole id(String id);

  OrganizationWithRole name(String name);

  OrganizationWithRole slug(String slug);

  OrganizationWithRole plan(String plan);

  OrganizationWithRole region(String region);

  OrganizationWithRole createdAt(DateTime createdAt);

  OrganizationWithRole role(OrgRole role);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrganizationWithRole(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrganizationWithRole(...).copyWith(id: 12, name: "My name")
  /// ````
  OrganizationWithRole call({
    String id,
    String name,
    String slug,
    String plan,
    String region,
    DateTime createdAt,
    OrgRole role,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOrganizationWithRole.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOrganizationWithRole.copyWith.fieldName(...)`
class _$OrganizationWithRoleCWProxyImpl
    implements _$OrganizationWithRoleCWProxy {
  const _$OrganizationWithRoleCWProxyImpl(this._value);

  final OrganizationWithRole _value;

  @override
  OrganizationWithRole id(String id) => this(id: id);

  @override
  OrganizationWithRole name(String name) => this(name: name);

  @override
  OrganizationWithRole slug(String slug) => this(slug: slug);

  @override
  OrganizationWithRole plan(String plan) => this(plan: plan);

  @override
  OrganizationWithRole region(String region) => this(region: region);

  @override
  OrganizationWithRole createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  OrganizationWithRole role(OrgRole role) => this(role: role);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrganizationWithRole(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrganizationWithRole(...).copyWith(id: 12, name: "My name")
  /// ````
  OrganizationWithRole call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? region = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return OrganizationWithRole(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      plan: plan == const $CopyWithPlaceholder()
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as String,
      region: region == const $CopyWithPlaceholder()
          ? _value.region
          // ignore: cast_nullable_to_non_nullable
          : region as String,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OrgRole,
    );
  }
}

extension $OrganizationWithRoleCopyWith on OrganizationWithRole {
  /// Returns a callable class that can be used as follows: `instanceOfOrganizationWithRole.copyWith(...)` or like so:`instanceOfOrganizationWithRole.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OrganizationWithRoleCWProxy get copyWith =>
      _$OrganizationWithRoleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrganizationWithRole _$OrganizationWithRoleFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OrganizationWithRole', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'name',
      'slug',
      'plan',
      'region',
      'created_at',
      'role',
    ],
  );
  final val = OrganizationWithRole(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    slug: $checkedConvert('slug', (v) => v as String),
    plan: $checkedConvert('plan', (v) => v as String),
    region: $checkedConvert('region', (v) => v as String),
    createdAt: $checkedConvert(
      'created_at',
      (v) => DateTime.parse(v as String),
    ),
    role: $checkedConvert('role', (v) => $enumDecode(_$OrgRoleEnumMap, v)),
  );
  return val;
}, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$OrganizationWithRoleToJson(
  OrganizationWithRole instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'plan': instance.plan,
  'region': instance.region,
  'created_at': instance.createdAt.toIso8601String(),
  'role': _$OrgRoleEnumMap[instance.role]!,
};

const _$OrgRoleEnumMap = {
  OrgRole.owner: 'owner',
  OrgRole.admin: 'admin',
  OrgRole.member: 'member',
};
