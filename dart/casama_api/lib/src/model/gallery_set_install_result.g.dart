// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_set_install_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySetInstallResultCWProxy {
  GallerySetInstallResult items(List<GallerySetInstallResultItemsInner> items);

  GallerySetInstallResult missing(GalleryMissing missing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetInstallResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetInstallResult(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySetInstallResult call({
    List<GallerySetInstallResultItemsInner> items,
    GalleryMissing missing,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySetInstallResult.copyWith(...)` or call `instanceOfGallerySetInstallResult.copyWith.fieldName(value)` for a single field.
class _$GallerySetInstallResultCWProxyImpl
    implements _$GallerySetInstallResultCWProxy {
  const _$GallerySetInstallResultCWProxyImpl(this._value);

  final GallerySetInstallResult _value;

  @override
  GallerySetInstallResult items(
    List<GallerySetInstallResultItemsInner> items,
  ) => call(items: items);

  @override
  GallerySetInstallResult missing(GalleryMissing missing) =>
      call(missing: missing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetInstallResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetInstallResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySetInstallResult call({
    Object? items = const $CopyWithPlaceholder(),
    Object? missing = const $CopyWithPlaceholder(),
  }) {
    return GallerySetInstallResult(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GallerySetInstallResultItemsInner>,
      missing: missing == const $CopyWithPlaceholder() || missing == null
          ? _value.missing
          // ignore: cast_nullable_to_non_nullable
          : missing as GalleryMissing,
    );
  }
}

extension $GallerySetInstallResultCopyWith on GallerySetInstallResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySetInstallResult.copyWith(...)` or `instanceOfGallerySetInstallResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySetInstallResultCWProxy get copyWith =>
      _$GallerySetInstallResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySetInstallResult _$GallerySetInstallResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GallerySetInstallResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items', 'missing']);
  final val = GallerySetInstallResult(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map(
            (e) => GallerySetInstallResultItemsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    missing: $checkedConvert(
      'missing',
      (v) => GalleryMissing.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$GallerySetInstallResultToJson(
  GallerySetInstallResult instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'missing': instance.missing.toJson(),
};
