// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_author_item_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAuthorItemListCWProxy {
  GalleryAuthorItemList items(List<GalleryAuthorItem> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorItemList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorItemList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAuthorItemList call({List<GalleryAuthorItem> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAuthorItemList.copyWith(...)` or call `instanceOfGalleryAuthorItemList.copyWith.fieldName(value)` for a single field.
class _$GalleryAuthorItemListCWProxyImpl
    implements _$GalleryAuthorItemListCWProxy {
  const _$GalleryAuthorItemListCWProxyImpl(this._value);

  final GalleryAuthorItemList _value;

  @override
  GalleryAuthorItemList items(List<GalleryAuthorItem> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorItemList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorItemList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAuthorItemList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryAuthorItemList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryAuthorItem>,
    );
  }
}

extension $GalleryAuthorItemListCopyWith on GalleryAuthorItemList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAuthorItemList.copyWith(...)` or `instanceOfGalleryAuthorItemList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAuthorItemListCWProxy get copyWith =>
      _$GalleryAuthorItemListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAuthorItemList _$GalleryAuthorItemListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryAuthorItemList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = GalleryAuthorItemList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => GalleryAuthorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$GalleryAuthorItemListToJson(
  GalleryAuthorItemList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
