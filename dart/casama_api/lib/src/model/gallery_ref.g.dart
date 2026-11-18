// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryRefCWProxy {
  GalleryRef type(String type);

  GalleryRef id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryRef(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryRef call({String type, String id});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryRef.copyWith(...)` or call `instanceOfGalleryRef.copyWith.fieldName(value)` for a single field.
class _$GalleryRefCWProxyImpl implements _$GalleryRefCWProxy {
  const _$GalleryRefCWProxyImpl(this._value);

  final GalleryRef _value;

  @override
  GalleryRef type(String type) => call(type: type);

  @override
  GalleryRef id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryRef(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryRef call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return GalleryRef(
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

extension $GalleryRefCopyWith on GalleryRef {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryRef.copyWith(...)` or `instanceOfGalleryRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryRefCWProxy get copyWith => _$GalleryRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryRef _$GalleryRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['type', 'id']);
      final val = GalleryRef(
        type: $checkedConvert('type', (v) => v as String),
        id: $checkedConvert('id', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GalleryRefToJson(GalleryRef instance) =>
    <String, dynamic>{'type': instance.type, 'id': instance.id};
