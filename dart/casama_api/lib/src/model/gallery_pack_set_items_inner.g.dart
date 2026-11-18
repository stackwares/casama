// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_pack_set_items_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryPackSetItemsInnerCWProxy {
  GalleryPackSetItemsInner type(String type);

  GalleryPackSetItemsInner id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPackSetItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPackSetItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryPackSetItemsInner call({String type, String id});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryPackSetItemsInner.copyWith(...)` or call `instanceOfGalleryPackSetItemsInner.copyWith.fieldName(value)` for a single field.
class _$GalleryPackSetItemsInnerCWProxyImpl
    implements _$GalleryPackSetItemsInnerCWProxy {
  const _$GalleryPackSetItemsInnerCWProxyImpl(this._value);

  final GalleryPackSetItemsInner _value;

  @override
  GalleryPackSetItemsInner type(String type) => call(type: type);

  @override
  GalleryPackSetItemsInner id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPackSetItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPackSetItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryPackSetItemsInner call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return GalleryPackSetItemsInner(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $GalleryPackSetItemsInnerCopyWith on GalleryPackSetItemsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryPackSetItemsInner.copyWith(...)` or `instanceOfGalleryPackSetItemsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryPackSetItemsInnerCWProxy get copyWith =>
      _$GalleryPackSetItemsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryPackSetItemsInner _$GalleryPackSetItemsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryPackSetItemsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['type', 'id']);
  final val = GalleryPackSetItemsInner(
    type: $checkedConvert('type', (v) => v as String),
    id: $checkedConvert('id', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$GalleryPackSetItemsInnerToJson(
  GalleryPackSetItemsInner instance,
) => <String, dynamic>{'type': instance.type, 'id': instance.id};
