// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_update_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryUpdateResultCWProxy {
  GalleryUpdateResult updated(int updated);

  GalleryUpdateResult version(int version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryUpdateResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryUpdateResult(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryUpdateResult call({int updated, int version});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryUpdateResult.copyWith(...)` or call `instanceOfGalleryUpdateResult.copyWith.fieldName(value)` for a single field.
class _$GalleryUpdateResultCWProxyImpl implements _$GalleryUpdateResultCWProxy {
  const _$GalleryUpdateResultCWProxyImpl(this._value);

  final GalleryUpdateResult _value;

  @override
  GalleryUpdateResult updated(int updated) => call(updated: updated);

  @override
  GalleryUpdateResult version(int version) => call(version: version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryUpdateResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryUpdateResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryUpdateResult call({
    Object? updated = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return GalleryUpdateResult(
      updated: updated == const $CopyWithPlaceholder() || updated == null
          ? _value.updated
          // ignore: cast_nullable_to_non_nullable
          : updated as int,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $GalleryUpdateResultCopyWith on GalleryUpdateResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryUpdateResult.copyWith(...)` or `instanceOfGalleryUpdateResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryUpdateResultCWProxy get copyWith =>
      _$GalleryUpdateResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryUpdateResult _$GalleryUpdateResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryUpdateResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['updated', 'version']);
      final val = GalleryUpdateResult(
        updated: $checkedConvert('updated', (v) => (v as num).toInt()),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$GalleryUpdateResultToJson(
  GalleryUpdateResult instance,
) => <String, dynamic>{
  'updated': instance.updated,
  'version': instance.version,
};
