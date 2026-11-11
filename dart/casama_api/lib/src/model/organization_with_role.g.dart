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

  OrganizationWithRole icon(String? icon);

  OrganizationWithRole color(String? color);

  OrganizationWithRole createdAt(DateTime createdAt);

  OrganizationWithRole role(OrgRole role);

  OrganizationWithRole requireMfa(bool? requireMfa);

  OrganizationWithRole suspended(bool? suspended);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrganizationWithRole(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrganizationWithRole(...).copyWith(id: 12, name: "My name")
  /// ```
  OrganizationWithRole call({
    String id,
    String name,
    String slug,
    String plan,
    String region,
    String? icon,
    String? color,
    DateTime createdAt,
    OrgRole role,
    bool? requireMfa,
    bool? suspended,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOrganizationWithRole.copyWith(...)` or call `instanceOfOrganizationWithRole.copyWith.fieldName(value)` for a single field.
class _$OrganizationWithRoleCWProxyImpl
    implements _$OrganizationWithRoleCWProxy {
  const _$OrganizationWithRoleCWProxyImpl(this._value);

  final OrganizationWithRole _value;

  @override
  OrganizationWithRole id(String id) => call(id: id);

  @override
  OrganizationWithRole name(String name) => call(name: name);

  @override
  OrganizationWithRole slug(String slug) => call(slug: slug);

  @override
  OrganizationWithRole plan(String plan) => call(plan: plan);

  @override
  OrganizationWithRole region(String region) => call(region: region);

  @override
  OrganizationWithRole icon(String? icon) => call(icon: icon);

  @override
  OrganizationWithRole color(String? color) => call(color: color);

  @override
  OrganizationWithRole createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  @override
  OrganizationWithRole role(OrgRole role) => call(role: role);

  @override
  OrganizationWithRole requireMfa(bool? requireMfa) =>
      call(requireMfa: requireMfa);

  @override
  OrganizationWithRole suspended(bool? suspended) => call(suspended: suspended);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrganizationWithRole(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrganizationWithRole(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OrganizationWithRole call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? region = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? requireMfa = const $CopyWithPlaceholder(),
    Object? suspended = const $CopyWithPlaceholder(),
  }) {
    return OrganizationWithRole(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      slug: slug == const $CopyWithPlaceholder() || slug == null
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      plan: plan == const $CopyWithPlaceholder() || plan == null
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as String,
      region: region == const $CopyWithPlaceholder() || region == null
          ? _value.region
          // ignore: cast_nullable_to_non_nullable
          : region as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OrgRole,
      requireMfa: requireMfa == const $CopyWithPlaceholder()
          ? _value.requireMfa
          // ignore: cast_nullable_to_non_nullable
          : requireMfa as bool?,
      suspended: suspended == const $CopyWithPlaceholder()
          ? _value.suspended
          // ignore: cast_nullable_to_non_nullable
          : suspended as bool?,
    );
  }
}

extension $OrganizationWithRoleCopyWith on OrganizationWithRole {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOrganizationWithRole.copyWith(...)` or `instanceOfOrganizationWithRole.copyWith.fieldName(...)`.
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
    icon: $checkedConvert('icon', (v) => v as String?),
    color: $checkedConvert('color', (v) => v as String?),
    createdAt: $checkedConvert(
      'created_at',
      (v) => DateTime.parse(v as String),
    ),
    role: $checkedConvert('role', (v) => $enumDecode(_$OrgRoleEnumMap, v)),
    requireMfa: $checkedConvert('require_mfa', (v) => v as bool?),
    suspended: $checkedConvert('suspended', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'createdAt': 'created_at', 'requireMfa': 'require_mfa'});

Map<String, dynamic> _$OrganizationWithRoleToJson(
  OrganizationWithRole instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'plan': instance.plan,
  'region': instance.region,
  'icon': ?instance.icon,
  'color': ?instance.color,
  'created_at': instance.createdAt.toIso8601String(),
  'role': _$OrgRoleEnumMap[instance.role]!,
  'require_mfa': ?instance.requireMfa,
  'suspended': ?instance.suspended,
};

const _$OrgRoleEnumMap = {
  OrgRole.owner: 'owner',
  OrgRole.admin: 'admin',
  OrgRole.member: 'member',
};
