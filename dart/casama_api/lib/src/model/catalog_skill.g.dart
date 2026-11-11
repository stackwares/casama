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

  CatalogSkill icon(String? icon);

  CatalogSkill files(List<String> files);

  CatalogSkill skillMd(String? skillMd);

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
    String? icon,
    List<String> files,
    String? skillMd,
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
  CatalogSkill icon(String? icon) => call(icon: icon);

  @override
  CatalogSkill files(List<String> files) => call(files: files);

  @override
  CatalogSkill skillMd(String? skillMd) => call(skillMd: skillMd);

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
    Object? icon = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? skillMd = const $CopyWithPlaceholder(),
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
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<String>,
      skillMd: skillMd == const $CopyWithPlaceholder()
          ? _value.skillMd
          // ignore: cast_nullable_to_non_nullable
          : skillMd as String?,
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
        icon: $checkedConvert('icon', (v) => v as String?),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        skillMd: $checkedConvert('skill_md', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'skillMd': 'skill_md'});

Map<String, dynamic> _$CatalogSkillToJson(CatalogSkill instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'icon': ?instance.icon,
      'files': instance.files,
      'skill_md': ?instance.skillMd,
    };
