// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryItemCWProxy {
  GalleryItem id(String id);

  GalleryItem type(GalleryItemTypeEnum type);

  GalleryItem name(String name);

  GalleryItem author(GalleryAuthor author);

  GalleryItem license(String license);

  GalleryItem tags(List<String> tags);

  GalleryItem featured(bool featured);

  GalleryItem retired(bool retired);

  GalleryItem version(int version);

  GalleryItem sha256(String sha256);

  GalleryItem category(String? category);

  GalleryItem icon(String? icon);

  GalleryItem description(String? description);

  GalleryItem document(Map<String, Object?>? document);

  GalleryItem files(List<String> files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryItem(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryItem call({
    String id,
    GalleryItemTypeEnum type,
    String name,
    GalleryAuthor author,
    String license,
    List<String> tags,
    bool featured,
    bool retired,
    int version,
    String sha256,
    String? category,
    String? icon,
    String? description,
    Map<String, Object?>? document,
    List<String> files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryItem.copyWith(...)` or call `instanceOfGalleryItem.copyWith.fieldName(value)` for a single field.
class _$GalleryItemCWProxyImpl implements _$GalleryItemCWProxy {
  const _$GalleryItemCWProxyImpl(this._value);

  final GalleryItem _value;

  @override
  GalleryItem id(String id) => call(id: id);

  @override
  GalleryItem type(GalleryItemTypeEnum type) => call(type: type);

  @override
  GalleryItem name(String name) => call(name: name);

  @override
  GalleryItem author(GalleryAuthor author) => call(author: author);

  @override
  GalleryItem license(String license) => call(license: license);

  @override
  GalleryItem tags(List<String> tags) => call(tags: tags);

  @override
  GalleryItem featured(bool featured) => call(featured: featured);

  @override
  GalleryItem retired(bool retired) => call(retired: retired);

  @override
  GalleryItem version(int version) => call(version: version);

  @override
  GalleryItem sha256(String sha256) => call(sha256: sha256);

  @override
  GalleryItem category(String? category) => call(category: category);

  @override
  GalleryItem icon(String? icon) => call(icon: icon);

  @override
  GalleryItem description(String? description) =>
      call(description: description);

  @override
  GalleryItem document(Map<String, Object?>? document) =>
      call(document: document);

  @override
  GalleryItem files(List<String> files) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryItem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
    Object? license = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? featured = const $CopyWithPlaceholder(),
    Object? retired = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? sha256 = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? document = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return GalleryItem(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryItemTypeEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      author: author == const $CopyWithPlaceholder() || author == null
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as GalleryAuthor,
      license: license == const $CopyWithPlaceholder() || license == null
          ? _value.license
          // ignore: cast_nullable_to_non_nullable
          : license as String,
      tags: tags == const $CopyWithPlaceholder() || tags == null
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>,
      featured: featured == const $CopyWithPlaceholder() || featured == null
          ? _value.featured
          // ignore: cast_nullable_to_non_nullable
          : featured as bool,
      retired: retired == const $CopyWithPlaceholder() || retired == null
          ? _value.retired
          // ignore: cast_nullable_to_non_nullable
          : retired as bool,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      sha256: sha256 == const $CopyWithPlaceholder() || sha256 == null
          ? _value.sha256
          // ignore: cast_nullable_to_non_nullable
          : sha256 as String,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String?,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      document: document == const $CopyWithPlaceholder()
          ? _value.document
          // ignore: cast_nullable_to_non_nullable
          : document as Map<String, Object?>?,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<String>,
    );
  }
}

extension $GalleryItemCopyWith on GalleryItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryItem.copyWith(...)` or `instanceOfGalleryItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryItemCWProxy get copyWith => _$GalleryItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryItem _$GalleryItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GalleryItem',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'type',
        'name',
        'author',
        'license',
        'tags',
        'featured',
        'retired',
        'version',
        'sha256',
        'files',
      ],
    );
    final val = GalleryItem(
      id: $checkedConvert('id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$GalleryItemTypeEnumEnumMap, v),
      ),
      name: $checkedConvert('name', (v) => v as String),
      author: $checkedConvert(
        'author',
        (v) => GalleryAuthor.fromJson(v as Map<String, dynamic>),
      ),
      license: $checkedConvert('license', (v) => v as String),
      tags: $checkedConvert(
        'tags',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      featured: $checkedConvert('featured', (v) => v as bool),
      retired: $checkedConvert('retired', (v) => v as bool),
      version: $checkedConvert('version', (v) => (v as num).toInt()),
      sha256: $checkedConvert('sha256', (v) => v as String),
      category: $checkedConvert('category', (v) => v as String?),
      icon: $checkedConvert('icon', (v) => v as String?),
      description: $checkedConvert('description', (v) => v as String?),
      document: $checkedConvert('document', (v) => v as Map<String, dynamic>?),
      files: $checkedConvert(
        'files',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$GalleryItemToJson(GalleryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$GalleryItemTypeEnumEnumMap[instance.type]!,
      'name': instance.name,
      'author': instance.author.toJson(),
      'license': instance.license,
      'tags': instance.tags,
      'featured': instance.featured,
      'retired': instance.retired,
      'version': instance.version,
      'sha256': instance.sha256,
      'category': ?instance.category,
      'icon': ?instance.icon,
      'description': ?instance.description,
      'document': ?instance.document,
      'files': instance.files,
    };

const _$GalleryItemTypeEnumEnumMap = {
  GalleryItemTypeEnum.theme: 'theme',
  GalleryItemTypeEnum.scheme: 'scheme',
  GalleryItemTypeEnum.wallpaper: 'wallpaper',
  GalleryItemTypeEnum.skill: 'skill',
};
