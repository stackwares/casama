// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_option.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelOptionCWProxy {
  ModelOption id(String id);

  ModelOption name(String name);

  ModelOption contextLength(int? contextLength);

  ModelOption featured(bool? featured);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelOption(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelOption(...).copyWith(id: 12, name: "My name")
  /// ```
  ModelOption call({
    String id,
    String name,
    int? contextLength,
    bool? featured,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfModelOption.copyWith(...)` or call `instanceOfModelOption.copyWith.fieldName(value)` for a single field.
class _$ModelOptionCWProxyImpl implements _$ModelOptionCWProxy {
  const _$ModelOptionCWProxyImpl(this._value);

  final ModelOption _value;

  @override
  ModelOption id(String id) => call(id: id);

  @override
  ModelOption name(String name) => call(name: name);

  @override
  ModelOption contextLength(int? contextLength) =>
      call(contextLength: contextLength);

  @override
  ModelOption featured(bool? featured) => call(featured: featured);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelOption(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelOption(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ModelOption call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? contextLength = const $CopyWithPlaceholder(),
    Object? featured = const $CopyWithPlaceholder(),
  }) {
    return ModelOption(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      contextLength: contextLength == const $CopyWithPlaceholder()
          ? _value.contextLength
          // ignore: cast_nullable_to_non_nullable
          : contextLength as int?,
      featured: featured == const $CopyWithPlaceholder()
          ? _value.featured
          // ignore: cast_nullable_to_non_nullable
          : featured as bool?,
    );
  }
}

extension $ModelOptionCopyWith on ModelOption {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfModelOption.copyWith(...)` or `instanceOfModelOption.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelOptionCWProxy get copyWith => _$ModelOptionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelOption _$ModelOptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ModelOption', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = ModelOption(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        contextLength: $checkedConvert(
          'context_length',
          (v) => (v as num?)?.toInt(),
        ),
        featured: $checkedConvert('featured', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'contextLength': 'context_length'});

Map<String, dynamic> _$ModelOptionToJson(ModelOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'context_length': ?instance.contextLength,
      'featured': ?instance.featured,
    };
