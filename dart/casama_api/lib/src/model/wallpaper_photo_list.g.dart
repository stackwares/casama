// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper_photo_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WallpaperPhotoListCWProxy {
  WallpaperPhotoList items(List<WallpaperPhoto> items);

  WallpaperPhotoList source_(WallpaperPhotoListSource_Enum source_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WallpaperPhotoList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WallpaperPhotoList(...).copyWith(id: 12, name: "My name")
  /// ```
  WallpaperPhotoList call({
    List<WallpaperPhoto> items,
    WallpaperPhotoListSource_Enum source_,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWallpaperPhotoList.copyWith(...)` or call `instanceOfWallpaperPhotoList.copyWith.fieldName(value)` for a single field.
class _$WallpaperPhotoListCWProxyImpl implements _$WallpaperPhotoListCWProxy {
  const _$WallpaperPhotoListCWProxyImpl(this._value);

  final WallpaperPhotoList _value;

  @override
  WallpaperPhotoList items(List<WallpaperPhoto> items) => call(items: items);

  @override
  WallpaperPhotoList source_(WallpaperPhotoListSource_Enum source_) =>
      call(source_: source_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WallpaperPhotoList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WallpaperPhotoList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WallpaperPhotoList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return WallpaperPhotoList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<WallpaperPhoto>,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as WallpaperPhotoListSource_Enum,
    );
  }
}

extension $WallpaperPhotoListCopyWith on WallpaperPhotoList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWallpaperPhotoList.copyWith(...)` or `instanceOfWallpaperPhotoList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WallpaperPhotoListCWProxy get copyWith =>
      _$WallpaperPhotoListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WallpaperPhotoList _$WallpaperPhotoListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WallpaperPhotoList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'source']);
      final val = WallpaperPhotoList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => WallpaperPhoto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        source_: $checkedConvert(
          'source',
          (v) => $enumDecode(_$WallpaperPhotoListSource_EnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$WallpaperPhotoListToJson(WallpaperPhotoList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'source': _$WallpaperPhotoListSource_EnumEnumMap[instance.source_]!,
    };

const _$WallpaperPhotoListSource_EnumEnumMap = {
  WallpaperPhotoListSource_Enum.unsplash: 'unsplash',
};
