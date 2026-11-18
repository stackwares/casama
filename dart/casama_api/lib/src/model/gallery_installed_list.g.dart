// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_installed_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInstalledListCWProxy {
  GalleryInstalledList items(List<GalleryInstalledItem> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstalledList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstalledList(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInstalledList call({List<GalleryInstalledItem> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInstalledList.copyWith(...)` or call `instanceOfGalleryInstalledList.copyWith.fieldName(value)` for a single field.
class _$GalleryInstalledListCWProxyImpl
    implements _$GalleryInstalledListCWProxy {
  const _$GalleryInstalledListCWProxyImpl(this._value);

  final GalleryInstalledList _value;

  @override
  GalleryInstalledList items(List<GalleryInstalledItem> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstalledList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstalledList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInstalledList call({Object? items = const $CopyWithPlaceholder()}) {
    return GalleryInstalledList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GalleryInstalledItem>,
    );
  }
}

extension $GalleryInstalledListCopyWith on GalleryInstalledList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInstalledList.copyWith(...)` or `instanceOfGalleryInstalledList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInstalledListCWProxy get copyWith =>
      _$GalleryInstalledListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInstalledList _$GalleryInstalledListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryInstalledList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = GalleryInstalledList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => GalleryInstalledItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$GalleryInstalledListToJson(
  GalleryInstalledList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
