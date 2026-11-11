// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper_photo.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WallpaperPhotoCWProxy {
  WallpaperPhoto id(String id);

  WallpaperPhoto thumbUrl(String thumbUrl);

  WallpaperPhoto url(String url);

  WallpaperPhoto color(String? color);

  WallpaperPhoto width(int width);

  WallpaperPhoto height(int height);

  WallpaperPhoto author(String author);

  WallpaperPhoto authorUrl(String authorUrl);

  WallpaperPhoto sourceUrl(String sourceUrl);

  WallpaperPhoto downloadLocation(String downloadLocation);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WallpaperPhoto(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WallpaperPhoto(...).copyWith(id: 12, name: "My name")
  /// ```
  WallpaperPhoto call({
    String id,
    String thumbUrl,
    String url,
    String? color,
    int width,
    int height,
    String author,
    String authorUrl,
    String sourceUrl,
    String downloadLocation,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWallpaperPhoto.copyWith(...)` or call `instanceOfWallpaperPhoto.copyWith.fieldName(value)` for a single field.
class _$WallpaperPhotoCWProxyImpl implements _$WallpaperPhotoCWProxy {
  const _$WallpaperPhotoCWProxyImpl(this._value);

  final WallpaperPhoto _value;

  @override
  WallpaperPhoto id(String id) => call(id: id);

  @override
  WallpaperPhoto thumbUrl(String thumbUrl) => call(thumbUrl: thumbUrl);

  @override
  WallpaperPhoto url(String url) => call(url: url);

  @override
  WallpaperPhoto color(String? color) => call(color: color);

  @override
  WallpaperPhoto width(int width) => call(width: width);

  @override
  WallpaperPhoto height(int height) => call(height: height);

  @override
  WallpaperPhoto author(String author) => call(author: author);

  @override
  WallpaperPhoto authorUrl(String authorUrl) => call(authorUrl: authorUrl);

  @override
  WallpaperPhoto sourceUrl(String sourceUrl) => call(sourceUrl: sourceUrl);

  @override
  WallpaperPhoto downloadLocation(String downloadLocation) =>
      call(downloadLocation: downloadLocation);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WallpaperPhoto(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WallpaperPhoto(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WallpaperPhoto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? thumbUrl = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
    Object? authorUrl = const $CopyWithPlaceholder(),
    Object? sourceUrl = const $CopyWithPlaceholder(),
    Object? downloadLocation = const $CopyWithPlaceholder(),
  }) {
    return WallpaperPhoto(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      thumbUrl: thumbUrl == const $CopyWithPlaceholder() || thumbUrl == null
          ? _value.thumbUrl
          // ignore: cast_nullable_to_non_nullable
          : thumbUrl as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String?,
      width: width == const $CopyWithPlaceholder() || width == null
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as int,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as int,
      author: author == const $CopyWithPlaceholder() || author == null
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as String,
      authorUrl: authorUrl == const $CopyWithPlaceholder() || authorUrl == null
          ? _value.authorUrl
          // ignore: cast_nullable_to_non_nullable
          : authorUrl as String,
      sourceUrl: sourceUrl == const $CopyWithPlaceholder() || sourceUrl == null
          ? _value.sourceUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceUrl as String,
      downloadLocation:
          downloadLocation == const $CopyWithPlaceholder() ||
              downloadLocation == null
          ? _value.downloadLocation
          // ignore: cast_nullable_to_non_nullable
          : downloadLocation as String,
    );
  }
}

extension $WallpaperPhotoCopyWith on WallpaperPhoto {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWallpaperPhoto.copyWith(...)` or `instanceOfWallpaperPhoto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WallpaperPhotoCWProxy get copyWith => _$WallpaperPhotoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WallpaperPhoto _$WallpaperPhotoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WallpaperPhoto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'thumb_url',
            'url',
            'color',
            'width',
            'height',
            'author',
            'author_url',
            'source_url',
            'download_location',
          ],
        );
        final val = WallpaperPhoto(
          id: $checkedConvert('id', (v) => v as String),
          thumbUrl: $checkedConvert('thumb_url', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          color: $checkedConvert('color', (v) => v as String?),
          width: $checkedConvert('width', (v) => (v as num).toInt()),
          height: $checkedConvert('height', (v) => (v as num).toInt()),
          author: $checkedConvert('author', (v) => v as String),
          authorUrl: $checkedConvert('author_url', (v) => v as String),
          sourceUrl: $checkedConvert('source_url', (v) => v as String),
          downloadLocation: $checkedConvert(
            'download_location',
            (v) => v as String,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'thumbUrl': 'thumb_url',
        'authorUrl': 'author_url',
        'sourceUrl': 'source_url',
        'downloadLocation': 'download_location',
      },
    );

Map<String, dynamic> _$WallpaperPhotoToJson(WallpaperPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'thumb_url': instance.thumbUrl,
      'url': instance.url,
      'color': instance.color,
      'width': instance.width,
      'height': instance.height,
      'author': instance.author,
      'author_url': instance.authorUrl,
      'source_url': instance.sourceUrl,
      'download_location': instance.downloadLocation,
    };
