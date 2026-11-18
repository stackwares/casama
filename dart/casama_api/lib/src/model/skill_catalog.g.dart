// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_catalog.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillCatalogCWProxy {
  SkillCatalog categories(List<String> categories);

  SkillCatalog items(List<CatalogSkill> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillCatalog call({List<String> categories, List<CatalogSkill> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillCatalog.copyWith(...)` or call `instanceOfSkillCatalog.copyWith.fieldName(value)` for a single field.
class _$SkillCatalogCWProxyImpl implements _$SkillCatalogCWProxy {
  const _$SkillCatalogCWProxyImpl(this._value);

  final SkillCatalog _value;

  @override
  SkillCatalog categories(List<String> categories) =>
      call(categories: categories);

  @override
  SkillCatalog items(List<CatalogSkill> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillCatalog call({
    Object? categories = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return SkillCatalog(
      categories:
          categories == const $CopyWithPlaceholder() || categories == null
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<String>,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CatalogSkill>,
    );
  }
}

extension $SkillCatalogCopyWith on SkillCatalog {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillCatalog.copyWith(...)` or `instanceOfSkillCatalog.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillCatalogCWProxy get copyWith => _$SkillCatalogCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillCatalog _$SkillCatalogFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkillCatalog', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['categories', 'items']);
      final val = SkillCatalog(
        categories: $checkedConvert(
          'categories',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => CatalogSkill.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SkillCatalogToJson(SkillCatalog instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
