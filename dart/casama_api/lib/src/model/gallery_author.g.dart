// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_author.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAuthorCWProxy {
  GalleryAuthor name(String name);

  GalleryAuthor url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthor(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAuthor call({String name, String? url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAuthor.copyWith(...)` or call `instanceOfGalleryAuthor.copyWith.fieldName(value)` for a single field.
class _$GalleryAuthorCWProxyImpl implements _$GalleryAuthorCWProxy {
  const _$GalleryAuthorCWProxyImpl(this._value);

  final GalleryAuthor _value;

  @override
  GalleryAuthor name(String name) => call(name: name);

  @override
  GalleryAuthor url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthor(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAuthor call({
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return GalleryAuthor(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $GalleryAuthorCopyWith on GalleryAuthor {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAuthor.copyWith(...)` or `instanceOfGalleryAuthor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAuthorCWProxy get copyWith => _$GalleryAuthorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAuthor _$GalleryAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryAuthor', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = GalleryAuthor(
        name: $checkedConvert('name', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$GalleryAuthorToJson(GalleryAuthor instance) =>
    <String, dynamic>{'name': instance.name, 'url': ?instance.url};
