// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_stats_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryStatsListCWProxy {
  GalleryStatsList items(Map<String, GalleryStats> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryStatsList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryStatsList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryStatsList call({Map<String, GalleryStats> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryStatsList.copyWith(...)` or call `instanceOfGalleryStatsList.copyWith.fieldName(value)` for a single field.
class _$GalleryStatsListCWProxyImpl implements _$GalleryStatsListCWProxy {
  const _$GalleryStatsListCWProxyImpl(this._value);

  final GalleryStatsList _value;

  @override
  GalleryStatsList items(Map<String, GalleryStats> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryStatsList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryStatsList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryStatsList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryStatsList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as Map<String, GalleryStats>,
    );
  }
}

extension $GalleryStatsListCopyWith on GalleryStatsList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryStatsList.copyWith(...)` or `instanceOfGalleryStatsList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryStatsListCWProxy get copyWith => _$GalleryStatsListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryStatsList _$GalleryStatsListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryStatsList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = GalleryStatsList(
        items: $checkedConvert(
          'items',
          (v) => (v as Map<String, dynamic>).map(
            (k, e) =>
                MapEntry(k, GalleryStats.fromJson(e as Map<String, dynamic>)),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryStatsListToJson(GalleryStatsList instance) =>
    <String, dynamic>{
      'items': instance.items.map((k, e) => MapEntry(k, e.toJson())),
    };
