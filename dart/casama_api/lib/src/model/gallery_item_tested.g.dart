// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_item_tested.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryItemTestedCWProxy {
  GalleryItemTested version(int version);

  GalleryItemTested date(String date);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryItemTested(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryItemTested(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryItemTested call({int version, String date});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryItemTested.copyWith(...)` or call `instanceOfGalleryItemTested.copyWith.fieldName(value)` for a single field.
class _$GalleryItemTestedCWProxyImpl implements _$GalleryItemTestedCWProxy {
  const _$GalleryItemTestedCWProxyImpl(this._value);

  final GalleryItemTested _value;

  @override
  GalleryItemTested version(int version) => call(version: version);

  @override
  GalleryItemTested date(String date) => call(date: date);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryItemTested(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryItemTested(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryItemTested call({
    Object? version = const $CopyWithPlaceholder(),
    Object? date = const $CopyWithPlaceholder(),
  }) {
    return GalleryItemTested(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
    );
  }
}

extension $GalleryItemTestedCopyWith on GalleryItemTested {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryItemTested.copyWith(...)` or `instanceOfGalleryItemTested.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryItemTestedCWProxy get copyWith =>
      _$GalleryItemTestedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryItemTested _$GalleryItemTestedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryItemTested', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version', 'date']);
      final val = GalleryItemTested(
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        date: $checkedConvert('date', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GalleryItemTestedToJson(GalleryItemTested instance) =>
    <String, dynamic>{'version': instance.version, 'date': instance.date};
