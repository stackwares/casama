// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_request_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryRequestListCWProxy {
  GalleryRequestList items(List<GalleryRequest> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryRequestList call({List<GalleryRequest> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryRequestList.copyWith(...)` or call `instanceOfGalleryRequestList.copyWith.fieldName(value)` for a single field.
class _$GalleryRequestListCWProxyImpl implements _$GalleryRequestListCWProxy {
  const _$GalleryRequestListCWProxyImpl(this._value);

  final GalleryRequestList _value;

  @override
  GalleryRequestList items(List<GalleryRequest> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryRequestList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryRequestList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryRequest>,
    );
  }
}

extension $GalleryRequestListCopyWith on GalleryRequestList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryRequestList.copyWith(...)` or `instanceOfGalleryRequestList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryRequestListCWProxy get copyWith =>
      _$GalleryRequestListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryRequestList _$GalleryRequestListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryRequestList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GalleryRequestList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GalleryRequest.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryRequestListToJson(GalleryRequestList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
