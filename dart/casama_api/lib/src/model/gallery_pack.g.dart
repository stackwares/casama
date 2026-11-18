// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_pack.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryPackCWProxy {
  GalleryPack kind(GalleryPackKindEnum kind);

  GalleryPack id(String id);

  GalleryPack name(String name);

  GalleryPack summary(String summary);

  GalleryPack icon(String icon);

  GalleryPack author(TemplateAuthor author);

  GalleryPack featured(bool featured);

  GalleryPack reviewed(bool reviewed);

  GalleryPack url(String? url);

  GalleryPack commit(String? commit);

  GalleryPack contents(GalleryPackContents? contents);

  GalleryPack setItems(List<GalleryPackSetItemsInner>? setItems);

  GalleryPack tags(List<String> tags);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPack(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryPack call({
    GalleryPackKindEnum kind,
    String id,
    String name,
    String summary,
    String icon,
    TemplateAuthor author,
    bool featured,
    bool reviewed,
    String? url,
    String? commit,
    GalleryPackContents? contents,
    List<GalleryPackSetItemsInner>? setItems,
    List<String> tags,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryPack.copyWith(...)` or call `instanceOfGalleryPack.copyWith.fieldName(value)` for a single field.
class _$GalleryPackCWProxyImpl implements _$GalleryPackCWProxy {
  const _$GalleryPackCWProxyImpl(this._value);

  final GalleryPack _value;

  @override
  GalleryPack kind(GalleryPackKindEnum kind) => call(kind: kind);

  @override
  GalleryPack id(String id) => call(id: id);

  @override
  GalleryPack name(String name) => call(name: name);

  @override
  GalleryPack summary(String summary) => call(summary: summary);

  @override
  GalleryPack icon(String icon) => call(icon: icon);

  @override
  GalleryPack author(TemplateAuthor author) => call(author: author);

  @override
  GalleryPack featured(bool featured) => call(featured: featured);

  @override
  GalleryPack reviewed(bool reviewed) => call(reviewed: reviewed);

  @override
  GalleryPack url(String? url) => call(url: url);

  @override
  GalleryPack commit(String? commit) => call(commit: commit);

  @override
  GalleryPack contents(GalleryPackContents? contents) =>
      call(contents: contents);

  @override
  GalleryPack setItems(List<GalleryPackSetItemsInner>? setItems) =>
      call(setItems: setItems);

  @override
  GalleryPack tags(List<String> tags) => call(tags: tags);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPack(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryPack call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
    Object? featured = const $CopyWithPlaceholder(),
    Object? reviewed = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? contents = const $CopyWithPlaceholder(),
    Object? setItems = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
  }) {
    return GalleryPack(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GalleryPackKindEnum,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      icon: icon == const $CopyWithPlaceholder() || icon == null
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      author: author == const $CopyWithPlaceholder() || author == null
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as TemplateAuthor,
      featured: featured == const $CopyWithPlaceholder() || featured == null
          ? _value.featured
          // ignore: cast_nullable_to_non_nullable
          : featured as bool,
      reviewed: reviewed == const $CopyWithPlaceholder() || reviewed == null
          ? _value.reviewed
          // ignore: cast_nullable_to_non_nullable
          : reviewed as bool,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
      contents: contents == const $CopyWithPlaceholder()
          ? _value.contents
          // ignore: cast_nullable_to_non_nullable
          : contents as GalleryPackContents?,
      setItems: setItems == const $CopyWithPlaceholder()
          ? _value.setItems
          // ignore: cast_nullable_to_non_nullable
          : setItems as List<GalleryPackSetItemsInner>?,
      tags: tags == const $CopyWithPlaceholder() || tags == null
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>,
    );
  }
}

extension $GalleryPackCopyWith on GalleryPack {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryPack.copyWith(...)` or `instanceOfGalleryPack.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryPackCWProxy get copyWith => _$GalleryPackCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryPack _$GalleryPackFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GalleryPack',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'kind',
        'id',
        'name',
        'summary',
        'icon',
        'author',
        'featured',
        'reviewed',
        'url',
        'commit',
        'contents',
        'set_items',
        'tags',
      ],
    );
    final val = GalleryPack(
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$GalleryPackKindEnumEnumMap, v),
      ),
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      summary: $checkedConvert('summary', (v) => v as String),
      icon: $checkedConvert('icon', (v) => v as String),
      author: $checkedConvert(
        'author',
        (v) => TemplateAuthor.fromJson(v as Map<String, dynamic>),
      ),
      featured: $checkedConvert('featured', (v) => v as bool),
      reviewed: $checkedConvert('reviewed', (v) => v as bool),
      url: $checkedConvert('url', (v) => v as String?),
      commit: $checkedConvert('commit', (v) => v as String?),
      contents: $checkedConvert(
        'contents',
        (v) => v == null
            ? null
            : GalleryPackContents.fromJson(v as Map<String, dynamic>),
      ),
      setItems: $checkedConvert(
        'set_items',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) =>
                  GalleryPackSetItemsInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      tags: $checkedConvert(
        'tags',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'setItems': 'set_items'},
);

Map<String, dynamic> _$GalleryPackToJson(GalleryPack instance) =>
    <String, dynamic>{
      'kind': _$GalleryPackKindEnumEnumMap[instance.kind]!,
      'id': instance.id,
      'name': instance.name,
      'summary': instance.summary,
      'icon': instance.icon,
      'author': instance.author.toJson(),
      'featured': instance.featured,
      'reviewed': instance.reviewed,
      'url': instance.url,
      'commit': instance.commit,
      'contents': instance.contents?.toJson(),
      'set_items': instance.setItems?.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
    };

const _$GalleryPackKindEnumEnumMap = {
  GalleryPackKindEnum.set_: 'set',
  GalleryPackKindEnum.pack: 'pack',
};
