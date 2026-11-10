// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_app.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderAppCWProxy {
  ProviderApp slug(String slug);

  ProviderApp name(String name);

  ProviderApp description(String description);

  ProviderApp logo(String? logo);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderApp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderApp(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderApp call({
    String slug,
    String name,
    String description,
    String? logo,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderApp.copyWith(...)` or call `instanceOfProviderApp.copyWith.fieldName(value)` for a single field.
class _$ProviderAppCWProxyImpl implements _$ProviderAppCWProxy {
  const _$ProviderAppCWProxyImpl(this._value);

  final ProviderApp _value;

  @override
  ProviderApp slug(String slug) => call(slug: slug);

  @override
  ProviderApp name(String name) => call(name: name);

  @override
  ProviderApp description(String description) => call(description: description);

  @override
  ProviderApp logo(String? logo) => call(logo: logo);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderApp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderApp(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderApp call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? logo = const $CopyWithPlaceholder(),
  }) {
    return ProviderApp(
      slug: slug == const $CopyWithPlaceholder() || slug == null
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      logo: logo == const $CopyWithPlaceholder()
          ? _value.logo
          // ignore: cast_nullable_to_non_nullable
          : logo as String?,
    );
  }
}

extension $ProviderAppCopyWith on ProviderApp {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderApp.copyWith(...)` or `instanceOfProviderApp.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderAppCWProxy get copyWith => _$ProviderAppCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderApp _$ProviderAppFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderApp', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['slug', 'name', 'description', 'logo'],
      );
      final val = ProviderApp(
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        logo: $checkedConvert('logo', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProviderAppToJson(ProviderApp instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'description': instance.description,
      'logo': instance.logo,
    };
