// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_organization_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateOrganizationRequestCWProxy {
  CreateOrganizationRequest name(String name);

  CreateOrganizationRequest slug(String? slug);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateOrganizationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateOrganizationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateOrganizationRequest call({String name, String? slug});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateOrganizationRequest.copyWith(...)` or call `instanceOfCreateOrganizationRequest.copyWith.fieldName(value)` for a single field.
class _$CreateOrganizationRequestCWProxyImpl
    implements _$CreateOrganizationRequestCWProxy {
  const _$CreateOrganizationRequestCWProxyImpl(this._value);

  final CreateOrganizationRequest _value;

  @override
  CreateOrganizationRequest name(String name) => call(name: name);

  @override
  CreateOrganizationRequest slug(String? slug) => call(slug: slug);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateOrganizationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateOrganizationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateOrganizationRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
  }) {
    return CreateOrganizationRequest(
      name: name == const $CopyWithPlaceholder() || name == null
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateOrganizationRequest.copyWith(...)` or `instanceOfCreateOrganizationRequest.copyWith.fieldName(...)`.
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
