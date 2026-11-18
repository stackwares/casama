// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_author_profile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAuthorProfileCWProxy {
  GalleryAuthorProfile handle(String handle);

  GalleryAuthorProfile name(String name);

  GalleryAuthorProfile url(String? url);

  GalleryAuthorProfile items(List<GalleryRef> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAuthorProfile call({
    String handle,
    String name,
    String? url,
    List<GalleryRef> items,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAuthorProfile.copyWith(...)` or call `instanceOfGalleryAuthorProfile.copyWith.fieldName(value)` for a single field.
class _$GalleryAuthorProfileCWProxyImpl
    implements _$GalleryAuthorProfileCWProxy {
  const _$GalleryAuthorProfileCWProxyImpl(this._value);

  final GalleryAuthorProfile _value;

  @override
  GalleryAuthorProfile handle(String handle) => call(handle: handle);

  @override
  GalleryAuthorProfile name(String name) => call(name: name);

  @override
  GalleryAuthorProfile url(String? url) => call(url: url);

  @override
  GalleryAuthorProfile items(List<GalleryRef> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAuthorProfile call({
    Object? handle = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return GalleryAuthorProfile(
      handle: handle == const $CopyWithPlaceholder() || handle == null
          ? _value.handle
          // ignore: cast_nullable_to_non_nullable
          : handle as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryRef>,
    );
  }
}

extension $GalleryAuthorProfileCopyWith on GalleryAuthorProfile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAuthorProfile.copyWith(...)` or `instanceOfGalleryAuthorProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAuthorProfileCWProxy get copyWith =>
      _$GalleryAuthorProfileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAuthorProfile _$GalleryAuthorProfileFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryAuthorProfile', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['handle', 'name', 'items']);
  final val = GalleryAuthorProfile(
    handle: $checkedConvert('handle', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String?),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => GalleryRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$GalleryAuthorProfileToJson(
  GalleryAuthorProfile instance,
) => <String, dynamic>{
  'handle': instance.handle,
  'name': instance.name,
  'url': ?instance.url,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
