// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryListCWProxy {
  GalleryList available(bool available);

  GalleryList items(List<GalleryItem> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryList call({bool available, List<GalleryItem> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryList.copyWith(...)` or call `instanceOfGalleryList.copyWith.fieldName(value)` for a single field.
class _$GalleryListCWProxyImpl implements _$GalleryListCWProxy {
  const _$GalleryListCWProxyImpl(this._value);

  final GalleryList _value;

  @override
  GalleryList available(bool available) => call(available: available);

  @override
  GalleryList items(List<GalleryItem> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryList call({
    Object? available = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return GalleryList(
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryItem>,
    );
  }
}

extension $GalleryListCopyWith on GalleryList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryList.copyWith(...)` or `instanceOfGalleryList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryListCWProxy get copyWith => _$GalleryListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryList _$GalleryListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['available', 'items']);
      final val = GalleryList(
        available: $checkedConvert('available', (v) => v as bool),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GalleryItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryListToJson(GalleryList instance) =>
    <String, dynamic>{
      'available': instance.available,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
