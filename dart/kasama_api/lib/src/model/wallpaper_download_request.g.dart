// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper_download_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WallpaperDownloadRequestCWProxy {
  WallpaperDownloadRequest downloadLocation(String downloadLocation);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WallpaperDownloadRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WallpaperDownloadRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  WallpaperDownloadRequest call({String downloadLocation});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWallpaperDownloadRequest.copyWith(...)` or call `instanceOfWallpaperDownloadRequest.copyWith.fieldName(value)` for a single field.
class _$WallpaperDownloadRequestCWProxyImpl
    implements _$WallpaperDownloadRequestCWProxy {
  const _$WallpaperDownloadRequestCWProxyImpl(this._value);

  final WallpaperDownloadRequest _value;

  @override
  WallpaperDownloadRequest downloadLocation(String downloadLocation) =>
      call(downloadLocation: downloadLocation);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WallpaperDownloadRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WallpaperDownloadRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WallpaperDownloadRequest call({
    Object? downloadLocation = const $CopyWithPlaceholder(),
  }) {
    return WallpaperDownloadRequest(
      downloadLocation:
          downloadLocation == const $CopyWithPlaceholder() ||
              downloadLocation == null
          ? _value.downloadLocation
          // ignore: cast_nullable_to_non_nullable
          : downloadLocation as String,
    );
  }
}

extension $WallpaperDownloadRequestCopyWith on WallpaperDownloadRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWallpaperDownloadRequest.copyWith(...)` or `instanceOfWallpaperDownloadRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WallpaperDownloadRequestCWProxy get copyWith =>
      _$WallpaperDownloadRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WallpaperDownloadRequest _$WallpaperDownloadRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WallpaperDownloadRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['download_location']);
  final val = WallpaperDownloadRequest(
    downloadLocation: $checkedConvert('download_location', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'downloadLocation': 'download_location'});

Map<String, dynamic> _$WallpaperDownloadRequestToJson(
  WallpaperDownloadRequest instance,
) => <String, dynamic>{'download_location': instance.downloadLocation};
