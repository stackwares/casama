// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_set.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySetCWProxy {
  GallerySet id(String id);

  GallerySet name(String name);

  GallerySet description(String description);

  GallerySet icon(String icon);

  GallerySet author(GalleryAuthor author);

  GallerySet featured(bool featured);

  GallerySet items(List<GalleryRef> items);

  GallerySet source_(String? source_);

  GallerySet added(String? added);

  GallerySet cover(String? cover);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySet(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySet(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySet call({
    String id,
    String name,
    String description,
    String icon,
    GalleryAuthor author,
    bool featured,
    List<GalleryRef> items,
    String? source_,
    String? added,
    String? cover,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySet.copyWith(...)` or call `instanceOfGallerySet.copyWith.fieldName(value)` for a single field.
class _$GallerySetCWProxyImpl implements _$GallerySetCWProxy {
  const _$GallerySetCWProxyImpl(this._value);

  final GallerySet _value;

  @override
  GallerySet id(String id) => call(id: id);

  @override
  GallerySet name(String name) => call(name: name);

  @override
  GallerySet description(String description) => call(description: description);

  @override
  GallerySet icon(String icon) => call(icon: icon);

  @override
  GallerySet author(GalleryAuthor author) => call(author: author);

  @override
  GallerySet featured(bool featured) => call(featured: featured);

  @override
  GallerySet items(List<GalleryRef> items) => call(items: items);

  @override
  GallerySet source_(String? source_) => call(source_: source_);

  @override
  GallerySet added(String? added) => call(added: added);

  @override
  GallerySet cover(String? cover) => call(cover: cover);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySet(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySet(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySet call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
    Object? featured = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? added = const $CopyWithPlaceholder(),
    Object? cover = const $CopyWithPlaceholder(),
  }) {
    return GallerySet(
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
      icon: icon == const $CopyWithPlaceholder() || icon == null
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      author: author == const $CopyWithPlaceholder() || author == null
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as GalleryAuthor,
      featured: featured == const $CopyWithPlaceholder() || featured == null
          ? _value.featured
          // ignore: cast_nullable_to_non_nullable
          : featured as bool,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryRef>,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String?,
      added: added == const $CopyWithPlaceholder()
          ? _value.added
          // ignore: cast_nullable_to_non_nullable
          : added as String?,
      cover: cover == const $CopyWithPlaceholder()
          ? _value.cover
          // ignore: cast_nullable_to_non_nullable
          : cover as String?,
    );
  }
}

extension $GallerySetCopyWith on GallerySet {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySet.copyWith(...)` or `instanceOfGallerySet.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySetCWProxy get copyWith => _$GallerySetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySet _$GallerySetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GallerySet', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'description',
          'icon',
          'author',
          'featured',
          'items',
        ],
      );
      final val = GallerySet(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        icon: $checkedConvert('icon', (v) => v as String),
        author: $checkedConvert(
          'author',
          (v) => GalleryAuthor.fromJson(v as Map<String, dynamic>),
        ),
        featured: $checkedConvert('featured', (v) => v as bool),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GalleryRef.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        source_: $checkedConvert('source', (v) => v as String?),
        added: $checkedConvert('added', (v) => v as String?),
        cover: $checkedConvert('cover', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$GallerySetToJson(GallerySet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'author': instance.author.toJson(),
      'featured': instance.featured,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'source': ?instance.source_,
      'added': ?instance.added,
      'cover': ?instance.cover,
    };
