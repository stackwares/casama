// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_pack_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryPackListCWProxy {
  GalleryPackList items(List<GalleryPack> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPackList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPackList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryPackList call({List<GalleryPack> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryPackList.copyWith(...)` or call `instanceOfGalleryPackList.copyWith.fieldName(value)` for a single field.
class _$GalleryPackListCWProxyImpl implements _$GalleryPackListCWProxy {
  const _$GalleryPackListCWProxyImpl(this._value);

  final GalleryPackList _value;

  @override
  GalleryPackList items(List<GalleryPack> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPackList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPackList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryPackList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryPackList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryPack>,
    );
  }
}

extension $GalleryPackListCopyWith on GalleryPackList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryPackList.copyWith(...)` or `instanceOfGalleryPackList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryPackListCWProxy get copyWith => _$GalleryPackListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryPackList _$GalleryPackListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryPackList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GalleryPackList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GalleryPack.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryPackListToJson(GalleryPackList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
