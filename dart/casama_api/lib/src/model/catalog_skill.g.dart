// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_skill.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CatalogSkillCWProxy {
  CatalogSkill id(String id);

  CatalogSkill name(String name);

  CatalogSkill description(String description);

  CatalogSkill category(String category);

  CatalogSkill files(List<String> files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogSkill(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogSkill(...).copyWith(id: 12, name: "My name")
  /// ```
  CatalogSkill call({
    String id,
    String name,
    String description,
    String category,
    List<String> files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCatalogSkill.copyWith(...)` or call `instanceOfCatalogSkill.copyWith.fieldName(value)` for a single field.
class _$CatalogSkillCWProxyImpl implements _$CatalogSkillCWProxy {
  const _$CatalogSkillCWProxyImpl(this._value);

  final CatalogSkill _value;

  @override
  CatalogSkill id(String id) => call(id: id);

  @override
  CatalogSkill name(String name) => call(name: name);

  @override
  CatalogSkill description(String description) =>
      call(description: description);

  @override
  CatalogSkill category(String category) => call(category: category);

  @override
  CatalogSkill files(List<String> files) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogSkill(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogSkill(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CatalogSkill call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return CatalogSkill(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      category: category == const $CopyWithPlaceholder() || category == null
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<String>,
    );
  }
}

extension $CatalogSkillCopyWith on CatalogSkill {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCatalogSkill.copyWith(...)` or `instanceOfCatalogSkill.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CatalogSkillCWProxy get copyWith => _$CatalogSkillCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogSkill _$CatalogSkillFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CatalogSkill', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'name', 'description', 'category', 'files'],
      );
      final val = CatalogSkill(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        category: $checkedConvert('category', (v) => v as String),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CatalogSkillToJson(CatalogSkill instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'files': instance.files,
    };
