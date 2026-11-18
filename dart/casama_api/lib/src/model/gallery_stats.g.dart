// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_stats.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryStatsCWProxy {
  GalleryStats installers(int? installers);

  GalleryStats trending(int? trending);

  GalleryStats active(int? active);

  GalleryStats success(num? success);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryStats(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryStats call({
    int? installers,
    int? trending,
    int? active,
    num? success,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryStats.copyWith(...)` or call `instanceOfGalleryStats.copyWith.fieldName(value)` for a single field.
class _$GalleryStatsCWProxyImpl implements _$GalleryStatsCWProxy {
  const _$GalleryStatsCWProxyImpl(this._value);

  final GalleryStats _value;

  @override
  GalleryStats installers(int? installers) => call(installers: installers);

  @override
  GalleryStats trending(int? trending) => call(trending: trending);

  @override
  GalleryStats active(int? active) => call(active: active);

  @override
  GalleryStats success(num? success) => call(success: success);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryStats(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryStats call({
    Object? installers = const $CopyWithPlaceholder(),
    Object? trending = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? success = const $CopyWithPlaceholder(),
  }) {
    return GalleryStats(
      installers: installers == const $CopyWithPlaceholder()
          ? _value.installers
          // ignore: cast_nullable_to_non_nullable
          : installers as int?,
      trending: trending == const $CopyWithPlaceholder()
          ? _value.trending
          // ignore: cast_nullable_to_non_nullable
          : trending as int?,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as int?,
      success: success == const $CopyWithPlaceholder()
          ? _value.success
          // ignore: cast_nullable_to_non_nullable
          : success as num?,
    );
  }
}

extension $GalleryStatsCopyWith on GalleryStats {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryStats.copyWith(...)` or `instanceOfGalleryStats.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryStatsCWProxy get copyWith => _$GalleryStatsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryStats _$GalleryStatsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryStats', json, ($checkedConvert) {
      final val = GalleryStats(
        installers: $checkedConvert('installers', (v) => (v as num?)?.toInt()),
        trending: $checkedConvert('trending', (v) => (v as num?)?.toInt()),
        active: $checkedConvert('active', (v) => (v as num?)?.toInt()),
        success: $checkedConvert('success', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$GalleryStatsToJson(GalleryStats instance) =>
    <String, dynamic>{
      'installers': ?instance.installers,
      'trending': ?instance.trending,
      'active': ?instance.active,
      'success': ?instance.success,
    };
