// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_author_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAuthorListCWProxy {
  GalleryAuthorList items(List<GalleryAuthorProfile> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAuthorList call({List<GalleryAuthorProfile> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAuthorList.copyWith(...)` or call `instanceOfGalleryAuthorList.copyWith.fieldName(value)` for a single field.
class _$GalleryAuthorListCWProxyImpl implements _$GalleryAuthorListCWProxy {
  const _$GalleryAuthorListCWProxyImpl(this._value);

  final GalleryAuthorList _value;

  @override
  GalleryAuthorList items(List<GalleryAuthorProfile> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAuthorList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryAuthorList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryAuthorProfile>,
    );
  }
}

extension $GalleryAuthorListCopyWith on GalleryAuthorList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAuthorList.copyWith(...)` or `instanceOfGalleryAuthorList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAuthorListCWProxy get copyWith =>
      _$GalleryAuthorListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAuthorList _$GalleryAuthorListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryAuthorList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GalleryAuthorList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => GalleryAuthorProfile.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryAuthorListToJson(GalleryAuthorList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
