// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_author_item_stats.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAuthorItemStatsCWProxy {
  GalleryAuthorItemStats installers(int installers);

  GalleryAuthorItemStats installers7d(int installers7d);

  GalleryAuthorItemStats active(int active);

  GalleryAuthorItemStats runsOk(int runsOk);

  GalleryAuthorItemStats runsTotal(int runsTotal);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorItemStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorItemStats(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAuthorItemStats call({
    int installers,
    int installers7d,
    int active,
    int runsOk,
    int runsTotal,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAuthorItemStats.copyWith(...)` or call `instanceOfGalleryAuthorItemStats.copyWith.fieldName(value)` for a single field.
class _$GalleryAuthorItemStatsCWProxyImpl
    implements _$GalleryAuthorItemStatsCWProxy {
  const _$GalleryAuthorItemStatsCWProxyImpl(this._value);

  final GalleryAuthorItemStats _value;

  @override
  GalleryAuthorItemStats installers(int installers) =>
      call(installers: installers);

  @override
  GalleryAuthorItemStats installers7d(int installers7d) =>
      call(installers7d: installers7d);

  @override
  GalleryAuthorItemStats active(int active) => call(active: active);

  @override
  GalleryAuthorItemStats runsOk(int runsOk) => call(runsOk: runsOk);

  @override
  GalleryAuthorItemStats runsTotal(int runsTotal) => call(runsTotal: runsTotal);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorItemStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorItemStats(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAuthorItemStats call({
    Object? installers = const $CopyWithPlaceholder(),
    Object? installers7d = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? runsOk = const $CopyWithPlaceholder(),
    Object? runsTotal = const $CopyWithPlaceholder(),
  }) {
    return GalleryAuthorItemStats(
      installers:
          installers == const $CopyWithPlaceholder() || installers == null
          ? _value.installers
          // ignore: cast_nullable_to_non_nullable
          : installers as int,
      installers7d:
          installers7d == const $CopyWithPlaceholder() || installers7d == null
          ? _value.installers7d
          // ignore: cast_nullable_to_non_nullable
          : installers7d as int,
      active: active == const $CopyWithPlaceholder() || active == null
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as int,
      runsOk: runsOk == const $CopyWithPlaceholder() || runsOk == null
          ? _value.runsOk
          // ignore: cast_nullable_to_non_nullable
          : runsOk as int,
      runsTotal: runsTotal == const $CopyWithPlaceholder() || runsTotal == null
          ? _value.runsTotal
          // ignore: cast_nullable_to_non_nullable
          : runsTotal as int,
    );
  }
}

extension $GalleryAuthorItemStatsCopyWith on GalleryAuthorItemStats {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAuthorItemStats.copyWith(...)` or `instanceOfGalleryAuthorItemStats.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAuthorItemStatsCWProxy get copyWith =>
      _$GalleryAuthorItemStatsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAuthorItemStats _$GalleryAuthorItemStatsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'GalleryAuthorItemStats',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'installers',
        'installers_7d',
        'active',
        'runs_ok',
        'runs_total',
      ],
    );
    final val = GalleryAuthorItemStats(
      installers: $checkedConvert('installers', (v) => (v as num).toInt()),
      installers7d: $checkedConvert('installers_7d', (v) => (v as num).toInt()),
      active: $checkedConvert('active', (v) => (v as num).toInt()),
      runsOk: $checkedConvert('runs_ok', (v) => (v as num).toInt()),
      runsTotal: $checkedConvert('runs_total', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'installers7d': 'installers_7d',
    'runsOk': 'runs_ok',
    'runsTotal': 'runs_total',
  },
);

Map<String, dynamic> _$GalleryAuthorItemStatsToJson(
  GalleryAuthorItemStats instance,
) => <String, dynamic>{
  'installers': instance.installers,
  'installers_7d': instance.installers7d,
  'active': instance.active,
  'runs_ok': instance.runsOk,
  'runs_total': instance.runsTotal,
};
