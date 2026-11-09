// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_organization_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateOrganizationRequestCWProxy {
  CreateOrganizationRequest name(String name);

  CreateOrganizationRequest slug(String? slug);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateOrganizationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateOrganizationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateOrganizationRequest call({String name, String? slug});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateOrganizationRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateOrganizationRequest.copyWith.fieldName(...)`
class _$CreateOrganizationRequestCWProxyImpl
    implements _$CreateOrganizationRequestCWProxy {
  const _$CreateOrganizationRequestCWProxyImpl(this._value);

  final CreateOrganizationRequest _value;

  @override
  CreateOrganizationRequest name(String name) => this(name: name);

  @override
  CreateOrganizationRequest slug(String? slug) => this(slug: slug);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateOrganizationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateOrganizationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateOrganizationRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
  }) {
    return CreateOrganizationRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String?,
    );
  }
}

extension $CreateOrganizationRequestCopyWith on CreateOrganizationRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateOrganizationRequest.copyWith(...)` or like so:`instanceOfCreateOrganizationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateOrganizationRequestCWProxy get copyWith =>
      _$CreateOrganizationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrganizationRequest _$CreateOrganizationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateOrganizationRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = CreateOrganizationRequest(
    name: $checkedConvert('name', (v) => v as String),
    slug: $checkedConvert('slug', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$CreateOrganizationRequestToJson(
  CreateOrganizationRequest instance,
) => <String, dynamic>{'name': instance.name, 'slug': ?instance.slug};
