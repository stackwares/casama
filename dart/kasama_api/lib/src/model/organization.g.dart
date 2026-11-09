// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrganizationCWProxy {
  Organization id(String id);

  Organization name(String name);

  Organization slug(String slug);

  Organization plan(String plan);

  Organization region(String region);

  Organization createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Organization(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Organization(...).copyWith(id: 12, name: "My name")
  /// ````
  Organization call({
    String id,
    String name,
    String slug,
    String plan,
    String region,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOrganization.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOrganization.copyWith.fieldName(...)`
class _$OrganizationCWProxyImpl implements _$OrganizationCWProxy {
  const _$OrganizationCWProxyImpl(this._value);

  final Organization _value;

  @override
  Organization id(String id) => this(id: id);

  @override
  Organization name(String name) => this(name: name);

  @override
  Organization slug(String slug) => this(slug: slug);

  @override
  Organization plan(String plan) => this(plan: plan);

  @override
  Organization region(String region) => this(region: region);

  @override
  Organization createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Organization(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Organization(...).copyWith(id: 12, name: "My name")
  /// ````
  Organization call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? region = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Organization(
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
    );
  }
}

extension $OrganizationCopyWith on Organization {
  /// Returns a callable class that can be used as follows: `instanceOfOrganization.copyWith(...)` or like so:`instanceOfOrganization.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OrganizationCWProxy get copyWith => _$OrganizationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Organization', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'slug',
          'plan',
          'region',
          'created_at',
        ],
      );
      final val = Organization(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        plan: $checkedConvert('plan', (v) => v as String),
        region: $checkedConvert('region', (v) => v as String),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'plan': instance.plan,
      'region': instance.region,
      'created_at': instance.createdAt.toIso8601String(),
    };
