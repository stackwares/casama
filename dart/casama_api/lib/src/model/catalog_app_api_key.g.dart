// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_app_api_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CatalogAppApiKeyCWProxy {
  CatalogAppApiKey label(String label);

  CatalogAppApiKey placeholder(String? placeholder);

  CatalogAppApiKey url(String url);

  CatalogAppApiKey steps(List<String> steps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogAppApiKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogAppApiKey(...).copyWith(id: 12, name: "My name")
  /// ```
  CatalogAppApiKey call({
    String label,
    String? placeholder,
    String url,
    List<String> steps,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCatalogAppApiKey.copyWith(...)` or call `instanceOfCatalogAppApiKey.copyWith.fieldName(value)` for a single field.
class _$CatalogAppApiKeyCWProxyImpl implements _$CatalogAppApiKeyCWProxy {
  const _$CatalogAppApiKeyCWProxyImpl(this._value);

  final CatalogAppApiKey _value;

  @override
  CatalogAppApiKey label(String label) => call(label: label);

  @override
  CatalogAppApiKey placeholder(String? placeholder) =>
      call(placeholder: placeholder);

  @override
  CatalogAppApiKey url(String url) => call(url: url);

  @override
  CatalogAppApiKey steps(List<String> steps) => call(steps: steps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogAppApiKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogAppApiKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CatalogAppApiKey call({
    Object? label = const $CopyWithPlaceholder(),
    Object? placeholder = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
  }) {
    return CatalogAppApiKey(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      placeholder: placeholder == const $CopyWithPlaceholder()
          ? _value.placeholder
          // ignore: cast_nullable_to_non_nullable
          : placeholder as String?,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      steps: steps == const $CopyWithPlaceholder() || steps == null
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<String>,
    );
  }
}

extension $CatalogAppApiKeyCopyWith on CatalogAppApiKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCatalogAppApiKey.copyWith(...)` or `instanceOfCatalogAppApiKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CatalogAppApiKeyCWProxy get copyWith => _$CatalogAppApiKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogAppApiKey _$CatalogAppApiKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CatalogAppApiKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['label', 'url', 'steps']);
      final val = CatalogAppApiKey(
        label: $checkedConvert('label', (v) => v as String),
        placeholder: $checkedConvert('placeholder', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String),
        steps: $checkedConvert(
          'steps',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CatalogAppApiKeyToJson(CatalogAppApiKey instance) =>
    <String, dynamic>{
      'label': instance.label,
      'placeholder': ?instance.placeholder,
      'url': instance.url,
      'steps': instance.steps,
    };
