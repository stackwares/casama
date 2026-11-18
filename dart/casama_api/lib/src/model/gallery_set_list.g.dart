// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_set_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySetListCWProxy {
  GallerySetList items(List<GallerySet> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetList(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySetList call({List<GallerySet> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySetList.copyWith(...)` or call `instanceOfGallerySetList.copyWith.fieldName(value)` for a single field.
class _$GallerySetListCWProxyImpl implements _$GallerySetListCWProxy {
  const _$GallerySetListCWProxyImpl(this._value);

  final GallerySetList _value;

  @override
  GallerySetList items(List<GallerySet> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySetList call({Object? items = const $CopyWithPlaceholder()}) {
    return GallerySetList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GallerySet>,
    );
  }
}

extension $GallerySetListCopyWith on GallerySetList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySetList.copyWith(...)` or `instanceOfGallerySetList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySetListCWProxy get copyWith => _$GallerySetListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySetList _$GallerySetListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GallerySetList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GallerySetList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GallerySet.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GallerySetListToJson(GallerySetList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
